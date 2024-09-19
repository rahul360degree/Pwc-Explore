/*-----------------------------------------------------------------------------------
 * Author        :        Mahith Madwesh
 * Company       :        Salesforce
 * Description   :        Class to Calculate Asset Sharing
 * Inputs        :        
 * Test Class    :        AssetBestValueQuickActionControllerTest
 * History
 * --------
 * 23-11-2020      Mahith Madwesh     Initial Release
 * ---------------------------------------------------------------------------------*/
public with sharing class AssetSharingProcessor {
    
public static void calculateSharing(list<Asset_Sharing__e> eventRecords){

    list<Id> loggerIds = new list<Id>();

    for(Asset_Sharing__e ev:eventRecords){
        loggerIds.add(ev.Logger_recordId__c);
    }
    List<Logger__c> loggerRecords = [SELECT Id, Deleted_PinCode__c,Pin_Code_Dealer_Mapping__r.Name,Status__c,SubType__c,Type__c,Account__c FROM Logger__c WHERE Id IN:loggerIds AND Status__c='Pending'];

    set<logger__c> pincodeUpdateSet = new set<logger__c>();
    set<logger__c> deletePinCodeSet = new set<logger__c>();
    set<logger__c> KeyAccountChangeSet = new set<logger__c>();
    set<Logger__c> metadataSet = new set<logger__c>();
    for(logger__c l:loggerRecords){
        if(l.Type__c == 'Pincode mapping - P2' && l.SubType__c=='New/Dealer Change'){
             pincodeUpdateSet.add(l);
        }

        if(l.Type__c == 'Pincode mapping - P2' && l.SubType__c=='Deleted'){
            deletePinCodeSet.add(l);
        }

        if(l.Type__c == 'Key Account change - P2'){
           KeyAccountChangeSet.add(l);
        }

        if(l.Type__c == 'Metadata change - P1'){
            metadataSet.add(l);
        }

    }

    if(pincodeUpdateSet.size()>0){
        List<Logger__c> loggers = new List<Logger__c>(pincodeUpdateSet);
        AssetSharingProcessor.pincodeDealerChange(loggers);
    }
    if(deletePinCodeSet.size()>0){
         List<Logger__c> loggers1 = new List<Logger__c>(deletePinCodeSet);
        AssetSharingProcessor.removePincodeDealerAccess(loggers1);
    }
     if(KeyAccountChangeSet.size()>0){
         List<Logger__c> loggers2 = new List<Logger__c>(KeyAccountChangeSet);
        AssetSharingProcessor.KeyAccountChangeAccess(loggers2);
    }
    if(metadataSet.size()>0){
          List<Logger__c> loggers3 = new List<Logger__c>(metadataSet);
        AssetSharingProcessor.recalculateAllAssetsSharing(loggers3);
    }

}



/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Method to Recalculate Sharing for All Assets
Inputs:        NA
Test Class:    
History
21-12-2020      Mahith Madwesh    Initial Release
----------------------------------------------------------------------------*/
public static void recalculateAllAssetsSharing(list<Logger__c> logRecords){
// change to batch class method for metadata change
    AssetSharingCalculatorBatch  acs = new AssetSharingCalculatorBatch();
    Database.executeBatch(acs);

    set<Logger__c> UpdateLoggerSet = new set<Logger__c>(logRecords); 

    for(Logger__c l: logRecords){
        l.Status__c = 'Success';
    }
   try{
        List<Logger__c> UpdateLoggerList = new List<Logger__c>(UpdateLoggerSet); 
        update UpdateLoggerList;
      }
      catch(Exception e){
        Logger.logError('AssetSharingProcessor', 'recalculateAllAssetsSharing', '', e);
      } 

}

/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Method to Recalculate Sharing for pincode Dealer Change
Inputs:        NA
Test Class:    
History
21-12-2020      Mahith Madwesh    Initial Release
----------------------------------------------------------------------------*/
public static void pincodeDealerChange(list<Logger__c> logRecords){
    set<string> zipcodeStrings = new set<string>();
    map<string,Logger__c> pincodeLoggerMap = new map<string,Logger__c>();
    set<Logger__c> UpdateLoggerSet = new set<Logger__c>();

    for(Logger__c l: logRecords){
        pincodeLoggerMap.put(l.Pin_Code_Dealer_Mapping__r.Name,l);
        zipcodeStrings.add(l.Pin_Code_Dealer_Mapping__r.Name);
    }
    list<Asset> existingAssets = [SELECT Id,Address_Code__r.ZipCode__r.Name,Zip_Code__c,AvailableForExternalSharing__c,Service_Dealer__c,Primary_Dealer__c 
                                        FROM Asset WHERE Address_Code__r.ZipCode__r.Name IN:zipcodeStrings AND Primary_Dealer__c = NULL]; //Modified by Namrata and Shreela for SMEPB-134 on 5th January 2024
    for(Asset a: existingAssets){
        if(pincodeLoggerMap.containsKey(a.Address_Code__r.ZipCode__r.Name)){  //Modified by Namrata and Shreela for SMEPB-134 on 5th January 2024
            if(a.AvailableForExternalSharing__c == true){
                a.Service_Dealer__c = pincodeLoggerMap.get(a.Address_Code__r.ZipCode__r.Name).Account__c;  //Modified by Namrata and Shreela for SMEPB-134 on 5th January 2024
             }
            if(a.AvailableForExternalSharing__c == false){
                a.Service_Dealer__c = null;
            }
            Logger__c newlog = new Logger__c();
            newlog.Id = pincodeLoggerMap.get(a.Address_Code__r.ZipCode__r.Name).Id; //Modified by Namrata and Shreela for SMEPB-134 on 5th January 2024
            newlog.Status__c = 'Success';
            UpdateLoggerSet.add(newlog);

        }
       
    }

    try{
        update existingAssets;
         List<Logger__c> UpdateLoggerList = new List<Logger__c>(UpdateLoggerSet); 
        update UpdateLoggerList;
      }
      catch(Exception e){
        Logger.logError('AssetSharingProcessor', 'pincodeDealerChange', '', e);
      }                                     
}


/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Method to Remove Access To Dealer if Pincode mapping is delete
Inputs:        NA
Test Class:    
History
21-12-2020      Mahith Madwesh    Initial Release
----------------------------------------------------------------------------*/
public static void removePincodeDealerAccess(list<Logger__c> logRecords){
    set<string> zipcodeStrings = new set<string>();
    map<string,Logger__c> pincodeLoggerMap = new map<string,Logger__c>();
   set<Logger__c> UpdateLoggerSet = new set<Logger__c>();

    for(Logger__c l: logRecords){
        pincodeLoggerMap.put(l.Deleted_PinCode__c,l);
        zipcodeStrings.add(l.Deleted_PinCode__c);
    }

    list<Asset> existingAssets = [SELECT Id,Address_Code__r.ZipCode__r.Name,Zip_Code__c,AvailableForExternalSharing__c,Service_Dealer__c,Primary_Dealer__c 
                                        FROM Asset WHERE Zip_Code__c IN:zipcodeStrings AND Primary_Dealer__c = null ];
    for(Asset a:existingAssets){
         if(pincodeLoggerMap.containsKey(a.Zip_Code__c)){
            if(a.Service_Dealer__c == pincodeLoggerMap.get(a.Zip_Code__c).Account__c){
                a.Service_Dealer__c = null;
            }
            Logger__c newlog = new Logger__c();
            newlog.Id = pincodeLoggerMap.get(a.Zip_Code__c).Id;
            newlog.Status__c = 'Success';
            UpdateLoggerSet.add(newlog);
         }
    }

     try{
        update existingAssets;
        List<Logger__c> UpdateLoggerList = new List<Logger__c>(UpdateLoggerSet); 
        update UpdateLoggerList;
      }
      catch(Exception e){
        Logger.logError('AssetSharingProcessor', 'removePincodeDealerAccess', '', e);
      }                                          
}


/*--------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Method to Decide Access to Asset based on Key Account Change
Inputs:        NA
Test Class:    
History
21-12-2020      Mahith Madwesh    Initial Release
----------------------------------------------------------------------------*/
public static void KeyAccountChangeAccess(list<Logger__c> logRecords){

     set<Id> accountIds = new set<Id>();
    map<Id,Logger__c> AccountLoggerMap = new map<Id,Logger__c>();
   set<Logger__c> UpdateLoggerSet = new set<Logger__c>();

    for(Logger__c l: logRecords){
        AccountLoggerMap.put(l.Account__c,l);
        accountIds.add(l.Account__c);
    }

 list<Asset> existingAssets = [SELECT Id,AccountId,Address_Code__r.ZipCode__r.Name,Zip_Code__c,AvailableForExternalSharing__c,Service_Dealer__c,Primary_Dealer__c 
                                        FROM Asset WHERE AccountId IN :accountIds];

 list<Pin_Code_Dealer_Mapping__c> pincodeDealerList = [SELECT Id,Name,IsActive__c,Service_Dealer__c FROM Pin_Code_Dealer_Mapping__c WHERE IsActive__c = true];

 map<String,Pin_Code_Dealer_Mapping__c> pincodeDealerMap = new map<String,Pin_Code_Dealer_Mapping__c>();

 for(Pin_Code_Dealer_Mapping__c pc:pincodeDealerList){
     pincodeDealerMap.put(pc.Name,pc);
 }

 for(Asset a: existingAssets){
     //For Offloaded Asset populate service dealer with Primary dealer value
     if(a.AvailableForExternalSharing__c == true && a.Primary_Dealer__c!=null & a.Service_Dealer__c==null){
         a.Service_Dealer__c = a.Primary_Dealer__c;
          if(AccountLoggerMap.containsKey(a.AccountId)){
            Logger__c newlog = new Logger__c();
            newlog.Id = AccountLoggerMap.get(a.AccountId).Id;
            newlog.Status__c = 'Success';
            UpdateLoggerSet.add(newlog);

         }
     }
     if(a.AvailableForExternalSharing__c == true && a.Primary_Dealer__c == null && pincodeDealerMap.containsKey(a.Zip_Code__c)){
         a.Service_Dealer__c = pincodeDealerMap.get(a.Zip_Code__c).Service_Dealer__c;
          if(AccountLoggerMap.containsKey(a.AccountId)){
            Logger__c newlog = new Logger__c();
            newlog.Id = AccountLoggerMap.get(a.AccountId).Id;
            newlog.Status__c = 'Success';
            UpdateLoggerSet.add(newlog);

         }
     }
     if(a.AvailableForExternalSharing__c == false){
         a.Service_Dealer__c = null;
          if(AccountLoggerMap.containsKey(a.AccountId)){
            Logger__c newlog = new Logger__c();
            newlog.Id = AccountLoggerMap.get(a.AccountId).Id;
            newlog.Status__c = 'Success';
            UpdateLoggerSet.add(newlog);

         }
     }
    
 }

 try{
        update existingAssets;
        List<Logger__c> UpdateLoggerList = new List<Logger__c>(UpdateLoggerSet); 
        update UpdateLoggerList;
      }
      catch(Exception e){
        Logger.logError('AssetSharingProcessor', 'KeyAccountChangeAccess', '', e);
      }        
}

}