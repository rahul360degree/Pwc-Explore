/* --------------------------------------------------------------------
Author: Sreekanth Jujare
Written for: Quotation PDF for Security Solutions
Visualforce Page: ssdQuotePdf
-----------------------------------------------------------------------*/

public class SsdQuotationController {
    public Quote quoteData {get; set;}
    public List<QuotelineItem> qlisData {get; set;}
    public List<ProcessInstanceWorkItem> apprData {get; set;}
    public List<ProcessInstanceStep> apprHist {get; set;}
    public List <WrapperClass> wrapperList{get; set;}
    public Id QuoteId {get;set;}
    public decimal totalQty{get;set;}
    public decimal totalUnitPrice{get;set;}
    public decimal totalGSTPu{get;set;}
    public decimal totalAmount{get;set;}
    
    // CONSTRUCTOR CLASS
    public SsdQuotationController(ApexPages.StandardController standardController){
        QuoteId = standardController.getId(); 
        quoteData = getQuote(QuoteId);
        qlisData = getQlis(QuoteId);
        wrapperList=new List<WrapperClass>();
        approvalStep(QuoteId);
        String Qnumber = 'inline; filename=' + System.Label.Discount_Saction + '_' + quoteData.QuoteNumber + '.pdf';
        Apexpages.currentPage().getHeaders().put('content-disposition', Qnumber);
    }    
    
    public Quote getQuote(Id quoteId){
        return[Select Id, Name,QuoteNumber, OpportunityId, Opportunity.Name, Opportunity.Enquiry_Number__c,
               Opportunity.End_customer_segment_SSD_If_Others__c,AccountId, Account.Name, ContactId, Contact.Name, 
               Contact.Title, Contact.Salutation, Address__c, OwnerId,Owner.Name, Owner.Title, Owner.Phone, Special_Instructions__c, 
               Delivery_Period__c,toLabel(Payment_Terms__c),Sales_Branch_Name__c,Dealer_Code__c,Associated_Dealer__r.Name,
               Transaction_Type__c, Booking_Option__c, toLabel(End_Customer_Segment_SSD__c),Sold_to_Address__r.Address_Code_Formula__c,
               Ship_to_Address__r.Address_Code_Formula__c, ExpirationDate,Approval_Status__c,
               (Select Id, ListPrice, UnitPrice,Product2.Name, Product_Name__c, GST_per_unit_SSD__c, Quantity,
                Sales_Price_Tax_Included__c,Product2.Item__c, Requested_Customer_Discount__c,
                Sales_Expenses_SSD__c, Min_Retention_SSD__c, Regular_Delivery_and_Installation_SSD__c,
                Extra_Delivery_and_Installation_SSD__c, Extra_WD_Retention_SSD__c, Approved_Max_Outflow_SSD__c,Sales_Price_AppOutflow_SSD__c
                From QuoteLineItems)
               From Quote Where Id =: quoteId];
    }
    public List<QuoteLineItem> getQlis(Id quoteId){
        totalQty=0;
        totalUnitPrice=0;
        totalGSTPu=0;
        totalAmount=0;
        for(QuoteLineItem item:quoteData.QuoteLineItems){
            Integer Qty=item.Quantity !=null?(Integer)item.Quantity:0;
            Decimal SPU=item.UnitPrice !=null?item.UnitPrice:0;
            Decimal GSTPU=item.GST_per_unit_SSD__c != null?item.GST_per_unit_SSD__c:0;
            Decimal TA=item.Sales_Price_Tax_Included__c != null? item.Sales_Price_Tax_Included__c:0;
            totalQty+=Qty;
            totalUnitPrice+=SPU;
            totalGSTPu+=GSTPU;
            totalAmount+=TA;		            
        }
        return quoteData.QuoteLineItems;
    }
    public User getUser(Id quoteId){
        return[Select Id, Name, Title, MobilePhone From User Where Id =: quoteData.OwnerId];
    }
    public void approvalStep(Id quoteId){ 
        String entryBy;
        String entryOn;
        String approvalStatus;
        for(ProcessInstanceStep processStep: [Select id,StepStatus,ProcessInstance.TargetObjectId,OriginalActorId,OriginalActor.Title,ActorId,Actor.Name,Comments,
                                              SystemModStamp from ProcessInstanceStep where ProcessInstance.TargetObjectId =:quoteId ORDER BY SystemModStamp])
        {
            
            if(processStep.StepStatus == GlobalConstants.STARTED){ 
                approvalStatus=GlobalConstants.SUBMITTED;
            }
            else if(processStep.StepStatus == GlobalConstants.Rejected){
                approvalStatus=GlobalConstants.Rejected;
            }
             else{
                approvalStatus=GlobalConstants.APPROVED;
            }
            WrapperClass wrapperInstance=new WrapperClass();
            wrapperInstance.Role=processStep.OriginalActor.Title;
            wrapperInstance.Status=approvalStatus;
            wrapperInstance.EntryBy=processStep.Actor.Name;
            wrapperInstance.EntryOn=processStep.SystemModStamp.format('dd/MM/yyyy HH:mm');
            wrapperInstance.Comments=processStep.Comments;
            wrapperList.add(wrapperInstance);
        }
        for(ProcessInstanceWorkItem processWorkItem: [Select id,ProcessInstance.TargetObjectId,OriginalActorId,OriginalActor.Title,ActorId,
                                                      Actor.Name,SystemModStamp from ProcessInstanceWorkItem where ProcessInstance.TargetObjectId =:quoteId])
        {
            approvalStatus=GlobalConstants.PENDING;
            WrapperClass wrapperInstance=new WrapperClass();
            wrapperInstance.Role=processWorkItem.OriginalActor.Title;
            wrapperInstance.Status=approvalStatus;
            wrapperInstance.EntryBy=processWorkItem.Actor.Name;
            wrapperInstance.EntryOn=processWorkItem.SystemModStamp.format('dd/MM/yyyy HH:mm');
            wrapperList.add(wrapperInstance);
        }
    }
    
    public PageReference createPDF(){ 
        //generate and attach the PDF document
        PageReference pdfPage = Page.ssdQuotePdf;// page reference
        pdfPage.getParameters().put('id',quoteData.Id);
        Blob pdfBlob; //create a blob for the PDF content
        pdfBlob = Test.isRunningTest() ? Blob.valueOf('generate pdf') : pdfPage.getContent();
        
        // created content version
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quotation.pdf';
        cv.PathOnClient = 'Quotation.pdf';
        cv.VersionData =  pdfBlob;
        cv.IsMajorVersion = true;
        Insert cv;
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = quoteData.Id ;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V'; 
        Insert cdl;
        
        //redirect the user
        PageReference pageRef = new ApexPages.StandardController(quoteData).view();
        pageRef.setRedirect(true); 
        return pageRef;
    } 
    
    public class WrapperClass{
        public String Role {get;set;}
        public String Status {get;set;}
        public String EntryBy {get;set;}
        public String EntryOn {get;set;}
        public String Comments {get;set;}
    }
}