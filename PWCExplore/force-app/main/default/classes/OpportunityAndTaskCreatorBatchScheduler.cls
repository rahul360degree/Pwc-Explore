/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Scheduler class to Schedule OpportunityAndTaskCreatorBatchForCP Batch.
			*Batch should create Opportunity record after 5 Years from Manufacturing Date
			*Batch should create Task record after 2 years from Manufacturing Date
Inputs:        
Test Class:   OptyAndTaskCreatorBatchSchedulerTest

History
13-08-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
global class OpportunityAndTaskCreatorBatchScheduler Implements Schedulable{
	
    global void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer cpBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('OpportunityAndTaskCreatorBatch').Batch_Size__c) != null){
            cpBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('OpportunityAndTaskCreatorBatch').Batch_Size__c);
        }
        OpportunityAndTaskCreatorBatchForCP cpBatch = new OpportunityAndTaskCreatorBatchForCP();
        database.executebatch(cpBatch, cpBatchSize);
    }
}