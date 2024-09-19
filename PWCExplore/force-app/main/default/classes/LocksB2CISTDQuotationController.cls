public class LocksB2CISTDQuotationController {
    public Quote quoteData {get; set;} //fetching Quote Data   
    public User userData {get; set;} //fetching Quote Data   
    public List<QuotelineItem> listQuoteLineItems{get; set;} //fetching QuotelineItems
    public Id quoteId {get;set;} // To get Quote Record
    public String Today { get;set;}
    public String QuoteExpiryDate {get;set;}
    public String errorMessage {get;set;}
    
     public LocksB2CISTDQuotationController(ApexPages.StandardController standardController){  
         try{ 
            quoteId = standardController.getId();   
            Today = Date.today().format(); // To fetch Today's Date
            quoteData =  getQuote(quoteID); // To fetch Quote Data
            QuoteExpiryDate=quoteData.ExpirationDate.format();
            listQuoteLineItems=getlistQuoteLineItems(quoteId); // To fetch All Qli's for related quote record.
            userData=getUser(quoteData.CreatedById); // To fetch User Data of Quote Created By User
         }
         catch(Exception ex){
            	errorMessage=ex.getMessage();
             	apexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, errorMessage));
                Logger.logError('QuoteRecordProcessor', 'LocksB2CISTDQuotationController', '', ex);
         } 
     }
        
      public Quote getQuote(Id quoteID){                          
          return[Select Id,Name,Opportunity.Enquiry_Number__c,QuoteNumber,Account_Name__r.Name,Account_Name__r.Account_Code__c,Opportunity.Retailer__r.Name,
                 Opportunity.Retailer__c,Opportunity.First_Name__c,Opportunity.Last_Name__c,Total_Sales_Price__c,Total_Tax_Amount__c,Total_Amount__c,
                 ExpirationDate,Delivery_Period__c,payment_terms__c,CreatedById from Quote where Id=:quoteID limit 1];           
      }
    
      public List<QuoteLineItem> getlistQuoteLineItems(Id quoteId){
          return[Select Id,QuoteId,Product2.Search_Key_II__c,Product2.Description,Quantity,MRP__c,Discount__c,
                 Customer_Sales_Price__c,Tax_Rate_Percentage__c,Customer_Sales_Price_Tax__c,Retailer_Retention__c,
                 Distributor_Retention__c,UnitPrice from QuoteLineItem where QuoteId=:quoteID and Status__c!=:GlobalConstants.QliLostStatus];
      }
    
     public User getUser(Id userId){
          return[Select Id,Name,MobilePhone from User where Id=:userId limit 1];
      }
}