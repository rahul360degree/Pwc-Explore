/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to hadle database events on 'Pricing Approval Request' records
Inputs:        NA
Test Class:   

History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger PricingApprovalRequestTrigger on Pricing_approval_request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    TriggerDispatcher.Run(new PricingApprovalRequestTriggerHandler());
}