/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Trigger to handle database events on Asset Benefit records
Inputs:        NA
Test Class:   

History
02-12-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
trigger AssetBenefitTrigger on Asset_Benefit__c (before insert, before update, after insert, after update, before delete) {
    TriggerDispatcher.Run(new AssetBenefitTriggerHandler());
}