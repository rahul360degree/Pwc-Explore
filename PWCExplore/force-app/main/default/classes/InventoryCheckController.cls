/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Controller class for inventory check LWC components.
Inputs:        NA
Test Class:    BDEInventoryExtensionTest, OLAPInventoryExtensionTest

History

----------------------------------------------------------------------------*/
public without sharing class InventoryCheckController {
    private static InventoryCheckController INVENTORYCHECKCONTROLLER_INSTANCE = new InventoryCheckController();
    private static final String API_TRANSACTION_SUCCESS_STATUS = System.Label.API_TRANSACTION_SUCCESS_STATUS;
    private static final String API_TRANSACTION_ERROR_STATUS = System.Label.API_TRANSACTION_ERROR_STATUS;
    private static final String PRODUCT_INVENTORY_FIELDSET = System.Label.PRODUCT_INVENTORY_FIELDSET;
    
    private static List<Warehouse__c> warehouseRecords = null;

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get user record based on the user id provided as input
    Inputs:        String userId
    Output Type:   User
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public User getCurrentUserRecord(String userId) {
        User currentUser = [Select Id, Primary_Warehouses__c, Secondary_Warehouses__c, Business_Unit__c FROM User WHERE Id = :userID LIMIT 1];
        return currentUser;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get create a field descriptor wrapper object.
    Inputs:        String label, String apiName, Map<String, String> fieldValueVSfieldLabel, String parentFieldAPIName
    Output Type:   FieldDescriptor
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public FieldDescriptor createFieldDescriptorObject(String label, String apiName, Map<String, String> fieldValueVSfieldLabel, 
        String parentFieldAPIName) {
        FieldDescriptor fieldDescriptorObj = new FieldDescriptor();
        fieldDescriptorObj.fieldLabel = label;
        fieldDescriptorObj.fieldAPIName = apiName;
        fieldDescriptorObj.fieldType = 'picklist';
        fieldDescriptorObj.fieldValueVSfieldLabel = fieldValueVSfieldLabel;
        fieldDescriptorObj.config = new Map<String, List<String>>();
        fieldDescriptorObj.dependentFields = new List<DependentFieldInformation>();
        fieldDescriptorObj.isError = false;
        fieldDescriptorObj.errorMessage = '';
        fieldDescriptorObj.parentFieldAPIName = parentFieldAPIName;

        return fieldDescriptorObj;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to dynamically get the field api names and field labels which are to be retrieved based on the field set.
    Inputs:        List<String> defaultFieldNames
    Output Type:   Map<String, String>
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public Map<String, String> getFieldsToFetchInfo(List<String> defaultFieldNames) {
        Map<String, String> fieldAPINameVSfieldLabel = new Map<String, String>();
        List<Schema.FieldSetMember> fieldSetMemberList = Utility.getFieldSetInfo(PRODUCT_INVENTORY_FIELDSET, 'Product2');
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList) {
            fieldAPINameVSfieldLabel.put(fieldSetMemberObj.getFieldPath(), fieldSetMemberObj.getLabel());
        }
        for(String fieldAPIName : defaultFieldNames) {
            String label = ((Schema.getGlobalDescribe().get('Product2')).getDescribe().fields.getMap()).get(fieldAPIName).getDescribe().getLabel();
            fieldAPINameVSfieldLabel.put(fieldAPIName, label);
        }
        return fieldAPINameVSfieldLabel;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the fields related info for their use in tab based LWC component.
    Inputs:        String userID
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getFilterFieldsInfo(String userID){
        return (new OLAPInventoryExtension()).getFilterFieldsInfo(userID);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the child product records (OppProduct/QLI/OrderItem) based on the parent record id and user id.
    Inputs:        String recId, String userId
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getProductsBasedOnDefaultValues(String recId, String userId) {
        return (new BDEInventoryExtension()).getProductsBasedOnDefaultValues(recId, userId);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get product records based on the filters applied in the tab based LWC component.
    Inputs:        String filters
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getProducts(String filters) {
        return (new OLAPInventoryExtension()).getProducts(filters);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get stock related information from external service based on the product info passed from tab
                   based LWC component.
    Inputs:        String productsToGet
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getStockProducts(String productsToGet) {
        API_Transactions__c apiTransactionObj = INVENTORYCHECKCONTROLLER_INSTANCE.createAPITransactionObject();
        HttpResponse response;
        try {
            response = (new OLAPInventoryExtension()).getStockProducts(productsToGet);
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_SUCCESS_STATUS;
            insert apiTransactionObj;
            return response.getBody();
        } catch(InventoryCheckerException ex) {
            System.debug('Error has occurred :: InventoryCheckController-getStockProducts');
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_ERROR_STATUS;
            apiTransactionObj.Error_Message__c = ex.getMessage();
            insert apiTransactionObj;
            throw new InventoryCheckerException(ex.getMessage());
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get stock related information from external service based on the product info passed from object
                   based LWC component.
    Inputs:        String productsToGet, String parentRecordId, String parentObjectName
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static String getStockProductsForBDE(String productsToGet, String parentRecordId, String parentObjectName) {
        API_Transactions__c apiTransactionObj = INVENTORYCHECKCONTROLLER_INSTANCE.createAPITransactionObject();
        try {
            String response =  (new BDEInventoryExtension()).getStockProductsForBDE(productsToGet, parentRecordId, parentObjectName);
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_SUCCESS_STATUS;
            insert apiTransactionObj;
            return response;
        } catch(InventoryCheckerException ex) {
            apiTransactionObj.End_Date__c = System.Now();
            apiTransactionObj.Status__c = API_TRANSACTION_ERROR_STATUS;
            apiTransactionObj.Error_Message__c = ex.getMessage();
            insert apiTransactionObj;
            throw new InventoryCheckerException(ex.getMessage());
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to create an instance of API_Transactions__c object with pre-populated start date value.
    Inputs:        
    Output Type:   API_Transactions__c
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    private API_Transactions__c createAPITransactionObject() {
        API_Transactions__c apiTransactionObj = new API_Transactions__c();
        apiTransactionObj.Start_Date__c = System.now();
        return apiTransactionObj;
    }
}