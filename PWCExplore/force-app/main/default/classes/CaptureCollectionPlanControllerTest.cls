@isTest
public with sharing class CaptureCollectionPlanControllerTest {
    @TestSetup
    public static void setupData(){
        test.startTest();
        UserRole iaUserRole = new UserRole(Name = 'CEO');
        insert iaUserRole;
        Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Integration Administrator' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User ssg_user = new User(UserRoleId = iaUserRole.Id, ProfileId = adminProfile.Id, 
                                 Alias = 'ssg', Email='ssgUser@godrej.com',Salary_Code__c='377337',Business_Unit__c='G',
                                 EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUser@godrej.com',CommunityNickname = 'test1234567');
        insert ssg_user; 
        System.runAs(ssg_user){
            Account partnerAccount = new TestAccountBuilder().setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer')
                                                                              .getRecordTypeId()).setBusinessUnit('G').getSavedTestRecord();
            
            Opportunity newSsgOpp = new Opportunity(
                Name = 'Test ssg Opp',               
                AccountId = partnerAccount.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'G',                       
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Qualification',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                // Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId());
            
            insert newSsgOpp;
            
            Quote newSsgQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newSsgOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',Dealer_SAC_Applicable__c = 'No',                   
                //  Transaction_Type__c = 'Primary',
                RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId(),                 
                Quote_Type__c = 'Customer Facing',Scope_of_Installation__c = 'Dealer');
            
            insert newSsgQuote;
            List<Order> ssgOrders = new List<Order>{new TestOrderBuilder().setAccountId(partnerAccount.Id).setOrderReferenceNumber('G12345')
                .setBusinessUnit('G').setQuoteId(newSsgQuote.id).getTestRecord(),
                new TestOrderBuilder().setName('Draft order').setAccountId(partnerAccount.Id).setBusinessUnit('G').getTestRecord()};
                    ssgOrders[0].Installation_Scope__c = newSsgQuote.Scope_of_Installation__c;
            ssgOrders[0].QuoteId = newSsgQuote.Id;
            ssgOrders[0].EffectiveDate = system.today();
            ssgOrders[0].Status = 'Draft';
            // ssgOrders[0].Advance_Amount__c = 180;
            // ssgOrders[0].Material_supply_Amount__c = 360;
            // ssgOrders[0].Installation_amount__c = 60;
            ssgOrders[1].QuoteId = newSsgQuote.Id;
            ssgOrders[1].Installation_Scope__c = newSsgQuote.Scope_of_Installation__c;
            ssgOrders[1].EffectiveDate = system.today();
            ssgOrders[1].Status = 'Draft';
            //  ssgOrders[1].Advance_Amount__c = 60;
            //  ssgOrders[1].Material_supply_Amount__c = 360;
            //  ssgOrders[1].Installation_amount__c = 60; 
            insert ssgOrders;
            system.debug('ssgOrders'+ssgOrders);
            List<Billed_Sales_Outstandings__c> billedSalesRecs = new List<Billed_Sales_Outstandings__c>{
                new TestBilledSalesOutstandingsBuilder().setAccount(partnerAccount.Id).setBusinessUnit('G').getTestRecord(),
                    new TestBilledSalesOutstandingsBuilder().setAccount(partnerAccount.Id).setBusinessUnit('G').getTestRecord()};
                        insert billedSalesRecs;
            Id receivableRecordTypeId = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId();
            List<Receivable__c> receivableRecs = new List<Receivable__c>{
                new TestReceivableBuilder().setInvoice(billedSalesRecs[0].Id).setOrder('G12345').setRecordTypeId(receivableRecordTypeId).getTestRecord(),
                    new TestReceivableBuilder().setInvoice(billedSalesRecs[1].Id).setOrder('G12345').setRecordTypeId(receivableRecordTypeId).getTestRecord()};
                        //receivableRecs[0].Cumulative_Paid_Amount__c = 10 ;
                        // receivableRecs[1].Cumulative_Paid_Amount__c =  ;
                        insert receivableRecs;
            //GlobalPicklistUpdater queueable = new GlobalPicklistUpdater('','',receivableRecs);
            //System.enqueueJob(queueable);
        }
        test.stopTest();
    }
    
    @isTest
    public static void requestingPlanCreationFromOrderShouldSetBalanceAmount() {
        Order orderRecord = [SELECT Id FROM Order WHERE OrderReferenceNumber = 'G12345'];
        Test.startTest();
        Collection_Plan__c collectionPlan = CaptureCollectionPlanController.getCollectionPlan(orderRecord.Id);
        Test.stopTest();
        System.assertEquals(orderRecord.Id, collectionPlan.Sales_Order__c, 'Sales Order not defaulted on collection plan');
        System.assertEquals(2000, collectionPlan.Balance_Amount__c, 'Balance amount not set on collection plan');
    }
    
    @isTest
    public static void requestingPlanCreationOnOpenOrderShouldFail() {
        Order orderRecord = [SELECT Id,Installation_scope__c, OrderReferenceNumber FROM Order WHERE Name = 'Draft Order'];
        String errorMessage = '';
        try {
            Test.startTest();
            Collection_Plan__c collectionPlan = CaptureCollectionPlanController.getCollectionPlan(orderRecord.Id);
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(Label.Order_Not_Synced, errorMessage, 'Collection Plan created on open order incorrectly');
    }
    
    @isTest
    public static void requestingPlanCreationOnOrderWithoutInvoicesShouldFail() {
        Order orderRecord = [SELECT Id, OrderReferenceNumber FROM Order WHERE Name = 'Draft Order'];
        orderRecord.OrderReferenceNumber = 'G12346';
        update orderRecord;
        String errorMessage = '';
        try {
            Test.startTest();
            Collection_Plan__c collectionPlan = CaptureCollectionPlanController.getCollectionPlan(orderRecord.Id);
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(Label.Order_Not_Invoiced, errorMessage, 'Collection Plan created on order without invoices');
    }
    
    @isTest
    public static void requestingPlanCreationFromInvoiceShouldSetOrderIdAndBalanceAmount() {
        Order orderRecord = [SELECT Id FROM Order WHERE OrderReferenceNumber = 'G12345'];
        Billed_Sales_Outstandings__c receivablesHeader = [SELECT Id FROM Billed_Sales_Outstandings__c LIMIT 1];
        Test.startTest();
        Collection_Plan__c collectionPlan = CaptureCollectionPlanController.getCollectionPlan(receivablesHeader.Id);
        Test.stopTest();
        System.assertEquals(orderRecord.Id, collectionPlan.Sales_Order__c, 'Sales Order not defaulted on collection plan');
        System.assertEquals(2000, collectionPlan.Balance_Amount__c, 'Balance amount not set on collection plan');
    }
    
    @isTest
    public static void creatingCollectionPlanShouldCopyValuesToAllInvoices() {
        Order orderRecord = [SELECT Id FROM Order WHERE OrderReferenceNumber = 'G12345'];
        Collection_Plan__c collectionPlan = CaptureCollectionPlanController.getCollectionPlan(orderRecord.Id);
        collectionPlan.Planned_Collection_Date_1__c = Date.today();
        collectionPlan.Planned_Collection_Amount_1__c = 100;
        insert collectionPlan;
        Test.startTest();
        CaptureCollectionPlanController.updateCollectionPlan(collectionPlan.Id);
        Test.stopTest();
        for (Billed_Sales_Outstandings__c each : [SELECT Id, Collection_Plan__c, Planned_Collection_Date_1__c, Planned_Collection_Amount_1__c FROM
                                                  Billed_Sales_Outstandings__c]) {
                                                      System.assertEquals(collectionPlan.Id, each.Collection_Plan__c, 'Collection Plan not linked to receivables header');
                                                      System.assertEquals(Date.today(), each.Planned_Collection_Date_1__c, 'Planned Collection date not stamped on receivables header');
                                                      System.assertEquals(100, each.Planned_Collection_Amount_1__c, 'Planned Collection Amount not stamped on receivables header');
                                                  }
    }
}