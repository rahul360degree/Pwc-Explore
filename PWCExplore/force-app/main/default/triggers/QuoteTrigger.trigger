/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Quote' records
Inputs:        NA
Test Class:   

History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger QuoteTrigger on Quote (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new QuoteTriggerHandler());
    
}