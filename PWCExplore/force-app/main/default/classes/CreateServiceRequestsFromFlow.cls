/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Helper class to create service requests from multiple flows
 * Inputs:        NA
 * Test Class:    
 * ---------------------------------------------------------------------------
 * History
 * 17-09-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
public class CreateServiceRequestsFromFlow {
    static Id serviceRequestRecordTypeId;
    
    /*------------------------------------------------------------------------
     * Author:        Shailja Mishra
     * Company:       Salesforce
     * Description:   Helper method called from all flows. Based on the inputs,
     *                this method calls other helper methods
     * Inputs:        ServiceRequestWrapper
     * Test Class:    
     * ---------------------------------------------------------------------------
     * History
     * 17-09-2020      Shailja Mishra     Initial Release
     * ----------------------------------------------------------------------------*/
    @InvocableMethod
    public static List<String> createCases(List<ServiceRequestWrapper> userInputs) {
        ServiceRequestWrapper wrapper;
        String recordId;
        serviceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        for (ServiceRequestWrapper each : userInputs) {
            wrapper = each;
            break;
        }
        if (wrapper.isFromOrderSaleCapture) {
            captureOrderSales(wrapper);
        }
        if (wrapper.isClone) {
            cloneCases(wrapper);
        }
        if (wrapper.isQuickCreate) {
            createCaseRecords(wrapper);
        }
        if (wrapper.isTertiaryOrderCreation) {
            recordId = createTertiaryOrder(wrapper);
        }
        return new List<String>{recordId};
    }
    
    /*------------------------------------------------------------------------
     * Author:        Shailja Mishra
     * Company:       Salesforce
     * Description:   Helper method used for tertiary order "submit sales" action
     *                The flow sends order ids, list of quantity and list of ";"
     *                separated asset serial numbers. These inputs are parsed
     *                and multiple cases are created
     * Inputs:        ServiceRequestWrapper
     * Test Class:    
     * ---------------------------------------------------------------------------
     * History
     * 17-09-2020      Shailja Mishra     Initial Release
     * ----------------------------------------------------------------------------*/
    public static void captureOrderSales(ServiceRequestWrapper wrapper) {
        if (wrapper.recordIds == null || wrapper.recordIds.isEmpty()) {
            return;
        }
        List<Case> newCases = new List<Case>();
        for (Integer i = 0; i < wrapper.recordIds.size(); i++) {
            List<String> serialNumberList = new List<String>();
            if (wrapper.assetSerialNumbers != null && wrapper.assetSerialNumbers.size() > i) {
                serialNumberList = String.isNotBlank(wrapper.assetSerialNumbers[i]) ? wrapper.assetSerialNumbers[i].split(';') : new List<String>();
            }
            if (wrapper.quantities.size() > i) {
                for (Integer j = 0; j < wrapper.quantities[i]; j++) {
                    Case eachCase = new Case(RecordTypeId = serviceRequestRecordTypeId, Order_Product__c = wrapper.recordIds[i]);
                    eachCase.Asset_Serial_Number__c = serialNumberList.size() > j ? serialNumberList[j] : null;
                    newCases.add(eachCase);
                }
            }
        }
        try{
            insert newCases;
        }catch(DMLException ex){
            throw createCustomException(ex.getDmlMessage(0));
        }
        if (String.isBlank(wrapper.recordId)) {
            return;
        }
        Order orderRec = new Order(Id = wrapper.recordId, Integration_Status__c = 'Captured', Status = 'Captured');
        try{
            update orderRec;
        }catch(DMLException ex){
            throw createCustomException(ex.getDmlMessage(0));
        }
        
    }
    
    /*----------------------------------------------------------------------------
     * Author:        Shailja Mishra
     * Company:       Salesforce
     * Description:   Helper method used for Case record's "Create Multiple Cases"
     *                action. The flow sends ";" separated serial numbers and case ID.
     *                This method clones the case, updates the serial number and
     *                inserts cases
     * Inputs:        ServiceRequestWrapper
     * Test Class:    
     * ---------------------------------------------------------------------------
     * History
     * 17-09-2020      Shailja Mishra     Initial Release
     * ----------------------------------------------------------------------------*/
    public static void cloneCases(ServiceRequestWrapper wrapper) {
        if (String.isBlank(wrapper.recordId)) {
            return;
        }
        Case caseRecord;
        for (Case each: Database.query(QueryBuilder.build('Case', 'Id = \'' + wrapper.recordId + '\'', false))) {
            caseRecord = each;
        }
        List<Case> newCases = new List<Case>();
        List<String> serialNumbers = new List<String>();
        if (String.isNotBlank(wrapper.serialNumbers)) {
            serialNumbers = wrapper.serialNumbers.split(';');
        }
        for (String each : serialNumbers) {
            if (String.isNotBlank(each)) {
                Case clonedCase = caseRecord.clone(false, false, false, false);
                clonedCase.Asset_Serial_Number__c = each;
                newCases.add(clonedCase);
            }
        }
        try{
            insert newCases;
        }catch(DMLException ex){
            throw createCustomException(ex.getDmlMessage(0));
        }
    }
    
    /*----------------------------------------------------------------------------
     * Author:        Shailja Mishra
     * Company:       Salesforce
     * Description:   Helper method used for Quick Create menu in community. The flow
     *                sends list of ";" separated serial numbers, product IDs and list
     *                of quantity values. This method creates multiple cases based on
     *                the inputs
     * Inputs:        ServiceRequestWrapper
     * Test Class:    
     * ---------------------------------------------------------------------------
     * History
     * 17-09-2020      Shailja Mishra     Initial Release
     * ----------------------------------------------------------------------------*/
    public static void createCaseRecords(ServiceRequestWrapper wrapper) {
        if (wrapper.recordIds == null || wrapper.recordIds.isEmpty()) {
            return;
        }
        List<Case> newCases = new List<Case>();
        Id addressByBPRecordTypeId = Schema.SObjectType.Address_By_BP__c.getRecordTypeInfosByDeveloperName().get('B2C_Additional_Address').getRecordTypeId();
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        
        if (wrapper.personAccount != null) {
            wrapper.personAccount.Business_Unit__c = 'H';
            wrapper.personAccount.RecordTypeId = personAccountRecordTypeId;
            
            insert wrapper.personAccount;
            wrapper.caseRecord.AccountId = wrapper.personAccount.Id;
            
            Account personAccountRecord = [SELECT Id, Name, PersonContactId FROM Account WHERE Id = :wrapper.personAccount.Id];
            wrapper.addressRecord.Address_Type__c = 'B2C';
            wrapper.addressRecord.Name__c = personAccountRecord.Name;
            insert wrapper.addressRecord;
            wrapper.caseRecord.ContactId = personAccountRecord.PersonContactId;
            wrapper.caseRecord.Address__c = wrapper.addressRecord.Id;
            
            Address_By_BP__c addressByBPRecord = new Address_By_BP__c(Address_Code__c = wrapper.addressRecord.Id, RecordTypeId = addressByBPRecordTypeId,
                Account__c = personAccountRecord.Id, Telephone__c = wrapper.addressRecord.Telephone__c, Name__c = personAccountRecord.Name,
                Email__c = wrapper.addressRecord.Email__c);
            insert addressByBPRecord;
            wrapper.caseRecord.Address_by_BP__c = addressByBPRecord.Id;
        }
        
        for (Integer i = 0; i < wrapper.recordIds.size(); i++) {
            List<String> serialNumberList;
            if (wrapper.assetSerialNumbers != null && wrapper.assetSerialNumbers.size() > i) {
                serialNumberList = String.isNotBlank(wrapper.assetSerialNumbers[i]) ? wrapper.assetSerialNumbers[i].split(';') : new List<String>();
            }
            if (wrapper.quantities.size() > i) {
                for (Integer j = 0; j < wrapper.quantities[i]; j++) {
                    Case eachCase = new Case(Status = String.valueOf(wrapper.caseRecord.Status),
                        Service_Request_Type__c = String.valueOf(wrapper.caseRecord.Service_Request_Type__c),
                        Service_Required_For__c = String.valueOf(wrapper.caseRecord.Service_Required_For__c),
                        ContactId = wrapper.caseRecord.ContactId,
                        Address_By_BP__c = wrapper.caseRecord.Address_By_BP__c,
                        RecordTypeId = serviceRequestRecordTypeId);
                    eachCase.Asset_Serial_Number__c = serialNumberList.size() > j ? serialNumberList[j] : null;
                    eachCase.ProductId = String.isNotBlank(wrapper.recordIds[i]) ? wrapper.recordIds[i] : null;
                    if (String.isBlank(eachCase.ProductId)) {
                        eachCase.Product_Category__c = wrapper.productCategories[i];
                    }
                    newCases.add(eachCase);
                }
            }
        }
        
        try{
            insert newCases;
        } catch(DMLException ex){
            throw createCustomException(ex.getDmlMessage(0));
        }
    }

    /*
     * Description: Throw custom exception to flow
     */
    public class CustomException extends Exception {}
    static CustomException createCustomException(String message){
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }
    
    public static String createTertiaryOrder(ServiceRequestWrapper wrapper) {
        Id addressByBPRecordTypeId = Schema.SObjectType.Address_By_BP__c.getRecordTypeInfosByDeveloperName().get('B2C_Additional_Address').getRecordTypeId();
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Tertiary').getRecordTypeId();
        
        try {
            Boolean orderCreationOnly = false;
            if (String.isNotBlank(wrapper.recordId)) {
                orderCreationOnly = true;
            }
            if (orderCreationOnly) {
                Account personAccountRecord = [SELECT Id, PersonContactId FROM Account WHERE Id = :wrapper.recordId];
                for (Address_By_BP__c each : [SELECT Id FROM Address_By_BP__c WHERE Account__c = :personAccountRecord.Id ORDER BY isPrimary__c DESC LIMIT 1]){
                    wrapper.orderRecord.Sold_To_Address__c = each.Id;
                    wrapper.orderRecord.Ship_To_Address__c = each.Id;
                }
                wrapper.orderRecord.Sold_To_Contact__c = personAccountRecord.PersonContactId;
            } else {
                wrapper.personAccount.RecordTypeId = personAccountRecordTypeId;
                wrapper.personAccount.Business_Unit__c = 'H';
                wrapper.personAccount.Sub_Division__c = 'B2C';
                insert wrapper.personAccount;
                
                Account personAccountRecord = [SELECT Id, Name, PersonContactId FROM Account WHERE Id = :wrapper.personAccount.Id];
                
                if (wrapper.orderRecord.Is_Create_Demo_Installation_Request__c) {
                    wrapper.addressRecord.Name__c = personAccountRecord.Name;
                    wrapper.addressRecord.Address_Type__c = 'B2C';
                    insert wrapper.addressRecord;
                
                    Address_By_BP__c newAddressByBPRecord = new Address_By_BP__c(Account__c = personAccountRecord.Id, Address_Code__c = wrapper.addressRecord.Id,
                        Name__c = personAccountRecord.Name, Email__c = wrapper.addressRecord.Email__c, Telephone__c = wrapper.addressRecord.Telephone__c,
                        RecordTypeId = addressByBPRecordTypeId);
                    insert newAddressByBPRecord;
                    wrapper.orderRecord.Sold_To_Address__c = newAddressByBPRecord.Id;
                    wrapper.orderRecord.Ship_To_Address__c = newAddressByBPRecord.Id;
                }
                wrapper.orderRecord.Sold_To_Contact__c = personAccountRecord.PersonContactId;
                wrapper.orderRecord.AccountId = personAccountRecord.Id;
                wrapper.orderRecord.Sold_to_Business_Partner__c = personAccountRecord.Id;
                wrapper.orderRecord.Ship_To_Account__c = personAccountRecord.Id;
            }
            
            wrapper.orderRecord.RecordTypeId = orderRecordTypeId;
            wrapper.orderRecord.Status = 'Draft';
            wrapper.orderRecord.Sales_Type__c = 'Tertiary';
            wrapper.orderRecord.Record_Types__c = 'Appliance Tertiary';
            wrapper.orderRecord.Business_Unit__c = 'H';
            insert wrapper.orderRecord;
            return wrapper.orderRecord.Id;
        } catch(DMLException ex) {
            throw createCustomException(ex.getDmlMessage(0));
        }
    }
    
    /*----------------------------------------------------------------------------
     * Author:        Shailja Mishra
     * Company:       Salesforce
     * Description:   Wrapper class used as input parameter from flows
     * Inputs:        ServiceRequestWrapper
     * Test Class:    
     * ---------------------------------------------------------------------------
     * History
     * 17-09-2020      Shailja Mishra     Initial Release
     * ----------------------------------------------------------------------------*/
    public class ServiceRequestWrapper {
        @InvocableVariable public List<Integer> quantities;
        @InvocableVariable public List<String> assetSerialNumbers;
        @InvocableVariable public Case caseRecord;
        @InvocableVariable public String recordId;
        @InvocableVariable public String serialNumbers;
        @InvocableVariable public Boolean isClone = false;
        @InvocableVariable public Boolean isFromOrderSaleCapture = false;
        @InvocableVariable public List<String> recordIds;
        @InvocableVariable public Boolean isQuickCreate = false;
        @InvocableVariable public List<String> productCategories;
        @InvocableVariable public Boolean isTertiaryOrderCreation = false;
        @InvocableVariable public Account personAccount;
        @InvocableVariable public Address__c addressRecord;
        @InvocableVariable public Order orderRecord;
    }
}