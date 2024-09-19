public with sharing class UploadCompressedFileHelper {
    @AuraEnabled
    public static List<Id> createContentDocuments(List<String> base64StringList, String fileName, String fileType) {
        List<ContentVersion> contentVersionFiles = new List<ContentVersion>();
        List<Id> documentIds = new List<Id>();
        for (Integer i = 0; i < base64StringList.size(); i++) {
            String each = EncodingUtil.urlDecode(base64StringList[i], 'UTF-8');
            contentVersionFiles.add(new ContentVersion(VersionData = EncodingUtil.base64Decode(each), Title = fileName + i,
                ContentLocation = 'S', PathOnClient = fileName + i + '.' + fileType));
        }
        insert contentVersionFiles;

        for (ContentVersion eachCV : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionFiles]) {
            documentIds.add(eachCV.ContentDocumentId);
        }
        return documentIds;
    }
}