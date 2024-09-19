/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   schedular to execute zip code rule rest batch.
Inputs:        
Test Class:   

History
11-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ResetZipCodeRuleBatchSchedular Implements Schedulable{
    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('ResetZipCodeRuleBatchSchedular').Batch_Size__c) != null){
            batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('ResetZipCodeRuleBatchSchedular').Batch_Size__c);
        }
        
        ResetZipCodeRuleBatch ruleReset = new ResetZipCodeRuleBatch(); 
        Database.executeBatch(ruleReset);
    }
}