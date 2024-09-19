global class GeneratePJPApexScheduler Implements Schedulable{
    global void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer pjpBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('GeneratePJPApexScheduler').Batch_Size__c) != null){
            pjpBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('GeneratePJPApexScheduler').Batch_Size__c);
        }
        GeneratePJPBatch b = new GeneratePJPBatch();
        database.executebatch(b, pjpBatchSize);
    }
}