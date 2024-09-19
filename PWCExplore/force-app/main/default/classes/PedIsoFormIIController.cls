/**
* @description       : Used as Controller class for PEDIsoFormPdf vf page..
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
public class PedIsoFormIIController {
    public Order orderData {get; set;}
    public Id OrderId {get;set;}
    public String Today { get;set;}
    public String EndUserName { get;set;}
    public Integer TotalOrderProductQuantity { get;set;}
    
     // CONSTRUCTOR CLASS
    public PedIsoFormIIController(ApexPages.StandardController standardController){
        try{
            Today = Date.today().format(); // To fetch Today's Date
            EndUserName='';
            TotalOrderProductQuantity=0;        
            OrderId = standardController.getId();
            orderData = getOrder(OrderId);
            EndUserName=orderData.Opportunity.End_User__c!='NEW END USER' ?orderData.Opportunity.End_User__c : orderData.Opportunity.Name_of_New_End_User__c;
            getOrderProductQuantity(OrderId);
        }
        catch(Exception ex){
            Logger.logError('PedIsoFormIIController', 'PedIsoFormIIController', '', ex);
        }        
    }
    
    // Retrieve an Order based on the provided orderId
    public Order getOrder(Id orderId){
        return[Select Id,Opportunity.End_User__c,Opportunity.Name_of_New_End_User__c,Quote.Level_1_Approver__r.Name,
               Design_Manager__r.Name From Order Where Id =: orderId Limit 1];
    }
    
    // Calculate and set the total quantity of Order Products
    public void getOrderProductQuantity(Id orderId){
        AggregateResult ar=[Select SUM(Quantity) totalQuantity from OrderItem where OrderId=:orderId];
        TotalOrderProductQuantity=  Integer.valueOf((Decimal)ar.get('totalQuantity'));
    }
   
    // Create a PDF and attach it to the Order
    public PageReference createPDF(){ 
        //generate and attach the PDF document
        PageReference pdfPage = Page.PedIsoFormIIPdf;// page reference
        pdfPage.getParameters().put('id',orderData.Id);
        Blob pdfBlob; //create a blob for the PDF content
        pdfBlob = Test.isRunningTest() ? Blob.valueOf('generate pdf') : pdfPage.getContent();
        
        // create content version
        ContentVersion cv = createContentVersion(pdfBlob);
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = createContentDocumentLink(conDocId);
        
        //redirect the user
        PageReference pageRef = new ApexPages.StandardController(orderData).view();
        pageRef.setRedirect(true); 
        return pageRef ;
    } 
    
    private ContentVersion createContentVersion(Blob pdfBlob){
        ContentVersion cv = new ContentVersion();
        cv.Title = 'ISO Form II.pdf';
        cv.PathOnClient = 'ISO Form II.pdf';
        cv.VersionData =  pdfBlob;
        cv.IsMajorVersion = true;
        Insert cv;
        return cv;
    }
    
    private ContentDocumentLink createContentDocumentLink(Id conDocId){
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = orderData.Id ;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        return cdl;
    }
    
    // Invocable method to generate ISO Form II
    @InvocableMethod
    public static void generateISOFormII(List<InvocableMethodParameter> parameters) {
        try{
            String orderRecordId=parameters[0].orderRecordId;
            Order orderRec =[Select ID FROM Order where Id=:orderRecordId];
            ApexPages.StandardController sc = new ApexPages.StandardController(orderRec);
            PedIsoFormIIController cae=new PedIsoFormIIController(sc);
            cae.createPDF();            
        }
        catch(Exception ex){
            Logger.logError('PedIsoFormIIController', 'generateISOFormII', '', ex);
        }
    }
    
    // Inner class to define InvocableMethodParameter
    public class InvocableMethodParameter {
        @InvocableVariable(required=true)
        public String orderRecordId;
    }
}