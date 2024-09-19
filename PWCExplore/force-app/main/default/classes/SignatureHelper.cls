public without sharing class SignatureHelper {
    
    @AuraEnabled
    public static ContentVersion saveSign(String strSignElement,Id recId){

        //recId = 'a0F0w000000NQy1EAG';
        // Create Salesforce File
        //Insert ContentVersion
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = 'Signature-'+System.now() +'.png';//File name with extention
        cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
        //cVersion.OwnerId = attach.OwnerId;//Owner of the file
        cVersion.Title = 'Signature-'+System.now() +'.png';//Name of the file
        cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);//File content
        cVersion.Is_System_Generated_Signature__c = TRUE;
        insert cVersion;
        
        //After saved the Content Verison, get the ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        
        //Insert ContentDocumentLink
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
        cDocLink.LinkedEntityId = recId;//Add attachment parentId
        cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
        insert cDocLink;

        return cVersion;
    }
}