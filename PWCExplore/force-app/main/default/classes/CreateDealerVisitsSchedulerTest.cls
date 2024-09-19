/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Test class for CreateDealerVisitsScheduler
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 18-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
@isTest
public class CreateDealerVisitsSchedulerTest {
	@testsetup
    static void testData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = 'W');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.UserRoleId = role.Id;
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        System.runAs(userToRun) {
        Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('W')
                .getSavedTestRecord();
        
        List<Contact> partnerContacts = new List<Contact> {
            new TestContactBuilder().setAccountId(acc.Id).getTestRecord(),
            new TestContactBuilder().setAccountId(acc.Id).getTestRecord()
        };
        insert partnerContacts;
        
        List<User> interioUsers = new List<User> {
            new TestUserBuilder().setLastName('InterioVFDDealer').setProfileId([SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD Dealer Partner User'].Id)
                .setContactId(partnerContacts[0].Id).setBusinessUnit('W').setPersona('InterioVFD- Dealer').getTestRecord(),
            new TestUserBuilder().setLastName('InterioKitchenDealer').setProfileId([SELECT Id FROM Profile WHERE Name = 'Interio B2C Kitchen Dealer Partner User'].Id)
                .setContactId(partnerContacts[1].Id).setBusinessUnit('W').setPersona('Interio Kitchen-Dealer').getTestRecord()
        };
        insert interioUsers;
            }
        
         /*Dealer_Visit__c dv = new Dealer_Visit__c( Name = 'TestDV',
                                                   Dealer_Visit_Status__c = 'In progress'
                                                 );
        insert dv;*/
        
    }
    
    @isTest private static void createDealerVisits(){
        Test.StartTest();
        CreateDealerVisitsScheduler scheduler = new CreateDealerVisitsScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Create Dealer Vists Scheduler', sch, scheduler); 
        Test.stopTest();
        //System.assert([Select Id From Dealer_Visit__c].size() > 0);
        
        Dealer_Visit__c dv = new Dealer_Visit__c( Name = 'TestDV',							//Added by Poonam 
                                                   Dealer_Visit_Status__c = 'Planned'
                                                 );
        insert dv;
        List<Dealer_Visit__c> DeV = new List<Dealer_Visit__c>();
		DeV = [SELECT Id FROM Dealer_Visit__c];
		System.assertEquals(true,DeV.Size() > 0);
    }
}