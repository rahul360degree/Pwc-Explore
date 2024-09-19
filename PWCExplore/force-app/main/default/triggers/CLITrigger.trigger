/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Trigger to handle database events on 'Contract Line item' records
Inputs:        NA
Test Class:   

History
23-05-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
trigger CLITrigger on ContractLineItem (before insert, before update,after update, after insert) {
    TriggerDispatcher.Run(new CLITriggerHandler());
}