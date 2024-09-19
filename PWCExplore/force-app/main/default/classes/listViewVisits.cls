public class listViewVisits {
    @AuraEnabled(cacheable=true)
    public static List<Visit__c> getrecords(id pjprecordid){
        List<Visit__c> records = new List<Visit__c>();
        records = [Select Id,Name,Visit_Planned_Date__c from Visit__c where PJP__c =: pjprecordid];
        system.debug(records);
        return records;
    }
}