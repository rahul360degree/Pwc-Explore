@isTest
public class ServiceRequestApexSchedulerTest {
	@testsetup
    private static void testData() {
        Runtime_Execution__c runtimeExec = TestCustomSettingBuilder.generateRuntimeExecutionRecords(new List<String> {'FireAccountValidationRules__c', 'FireAccountWorkflowRules__c', 'FireCaseValidationRules__c'}, false,
                                                                                                    new List<String>{'AccountTriggerDisabled__c'}, true);
        insert runtimeExec;
        
         Account accountRecord = new Account(Name = 'TestB2B78',
                                            Industry = 'Apparel',
                                            Type = '3',
                                            Business_Unit__c = 'W',
                                            Account_Code__c = 'FDG2435',
                                            PAN__c = 'ABCDE1234Q');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
        insert accountRecord;
        
        accountRecord.IsPartner = true;
        update accountRecord;
        
        Contact contactRecord = new Contact(LastName = 'TestCon43',
                                           AccountId = accountRecord.Id);
        insert contactRecord;
        
        Case cs = new Case(AccountId = accountRecord.Id,
                           ContactId = contactRecord.Id,
                           Status = 'New',
                           Origin = 'Email',
                           Service_Request_Type__c = 'Repair',
                           Asset_Serial_Number__c = 'asv324',
                           Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_DRAFT
                          );
        cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Service_Request');
        insert cs; 
    }
    
    @isTest private static void testSchedular() {
        Test.StartTest();
        ServiceRequestApexScheduler scheduler = new ServiceRequestApexScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('service request Scheduler', sch, scheduler); 
        Test.stopTest();
   }
}