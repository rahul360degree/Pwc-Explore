/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   schedular to execute AssetBenifitBestValueBatch.
Inputs:        
Test Class:   

History
12-16-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AssetBenifitBestValueScheduler Implements Schedulable {
   public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer assignerBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssetBenifitBestValueScheduler').Batch_Size__c) != null){
            assignerBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssetBenifitBestValueScheduler').Batch_Size__c);
        }
        
        
            AssetBenifitBestValueBatch assigner = new AssetBenifitBestValueBatch(); 
            Database.executeBatch(assigner,assignerBatchSize);
    }
}