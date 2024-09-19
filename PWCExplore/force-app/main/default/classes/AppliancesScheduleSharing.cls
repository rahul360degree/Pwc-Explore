/*----------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Scheduler for AppliancesBatchSharing
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 30-05-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public without sharing class AppliancesScheduleSharing implements Schedulable {
    public void execute(SchedulableContext ctx) {
        List<AsyncApexJob> batches= [SELECT Id
                                     FROM AsyncApexJob 
                                     WHERE JobType = 'BatchApex' And ApexClass.Name = :AppliancesBatchSharing.class.getName()
                                           AND Status IN ('Holding','Queued','Preparing','Processing')];
        if (batches.size() == 0) {
            AppliancesBatchSharing batchInst = new AppliancesBatchSharing();
            //Error handling mechanism to default the batch size
            Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
            //Fetch Batch Size from Custom setting
            if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('AppliancesScheduleSharing').Batch_Size__c) != null){
                batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('AppliancesScheduleSharing').Batch_Size__c);
            }
            Database.executeBatch(batchInst, batchSize);
        }
    }
}