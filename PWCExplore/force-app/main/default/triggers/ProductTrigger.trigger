/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Product' records
Inputs:        NA
Test Class:   

History
23-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger ProductTrigger on Product2 (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new ProductTriggerHandler());

}