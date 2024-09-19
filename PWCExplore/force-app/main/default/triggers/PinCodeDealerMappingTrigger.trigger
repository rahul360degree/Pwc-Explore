/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Trigger to hadle database events on 'Pin_Code_Dealer_Mapping__c'
               records
Inputs:        NA
Test Class:   

History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
trigger PinCodeDealerMappingTrigger on Pin_Code_Dealer_Mapping__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 TriggerDispatcher.Run(new PinCodeDealerMappingTriggerHandler());
}