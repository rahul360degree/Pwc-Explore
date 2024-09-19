/*------------------------------------------------------------------------------
 * Author:        Joshna
 * Company:       Salesforce
 * Description:   Trigger handler for time entry object
 * ---------------------------------------------------------------------------
 * History
 * 16-11-2020      Joshna     Initial Release
 * ----------------------------------------------------------------------------*/
public with sharing class TimeEntryTriggerHandler extends VTriggerHandler {
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.TimeEntryTriggerDisabled__c) {
            return true;
        } else {
            return TriggerDisabled;
        }
    }

    public override void BeforeInsert(List<sObject> newItems) {
        TimeEntryTriggerHelper helperInst = new TimeEntryTriggerHelper();
        helperInst.validateTimeEntryRecords((List<Time_Entry__c>) newItems);
    }

    public override void BeforeUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems) {
        TimeEntryTriggerHelper helperInst = new TimeEntryTriggerHelper();
        helperInst.validateTimeEntryRecords((Map<Id, Time_Entry__c>) newItems, (Map<Id, Time_Entry__c>) oldItems);
    }
}