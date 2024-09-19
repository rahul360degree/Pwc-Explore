/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for 'Quote Line Item' Trigger
Inputs:        NA
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
10-06-2020      Kartik Shetty     Added method to update asset serial number.
12-06-2020      Kartik Shetty     Added method to populate contract related fields in QLI.
----------------------------------------------------------------------------*/
public with sharing class QLITriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
Checks to see if the trigger has been disabled either by custom setting or by running code
*/
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.QLITriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to handle before Insert event context of Quote Line Item Trigger
Inputs:        list of inserted records

History
08-04-2020      Kishor Kumar     Initial Release
25-05-2020      Kartik Shetty     Added method to update sequence number.
10-06-2020      Kartik Shetty     Added method to update asset serial number.
12-06-2020      Kartik Shetty     Added method to populate contract related fields in QLI.
----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        qliProcessor.populateDefaults((List<QuoteLineItem>) newItems);
         // Added by Rohit Jadhav for PED on 6th july 2023
    	qliProcessor.populateDefaultsPED((List<QuoteLineItem>) newItems);
        //added by siddhesh to populate defaults from OLI to QLI
        qliProcessor.populateFieldsFromOLI((List<QuoteLineItem>) newItems);
        qliProcessor.copyOpportunityProductValuesToQLI((List<QuoteLineItem>) newItems);
        qliProcessor.updateCustomerDiscount((List<QuoteLineItem>) newItems,null);
        qliProcessor.updateSequence((List<QuoteLineItem>)newItems,null,GlobalConstants.Context_Variable_Before); //Modified by shreela on 4th Nov for SAEPB - 44
        qliProcessor.isSecondaryCategoryAorCategoryB((List<QuoteLineItem>)newItems,null); //Added by Shreela on 20th Dec 2023 for SMEPB 111
        qliProcessor.updateSequenceNumber((List<QuoteLineItem>) newItems);
        qliProcessor.updateAssetSerialNumber((List<QuoteLineItem>) newItems);
        qliProcessor.prepopulateContractRelatedFields((List<QuoteLineItem>) newItems, true);
        qliProcessor.setPriceBookForKitchenFileUpload((List<QuoteLineItem>) newItems);
        qliProcessor.setProductLineApprovalType((List<QuoteLineItem>) newItems);  
        QuoteLineRuleEngine.evaluteRule(newItems, null, 'QuoteLineItem',GlobalConstants.Context_Variable_Insert);  //Added GlobalConstants.Context_Variable_Insert by Shreela on 16th January 2023 for SAEPB 44
        qliProcessor.updatePricingApprovalRequestId((List<QuoteLineItem>) newItems);
        //qliProcessor.updateCustomerDiscount((List<QuoteLineItem>) newItems);  
        qliProcessor.updateSalesPrice((List<QuoteLineItem>) newItems);
        qliProcessor.validateSalesPrice((List<QuoteLineItem>) newItems);
        qliProcessor.captureSalesPriceDifference((List<QuoteLineItem>) newItems);
        qliProcessor.updateSalesPriceAccordingToAgeing((List<QuoteLineItem>) newItems,null);
        //Added by Praful 23-Feb-2021
        qliProcessor.populateDurationFields((List<QuoteLineItem>) newItems);
        qliProcessor.updateApprovalStatus((List<QuoteLineItem>) newItems);//Added by pankaj on 16 Nov 2022
        qliProcessor.handleBeforeInsertOrDelete((List<QuoteLineItem>) newItems);
        
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to handle Before Update event context of 'Quote Line Item' Trigger
Inputs:        map of created records

History
08-04-2020      Kishor Kumar     Initial Release
25-05-2020      Kartik Shetty     Added method to update sequence number.
10-06-2020      Kartik Shetty     Added method to update asset serial number.
12-06-2020      Kartik Shetty     Added method to populate contract related fields in QLI.
----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        
        //Normalise QLI
        NormaliseQLIController normaliseQLI = new NormaliseQLIController();
        
        map<Id, QuoteLineItem> oldLines = (Map<Id, QuoteLineItem>) oldItems;
        
        //ADDED BY PRAFUL - 03-09       
        for( QuoteLineItem qli : (List<QuoteLineItem>) newItems.values() ){
            /* 23-04-2022      Alpana S   Change for downward revision on the discount %
Jira #  SSEPB-16 [SSG - Updates for submission of discount approval with buffer]                        
Requirement : The system should not ask the user for approval if it is a downward revision on the discount %.
*/
            //START SSEPB-16
            If (oldLines.get(qli.Id).Approval_Status__c == GlobalConstants.APPROVED_STATUS &&             
                oldLines.get(qli.Id).Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_SSG &&
                qli.Requested_Customer_Discount__c != 0 && qli.Requested_Customer_Discount__c != null &&
                oldLines.get(qli.Id).Approved_Customer_Discount__c > qli.Requested_Customer_Discount__c)                
            {
                GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE = False;  
                break;
            } 
            // END SSEPB-16 
            //Shankar Sahu 8-1-2020 edited for adding ssg quote record type
            if( (qli.Quote_Record_Type__c == 'MHE_Parts' || qli.Quote_Record_Type__c == 'MHE_Contracts' || qli.Quote_Record_Type__c == 'MHE_Equipments' || qli.Quote_Record_Type__c == 'SSG' ) 
               && qli.Approval_Status__c != oldLines.get(qli.Id).Approval_Status__c
               && qli.Approval_Status__c == GlobalConstants.APPROVED_STATUS                
              ){
                  
                  
                  //for customer discount
                  if( (qli.Approved_Customer_Discount__c == 0 || qli.Approved_Customer_Discount__c == null)
                     && 
                     qli.Requested_Customer_Discount__c != 0 && qli.Requested_Customer_Discount__c != null )
                      qli.Approved_Customer_Discount__c = qli.Requested_Customer_Discount__c;
                  
                  //for dealer discount
                  if( (qli.Approved_Dealer_Discount__c == 0 || qli.Approved_Dealer_Discount__c == null)
                     && 
                     qli.Requested_Dealer_Discount__c != 0 && qli.Requested_Dealer_Discount__c != null ) 
                      qli.Approved_Dealer_Discount__c = qli.Requested_Dealer_Discount__c;
                  
              }
        }
        qliProcessor.populateDefaults((List<QuoteLineItem>) newItems.values());
        qliProcessor.updateCustomerDiscount((List<QuoteLineItem>) newItems.values(),GlobalConstants.Context_Variable_Update);  //Added GlobalConstants.Context_Variable_Update by Shreela for SAEPB 44
        qliProcessor.updateSequence((List<QuoteLineItem>) newItems.values(),(Map<Id, QuoteLineItem>) oldItems,GlobalConstants.Context_Variable_Before); //Modified by Shreela on 4th Nov 2022 for SAEPB - 44
        qliProcessor.updateDealerDiscountforMHE((List<QuoteLineItem>) newItems.values()); //Added by Shreela on 8th Dec 20323 for SMEPB 111
        qliProcessor.isApprovalRequiredForCategoryAorAB((Map<Id, QuoteLineItem>) newItems, (Map<Id, QuoteLineItem>) oldItems); //Added by Shreela on 18th Dec 2023 for SMEPB 111
        qliProcessor.isSecondaryCategoryAorCategoryB((List<QuoteLineItem>)newItems.values(),(Map<Id, QuoteLineItem>) oldItems); //Added by Shreela on 20th Dec 2023 for SMEPB 111
        if(GlobalConstants.ALLOW_TRIGGER_TO_EXECUTE){ 
                    QuoteLineRuleEngine.evaluteRule(newItems.values(), oldItems,'QuoteLineItem',GlobalConstants.Context_Variable_Update); //Added GlobalConstants.Context_Variable_Update by Shreela on 16th January 2023 for SAEPB 44
         }
        
        qliProcessor.updateAssetSerialNumber((List<QuoteLineItem>) newItems.values());
        qliProcessor.prepopulateContractRelatedFields((List<QuoteLineItem>) newItems.values(), false);
        qliProcessor.validateSalesPrice((Map<Id, QuoteLineItem>) newItems, (Map<Id, QuoteLineItem>) oldItems);
        qliProcessor.captureSalesPriceDifference((List<QuoteLineItem>) newItems.values());
        qliProcessor.populateRetentionValues((map<Id, QuoteLineItem>) newItems, (Map<Id, QuoteLineItem>) oldItems); //Added by Sreekanth Jujare for SSD
        // Warehouse defaulting and validating warehouse lookups for QLI records.
        qliProcessor.populateDefaultQLIWarehouses((List<QuoteLineItem>) newItems.values());
        qliProcessor.validateQLIWarehouses((Map<Id, QuoteLineItem>) newItems, (List<QuoteLineItem>) oldItems.values());
        
        //Autoapprove QLI
        qliProcessor.validateAndAutoapproveForKitchen((Map<Id, QuoteLineItem>) newItems, (Map<Id, QuoteLineItem>) oldItems);
        
        qliProcessor.updateSalesPriceAccordingToAgeing((List<QuoteLineItem>)newItems.values(), (Map<Id, QuoteLineItem>) oldItems);
          
        //Normalise QLI
        normaliseQLI.createNormalisedQLIs((Map<Id, QuoteLineItem>) newItems, (Map<Id, QuoteLineItem>) oldItems);  
        
        
    }
    
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to handle After Insert event context of 'Quote Line Item' Trigger
Inputs:        map of created records

History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        qliProcessor.updateIsGenericCheckboxOnPricingApproval((Map<Id, QuoteLineItem>) newItems);
        qliProcessor.populateNPPFieldForAppliances((Map<Id, QuoteLineItem>) newItems); //kept only method call as for loop redundant - Added by Shreela  for SAEPB - 44
        
        QuoteCustomRollUpSummary customRollUp = new QuoteCustomRollUpSummary();//Added by Pankaj on 04-04-2023 for SMEPB-85
        customRollUp.updateLeadTimeAndBomCost((List<QuoteLineItem>) newItems.values());//Added by Pankaj on 04-04-2023 for SMEPB-85
        
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to handle After Update event context of 'Quote Line Item' Trigger
Inputs:        map of created records

History
02-04-2020      Kishor Kumar     Initial Release   
----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        qliProcessor.checkForLockRecordOnUpdate((map<Id, QuoteLineItem>) newItems, (map<Id, QuoteLineItem>) oldItems);
        SyncQuoteCustomField.syncQuoteLineItem((List<QuoteLineItem>) newItems.values());
        
        //QLI AutoApproval 
        qliProcessor.updatePARForAutoapprovedQLI((map<Id, QuoteLineItem>) newItems, (map<Id, QuoteLineItem>) oldItems); //Added by Shreela on 31st Oct 2022
        qliProcessor.updateSequence((List<QuoteLineItem>)newItems.values(),(map<Id,QuoteLineItem>) oldItems,GlobalConstants.Context_Variable_After); //Added by Shreela on 4th Nov 2022 for SAEPB - 44
        QuoteCustomRollUpSummary customRollUp = new QuoteCustomRollUpSummary();//Added by Pankaj on 04-04-2023 for SMEPB-85
        customRollUp.updateLeadTimeAndBomCost((List<QuoteLineItem>) newItems.values());//Added by Pankaj on 04-04-2023 for SMEPB-85
        
    }
    
    public override void AfterDelete(Map<Id, SObject> oldItems) {
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        qliProcessor.reevaluateIsGenericAndIsNew((Map<Id, QuoteLineItem>) oldItems);
        
        QuoteCustomRollUpSummary customRollUp = new QuoteCustomRollUpSummary();//Added by Pankaj on 04-04-2023 for SMEPB-85
        customRollUp.updateLeadTimeAndBomCost((List<QuoteLineItem>) oldItems.values());//Added by Pankaj on 04-04-2023 for SMEPB-85
    }
    
    public override void AfterUndelete(Map<Id, SObject> oldItems) {
        QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
        qliProcessor.reevaluateIsGenericAndIsNew((Map<Id, QuoteLineItem>) Trigger.newMap);
    }   
    
    public override void beforeDelete(Map<Id, SObject> oldItems){// Added by snehal W 17/01/24
         QLIRecordProcessor qliProcessor = new QLIRecordProcessor();        
         qliProcessor.handleBeforeInsertOrDelete((list<QuoteLineItem>) oldItems.Values());
       
    }
    
}