/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Handler class for Event Trigger
Test Class:    DealerVisitTriggerTest
---------------------------------------------------------------------------
History
19-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
public without sharing class EventTriggerHandler extends VTriggerHandler{
     // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.EventTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

    /*------------------------------------------------------------------------
    Author:        Pawan 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Event Trigger
    Inputs:        list of created records
    ---------------------------------------------------------------------------
    History
    29-10-2020      Pawan      Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        EventTriggerHelper helper = new EventTriggerHelper();
        helper.validateEvents((List<Event>)newItems);
        helper.createTrainingRecord((List<Event>) newItems);
    }

     /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle After Update event context of 'Event' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    10-05-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void afterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        EventTriggerHelper helper = new EventTriggerHelper();
        helper.updateEvents((Map<Id, Event>)newItems, (Map<Id, Event>)oldItems);
    }
}