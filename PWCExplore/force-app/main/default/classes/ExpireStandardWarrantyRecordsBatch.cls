/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Batch class to expire standard warranty record for an Asset 
whose End date is already lapsed.
Inputs:        
Test Class:   
----------------------------------------------------------------------------*/
public class ExpireStandardWarrantyRecordsBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {  
        String query = 'SELECT Id, Is_Active__c,Asset__c,Asset__r.Primary_Dealer__c,Asset__r.Type_of_Warranty__c,Asset__r.Coverage__c,Asset__r.Serialized_item_warranty_term__c '+ //Added by Shreela and Namrata for SMEPB-139 on 2nd Jan 2024
            'FROM Asset_Benefit__c '+ 
            'WHERE Asset__r.Product_Purchased_Warranty_End_Date__c <= YESTERDAY '+ 
            'AND Plan__r.Is_Standard_Plan__c = true ' + 
            'AND Is_Active__c = true ' ;
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Asset_Benefit__c> assetBenefitsToBeExpired ) { 
        List<Asset> assetList = new List<Asset>(); //Added by Shreela and Namrata for SMEPB-139 on 2nd Jan 2024
        List<Asset_Benefit__c> assetBenefitsToBeUpdated = new List<Asset_Benefit__c>();
        for(Asset_Benefit__c assetBenefitRec: assetBenefitsToBeExpired ){
            if (Schema.sObjectType.Asset_Benefit__c.fields.Is_Active__c.isUpdateable()){ 
                assetBenefitRec.Is_Active__c = false;
                assetList.add(new Asset(Id = assetBenefitRec.Asset__c, Primary_Dealer__c =null, Type_of_Warranty__c = GlobalConstants.NOT_APPLICABLE,
                                        Coverage__c='',Serialized_item_warranty_term__c = GlobalConstants.NO_CONSTANT)); //Added by Shreela and Namrata for SMEPB-139 on 2nd Jan 2024
                assetBenefitsToBeUpdated.add(assetBenefitRec);
            }     
        }       
        try{
            update assetBenefitsToBeUpdated;
            update assetList;//Added by Shreela and Namrata for SMEPB-139 on 2nd Jan 2024
        }
        catch(Exception ex){
            Logger.logError('ExpireStandardWarrantyRecordsBatch', 'Execute', '', ex);            
        }
        
    }
    
    public Void finish(Database.BatchableContext bc) {
    }
    
}