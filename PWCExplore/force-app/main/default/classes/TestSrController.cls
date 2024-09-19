/*----------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for service request controller
 * History
 * --------
 * 08-12-2021     :    Initial Release
 * ----------------------------------------------------------------------*/
@isTest
Private with sharing class TestSrController {   
    static testmethod void test() {
   /*  test.StartTest();
       Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
       Id accoundId = LeaseTestDataFactory.createAccount('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {*/
   		 String csId = LeaseTestDataFactory.createCase();
   		 Test.startTest();
    
  	    PageReference pageRef = Page.Service_Req;
    	Test.setCurrentPage(pageRef);
    	ApexPages.currentPage().getParameters().put('srId',csId); 
   		SRController cs = new SRController();       
    	cs.getDetails();
        
	Test.stopTest();
    }     
}