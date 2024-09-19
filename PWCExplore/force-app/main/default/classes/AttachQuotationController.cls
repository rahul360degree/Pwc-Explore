public class AttachQuotationController {
    public class PDFException extends Exception {}
    
    @AuraEnabled
    public static string createAttachmentRecord(String recordId) {
        PageReference pdf;
        Blob body;
        String prodSubType;
        //Set<String> productSubtype = new Set<String>();
        Quote quoteRecord = [Select Id,AccountId,QuoteNumber,LOB_N__c,Internal_Sales_Representative__c,Pumping_charges_per_cuM__c,Total_pumping_charges__c,Basic_cement_rate__c,Diesel_Escalation_rate__c from Quote where Id =: recordId Limit 1];
        //QuoteLineItem QLIrecord = [ Select Product_Sub_Category__c from QuoteLineItem where QuoteId =: recordId Limit 1];
        List<QuoteLineItem> prods_AAC = [Select Product_Sub_Category__c from QuoteLineItem where QuoteId =: recordId AND Product_Sub_Category__c =: GlobalConstants.Construction_Prod_SubCategory_AAC ];
        List<QuoteLineItem> prods_RCM = [Select Product_Sub_Category__c from QuoteLineItem where QuoteId =: recordId AND Product_Sub_Category__c =: GlobalConstants.Construction_Prod_SubCategory_RCM];
        List<QuoteLineItem> prods_RMC = [Select Product_Sub_Category__c from QuoteLineItem where QuoteId =: recordId AND Product_Sub_Category__c =: GlobalConstants.Construction_LOB_RMC ];
        
        
        List<ContentDocumentLink> existingPDF = [SELECT Id FROM ContentDocumentLink where LinkedEntityId= : recordId];
        
        //Validation for Int-Sales Rep should not be null
        if(quoteRecord.Internal_Sales_Representative__c == null)
            throw new PDFException('Please maintain Internal Sales Representative before generating quote.');
        //Validation for mandatory fields for LOB = RMC while generating quote pdf. 
        System.debug('Quotes LOBs : '+ quoteRecord.LOB_N__c);
        if(quoteRecord.LOB_N__c == GlobalConstants.Construction_LOB_RMC && (quoteRecord.Pumping_charges_per_cuM__c == null || quoteRecord.Total_pumping_charges__c == null || quoteRecord.Basic_cement_rate__c == null || quoteRecord.Diesel_Escalation_rate__c == null))
            throw new PDFException('Pumping charges per cuM, Total pumping charges, Basic cement rate and Diesel Escalation rate are mandatory if LOB is RMC.');
        
        
        if(prods_AAC.size()>0){
            prodSubType = GlobalConstants.Construction_Prod_SubCategory_AAC;            generatePDF(prodSubType, recordId, quoteRecord);
        }
        if(prods_RCM.size()>0){
            prodSubType = GlobalConstants.Construction_Prod_SubCategory_RCM;            generatePDF(prodSubType, recordId, quoteRecord);
        }
        if(prods_RMC.size()>0){
            prodSubType = GlobalConstants.Construction_LOB_RMC;            generatePDF(prodSubType, recordId, quoteRecord);
        }         
        
        return 'Successfully created attachment. Will be redirected to record page.';    
    }
    
    public static void generatePDF(String prodSubType, String recordId,Quote quoteRecord){
        System.debug('Sid Prod : '+prodSubType+ ' Record Id : '+recordId + ' Quote : '+quoteRecord);
        List<ContentDocumentLink> existingPDF = [SELECT Id FROM ContentDocumentLink where LinkedEntityId= : recordId];
        PageReference pdf;
        Blob body;
        if(prodSubType == GlobalConstants.Construction_Prod_SubCategory_AAC){pdf = Page.construction_AAC_quotation;}
        if(prodSubType == GlobalConstants.Construction_Prod_SubCategory_RCM){pdf = Page.construction_RCM_quotation;}
        if(prodSubType == GlobalConstants.Construction_LOB_RMC){pdf = Page.construction_RMC_quotation;}
        
        if(pdf != null){
            pdf.getParameters().put('Id', recordId);
        }
        
        //Blob body;
        try {
            if(Test.isRunningTest()) {
                body = blob.valueOf('PDF Content');
            } else {
                body = pdf.getContent();
            }
            
        } catch (PDFException ex) {
            System.debug('Message '+ ex);
        }
        String fileName = '';
        if(existingPDF.size()>0){
            fileName = prodSubType+ '-' + quoteRecord.LOB_N__c +'-QuoteNo.' + quoteRecord.QuoteNumber + '-'+ existingPDF.size() +'.pdf';
        }else{
            fileName = prodSubType+ '-' + quoteRecord.LOB_N__c +'-QuoteNo.' + quoteRecord.QuoteNumber + '.pdf';
        }
        
        ContentVersion contentVersion = new ContentVersion(ContentLocation = 'S', PathOnClient = fileName, Origin = 'H',
                                                           Title = fileName, VersionData = body);
        insert contentVersion;
        
        Id contentDocumentId = [SELECT ContentDocumentId 
                                FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        
        ContentDocumentLink contentDocLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = recordId,
                                                                     ShareType = 'I', Visibility = 'AllUsers');
        insert contentDocLink;
    }
    
    
    
}