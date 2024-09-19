/*-----------------------------------------------------------------------------------
* Author        :        Mahith Madwesh
* Company       :        Salesforce
* Description   :        Batch job Heler for Calcuating Asset Sharing 
*                         Assets
* Inputs        :        
* Test Class    :         AssetBenfitBestValueBatchHelperTest.cls
* History
* --------
* 23-11-2020      Mahith Madwesh     Initial Release
* ---------------------------------------------------------------------------------*/
public with sharing class AssetSharingCalculatorBatchHelper {
    
/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Method 
Inputs:        NA
Test Class:    
History
23-11-2020      Mahith Madwesh    Initial Release
----------------------------------------------------------------------------*/
public List<Asset> calculateAssetSharing(list<Asset> existingAssets){

    list<Pin_Code_Dealer_Mapping__c> pincodeDealerList = [SELECT Id,Name,IsActive__c,Service_Dealer__c FROM Pin_Code_Dealer_Mapping__c WHERE IsActive__c = true];

    map<String,Pin_Code_Dealer_Mapping__c> pincodeDealerMap = new map<String,Pin_Code_Dealer_Mapping__c>();

    for(Pin_Code_Dealer_Mapping__c pc:pincodeDealerList){
        pincodeDealerMap.put(pc.Name,pc);
    }      

    for(Asset a: existingAssets){
     //For Offloaded Asset populate service dealer with Primary dealer value
     if(a.AvailableForExternalSharing__c == true && a.Primary_Dealer__c!=null & a.Service_Dealer__c==null){
         a.Service_Dealer__c = a.Primary_Dealer__c;
     }
     if(a.AvailableForExternalSharing__c == true && a.Primary_Dealer__c == null && pincodeDealerMap.containsKey(a.Zip_Code__c)){
         a.Service_Dealer__c = pincodeDealerMap.get(a.Zip_Code__c).Service_Dealer__c;
     }
     if(a.AvailableForExternalSharing__c == false){
         a.Service_Dealer__c = null;
     }
    
 }

return existingAssets;

}
}