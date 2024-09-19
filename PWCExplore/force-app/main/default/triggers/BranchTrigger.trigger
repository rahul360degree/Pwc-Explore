/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Branch__c' records
Inputs:        NA
Test Class:   

History
15-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger BranchTrigger on Branch__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new BranchTriggerHandler());
    
    
}