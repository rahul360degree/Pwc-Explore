/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Trigger to hadle database events on 'Asset' records
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/
trigger AssetTrigger on Asset (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new AssetTriggerHandler());
}