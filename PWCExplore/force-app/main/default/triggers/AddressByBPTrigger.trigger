/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Address_by_BP__c' records
Inputs:        NA
Test Class:   

History
26-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger AddressByBPTrigger on Address_by_BP__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new AddressByBPTriggerHandler());
}