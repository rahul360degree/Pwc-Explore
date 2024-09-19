/*------------------------------------------------------------------------
Author:        Deepali
Jira Story :   SMEPB 71
Description:   Scheduler to execute AutoCreateRenewalOpportunitiesBatch.
----------------------------------------------------------------------------*/
public without sharing class AutoRenewalScheduler Implements Schedulable{

    public void execute(SchedulableContext ctx) {
        
       //Error handling mechanism to default the batch size
        Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('AutoRenewalScheduler').Batch_Size__c) != null){
            batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('AutoRenewalScheduler').Batch_Size__c);
        }
        
        List<AsyncApexJob> batches=[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name='AutoCreateRenewalOpportunitiesBatch' 
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batches.size()==0){                            
            AutoCreateRenewalOpportunitiesBatch AutoRenewal = new AutoCreateRenewalOpportunitiesBatch(); 
            Database.executeBatch(AutoRenewal,batchSize);
        }
    }
}