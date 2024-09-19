@isTest
public class ExpireStandardWarrantyRecordsBatchTest {
    @testSetup
    static void createData(){
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'ExpireStandardWarrantyRecordsBatch', 
                                                                            Batch_Size__c = 200);
        insert abc;
        
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount.Business_Unit__c = 'K';
        insert newAccount;
        
        Plan__c standardPlan = new Plan__c();
        standardPlan.Name = 'Standard Warrenty Plan';
        standardPlan.Is_Active__c= true;
        standardPlan.Plan_Type__c = 'Basic';
        standardPlan.Is_Standard_Plan__c = true; 
        insert standardPlan;
        
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
        
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Purchased';
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addDays(-1);
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Coverage__c = 'KFGWC00600001';
        newAsset.Address_Code__c = address.id;		//Added by pc
        insert newAsset;

        Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
        newAssetBenefit.Name = 'Test Asset_Benefit';
        newAssetBenefit.Asset__c = newAsset.id;
        newAssetBenefit.Is_Active__c = true;
        newAssetBenefit.Plan__c = standardPlan.id;
        insert newAssetBenefit;       
    }
    
    @isTest
    static void testBatch() {
        Test.StartTest();
        ExpireStandardWarrantyRecordsBatch be = new ExpireStandardWarrantyRecordsBatch();
		database.executeBatch(be);
        Test.stopTest();
        Asset_Benefit__c testAssetBenefit = [Select Id, Name, Is_Active__c FROM Asset_Benefit__c where Name = 'Test Asset_Benefit' LIMIT 1];
        System.assertEquals(testAssetBenefit.Is_Active__c, false);
    }
    
    
    @isTest
    static void testSchedular(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
                
        Test.startTest();
        String jobId = System.schedule('CaseCreationBatch',  CRON_EXP, new ExpireStandardWarrantyRecordsSchedular());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('ExpireStandardWarrantyRecordsSchedular', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job'); 
    }
    

}