/*------------------------------------------------------------------------
Author:        Vikrant Mahantare
Description:   Trigger to hadle database events on 'qsyd_FE__FileExplorerFile__c' records
Inputs:        NA
Test Class:   
----------------------------------------------------------------------------*/

public with sharing class FileExplorerTriggerHandler extends VTriggerHandler {
		  // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.OrderTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
 
    public override void AfterInsert(map<Id, sObject> newItems){
        FileExplorerEmailTrigger Emailtrig = new FileExplorerEmailTrigger();
        Emailtrig.Emailtriggersemail(newItems);
    }
 
}