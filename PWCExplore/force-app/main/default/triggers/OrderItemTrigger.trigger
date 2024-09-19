/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Order' records
Inputs:        NA
Test Class:   

History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger OrderItemTrigger on OrderItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(!OrderItemTriggerHandler.TriggerDisabled){
        TriggerDispatcher.Run(new OrderItemTriggerHandler());
    }
    
}