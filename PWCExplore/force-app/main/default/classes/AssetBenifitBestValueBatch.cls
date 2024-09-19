/*-----------------------------------------------------------------------------------
 * Author        :        Mahith Madwesh
 * Company       :        Salesforce
 * Description   :        Batch job for Updating Asset Benifit Best Value on Assets
 * Inputs        :        
 * Test Class    :        AssetBenifitBestValueBatchTest.cls
 * History
 * --------
 * 23-11-2020      Mahith Madwesh     Initial Release
 * 03-04-2023	   PSM				  Tweaked the query and the break statements , as they were not positioned correctly 
 * 24-08-2023	   PSM				  Supplied the start method o/p to the helper class as the irrelevant assets will be marked as Recalc reqd = false there
 * ---------------------------------------------------------------------------------*/
global class AssetBenifitBestValueBatch implements Database.Batchable<sobject> {
  
  global Database.QueryLocator start(Database.BatchableContext bc) {
      //getting such asset records where recalc reqd is true and its asset benefit record is last modified in the last n days
      return Database.getQueryLocator('SELECT Id, Name, Product_Purchased_Warranty_End_Date__c,Date_of_Commissioning__c,Recalculation_Required__c,'+
                                  'Product_Purchased_Warranty_Start_Date__c,(SELECT Id ,name , audits__c , Scheduled_PM_Visits_Number__c , Operator__c , '+
                                  'Scheduled_PM_Visits__c , BD_Visits__c , BD_Visits_Number__c,Equipment_Type__c,Parts_Support__c,Remote_Assistance__c,'+
                                  'Reports_Dashboards__c,Stationed_Manpower__c,plan__r.name,Supervisor__c,Contract_Line_Item__r.startDate,'+
                                  'Contract_Line_Item__r.endDate,lastModifiedDate,Is_Legacy_Benefit__c,Contract_Line_Item__r.ServiceContract.Approved_Date__c FROM Asset_Benefits__r where is_active__c = true and '+
                                  'lastmodifieddate>=N_DAYS_AGO:10 and Scheduled_PM_Visits_Number__c!=null and Scheduled_PM_Visits_Number__c != 0 and Scheduled_PM_Visits_Number__c <=12) FROM Asset WHERE Recalculation_Required__c = true');
  }

  global void execute(Database.BatchableContext bc, List<Asset> scope) {
    List<Asset> assetsToUpdate  = new list<Asset>();
    List<Asset> assetRecords = new List<Asset>();
    system.debug('scope.size() :'+scope.size());
    // Commented the section of assetRecords as the irrelevant assets will be marked as Recalc reqd = false in the helper class
    /*for(asset a: scope)
      if(!a.Asset_Benefits__r.isempty() && a.Asset_Benefits__r.size()>0)
            assetRecords.add(a);

      system.debug('assetRecords.size() :'+assetRecords.size());*/ 
      AssetBenfitBestValueBatchHelper abHelper = new AssetBenfitBestValueBatchHelper();
      //assetsToUpdate = abHelper.UpdatebestValueBenifit(assetRecords);
      assetsToUpdate = abHelper.UpdatebestValueBenifit(scope);
      try{
        update assetsToUpdate;
      }
      catch(Exception e){
        Logger.logError('AssetBenifitBestValueBatch', 'execute', '', e);
      }  
  }

  global void finish(Database.BatchableContext bc) {

  }
}