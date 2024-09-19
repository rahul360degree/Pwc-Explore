public without sharing class AttachSOAController {
    public class SalesAckException extends Exception {}
    
    private Order orderRecord = new Order();
    public Boolean isError {get; set;}
    public String toastMessage {get; set;}
    PageReference pdf;
    public Boolean showTermsOfOrder{get;set;}
    PageReference termsOfOrderPDF;
    
    public AttachSOAController(ApexPages.StandardController stdController) {
        isError = false;
        toastMessage = 'Successfully created attachment. Will be redirected to acknowledgement page.'; //Added by SREEKANTH JUJARE
        Id orderId = (Id)stdController.getId();
        AttachSalesAckHandler(orderId);
    }
    
    private void AttachSalesAckHandler(Id recordId) {
        orderRecord = [Select Id,Name,RecordType.DeveloperName,OrderNumber,Sold_To_Address__r.Integration_Status__c,  Ship_To_Address__r.Integration_Status__c,Integration_Status__c from Order Where ID = :recordId];
    }
    
    @AuraEnabled
    public static String createAttachmentWithoutSync(String orderId) {
        String message;
        string successMessage='Successfully created attachment. View Notes & Attachments in Related Tab'; //Added by SREEKANTH JUJARE
        PageReference pdf;
        PageReference termsOfOrderPDF;
        Order orderRecord = [SELECT Id, OrderNumber, Integration_Status__c, Sold_To_Address__c, Ship_To_Address__c, RecordType.DeveloperName FROM Order WHERE Id = :orderId Limit 1 ];
        String orderRecordType = orderRecord.RecordType.DeveloperName;
        Boolean showTermsOfOrder = false;
        if(orderRecordType==GlobalConstants.INTERIO_B2C_VFD_PRIMARY)
        {
            pdf = Page.InterioSOAWithoutSyncing;
            showTermsOfOrder=true;
            termsOfOrderPDF=Page.TermsOfOrder;
        }
        pdf.getParameters().put('orderId', orderId);
        
        Blob body;
        
        try {
            if(Test.isRunningTest()) {
                body = blob.valueOf('PDF Content');
            } else {
                body = pdf.getContent();
            }   
        } catch (SalesAckException ex) {
            body = Blob.valueOf('PDF Content');
        }
        
        String fileName = 'Sales_Acknowledgement-' + orderRecord.OrderNumber + '.pdf';
        
        List<ContentDocumentLink> existingContent = [Select Id from ContentDocumentLink Where ContentDocument.Title = :fileName and LinkedEntityId = :orderId];
        
        ContentVersion contentVersion = new ContentVersion(ContentLocation = 'S', PathOnClient = fileName, Origin = 'H',
                                                           Title = fileName, VersionData = body);
        insert contentVersion;
        
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        
        ContentDocumentLink contentDocLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = orderId,
                                                                     ShareType = 'I', Visibility = 'AllUsers');
        insert contentDocLink;
        
        return successMessage;
    }
    
    public void createAttachmentWithoutSync() {
        showTermsOfOrder=false;
        Id recordId = orderRecord.Id;
        String orderRecordType=orderRecord.RecordType.DeveloperName;
        String errorMsg ='Cannot generate sales acknowledgement, Please Sync Order in Infor LN First.';   //Added by SREEKANTH JUJARE
        
        //Following Condition is to validate the Record Type by Sreekanth Jujare
        if(orderRecordType == GlobalConstants.INTERIO_B2C_VFD_PRIMARY){
            pdf = Page.InterioSOAWithoutSyncing;
            showTermsOfOrder=true;
            termsOfOrderPDF=Page.TermsOfOrder;
        }
        
        pdf.getParameters().put('orderId',orderRecord.Id);
        
        Blob body;
        
        try {
            if(Test.isRunningTest()) {
                body = blob.valueOf('PDF Content');
            } else {
                body = pdf.getContent();
            }   
        } catch (SalesAckException ex) {
            body = Blob.valueOf('PDF Content');
        }
        
        String fileName = 'Sales_Acknowledgement-' + orderRecord.OrderNumber + '.pdf';
        List<ContentDocumentLink> existingContent = [Select Id from ContentDocumentLink Where ContentDocument.Title = :fileName and LinkedEntityId = :recordId];
        
        //Following Conditions are added to validate the Integration Status of Order and Address by BP by Sreekanth Jujare
        try {
            if( (orderRecord.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_DRAFT) || 
               (orderRecord.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_CAPTURED) || 
               (orderRecord.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_BLOCKED) ||
               (orderRecord.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_NOT_SYNCED) || 
               orderRecord.Sold_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_DRAFT ||
               orderRecord.Sold_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_CAPTURED ||
               orderRecord.Sold_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_BLOCKED ||
               orderRecord.Sold_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_NOT_SYNCED ||
               orderRecord.Ship_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_DRAFT ||
               orderRecord.Ship_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_CAPTURED ||
               orderRecord.Ship_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_BLOCKED ||
               orderRecord.Ship_To_Address__r.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_NOT_SYNCED 
              ) 
                throw new SalesAckException(errorMsg);
            
            ContentVersion contentVersion = new ContentVersion(ContentLocation = 'S', PathOnClient = fileName, Origin = 'H',
                                                               Title = fileName, VersionData = body);
            insert contentVersion;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            
            ContentDocumentLink contentDocLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = recordId,
                                                                         ShareType = 'I', Visibility = 'InternalUsers');
            insert contentDocLink;
            
        } catch(SalesAckException ex) {
            isError = true;
            toastMessage = ex.getMessage();
        }
    }
    
    public PageReference redirectToDetailPage() {
        return pdf;
    }
    
    public PageReference showTermsOfOrderPDF(){
        return termsOfOrderPDF;
    }
}