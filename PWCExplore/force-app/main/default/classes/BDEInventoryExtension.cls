/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Utility class to perform inventory integration and other operations for BDE approach
Inputs:        NA
Test Class:    BDEInventoryExtensionTest
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public class BDEInventoryExtension {
    private static final String PRODUCT_STOCK_ENQUIRY_BDE_URL = System.Label.PRODUCT_STOCK_ENQUIRY_BDE_URL;
    private static List<Product2> productsToDisplay;

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the child product records (OppProduct/QLI/OrderItem) in a formatted datastructure
                   based on the parent record id and user id.
    Inputs:        String recId, String userId
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public String getProductsBasedOnDefaultValues(String recId, String userId) {
        InventoryCheckController checkControllerInstance = new InventoryCheckController();
        List<String> productIds = new List<String>();
        productsToDisplay = new List<Product2>();
        List<String> defaultFields = new List<String>{'Name', 'Item__c'};
        Map<String, String> fieldAPINameVSLabel = checkControllerInstance.getFieldsToFetchInfo(defaultFields);
        List<String> dataList = new List<String>();
        List<String> warehouseCodes = new List<String>();
        List<String> companyCodes = new List<String>();
        Boolean isError = false;
        Boolean isGodrejRenTrust=false;
        String errorMessage = '';

        Id recordId = Id.valueOf(recId);
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        System.debug('object name: ' + sObjName);
        isGodrejRenTrust = isGodrejRenTRUST(recordId,sObjName);
        checkControllerInstance.getCurrentUserRecord(userId);
     

        List<sObject> childRecords = getChildLineItemsOfObject(recordId, sObjName);

        // Identify the products to be fetched and also create a DS for company code and warehouse code.
        for(sObject childRecord : childRecords) {
            Map<String, Object> fieldsToValueMap = childRecord.getPopulatedFieldsAsMap();
            System.debug('fieldsToValueMap::' + fieldsToValueMap.keySet());
            if(fieldsToValueMap.containsKey('Warehouse__r') && isGodrejRenTrust ==false) {
                //Warehouse__c warehouseRecord = (Warehouse__c) fieldsToValueMap.get((String) childRecord.getSobject('Warehouse__c'));
                String companyCode = (String) childRecord.get('Product2Id') + '--' + (String) childRecord.getSobject('Warehouse__r').get('Logistic_Company__c');
                String warehouseCode = (String) childRecord.get('Product2Id') + '--' + (String) childRecord.getSobject('Warehouse__r').get('Warehouse__c');

                companyCodes.add(companyCode);
                warehouseCodes.add(warehouseCode);
            }
            productIds.add((String)childRecord.get('Product2Id'));
        }
        if(isGodrejRenTrust == True){
          String mheRentalsWHCompanyCodes= Label.MHERentalsWHCompanyCodes;
          for (String pid: productIds){
            List<String> whCompCodes = mheRentalsWHCompanyCodes.split('#');
            system.debug(' length is ' + whCompCodes);
            for (String whCompCode: whCompCodes)
            {             
            warehouseCodes.add(pid + '--' + (whCompCode.split('_'))[1]);
            companyCodes.add(pid + '--' + (whCompCode.split('_'))[0]);
            }
          }
        }
        System.debug('Company Codes: ' + companyCodes);
        System.debug('Warehouse Codes: ' + warehouseCodes);

        productsToDisplay = getProductsBasedOnId(productIds, new List<String>(fieldAPINameVSLabel.keySet()));
        for(Product2 productRecord : productsToDisplay) {
            String data = JSON.serialize(productRecord);
            dataList.add(data);
        }

        FieldDescriptor fieldDescriptorObj = checkControllerInstance.createFieldDescriptorObject('Search Table', 'search_table', fieldAPINameVSLabel, '');
        fieldDescriptorObj.fieldType = 'table';
        fieldDescriptorObj.config.put('data', dataList);
        fieldDescriptorObj.config.put('CompanyCodes', companyCodes);
        fieldDescriptorObj.config.put('WarehouseCodes', warehouseCodes);
        fieldDescriptorObj.isError = isError;
        fieldDescriptorObj.errorMessage = errorMessage;

        return JSON.serialize(fieldDescriptorObj);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the parent sobject record based on the record id and object name 
    Inputs:        Id recordId, String sObjectName
    Output Type:   sObject
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private sObject getParentRecord(Id recordId, String sObjectName) {
        switch on sObjectName.toUpperCase() {
            when 'OPPORTUNITY' {
                return [Select Id, Sales_Branch_Name__c FROM Opportunity WHERE Id = :recordId];
            }
            when 'QUOTE' {
                return [Select Id, Sales_Branch_Name__c FROM Quote WHERE Id = :recordId];
            }
            when 'ORDER' {
                return [Select Id, Logistics_Company_Branch__c, WarehouseCode__c FROM Order WHERE Id = :recordId];
            }
            when 'WAREHOUSE' {
                return [Select Id, Name, Warehouse__c FROM Warehouse__c WHERE Id = :recordId];
            }
            when else {
                System.debug('No match found');
                return recordId.getSObjectType().newSObject(recordId);
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get list of child sObject records based on parent record id and parent object name.
    Inputs:        Id recordId, String sObjectName
    Output Type:   List<sObject>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private List<sObject> getChildLineItemsOfObject(Id parentRecordId, String parentObjectName) {
        switch on parentObjectName.toUpperCase() {
            when 'OPPORTUNITY' {
                return [Select Id, Product2Id, Warehouse__r.Warehouse__c, Warehouse__r.Logistic_Company__c, Free_Stock__c 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId = :parentRecordId];
            }
            when 'QUOTE' {
                return [Select Id, Product2Id, Warehouse__r.Warehouse__c, Warehouse__r.Logistic_Company__c, Free_Stock__c
                    FROM QuoteLineItem WHERE QuoteId = :parentRecordId];
            }
            when 'ORDER' {
                return [Select Id, Product2Id, Warehouse__r.Warehouse__c, Warehouse__r.Logistic_Company__c, Free_Stock__c
                    FROM OrderItem WHERE OrderId = :parentRecordId];
            }
            when else {
                System.debug('No match found');
                return new List<sObject>();
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get list of product records based on the product ids and 
                   also dynamically determine the fields to get from the product records.
    Inputs:        List<String> productIds, List<String> fieldsToGet
    Output Type:   List<Product2>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private List<Product2> getProductsBasedOnId(List<String> productIds, List<String> fieldsToGet) {
        System.debug('Fields to get: ' + fieldsToGet.size());
        List<Product2> productList = new List<Product2>();

        String query = 'Select Id';
        for(String field : fieldsToGet) {
            query += ', ' + field;
        }
        query += ' FROM Product2 WHERE Id IN :productIds';
        //query += ' LIMIT 200';
        productList = Database.query(query);
        return productList;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get stock information for the products passed
    Inputs:        String productsToGet, String parentRecordId, String parentObjectName
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public String getStockProductsForBDE(String productsToGet, String parentRecordId, String parentObjectName) {
        InventoryCheckController checkControllerInstance = new InventoryCheckController();
        Map<String, Object> requestParameters = (Map<String, Object>) JSON.deserializeuntyped(productsToGet);
        InventoryXMLParser inventoryXMLParserObj = new InventoryXMLParser();

        BDERequestMapper requestMapperObject = new BDERequestMapper();
        requestMapperObject.organizationId = System.Label.Organization_Id;

        try {
            if(requestParameters.containsKey('CompanyCodes')) {
                requestMapperObject.company = ( ((String) requestParameters.get('CompanyCodes')).split(','))[0];
            }
            if(requestParameters.containsKey('WarehouseCodes')) {
                system.debug('warehouse --------- '+requestParameters.get('WarehouseCodes'));
                requestMapperObject.warehouse = ( ((String) requestParameters.get('WarehouseCodes')).split(','))[0];
            }
            if(requestParameters.containsKey('ItemCodes')) {
                requestMapperObject.itemCode = ( ((String) requestParameters.get('ItemCodes')).split(','))[0];
            }
    
            DOM.Document doc = inventoryXMLParserObj.generateXMLRequestStructure(requestMapperObject);
            HttpResponse response = makeHTTPCalloutForBDE(PRODUCT_STOCK_ENQUIRY_BDE_URL, 'POST', doc);
            System.debug('Response:');
            System.debug(response.getBody());
            if(response.getStatusCode() != 200) {
                System.debug('There was an error while fetching records from the remote site.');
                BDEResponseMapper responseMapperObj = inventoryXMLParserObj.parseXMLResponse(response.getBody());
                return createBDEResponseStructure(responseMapperObj, response.getStatusCode());
            } else {
                BDEResponseMapper responseMapperObj = inventoryXMLParserObj.parseXMLResponse(response.getBody());
                System.debug('BDEResponseMapper response:');
                System.debug(responseMapperObj);
                List<SObject> childRecords = getChildLineItemsOfObject(Id.valueOf(parentRecordId), parentObjectName);
                postSuccessfulCalloutOperations(responseMapperObj, parentRecordId, parentObjectName, childRecords);
                return createBDEResponseStructure(responseMapperObj, 200);
            }
        } catch(InventoryCheckerException exceptionObj) {
            throw exceptionObj;
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to make an HTTP callout to get stock product information from external service.
    Inputs:        String endpoint, String method, DOM.Document body
    Output Type:   HttpResponse
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private HttpResponse makeHTTPCalloutForBDE(String endpoint, String method, DOM.Document body) {
        Http h = new Http();
        // Instantiate a new HTTP request, specify the method (POST) as well as the endpoint
        HttpRequest req = new HttpRequest();
        System.debug('XML String');
        System.debug(body.toXMLString());

        try {
            req.setEndpoint(endpoint);
            req.setMethod(method);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(body.toXMLString());
            req.setTimeout(120000);

            // Send the request, and return a response
            HttpResponse res = h.send(req);
            System.debug('Status Code: ' + res.getStatusCode());
            return res;
        } catch(InventoryCheckerException exceptionObj) {
            throw new InventoryCheckerException('There was an exception while trying to get the stock values from BDE endpoint.');
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to perform a set of operations if the callout was successful.
    Inputs:        BDEResponseMapper response, String parentRecId, String parentObjectName, List<SObject> childRecords
    Output Type:   
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private void postSuccessfulCalloutOperations(BDEResponseMapper response, String parentRecId, String parentObjectName, List<SObject> childRecords) {
        Id parentRecordId = Id.valueOf(parentRecId);
        String itemCode = response.Itemcode;
        Integer freeStock = String.isNotBlank(response.FreeStock) ? Integer.valueOf(response.FreeStock) : 0;
        Integer onHandStock = String.isNotBlank(response.OnHandStock) ? Integer.valueOf(response.OnHandStock) : 0;
        Integer transactionAgingDays = String.isNotBlank(response.TransactionAgingDays) ? Integer.valueOf(response.TransactionAgingDays) : 0;
        Product2 productRecord = [Select Id, Name FROM Product2 WHERE Item__c = :itemCode LIMIT 1];
        List<SObject> childSObjectsToUpdate = new List<SObject>();

        // Update the child sobjects to indicate the amount of free stock available of there is any.
        for(SObject childRecord : childRecords) {
            if((String) childRecord.get('Product2Id') == String.valueOf(productRecord.Id)) {
                Id sObjectRecordId = Id.valueOf((String) childRecord.get('Id'));
                SObject sObj = sObjectRecordId.getSobjectType().newSobject(sObjectRecordId);
                sObj.put('Free_Stock__c', freeStock);
                sObj.put('Stock_In_Hand__c', onHandStock);
                sObj.put('Transaction_Aging_Days__c', transactionAgingDays);
                childSObjectsToUpdate.add(sObj);
                break;
            }
        }

        if(childSObjectsToUpdate.size() > 0) {
            update childSObjectsToUpdate;
        }

        // Update parent object indicating whether free stock is available or not.
        updateParentObjectOnStockDetails(parentRecId);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to update the parent / header object on the stock information and last stock check time.
    Inputs:        String parentRecId
    Output Type:   
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private void updateParentObjectOnStockDetails(String parentRecId) {
        Id parentRecordId = Id.valueOf(parentRecId);
        String sObjName = parentRecordId.getSObjectType().getDescribe().getName();
        SObject parentSObjectRecord = parentRecordId.getSObjectType().newSObject(parentRecordId);
        Boolean isStockAvailable = true;
        List<SObject> childRecords = getChildLineItemsOfObject(parentRecordId, sObjName);

        if(childRecords.size() > 0) {
            for(SObject childRecord : childRecords) {
                Integer freeStockValue = Integer.valueOf(childRecord.get('Free_Stock__c'));
                if(freeStockValue == null || Integer.valueOf(freeStockValue) < 1) {
                    isStockAvailable = false;
                    break;
                }
            }
        }

        parentSObjectRecord.put('Is_Stock_Available__c', isStockAvailable);
        parentSObjectRecord.put('Last_Stock_Check__c', System.Now());
        update parentSObjectRecord;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to create a response datastrucure to be passed to the LWC component.
    Inputs:        BDEResponseMapper response, Integer statusCode
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public String createBDEResponseStructure(BDEResponseMapper response, Integer statusCode) {
        Integer listCount = statusCode == 200 ? 1 : 0;
        String status = statusCode == 200 ? 'Success' : 'Failed';
        List<BDEResponseMapper> responseList = new List<BDEResponseMapper>();
        responseList.add(response);

        BDEJSONResponse jsonResponseObject = new BDEJSONResponse();
        jsonResponseObject.status = status;
        jsonResponseObject.statusCode = statusCode;
        jsonResponseObject.listCount = listCount;
        jsonResponseObject.data = responseList;
        return JSON.serialize(jsonResponseObject);
    }

    public class BDEJSONResponse {
        public String status;
        public Integer statusCode;
        public Integer listCount;
        public List<BDEResponseMapper> data;
    }
    
/*------------------------------------------------------------------------
    Author:        Anupam Mishra
    Company:       GITL
    Description:   Method to check MHE Rental Record Type.
    Inputs:        String recordId , String objectName
   ----------------------------------------------------------------------------*/
      public static boolean isGodrejRenTRUST(String recordId , String objectName){
         boolean isRenTRUST = false;
         switch on objectName.toUpperCase() {
            when 'OPPORTUNITY' {
                List<Opportunity>RentalRcrdType=[SELECT Id,Name,RecordType.DeveloperName FROM Opportunity WHERE RecordType.DeveloperName=:GlobalConstants.QUOTE_RECORDTYPE_MHE_RENTAL AND Id =:recordId limit 1];       
                if(RentalRcrdType.size()>0){      
                    isRenTRUST = true; 
                }                
                system.debug('Return'+isRenTRUST);
            }
            when 'QUOTE' {
                List<Quote>RentalRcrdType=[SELECT Id,Name,RecordType.DeveloperName FROM Quote WHERE RecordType.DeveloperName=:GlobalConstants.QUOTE_RECORDTYPE_MHE_RENTAL AND Id =:recordId limit 1];       
                if(RentalRcrdType.size()>0){
                    isRenTRUST = true;                                      
                }
                system.debug('Return'+isRenTRUST);
            }
        }
        system.debug('Return'+isRenTRUST);
        return isRenTRUST;        
    }
 }