/*-----------------------------------------------------------------------------------
 * Author        :        Mahith Madwesh
 * Company       :        Salesforce
 * Description   :        Aura Controller for Asset Quick Action Component to Calculate 
 *                        Asset Benifit Best Value for Asset
 * Inputs        :        
 * Test Class    :        AssetBestValueQuickActionControllerTest
 * History
 * --------
 * 23-11-2020      Mahith Madwesh     Initial Release
 * ---------------------------------------------------------------------------------*/
public with sharing class AssetBestValueQuickActionController {



  /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   method to return true or False Based on Updating asset
                   with Asset Benifit Best Value
    Inputs:        RecordId
    Test Class:    AssetBestValueQuickActionControllerTest
    History
    23-11-2020      Mahith Madwesh    Initial Release
	12-03-2023		PSM				  Added plan info to be retrieved from asset benefit record	
    ----------------------------------------------------------------------------*/ 
   @AuraEnabled
   public static boolean updateBenifitBestValueOnAsset(string recordId){
       List<Asset> assetsToUpdate  = new list<Asset>();
       Boolean savedResult = false;
       //retrieving plan info SMF-104
       list<Asset> assetRecord = [SELECT Id, Name, Product_Purchased_Warranty_End_Date__c,Date_of_Commissioning__c,Product_Purchased_Warranty_Start_Date__c,Recalculation_Required__c,  
                                      (SELECT Id, Name, Audits__c, Scheduled_PM_Visits_Number__c, Operator__c, Scheduled_PM_Visits__c, 
                                            BD_Visits__c, BD_Visits_Number__c, Equipment_Type__c, Parts_Support__c, plan__r.name,
                                            Remote_Assistance__c, Reports_Dashboards__c, Stationed_Manpower__c, Supervisor__c,
                                            Contract_Line_Item__r.startDate,Contract_Line_Item__r.endDate,Is_Legacy_Benefit__c,Contract_Line_Item__r.ServiceContract.Approved_Date__c//added approved date for MHE-SMF-139   
                                        FROM Asset_Benefits__r 
                                       	WHERE Is_Active__c = true) FROM Asset 
                                  WHERE Id =:recordId AND Recalculation_Required__c = true];
	system.debug('assetRecord:'+assetRecord);
    //system.debug('assetRecord[0].Asset_Benefits__r:'+assetRecord[0].Asset_Benefits__r);
    AssetBenfitBestValueBatchHelper abHelper = new AssetBenfitBestValueBatchHelper();
      assetsToUpdate = abHelper.UpdatebestValueBenifit(assetRecord);

      Set<Asset> sStrings = new Set<Asset>(assetsToUpdate);
      List<Asset> assetsToUpdate1 = new List<Asset>(sStrings);

      try{
        update assetsToUpdate1;
        savedResult = true;
      }
      catch(Exception e){
        Logger.logError('AssetBenifitBestValueQuickActionController', 'updateBenifitBestValueOnAsset', '', e);
      }
      return savedResult;                             
   }
}