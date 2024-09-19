public with sharing class AssetCreationController {
    
    @AuraEnabled
    public static void createAsset(String assetName, String assetDescription, String assetBusinessUnit, Boolean isCompetitor,String serialNumber,
                                   String brandName, String assetType, Decimal capacity, Integer ageOfProduct, Date manufacturingDate,String recordId,String productId,String addressCode,String addressValue) {
        try {
            System.debug('RecordID===>' + recordId);
            System.debug('ProductCode-<'+productId);
            System.debug('AddressCode-->' +addressCode + '   addresscod->'+addressValue );
            Asset newAsset = new Asset();
            newAsset.Name = assetName;
            newAsset.Description = assetDescription;
            //newAsset.Business_Unit__c = assetBusinessUnit;
            newAsset.IsCompetitorProduct = isCompetitor;
            newAsset.AccountId = recordId;
            //newAsset.Product2Id = productId;
            newAsset.Equipment_Serial_No__c = serialNumber;
            newAsset.Address_Code__c = addressCode;
			newAsset.Area_Code__c = addressValue;
            if (isCompetitor) {
                newAsset.Brand_Name__c = brandName;
                newAsset.Asset_Type__c = assetType;
                newAsset.Capacity__c = capacity;
                newAsset.Age_of_Product__c = ageOfProduct;
                newAsset.ManufactureDate = manufacturingDate;
            }
            
            insert newAsset;
        } catch(Exception e) {
            throw new AuraHandledException('Error occurred while creating asset: ' + e.getMessage());
        }
    }
}