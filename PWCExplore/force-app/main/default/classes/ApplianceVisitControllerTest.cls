/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 10-25-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   10-25-2023   Varun Rajpoot   Initial Version
**/
@isTest
public with sharing class ApplianceVisitControllerTest {
    @testsetup
    private static void testData() {
        Id displayShareRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId();

        Account accountRecord = new TestAccountBuilder()
        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
        .setBusinessUnit(GlobalConstants.APPLIANCE_BUSINESS_UNIT)
        .getSavedTestRecord();   


        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accountRecord.Id;
        atm.TeamMemberRole = 'Visual Merchandiser';
        atm.UserId = userinfo.getUserId();
        insert atm;

        
    }

    @isTest
    private static void test_DealerVisitEventsInsert(){
        List<Account> acc = [Select Id From Account limit 1];

        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25389')
            .setPersona(GlobalConstants.const_engineer_persona)
            .getSavedTestRecord();

        System.runAs(contextuser){
            Test.startTest();
            
            PJP__c pjp = new PJP__c(Name = 'TestPJP');
            ApplianceVisitController.createPJP(pjp);

            ApplianceVisitController.getVisitRecordConfig();
            ApplianceVisitController.getAccountTeamMember();
            
            Id displayShareRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId();
            Account accountRecord = [Select Id from Account limit 1];
			accountRecord.OwnerId = contextuser.id; 
            
            Dealer_Visit__c dealerVisitRec = new TestDealerVisitBuilder() 
            .setRecordTypeId(displayShareRecordTypeId)
            .setAccountInformation(accountRecord.Id)               
            .getTestRecord();           
            dealerVisitRec.Search_Other_Account__c=true;
            

            ApplianceVisitController.createVisits(new List<Dealer_Visit__c>{dealerVisitRec});

            ApplianceVisitController.getUserDetail();

            try{
                ApplianceVisitController.createPJP( new PJP__c(Name = 'TestPJP'));
            }catch(Exception ex){

            }

            try{
                dealerVisitRec.View_All_Accounts__c=false;
                ApplianceVisitController.createVisits(new List<Dealer_Visit__c>{dealerVisitRec});
            }catch(Exception ex){

            }

            Test.stopTest();
            
        }
    }


}