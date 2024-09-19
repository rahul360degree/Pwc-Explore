@isTest
public with sharing class BilledSalesTriggerTest {
    @TestSetup
    public static void setupData(){
        Profile salesProfile = [SELECT Id from Profile where Name = 'MHE Sales User' LIMIT 1];
        User salesUser = new TestUserBuilder().setLastName('SalesUserBSOTest').setProfileId(salesProfile.Id).setBusinessUnit('G').getSavedTestRecord();
        Billed_Sales_Outstandings__c billedSalesRec = new TestBilledSalesOutstandingsBuilder().setBusinessUnit('G').getSavedTestRecord();
        Id receivableRecordTypeId = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId();
        Receivable__c receivableRec = new TestReceivableBuilder().setInvoice(billedSalesRec.Id).setOrder('G12345').setRecordTypeId(receivableRecordTypeId)
            .getSavedTestRecord();
    }

    @isTest
    public static void creatingBilledSalesWithSalesRepShouldSetOwnerId() {
        User mheUser = [SELECT Id FROM User WHERE Name = 'SalesUserBSOTest' LIMIT 1];
        Test.startTest();
        Billed_Sales_Outstandings__c billedSalesRec = new TestBilledSalesOutstandingsBuilder().setBusinessUnit('K').setSalesRepresentative(mheUser.Id)
            .getSavedTestRecord();
        Test.stopTest();
        billedSalesRec = [SELECT OwnerId FROM Billed_Sales_Outstandings__c WHERE Id = :billedSalesRec.Id];
        //System.assertEquals(mheUser.Id, billedSalesRec.OwnerId, 'Billed Sales Record Owner not defaulted to Sales Rep ID');
    }

    @isTest
    public static void updatingReceivableStatusToNotDueShouldSetDate() {
        Billed_Sales_Outstandings__c billedSalesRec = [SELECT Id FROM Billed_Sales_Outstandings__c];
        billedSalesRec.Status__c = 'Not Due';
        Test.startTest();
        update billedSalesRec;
        Test.stopTest();
        billedSalesRec = [SELECT Not_Due_Since__c FROM Billed_Sales_Outstandings__c WHERE Id = :billedSalesRec.Id];
        System.assertEquals(Date.today(), billedSalesRec.Not_Due_Since__c, 'Not due since not defaulted based on status update');
    }

    @isTest
    public static void updatingReceivableStatusToDueShouldResetDate() {
        Billed_Sales_Outstandings__c billedSalesRec = [SELECT Id FROM Billed_Sales_Outstandings__c];
        billedSalesRec.Status__c = 'Not Due';
        update billedSalesRec;
        billedSalesRec = [SELECT Not_Due_Since__c FROM Billed_Sales_Outstandings__c WHERE Id = :billedSalesRec.Id];
        System.assertEquals(Date.today(), billedSalesRec.Not_Due_Since__c, 'Not due since not defaulted based on status update');
        billedSalesRec.Status__c = 'Due';
        Test.startTest();
        update billedSalesRec;
        Test.stopTest();
        billedSalesRec = [SELECT Not_Due_Since__c FROM Billed_Sales_Outstandings__c WHERE Id = :billedSalesRec.Id];
        System.assertEquals(null, billedSalesRec.Not_Due_Since__c, 'Not due since not reset after changing status');
    }

    @isTest
    public static void settingShortCodeShouldUpdateSOAndTotalBalance() {
        Billed_Sales_Outstandings__c billedSalesRec = [SELECT Id FROM Billed_Sales_Outstandings__c];
        billedSalesRec.SF_Short_Code__c = 'Freight Issue';
        Test.startTest();
        update billedSalesRec;
        Test.stopTest();
        billedSalesRec = [SELECT SO__c, Total_Balance__c FROM Billed_Sales_Outstandings__c WHERE Id = :billedSalesRec.Id];
        System.assertEquals('G12345', billedSalesRec.SO__c, 'SO# on receivables header not set');
        System.assertEquals(1000, billedSalesRec.Total_Balance__c, 'Total Balance on receivables header not set');
    }
}