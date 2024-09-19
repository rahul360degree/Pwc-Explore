public class CompetitorProductOnboardingController {
    
    @AuraEnabled(cacheable=false)
    public static void saveAsset(String recordId, String brandName, String assetType, String assetName, 
                                 Integer capacity, Integer ageOfProduct, Date manufacturingDate, List<String> fileNames, List<String> fileContents) {
                                     System.debug('AsstRecordID-->' + recordId);
                                     System.debug('AssetName==>' + fileNames);
                                     System.debug('AssetFile==>' + fileContents);
                                     
                                     try {
                                         // Create Asset record with provided Id
                                         Asset asset = new Asset(Id = recordId);
                                         
                                         // Update Asset fields
                                         asset.Brand_Name__c = brandName;
                                         asset.Asset_Type__c = assetType;
                                         asset.Name = assetName;
                                         asset.Capacity__c = capacity;
                                         asset.Age_of_Product__c = ageOfProduct;
                                         asset.ManufactureDate = manufacturingDate;
                                         update asset;
                                         
                                         // Create lists to hold ContentDocumentLink records
                                         List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
                                         
                                         // Create ContentVersion records and insert them
                                         List<ContentVersion> contentVersions = new List<ContentVersion>();
                                         for (Integer i = 0; i < fileNames.size(); i++) {
                                             ContentVersion cv = new ContentVersion(
                                                 Title = fileNames[i],
                                                 PathOnClient = fileNames[i],
                                                 VersionData = EncodingUtil.base64Decode(fileContents[i]),
                                                 FirstPublishLocationId = asset.Id
                                             );
                                             contentVersions.add(cv);
                                         }
                                         insert contentVersions;
                                     } catch (Exception e) {
                                         System.debug('errrrorrrr->' + e);
                                         // throw new AuraHandledException(e.getMessage());
                                     }
                                 }
    
}