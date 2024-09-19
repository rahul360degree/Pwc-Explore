/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Processor class for Asset Benefit Records
Inputs:        NA
Test Class:    
History
09-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AssetBenefitTriggerHelper {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to update Recalculation Required flag on Asset 
    Inputs:        NA
    Test Class:    
    History
    02-12-2020      Kishor Kumar     Initial Release
	28-08-2023		PSM				 Introduced condition to check if the asset benefit.isactive=false , if yes then 'Recalculation required' flag shouldnt be set to true
    ----------------------------------------------------------------------------*/
    public void updateRecalculationRequiredOnAsset(map<Id, Asset_Benefit__c> assetBenefits, map<Id, Asset_Benefit__c> oldAssetBenefits){
    	set<Id> assetIds = new set<Id>();
        list<Asset> assetsToUpdate = new list<Asset>();
        
        //fetch the asset Id for the updated asset benefit record
        for(Id assetBenefitId : assetBenefits.keyset()){
            if(assetBenefits.get(assetBenefitId).Asset__c != null 
              		&& (oldAssetBenefits == null || 
                        	( oldAssetBenefits != null && oldAssetBenefits.containsKey(assetBenefitId) && (
                            	   oldAssetBenefits.get(assetBenefitId).Asset__c != assetBenefits.get(assetBenefitId).Asset__c 
                                || oldAssetBenefits.get(assetBenefitId).Audits__c != assetBenefits.get(assetBenefitId).Audits__c 
                                || oldAssetBenefits.get(assetBenefitId).BD_Visits__c != assetBenefits.get(assetBenefitId).BD_Visits__c 
                                || oldAssetBenefits.get(assetBenefitId).BD_Visits_Number__c != assetBenefits.get(assetBenefitId).BD_Visits_Number__c 
                                || oldAssetBenefits.get(assetBenefitId).Contract_Line_Item__c != assetBenefits.get(assetBenefitId).Contract_Line_Item__c 
                                || oldAssetBenefits.get(assetBenefitId).Equipment_Type__c != assetBenefits.get(assetBenefitId).Equipment_Type__c 
                                || (oldAssetBenefits.get(assetBenefitId).Is_Active__c != assetBenefits.get(assetBenefitId).Is_Active__c && assetBenefits.get(assetBenefitId).Is_Active__c)
                                || oldAssetBenefits.get(assetBenefitId).Operator__c != assetBenefits.get(assetBenefitId).Operator__c 
                                || oldAssetBenefits.get(assetBenefitId).Parts_Support__c != assetBenefits.get(assetBenefitId).Parts_Support__c 
                                || oldAssetBenefits.get(assetBenefitId).Plan__c != assetBenefits.get(assetBenefitId).Plan__c 
                                || oldAssetBenefits.get(assetBenefitId).Quote_Line_Item__c != assetBenefits.get(assetBenefitId).Quote_Line_Item__c 
                                || oldAssetBenefits.get(assetBenefitId).Remote_Assistance__c != assetBenefits.get(assetBenefitId).Remote_Assistance__c 
                                || oldAssetBenefits.get(assetBenefitId).Reports_Dashboards__c != assetBenefits.get(assetBenefitId).Reports_Dashboards__c 
                                || oldAssetBenefits.get(assetBenefitId).Scheduled_PM_Visits__c != assetBenefits.get(assetBenefitId).Scheduled_PM_Visits__c 
                                || oldAssetBenefits.get(assetBenefitId).Scheduled_PM_Visits_Number__c != assetBenefits.get(assetBenefitId).Scheduled_PM_Visits_Number__c 
                                || oldAssetBenefits.get(assetBenefitId).Stationed_Manpower__c != assetBenefits.get(assetBenefitId).Stationed_Manpower__c 
                                || oldAssetBenefits.get(assetBenefitId).Supervisor__c != assetBenefits.get(assetBenefitId).Supervisor__c 
                            )) 
                       )){
                assetIds.add(assetBenefits.get(assetBenefitId).Asset__c);
            }
        }
        
        //fetch the asset details & update the 'Recalculation required' flag
        if(assetIds.size() > 0 ){
            for(Asset assetRec : [SELECT Id, Recalculation_Required__c FROM Asset WHERE Id IN : assetIds 
                                  				AND Recalculation_Required__c = false]){
                if (Schema.sObjectType.Asset.fields.Recalculation_Required__c.isUpdateable()){
                    assetRec.Recalculation_Required__c = true;   
                }
                assetsToUpdate.add(assetRec);
            }
        }
        
        //update Assets
        try{
            update assetsToUpdate;
        } catch(Exception ex){
            Logger.logError('AssetBenefitTriggerHelper', 'updateRecalculationRequiredOnAsset', '', ex);
        }
    
    }
    
}