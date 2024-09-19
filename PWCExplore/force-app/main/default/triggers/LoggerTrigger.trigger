/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger to Handler Logger__c records
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
17-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
trigger LoggerTrigger on Logger__c (before insert, before update, before delete, after insert, after update, after delete) {
     TriggerDispatcher.Run(new LoggerTriggerHandler());
}