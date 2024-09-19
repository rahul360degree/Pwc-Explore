public with sharing class GVLC_QR_Code_Scheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Integer noOfAssest = [SELECT COUNT() FROM Asset WHERE Status = 'Pending QR Codes' AND QR_Code__c != NULL];
        if(noOfAssest > 0) {
            Database.executeBatch(new GVLC_QR_Code_Batch(), 20);
        }
    }
}