/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger to Handler Logger__c records
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
17-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
public with sharing class LoggerTriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.LoggerTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }


/*------------------------------------------------------------------------
    Author:        Mahith Madwesh 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Event Trigger
    Inputs:        list of created records
    ---------------------------------------------------------------------------
    History
    17-12-2020      Mahith Madwesh      Initial Release
    ----------------------------------------------------------------------------*/
    public override void afterInsert(map<Id,sObject> newItems){
        LoggerTriggerHelper helper = new LoggerTriggerHelper();
        helper.passLoggerIdToPlatfromEvent((list<Logger__c>)newItems.values());
    }
}