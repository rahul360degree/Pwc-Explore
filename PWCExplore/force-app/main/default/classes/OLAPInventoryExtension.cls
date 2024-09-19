/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Utility class to perform inventory integration and other operations for OLAP approach
Inputs:        NA
Test Class:    OLAPInventoryExtensionTest
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public class OLAPInventoryExtension {
    private static final String COMPANY_FIELD_API_NAME = 'CompanyCodes';
    private static final String WAREHOUSE_FIELD_API_NAME = 'WarehouseCodes';
    private static User currentUser = null;
    private static List<Warehouse__c> warehouseRecords = null;
    private static final String STOCK_CATEGORY_FIELD_API_NAME = 'Stock_Category__c';
    private static final String USER_WAREHOUSE_CODES_ARE_EMPTY = System.Label.USER_WAREHOUSE_CODES_ARE_EMPTY;

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to field values based on the userId for the tab based component.
    Inputs:        String userId
    HttpResponse   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public String getFilterFieldsInfo(String userID){
        Map<String, FieldDescriptor> fieldDescriptorMap = new Map<String, FieldDescriptor>();
        InventoryCheckController checkControllerInstance = new InventoryCheckController();

        List<String> fieldList = new List<String>{
            'Product2--Product_Category__c', 'Product2--Family', 'Product2--Business_Code__c', 
            'Product2--Product_Type__c', 'Product2--Statistical_Group__c',
            'Warehouse__c--Stock_Category__c', 'Warehouse__c--CompanyCodes', 'Warehouse__c--WarehouseCodes'
        };

        currentUser = checkControllerInstance.getCurrentUserRecord(userID);
        if(String.isBlank(currentUser.Primary_Warehouses__c) && String.isBlank(currentUser.Secondary_Warehouses__c)) {
            throw new InventoryCheckerException(USER_WAREHOUSE_CODES_ARE_EMPTY);
        }
        for(String fieldDesc : fieldList) {
            String objectName = (fieldDesc.split('--'))[0];
            String fieldAPIName = (fieldDesc.split('--'))[1];
            FieldDescriptor fieldDescriptorObj = new FieldDescriptor();
            String parentFieldAPIName = '';
            Map<String, String> fieldValueVSfieldLabel = new Map<String, String>();
            String fieldLabel = null;

            if(fieldAPIName != COMPANY_FIELD_API_NAME && fieldAPIName != WAREHOUSE_FIELD_API_NAME) {
                fieldLabel = ((Schema.getGlobalDescribe().get(objectName)).getDescribe().fields.getMap()).get(fieldAPIName).getDescribe().getLabel();
                parentFieldAPIName = fieldAPIName == STOCK_CATEGORY_FIELD_API_NAME ? COMPANY_FIELD_API_NAME : '';
                fieldValueVSfieldLabel = getPicklistFieldValues(objectName, fieldAPIName);
            } else {
                fieldLabel = fieldAPIName == COMPANY_FIELD_API_NAME ? 'Company Codes' : fieldAPIName == WAREHOUSE_FIELD_API_NAME ? 'Warehouse Codes' : fieldAPIName;
                parentFieldAPIName = fieldAPIName == WAREHOUSE_FIELD_API_NAME ? STOCK_CATEGORY_FIELD_API_NAME : '';
                fieldValueVSfieldLabel = getCustomFieldValues(fieldAPIName);
            }
            fieldDescriptorMap.put(fieldAPIName, checkControllerInstance.createFieldDescriptorObject(fieldLabel, fieldAPIName, fieldValueVSfieldLabel, parentFieldAPIName));
        }
        updateFieldDependenciesAndValues(fieldDescriptorMap);
        updateFieldValues_BasedOnFirstBUCharacter(fieldDescriptorMap, 'Statistical_Group__c', 0, 1);
        updateFieldValues_BasedOnFirstBUCharacter(fieldDescriptorMap, 'Product_Type__c', 0, 1);
        updateFieldValues_BasedOnFirstBUCharacter(fieldDescriptorMap, 'Business_Code__c', 0, 1);
        return JSON.serialize(fieldDescriptorMap.values());
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the picklist field values and their labels dynamically.
    Inputs:        String objectName, String fieldName
    Output Type:   Map<String, String>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, String> getPicklistFieldValues(String objectName, String fieldName) {
        Map<String, String> fieldValueVSfieldLabel = new Map<String, String>();

        Schema.SObjectType sObj = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult sObjectResult = sObj.getDescribe();
        Map<String,Schema.SObjectField> fields = sObjectResult.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistEntryList = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry picklistEntry : picklistEntryList) {
            fieldValueVSfieldLabel.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }
        return fieldValueVSfieldLabel;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to set the field values for custom fields like CompanyCodes and WarehouseCodes
    Inputs:        String fieldApiName
    Output Type:   Map<String, String>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, String> getCustomFieldValues(String fieldApiName) {
        getWarehouseRecords();
        System.debug('Field API name: ' + fieldApiName);

        switch on fieldApiName.toUpperCase() {
            when 'COMPANYCODES' {
                return calculateCompanyFieldValues();
            }
            when 'WAREHOUSECODES' {
                return calculateWarehouseFieldValues();
            }
            when else {
                System.debug('No matching field name found. Please create the api name datastructure and it\'s relevant methods.');
                return (new Map<String, String>());
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the warehouse records
    Inputs:        
    Output Type:   
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private void getWarehouseRecords() {
        if(warehouseRecords == null || !(warehouseRecords.size() > 0)){
            String warehouseCodeString = ('' + currentUser.Primary_Warehouses__c + ',' + currentUser.Secondary_Warehouses__c).deleteWhitespace();
            List<String> warehouseCodes = warehouseCodeString.split(',');
            System.debug('Warehouse Codes: ' + warehouseCodes.size());

            warehouseRecords = [Select Id, Name, Stock_Category__c, Logistic_Company__c, Warehouse__c FROM Warehouse__c 
                WHERE Warehouse__c IN :warehouseCodes];
            System.debug('Warehouse Records: ' + warehouseRecords.size());
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to calculate the values to be shown for the CompanyCodes field.
    Inputs:        
    Output Type:   Map<String, String>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, String> calculateCompanyFieldValues() {
        Map<String, String> fieldValueVSfieldLabel = new Map<String, String>();
        for(Warehouse__c warehouseRecord : warehouseRecords) {
            fieldValueVSfieldLabel.put(warehouseRecord.Logistic_Company__c, warehouseRecord.Logistic_Company__c);
        }
        return fieldValueVSfieldLabel;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to calculate the values to be shown for the WarehouseCodes field.
    Inputs:        
    Output Type:   Map<String, String>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, String> calculateWarehouseFieldValues() {
        Map<String, String> fieldValueVSfieldLabel = new Map<String, String>();
        for(Warehouse__c warehouseRecord : warehouseRecords) {
            fieldValueVSfieldLabel.put(warehouseRecord.Warehouse__c, warehouseRecord.Name);
        }
        return fieldValueVSfieldLabel;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get and create a data structure for field dependencies.
    Inputs:        Map<String, FieldDescriptor> fieldDescriptorMap
    Output Type:   
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private void updateFieldDependenciesAndValues(Map<String, FieldDescriptor> fieldDescriptorMap) {
        Map<String, List<String>> companyCodes_VS_stockCategoryFieldDependency = identify_CompanyAndStockCategory_Dependency();
        Map<String, List<String>> companyCodes_VS_warehouseCodesFieldDependency = identify_CompanyAndWarehouse_Dependency();
        Map<String, List<String>> stockCategory_VS_warehouseCodesFieldDependency = identify_StockCategoryAndWarehouse_Dependency();
        for(String key : fieldDescriptorMap.keySet()) {
            FieldDescriptor fieldDescriptorObj = fieldDescriptorMap.get(key);
            switch on key.toUpperCase() {
                when 'COMPANYCODES' {
                    // Add dependent stock category values.
                    if(companyCodes_VS_stockCategoryFieldDependency.size() > 0) {
                        DependentFieldInformation stockCategoryFieldInfo = new DependentFieldInformation();
                        stockCategoryFieldInfo.dependentField_APIName = STOCK_CATEGORY_FIELD_API_NAME;
                        stockCategoryFieldInfo.controllingFieldValue_VS_dependentValues = companyCodes_VS_stockCategoryFieldDependency;
                        (fieldDescriptorObj.dependentFields).add(stockCategoryFieldInfo);
                    }

                    // Add dependent warehouse values.
                    if(companyCodes_VS_warehouseCodesFieldDependency.size() > 0) {
                        DependentFieldInformation warehouseFieldInfo = new DependentFieldInformation();
                        warehouseFieldInfo.dependentField_APIName = WAREHOUSE_FIELD_API_NAME;
                        warehouseFieldInfo.controllingFieldValue_VS_dependentValues = companyCodes_VS_warehouseCodesFieldDependency;
                        (fieldDescriptorObj.dependentFields).add(warehouseFieldInfo);
                    }
                }
                when 'STOCK_CATEGORY__C' {
                    // Add dependent warehouse values.
                    if(stockCategory_VS_warehouseCodesFieldDependency.size() > 0) {
                        DependentFieldInformation warehouseFieldInfo = new DependentFieldInformation();
                        warehouseFieldInfo.dependentField_APIName = WAREHOUSE_FIELD_API_NAME;
                        warehouseFieldInfo.controllingFieldValue_VS_dependentValues = stockCategory_VS_warehouseCodesFieldDependency;
                        (fieldDescriptorObj.dependentFields).add(warehouseFieldInfo);
                    }
                }
                when else {
                }
            }

            fieldDescriptorMap.put(key, fieldDescriptorObj);
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to update values inside the data structure passed based on the user records Business Unit value.
    Inputs:        Map<String, FieldDescriptor> fieldDescriptorMap, String apiName, Integer startIndex, Integer endIndex
    Output Type:   
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private void updateFieldValues_BasedOnFirstBUCharacter(Map<String, FieldDescriptor> fieldDescriptorMap, String apiName, Integer startIndex, Integer endIndex ) {
        if(currentUser.Business_Unit__c != null) {
            FieldDescriptor fieldDescriptorObj = fieldDescriptorMap.get(apiName);
            Map<String, String> updatedFieldValueVSfieldLabel = new Map<String, String>();

            for(String fieldValue : fieldDescriptorObj.fieldValueVSfieldLabel.keySet()) {
                if(currentUser.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT){
                    if(fieldValue.subString(startIndex, endIndex) == currentUser.Business_Unit__c || fieldValue.subString(startIndex, endIndex) == GlobalConstants.Character_X || fieldValue.subString(startIndex, endIndex) == GlobalConstants.Character_Y ) {
                    updatedFieldValueVSfieldLabel.put(fieldValue, fieldDescriptorObj.fieldValueVSfieldLabel.get(fieldValue));
                    }
                }
                else{
                     if(fieldValue.subString(startIndex, endIndex) == currentUser.Business_Unit__c) {
                     updatedFieldValueVSfieldLabel.put(fieldValue, fieldDescriptorObj.fieldValueVSfieldLabel.get(fieldValue));
                      }
               }
                
           }
            
            fieldDescriptorObj.fieldValueVSfieldLabel = updatedFieldValueVSfieldLabel;
            fieldDescriptorMap.put(apiName, fieldDescriptorObj);
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to identify field dependent values between company and stock category fields.
    Inputs:        
    Output Type:   Map<String, List<String>>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, List<String>> identify_CompanyAndStockCategory_Dependency() {
        Map<String, List<String>> companyCodes_VS_stockCategoryFieldDependency = new Map<String, List<String>>();
        for(Warehouse__c warehouseRecord : warehouseRecords) {
            List<String> stockCategoryValues = new List<String>();
            
            if(!companyCodes_VS_stockCategoryFieldDependency.containsKey(warehouseRecord.Logistic_Company__c)) {
                stockCategoryValues.add(warehouseRecord.Stock_Category__c);
            } else {
                stockCategoryValues = companyCodes_VS_stockCategoryFieldDependency.get(warehouseRecord.Logistic_Company__c);
                stockCategoryValues.add(warehouseRecord.Stock_Category__c);
            }
            companyCodes_VS_stockCategoryFieldDependency.put(warehouseRecord.Logistic_Company__c, stockCategoryValues);
        }

        return companyCodes_VS_stockCategoryFieldDependency;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to identify field dependent values between company and warehouse fields.
    Inputs:        
    Output Type:   Map<String, List<String>>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, List<String>> identify_CompanyAndWarehouse_Dependency() {
        Map<String, List<String>> companyCodes_VS_warehouseFieldDependency = new Map<String, List<String>>();
        for(Warehouse__c warehouseRecord : warehouseRecords) {
            List<String> warehouseValues = new List<String>();
            
            if(!companyCodes_VS_warehouseFieldDependency.containsKey(warehouseRecord.Logistic_Company__c)) {
                warehouseValues.add(warehouseRecord.Warehouse__c);
            } else {
                warehouseValues = companyCodes_VS_warehouseFieldDependency.get(warehouseRecord.Logistic_Company__c);
                warehouseValues.add(warehouseRecord.Warehouse__c);
            }
            companyCodes_VS_warehouseFieldDependency.put(warehouseRecord.Logistic_Company__c, warehouseValues);
        }

        return companyCodes_VS_warehouseFieldDependency;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to identify field dependent values between stock category and warehouse fields.
    Inputs:        
    Output Type:   Map<String, List<String>>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private Map<String, List<String>> identify_StockCategoryAndWarehouse_Dependency() {
        Map<String, List<String>> stockCategory_VS_warehouseCodesFieldDependency = new Map<String, List<String>>();
        for(Warehouse__c warehouseRecord : warehouseRecords) {
            List<String> warehouseValues = new List<String>();
            
            String key = warehouseRecord.Stock_Category__c;
            if(!stockCategory_VS_warehouseCodesFieldDependency.containsKey(key)) {
                warehouseValues.add(warehouseRecord.Warehouse__c);
            } else {
                warehouseValues = stockCategory_VS_warehouseCodesFieldDependency.get(key);
                warehouseValues.add(warehouseRecord.Warehouse__c);
            }
            stockCategory_VS_warehouseCodesFieldDependency.put(key, warehouseValues);
        }

        return stockCategory_VS_warehouseCodesFieldDependency;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get product records based on the filters passed.
    Inputs:        String filters
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public String getProducts(String filters) {
        System.debug('Search Filters: ' + filters);
        InventoryCheckController checkControllerInstance = new InventoryCheckController();

        List<String> defaultFields = new List<String>{'Name', 'Item__c'};
        Map<String, String> fieldAPINameVSLabel = checkControllerInstance.getFieldsToFetchInfo(defaultFields);
        Map<String, Object> filterFieldAPINameVSfiterValue = (Map<String, Object>) JSON.deserializeuntyped(filters);
        List<Product2> productsToDisplay = getProductsBasedOnFilters(filterFieldAPINameVSfiterValue, new List<String>(fieldAPINameVSLabel.keySet()));
        List<String> dataList = new List<String>();

        for(Product2 productRecord : productsToDisplay) {
            String data = JSON.serialize(productRecord);
            dataList.add(data);
        }

        FieldDescriptor fieldDescriptorObj = checkControllerInstance.createFieldDescriptorObject('Search Table', 'search_table', fieldAPINameVSLabel, '');
        fieldDescriptorObj.fieldType = 'table';
        fieldDescriptorObj.config.put('data', dataList);

        return JSON.serialize(fieldDescriptorObj);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Helper method for getProducts method.
    Inputs:        Map<String, Object> filterFieldNameVSValue, List<String> fieldsToGet
    Output Type:   List<Product2>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private List<Product2> getProductsBasedOnFilters(Map<String, Object> filterFieldNameVSValue, List<String> fieldsToGet) {
        List<Product2> productList = new List<Product2>();
        SObject productSObject = Schema.getGlobalDescribe().get('Product2').newSObject();

        String query = 'Select Id';
        for(String field : fieldsToGet) {
            query += ', ' + field;
        }
        query += ' FROM Product2';
            
        if(filterFieldNameVSValue.size() > 0) {
            Boolean firstElement = true;
            for(String fieldAPIName : filterFieldNameVSValue.keySet()) {
                if(productSObject.getSobjectType().getDescribe().fields.getMap().containsKey(fieldAPIName)) {
                    List<String> fieldValue =  String.valueOf(filterFieldNameVSValue.get(fieldAPIName)).split(',');
                    if(firstElement) {
                        query += ' WHERE'; // Add the WHERE clause only once at the start of first element.
                    } else {
                        query += ' AND'; // Add the AND clause everytime if it is not the first element.
                    }
                    query += ' ' + fieldAPIName + ' IN :fieldValue';
                    firstElement = false;
                }
            }
        }
        query += ' LIMIT 24000';
        System.debug(query);
        productList = Database.query(query);
        System.debug('ProductList size ::' + productList.size());
        return productList;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to make a callout to fetch the stock related information for products selected by the user.
    Inputs:        String productsToGet
    Output Type:   HttpResponse
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public HttpResponse getStockProducts(String productsToGet) {
        try {
            System.debug('Stock Filters: ' + productsToGet);
            InventoryVisiblityRequstor requestorObject = new InventoryVisiblityRequstor();
            HttpResponse response = requestorObject.generateRequest(productsToGet);

            if(response.getStatusCode() != 200) {
                throw new InventoryCheckerException(response.getBody());
            } else {
                return response;
            }
        } catch(InventoryCheckerException exceptionObj) {
            ResponseError responseError = (ResponseError) JSON.deserialize(exceptionObj.getMessage(), ResponseError.class);
            System.debug('Response Error msg: ' + responseError.error.message);
            System.debug('Error has occurred :: OLAPInventoryExtension-getStockProducts');
            System.debug(exceptionObj.getMessage());
            throw new InventoryCheckerException(responseError.error.source + responseError.error.message);
        }
    }

    public class ResponseError {
        public Error error;
    }

    public class Error {
        public String message;
        public String source;
    }
}