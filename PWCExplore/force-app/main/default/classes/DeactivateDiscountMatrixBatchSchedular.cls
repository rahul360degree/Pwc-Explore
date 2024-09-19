/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   schedular to execute DeactivateDiscountMatrix batch.
Inputs:        
Test Class:   DeactivateDiscountMatrixSchedulerTest

History
11-08-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class DeactivateDiscountMatrixBatchSchedular Implements Schedulable{
    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('DeactivateDiscountMatrixBatchSchedular').Batch_Size__c) != null){
            batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('DeactivateDiscountMatrixBatchSchedular').Batch_Size__c);
        }
        
        DeactivateDiscountMatrixBatch deactivateMatrix = new DeactivateDiscountMatrixBatch(); 
        Database.executeBatch(deactivateMatrix,batchSize);
    }
}