/*----------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Scheduler for ReceivableAlertsBatch
 * Test Class    :        ReceivableAlertsBatchTest
 * History
 * --------
 * 19-10-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public without sharing class ReceivableAlertsScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        if (!Schema.sObjectType.AsyncApexJob.isAccessible()) {
            return;
        }
        // Schedule the job only if there's no "in progress" job already
        List<AsyncApexJob> batches = [SELECT Id
                                     FROM AsyncApexJob 
                                     WHERE JobType = 'BatchApex' And ApexClass.Name = :ReceivableAlertsBatch.class.getName()
                                           AND Status IN ('Holding','Queued','Preparing','Processing')];
        if (batches.size() == 0) {
            ReceivableAlertsBatch batchInst = new ReceivableAlertsBatch();
            // Error handling mechanism to default the batch size
            Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
            // Fetch Batch Size from Custom setting
            if(Apex_Batch_Configurations__c.getValues('ReceivableAlertsScheduler') != null){
                batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('ReceivableAlertsScheduler').Batch_Size__c);
            }
            Database.executeBatch(batchInst, batchSize);
        }
    }
}