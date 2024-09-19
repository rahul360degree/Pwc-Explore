/*-----------------------------------------------------------------------------------
 * Author        :        Kishor Kumar
 * Company       :        Salesforce
 * Description   :        Schedular class to schedule Batch job to purge unused Plan Benefit records
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 24-11-2020      Kishor Kumar     Initial Release
 * ---------------------------------------------------------------------------------*/
public without sharing class UnusedAssetBenefitPurgerBatchSchedular Implements Schedulable{
	
    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer assetBenefitPurgerBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('UnusedAssetBenefitPurgerBatchSize').Batch_Size__c) != null){
            assetBenefitPurgerBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('UnusedAssetBenefitPurgerBatchSize').Batch_Size__c);
        }
        
        List<AsyncApexJob> batches=[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name=:GlobalConstants.ASSET_BENEFIT_PURGER_BATCH_CLASS 
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batches.size() == 0){                            
            UnusedAssetBenefitPurgerBatch purgerBatch = new UnusedAssetBenefitPurgerBatch();  
            Database.executeBatch(purgerBatch, assetBenefitPurgerBatchSize);
        }
    }
}