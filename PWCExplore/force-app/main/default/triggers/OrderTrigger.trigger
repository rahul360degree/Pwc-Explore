/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Order' records
Inputs:        NA
Test Class:   

History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger OrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new OrderTriggerHandler());
    
}