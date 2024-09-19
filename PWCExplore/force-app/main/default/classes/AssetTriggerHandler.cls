/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Handler class for Asset Trigger
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/
public with sharing class AssetTriggerHandler extends VTriggerHandler {   
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;   
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
     */
    
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AssetTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    } 

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Asset Trigger
    Inputs:        list of created records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    03-12-2020      Kishor     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        AssetTriggerHelper helper = new AssetTriggerHelper();
        helper.setDefaults((list<Asset>)newItems);
        helper.setAseetRecordType((list<Asset>)newItems);
        helper.populateProductDetails((list<Asset>)newItems);
        helper.updateAssetStatusForIntegrationUser((list<Asset>)newItems);
        helper.populateDefaultsBasedOnOrderReference((list<Asset>)newItems);
        helper.populateWarrantyStartAndEndDate((list<Asset>)newItems,null);
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Asset Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    06-11-2020      Suwarna Rao     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(Map<Id, SObject> newItems){
        AssetTriggerHelper helper = new AssetTriggerHelper();
        helper.checkForExternalSharing((list<Asset>)newItems.values(),null);
        helper.createStandardWarrantyAssetBenefits((map<Id, Asset>)newItems, null);
        helper.createServiceRequest((list<Asset>)newItems.values());
        helper.createInstallationServiceRequest((map<Id, Asset>)newItems, null);
        helper.createWarrantyClaimsForNewActiveAssets((list<Asset>)newItems.values());
    }    
	
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to handle After Update event context of Asset Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    06-11-2020      Suwarna Rao     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){       
        AssetTriggerHelper helper = new AssetTriggerHelper();
        helper.checkForExternalSharing((list<Asset>)newItems.values(),(map<Id, Asset>)oldItems);
        helper.createStandardWarrantyAssetBenefits((map<Id, Asset>)newItems, (map<Id, Asset>)oldItems);
        helper.disableScrappedAssetBenefits((map<Id, Asset>)newItems, (map<Id, Asset>)oldItems);
        helper.createInstallationServiceRequest((map<Id, Asset>)newItems, (map<Id, Asset>)oldItems);
        helper.createWarrantyClaimRequestsForAssetsUpdatedActive((map<Id, Asset>)newItems, (map<Id, Asset>)oldItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to handle Before Update event context of Asset Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    11-12-2020      Pawan     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        AssetTriggerHelper helper = new AssetTriggerHelper();
        helper.populateProductDetails((list<Asset>)newItems.values());
        helper.validateMHEAssetStatus((map<Id, Asset>)newItems,(map<Id, Asset>)oldItems);
        helper.populateDefaultsBasedOnOrderReference((list<Asset>)newItems.values());
        helper.updateWarrantyEndDate((map<Id, Asset>)newItems,(map<Id, Asset>)oldItems);
        helper.updateEventActionOnAsset((map<Id, Asset>)newItems,(map<Id, Asset>)oldItems);
        helper.populateWarrantyStartAndEndDate((list<Asset>)newItems.values(),(map<Id,Asset>)oldItems);
        helper.updateAssetName_If_EquipmentSerialNo_IsUpdated((Map<Id, Asset>) newItems, (Map<Id, Asset>) oldItems);
    }
}