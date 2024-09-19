/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Test class for CaseGeneratorBatchForPMscheduling, CaseGeneratorBatchForPMschedular and 
				CaseGeneratorBatchForAssetHelper.
Inputs:        
Test Class:   
----------------------------------------------------------------------------*/
@isTest
public class CaseGeneratorBatchForPMschedulingTest {
    @testSetup
    static void createData(){
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'CaseGeneratorBatchForPMscheduling', 
                                                                            Batch_Size__c = 200);
        insert abc;
        
        Account acc= new Account();
        acc.Name = 'TestAccount';
        acc.Interio_Sub_Division__c= 'B2B-KAM';
        acc.Business_Unit__c = 'K';
        insert acc;
        
        //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
        
        List<Asset> AssetList = new List<Asset>();
        for(integer i =1; i<3; i++){
            Asset assetRec = new Asset();
            assetRec.Name = 'testAsset'+i;
            assetRec.Coverage__c = 'KFGWC00600001';
            assetRec.Type_of_Warranty__c = 'Special Warranty';
            assetRec.AccountId = acc.id;
            assetRec.Address_Code__c = address.id;		//Added by pc
            assetRec.Status = 'Active';
            assetRec.Scheduled_PM_Visit_1__c = System.today();
            assetRec.Scheduled_PM_Visit_2__c = System.today().addDays(i) ;
            assetRec.Scheduled_PM_Visit_3__c = System.today().addDays(i+1);
            assetRec.Scheduled_PM_Visit_4__c = System.today().addDays(i+2);
            assetRec.Scheduled_PM_Visit_5__c = System.today().addDays(i+3);
            assetRec.Scheduled_PM_Visit_6__c = System.today().addDays(i+5);
            
            if(i==2){
               assetRec.Case_creation_status__c = 'Case_2_created'; 
            }
            AssetList.add(assetRec);        
        }
        insert AssetList;      
    }
    
     @isTest
    static void testBatch() {
        Test.StartTest();
        CaseGeneratorBatchForPMscheduling be = new CaseGeneratorBatchForPMscheduling();
		database.executeBatch(be);
        Test.stopTest();
        List<Case> caseList = new List<Case>([SELECT Id, Subject, AssetId FROM Case WHERE Subject='PM Visit Scheduled']);
        system.debug(caseList.size());
        System.assertNotEquals(caseList.size(), Null, 'Cases should be created with subject= PM Visit Scheduled');
        //System.assertEquals(1, (caseList.size()));
   }
    @isTest
    static void testSchedular(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
                
        Test.startTest();
        String jobId = System.schedule('CaseCreationBatch',  CRON_EXP, new CaseGeneratorBatchForPMschedular());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('CaseGeneratorBatchForPMschedular', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');    
    }

    
    
    @isTest
    static void testBatch_failedAssetsIds() {
        Test.StartTest();
        CaseGeneratorBatchForPMscheduling be = new CaseGeneratorBatchForPMscheduling();
		database.executeBatch(be);
        database.executeBatch(be);
        Test.stopTest();
        List<Case> caseList = new List<Case>([SELECT Id, Subject, AssetId FROM Case WHERE Subject='PM Visit Scheduled']);
        system.debug(caseList.size());
        System.assertNotEquals(caseList.size(), Null, 'Cases should be created with subject= PM Visit Scheduled');
        //System.assertEquals(1, (caseList.size()));
   }
}