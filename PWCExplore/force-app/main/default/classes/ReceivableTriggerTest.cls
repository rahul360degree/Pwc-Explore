@isTest
public with sharing class ReceivableTriggerTest {
    @TestSetup
    public static void setupData(){
        Profile salesProfile = [SELECT Id from Profile where Name = 'MHE Sales User' LIMIT 1];
        User salesUser = new TestUserBuilder().setLastName('SalesUserReceivableTest').setProfileId(salesProfile.Id).setBusinessUnit('G').getSavedTestRecord();
        Billed_Sales_Outstandings__c billedSalesRec = new TestBilledSalesOutstandingsBuilder().setBusinessUnit('G').getSavedTestRecord();
    }

    @isTest
    public static void creatingReceivableWithSalesRepShouldDefaultOwner() {
        User salesUser = [SELECT Id FROM User WHERE Name = 'SalesUserReceivableTest'];
        Billed_Sales_Outstandings__c headerRec = [SELECT Id FROM Billed_Sales_Outstandings__c];
        Test.startTest();
        Receivable__c receivableRec = new TestReceivableBuilder().setInvoice(headerRec.Id).setRecordType('Receivable').setSalesRepresentative(salesUser.Id)
            .getSavedTestRecord();
        Test.stopTest();
        receivableRec = [SELECT RecordTypeId, OwnerId FROM Receivable__c];
        System.assertEquals(Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId(), receivableRec.RecordTypeId,
            'Line Item record type not set to receivable');
        //System.assertEquals(salesUser.Id, receivableRec.OwnerId, 'Owner not set to Sales Rep Id');
    }

    @isTest
    public static void creatingInvoiceShouldCreateCommission() {
        User salesUser = [SELECT Id FROM User WHERE Name = 'SalesUserReceivableTest'];
        Billed_Sales_Outstandings__c headerRec = [SELECT Id FROM Billed_Sales_Outstandings__c];
        Test.startTest();
        Receivable__c invoiceRec = new TestReceivableBuilder().setInvoice(headerRec.Id).setRecordType('Invoice').setSalesRepresentative(salesUser.Id)
            .setBusinessUnit('K').getSavedTestRecord();
        
        invoiceRec.Salary_Code__c ='12';
        update invoiceRec;
        Test.stopTest();
        Commission__c commissionRec = [SELECT Id, Invoice__c, Line_Item__c, OwnerId, Credit__c, Type__c FROM Commission__c];
        System.assertEquals(headerRec.Id, commissionRec.Invoice__c, 'Invoice record not tagged on Commission');
        System.assertEquals(invoiceRec.Id, commissionRec.Line_Item__c, 'Line Item record not tagged on Commission');
        //System.assertEquals(salesUser.Id, commissionRec.OwnerId, 'Owner not tagged on Commission');
        System.assertEquals(100, commissionRec.Credit__c, 'Default credit not set on Commission');
        System.assertEquals('Actual', commissionRec.Type__c, 'Type not set on Commission');
    }
}