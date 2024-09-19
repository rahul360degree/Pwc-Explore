/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Asset Benefit Trigger
Inputs:        NA
Test Class:    
History
09-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AssetBenefitTriggerHandler extends VTriggerHandler {
	
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AssetBenefitTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Asset Benefit Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    09-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Before Update event context of Asset Benefit Trigger
    Inputs:        map of created records
    Test Class:   

    History
    09-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){ 
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Asset Benefit Trigger
    Inputs:        map of created records
    Test Class:   

    History
    09-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        AssetBenefitTriggerHelper helper = new AssetBenefitTriggerHelper();
        helper.updateRecalculationRequiredOnAsset((map<Id, Asset_Benefit__c>) newItems, null);
    } 
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Asset Benefit Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    09-11-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        AssetBenefitTriggerHelper helper = new AssetBenefitTriggerHelper();
        helper.updateRecalculationRequiredOnAsset((map<Id, Asset_Benefit__c>) newItems, (map<Id, Asset_Benefit__c>) oldItems);
    }
    
    
}