/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Helper class for Asset Trigger
Inputs:        
Test Class:    

----------------------------------------------------------------------------*/
public with sharing class AssetTriggerHelper {
    public static Map<String,String> recordTypeIdVsRecordTypeName = new Map<String,String>();
    public static final string ASSET_STATUS_ACTIVE = 'Active';
    //Flag to avoid reexcution of trigger when asset records are updated for sharing purpose only
    public static Boolean runningFromSharingContext = false;
    
    {
        if(recordTypeIdVsRecordTypeName.size() == 0){
            for(RecordType recType : [Select Id,DeveloperName 
                                      From RecordType 
                                      Where sObjectType =: GlobalConstants.ASSET_OBJECT_API_NAME]){
                                          if(!recordTypeIdVsRecordTypeName.containsKey(recType.Id)){
                                              recordTypeIdVsRecordTypeName.put(recType.Id,recType.DeveloperName);
                                          }
                                      }
        }
    }  
    
    
    /*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Method to deactivate all the associated asset Benefit records
once Asset becomes inactive
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
09-11-2020      Suwarna Rao    Initial Release
----------------------------------------------------------------------------*/
    public void disableScrappedAssetBenefits(map<Id,Asset> newAssets, map<Id,Asset> oldAssets){                 
        List<Id> scrappedAssetsIDs = new List<Id>();
        List<Asset_Benefit__c> assetBenefitsToScrap = new List<Asset_Benefit__c>();
        
        //Get the Scrapped Assets IDs 
        for(Id assetId: newAssets.keySet()){
            if(oldAssets.containsKey(assetId) 
               && !GlobalConstants.ASSET_SCRAPPED_STATUS.contains(oldAssets.get(assetId).Status)  
               && GlobalConstants.ASSET_SCRAPPED_STATUS.contains(newAssets.get(assetId).Status)){ 
                   scrappedAssetsIDs.add(assetId);
               }        
        }   
        
        //Update all the Asset Benefit to Inactive for Scrapped Asset
        if(scrappedAssetsIDs.size() > 0){
            for(Asset_Benefit__c assetBenefitsRecord: [SELECT Id, Name, Is_Active__c 
                                                       FROM Asset_Benefit__c 
                                                       WHERE Asset__c IN: scrappedAssetsIDs 
                                                       AND Is_Active__c = true]){ 
                                                           if(Schema.sObjectType.Asset_Benefit__c.fields.Is_Active__c.isupdateable()){
                                                           assetBenefitsRecord.Is_Active__c = false;
                                                           assetBenefitsToScrap.add(assetBenefitsRecord);
                                                           }
                                                       }      
        }
        try{
            if(assetBenefitsToScrap.size() > 0)
                update assetBenefitsToScrap;  
        } catch(Exception ex){
            Logger.logError('AssetTriggerHelper', 'disableScrappedAssetBenefits', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Method to create asset Benefit record of Standard Warranty
Assumption:     Plan Name & Type of warranty value will be same             
Inputs:        NA
Test Class:    
History
09-11-2020      Suwarna Rao    Initial Release
----------------------------------------------------------------------------*/
    public void createStandardWarrantyAssetBenefits(map<Id,Asset> newAssetRecords, map<Id,Asset> oldAssetRecords){
        List<Asset_Benefit__c> assetBenefitsToCreate = new List<Asset_Benefit__c>();
        map<String, Plan__c> planNameVsDetail = new map<String, Plan__c>();
        set<String> warrantyTypes = new set<String>();
        
        //Fetch Contract Plan RT Id
        Id ContractPlanRTId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
        
        //Iterate to check active & get the warranty types
        for(Id assetId : newAssetRecords.keyset()){
            if((oldAssetRecords == null  || 
                (oldAssetRecords.containsKey(assetId) &&
                 newAssetRecords.get(assetId).Status != oldAssetRecords.get(assetId).Status)) 
               &&  newAssetRecords.get(assetId).Status == GlobalConstants.ASSET_ACTIVE_STATUS 
               &&  String.isNotBlank(newAssetRecords.get(assetId).Type_of_Warranty__c)){
                   warrantyTypes.add(newAssetRecords.get(assetId).Type_of_Warranty__c);
               }
        }
        
        //Fetch Standard Warranty Record
        if(warrantyTypes.size() > 0){
            for(Plan__c plan : [SELECT Id, Name, BD_Visits_Number__c, Scheduled_PM_Visits_Number__c, Audits__c,
                                BD_Visits__c, Equipment_Type__c, Operator__c, Parts_Support__c, Remote_Assistance__c, 
                                Reports_Dashboards__c, Scheduled_PM_Visits__c, Stationed_Manpower__c, Supervisor__c
                                FROM Plan__c 
                                WHERE Name IN :  warrantyTypes 
                                AND Is_Active__c = true 
                                AND RecordTypeId =: ContractPlanRTId]){
                                    planNameVsDetail.put((plan.Name).toUpperCase(), plan);          
                                }
        }
        
        //Create Asset Benefit for Standard Warranty plan
        if(!planNameVsDetail.isEmpty()){
            for(Id assetId: newAssetRecords.keyset()){
                Asset assetRec = newAssetRecords.get(assetId);
                
                if((oldAssetRecords == null  || 
                    (oldAssetRecords.containsKey(assetId) &&
                     assetRec.Status != oldAssetRecords.get(assetId).Status)) 
                   && assetRec.Status == GlobalConstants.ASSET_ACTIVE_STATUS 
                   && String.isNotBlank(assetRec.Type_of_Warranty__c) 
                   && planNameVsDetail.containsKey((assetRec.Type_of_Warranty__c).toUpperCase())){
                       
                       Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
                       
                       assetBenefit.Name = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Name;
                       assetBenefit.Asset__c = assetRec.id;
                       assetBenefit.Plan__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Id;
                       assetBenefit.Is_Active__c = true;
                       assetBenefit.BD_Visits_Number__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).BD_Visits_Number__c;
                       assetBenefit.BD_Visits__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).BD_Visits__c;
                       assetBenefit.Scheduled_PM_Visits_Number__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Scheduled_PM_Visits_Number__c;
                       assetBenefit.Scheduled_PM_Visits__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Scheduled_PM_Visits__c;
                       assetBenefit.Audits__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Audits__c;
                       assetBenefit.Equipment_Type__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Equipment_Type__c;
                       assetBenefit.Operator__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Operator__c;
                       assetBenefit.Parts_Support__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Parts_Support__c;
                       assetBenefit.Remote_Assistance__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Remote_Assistance__c;
                       assetBenefit.Reports_Dashboards__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Reports_Dashboards__c;
                       assetBenefit.Stationed_Manpower__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Stationed_Manpower__c;
                       assetBenefit.Supervisor__c = planNameVsDetail.get((assetRec.Type_of_Warranty__c).toUpperCase()).Supervisor__c;
                       
                       assetBenefitsToCreate.add(assetBenefit);
                   }
            }
        }
        
        //Perform insertion of Asset Benefit records
        try{
            if(assetBenefitsToCreate.size() > 0)
                insert assetBenefitsToCreate;
        } catch(Exception ex){
            Logger.logError('AssetTriggerHelper', 'createStandardWarrantyAssetBenefits', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to update Asset status for Integration user
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
03-12-2020     Kishor Kumar    Initial Release
----------------------------------------------------------------------------*/
    public void updateAssetStatusForIntegrationUser(list<Asset> newAssets){
        set<Id> accountIds = new set<Id>();
        map<Id, Account> accountMap = new map<Id, Account>();
        
        Boolean isIntegrationUser = false;
        
        //fetch user & account Ids
        for(Asset assetRec : newAssets){
            if(assetRec.AccountId != null){
                accountIds.add(assetRec.AccountId);
            }
        }
        
        //fetch user details
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
        //Identify Integration User
        isIntegrationUser  =  currentUser.Profile.Name.toUpperCase()  == GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME.toUpperCase() ? true : false;                       
        
        //Fetch Account details
        accountMap = new map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN: accountIds 
                                           AND (RecordType.DeveloperName IN : GlobalConstants.INSTALLATION_CASE_ACCOUNT_RT 
                                                OR RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER)
                                          ]);                                
        
        //Business logic
        for(Asset assetRec : newAssets){
            
            if(assetRec.AccountId != null && accountMap.containsKey(assetRec.AccountId) 
               && isIntegrationUser){
                   //tagged BP is a dealer then asset status should be Unregistered
                   if(accountMap.get(assetRec.AccountId).RecordType.DeveloperName == GlobalConstants.ACCOUNT_RECORDTYPE_DEALER){
                       assetRec.status = GlobalConstants.ASSET_UNREGISTERED_STATUS;
                   } else {
                       //tagged BP is a B2B custom then asset status should be 'Shipped' 
                       //and installation requests needs to be created against an asset
                       assetRec.status = GlobalConstants.ASSET_STATUS_SHIPPED;
                   }
               }
        } 
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to create Installation type Case record for Shipment of asset
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
19-11-2020     Kishor Kumar    Initial Release
----------------------------------------------------------------------------*/
    public void createInstallationServiceRequest(map<Id,Asset> newAssets, map<Id,Asset> oldAssets){
        list<Case> casesToCreate = new list<Case>();
        map<Id, Account> accountMap = new map<Id, Account>();
        set<Id> accountIds = new set<Id>();
        
        //get all the related account Ids
        for(Id assetId : newAssets.keyset()){   
            if(newAssets.get(assetId).Status == GlobalConstants.ASSET_STATUS_SHIPPED && 
               newAssets.get(assetId).AccountId != null && newAssets.get(assetId).Date_of_Commissioning__c == null &&
               (oldAssets == null || (oldAssets.containsKey(assetId) && 
                                      oldAssets.get(assetId).Status != GlobalConstants.ASSET_STATUS_SHIPPED))){
                                          accountIds.add(newAssets.get(assetId).AccountId);  
                                      }
        }
        
        //fetch account details
        if(accountIds.size() > 0)
            accountMap = new map<Id, Account>([SELECT Id  
                                               FROM Account 
                                               WHERE Id IN: accountIds 
                                               AND RecordType.DeveloperName IN : GlobalConstants.INSTALLATION_CASE_ACCOUNT_RT]);
        List<AssetWrapper> assetForCase = new List<AssetWrapper>();
        //Create Case for Shipped Record
        for(Id assetId : newAssets.keyset()){
            if(newAssets.get(assetId).Status == GlobalConstants.ASSET_STATUS_SHIPPED && 
               newAssets.get(assetId).AccountId != null && 
               newAssets.get(assetId).Date_of_Commissioning__c == null &&
               accountMap.containsKey(newAssets.get(assetId).AccountId) && 
               (oldAssets == null || (oldAssets.containsKey(assetId) && oldAssets.get(assetId).Status != GlobalConstants.ASSET_STATUS_SHIPPED)))
            { 
                assetForCase.add(new AssetWrapper(newAssets.get(assetId)));
            }
        }
        //Perform insertion of Case records
        try{
            if(!assetForCase.isEmpty()){
                assetForCase.sort();
                Profile profile = [Select Id,Name from Profile where id=:Userinfo.getProfileId() ];
                if(profile.name=='Integration Administrator'){
                    Id jobId = System.enqueueJob(new AssetTriggerHelper_Queueable(assetForCase));
                }else{
                    AssetTriggerHelper_Queueable obj = new AssetTriggerHelper_Queueable(assetForCase);
                    obj.createInstallationCase(assetForCase);
                } 
             }
        } catch(Exception ex){
            Logger.logError('AssetTriggerHelper', 'createInstallationServiceRequest', '', ex, 'P1');
        }
    }
    
    
    
    
    
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Set default record type on Asset record based on Business Unit on Account 
only for assets created by Intergation Administrator
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
02-12-2020     Pawan    Initial Release
----------------------------------------------------------------------------*/
    public void setAseetRecordType(List<Asset> newAssets){
        Set<String> accountIds = new Set<String>();
        Set<String> ownerIds = new Set<String>();
        for(Asset asset : newAssets){
            if(asset.AccountId != null){
                accountIds.add(asset.AccountId);
                ownerIds.add(asset.OwnerId);
            }
        }
        //Fetch users where Profile is not 'Integration Administrator'
        Map<String,User> users = new Map<String,User>([Select Id, Profile.Name FROM User 
                                                       WHERE Id IN :ownerIds 
                                                       AND Profile.Name = :System.Label.Integration_User_Profile_Name]);
        if(users.size() > 0){
            //Get Account records where Business Unit is 'MHE Division' and related to an Asset
            Map<String,Account> accountsMap = new Map<String,Account>([Select Id,Business_Unit__c 
                                                                       FROM Account 
                                                                       WHERE Id IN :accountIds AND 
                                                                       Business_Unit__c =: GlobalConstants.BUSINESS_UNIT_MHE_DIVISION]);
            if(accountsMap.size() > 0){
                Id recordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_ASSET_RECORD_TYPE_DEV_NAME).getRecordTypeId();
                
                //Set 'MHE Asset' record type for the asset records created by Integration User
                for(Asset asset : newAssets){
                    if(accountsMap.containsKey(asset.AccountId) && users.containsKey(asset.OwnerId)){
                        asset.RecordTypeId = recordTypeId;
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Create Service record for asset enrollment created from internal user
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
03-12-2020     Pawan    Initial Release
----------------------------------------------------------------------------*/
    public void createServiceRequest(List<Asset> newAssets){
        try{    
            Set<String> createdByIds = new Set<String>();
            for(Asset asset : newAssets){
                createdByIds.add(asset.CreatedById);
            }
            
            List<Asset> assetRecords = new List<Asset>();
            //Fetch users where Profile is not 'Integration Administrator'
            Map<String,User> users = new Map<String,User>([Select Id, Profile.Name FROM User 
                                                           WHERE Id IN :createdByIds 
                                                           AND Profile.Name != : System.Label.Integration_User_Profile_Name]);
            for(Asset asset : newAssets){
                if(asset.Status == GlobalConstants.ASSET_UNREGISTERED_STATUS && users.containsKey(asset.CreatedById)){
                    assetRecords.add(asset);
                }
            }
            
            //Create service record for Asset Enrollment created by Internal User only
            if(assetRecords.size() > 0){
                Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
                List<Case> cases = new List<Case>();
                for(Asset asset : assetRecords){
                    cases.add(new Case(AssetId = asset.Id,
                                       Origin = GlobalConstants.CASE_ORIGIN_AUTOMATED,
                                       Is_System_Created__c = TRUE,
                                       AccountId = asset.AccountId,
                                       Type = GlobalConstants.ASSET_ENROLLEMENT,
                                       Subject = GlobalConstants.ASSET_ENROLLEMENT,
                                       Description = GlobalConstants.ASSET_ENROLLEMENT,
                                       RecordTypeId = recordTypeId,
                                       OwnerId = asset.CreatedById,
                                       Asset_Serial_Number__c = asset.Equipment_Serial_No__c,
                                       Branch__c = asset.Branch__c ));
                }
                System.debug('cases :: ' + cases);
                if(cases.size() > 0 ){
                    insert cases;
                } 
            }
        }catch(Exception ex){
            Logger.logError('AssetTriggerHelper', 'createServiceRequest',null, ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Set defaults at asset record
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
10-12-2020     Pawan            Initial Release
28-01-2021     Kartik Shetty    Updated method to rename asset name based on asset equipment number 
----------------------------------------------------------------------------*/
    public void setDefaults(List<Asset> newAssets){
        Set<String> accountIds = new Set<String>();
        for(Asset asset : newAssets){
            if(recordTypeIdVsRecordTypeName.containsKey(asset.RecordTypeId) 
               && recordTypeIdVsRecordTypeName.get(asset.RecordTypeId) == GlobalConstants.MHE_ASSET_RECORD_TYPE_DEV_NAME){
                   asset.Quantity = 1;
                   if(String.isNotBlank(asset.Equipment_Serial_No__c)) {
                       asset.Name = asset.Equipment_Serial_No__c;
                   }
                   // If account id is present then add it to the list of accounts to fetch
                   if(asset.AccountId != null) {
                       accountIds.add(asset.AccountId);
                   }
               }
        }
        Map<String,Account> accounts = new Map<String,Account>([Select Id,Business_Unit__c FROM Account 
                                                                WHERE Id IN :accountIds 
                                                                AND Business_Unit__c = :GlobalConstants.BUSINESS_UNIT_MHE_DIVISION]);
        if(accounts.size() > 0){
            for(Asset asset : newAssets){
                //Populate Business Unit on Asset record from Account , this will be used in sharing rule
                if(accounts.containsKey(asset.AccountId)){
                    asset.Business_Unit__c = accounts.get(asset.AccountId).Business_Unit__c;
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Update asset name to that of asset Equipment Serial No if asset name or asset Equipment Serial No is changed
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
28-01-2021     Kartik Shetty    Initial Release
----------------------------------------------------------------------------*/
    public void updateAssetName_If_EquipmentSerialNo_IsUpdated(Map<Id, Asset> updatedAssets, Map<Id, Asset> oldAssets) {
        for(Asset assetRecord : updatedAssets.values()) {
            if(recordTypeIdVsRecordTypeName.containsKey(assetRecord.RecordTypeId) 
               && recordTypeIdVsRecordTypeName.get(assetRecord.RecordTypeId) == GlobalConstants.MHE_ASSET_RECORD_TYPE_DEV_NAME) {
                   Asset oldAssetRecord = oldAssets.get(assetRecord.Id);
                   if(oldAssetRecord.Name != assetRecord.Name || oldAssetRecord.Equipment_Serial_No__c != assetRecord.Equipment_Serial_No__c) {
                       if(String.isNotBlank(assetRecord.Equipment_Serial_No__c)) {
                           assetRecord.Name = assetRecord.Equipment_Serial_No__c;
                       }
                   }
               }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Populate Service Dealer on Asset for Asset Sharing
Inputs:        NA
Test Class:    AssetTriggerHelperTest
History
10-12-2020     Pawan    Initial Release
----------------------------------------------------------------------------*/
    public void checkForExternalSharing(List<Asset> newAssets, Map<Id,Asset> oldAssets){
        try{
            Set<String> accountIds = new Set<String>();
            Set<String> addressCodes = new Set<String>();
            Map<String,Pin_Code_Dealer_Mapping__c> pincodeMapping = new Map<String,Pin_Code_Dealer_Mapping__c>();
            Map<String,String> addresses = new Map<String,String>();
            Map<String,Account> accounts = new Map<String,Account>();
            Set<String> zipCodes = new Set<String>();
            
            List<Asset> assets = new List<Asset>();
            if(!runningFromSharingContext){
                for(Asset asset : [Select Id,AccountId,Address_Code__c,Zip_Code__c,Service_Dealer__c,AvailableForExternalSharing__c,LastModifiedBy.Name,Primary_Dealer__c,
                                   //Shankar Sahu 31/3/2021 Status field added to this query 
                                   Status,
                                   //Added on 28-Jul-2021 to check for primary dealer's BP Code
                                   Primary_Dealer__r.Account_Code__c FROM Asset 
                                   WHERE Id IN : newAssets
                                   AND LastModifiedBy.Name != 'Automated Process']){
                                       assets.add(asset);                        
                                   }
                
                for(Asset asset : assets){
                    if(asset.AccountId != null){
                        accountIds.add(asset.AccountId);
                    }
                    
                    //Whenever Address Code is populated
                    if(asset.Address_Code__c != null){
                        addressCodes.add(asset.Address_Code__c);
                    }else if(asset.Zip_Code__c != null){ //Whenever Zip Code(Text) is populated, this will be populated for legacy data only
                        zipCodes.add(asset.Zip_Code__c);
                    }
                }
                
                if(accountIds.size() > 0){
                    accounts = new Map<String,Account>([Select Id,RecordType.DeveloperName 
                                                        FROM Account 
                                                        WHERE Id IN :accountIds
                                                        AND Account.RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER]);
                }
                
                //If Address Code is populated on Records
                if(addressCodes.size() > 0){
                    for(Address__c address : [Select Id,ZipCode__r.Name FROM Address__c WHERE Id IN :addressCodes]){
                        addresses.put(address.Id,address.ZipCode__r.Name);
                    }
                    
                    if(addresses.values().size() > 0){
                        for(Pin_Code_Dealer_Mapping__c pincode : [Select Id,Name,Service_Dealer__c FROM Pin_Code_Dealer_Mapping__c 
                                                                  WHERE Name IN :addresses.values()
                                                                  AND IsActive__c = true]){
                                                                      pincodeMapping.put(pincode.Name,pincode);
                                                                  }
                    }
                }
                
                //If ZipCode(Text) is populated on records
                if(zipCodes.size() > 0){
                    for(Pin_Code_Dealer_Mapping__c pincode : [Select Id,Name,Service_Dealer__c FROM Pin_Code_Dealer_Mapping__c 
                                                              WHERE Name IN :zipCodes
                                                              AND IsActive__c = true]){
                                                                  pincodeMapping.put(pincode.Name,pincode);
                                                              }
                }
                
                for(Asset asset : assets){
                    
                    //External Sharing :: Scenarion 1 => Set Service Dealer for Unregistered asset for dealer :: Update from Asset Owner to Asset Account of dealer record type
                    if(accounts.containsKey(asset.AccountId) 
                       && asset.Status == GlobalConstants.ASSET_UNREGISTERED_STATUS
                       && asset.AvailableForExternalSharing__c ){
                           asset.Service_Dealer__c = asset.AccountId;    
                       }
                    
                    //External Sharing :: Scenarion 2 => Set Service Dealer when address is changed on asset record
                    // If => Address Code is populated
                    // else => ZipCode(Text) is populated
                    if((oldAssets == null ||(asset.Address_Code__c != null)) 
                       && addresses.containsKey(asset.Address_Code__c) 
                       && pincodeMapping.containsKey(addresses.get(asset.Address_Code__c))
                       && pincodeMapping.get(addresses.get(asset.Address_Code__c)).Service_Dealer__c != null){
                           asset.Service_Dealer__c = pincodeMapping.get(addresses.get(asset.Address_Code__c)).Service_Dealer__c;
                       }else if((oldAssets == null ||(asset.Zip_Code__c != null)) 
                                && pincodeMapping.containsKey(asset.Zip_Code__c)
                                && pincodeMapping.get(asset.Zip_Code__c).Service_Dealer__c != null){
                                    asset.Service_Dealer__c = pincodeMapping.get(asset.Zip_Code__c).Service_Dealer__c;
                                }else{
                                    asset.Service_Dealer__c = null;
                                }
                    
                    //External Sharing :: Scenarion 3 => Asset Offloaded to a dealer
                    if(asset.Primary_Dealer__c != null && asset.AvailableForExternalSharing__c && asset.Primary_Dealer__r.Account_Code__c != null){
                        asset.Service_Dealer__c = asset.Primary_Dealer__c;
                    }
                    
                    if(asset.AvailableForExternalSharing__c == false){
                        asset.Service_Dealer__c = null;
                    }
                }
            }
            
            if(assets.size() > 0){
                runningFromSharingContext = true;
                upsert assets;
            }
        }catch(Exception ex){
            Logger.logError('AssetTriggerHelper', 'checkForExternalSharing', null, ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        kishor Kumar
Company:       Salesforce
Description:   validate Asset Status flow for MHE
* Asset status can move from Inactive to Active. 
* Unregistered → In Transit → Shipped → Registered/Commissioned → Active→ Inactive→ Scrapped

Inputs:        map of updated Asset records

History
16-12-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void validateMHEAssetStatus(map<Id,Asset> newAssets, map<Id, Asset> oldAssets){
        map<String, Integer> statusVsIndex = new map<String, Integer>();
        map<String, Integer> statusVsIndex2 = new map<String, Integer>();
        Boolean hasCustomPermBackTrackAssetStatus; // Checks on user if asset status backtrack allowed
        //Fetch MHE Record Type Id
        Id mheAssetRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
        
        String mheAssetStatus = System.Label.MHE_Asset_Status_Validator;
        List<String> commaSeperatedList = mheAssetStatus.split(',');
        
        List<String> statusList = commaSeperatedList[0].split('>');
        List<String> statusList2 = commaSeperatedList[1].split('>');
        
        //Map for all the valid status
        for(Integer i = 0; i < statusList.size(); i++){
            statusVsIndex.put((statusList[i]).trim().toUpperCase(), i);
        }
        
        //Map for Inactive to Active status
        for(Integer i = 0; i < statusList2.size(); i++){
            statusVsIndex2.put((statusList2[i]).trim().toUpperCase(), i);
        }
        
        //Logic to validate
        for(Id assetId : newAssets.keyset()){
            Boolean isInvalidStatus = false;
            
            if(newAssets.get(assetId).RecordTypeId == mheAssetRecordTypeId && 
               newAssets.get(assetId).Status != oldAssets.get(assetId).Status){
                   if(String.isBlank(newAssets.get(assetId).Status)){
                       isInvalidStatus = true;
                   } else 
                       
                       //Asset status can move from Inactive to Active
                       if(statusVsIndex2.containsKey((newAssets.get(assetId).Status).trim().toUpperCase()) && 
                          statusVsIndex2.containsKey((oldAssets.get(assetId).Status).trim().toUpperCase()) && 
                          statusVsIndex2.get((oldAssets.get(assetId).Status).trim().toUpperCase()) == 0 && 
                          statusVsIndex2.get((newAssets.get(assetId).Status).trim().toUpperCase()) == 1){
                              isInvalidStatus = false;
                          } 
                   
                   //Unregistered → In Transit → Shipped → Registered/Commissioned → Active→ Inactive→ Scrapped
                   else if(statusVsIndex.containsKey((newAssets.get(assetId).Status).trim().toUpperCase()) && 
                           statusVsIndex.containsKey((oldAssets.get(assetId).Status).trim().toUpperCase()) && 
                           statusVsIndex.get((oldAssets.get(assetId).Status).trim().toUpperCase())  > 
                           statusVsIndex.get((newAssets.get(assetId).Status).trim().toUpperCase())){
                               isInvalidStatus = true;
                           }    
               }
            //Added the boolean to check if the asset status back tracking allowed
            hasCustomPermBackTrackAssetStatus = FeatureManagement.checkPermission(System.Label.Allow_Asset_Status_BackTrack);
            if(isInvalidStatus && !hasCustomPermBackTrackAssetStatus){
                newAssets.get(assetId).Status.addError(System.Label.Asset_Status_Backtrack_error); 
            }
        }
    } 
    
    /*------------------------------------------------------------------------
Author:        Amit Shingavi
Company:       Salesforce
Description:   Map to update the Asset defaults based on the order reference number

History
21-12-2020      Amit Shingavi     Initial Release
----------------------------------------------------------------------------*/
    public void populateDefaultsBasedOnOrderReference(List<Asset> newAssets){
        
        List<Order> orderList = new List<Order>();
        Map<String,Order> orderMap = new Map<String,Order>();
        Set<String> orderRefLst = new Set<String>();
        Set<String> areaCodes = new Set<String>();
        Map<String,Asset> assetToUpdate = new Map<String,Asset>();
        
        for(Asset assetItr : newAssets){
            if(String.isNotBlank(assetItr.Order_Number__c)){
                orderRefLst.add(assetItr.Execution_Branch__c+'_'+assetItr.Order_Number__c);
                assetToUpdate.put(assetItr.Execution_Branch__c+'_'+assetItr.Order_Number__c,assetItr);
            }
            
            if(String.isNotBlank(assetItr.Area_Code__c))
                areaCodes.add(assetItr.Area_Code__c);
        }
        
        for(Order orderItr : [SELECT Id, 
                              Order_Reference_Number_Ext__c,
                              Area__c,
                              Ship_To_Address__r.Address_Code__c 
                              FROM Order 
                              WHERE Order_Reference_Number_Ext__c IN:orderRefLst]){
                                  
                                  if(assetToUpdate.containsKey(orderItr.Order_Reference_Number_Ext__c)){
                                      Asset assetTemp = assetToUpdate.get(orderItr.Order_Reference_Number_Ext__c);
                                      assetTemp.Area_Code__c    =  String.isBlank(assetTemp.Area_Code__c) && orderItr.Area__c != null? 
                                          orderItr.Area__c : assetTemp.Area_Code__c;
                                      
                                      assetTemp.Address_Code__c = String.isBlank(assetTemp.Address_Code__c) && 
                                          orderItr.Ship_To_Address__c != null  
                                          ? orderItr.Ship_To_Address__r.Address_Code__c : assetTemp.Address_Code__c; 
                                      areaCodes.add(orderItr.Area__c);
                                  }                     
                              }
        
        system.debug('areaCodes=='+areaCodes);
        // Method to populate the service branch on asset records based on area code 
        Map<String,Area_Code_Branch_Champion__mdt> areaServiceBranchMap = areaServiceBranchMapping(areaCodes);
        system.debug(areaServiceBranchMap);
        
        for(Asset assetItr : newAssets){
            if(String.isNotBlank(assetItr.Area_Code__c) && 
               areaServiceBranchMap.containsKey(assetItr.Area_Code__c) 
               && areaServiceBranchMap.get(assetItr.Area_Code__c) != null)
                assetItr.Branch__c = String.isBlank(assetItr.Branch__c ) && String.isNotBlank(areaServiceBranchMap.get(assetItr.Area_Code__c).Service_Branch__c)? 
                areaServiceBranchMap.get(assetItr.Area_Code__c).Service_Branch__c : assetItr.Branch__c;
            assetItr.Execution_Branch__c = String.isBlank(assetItr.Execution_Branch__c ) && areaServiceBranchMap.containsKey(assetItr.Area_Code__c) && String.isNotBlank(areaServiceBranchMap.get(assetItr.Area_Code__c).MHE_Execution_Branch__c)? 
                areaServiceBranchMap.get(assetItr.Area_Code__c).MHE_Execution_Branch__c : assetItr.Execution_Branch__c; 
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Amit Shingavi
Company:       Salesforce
Description:   Populate the event action based on the synced status, Add would be the default value and 

History
28-12-2020      Amit Shingavi     Initial Release
----------------------------------------------------------------------------*/
    public void updateEventActionOnAsset(map<Id,Asset> newAssets, map<Id, Asset> oldAssets){
        
        for(Asset assetRec : newAssets.values()){
            if(assetRec.Integration_Status__c == 'Synced' &&
               assetRec.Integration_Status__c != oldAssets.get(assetRec.Id).Integration_Status__c ) {
                   assetRec.Event_Action__c = 'Replace';           
               }
        }
    }     
    
    /*------------------------------------------------------------------------
Author:        kishor Kumar
Company:       Salesforce
Description:   Update Warranty End Date for MHE Assets

Inputs:        map of updated Asset records

History
24-12-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void updateWarrantyEndDate(map<Id,Asset> newAssets, map<Id, Asset> oldAssets){
        //Fetch Api Vs Label values of Coverage picklist
        map<String, String> picklistApiVsLabelValues = getPicklistValues('Asset', 'Coverage__c');
        
        //Fetch MHE Record Type Id
        Id mheAssetRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('MHE_Asset').getRecordTypeId();
        
        
        for(Asset assetRec : newAssets.values()){
            if(oldAssets.containsKey(assetRec.Id) && assetRec.RecordTypeId == mheAssetRecordTypeId && 
               (assetRec.Product_Purchased_Warranty_Start_Date__c != oldAssets.get(assetRec.Id).Product_Purchased_Warranty_Start_Date__c 
                || assetRec.Coverage__c != oldAssets.get(assetRec.Id).Coverage__c)){
                    if(assetRec.Product_Purchased_Warranty_Start_Date__c != null 
                       && String.isNotBlank(assetRec.Coverage__c)){
                           Integer coverageMonth = Integer.valueOf(picklistApiVsLabelValues.get(assetRec.Coverage__c.toUpperCase()).substringAfterLast('_'));
                           DateTime dt = assetRec.Product_Purchased_Warranty_Start_Date__c.addMonths(coverageMonth) - 1;
                           assetRec.Product_Purchased_Warranty_End_Date__c = Date.newinstance(dt.year(), dt.month(), dt.day());
                       } else if(assetRec.Product_Purchased_Warranty_Start_Date__c == null 
                                 || String.isBlank(assetRec.Coverage__c)){
                                     assetRec.Product_Purchased_Warranty_End_Date__c = null;
                                 }
                }
        }
        
    }
    
    private map<String, String> getPicklistValues(String objectAPIName, String fieldAPIName){
        map<String, String> picklistApiVsLabelValues = new map<String, String>(); 
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectAPIName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : values){
            picklistApiVsLabelValues.put(pickListVal.getValue().toUpperCase(), pickListVal.getLabel().toUpperCase());
        } 
        return picklistApiVsLabelValues; 
    }
    
    /*------------------------------------------------------------------------
Author:        Amit Shingavi
Company:       Salesforce
Description:   Generic method to return the area code to the branch mapping

Inputs:        Set of area codes from order based on the order number populated on the asset 

History
28-12-2020     Amit Shingavi     Initial Release
----------------------------------------------------------------------------*/
    public Map<String,Area_Code_Branch_Champion__mdt> areaServiceBranchMapping(Set<String> areaCodes){
        Map<String,Area_Code_Branch_Champion__mdt> areaServiceBranch = new Map<String,Area_Code_Branch_Champion__mdt>();
        for(Area_Code_Branch_Champion__mdt mdtItr : [SELECT Area_Code__c,
                                                     Service_Branch__c,
                                                     MHE_Execution_Branch__c
                                                     FROM Area_Code_Branch_Champion__mdt
                                                     WHERE Area_Code__c IN: areaCodes]){
                                                         areaServiceBranch.put(mdtItr.Area_Code__c,mdtItr);                                            
                                                     }
        return areaServiceBranch;
    }
    
    /*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   populate warranty start and end Date for Std and silver EWP Warranty
History
15-01-2020     Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
    public void populateWarrantyStartAndEndDate(list<Asset> newAssets, map<Id,Asset> oldAssets){
        Integer stdWarrantyDates = Integer.valueOf(System.label.Asset_Standard_warranty_End_Date);
        Integer silverWarrantyDates = Integer.valueOf(System.label.Asset_Silver_warranty_End_Date);
        for(asset a: newAssets){
            
            if(oldAssets == null || (oldAssets.get(a.Id).Status != a.Status && a.Status== GlobalConstants.ASSET_ACTIVE_STATUS )){
                if(a.Date_of_Commissioning__c!=null){
                    if(a.Type_of_Warranty__c == GlobalConstants.ASSET_STD_WARRANTY){
                        a.Product_Purchased_Warranty_Start_Date__c = a.Date_of_Commissioning__c;
                        DateTime dt = a.Date_of_Commissioning__c.addDays(stdWarrantyDates);
                        a.Product_Purchased_Warranty_End_Date__c = Date.newinstance(dt.year(), dt.month(), dt.day());
                    }else if(a.Type_of_Warranty__c == GlobalConstants.ASSET_SILVER_EWP_WARRANTY){
                        a.Product_Purchased_Warranty_Start_Date__c = a.Date_of_Commissioning__c;
                        DateTime dt = a.Date_of_Commissioning__c.addDays(silverWarrantyDates);
                        a.Product_Purchased_Warranty_End_Date__c = Date.newinstance(dt.year(), dt.month(), dt.day());
                    }
                    
                }
            }
        }
    }
    
    /*-------------------------------------------------------------------------
Author:        Abhishek Chaturvedi
Company:       Salesforce
Description:   Create warranty claims for Active Asset
History
27-01-2020     Abhishek Chaturvedi     Initial Release
----------------------------------------------------------------------------*/
    public void createWarrantyClaimRequestForActiveAssets(Map<Id,Asset> idVsAsset) {
        CreateWarrantyClaimRequestForAsset.createWarrantyClaims(idVsAsset);
    }
    
    public void createWarrantyClaimsForNewActiveAssets(List<Asset> newAssets) {
        Map<Id,Asset> idVsAsset=new Map<Id,Asset>();
        for(Asset newAsset : newAssets) {
            if(newAsset.Status == ASSET_STATUS_ACTIVE) {
                idVsAsset.put(newAsset.Id,newAsset);
            }
        }
        if((idVsAsset.keySet()).size() > 0) {
            createWarrantyClaimRequestForActiveAssets(idVsAsset);
        }
    }
    public void createWarrantyClaimRequestsForAssetsUpdatedActive(Map<Id,Asset> newMap,Map<Id,Asset> oldMap) {
        Map<Id,Asset> idVsAsset=new Map<Id,Asset>();
        for(Asset assetRecord : newMap.values()) {
            if(assetRecord.Status == ASSET_STATUS_ACTIVE && assetRecord.Status != oldMap.get(assetRecord.Id).Status) {
                idVsAsset.put(assetRecord.Id,assetRecord);
            }
        }
        if((idVsAsset.keySet()).size() > 0) {
            createWarrantyClaimRequestForActiveAssets(idVsAsset);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   populate product related details on asset record
    History
    17-02-2020     Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateProductDetails(list<Asset> newAssets){
        Set<String> productIds = new Set<String>();
        for(Asset asset : newAssets){
            if(recordTypeIdVsRecordTypeName.containsKey(asset.RecordTypeId) 
               && recordTypeIdVsRecordTypeName.get(asset.RecordTypeId) == GlobalConstants.MHE_ASSET_RECORD_TYPE_DEV_NAME
               && asset.Product2Id != null 
               && (asset.Product_Family__c == null || asset.Product_Category__c == null 
                   || asset.Product_Sub_Category__c == null || asset.Equipment_Category__c == null)){
                       productIds.add(asset.Product2Id);
                   }
        }
        
        if(productIds.size() > 0){
            Map<String,Product2> productsMap = new Map<String,Product2>([Select Id,Family,Product_Category__c,Product_Sub_Category__c 
                                                                         FROM Product2 
                                                                         WHERE Id IN :productIds]);
            
            for(Asset asset : newAssets){
                if(productsMap.containsKey(asset.Product2Id)){
                    asset.Product_Family__c = productsMap.get(asset.product2Id).Family;
                    asset.Product_Category__c = productsMap.get(asset.product2Id).Product_Category__c;
                    asset.Product_Sub_Category__c = productsMap.get(asset.product2Id).Product_Sub_Category__c;
                    if(asset.Product_Sub_Category__c != null 
                       && GlobalConstants.PRODUCT_CATEGORY_WITH_EQUIPMENT_CATEGORY.containsKey(asset.Product_Sub_Category__c)){
                           asset.Equipment_Category__c = GlobalConstants.PRODUCT_CATEGORY_WITH_EQUIPMENT_CATEGORY.get(asset.Product_Sub_Category__c);
                       }
                }
            }
        }
    }
}