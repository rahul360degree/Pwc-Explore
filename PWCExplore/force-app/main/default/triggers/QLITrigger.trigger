/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Quote Line item' records
Inputs:        NA
Test Class:   

History
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger QLITrigger on QuoteLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(!QLITriggerHandler.TriggerDisabled)
        TriggerDispatcher.Run(new QLITriggerHandler());
}