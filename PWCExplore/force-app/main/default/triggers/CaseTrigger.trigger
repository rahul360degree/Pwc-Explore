/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Trigger to hadle database events on 'Case' records
Inputs:        NA
Test Class:    CaseTriggerTest

History
16-09-2020      Shailja Mishra     Initial Release
----------------------------------------------------------------------------*/
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new CaseTriggerHandler());
}