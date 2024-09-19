/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Trigger to hadle database events on 'Service_Form__c' records
Inputs:        NA
Test Class:   

History
16-12-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
trigger ServiceFormTrigger on Service_Form__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new ServiceFormTriggerHandler());
}