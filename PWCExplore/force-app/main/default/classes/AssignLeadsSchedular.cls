/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   schedular to execute lead assignment batch.
Inputs:        
Test Class:   AssignLeadSchedularTest

History
11-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class AssignLeadsSchedular Implements Schedulable{

    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer assignerBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssignLeadsSchedular').Batch_Size__c) != null){
            assignerBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssignLeadsSchedular').Batch_Size__c);
        }
        
        List<AsyncApexJob> batches=[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name=:GlobalConstants.LEAD_ASSIGNER_BATCH_CLASS 
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batches.size()==0){                            
            AssignLeadsBatch assigner = new AssignLeadsBatch(); 
            Database.executeBatch(assigner,assignerBatchSize);
        }
    }
}