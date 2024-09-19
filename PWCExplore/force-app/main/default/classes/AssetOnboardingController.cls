public class AssetOnboardingController {
    
    @AuraEnabled(cacheable =true)
    public static string makeCallout(String recordData,String recordId){
        
        /*HttpRequest request = new HttpRequest();
request.setEndpoint('https://test14.free.beeceptor.com');
request.setMethod('GET');
HttpResponse response = new Http().send(request);
return response.getBody();*/
        System.debug('RecordId--->' + recordId + ' SerialNumber--->' + recordData);
      /*  Asset asstRecord = new Asset();
        asstRecord.Id = recordId;
        asstRecord.SerialNumber = recordData;
        System.debug('Asset--->' + asstRecord);
        update asstRecord;*/
        return null;
    }
    
    @AuraEnabled
    public static Boolean makeMockApiCall(String scannedValue, String recordId) {
        String mockApiEndpoint = 'https://test14.free.beeceptor.com';
        Boolean isProductFound = true;
        system.debug('ScannedValue-->'+ scannedValue);
        Asset asstRecord = new Asset();
        asstRecord.Id = recordId;
        asstRecord.SerialNumber = scannedValue;
        update asstRecord;
        /*HttpRequest req = new HttpRequest();
req.setEndpoint(mockApiEndpoint);
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody('{"barcode":"' + scannedValue + '"}');

Http http = new Http();
HttpResponse res = http.send(req);

if (res.getStatusCode() == 200) {
isProductFound = res.getBody() == 'true';
} else {
System.debug('Failed to make mock API call: ' + res.getStatus() + ' ' + res.getBody());
isProductFound = false;
}*/
        
        return false;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> isSerialIdLinked(String serialId) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('isLinked', false);
        result.put('recordId', null);
        
        if (String.isBlank(serialId)) {
            return result; // Return false and null if serialId is null or empty
        }
        
        // Perform query to check if the serial ID is linked with any existing asset records
        List<Asset> linkedAssets = [SELECT Id,AccountId FROM Asset WHERE SerialNumber = :serialId LIMIT 1];
        
        if (!linkedAssets.isEmpty()) {
            result.put('isLinked', true);
            result.put('recordId', linkedAssets[0].Id);
            result.put('previusAccount',linkedAssets[0].AccountId);
        }
        
        return result;
    }
    
    @AuraEnabled(cacheable=false)
    public static void saveAttachment(Id parentId, String fileName, String base64Data) {
        try {
            List<WorkOrderLineItem> woliList = [SELECT AssetId FROM WORKORDERLINEITEM WHERE Id =:parentId];
            // Decode base64Data to Blob
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            List<ContentVersion> contentVersions = new List<contentVersion>();            
            ContentVersion cv = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName,
                VersionData = EncodingUtil.base64Decode(base64Data),
                FirstPublishLocationId = woliList[0].AssetId
            );
            contentVersions.add(cv);
            insert contentVersions;
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error occurred while saving attachment: ' + ex.getMessage());
        }  
    }
    
    @AuraEnabled(cacheable=false)
    public static void transfertAnAsset(Id recordID,Id previousAssetId,Id accountId){
        // Query the RecordType Id for "Appliances"
        System.debug('recordId-->' + accountId);
        System.debug('previousAsset-->' + previousAssetId);
        List<WorkOrderLineItem> woliRecords = [SELECT CreatedById, AssetId,Asset.AccountId FROM WorkOrderLineItem WHERE Id = :recordID];
        if(woliRecords[0].AssetId!=Null){
            Id appliancesRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Appliances').getRecordTypeId();
            List<Task> tasksToInsert = new List<Task>();
            Task taskRecord = new Task();
            taskRecord.Task_Type__c = 'Call';
            taskRecord.status = 'Requested for Transfer of Asset';
            taskRecord.Subject = 'Call';
            taskRecord.Customer_Name__c = woliRecords[0].Asset.AccountId;
            taskRecord.WhatId = woliRecords[0].AssetId;
            taskRecord.OwnerId = woliRecords[0].CreatedById;
            taskRecord.Previous_Asset__c = previousAssetId;
            taskRecord.ActivityDate = Date.today(); // Set dueDate to today's date
            taskRecord.RecordTypeId = appliancesRecordTypeId; // Set the RecordType
            tasksToInsert.add(taskRecord);
            
            
            if (!tasksToInsert.isEmpty()) {
                Insert tasksToInsert;
            }
            System.debug('Asset->'+tasksToInsert);
            CustomNotificationType notificationType = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName = 'Cancelled_SA_Notification_to_ASP' Limit 1
            ];
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            
            notification.setTitle('Task Assigned to You');
            notification.setBody('A new task has been assigned to you. Please review it.');
            notification.setTargetId(tasksToInsert[0].Id); 
            notification.setNotificationTypeId(notificationType.Id);
            
            Set<String> targetIds = new Set<String>();
            targetIds.add(woliRecords[0].CreatedById); 
            
            try {
                notification.send(targetIds);
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
            }
            List<Id> contentDocumentIdList = new List<Id>();
            for (ContentDocumentLink cont : [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :woliRecords[0].AssetId]) {    
                contentDocumentIdList.add(cont.ContentDocumentId);
            }
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            For(ContentVersion contentVersionObj : [SELECT Title,PathOnClient,VersionData,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId=: contentDocumentIdList]){
                ContentVersion cv = new ContentVersion(
                    Title = contentVersionObj.Title,
                    PathOnClient = contentVersionObj.PathOnClient,
                    VersionData = contentVersionObj.VersionData,
                    FirstPublishLocationId = previousAssetId
                );
                contentVersionList.add(cv);
            }
            try{
                Insert contentVersionList;
            }
            catch(Exception exc){
                System.debug('Error-->' + exc);
            }
            
            
        }
        
        
    }
}