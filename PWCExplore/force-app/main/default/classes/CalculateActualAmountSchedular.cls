public without sharing class CalculateActualAmountSchedular Implements Schedulable{
    public void execute(SchedulableContext ctx) {
        //Error handling mechanism to default the batch size
        Integer batchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('CalculateOutstandingAmountSchedular').Batch_Size__c) != null){
            batchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('CalculateOutstandingAmountSchedular').Batch_Size__c);
        }   
        CalculateActuals calculator = new CalculateActuals(); 
        Database.executeBatch(calculator,batchSize);
    }
}