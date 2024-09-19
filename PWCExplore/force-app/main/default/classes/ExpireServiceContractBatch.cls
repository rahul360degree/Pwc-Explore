/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Batch class to expire service contract.
Inputs:        
Test Class:  
----------------------------------------------------------------------------*/
public class ExpireServiceContractBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC) {  
        String query = 'SELECT Id, Name, StartDate, EndDate, (SELECT Id, AssetId, Asset.Primary_Dealer__c FROM ContractLineItems WHERE Asset.Primary_Dealer__c != null ) '+ 
            			'FROM ServiceContract '+
            			'WHERE EndDate <=  YESTERDAY '+
            			'AND Status__c = \'Open\'' ;
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<ServiceContract> serviceContractsToBeExpired ){
        List<ServiceContract> serviceContractsToBeUpdated = new List<ServiceContract>();
        List<Asset> assetsToBeUpdatedForPrimaryDealer = new List<Asset>();
        
        for(ServiceContract sc: serviceContractsToBeExpired ){
            if(Schema.sObjectType.ServiceContract.fields.Status__c.isUpdateable()){ 
            sc.Status__c = 'Expired';
            serviceContractsToBeUpdated.add(sc);
              }
            //Remove the Primary dealer from Asset for expired Service contract
            if(sc.ContractLineItems.size() > 0){
                for(ContractLineItem cli : sc.ContractLineItems){
                    Asset assetReord = new Asset(Id = cli.AssetId);
                    if(Schema.sObjectType.Asset.fields.Primary_Dealer__c .isUpdateable()){ 
                       assetReord.Primary_Dealer__c = null;
                       assetsToBeUpdatedForPrimaryDealer.add(assetReord);
                    }
                }
                
            }
        }
        try{
            update serviceContractsToBeUpdated;
            update assetsToBeUpdatedForPrimaryDealer;
            
        } catch(Exception ex){
            Logger.logError('ExpireServiceContractBatch', 'Execute', '', ex);            
        }
    }
    
    public Void finish(Database.BatchableContext bc) {
    }

}