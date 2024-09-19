/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Trigger to handle database events on 'Dealer Visit' records
Inputs:        NA
Test Class:    DealerVisitTriggerTest
----------------------------------------------------------------------------
History
09-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
trigger DealerVisitTrigger on Dealer_Visit__c (before insert,before update, before delete, after insert, after update, after delete) {
	TriggerDispatcher.Run(new DealerVisitTriggerHandler());
}