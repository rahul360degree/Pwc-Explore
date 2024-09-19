/**
* @description       : Used as Controller class for PedQuotePdf vf page..
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
public class PedQuotePdfController {
    public Quote quoteData {get; set;}
    public Opportunity oppData {get; set;}
    public List<QuotelineItem> listQuoteLineItems{get; set;} //fetching QuotelineItems
    public Id QuoteId {get;set;}
    public String Today { get;set;}
    public String FileNo { get;set;}
    public String EnquiryRecpeiptDate { get;set;}
    public String EquipmentName { get;set;}
    public String EquipmentType { get;set;}
    public String totalAmountInWords { get;set;}
    public List<String> techinicalOfferDesignCodes { get;set;}
    public List<String> techinicalOfferExclusions { get;set;}
    public List<QliWrapperClass> QliWrapperList { get;set;}
    public String formattedTotalSalesPrice { get; set; }
    public Decimal myDecimalVariable { get; set; }
    
     // CONSTRUCTOR CLASS
    public PedQuotePdfController(ApexPages.StandardController standardController){
        try{
            Today = Date.today().format(); // To fetch Today's Date
            FileNo='';
            EnquiryRecpeiptDate='';
            EquipmentName='';
            EquipmentType='';
            QuoteId = standardController.getId();
            quoteData = getQuote(QuoteId);
            getlistQuoteLineItems(QuoteId); // To fetch All Qli's for related quote record.
            getOpp(QuoteId);
            if(quoteData.Currency__c==GlobalConstants.Currency_INR){
                totalAmountInWords=convertINRAmountToWords(quoteData.Total_Price__c.longValue()) + ' Only';
                formattedTotalSalesPrice = ((Long)quoteData.Total_Price__c.setScale(0)).format();
            }else if(quoteData.Currency__c==GlobalConstants.Currency_USD || quoteData.Currency__c==GlobalConstants.Currency_EURO){
                totalAmountInWords=convertUSDAmountToWords(quoteData.Total_Price__c.longValue()) + ' Only';
            }
            if(quoteData.Technical_Offer_Design_Codes__c!=null){
                techinicalOfferDesignCodes = quoteData.Technical_Offer_Design_Codes__c.split(';');
            }
            if(quoteData.Technical_Offer_Exclusions__c!=null){
                techinicalOfferExclusions = quoteData.Technical_Offer_Exclusions__c.split(';');
            }
        }
        catch(Exception ex){
            Logger.logError('PedQuotePdfController', 'PedQuotePdfController', '', ex);
        } 
    }
    
    // Retrieve a Quote based on the provided QuoteId
    public Quote getQuote(Id quoteId){
        return[Select Id, Name,QuoteNumber,Offer_Number__c,Offer_Date__c,Invoice_to_Address_txt__c,Buyer_Name__c,Buyer_Designation__c,
               Technical_Offer_Design_Codes__c,Technical_Offer_Exclusions__c,Opportunity.MFG_Location__c,
               PED_Quote_PDF_Type__c,OpportunityId,RFQ_No__c,Opportunity.Equipment_Name__c,Opportunity.EQUIPMENT_TYPE__c,Opportunity.Project_Name__c,
               AccountId,Account.Name,toLabel(Incoterm__c),toLabel(Currency__c),Total_Price__c,Technical_offer_II__c,              
               ContactId, Address__c,Table_Of_Contents__c,Technical_offer__c,Section_II_Additional_Details__c,Commercial_Terms_Condition__c,
               Level_1_Approver__c,Level_1_Approver__r.Name,Level_1_Approver__r.Title,Level_1_Approver__r.Email,Level_1_Approver__r.MobilePhone,
               Level_2_Approver__c,Level_2_Approver__r.Name,Level_2_Approver__r.Title,Level_2_Approver__r.Email,Level_2_Approver__r.MobilePhone,
               Level_3_Approver__c,Level_3_Approver__r.Name,Level_3_Approver__r.Title,Level_3_Approver__r.Email,Level_3_Approver__r.MobilePhone
               From Quote Where Id =: quoteId Limit 1];
    }
    
    // Retrieve a list of QuoteLineItems based on the provided QuoteId
    public void getlistQuoteLineItems(Id quoteId){
        listQuoteLineItems=[Select Id,QuoteId,Product2.Description,Quantity,Equipment_Name__c,Tag_Number__c,Sales_Price__c,Total_Price_PED__c
                 from QuoteLineItem where QuoteId=:quoteID];
        QliWrapperList=new List<QliWrapperClass>();
        if(!listQuoteLineItems.isEmpty()){
        	for(QuoteLineItem qli:listQuoteLineItems){
           		QliWrapperClass qliWrapper=new QliWrapperClass();
                qliWrapper.qliRecord=qli;
               	qliWrapper.formattedQliSalesPrice=((Long)qli.Sales_Price__c.setScale(0)).format();
                qliWrapper.formattedQliTotalSalesPrice=((Long)qli.Total_Price_PED__c.setScale(0)).format();
                qliWrapper.formattedQliQuantity=((Integer)qli.Quantity.setScale(0)).format();
                QliWrapperList.add(qliWrapper);
        	} 
        }        
      }
    
     // Retrieve an Opportunity based on the QuoteId and determine FileNo and EnquiryRecpeiptDate
    public void getOpp(Id quoteId){
        Id pedFirmRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_FIRM_OPPORTUNITY_RT).getRecordTypeId();
        oppData= [Select Id, Name, Estimation_Due_Date__c,Sales_Due_Date_Time__c,EST_FILE_NO_Firm__c,EST_FILE_NO_Budgetory__c,Account.Name,Project_Name__c,
               ENQUIRY_RECEIPT_MONTH_FIRM__c,ENQUIRY_RECEIPT_MONTH_BQ__c,RecordTypeId From Opportunity Where Id=: quoteData.OpportunityId Limit 1];
        if(oppData.RecordTypeId==pedFirmRecordTypeId)
        {
            FileNo=oppData.EST_FILE_NO_Firm__c;
            EnquiryRecpeiptDate=oppData.ENQUIRY_RECEIPT_MONTH_FIRM__c!=null ?(oppData.ENQUIRY_RECEIPT_MONTH_FIRM__c).format() : '';
         }else{
            FileNo=oppData.EST_FILE_NO_Budgetory__c;
            EnquiryRecpeiptDate=oppData.ENQUIRY_RECEIPT_MONTH_BQ__c!=null ?(oppData.ENQUIRY_RECEIPT_MONTH_BQ__c).format() : '';
         }
    }  
   
    // Create a PDF and attach it to the Quote
    public PageReference createPDF(){ 
        try{
            //generate and attach the PDF document
            PageReference pdfPage = Page.PedQuotePdf;// page reference
            pdfPage.getParameters().put('id',quoteData.Id);
            Blob pdfBlob; //create a blob for the PDF content
            pdfBlob = Test.isRunningTest() ? Blob.valueOf('generate pdf') : pdfPage.getContent();
            
            // created content version
            ContentVersion cv = createContentVersion(pdfBlob);
            
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = createContentDocumentLink(conDocId);
            
            //redirect the user
            PageReference pageRef = new ApexPages.StandardController(quoteData).view();
            pageRef.setRedirect(true); 
            return pageRef ;
        }
        catch(Exception ex){
            Logger.logError('PedQuotePdfController', 'createPDF', '', ex);
            return null;
        } 
    } 
    
    //Create content version
    private ContentVersion createContentVersion(Blob pdfBlob){
        ContentVersion cv = new ContentVersion();
        cv.Title = quoteData.PED_Quote_PDF_Type__c+' - '+FileNo;
        cv.PathOnClient = quoteData.PED_Quote_PDF_Type__c+' - '+FileNo+'.pdf';
        cv.VersionData =  pdfBlob;
        cv.IsMajorVersion = true;
        Insert cv;
        return cv;
    }
    
    //Create ContentDocumentLink 
    private ContentDocumentLink createContentDocumentLink(Id conDocId){
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = quoteData.Id ;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        return cdl;
    }
    
    // Convert an INR amount to words
    public static String convertINRAmountToWords(Long amount)  {
        if (amount < 10) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.UNITS[intAmount];
        }
        
        if (amount < 20) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.TEENS[intAmount - 10];
        }
        
        if (amount < 100) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.TENS[intAmount / 10] + ' ' + GlobalConstants.UNITS[math.mod(intAmount,10)];
        }
        
        if (amount < 1000) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.UNITS[intAmount / 100] + ' ' +GlobalConstants.HUNDRED + ' ' + convertINRAmountToWords(math.mod(amount, 100));
        }
        
        if (amount < 100000) {
            return convertINRAmountToWords(amount / 1000) + ' ' +GlobalConstants.THOUSAND  + ' ' + convertINRAmountToWords(math.mod(amount, 1000));
        }
        
        if (amount < 10000000) {
            return convertINRAmountToWords(amount / 100000) + ' ' +GlobalConstants.LAKH  + ' ' + convertINRAmountToWords(math.mod(amount,100000));
        }
       
        return convertINRAmountToWords(amount / 10000000) + ' ' +GlobalConstants.CRORE  + ' ' + convertINRAmountToWords(math.mod(amount, 10000000)); 
    }
    
    // Convert a USD amount to words
    public static String convertUSDAmountToWords(Long amount)  {               
        if (amount < 10) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.UNITS[intAmount];
        }
        
        if (amount < 20) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.TEENS[intAmount - 10];
        }
        
        if (amount < 100) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.TENS[intAmount / 10]  + ' ' + GlobalConstants.UNITS[math.mod(intAmount,10)];
        }
        
        if (amount < 1000) {
            Integer intAmount = amount.intValue();
            return GlobalConstants.UNITS[intAmount / 100] + ' ' +GlobalConstants.HUNDRED + ' ' + convertUSDAmountToWords(math.mod(amount, 100));
        }
        
        if (amount < 1000000) {
            return convertUSDAmountToWords(amount / 1000) + ' ' +GlobalConstants.THOUSAND  + ' ' + convertUSDAmountToWords(math.mod(amount, 1000));
        }
        
        if (amount < 1000000000) {
            return convertUSDAmountToWords(amount / 1000000) + ' ' +GlobalConstants.MILLION  + ' ' + convertUSDAmountToWords(math.mod(amount,1000000));
        }
       
        if(amount < Long.valueOf(GlobalConstants.One_Trillion)){
            return convertUSDAmountToWords(amount / 1000000000) + ' ' +GlobalConstants.BILLION  + ' ' + convertUSDAmountToWords(math.mod(amount, 1000000000)); 
        }
        return convertUSDAmountToWords(amount / Long.valueOf(GlobalConstants.One_Trillion)) + ' ' +GlobalConstants.TRILLION  + ' ' + convertUSDAmountToWords(math.mod(amount, Long.valueOf(GlobalConstants.One_Trillion))); 
    }
    
     // Wrapper class for QuoteLineItem
    public class QliWrapperClass{
    	public QuoteLineItem qliRecord {get;set;}
        public String formattedQliSalesPrice {get;set;}
        public String formattedQliTotalSalesPrice {get;set;}
        public String formattedQliQuantity {get;set;}
    }
}