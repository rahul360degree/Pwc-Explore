/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Schedular class to schedule batch class to expire service contracts.
Inputs:        
Test Class:  
----------------------------------------------------------------------------*/
public class ExpireServiceContractBatchSchedular Implements Schedulable {
        public void execute(SchedulableContext ctx){
        //Error handling mechanism to default the batch size
        Integer serviceContractBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('ExpireServiceContractBatch').Batch_Size__c) != null){
            serviceContractBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('ExpireServiceContractBatch').Batch_Size__c);
        }
        List<AsyncApexJob> batchesInQueue =[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name= 'ExpireServiceContractBatch'  
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batchesInQueue.size()==0){                            
            ExpireServiceContractBatch expireServiceContract = new ExpireServiceContractBatch(); 
            Database.executeBatch(expireServiceContract,serviceContractBatchSize);
        }        
        
    }

}