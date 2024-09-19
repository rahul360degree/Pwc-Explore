/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-26-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class DSA_Attachment {
    //this method return attachment list
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getAttchments(String recordId){
        try {
            ProcessInstanceWorkitem workItem = [Select ProcessInstance.TargetObjectId  from ProcessInstanceWorkitem where Id=:recordId];
            //Get Object Type
            String objectName = (workItem.ProcessInstance.TargetObjectId).getSObjectType().getDescribe().getName();

            if(objectName =='Statement_of_Account__c'){
                Set<ID> cdLink_ID_Set = new Set<ID>();
                for(ContentDocumentLink cdLink:[SELECT ContentDocumentId from ContentDocumentLink Where LinkedEntityId =:workItem.ProcessInstance.TargetObjectId ]){
                    cdLink_ID_Set.add(cdLink.ContentDocumentId);
                }
                return [
                    SELECT Id, Title, FileType, ContentDocumentId
                    FROM ContentVersion
                    WHERE 
                    isLatest = true  
                    AND ContentDocumentId IN: cdLink_ID_Set
                ];
            }else{ return null;}
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}