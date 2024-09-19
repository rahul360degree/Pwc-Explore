@isTest
public with sharing class CommissionTriggerTest {
    @TestSetup
    static void makeData(){
        Profile mheProfile = [SELECT Id FROM Profile WHERE Name = 'MHE Sales User'];
        List<User> mheUsers = new List<User>{new TestUserBuilder().setLastName('SalesUserCommissionTest1').setProfileId(mheProfile.Id)
            .setBusinessUnit('K').setLogisticCompany('5000').getTestRecord(),
            new TestUserBuilder().setLastName('SalesUserCommissionTest2').setProfileId(mheProfile.Id).setBusinessUnit('K').setLogisticCompany('5000').getTestRecord()};                
        insert mheUsers;

        Account accountRecord = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            .getSavedTestRecord();
        Billed_Sales_Outstandings__c relatedInvoiceRecord = new TestBilledSalesOutstandingsBuilder().setOwnerId(mheUsers[0].Id).getSavedTestRecord();
        Id invoiceRecTypeId = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();
        Receivable__c invoiceRecord = new TestReceivableBuilder().setBusinessUnit('K').setRecordType('Invoice').setNetBilledSales(1000)
            .setInvoice(relatedInvoiceRecord.Id).setOwnerId(mheUsers[0].Id).setRecordTypeId(invoiceRecTypeId).setBranch('5000').getSavedTestRecord(); //added setBranch method by Shreela for resolving test class issue on 25th October 2021
    }

    @isTest
    public static void newCreditRequestWithValidInvoiceNumberShouldSetDefaults() {
        User mheUser = [SELECT Id FROM User WHERE LastName = 'SalesUserCommissionTest2' LIMIT 1];
        Commission__c creditRequest;
        Test.startTest();
        System.runAs(mheUser) {
            creditRequest = new TestCommissionBuilder().setType('Credit Request').setInvoiceNumber('12345').getSavedTestRecord();
        }
        Test.stopTest();
        creditRequest = [SELECT Invoice__c, Credit__c FROM Commission__c WHERE Id = :creditRequest.Id];
        Billed_Sales_Outstandings__c invoiceHeader = [SELECT Id FROM Billed_Sales_Outstandings__c];
        System.assertEquals(invoiceHeader.Id, creditRequest.Invoice__c, 'Invoice not pre-populated on Credit Request record');
        System.assertEquals(50, creditRequest.Credit__c, 'Credit % not set correctly');
    }

    @isTest
    public static void newCreditRequestWithInvalidInvoiceNumberShouldFail() {
        String errorMessage = '';
        try {
            Test.startTest();
            Commission__c creditRequest = new TestCommissionBuilder().setType('Credit Request').setInvoiceNumber('ABCDE').getSavedTestRecord();
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(true, errorMessage.contains(Label.Invalid_Invoice_Number), 'Invoice not pre-populated on Credit Request record');
    }

    @isTest
    public static void newCreditRequestForOldInvoiceShouldFail() {
        String errorMessage = '';
        Billed_Sales_Outstandings__c billedSalesRec = [SELECT Id, Document_Date__c FROM Billed_Sales_Outstandings__c];
        billedSalesRec.Document_Date__c = Date.today().addYears(-1);
        update billedSalesRec;
        try {
            Test.startTest();
            Commission__c creditRequest = new TestCommissionBuilder().setType('Credit Request').setInvoiceNumber('12345').getSavedTestRecord();
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(true, errorMessage.contains(Label.Credit_Sharing_Locked), 'Invoice not pre-populated on Credit Request record');
    }

    @isTest
    public static void approvingCreditRequestShouldGenerateCommissionRecord() {
        User mheUser = [SELECT Id FROM User WHERE LastName = 'SalesUserCommissionTest2' LIMIT 1];
        Commission__c creditRequest;
        System.runAs(mheUser) {
            creditRequest = new TestCommissionBuilder().setType('Credit Request').setInvoiceNumber('12345').getSavedTestRecord();
        }
        creditRequest.Approval_Status__c = 'Approved';
        Test.startTest();
        update creditRequest;
        Test.stopTest();
        List<Commission__c> commissionRecords = [SELECT Id, Credit__c FROM Commission__c WHERE Type__c = 'Actual' OR Type__c = 'Credit Share'];
        System.assertEquals(2, commissionRecords.size(), 'Credit Share record not generated');
        for (Commission__c each : commissionRecords) {
            System.assertEquals(50, each.Credit__c, 'Credit % not set appropriately');
        }
    }
}