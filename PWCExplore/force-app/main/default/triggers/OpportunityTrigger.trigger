/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Opportunity' records
Inputs:        NA
Test Class:   

History
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new OpportunityTriggerHandler());
    
    
}