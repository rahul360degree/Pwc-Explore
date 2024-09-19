/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Class to contains RecordTypeIds or Names to remove hardcoding
Inputs:        NA
-------------------------------------------------------------------------------
History
01-06-2020      Shailja      Initial Release
08-06-2020      Kartik       Singleton Framework responsible for returning recordtypeids 
----------------------------------------------------------------------------*/
public without sharing class RecordTypeUtils {
    private static RecordTypeUtils instance = null;
    private Map<String, Map<String, Id>> objectNameVSRecordTypeMap = new Map<String, Map<String, Id>>();

    private RecordTypeUtils() {
        createRecordTypeMap_ForObjects();
    }

    private void createRecordTypeMap_ForObjects() {
        Boolean positive = true;
        List<RecordType> recordTypes = [Select Id, DeveloperName, SobjectType  FROM RecordType WHERE IsActive = :positive LIMIT 9999];
        Map<String, List<RecordType>> sObjectVSRecordTypes = new Map<String, List<RecordType>>();
        // Get list of record types for a specific SobjectType.
        for(RecordType recordType : recordTypes) {
            List<RecordType> tempRecordTypes = new List<RecordType>();
            if(sObjectVSRecordTypes.containsKey((recordType.SobjectType).toUpperCase())) {
                tempRecordTypes = sObjectVSRecordTypes.get((recordType.SobjectType).toUpperCase());
            }
            tempRecordTypes.add(recordType);
            sObjectVSRecordTypes.put((recordType.SobjectType).toUpperCase(), tempRecordTypes);
        }

        // Convert the list of record types for specific sobject to a map where key is the developername of that record type.
        for(String key : sObjectVSRecordTypes.keySet()) {
            List<RecordType> tempRecordTypes = sObjectVSRecordTypes.get(key);
            Map<String, Id> developerNameVSRecordTypeId = new Map<String, Id>();
            for(RecordType recordType : tempRecordTypes) {
                developerNameVSRecordTypeId.put(recordType.DeveloperName, recordType.Id);
            }
            objectNameVSRecordTypeMap.put(key, developerNameVSRecordTypeId);
        }
    }

    // Method to get the id for specified record type name of specified object. 
    public Id getRecordTypeId(String objectName, String recordTypeDeveloperName) {
        if(objectNameVSRecordTypeMap.containsKey(objectName.toUpperCase()) && 
            objectNameVSRecordTypeMap.get(objectName.toUpperCase()).containsKey(recordTypeDeveloperName)) {
            return objectNameVSRecordTypeMap.get(objectName.toUpperCase()).get(recordTypeDeveloperName);
        }
        return null;
    }

    // Method to get the all the record types based on the specified sObject.
    public Map<String, Id> getRecordTypeIds(String objectName) {
        if(objectNameVSRecordTypeMap.containsKey(objectName.toUpperCase())) {
            return objectNameVSRecordTypeMap.get(objectName.toUpperCase());
        }
        return null;
    }

    // Singleton method.
    public static RecordTypeUtils getInstance() {
        if(instance == null) {
            instance = new RecordTypeUtils();
        }
        return instance;
    }
   
}