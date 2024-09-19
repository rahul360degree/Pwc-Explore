/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for PricingApprovalRequest Trigger
Inputs:        NA
Test Class:    
History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class PricingApprovalRequestTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.PricingApprovalRequestTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of PricingApprovalRequest Trigger
    Inputs:        map of records with New & Old values
    Test Class:   

    History
    06-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        PricingApprovalRequestProcessor processor = new PricingApprovalRequestProcessor();
        processor.updateParentQuote((map<Id, Pricing_approval_request__c>)oldItems, 
                                        (map<Id, Pricing_approval_request__c>)newItems);
                                       
       processor.updateProductTypeOnQuote((map<Id, Pricing_approval_request__c>)newItems,
                           (map<Id, Pricing_approval_request__c>)oldItems);
                                        
    }
 }