/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Class to delete content documents
Inputs:        NA
Test Class:   
---------------------------------------------------------------------------
History
02-02-2021      Shailja Mishra     Initial Release
----------------------------------------------------------------------------*/
public without sharing class DeletePastContentDocumentsBatch implements Database.Batchable<sObject>, Database.Stateful {
    String QUERY; 
    String sObjectApiName = GlobalConstants.ATTENDANCE_SOBJECT_API_NAME;
    Set<String> sObjectFields = new Set<String>{'Id', 'CreatedDate'};
    List<Application_Settings__mdt> applicationSettings = new List<Application_Settings__mdt>();
    
    public DeletePastContentDocumentsBatch() {
        Integer defaultDayCount = 45;
        for (Application_Settings__mdt each : [Select Id, Value__c From Application_Settings__mdt Where DeveloperName = 'Last_N_Days_To_Delete_Content_Documents']) {
            defaultDayCount = Integer.valueOf(each.Value__c);
        }
        QUERY = QueryBuilder.build(sObjectApiName, sObjectFields, ' CreatedDate < LAST_N_DAYS:' + defaultDayCount + ' ');
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(QUERY);
    }
    public Void execute(Database.BatchableContext bc, List<sObject> records){
        deleteAttendanceFiles(records);
    }
    public Void finish(Database.BatchableContext bc) {}
     
    private void deleteAttendanceFiles(List<sObject> records){
        List<ContentDocument> contentDocsToDelete = new List<ContentDocument>();
        Set<Id> recordIds = new Set<Id>();
        for(sObject record : records){
            recordIds.add(record.Id);
        }
        for(ContentDocumentLink iterator : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :recordIds]){
            contentDocsToDelete.add(new ContentDocument(Id = iterator.ContentDocumentId));
        }
        if(!contentDocsToDelete.isEmpty() && contentDocsToDelete != null) {
            ContentDocumentTriggerHandler.TriggerDisabled = true;
            try{
                Database.delete(contentDocsToDelete, false);
                Database.emptyRecycleBin(contentDocsToDelete);
            }catch(Exception ex){
                Logger.logError('Past Content Document Deletion', 'DeletePastContentDocumentsBatch', 'deleteAttendanceFiles', '', ex);
            }
        }
    }
}