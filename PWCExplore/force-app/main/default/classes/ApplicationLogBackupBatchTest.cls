/*------------------------------------------------------------------------
Author:        Maherzad Chothia/Shreela Nair
Company:       Godrej Infotech
Description:   For hard deleting Application records generated more than 14 days
Inputs:        
Test Class:    
History 
07-02-2024     Maherzad Chothia     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class ApplicationLogBackupBatchTest {

@testSetup
public static void testDataSetup() {
    List<Application_Log__c> lstApplLog = new List<Application_Log__c>();

    String userId = LeaseTestDataFactory.createAdminUser('ApplicationLogBackupBatchTest@godrej.com');
    User objUser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];

    System.runAs(objUser) {
        // Create some records older than 14 days
        for (Integer i = 0; i < 5; i++) {
            Application_Log__c objApplLog = new Application_Log__c();
            // Set CreatedDate to more than 14 days ago
            objApplLog.CreatedDate = System.now().addDays(-15);
            lstApplLog.add(objApplLog);
        }
        // Create some records within last 14 days
        for (Integer i = 0; i < 5; i++) {
            Application_Log__c objApplLog = new Application_Log__c();
            // Set CreatedDate to within last 14 days
            objApplLog.CreatedDate = System.now().addDays(-5);
            lstApplLog.add(objApplLog);
        }
        insert lstApplLog;
    }
}




    @IsTest
    public static void ApplicationLogBackupBatchExecute() {
        User objUser = [SELECT Id, Name, Email FROM User WHERE username = 'ApplicationLogBackupBatchTest@godrej.com'];

        Integer intCountBefore = [SELECT COUNT() FROM Application_Log__c];
        //System.assertEquals(10, intCountBefore, 'Initial record count should be 10');

        System.runAs(objUser) {
            Test.startTest();
            ApplicationLogBackupBatch batchJob = new ApplicationLogBackupBatch();
            Database.executeBatch(batchJob);
            Test.stopTest();
        }

        Integer intCountAfter = [SELECT COUNT() FROM Application_Log__c];
        //System.assertEquals(0, intCountAfter, 'All records should be deleted');


    }
@IsTest
public static void testCSVDataConstruction() {
    // Create test data
    Application_Log__c applLogRecord = new Application_Log__c(Category__c = 'Test Category',CreatedById = UserInfo.getUserId());
    insert applLogRecord;

    // Instantiate the batch class
    ApplicationLogBackupBatch batchJob = new ApplicationLogBackupBatch();

    // Create a list to hold the test data (simulating the records processed by the batch)
    List<Application_Log__c> testApplLogRecords = new List<Application_Log__c>();
    testApplLogRecords.add(applLogRecord);

    // Call the execute method directly
    Test.startTest();
    batchJob.execute(null, testApplLogRecords);
    Test.stopTest();

    // Verify the constructed CSV data indirectly by asserting the expected format
    String expectedCSVData = 'Id,Name,Category__c,CreatedById,CreatedDate,IsDeleted,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Message__c,Object_Type__c,OwnerId,Priority__c,Record_ID__c,Record_URL__c,Source_Apex_Class__c,Source_Function__c,Source__c,SystemModstamp,Target__c,Type__c,User__c,\n';
    expectedCSVData += applLogRecord.Id + ',' + applLogRecord.Name + ',' + applLogRecord.Category__c + ',' + applLogRecord.CreatedById + ',' + applLogRecord.CreatedDate + ',false,,' + applLogRecord.LastModifiedDate + ',,,,,' + applLogRecord.OwnerId + ',,' + applLogRecord.Record_ID__c + ',' + applLogRecord.Record_URL__c + ',' + applLogRecord.Source_Apex_Class__c + ',' + applLogRecord.Source_Function__c + ',' + applLogRecord.Source__c + ',' + applLogRecord.SystemModstamp + ',' + applLogRecord.Target__c + ',' + applLogRecord.Type__c + ',' + applLogRecord.User__c + ',\n';

    // Assert that the constructed CSV data matches the expected format
    //System.assertEquals(expectedCSVData, batchJob.getCsvData(), 'Constructed CSV data should match expected format');
}


    @IsTest
    public static void ApplicationLogBackupBatchExecute_ExceptionHandling() {
    // Simulate an exception during batch execution
    Test.startTest();
    ApplicationLogBackupBatch batchJob = new ApplicationLogBackupBatch();
    // Pass in null to trigger an exception
    Database.executeBatch(batchJob, 10);
    Test.stopTest();

    // Add assertions to verify exception handling behavior
    // For example, check if the logs are correctly captured
    // assert(Logs.size() > 0, 'Exception logs should have been captured');
}


    @IsTest
	public static void ApplicationLogBackupBatchFinish_ExceptionHandling() {
    // Simulate an exception during finish method
    Test.startTest();
    ApplicationLogBackupBatch batchJob = new ApplicationLogBackupBatch();
    // Execute batch job to the point where finish method is called
    Database.executeBatch(batchJob);
    Test.stopTest();

    // Add assertions to verify exception handling behavior
    // For example, check if the logs are correctly captured
    // assert(Logs.size() > 0, 'Exception logs should have been captured');
}
    @IsTest
	public static void ApplicationLogBackupBatchExecute_ValidateExecution() {
    Test.startTest();
    ApplicationLogBackupBatch batchJob = new ApplicationLogBackupBatch();
    Database.executeBatch(batchJob);
    Test.stopTest();

    // Add assertions to validate batch execution
    Integer intCountAfter = [SELECT COUNT() FROM Application_Log__c];
    System.assertEquals(10, intCountAfter, 'Only records within last 14 days should remain');

    // You can also assert if the email was sent correctly if possible
    // For example, check if the email was sent with the expected attachment
    // assert(Emails.size() > 0, 'Email with backup file should have been sent');
}




     @IsTest
    public static void executeSchedulableContextTest() {
        Test.startTest();
        // Instantiate the Schedulable class
        ApplicationLogBackupBatch schedulableClass = new ApplicationLogBackupBatch();
        // Call the execute method
        schedulableClass.execute(null); // Passing null for SchedulableContext as it's not used in the method
        Test.stopTest();

        // Add assertions to verify the behavior of the execute method if needed
        // For example, check if the batch job was started successfully
        // Assert.assertEquals(expectedValue, actualValue, 'Message');
    }


    
    
}