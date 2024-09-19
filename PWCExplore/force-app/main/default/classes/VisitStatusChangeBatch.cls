global class VisitStatusChangeBatch implements Database.Batchable<sObject>,Schedulable {
    global void execute(SchedulableContext sc)
    {
        VisitStatusChangeBatch b = new VisitStatusChangeBatch(); // Your batch class
        database.executeBatch(b,300);
    }
    List<Visit__c> updateVisits = new List<Visit__c>();
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id,Status__c from Visit__c where Status__c != 'Completed' and Name='statuschangetest']);
    }
    global void execute(Database.BatchableContext BC, List<Visit__c> scope){
        system.debug('data'+scope);
        for(Visit__c listOfNotCompletedVisits : scope){
            listOfNotCompletedVisits.Status__c = 'Not Executed';
            updateVisits.add(listOfNotCompletedVisits);
        }
        if(!updateVisits.isEmpty()){
            system.debug('updateVisits'+updateVisits);
            Update updateVisits;
        }
    }
    global void finish(Database.BatchableContext BC){
        system.debug('finish');
    }
}