/* ================================================
* @class name: GenericBulkDeleteBatchTest
* @author: GITL (PSM)
* @purpose: To cover the test scenarios for GenericBulkDeleteBatch Class
* @created date (mm/dd/yyyy) : (07/07/2023)
================================================*/ 
@isTest
public class GenericBulkDeleteBatchTest {
/* ================================================
    * @method name: testDataSetup
    * @author: GITL (PSM)
    * @purpose: test data creation
    * @created date (mm/dd/yyyy) :(07/07/2023)
    ================================================*/
    @testSetup
    public static void testDataSetup(){
        list<Application_Log__c> lstApplLog=new list<Application_Log__c>();
        String userId = LeaseTestDataFactory.createAdminUser('GenericBulkDeleteBatchTest@godrej.com');
        User objUser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        System.runAs(objUser){
			for(integer i=0;i<10;i++){
            	Application_Log__c objApplLog=new Application_Log__c();
            	lstApplLog.add(objApplLog);
        	}
        	insert lstApplLog;
            system.debug('lstApplLog :'+lstApplLog);
            system.debug('lstApplLog.size() :'+lstApplLog.size());
        }
    }
    
    /* ========================================================
    * @method name : GenericBulkDeleteBatchExecute
    * @author : GITL (PSM)
    * @purpose: method to test GenericBulkDeleteBatch
    * @param : NA
    * @return: NA
    * @created date (mm/dd/yyyy) : 07/07/2023
    ===========================================================*/    
    @IsTest
    public static void GenericBulkDeleteBatchExecute(){
        User objUser = [SELECT Id, Name, Email FROM User WHERE username = 'GenericBulkDeleteBatchTest@godrej.com'];
        Integer intCountBefore = [select count() from Application_Log__c ];
        System.AssertEquals(intCountBefore,10);
        System.runAs(objUser){
        	Test.startTest();
            GenericBulkDeleteBatch objGenericBulkDeleteBatch = new GenericBulkDeleteBatch();//Run Purge Batch
            database.executeBatch(objGenericBulkDeleteBatch);
            Test.stopTest();
        }
        Integer intCountAfter = [select count() from Application_Log__c ];
        System.AssertEquals(intCountAfter,0);
    }
}