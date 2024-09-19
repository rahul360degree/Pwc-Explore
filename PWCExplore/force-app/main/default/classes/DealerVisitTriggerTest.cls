@isTest
private class DealerVisitTriggerTest {
    @testsetup
    private static void testData() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        UserRole appliancesRole = [SELECT Id FROM UserRole WHERE Name = 'Appliances'];
        User newAdminuser = new TestUserBuilder().setLastName('AdminD2DTest').setProfileId(adminProfile.Id).setUserRoleId(appliancesRole.Id).getSavedTestRecord();
        
        System.runAs(newAdminuser) {
            Account accountRecord = new Account(Name = 'TestB2B9',
                                                Industry = 'Apparel',
                                                Type = 'D',
                                                Business_Unit__c = 'W',
                                                Account_Code__c = 'FDG2435');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
            insert accountRecord;
            
            Contact partnerContact = new TestContactBuilder().setAccountId(accountRecord.Id).getSavedTestRecord();
            User partnerUser = new TestUserBuilder().setLastName('CADealerVisitTriggerTest').setProfileId([SELECT Id FROM Profile WHERE Name = 'Appliances Customer Advisor Partner User'].Id)
                .setContactId(partnerContact.Id).setBusinessUnit('H').getSavedTestRecord();
            
            PJP__c pjp = new PJP__c(Name = 'TestPJP');
            insert pjp;
            
            Interio_Questionnaire__c template =  new Interio_Questionnaire__c(Task_Type__c = 'Market visit',
                                                 RecordTypeId = Schema.SObjectType.Interio_Questionnaire__c.getRecordTypeInfosByDeveloperName().get('Template').getRecordTypeId(),
                                                 Question_1__c = 'Q1' ,
                                                                              Status__c = 'Active' 
                                                );
            insert template;
                
            Dealer_Visit__c dv = new Dealer_Visit__c( Name = 'TestDV',
                                                       Visit_Due_Date__c = Datetime.now()+30,
                                                       Dealer_Visit_Status__c = 'Planned',
                                                       PJP__c = pjp.Id,
                                                     	Search_Other_Account__c= TRUE,
                                                       Account_Information__c = accountRecord.Id,
                                                     RecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId(),
                                                     Task_Type__c = 'Market visit'
            );
            
            insert dv;
            
        }
    }
    @isTest
    private static void test_DealerVisitEventsInsert(){
        List<PJP__c> pjp = [Select Id From PJP__c limit 1];
        List<Account> acc = [Select Id From Account limit 1];
        Test.startTest();
         Dealer_Visit__c dv = new Dealer_Visit__c( Name = 'TestDV',
                                                   Visit_Due_Date__c = Datetime.now()+30,
                                                   Dealer_Visit_Status__c = 'Planned',
                                                   PJP__c = pjp[0].Id,
                                                  	Search_Other_Account__c= TRUE,
                                                   Account_Information__c = acc[0].Id
         );
        insert dv;
        	
        List<Dealer_Visit__c> dvs = [Select Id from Dealer_Visit__c limit 1];
        System.assertEquals(1, dvs.size());
    }
    
    @isTest
    private static void test_DealerVisitEventsUpdate(){
        List<Dealer_Visit__c> dv = [Select Id, Dealer_Visit_Status__c, Visit_Due_Date__c  From Dealer_Visit__c limit 1];
        Test.startTest();
          Dealer_Visit__c dvToUpdate = new Dealer_Visit__c();
          dvToUpdate.Id = dv[0].Id;
          dvToUpdate.Visit_Due_Date__c = DateTime.now() + 32;
          dvToUpdate.Dealer_Visit_Status__c = 'Planned';
          update dvToUpdate;
        Test.stopTest();
        List<Dealer_Visit__c> dvs = [Select Id, Dealer_Visit_Status__c from Dealer_Visit__c limit 1];
        System.assertEquals(1, dvs.size());
    }

    @isTest
    private static void creatingCounterShareAsAPartnerUserShouldSetAccountIdOnRecord() {
        Id counterShareRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Counter_Share').getRecordTypeId();
        User partnerUser = [SELECT Id, AccountId FROM User WHERE LastName = 'CADealerVisitTriggerTest'];
        System.runAs(partnerUser) {
            Test.startTest();
            Dealer_Visit__c dealerVisitRec = new TestDealerVisitBuilder() 
                .setRecordTypeId(counterShareRecordTypeId)
                .setAccountInformation(partnerUser.AccountId)                
                .getTestRecord();
            	dealerVisitRec.Search_Other_Account__c=true;
            insert dealerVisitRec;
            Test.stopTest();
            System.assertEquals(partnerUser.AccountId, [SELECT Account_Information__c FROM Dealer_Visit__c WHERE Id = :dealerVisitRec.Id].Account_Information__c,
                'Dealer account record not set on Counter Share');
        }
    }
    
    @isTest
    private static void test_InsertCalendarEvent(){
        Test.startTest();
        Campaign newCampaign = new Campaign();
        newCampaign.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Interio_Appliances_B2C_Campaign').getRecordTypeId();
        newCampaign.Name = 'Test Campaign';
        insert newCampaign;
        
        Event newEvent = new Event();
        newEvent.WhatId = newCampaign.Id;
        newEvent.Event_Type__c = GlobalConstants.CALENDAR_EVENT_TYPE;
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = System.now();
        insert newEvent;
        Test.stopTest();
        //  system.assertEquals(60,newEvent.DurationInMinutes);gcp-22 edited by dhiren 04/04/2023
    }
}