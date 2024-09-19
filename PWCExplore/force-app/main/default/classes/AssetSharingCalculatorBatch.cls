/*-----------------------------------------------------------------------------------
 * Author        :        Mahith Madwesh
 * Company       :        Salesforce
 * Description   :        Batch job for Calculating Asset Sharing
 * Inputs        :        
 * Test Class    :        
 * History
 * --------
 * 31-12-2020      Mahith Madwesh     Initial Release
 * ---------------------------------------------------------------------------------*/
global class AssetSharingCalculatorBatch implements Database.Batchable<sobject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator('SELECT Id,AccountId,AvailableForExternalSharing__c,Zip_Code__c,Service_Dealer__c,Primary_Dealer__c FROM Asset');
  }

  global void execute(Database.BatchableContext bc, List<Asset> scope) {

    List<Asset> assetsToUpdate  = new list<Asset>();

      AssetSharingCalculatorBatchHelper abHelper = new AssetSharingCalculatorBatchHelper();
      assetsToUpdate = abHelper.calculateAssetSharing(scope);

      try{
        update assetsToUpdate;
      }
      catch(Exception e){
        Logger.logError('AssetSharingCalculatorBatch', 'execute', '', e);
      }
      
  }

  global void finish(Database.BatchableContext bc) {

  }
    
}