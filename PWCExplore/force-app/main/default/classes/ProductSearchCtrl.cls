/*------------------------------------------------------------------------------------
 * Author        :        Sumit
 * Company       :        Salesforce
 * Description   :        Controller for product search
 * Test Class    :        ProductSearchCtrlTest
 * History
 * --------
 * 13-07-2020      Sumit Swami     Initial Release
 * 07-02-2021      Kartik Shetty   Revamped codebase
 * 17-02-2021      Kartik Shetty   Added code to update asset benefit 
 * ----------------------------------------------------------------------------------*/
public without sharing class ProductSearchCtrl {

  public class ProductSearchException extends Exception {}

  //Checks if there are more records for pagination
  public static boolean hasMore = true;

  public static final String EXCLUSTION_PRODUCT_TYPE = 'Exclusion';
  public static final String INCLUSION_PRODUCT_TYPE = 'Inclusion';
  public static final String SERVICE_FORM_SUBMITTED_STATUS = 'Submitted';
  public static final String VALID_USER_PERSONA = System.Label.SR_Product_Valid_Persona;

  private static List<Asset_Benefit__c> assetBenefits = new List<Asset_Benefit__c>();

  /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to check if the record has been locked for further modifications for the user
    Inputs:        Id - Record Id
    Returns:       String
  *----------------------------------------------------------------------------*/
  @AuraEnabled
  public static String checkForRecordLock(Id recordId) {
    try {
      
      Service_Form__c serviceFormRecordInCtxt = [Select Id, Status__c, Opportunity__c, Order__c FROM Service_Form__c WHERE Id = :recordId];
      if(checkIfRecordIsLocked(serviceFormRecordInCtxt)) {
        return 'RECORD_LOCKED';
      }
      return 'RECORD_OPEN';
    } catch (Exception e) {
      throw new ProductSearchException(e.getMessage());
    }
  }

  /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Utility function to check if record is locked or not
    Inputs:        Service_Form__c - serviceFormRecordInCtxt
    Returns:       Boolean
  *----------------------------------------------------------------------------*/
  private static Boolean checkIfRecordIsLocked(Service_Form__c serviceFormRecordInCtxt) {
    User userRecord = [Select Id, Name, Persona__c FROM User WHERE Id = :UserInfo.getUserId()];
    if(serviceFormRecordInCtxt.Order__c != null || serviceFormRecordInCtxt.Opportunity__c != null) {
        return true;
    } else if((String.isBlank(userRecord.Persona__c) || !VALID_USER_PERSONA.containsIgnoreCase(userRecord.Persona__c)) && 
    serviceFormRecordInCtxt.Status__c == SERVICE_FORM_SUBMITTED_STATUS) {
      return true;
    }

    return false;
  }

  /*------------------------------------------------------------------------
    Author:        Sumit
    Company:       Salesforce
    Description:   Main method for Product Search
    Inputs:        String - whereClause, pageSize, pageNumber, fltrProductCode, fltrProductType 
    Returns:       List<productWrapper.product> - Products searched
  *----------------------------------------------------------------------------*/
  @AuraEnabled(cacheable=true)
  public static List<productWrapper.product> getProductsWithOffset(
    String whereClause,
    String pageSize,
    String pageNumber,
    String fltrProductCode,
    String fltrProductType
  ) {
    try {
      List<PricebookEntry> pConfigList = fetchProducts(
        whereClause,
        fltrProductType,
        fltrProductCode,
        pageSize,
        pageNumber
      );
      List<productWrapper.product> pWrapperList = getPBWrapper(pConfigList);
      return pWrapperList;
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw new ProductSearchException(e.getMessage());
    }
  }

  /*------------------------------------------------------------------------
    Author:        Sumit
    Company:       Salesforce
    Description:   Helper method for Product Search
    Inputs:        String - whereClause, pageSize, pageNumber, fltrProductCode, fltrProductType 
    Returns:       List<PricebookEntry> - Products searched
  *----------------------------------------------------------------------------*/
  private static List<PricebookEntry> fetchProducts(
    String whereClause,
    String fltrProductType,
    String fltrProductCode,
    String pageSize,
    String pageNumber
  ) {
    List<PricebookEntry> pConfigList = new List<PricebookEntry>();
    String pricebookName = Label.Product_Search_Pricebook;

    String soqlStr = 'SELECT Id';
    for (
      Schema.FieldSetMember fieldNameTwo : SObjectType.PricebookEntry.FieldSets.Product_Search.getFields()
    ) {
      if (!soqlStr.contains(fieldNameTwo.getFieldPath())) {
        soqlStr = soqlStr + ', ' + fieldNameTwo.getFieldPath();
      }
    }
    //07-May-2021: Added Product2.IsActive = TRUE condition in the where clause
    soqlStr = soqlStr + ' FROM PricebookEntry WHERE product2.IsActive = TRUE AND pricebook2.Name =: pricebookName';
    system.debug('query' + soqlStr);

    if (whereClause != null && whereClause != '') {
      String whereClausePN = '%' + whereClause + '%';
      String whereClauseStr = ' AND (Product2.Name LIKE : whereClausePN OR Product2.Item__c LIKE :whereClausePN)';
      soqlStr += whereClauseStr;
    }

    if (fltrProductType != null && fltrProductType != '') {
      String filterProductType = fltrProductType;
      String filterProductTypeStr = ' AND Product2.Family =: filterProductType';
      soqlStr += filterProductTypeStr;
    }

    if (fltrProductCode != null && fltrProductCode != '') {
      String filterProductCode = '%' + fltrProductCode + '%';
      String filterProductCodeStr = ' AND Product2.Item__c LIKE: filterProductCode';
      soqlStr += filterProductCodeStr;
    }

    String orderByStr = ' ORDER BY Product2.Name LIMIT 9000';
    soqlStr += orderByStr;

    ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(
      Database.getQueryLocator(soqlStr)
    );

    ssc.setpagesize(Integer.valueOf(pageSize));
    ssc.setPageNumber(Integer.valueOf(pageNumber));
    hasMore = ssc.getHasNext();
    pConfigList = (List<PricebookEntry>) ssc.getRecords();

    return pConfigList;
  }

  /*------------------------------------------------------------------------
    Author:        Sumit
    Company:       Salesforce
    Description:   Create wrapper for Product Search results
    Inputs:        List<PriceBookEntry> - Products searched 
    Returns:       List<productWrapper.product> - Products searched in wrapper
  *----------------------------------------------------------------------------*/
  public static List<productWrapper.product> getPBWrapper(
    List<PriceBookEntry> pbeList
  ) {
    Set<id> pbeSet = new Set<id>();
    Set<id> referenceProdSet = new Set<id>();
    integer i = 0;
    List<productWrapper.product> pWrapperList = new List<productWrapper.product>();
    for (PriceBookEntry pbe : pbeList) {
      productWrapper.product pWrap = new productWrapper.product();
      //if custom id is not required this can be cahnged to Product id or PBE id
      pWrap.Id = String.valueOf(getUUID()) + '~' + i;
      pWrap.priceBookEntryId = pbe.Id;
      pWrap.product2Id = pbe.product2Id;
      pWrap.productName = pbe.product2.name;
      pWrap.productCode = pbe.product2.productCode;
      pWrap.itemCode = pbe.product2.Item__c;
      pWrap.unitPrice = pbe.UnitPrice;
      pWrap.isSelected = false;
      pWrap.quantity = 1;
      pWrap.hasMore = hasMore;
      pWrap.netTotal = pbe.UnitPrice;
      pWrapperList.add(pWrap);
      i++;
    }
    return pWrapperList;
  }

  //Custom id for Product wrapper - if required
  private static Long getUUID() {
    Long guid = DateTime.now().getTime();
    return guid;
  }

  /*------------------------------------------------------------------------
    Author:        Sumit
    Company:       Salesforce
    Description:   Main method to add products
    Inputs:        List<productWrapper.product> Products Selected, id - Id of the initiator record 
    Returns:       String
  *----------------------------------------------------------------------------*/
  @AuraEnabled
  public static String addProductsAsLines(List<productWrapper.product> pWrapperBaseProdList, Id recordId) {
    System.debug(pWrapperBaseProdList);
    try {
      Service_Form__c serviceFormRecordInCtxt = [Select Id, Case__c, Case__r.AssetId, Case__r.Asset.Product2Id ,Asset_Benefit__c
        FROM Service_Form__c WHERE Id = :recordId
      ];

      Map<Id, SR_Products__c> productId_VS_existingSRProductList = getExistingSRProductMap(recordId);
      Map<Id, SR_Products__c> productId_VS_SRProduct_ToInsert = new Map<Id, SR_Products__c>();

      for(productWrapper.product productWrapper: pWrapperBaseProdList) {
        // If there is an existing SR product record then update the quantity else create new SR Product record. 
        if(productId_VS_existingSRProductList.containsKey(productWrapper.product2Id) && 
           (productId_VS_existingSRProductList.get(productWrapper.product2Id) != null && 
           !productId_VS_existingSRProductList.get(productWrapper.product2Id).Ignore_record__c)) {
          SR_Products__c srProductRecord = productId_VS_existingSRProductList.get(productWrapper.product2Id);
          srProductRecord.Quantify__c = srProductRecord.Quantify__c + productWrapper.quantity;
          productId_VS_existingSRProductList.put(productWrapper.product2Id, srProductRecord);
        } else {
          SR_Products__c srProductRecord = new SR_Products__c();
          srProductRecord.Product__c = Id.valueOf(productWrapper.product2Id);
          srProductRecord.Quantify__c = productWrapper.quantity;
          srProductRecord.Service_Form__c = recordId;
          srProductRecord.Service_Request__c = serviceFormRecordInCtxt.Case__c;
          productId_VS_SRProduct_ToInsert.put(srProductRecord.Product__c, srProductRecord);
        }
      }

      // Get the list of inclusion products.
      Set<Id> inclusionProductIds = new Set<Id>();
      inclusionProductIds = getInclusionProducts(serviceFormRecordInCtxt.Case__r.Asset.Product2Id, serviceFormRecordInCtxt.Case__r.AssetId);

      // If there are any inclusion products then update the related SR Product's product type field value.
      if(!inclusionProductIds.isEmpty()) {
        for(Id productId : inclusionProductIds) {
          if(productId_VS_SRProduct_ToInsert.containsKey(productId)) {
            SR_Products__c srProductRecord = productId_VS_SRProduct_ToInsert.get(productId);
            srProductRecord.Is_Available_In_Inclusion_List__c = true;
            productId_VS_SRProduct_ToInsert.put(productId, srProductRecord);
          }
        }
      }

      // Insert new SR product records
      if(!productId_VS_SRProduct_ToInsert.isEmpty()) {
        insert productId_VS_SRProduct_ToInsert.values();
      }

      // Update existing SR product records if a similar product is added
      if(!productId_VS_existingSRProductList.isEmpty()) {
        update productId_VS_existingSRProductList.values();
      }

      List<Asset_Benefit__c> assetBenefits = getActiveAssetBenefits(serviceFormRecordInCtxt.Case__r.AssetId);
      if(!assetBenefits.isEmpty()) {
        serviceFormRecordInCtxt.Asset_Benefit__c = assetBenefits[0].Id;
        update serviceFormRecordInCtxt;
      }
      return 'Success';
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw new ProductSearchException(e.getMessage());
    }
  }

  /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get active asset benefits for the specified asset.
    Inputs:        Id - Asset record id
    Returns:       List<Asset_Benefit__c>
  *----------------------------------------------------------------------------*/
  private static List<Asset_Benefit__c> getActiveAssetBenefits(Id assetId) {
    if(assetBenefits.isEmpty()) {
      assetBenefits = [Select Id, Plan__c, Plan__r.Is_Active__c FROM Asset_Benefit__c 
        WHERE Asset__c = :assetId AND Is_Active__c = true AND Plan__r.Is_Active__c = true LIMIT 1
      ];
    }
    return assetBenefits;
  }

  /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get list of product ids that are of type inclusion.
    Inputs:        Set<Id> - Products Selected, Id - Asset Id
    Returns:       Set<Id>
  *----------------------------------------------------------------------------*/
  private static Set<Id> getInclusionProducts(Id primaryProductId, Id assetId) {
    Set<Id> inclusionProductIds = new Set<Id>();
    
    List<Asset_Benefit__c> assetBenefits = getActiveAssetBenefits(assetId);

    // Throw an error if there are no active asset benefits available.
    if(assetBenefits.isEmpty()) {
      // throw new ProductSearchException(System.Label.No_active_asset_benefits_found);
      return inclusionProductIds;
    }

    // Create a set of plans that are available for that asset using the asset benefit data.
    Set<Id> availablePlans = new Set<Id>();
    availablePlans.add(assetBenefits[0].Plan__c);

    // Only add those products for that have a plan specified for them in the asset benefits for the asset record in context.
    List<Inclusion_List__c> inclusionListRecords = [Select Id, Plan__c, Primary_Product__c, Secondary_Product__c
      FROM Inclusion_List__c
      WHERE Primary_Product__c = :primaryProductId AND Plan__c IN :availablePlans
    ];

    if(!inclusionListRecords.isEmpty()) {
      for(Inclusion_List__c inclusionRecord : inclusionListRecords) {
        inclusionProductIds.add(inclusionRecord.Secondary_Product__c);
      }
    }
    return inclusionProductIds;
  }

  /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get map of product id vs existing SR Product records
    Inputs:        Id - Record Id
    Returns:       Map<Id, SR_Products__c>
  *----------------------------------------------------------------------------*/
  private static Map<Id, SR_Products__c> getExistingSRProductMap(Id recordId) {
    Map<Id, SR_Products__c> productId_VS_existingSRProductMap = new Map<Id, SR_Products__c>();
    List<SR_Products__c> srProducts = [Select Id, Product__c, Quantify__c,Ignore_record__c FROM SR_Products__c WHERE Service_Form__c = :recordId];
    if(!srProducts.isEmpty()) {
      for(SR_Products__c srProduct : srProducts) {
        productId_VS_existingSRProductMap.put(srProduct.Product__c, srProduct);
      }
    }

    return productId_VS_existingSRProductMap;
  }
}