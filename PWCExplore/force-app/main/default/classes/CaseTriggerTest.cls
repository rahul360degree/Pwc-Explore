/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test methods for different scenario of case
 * History
 * --------
 * 09-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
private class CaseTriggerTest {
    @testsetup
    private static void testData() {
        Runtime_Execution__c orgInst = new Runtime_Execution__c(SetupOwnerId = UserInfo.getOrganizationId(), AccountTriggerDisabled__c = true,
            FireAccountValidationRules__c = false, FireAccountWorkflowRules__c = false, FireCaseValidationRules__c = false);
        insert orgInst;
        Account accountRecord = new Account(Name = 'TestB2B78',
                                            Industry = 'Apparel',
                                            Type = '3',
                                            Business_Unit__c = 'W',
                                            Account_Code__c = 'FDG2435',
                                            PAN__c = 'AGFRR1254G');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
        insert accountRecord;
        
        accountRecord.IsPartner = true;
        update accountRecord;
        
        Contact contactRecord = new Contact(LastName = 'TestCon43',
                                           AccountId = accountRecord.Id,
                                           Phone = '9874562135');
        insert contactRecord;
    }
    
    @isTest
    private static void testInValidRequestTypeForDealer(){
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        Test.startTest();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Email',
                           Service_Request_Type__c = 'Install and Demo'
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Service_Request');
        try{
            Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator()); 
            insert cs;
        }Catch(Exception ex){
            System.assert(ex.getMessage().contains('Service Request can be created for type'));
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testValidRequestTypeForDealer(){
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        Test.startTest();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Email',
                           Service_Request_Type__c = 'Repair',
                           Asset_Serial_Number__c = 'asv324'
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Service_Request');
        Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator()); 
        insert cs; 
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    } 
    
    @isTest
    private static void testInValidRequestTypeForDealerOnCaseUpdate(){
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        Test.startTest();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Email',
                           Service_Request_Type__c = 'Repair',
                           Asset_Serial_Number__c = 'asv322'
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Service_Request');
        Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator()); 
        insert cs; 
        
        Case csToUpdate = new Case(Id = cs.Id,
                                   Service_Request_Type__c = 'Install and Demo');
        try{
            update csToUpdate;
        }Catch(Exception ex){
            System.assert(ex.getMessage().contains('Service Request can be created for type'));
        }
        Test.stopTest();
    } 
    
    @isTest
    private static void testPopulateDefaultsfromItemCode(){
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        Test.startTest();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Email',
                           Service_Request_Type__c = 'Repair',
                           Asset_Serial_Number__c = 'asv322',
                           Item_Code__c = '34534636'
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Service_Request');
        Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator()); 
        insert cs; 
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
    
  @isTest
    	private static void testSendSMSNotificationCreateServiceRequest(){
            
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        //Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) { 
            
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        //Test.startTest();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Phone',
                           Type = 'IT Park',
                           Leasing_Case_Category__c ='Elevator',
						   Sub_Category__c ='MAN TRAPPED IN LIFT'
                          // Service_Request_Type__c = 'Repair',
                          // Asset_Serial_Number__c = 'asv322',
                          // Item_Code__c = '34534636'
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Leasing_B2B_Service');
        Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator());   
        insert cs; 
        }    
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
    
    @isTest
    	private static void testCalculateTimeOnCase(){
       
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        //Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {   
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.CaseTriggerDisabled__c = true;
        insert setting; 
            
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        Id serviceRecordTypeId = Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.CASE_RECORD_TYPE_LEASING).getRecordTypeId();
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Phone',
                           Type = 'IT Park',
                           Leasing_Case_Category__c ='Elevator',
						   Sub_Category__c ='MAN TRAPPED IN LIFT'                        
                          );
        cs.RecordTypeId = serviceRecordTypeId;
        Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator()); 
             test.StartTest();
        insert cs; 
        //Test.startTest();
        cs.Status = 'Wip';
        update cs;   
        }   
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
    
    @isTest
    	private static void testSendSMSNotificationUpdateServiceRequest(){
            
         Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        //Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {    
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Phone',
                           Type = 'IT Park',
                           Leasing_Case_Category__c ='Elevator',
						   Sub_Category__c ='MAN TRAPPED IN LIFT'                        
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Leasing_B2B_Service');
            Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator());  
        insert cs; 
        Test.startTest();
        cs.Status = 'Assigned';
        cs.Job_assigned_to__c = userInfo.getUserId();
       // cs.OwnerId = u.id;     
        update cs;    
        }    
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
    
    @isTest
    	private static void testSendSMSNotificationClosedServiceRequest(){
       //  test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        //Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {    
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Phone',
                           Type = 'IT Park',
                           Leasing_Case_Category__c ='Elevator',
						   Sub_Category__c ='MAN TRAPPED IN LIFT'                        
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Leasing_B2B_Service');
            Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator());  
        insert cs; 
        Test.startTest();
        cs.Status = 'Closed';
        //cs.Job_assigned_to__c = userInfo.getUserId();
        update cs;    
        }    
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
    
    @isTest
    	private static void testSendSMSNotificationStatusChaneServiceRequest(){
       
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        //Id accoundId = LeaseTestDataFactory.createAccountFromName('Test Stetig Consultancy Bill');
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {     
        Account acc = [Select Id From Account where IsPartner = true limit 1];
        Contact con = [Select Id From Contact where AccountId =: acc.Id limit 1];
        
        Case cs = new Case(AccountId = acc.Id,
                           ContactId = con.Id,
                           Status = 'New',
                           Origin = 'Phone',
                           Type = 'IT Park',
                           Leasing_Case_Category__c ='Elevator',
						   Sub_Category__c ='MAN TRAPPED IN LIFT'                        
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Leasing_B2B_Service');
            Test.setMock(HttpCalloutMock.class, new MockSMSResponseGenerator());  
        insert cs; 
        Test.startTest();
        cs.Status = 'on hold';
        cs.Job_assigned_to__c = userInfo.getUserId();
        update cs;    
        }    
        Test.stopTest();
        System.assert([Select Id from Case limit 1].size() > 0);
    }
}