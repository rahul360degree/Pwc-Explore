/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Handler class for zip code rule Trigger
Inputs:        NA
Test Class:    
History
09-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ZipCodeRuleTriggerHandler extends VTriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ZipCodeRuleTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of zip code rule Trigger
    Inputs:        list of created records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    09-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        ZipCodeRuleFieldPopulator fieldPopulator = new ZipCodeRuleFieldPopulator();
        fieldPopulator.appendChannelToRuleName((list<Zip_Code_Rule__c>)newItems,null);
        fieldPopulator.validateQueueNamePopulated((list<Zip_Code_Rule__c>)newItems,null);
        fieldPopulator.validateRuleNamePopulated((list<Zip_Code_Rule__c>)newItems,null);
        fieldPopulator.checkDuplicateRule((list<Zip_Code_Rule__c>)newItems,null);
        fieldPopulator.populateQueueVsLastAssignedId((list<Zip_Code_Rule__c>)newItems);
        fieldPopulator.validateQueueSequence((list<Zip_Code_Rule__c>)newItems,null);
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to handle before Update event context of zip code rule Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ZipCodeRuleFieldPopulator fieldPopulator = new ZipCodeRuleFieldPopulator();
        fieldPopulator.appendChannelToRuleName((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
        fieldPopulator.validateQueueNamePopulated((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
        fieldPopulator.validateRuleNamePopulated((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
        fieldPopulator.checkDuplicateRule((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
        fieldPopulator.updateQueueVsLastAssignedId((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
        fieldPopulator.validateQueueSequence((list<Zip_Code_Rule__c>)newItems.values(),(Map<Id,Zip_Code_Rule__c>)oldItems);
    }
}