public with sharing class UploadFilesMetaDataController {
    @AuraEnabled(cacheable=true)
    public static List<UploadFilesCheckList__mdt> fetchMetaData(String label) {
       // List<UploadFilesCheckList__mdt> checklist=new List<UploadFilesCheckList__mdt>();
        //checklist=[SELECT RequiredDocuments__c,Related_Object__c,DocumentName__c,Business_Unit__c FROM UploadFilesCheckList__mdt];
return [SELECT RequiredDocuments__c,Related_Object__c,DocumentName__c,Business_Unit__c FROM UploadFilesCheckList__mdt WHERE Label=:label];
    }

    @AuraEnabled(cacheable=true)
    public static List<UploadFilesCheckList__mdt> mdtLabelList(String BU, String objectApiName){
        String sTerm='('+BU+')';
        if(BU=='Gen'){
            throw new IllegalArgumentException('Invalid Business Unit please check');
        }
        else{             
            return [SELECT label FROM UploadFilesCheckList__mdt WHERE label LIKE :sTerm+'%' AND Related_Object__c =: objectApiName];
        }
        
    }

    @AuraEnabled(cacheable=false)
    public static void updateContentVersionRecs(List<String> conVerRecIds, String documentType){
        List<ContentVersion> conVerUpdateList = new List<ContentVersion>();
        try {
            for(ContentVersion conVerRec : [SELECT Id, Document_Name__c FROM ContentVersion WHERE Id IN :conVerRecIds]) {
                conVerRec.Document_Name__c = documentType;
                conVerUpdateList.add(conVerRec);
            }
            if(conVerUpdateList.size() > 0) {
                system.debug('converupdate list'+conVerUpdateList);
                update conVerUpdateList;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable='true')
    public static List<ContentVersion> getDocuments(String rId){
        Set<Id> conDocIdSet = new Set<Id>();
        try {
            for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:rId]) {
                conDocIdSet.add(conDocLink.ContentDocumentId);
            }
            return [SELECT Id, Title, ContentDocumentId, FileType, Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN :conDocIdSet];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteFile(String conVerRecId){
        try {
            List<ContentDocument> conDocList = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :conVerRecId)];
            if(conDocList.size() > 0) {
                delete conDocList;
            } 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}