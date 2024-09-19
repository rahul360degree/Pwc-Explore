/*------------------------------------------------------------------------
Company:       Salesforce
Description:   Handler class for Attendance Object Trigger
Inputs:        NA
Test Class:    AttendanceTriggerTest
History
13-10-2020     Kshipra Kankariya     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AttendanceTriggerHandler  extends VTriggerHandler {
    public static Boolean tiggerDisabled = false;
    
    /**
     * Method for before Insert
     */
    public override void BeforeInsert(list<SObject> newItems){
        AttendanceTriggerHandlerHelper helper = new AttendanceTriggerHandlerHelper();
        helper.validateBaseLocationResetRequestPersona((List<Attendance__c>) newItems);
        helper.checkDuplicateResetBaseLocationRequest((List<Attendance__c>) newItems);
        helper.populateApproverAndCheckForDuplicates((List<Attendance__c>) newItems);
        SharingUtility.setParentContacts(newItems, null, false, false);
    }

    public override void BeforeUpdate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        AttendanceTriggerHandlerHelper helper = new AttendanceTriggerHandlerHelper();
        helper.populateApproverAndCheckForDuplicates((List<Attendance__c>) (newItems.values()));
        helper.resetUserBaseLocation((List<Attendance__c>)(newItems.values()),(Map<Id,Attendance__c>)oldItems);
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, false);
    }

    /*
     *   Checks to see if the trigger has been disabled either by custom setting or by running code
     */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AttendanceTriggerDisabled__c)
            return true;
        else 
            return tiggerDisabled;
    }
}