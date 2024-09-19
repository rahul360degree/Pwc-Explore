/*------------------------------------------------------------------------
Author:        Varun Rajpoot
Company:       GITL
Description:   Controller class for splitQuoteLineItemQty
last modified on: 04-04-2022
----------------------------------------------------------------------------*/

public class SplitQuoteLineitemQtyController {    
    // get the content document
    private static List<ContentDocumentLink> contentDocument(Id recordId, String docType){
        return [SELECT contentdocument.latestpublishedversion.ContentSize, contentdocument.latestpublishedversion.FileExtension, 
                contentdocument.latestpublishedversion.Title, contentdocument.latestpublishedversion.Type__c
                FROM ContentDocumentLink where linkedentityid =:recordId 
                AND contentdocument.latestpublishedversion.Type__c =:docType
                AND contentdocument.latestpublishedversion.Is_Synced_with_PC__c = false
                order by ContentDocument.CreatedDate Desc limit 1];
    }

    // get the latest content document
    @AuraEnabled
    public static List<ContentDocumentLink> ContentDocumentLinkFn(Id recordId){
        List<ContentDocumentLink> po_document = contentDocument(recordId,'PO');
        List<ContentDocumentLink> ho_document = contentDocument(recordId,'HO');
        List<ContentDocumentLink> supplier_document = contentDocument(recordId,'Supplier');

        List<ContentDocumentLink> documentLink = new List<ContentDocumentLink>();
        if(!po_document.isEmpty()){
            documentLink.add(po_document[0]);
        }
        if(!ho_document.isEmpty()){
            documentLink.add(ho_document[0]);
        }
        if(!supplier_document.isEmpty()){
            documentLink.add(supplier_document[0]);
        }

        return documentLink;
    }
    
    
    
    //Get QuoteLineItems
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItemFromQuote(Id recordId){
        try{
            String errorMessage = '';
            recordId = String.escapeSingleQuotes(recordId);
            Quote quote = [Select Id, Disable_PC_Sync__c,
                                Delivery_Type__c,
                                Expected_Date_of_Delivery__c,
                                Branch_Locks_B2B__c,
                                Channel__c,
                                Segment__c,
                                Remarks__c,
                                Special_Remarks__c,
                                QuoteNumber,
                                Agreed_by_customer__c
                                from Quote where Id=:recordId
                                ];

            List<ContentDocumentLink> po_document = contentDocument(recordId,'PO');
            //Added By Mrunali Chaudhari on 2 Nov 2022
            if(!quote.Agreed_by_customer__c){
                errorMessage = system.label.Quote_is_not_yet_agreed_by_Customer;
            }

            if(quote.Disable_PC_Sync__c){
                errorMessage = system.label.Quote_is_Locked_Please_contact_your_admin;
            }
            
            if(po_document.isEmpty()){
                errorMessage += system.label.PO_document_is_mandatory;
            }

            if(String.isEmpty(quote.Delivery_Type__c)){
                errorMessage += system.label.Delivery_Type_is_a_required_field;
            }
            if(quote.Expected_Date_of_Delivery__c==null){
                errorMessage += system.label.Expected_Date_of_Delivery_is_a_required_field;
            }
            if(String.isEmpty(quote.Branch_Locks_B2B__c)){
                errorMessage += system.label.Branch_Warehouse_is_a_required_field;
            }
            if(String.isEmpty(quote.Channel__c)){
                errorMessage += system.label.Channel_is_a_required_field;
            }
            if(String.isEmpty(quote.Segment__c)){
                errorMessage += system.label.Segment_is_a_required_field;
            }
            if(String.isEmpty(quote.Remarks__c)){
                errorMessage += system.label.Remarks_is_a_required_field;
            }
            if(String.isEmpty(quote.Special_Remarks__c)){
                errorMessage += system.label.Special_remarks_is_a_required_field;
            }
            if(String.isNotEmpty(errorMessage)){
                AuraHandledException error = new AuraHandledException(errorMessage);
                error.setMessage(errorMessage);
                throw error; 
            }
            //Added by MRUNALI CHAUDHARI (Product_Type_Code__c,Quote_Unit_Basics_Cust__c) on 29-11-2022 for SLF - 57 , PSM added customer sales Price for SLF-34
            List<QuoteLineItem> qlis = [
                Select Id,Product_Name__c,Remaining_Quantity__c,Previous_Split_Quantitiy__c,
                Search_Key_II__c, Item_Code__c,Quantity,MRP__c,Ordered_Quantity__c,
                UnitPrice, Discount__c,Product_Type_Code__c,Quote_Unit_Basics_Cust__c,
                Quote.QuoteNumber,customer_sales_price__c, Status__c
                from QuoteLineItem 
                where QuoteId =:recordId and Remaining_Quantity__c >= 1 AND Status__c =:GlobalConstants.QLI_Won_Status];
            if(qlis.isEmpty()){
                errorMessage = System.Label.Won_QLI_Error;
                AuraHandledException error = new AuraHandledException(errorMessage);
                error.setMessage(errorMessage);
                throw error;
            }
            else{
                return qlis ;
            }
        }
        catch(Exception ex){
            Logger.logError('SplitQuoteLineitemQtyController', 'getQuoteLineItemFromQuote', '', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //Get the Quote records
    private static Quote quoteValueAssignment(Id quoteId,String userId, String sfQuotationPos){
        return [Select Id,Account_Name__r.Account_code__c,Account.Account_code__c,OEM__r.Name,
                Invoice_To_Address__r.Address_code_Formula__c,Ship_To_Address__r.Address_Code_Formula__c, 
                Customer_Order_No__c,Segment__c, Expected_Date_of_Delivery__c, Influencer__c, Influencer__r.Account_code__c,Remarks__c,
                Special_remarks__c,Channel__c, QuoteNumber,Integration_Error_Message__c,
                Opportunity_Owner__r.Salary_Code__c,Branch_Locks_B2B__c,Delivery_Type__c
                FROM Quote
                WHERE Id=: quoteId limit 1];
    }
    
    //Prepare QLI JSON
    private static String quoteLineValueAssignment(List<QuoteLineItem> qLIrecords){        
        String productDetails = '[';
        integer i=1;
        for(QuoteLineItem qLI: qLIrecords) {
            if(i>1){
                productDetails +=',';    
            }
            i++;
            productDetails +='{'
                +'"productCode":"",'
                +'"unspscCode":"'+qLI.Item_Code__c+'",'
                +'"qty":"'+String.valueOf(qLI.Previous_Split_Quantitiy__c)+'",'
                +'"mrp":"'+String.valueOf(qLI.MRP__c)+'",'
                +'"basic":"'+String.valueOf(qLI.customer_sales_price__c)+'",'
                +'"discPerc":"'+String.valueOf(qLI.Discount__c)+'"'                        
                +'}';
        }
        productDetails +=']';
        return productDetails;
    }    
    //Step 1 : flag-true to disable sync
    @AuraEnabled
    public static string disableEnableQuoteSync(Id QuoteId,String flag){
        //Step 1: Lock the Quote
        try{
            Quote quote = new Quote();
            
            quote.Id = QuoteId;
            quote.Disable_PC_Sync__c = (flag=='true'?true:false);
            update quote;
            return 'SUCCESS';
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
   //Wrapper class to return required data for callout
    public class WrapperClass{
        @AuraEnabled public String accessToken;
        @AuraEnabled public Quote quoteRec;
        @AuraEnabled public String lineItemData;
        @AuraEnabled public String userId;
        @AuraEnabled public String quoteEndPointURL;
    }
    //Return Token and required data for callout
    @AuraEnabled
    public static WrapperClass syncRecord(List<QuoteLineItem> qLIrecords,Id QuoteId,String sfQuotationPos){
        try{
            // Intialize Callout
            ProductConfig_Callout callout = new ProductConfig_Callout();
            String token = callout.getsfpcToken();
            String errorMessage='';
            WrapperClass wrap = new WrapperClass();
            if(String.isNotEmpty(token)){
                wrap.accessToken = token;
                wrap.quoteRec = quoteValueAssignment(quoteId, callout.userId, sfQuotationPos);
                wrap.lineItemData = quoteLineValueAssignment(qLIrecords);  
                wrap.userId = callout.userId;
                wrap.quoteEndPointURL = callout.qliEndPointURL;
                
            }else{
                errorMessage = 'Authentication issue! Please connect with Admin. ';
            }
            if(String.isNotEmpty(errorMessage))
            {
                AuraHandledException error = new AuraHandledException(errorMessage);
                error.setMessage(errorMessage);
                throw error;
            }else
                return wrap;            
        }
        catch(Exception ex){
            Logger.logError('SplitQuoteLineitemQtyController', 'syncRecord', '', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //Decode the response
    @AuraEnabled
    public static String parseLWCCalloutResponse(String response){
        ProductConfig_Callout callout = new ProductConfig_Callout();
        String parseResponse = callout.parseResponse(response);
        System.debug(parseResponse);
        return parseResponse;
    }
    //Step 3: UPdate QLI and Quote
    @AuraEnabled
    public static String updateQuoteAndLineItem(List<QuoteLineItem> qLIrecords,Id QuoteId, String opfNo,String quoteDescription){
        String errorMessage = '';
        try{
            Set<ID> cdLink_ID_Set = new Set<ID>();
            for(ContentDocumentLink cdLink:[SELECT ContentDocumentId from ContentDocumentLink Where LinkedEntityId =:QuoteId]){
                cdLink_ID_Set.add(cdLink.ContentDocumentId);
            }
            if(!cdLink_ID_Set.isEmpty()){
                List<ContentVersion> cVersion = [
                    SELECT Id, Title, FileType, ContentDocumentId
                    FROM ContentVersion
                    WHERE 
                    isLatest = true
                    AND ContentDocumentId IN: cdLink_ID_Set
                    AND Type__c IN ('PO','HO','Supplier')
                    AND Is_Synced_with_PC__c = false
                ];
                for(ContentVersion ver:cVersion){
                    ver.Is_Synced_with_PC__c = true;
                }	

                Database.SaveResult [] updateversionResult = Database.update(cVersion, false);
                for (Database.SaveResult sr : updateversionResult) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage += err.getStatusCode() + ': ' + err.getMessage();
                        }
                    }
                }
            }



            if(String.isBlank(errorMessage)){
                Database.SaveResult [] updateResult = Database.update(qLIrecords, false);
                for (Database.SaveResult sr : updateResult) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage += err.getStatusCode() + ': ' + err.getMessage();
                        }
                    }
                }
         }
            if(String.isBlank(errorMessage)){
                Quote quote= [Select Id,OPF_Number__c,Disable_PC_Sync__c, Split_Log__c from Quote where ID=:QuoteId];
                quote.Disable_PC_Sync__c = false;
                quote.Split_Log__c =  (String.isBlank(quote.Split_Log__c) || quote.Split_Log__c ==null )? quoteDescription : quote.Split_Log__c+'<br/>'+quoteDescription;
                quote.OPF_Number__c =(String.isBlank(quote.OPF_Number__c) || quote.OPF_Number__c==null )? opfNo : quote.OPF_Number__c+'; '+opfNo;
                update quote;
                return 'SUCCESS';
                
            }else{
                AuraHandledException error = new AuraHandledException(errorMessage);
                error.setMessage(errorMessage);
                throw error;
            }
            
            
        }catch(Exception ex){           
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
}