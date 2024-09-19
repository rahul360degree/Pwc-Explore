public without sharing class VideoPreviewerController {
    
    
                
	@AuraEnabled(cacheable=true)
    public static list<ContentDocumentLink> getAttachedDocuments(string recordId) {
        map<string,list<ContentDocumentLink>> finalResult = new map<string,list<ContentDocumentLink>>();
        List<String> allowedFileTypes = System.label.Knowlege_video_accepted_formats.split(',');
       return [SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.Description,ContentDocument.FileExtension FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId AND ContentDocument.FileExtension IN :allowedFileTypes];
    }
    
    @AuraEnabled(cacheable=true)
    public static String getBaseUrl() {
        return System.URL.getOrgDomainUrl().toExternalForm();
    }
}