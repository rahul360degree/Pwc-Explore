/**
* @description       : Controller class for Interio B2B Quotation PDF
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 22-06-2023
* @last modified by  : snehalw@godrej.com
**/

public class InterioB2BQuotatationController {
    
    
    public Opportunity opportunityData {get; set;}//fetching Opportunity Data
    public Quote quoteData {get; set;} //fetching Quote Data
    public Account accountData {get; set;} //fetching Account Data
    public String productLines {get; set;}
    public String pendingWithOwner {get; set;}
    public List<QuotelineItem> listQuoteLineItems{get; set;} //fetching QuotelineItems
    
    public List<Quote_Approval_History__c> listQuoteApprovalHstry{get; set;} //fetching quoteApprovalHstry data
    public List<Summation> lstSummations {get; set;} // Wrapper class list to use as a property in VF page
    
    public List<SummationNew> listWrapper {get;set;} // Wrapper class list to use as a property in VF page
    public Id QuoteId {get;set;} // To get Quote Record
    
    public Boolean displayCOP {get;set;}
    public Boolean hideCOP {get;set;}
    
    private final Quote quoteRec; // To get the record for attachment
    
    public Quote getQuote(Id quoteID){
        return [Select Id,Name,AccountId,OpportunityId,CreatedById,CreatedBy.Name,ContactId,QuoteNumber,CreatedDate,Interio_Sub_Division__c,
                Scope_of_Architect__c,Strategy_to_Win__c,Transaction_through_WD_Dealer_Investment__c,Buyer_Segment__c,Opportunity_Type__c,
                Reason_for_Discount__c,LD_Clause__c,Details_of_LD_Clause__c,Delivery_Period_in_weeks__c,Delivery_Location__c,
                Validity_Period_Approved__c,Req_WD_Ret_Disc_Basic__c,Req_WD_Ret_Cons_Basic__c,Appr_WD_Ret_Disc_Basic__c,Appr_WD_Ret_Cons_Basic__c,Req_WD_CONT__c,
                Req_WD_CONT_Cons_Basic__c,Appr_WD_CONT_Disc_Basic__c,Appr_WD_CONT_Cons_Basic__c,Req_Net_Rlizd_Disc_Cons_Basic__c,Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c,
                Total_List_Price__c,Req_Cust_Disc__c,Total_Sales_Price__c,App_Cust_Disc__c,Total_Approved_Customer_Discount_Price__c,Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c,
                Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c,Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c,Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c,Req_WD_CONT_Amt_on_Req_Disc_bsc__c,Req_WD_CONT_amt_on_cons_bsc__c,
                Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c,Appr_WD_CONT_Amt_On_Cons_Bsc__c,Req_Net_Rlizd_Basic_Rate_Cons__c,Appr_Net_Rlizd_Basic_Rate_Cons__c,
                COP__c,Requested_COP_Factor__c,Approved_COP_Factor__c,LOBSummaryTotal__c,Last_Disc_Sanctioned__c,Warranty__c    
                ,Contact.Title,Contact.Department,Dealer_Name__r.Account_Code__c,Dealer_Name__r.Name,Validity_Period_Req__c,
                Delivery_Period_Appr_in_weeks__c,Warranty_APO_No__c,Pending_Since_Date__c,Warranty_Approved__c,Approval_Status__c,Payment_Terms__c,
                Dealer_Involved_Y_N__c,Is_KAM__c,Transaction_Type_c__c,toLabel(Transaction_Type__c) from Quote where Id =: quoteId Limit 1]; 
        
    }
    public Account getAccount(Id quoteId){
        return [Select Is_Key_Account__c,Name,Account_Code__c,Primary_Contact__r.Name from Account where Id =: quoteData.AccountId];  
    }
    
    public Opportunity getOpportunity(Id quoteId){
        return [Select Name,Id,Segment__c,Transaction_Type__c,Account.Name,Account.RecordType.Name,End_Customer__r.name,Product_Loyality__c,
                Influencer__c,Competitor__c,Competitor_If_Other__c,Order_Type__c ,Dealer_Involved_Y_N__c,Influencer_Contact__c, 
                toLabel(Sales_Branch_Name__c),CreatedBy.Name,Buyer_Interio_Segment__c,Enquiry_Number__c,Primary_contact__r.Name, Payment_Terms__c,Influencer__r.Name,Dealer_Name__r.Name,AccountId,Dealer_Name__r.Account_Code__c,RecordTypeId,RecordType.Name,Opportunity_Type__c,Influencer__r.Primary_contact__r.Name From Opportunity
                where Id=: quoteData.OpportunityId LIMIT 1];
    }
    public  List<Quote_Approval_History__c> getQuoteApprovalHstry(Id quoteId){
        return  [ Select Id, Approval_Comments__c, CreatedBy.Name, Quote__r.Opportunity_Owner__r.Name,CreatedDate,Status__c from Quote_Approval_History__c 
                 where Quote__c =:quoteId 
                 Order by createdDate desc
                ];  
        
        
    }
    public List<QuoteLineItem> getlistQuoteLineItems(Id quoteId){
        return [Select  ListPrice,Id,toLabel(Product_Line_c__c),Quantity,Effective_Pricebook_Date__c,Description, Requested_Customer_Discount__c, UnitPrice,
                Approved_Customer_Discount__c,Approved_Customer_Discounted_Basic_Price__c,Req_WD_Ret_SAC_OnReqDiscBasic__c,
                Req_WD_Ret_Amt_SACConsBasic__c,Approved_WD_Retention_On_ReqDiscbasic__c,Apr_WD_Ret_Amt_SACConsBasic__c, Requested_WD_CONT_Req_Disc_Basic__c,
                Req_WD_CONT_Amt_Consumer_Basic__c,Approved_WD_CONT__c,Approved_WD_CONT_Amt_Consumer_Basic__c,Req_Net_Rlizd_Bsc_Disc__c,
                Req_Net_Realizd_BsicAmnt_Rate_Unit__c,Approved_Net_Realized_Basic_Discount__c,Approved_Net_Realized_Basic_Rate_Unit__c,
                COP__c,Requested_COP_Factor__c,Approved_COP_Factor__c,Product_Name__c,Current_Approver__c,Pending_With_Owner__c,Item_Code__c
                from QuoteLineItem  where QuoteId=: QuoteId ORDER BY Product_Line_c__c];
        
    }
    //Constructor
    public InterioB2BQuotatationController(ApexPages.StandardController standardController){
        quoteRec = (Quote)standardController.getRecord();
        QuoteId = standardController.getId();
        quoteData =  getQuote(quoteID);
        accountData = getAccount(quoteId);
      
        listQuoteApprovalHstry = getQuoteApprovalHstry(quoteId);
        listQuoteLineItems = getlistQuoteLineItems(quoteId);
        opportunityData = getOpportunity(quoteId);
        //To  display data as per Productline
        Map<String,List<QuoteLineItem>> lobVsQliMap = new  Map<String,List<QuoteLineItem>>();
        List<QuoteLineItem> qliList=new List<QuoteLineItem>();
        Set<String> productLineSet= new Set<String>(); // To Display Send All Line Items in Email Template Table.
        Map<String,String> currentApproverIdVsNameMap = new Map<String,String>();
        String newLob;
        String oldLob; 
        Boolean flag = true ;           
        for(QuoteLineItem QLI : listQuoteLineItems){
            productLineSet.add(qli.Product_Line_c__c);// added product line in set
            if(qli.Current_Approver__c!='' && qli.Current_Approver__c!=null)
            {
                currentApproverIdVsNameMap.put(qli.Current_Approver__c, qli.Pending_With_Owner__c);
            }
            newLob = QLI.Product_Line_c__c;         
            if(flag==true)
            {
                oldLob = QLI.Product_Line_c__c;
                
                flag=false;            }
            if(newLob==oldLob )
            {
                qliList.add(QLI);
                oldLob=QLI.Product_Line_c__c;
            }
            else if(oldLob != newLob){
                lobVsQliMap .put(oldLob,qliList);
                qliList=new List<QuoteLineItem>();
                qliList.add(QLI);
                oldLob=QLI.Product_Line_c__c;
                
            }
        }
        lobVsQliMap.put(oldLob,qliList);
        productLines = productLineSet.toString().replaceAll('[{}]',''); // converted to string
        
        // parsed JSON to store the values in field
        String strJson = quoteData.LOBSummaryTotal__c;
        
        lstSummations =(List<Summation> )JSON.deserialize(strJson,List<Summation>.class);
        
        listWrapper=new List<SummationNew>();
        for(Summation obj : lstSummations){
            if(lobVsQliMap.containsKey(obj.LOB))
            {
                SummationNew sum1=new SummationNew();
                sum1.qliList=LobVsQliMap.get(obj.LOB);
                sum1.sumRecord=obj;
                listWrapper.add(sum1);
            }
        }
        pendingWithOwner =  displayOwner(currentApproverIdVsNameMap );
        checkUserPersona();
    }
    
    // to display pending with owner on pdf
    public static String displayOwner(Map<string,String> currentApproverIdVsNameMap ){
        set<string> pendingWithOwnerSet = new set <string>(); // pending with owner set
        Boolean isPendingWithAnyHO=false;// to check QLI pending with any HO
        Boolean isPendingWithUser= false; // to check QLI pending with which user     
        String currentApproverId;
        if(!currentApproverIdVsNameMap.isEmpty()){ 
            for(string  qli: currentApproverIdVsNameMap.keySet()){
                if(qli.startsWith('005')){
                    isPendingWithUser = true ; 
                    currentApproverId = qli ;
                }else {
                    isPendingWithAnyHO = true ;
                }
            }
            if(isPendingWithUser == true && isPendingWithAnyHO == true ){ // if pending with any HO then it will not available to VP
                currentApproverIdVsNameMap.remove(currentApproverId);
            }  
            for(string  qli: currentApproverIdVsNameMap.keySet()){ 
                pendingWithOwnerSet.add(currentApproverIdVsNameMap.get(qli)); 
            }
            
            return (pendingWithOwnerSet.toString().replaceAll('[{}]','')); // converted to string  
        }
        return null;
    }
    //Added by snehal w 27th feb 2023
    // Depend on persona need to hide and display cop fields
    public void checkUserPersona(){
        User userDetail = [Select Id,Persona__c from User where Id = :UserInfo.getUserId() limit 1];
        if(userDetail.Persona__c != Null && (userDetail.Persona__c == GlobalConstants.Interio_HO_PERSONA || userDetail.Persona__c == GlobalConstants.PERSONA_VP ||userDetail.Persona__c ==GlobalConstants.Interio_BH_PERSONA) ){
            displayCOP=true;// display cop fields for HO,VP,BH
            hideCOP=false;
        }
        else
        {
            displayCOP=false;
            hideCOP=true;// Hide cop fields for sales persona,Manager,RM,ZH
        }
    }
    //Added by snehal w 27th feb 2023
    // pdf attachment in notes and files for sales persona,Manager,RM,ZH
    public PageReference createPDF()
    { 
        if(GlobalConstants.interioB2BPage == true   ){
            //generate and attach the PDF document
            PageReference pdfPage = Page.InterioB2BQuotation;// page reference
            pdfPage.getParameters().put('id',quoteRec.Id);
            Blob pdfBlob; //create a blob for the PDF content
            pdfBlob = Test.isRunningTest() ? Blob.valueOf('generate pdf') : pdfPage.getContent();
            
            // created content version
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Print View.pdf';
            cv.PathOnClient = 'Print View.pdf';
            cv.VersionData =  pdfBlob;
            cv.IsMajorVersion = true;
            Insert cv;
            
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = quoteRec.Id ;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;
            
            GlobalConstants.interioB2BPage = false;
            
            //redirect the user
            PageReference pageRef = new ApexPages.StandardController(quoteRec).view();
            pageRef.setRedirect(true); 
            return pageRef ;
        }
        return null;
    } 
    
    // wrapper class to parse the JSON
    public class SummationNew{
        public List<QuoteLineItem> qliList {get;set;}
        public Summation sumRecord {get;set;}
    }
    
    //Wrapper class to get summary total values as per product line
    public class Summation{
        public String LOB  {get; set;}
        public String summation_listPrice  {get; set;}
        public string summation_unitPrice  {get; set;}
        public string summationApprovedCustomerDiscountedBasicPrice  {get; set;}
        public string summationReqWDRetSACOnReqDiscBasic  {get; set;}
        public string summationAppWDRetReqDiscbasic  {get; set;}
        public string summationReqWDCONT  {get; set;}
        public string summationApprovedWDCONT  {get; set;}
        public string summationReqNetRealizdBsicAmntRateUnit  {get; set;}
        public string summationApprovedNetRealizedBasicRateUnit  {get; set;}
        public string summationCOPperUnit  {get; set;}
        public string summationRequestedCOPFactor  {get; set;}
        public string summationApprovedCOPFactor  {get; set;}
        public string summationReqWDRetSACOnReqDiscBasic_Percentage  {get; set;}
        public string summationReqWDRetSACOnConsumerBasic_Percentage  {get; set;}
        public string summationAppWDRetReqDiscBasic_Percentage  {get; set;}
        public string summationAppWDRetConsumerBasic_Percentage  {get; set;}
        public string summationReqWDCONTOnReqDiscBasic_Percentage  {get; set;}
        public string summationReqWDCONTOnConsumerBasic_Percentage  {get; set;}
        public string summationApprovedWDCONTOnReqDiscBasic_Percentage  {get; set;}
        public string summationApprovedWDCONTOnConsumerBasic_Percentage  {get; set;}
        public string summationUnitPrice_Percentage  {get; set;}
        public string summationApprovedCustomerDiscountedBasicPrice_Percentage  {get; set;}
        public string summationReqNetRealizdBsicAmntRateUnit_Percentage  {get; set;}
        public string summationApprovedNetRealizedBasicRateUnit_Percentage  {get; set;}
    }
}