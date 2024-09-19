/*-----------------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for schedulable batch to creating premise traction record
 * History
 * --------
 * 09-12-2021     :    Initial Release
 * -----------------------------------------------------------------------------------------------*/
@isTest
private class TestScheduableBatchCreatePT {

    @testsetup
    static void createTestData(){
        Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        Id contactId = LeaseTestDataFactory.createContact(accoundId);
        Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
        Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
        String PreT = LeaseTestDataFactory.tagPremiseWithStatusActive(hotId,oppId);
    }
    
    static testMethod void testschedule() {
		
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
		ScheduleBatchCreatePT sbpt = new ScheduleBatchCreatePT();
        test.StartTest();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, sbpt );
        }    
		Test.stopTest();
	}
    
}