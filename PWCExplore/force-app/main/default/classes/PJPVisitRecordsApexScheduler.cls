global class PJPVisitRecordsApexScheduler implements Schedulable {
    global void execute(SchedulableContext sc){
        PJPVisitRecordsBatch batch = new PJPVisitRecordsBatch();
		Database.executeBatch(batch);
    } 
}