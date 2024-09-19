/*---------------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method to create Premise traction record by using batch classes
 * History
 * --------
 * 09-12-2021     :    Initial Release
 * --------------------------------------------------------------------------------------------*/
@isTest
private class TestBatchCreatePT {

    @testsetup
    static void createTestData(){
        Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        Id contactId = LeaseTestDataFactory.createContact(accoundId);
        Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
        Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
        String PreT = LeaseTestDataFactory.tagPremiseWithStatusActive(hotId,oppId);
    }
    
    static testmethod void testBatchPT() {
    	test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
        BatchCreatePT bpt = new BatchCreatePT();
        database.executebatch(bpt);
        }        
        test.stopTest();
        
    }
}