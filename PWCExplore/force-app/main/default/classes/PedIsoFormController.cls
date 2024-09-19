/**
* @description       : Used as Controller class for PEDIsoFormPdf vf page.
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
public class PedIsoFormController {
    public Quote quoteData {get; set;}
    public Opportunity oppData {get; set;}
    public Id QuoteId {get;set;}
    public String Today { get;set;}
    public String FileNo { get;set;}
    public String EnquiryRecpeiptDate { get;set;}
    public String EquipmentName { get;set;}
    public String EquipmentType { get;set;}
    public String EstimationDueDate { get;set;}
    public String SalesDueDateTime { get;set;}		//added SalesDueDateTime
    public String MKTG_II { get;set;}
    
     // CONSTRUCTOR CLASS
    public PedIsoFormController(ApexPages.StandardController standardController){
        try{
            Today = Date.today().format(); // To fetch Today's Date
            FileNo='';
            EnquiryRecpeiptDate='';
            EquipmentName='';
            EquipmentType='';
            EstimationDueDate='';
            SalesDueDateTime='';		//added SalesDueDateTime
            QuoteId = standardController.getId();
            quoteData = getQuote(QuoteId);
            MKTG_II=quoteData.Offer_Number__c.substringBetween('PED/ ', '-');
            getOpp(QuoteId);
            getOppProductData(quoteData.OpportunityId);
        }
        catch(Exception ex){
            Logger.logError('PedIsoFormController', 'PedIsoFormController', '', ex);
        }        
    }
    
    // Retrieve a Quote based on the provided QuoteId
    public Quote getQuote(Id quoteId){
        return[Select Id, Name,QuoteNumber,Offer_Number__c,Estimator_Initials__c,OpportunityId, AccountId, ContactId, Address__c, OwnerId,Owner.Name, Owner.Title, Owner.Phone, Special_Instructions__c, Delivery_Period__c,toLabel(Payment_Terms__c) From Quote Where Id =: quoteId Limit 1];
    }
    
    // Retrieve an Opportunity based on the QuoteId and determine FileNo and EnquiryRecpeiptDate
    public void getOpp(Id quoteId){
        Id pedFirmRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_FIRM_OPPORTUNITY_RT).getRecordTypeId();
        oppData= [Select Id, Name, Estimation_Due_Date__c,Sales_Due_Date_Time__c,EST_FILE_NO_Firm__c,EST_FILE_NO_Budgetory__c,Account.Name,Project_Name__c,
               ENQUIRY_RECEIPT_MONTH_FIRM__c,ENQUIRY_RECEIPT_MONTH_BQ__c,RecordTypeId From Opportunity Where Id=: quoteData.OpportunityId Limit 1];
        EstimationDueDate=oppData.Estimation_Due_Date__c!=null ? (oppData.Estimation_Due_Date__c).format() : '';
        SalesDueDateTime=oppData.Sales_Due_Date_Time__c!=null ?(oppData.Sales_Due_Date_Time__c).format() : '';		//added SalesDueDateTime 
        if(oppData.RecordTypeId==pedFirmRecordTypeId)
        {
            FileNo=oppData.EST_FILE_NO_Firm__c;
            EnquiryRecpeiptDate=oppData.ENQUIRY_RECEIPT_MONTH_FIRM__c!=null ?(oppData.ENQUIRY_RECEIPT_MONTH_FIRM__c).format() : '';
            EquipmentType=GlobalConstants.PED_Equipment_Type_FIRM;
         }else{
            FileNo=oppData.EST_FILE_NO_Budgetory__c;
            EnquiryRecpeiptDate=oppData.ENQUIRY_RECEIPT_MONTH_BQ__c!=null ?(oppData.ENQUIRY_RECEIPT_MONTH_BQ__c).format() : '';
            EquipmentType=GlobalConstants.PED_Equipment_Type_BUDGETARY;         
         }
    }
   
    // Retrieve Opportunity Line Items and concatenate Equipment Names
    public void getOppProductData(Id oppId){
        for(OpportunityLineItem item : [Select Id,Equipment_Name__c  From OpportunityLineItem Where OpportunityId=: oppId]){        
 			if(item.Equipment_Name__c!=null)
        	{
               EquipmentName = EquipmentName + item.Equipment_Name__c +', ';	            
            }            
        }
        EquipmentName = EquipmentName!='' ? EquipmentName.Substring(0,EquipmentName.length()-2) : '';
    }
   
    // Create a PDF and attach it to the Quote
    public PageReference createPDF(){ 
        try{
            //generate and attach the PDF document
            PageReference pdfPage = Page.PedIsoFormPdf;// page reference
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
            Logger.logError('PedIsoFormController', 'createPDF', '', ex);
            return null;
        }        
    } 
    
    private ContentVersion createContentVersion(Blob pdfBlob){
        ContentVersion cv = new ContentVersion();
        cv.Title = 'ISO Form I.pdf';
        cv.PathOnClient = 'ISO Form I.pdf';
        cv.VersionData =  pdfBlob;
        cv.IsMajorVersion = true;
        Insert cv;
        return cv;
    }
    
    private ContentDocumentLink createContentDocumentLink(Id conDocId){
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = quoteData.Id ;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        return cdl;
    }
}