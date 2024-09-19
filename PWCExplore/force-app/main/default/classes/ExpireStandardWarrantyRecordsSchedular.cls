/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Schedular class to schedule batch class to expire standard warranty record for an Asset 
				whose End date is already lapsed.
Inputs:        
Test Class:   
----------------------------------------------------------------------------*/
public class ExpireStandardWarrantyRecordsSchedular Implements Schedulable {
    
    public void execute(SchedulableContext ctx){
        //Error handling mechanism to default the batch size
        Integer caseCreatorBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('ExpireStandardWarrantyRecordsBatch').Batch_Size__c) != null){
            caseCreatorBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('ExpireStandardWarrantyRecordsBatch').Batch_Size__c);
        }
        List<AsyncApexJob> batchesInQueue =[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name= 'ExpireStandardWarrantyRecordsBatch'  
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batchesInQueue.size()==0){                            
            ExpireStandardWarrantyRecordsBatch deleteStandardWarrentyRecord = new ExpireStandardWarrantyRecordsBatch(); 
            Database.executeBatch(deleteStandardWarrentyRecord,caseCreatorBatchSize);
        }        
        
    }

}