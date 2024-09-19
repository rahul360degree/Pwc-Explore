/**
 * @description       : Added qliMap map to remove duplicate OpportunityLineItem
 * @author            : 
 * @group             : 
 * @last modified on  : 03-31-2023
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class SyncQuoteCustomField{
  public static Boolean SyncQuoteCustomFieldDisabled = false;

  public static void syncQuoteLineItem(List<QuoteLineItem> lstQuoteLine){
      if(SyncQuoteCustomFieldDisabled == true)
          return;
      //setting the static variable to ensure syncQuoteLineItem runs only once
      SyncQuoteCustomFieldDisabled = true;

    List<OpportunityLineItem> lstOppProduct=new List<OpportunityLineItem>();
    //Added qliMap map to remove duplicate OpportunityLineItem. https://gnbdigitalprojects.atlassian.net/browse/GTP-213
    Map<Id,QuoteLineItem> qliMap = new Map<Id,QuoteLineItem>();
    for(QuoteLineItem qlVar: lstQuoteLine){
      // Added recordType check to bypass for PED Division by Rohit Jadhav on 4th july 2023
      if(qlVar.Quote_Record_Type__c!=GlobalConstants.PED_QUOTE_RT && !String.isEmpty(qlVar.Opportunity_Line_Item_ID__c)){
        if(qliMap == null ||  ( qliMap != null && 
            (!qliMap.containskey(qlVar.Opportunity_Line_Item_ID__c) ||   (qliMap.containskey(qlVar.Opportunity_Line_Item_ID__c) && qliMap.get(qlVar.Opportunity_Line_Item_ID__c).CreatedDate < qlVar.CreatedDate )   )  
        )){
          qliMap.put(qlVar.Opportunity_Line_Item_ID__c,qlVar);
        }
      }
    }

    if(!qliMap.isEmpty()){
     for(QuoteLineItem qlVar: qliMap.values()){
      //for(QuoteLineItem qlVar: lstQuoteLine){
       if(qlVar.Opportunity_Line_Item_ID__c!=null){
         OpportunityLineItem oppPrdVar=new OpportunityLineItem(Id=qlVar.Opportunity_Line_Item_ID__c);
         if(Schema.sObjectType.OpportunityLineItem.isUpdateable()){ 
         oppPrdVar.Contract_Type__c=qlVar.Contract_Type__c;
         oppPrdVar.Number_Of_Shifts__c=qlVar.Number_Of_Shifts__c;
         oppPrdVar.Contract_Start_Date__c=qlVar.Contract_Start_Date__c;
         oppPrdVar.Contract_End_Date__c=qlVar.Contract_End_Date__c;
         oppPrdVar.Lubricants_Included__c=qlVar.Lubricants_Included__c;
         oppPrdVar.Uptime_Required__c=qlVar.Uptime_Required__c;
         oppPrdVar.Payment_Terms__c=qlVar.Payment_Terms__c;
         oppPrdVar.Discount__c=qlVar.Total_Approved_Discount__c;
         oppPrdVar.Sequence_Number__c = qlVar.Sequence_Number__c;
       } 
         //For MHE Rentals
         if(qlVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL)
         {
           if(Schema.sObjectType.OpportunityLineItem.fields.Description.isUpdateable()){
           oppPrdVar.Description = qlVar.Description;
            }
         }

         lstOppProduct.add(oppPrdVar);
       }
     }
    }
      if(Schema.sObjectType.OpportunityLineItem.isUpdateable()){ 
          if(lstOppProduct.size()>0)
              update lstOppProduct;
        }
             
 }
}