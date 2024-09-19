/*------------------------------------------------------------------------
Author:        Rohit Jadhav
Company:       Salesforce
Description:   Trigger to handle database events on 'Address__c' records
Inputs:        NA
Test Class:   

History
06-02-2024     Rohit Jadhav     Initial Release
----------------------------------------------------------------------------*/
trigger AddressTrigger on Address__c (before insert, before update) {
    TriggerDispatcher.Run(new AddressTriggerHandler());
}