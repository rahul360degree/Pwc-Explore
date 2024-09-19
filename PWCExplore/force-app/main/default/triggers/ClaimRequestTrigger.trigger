/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Trigger to handle database events on 'ClaimRequest' records
               Object Name - Claim Request
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
19-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
trigger ClaimRequestTrigger on Claim_Requests__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
     TriggerDispatcher.Run(new ClaimRequestTriggerHandler());
}