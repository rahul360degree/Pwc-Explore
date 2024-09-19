/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        Test method for changing account name tagged at opportunity
* History
* --------
* 06-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest(SeeAllData=false)
public with sharing class TestChangeAccountName {
    static testmethod void testChangeAccountName() {
        Id accoundId1 = LeaseTestDataFactory.createAccountFromName('Test Stetig');
        Id accoundId2 = LeaseTestDataFactory.createAccount();
        
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            Id contactId1 = LeaseTestDataFactory.createContact(accoundId1);
            Id oppId1 = LeaseTestDataFactory.createOpportunity(accoundId1);
            Id contactId2 = LeaseTestDataFactory.createContact(accoundId2);
            
            LeaseTestDataFactory.CreateHoT(oppId1);
            List<Account> accountList = [Select Id, Name from Account where Id =: accoundId2];
            system.assertEquals(accountList.size(), 1);
            changeAccountName.getAccounts(accountList[0].Name);
            
            changeAccountName.getOpportunityData(oppId1);
            
            changeAccountName.getContacts(accoundId2);
            
            changeAccountName.updateAccountName(oppId1, accoundId2, 'Testing for test class coverage', accoundId1, contactId2);
        }
        test.stopTest();
    }
}