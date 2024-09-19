public without sharing class QuotationController {
    
    public Contact Contacts {get; set;}
    public Opportunity Opportunities {get; set;}
    public Quote Quotes {get; set;}
    public Account Account {get; set;}
    public Address__c  Address {get; set;}
    public User User {get; set;}
    public User SalesRep {get; set;}
    public List<QuotelineItem> QuotelineItem_AAC {get; set;}
    public List<QuotelineItem> QuotelineItem_RCM {get; set;}
    public List<QuotelineItem> QuotelineItem_RMC {get; set;}
    private List<QuotelineItem> QuotelineItems = new List<QuotelineItem>();
    public string additionalPaymentTerms {get; set;}
    public string specialRequirement {get; set;}
    
    public QuotationController(){
        QuotelineItem_AAC = new List<QuotelineItem>();
        QuotelineItem_RCM = new List<QuotelineItem>();
        QuotelineItem_RMC = new List<QuotelineItem>();
        Id QuoteId = Apexpages.currentPage().getparameters().get('Id');
        Quotes = [Select Id,Name,AccountId,OpportunityId,Contact.Phone,QuoteNumber,CreatedDate,QuoteToName,Plant_Location__c,Site__c,toLabel(Payment_Terms__c),Pumping_charges_per_cuM__c,Total_pumping_charges__c,
                  Basic_cement_rate__c,Diesel_Escalation_rate__c,Minimum_Pumping_Quantity__c,Additional_Payment_Terms__c,Payment_Terms_more_Information__c,Cluster__c,Special_Instructions__c,Area_Code__c,
                  Special_remarks__c,Internal_Sales_Representative__c,Primary_Address__c from Quote where Id =: QuoteId Limit 1]; //Added Contact.Phone by Sreekanth jujare on 13/07/2022 for the usage in VF page
        Account = [Select Primary_Address__c,Name from Account where Id =: Quotes.AccountId];
        //Address = [Select House_Number__c , Building__c ,Street__c , City_2__c,City__c from Address__c  where id=: Account.Primary_Address__c];
        User = [Select User_Signature__c, Name, Title, MobilePhone, Email from User where id =:Userinfo.getUserId()];
        SalesRep = [Select User_Signature__c, Name, Title, MobilePhone, Email from User where id =: Quotes.Internal_Sales_Representative__c];
        
        //Modified the ORDER BY with Product_Sequence_Value__c field in QuotelineItem_AAC and QuotelineItem_RCM by Sreekanth Jujare on 02/08/2022
        QuotelineItem_AAC = [Select Id,Product_Name__c,UnitPrice,C_GST__c,S_GST__c,Total_Price_with_Customer_Discount__c,
                             Product_Description_N__c, Commodity_Code__c,Inventory_Unit__c,Tax_Rate_Percentage__c,
                             Line_Tax_for_Customer__c,Basic_Rate_per_CbM__c,Basic_Rate_Per_Unit__c,Sales_Amount__c,Product_Name_Construction__c 
                             from QuoteLineItem 
                             where QuoteId=: QuoteId AND Product_Sub_Category__c =: 'AAC' ORDER BY Product_Sequence_Value__c]; 
        QuotelineItem_RCM = [Select Id,Product_Name__c,UnitPrice,C_GST__c,S_GST__c,Total_Price_with_Customer_Discount__c,Product_Description_N__c, 
                             Commodity_Code__c,Inventory_Unit__c,Tax_Rate_Percentage__c,Line_Tax_for_Customer__c,Basic_Rate_per_CbM__c,Basic_Rate_Per_Unit__c,
                             Sales_Amount__c,Product_Name_Construction__c 
                             from QuoteLineItem 
                             where QuoteId=: QuoteId AND Product_Sub_Category__c =: 'RCM' order by Product_Sequence_Value__c]; 
        QuotelineItem_RMC = [Select Id,Product_Name__c,UnitPrice,C_GST__c,S_GST__c,Total_Price_with_Customer_Discount__c,Product_Description_N__c,
                             Commodity_Code__c,Inventory_Unit__c,Tax_Rate_Percentage__c,Line_Tax_for_Customer__c,Basic_Rate_per_CbM__c,Basic_Rate_Per_Unit__c,Sales_Amount__c 
                             from QuoteLineItem 
                             where QuoteId=: QuoteId AND Product_Sub_Category__c =: 'RMC'order by Product_Name__c];      
        //REMOVED THE HARD CODED VALUES AND ADDED GLOBAL CONSTANT VALUE IN BOTH FOLLOWING CONDITIONS BY SREEKANTH JUJARE ON 04/08/2022
        //For RMC Quote
        if(Quotes.Payment_Terms_more_Information__c != null){ 
            additionalPaymentTerms = Quotes.Payment_Terms_more_Information__c;
        }else{ additionalPaymentTerms = GlobalConstants.NOT_APPLICABLE; }   
        //For RCM Quote
        if(Quotes.Special_remarks__c != null){
            specialRequirement = Quotes.Special_remarks__c;}
        else{ specialRequirement = GlobalConstants.NOT_APPLICABLE; } 
        
    }      
}