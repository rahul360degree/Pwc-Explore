public with sharing class GVLC_Product_Scheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Integer noOfAssest = [SELECT COUNT() FROM Asset WHERE Status = 'Pending QR Codes' AND QR_Code__c != NULL];
        if(noOfAssest > 0) {
            Database.executeBatch(new GVLC_Product_Batch(), 20);
        }
    }
}