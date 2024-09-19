public with sharing class RMAController {
    
    @AuraEnabled(cacheable=true)
    public static WorkOrderLineItem fetchWorkOrderDetails(Id workOrderId){
        
        return [SELECT Id,AssetId,Asset.Product2Id,WorkOrder.ContactId,WorkOrder.Contact.Name FROM WorkOrderLineItem
                WHERE Id =:workOrderId LIMIT 1];
        
    }
    
    @AuraEnabled
    public static void createPRARecord(Map<String, Object> praData, String fileBody, String fileName) {
        System.debug('preii-->' + praData  +   '    FileBody--0 +' + fileBody);
        Pra__c pra = new Pra__c(
            Work_Order__c = (Id)praData.get('workOrderId'),
            Product__c = (Id)praData.get('productId'),
            Contact__c = (Id)praData.get('contactId'),
            Reason__c = (String)praData.get('reason')
        );
        insert pra;
            if(fileBody !=null){
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(fileBody);
            insert contentVersion;
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            cdl.LinkedEntityId = pra.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        }
    }
    
    
    
}