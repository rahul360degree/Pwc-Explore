/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Handler class for Dealer Visit Trigger
Test Class:    DealerVisitTriggerTest
---------------------------------------------------------------------------
History
09-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
public without sharing class DealerVisitTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.DealerVisitTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Joshna 
    Company:       Salesforce
    Description:   Method to set dealer account ID on counter share
    Inputs:        List of new records
    Test Class:   
    -------------------------------------------------------------------------------------
    History
    06-11-2020      Joshna     Initial Release
    -------------------------------------------------------------------------------------*/
    public override void beforeInsert(List<sObject> newItems) {
        DealerVisitTriggerHelper helper = new DealerVisitTriggerHelper();
        helper.setAccountIdForCounterShare((List<Dealer_Visit__c>) newItems);
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Shailja 
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Dealer Vist Trigger
    Inputs:        list of new records
    Test Class:   
    -------------------------------------------------------------------------------------
    History
    10-05-2020      Shailja     Initial Release
    -------------------------------------------------------------------------------------*/
    public override void afterInsert(Map<Id, SObject> newItems){
        DealerVisitTriggerHelper helper = new DealerVisitTriggerHelper();
        helper.createDealerVisitEvents((list<Dealer_Visit__c>)newItems.values());
        helper.populateQuestionnaireFields((List<Dealer_Visit__c>) newItems.values());
        helper.checkforSameTime((List<Dealer_Visit__c>) newItems.values());
    }
    
    /*-----------------------------------------------------------------------------------
    Author:        Shailja 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Dealer Vist Trigger
    Inputs:        list of new records
    Test Class:   
    -------------------------------------------------------------------------------------
    History
    07-07-2020      Shailja     Initial Release
    -------------------------------------------------------------------------------------*/
    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
         DealerVisitTriggerHelper helper = new DealerVisitTriggerHelper();
         helper.updateIntentOnUpdate((map<Id, Dealer_Visit__c>)newItems, (map<Id, Dealer_Visit__c>)oldItems);
        // helper.populateQuestionnaireFields((List<Dealer_Visit__c>) newItems.values()); 
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 'Dealer Visit' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    10-05-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void afterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        DealerVisitTriggerHelper helper = new DealerVisitTriggerHelper();
        helper.updateDealerVisitEvents((Map<Id, Dealer_Visit__c>)newItems, (Map<Id, Dealer_Visit__c>)oldItems);
        helper.checkforSameTime((List<Dealer_Visit__c>) newItems.values());
    }
}