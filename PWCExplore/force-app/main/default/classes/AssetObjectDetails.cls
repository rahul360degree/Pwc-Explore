/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-22-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AssetObjectDetails {
    public AssetObjectDetails() {

    }
    @AuraEnabled(Cacheable = true)
    public static List<Asset> showAssets(String recordId){
        List<Asset> getAsset = new List<Asset>();
        Case sr = [SELECT Id, AccountId, Service_Request_Type__c, Product_Category__c
                         FROM Case 
                         WHERE Id =:recordId];


        if(sr !=null && sr.Service_Request_Type__c == 'Install and Demo'){

             getAsset = [SELECT Id, AccountId, InstallDate, Actual_Product_Category__c 
                        FROM Asset 
                        WHERE AccountId =: sr.AccountId 
                        AND InstallDate = NULL 
                        AND Actual_Product_Category__c =: sr.Product_Category__c ];


        }
        return getAsset;
    }
}