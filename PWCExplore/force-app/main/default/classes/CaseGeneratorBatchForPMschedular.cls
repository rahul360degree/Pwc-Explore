/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Schedular class to schedule batch class to create Case record for PM Visits.
Inputs:        
Test Class:   
----------------------------------------------------------------------------*/
public without sharing class CaseGeneratorBatchForPMschedular Implements Schedulable{

    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer caseCreatorBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('CaseGeneratorBatchForPMscheduling').Batch_Size__c) != null){
            caseCreatorBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('CaseGeneratorBatchForPMscheduling').Batch_Size__c);
        }
        
        List<AsyncApexJob> batchesInQueue =[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name= 'CaseGeneratorBatchForPMscheduling'  
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batchesInQueue.size()==0){                            
            CaseGeneratorBatchForPMscheduling caseCreator = new CaseGeneratorBatchForPMscheduling(); 
            Database.executeBatch(caseCreator,caseCreatorBatchSize);
        }
    }
}