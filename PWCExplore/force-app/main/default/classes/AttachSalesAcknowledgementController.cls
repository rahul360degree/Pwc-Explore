public without sharing  class AttachSalesAcknowledgementController {
    public class SalesAckException extends Exception {}
    
    private Order orderRecord = new Order();
    public Boolean isError {get; set;}
    public String toastMessage {get; set;}
    PageReference pdf;
    public Boolean showTermsOfOrder{get;set;}
    PageReference termsOfOrderPDF;
    
    public AttachSalesAcknowledgementController(ApexPages.StandardController stdController) {
        isError = false;
        toastMessage = 'Successfully created attachment. Will be redirected to acknowledgement page.'; //Added by SREEKANTH JUJARE
        Id orderId = (Id)stdController.getId();
        AttachSalesAckHandler(orderId);
    }
    
    private void AttachSalesAckHandler(Id recordId) {
        orderRecord = [Select Id,Name,RecordType.DeveloperName,OrderNumber,Integration_Status__c from Order Where ID = :recordId];
    }
    
    @AuraEnabled
    public static String createAttachmentRecord(String orderId) {
        PageReference pdf;
        PageReference termsOfOrderPDF;
        Order orderRecord = [SELECT Id, OrderNumber, Integration_Status__c, RecordType.DeveloperName FROM Order WHERE Id = :orderId];
        String orderRecordType = orderRecord.RecordType.DeveloperName;
        Boolean showTermsOfOrder = false;
        String successMsg = 'Successfully created attachment. View Notes & Attachments in Related Tab'; //Added by SREEKANTH JUJARE
        String errorMsg ='Cannot generate sales acknowledgement as order has not been synced to Infor yet'; //Added by SREEKANTH JUJARE
        if(orderRecordType==GlobalConstants.APPLIANCE_PRIMARY)
            pdf = Page.D2DApplianceSalesAcknowledgement;
        else if(orderRecordType==GlobalConstants.INTERIO_B2C_SCRIPT || orderRecordType==GlobalConstants.INTERIO_B2C_KITCHEN 
            || orderRecordType==GlobalConstants.INTERIO_B2C_VFD_PRIMARY 
            /*10-Dec-2021 Added OR condition to include Interio VFD Secondary*/
            || orderRecordType==GlobalConstants.INTERIO_VFD_SECONDARY){
            pdf = Page.InterioSalesAcknowledgement;
            showTermsOfOrder=true;
            termsOfOrderPDF=Page.TermsOfOrder;
        }
        else if(orderRecordType== GlobalConstants.QUOTE_RECORDTYPE_SSD) //Added by Sreekanth Jujare
            pdf = Page.SSDSalesAcknowledgement;
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
        
  /*      if(existingContent.size() > 0)
            throw new AuraHandledException('Cannot generate sales acknowledgement more than once.'); */
       
        if((orderRecordType==GlobalConstants.INTERIO_B2C_SCRIPT || orderRecordType==GlobalConstants.INTERIO_B2C_KITCHEN 
            || orderRecordType==GlobalConstants.INTERIO_B2C_VFD_PRIMARY || orderRecordType== GlobalConstants.QUOTE_RECORDTYPE_SSD //Added by Sreekanth Jujare
            /*10-Dec-2021 commenting out the OR condition for Interio VFD Secondary to allow Sales Ack creation without sync 
            || orderRecordType==GlobalConstants.INTERIO_VFD_SECONDARY
            */) 
           && orderRecord.Integration_Status__c!=GlobalConstants.INTEGRATION_STATUS_SYNCED)
            throw new AuraHandledException(errorMsg);
        
        ContentVersion contentVersion = new ContentVersion(ContentLocation = 'S', PathOnClient = fileName, Origin = 'H',
        Title = fileName, VersionData = body);
        insert contentVersion;
         
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
         
        ContentDocumentLink contentDocLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = orderId,
            ShareType = 'I', Visibility = 'AllUsers');
        insert contentDocLink;
        
        return successMsg;
    }
    
    public void createAttachmentRecord() {
        showTermsOfOrder=false;
        Id recordId = orderRecord.Id;
        String orderRecordType=orderRecord.RecordType.DeveloperName;
        String errorMsg ='Cannot generate sales acknowledgement as order has not been synced to Infor yet'; //Added by SREEKANTH JUJARE
        if(orderRecordType==GlobalConstants.APPLIANCE_PRIMARY)
            pdf = Page.D2DApplianceSalesAcknowledgement;
        else if(orderRecordType==GlobalConstants.INTERIO_B2C_SCRIPT || orderRecordType==GlobalConstants.INTERIO_B2C_KITCHEN 
            || orderRecordType==GlobalConstants.INTERIO_B2C_VFD_PRIMARY || orderRecordType==GlobalConstants.INTERIO_VFD_SECONDARY){
            pdf = Page.InterioSalesAcknowledgement;
            showTermsOfOrder=true;
            termsOfOrderPDF=Page.TermsOfOrder;
        }
        else if(orderRecordType== GlobalConstants.QUOTE_RECORDTYPE_SSD) //Added by Sreekanth Jujare
            pdf = Page.SSDSalesAcknowledgement;
        
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
        
        try {
            /*if(existingContent.size() > 0) Commented by SREEKANTH JUJARE TO AVOID THIS CONDITION ON 03/08/2022
                throw new SalesAckException('Cannot generate sales acknowledgement more than once.'); */
            if((orderRecordType==GlobalConstants.INTERIO_B2C_SCRIPT || orderRecordType==GlobalConstants.INTERIO_B2C_KITCHEN 
            || orderRecordType==GlobalConstants.INTERIO_B2C_VFD_PRIMARY || orderRecordType== GlobalConstants.QUOTE_RECORDTYPE_SSD //Added by Sreekanth Jujare
            /*10-Dec-2021 commenting out the OR condition for Interio VFD Secondary to allow Sales Ack creation without sync 
            || orderRecordType==GlobalConstants.INTERIO_VFD_SECONDARY
            */) 
               && orderRecord.Integration_Status__c!=GlobalConstants.INTEGRATION_STATUS_SYNCED)
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