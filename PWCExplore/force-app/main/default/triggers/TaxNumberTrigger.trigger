/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Trigger to handle database events on 'Tax Number' records
Inputs:        NA
Test Class:   

History
10-06-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
trigger TaxNumberTrigger on Tax_Number__c (before insert, before update) {
    TriggerDispatcher.Run(new TaxNumberTriggerHandler());
}