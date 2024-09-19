/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger to handle saving of Competitor visit records
Inputs:        NA
Test Class:   

History
20-10-2020      Mahith     Initial Release
----------------------------------------------------------------------------*/
trigger CompetitorVisitTrigger on Competitor_Visit__c (before insert, before update) {
     TriggerDispatcher.Run(new CompetitorVisitTriggerHandler());
}