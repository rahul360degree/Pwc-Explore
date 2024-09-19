/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Trigger to hadle database events on 'zip code rule' records
Inputs:        NA
Test Class:   

History
09-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
trigger ZipCodeRuleTrigger on Zip_Code_Rule__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new ZipCodeRuleTriggerHandler());
}