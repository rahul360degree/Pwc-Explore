/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Trigger to handle database events on 'Event' records
Inputs:        NA
Test Class:    DealerVisitTriggerTest
---------------------------------------------------------------------------
History
19-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
trigger EventTrigger on Event (before insert, before update, before delete, after insert, after update, after delete) {
    TriggerDispatcher.Run(new EventTriggerHandler());
}