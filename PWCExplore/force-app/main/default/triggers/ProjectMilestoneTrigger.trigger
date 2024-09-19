/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Trigger to hadle database events on 'Project Mileston' records
Inputs:        NA
Test Class:   

History
02-12-2020      Suwarna Rao     Initial Release
----------------------------------------------------------------------------*/
trigger ProjectMilestoneTrigger on Project_milestone__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.Run(new ProjectMilestoneTriggerHandler());

}