/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to handle database events on Service Contract records
Inputs:        NA
Test Class:   

History
09-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger ServiceContractTrigger on ServiceContract (before insert, before update,before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new ServiceContractTriggerHandler());
}