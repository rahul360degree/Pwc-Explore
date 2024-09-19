/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Utility class to perform inventory / warehouse related operations like validations and defaulting of warehouses.
Inputs:        NA
Test Class:    
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public class InventoryUtilityController {
    private static User currentUser = null;
    private static Map<String, Id> warehouseCodeVSId = new Map<String, ID>();
    private static Map<Id, String> warehouseIdVSCode = new Map<Id, String>();
    private static Map<Id, Warehouse__c> warehouseRecordMap = new Map<Id, Warehouse__c>();
    private static Set<String> availableChannelValues = new Set<String>();

    private static final String USER_PRIMARY_WAREHOUSE_MISSING = System.Label.USER_PRIMARY_WAREHOUSE_MISSING;
    private static final String NON_PRIMARY_WAREHOUSE_ADDED = System.Label.NON_PRIMARY_WAREHOUSE_ADDED;
    private static final String NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED = System.Label.NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED;
    private static final String ORDER_CHANNEL_VALIDATION_RECORD_TYPES = System.Label.Order_Stock_Check_Record_Types;

    private static final String QUOTE_APPLIANCES_RECORDTYPE_APINAME = 'Appliances';
    private static final String OPPORTUNITY_APPLIANCE_RECORDTYPE = 'Interio_B2C_Appliances';
    private static final String OPPORTUNITY_APPLIANCE_BUSINESS_UNIT = 'H';
    
    private static String profileName = null;

    private void getProfileName(){
        if(profileName==null){
            List<Profile> profile = [Select Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1];
            if(profile != null && profile.size() > 0){
                profileName = profile[0].Name;    
            }
        }
    }

    private void getUserRecord(String userId) {
        if(currentUser == null || currentUser.Id != Id.valueOf(userId)) {
            currentUser = [Select Id, Primary_Warehouses__c, Secondary_Warehouses__c, Business_Unit__c FROM User WHERE Id = :userID LIMIT 1];
        }
    }

    private void associateErrorToRecords(List<sObject> records, String errorMessage) {
        for(sObject sObjectRecord : records) {
            sObjectRecord.addError(errorMessage);
        }
    }

    private void getWarehouseRecordMap() {
        warehouseCodeVSId = new Map<String, Id>();
        warehouseIdVSCode = new Map<Id, String>();
        warehouseRecordMap = new Map<Id, Warehouse__c>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            List<String> userPrimaryWarehouseCode = currentUser.Primary_Warehouses__c.deleteWhitespace().split(',');

            if(warehouseCodeVSId.size() == 0) {
                List<Warehouse__c> warehouseRecords = [Select Id, Warehouse__c, Channel__c FROM Warehouse__c 
                    WHERE Warehouse__c IN :userPrimaryWarehouseCode LIMIT 3000];
                
                for(Warehouse__c warehouseRecord : warehouseRecords) {
                    warehouseCodeVSId.put(warehouseRecord.Warehouse__c, warehouseRecord.Id);
                    warehouseIdVSCode.put(warehouseRecord.Id, warehouseRecord.Warehouse__c);
                    warehouseRecordMap.put(warehouseRecord.Id, warehouseRecord);
                }
            }
        }
    }

    private void getWarehouseRecordMapWithChannel(List<String> channelValues) {
        warehouseCodeVSId = new Map<String, Id>();
        warehouseIdVSCode = new Map<Id, String>();
        warehouseRecordMap = new Map<Id, Warehouse__c>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            String query = 'Select Id, Warehouse__c FROM Warehouse__c';
            List<String> userPrimaryWarehouseCode = currentUser.Primary_Warehouses__c.deleteWhitespace().split(',');
            query += ' WHERE Warehouse__c IN :userPrimaryWarehouseCode AND Channel__c INCLUDES (';
            Boolean notFirstValue = false;
            for(String channelValue : channelValues) {
                if(notFirstValue) {
                    query += ',';
                }
                query += '\'' + channelValue + '\'';
                notFirstValue = true;
            }
            query += ') LIMIT 3000';

            List<Warehouse__c> warehouseRecords = Database.query(query);
            for(Warehouse__c warehouseRecord : warehouseRecords) {
                warehouseCodeVSId.put(warehouseRecord.Warehouse__c, warehouseRecord.Id);
                warehouseIdVSCode.put(warehouseRecord.Id, warehouseRecord.Warehouse__c);
                warehouseRecordMap.put(warehouseRecord.Id, warehouseRecord);
            }
        }
    }

    private void getWarehouseRecordMapBasedOnChannel() {
        warehouseCodeVSId = new Map<String, Id>();
        warehouseIdVSCode = new Map<Id, String>();
        warehouseRecordMap = new Map<Id, Warehouse__c>();
        List<String> channelValueList = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            List<String> userPrimaryWarehouseCode = currentUser.Primary_Warehouses__c.deleteWhitespace().split(',');

            if(warehouseCodeVSId.size() == 0) {
                List<Warehouse__c> warehouseRecords = [Select Id, Warehouse__c, Channel__c FROM Warehouse__c 
                    WHERE Warehouse__c IN :userPrimaryWarehouseCode AND Channel__c != null LIMIT 3000];
                
                for(Warehouse__c warehouseRecord : warehouseRecords) {
                    warehouseCodeVSId.put(warehouseRecord.Warehouse__c, warehouseRecord.Id);
                    warehouseIdVSCode.put(warehouseRecord.Id, warehouseRecord.Warehouse__c);
                    warehouseRecordMap.put(warehouseRecord.Id, warehouseRecord);
                    if(String.isNotBlank(warehouseRecord.Channel__c)) {
                        channelValueList.add(warehouseRecord.Channel__c);
                    }
                }
            }

            if(channelValueList.size() > 0) {
                getAvailableChannelValueSet(channelValueList);
            }
        }
    }

    private void getAvailableChannelValueSet(List<String> channelValueList) {
        Set<String> channnelValueSet = new Set<String>();
        // Since in multi-select picklist's, channel values are stored in semi-colon seperated values which needs to be converted.
        for(String combinedChannelValues : channelValueList) {
            List<String> channelValuesAfterSplit = combinedChannelValues.deleteWhitespace().split(';');
            for(String channelValue : channelValuesAfterSplit) {
                if(String.isNotBlank(channelValue)) {
                    availableChannelValues.add(channelValue);
                }
            }
        }
    }
    
    // Opportunity defaulting section for appliance and other type opportunities.
    public void populateApplianceAndNormalOpportunityWarehouse(List<Opportunity> opportunityRecords) {
        List<Opportunity> channelOpportunity = new List<Opportunity>();
        List<Opportunity> normalOpportunity = new List<Opportunity>();

        // Split order records into channel and normal flow order.
        for(Opportunity opportunityRecord : opportunityRecords) {
            if(opportunityRecord.WarehouseCode__c == null) {
                String recordTypeDevName =  Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opportunityRecord.RecordTypeId).getDeveloperName();
                if(OPPORTUNITY_APPLIANCE_RECORDTYPE == recordTypeDevName && opportunityRecord.Business_Unit__c == OPPORTUNITY_APPLIANCE_BUSINESS_UNIT) {
                    channelOpportunity.add(opportunityRecord);
                } else {
                    normalOpportunity.add(opportunityRecord);
                }
            }
        }

        if(channelOpportunity.size() > 0) {
            defaultChannelOpportunityWarehouses(channelOpportunity);
        }
        if(normalOpportunity.size() > 0) {
            defaultNormalOpportunityWarehouses(normalOpportunity);
        }
    }

    private void defaultChannelOpportunityWarehouses(List<Opportunity> opportunityRecords) {
        // Get the user record baed on the current action performing user.
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<Branch__c> branchRecords = new List<Branch__c>();
        
        List<Id> accountIds = new List<Id>();
        for(Opportunity oppRecord : opportunityRecords) {
            accountIds.add(oppRecord.AccountId);
        }

        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMapBasedOnChannel();

        if(availableChannelValues.size() > 0) {
            branchRecords = [Select Id, Business_Partner__c, Channel__c FROM Branch__c 
                WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
        }

        if(branchRecords.size() > 0) {

            Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();
            for(Branch__c branchRecord : branchRecords) {
                Set<String> validChannelValues = new Set<String>();
                if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                    validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                }
                validChannelValues.add(branchRecord.Channel__c);
                accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
            }

            List<String> primaryWarehouseCodes = new List<String>();
            // Get the list of warehouse codes based the values mentioned in the Primary Warehouse field in user record.
            if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
            }

            // Iterate through the opportunity records and check if a valid warehouse record is available for it to be assigned
            // to the respective record.
            if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                for(Opportunity opportunityRecord : opportunityRecords) {

                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(opportunityRecord.AccountId);
                    Set<String> validWarehouseCode_ForParticularOppRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularOppRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }
                    
                    for(String primaryWarehouseCode : primaryWarehouseCodes) {
                        if(validWarehouseCode_ForParticularOppRecord.contains(primaryWarehouseCode.trim())
                        && warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                            opportunityRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                            break;
                        }
                    }
                }
            }
        }
    }

    private void defaultNormalOpportunityWarehouses(List<Opportunity> opportunityRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
        }
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(warehouseCodeVSId.size() > 0) {
            for(Opportunity opportunityRecord : opportunityRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        opportunityRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    // Opportunity validation section for appliance and other opportunities.
    public void validateApplianceAndNormalOpportunityWarehouse(List<Opportunity> opportunityRecords) {
        List<Opportunity> channelOpportunityRecords = new List<Opportunity>();
        List<Opportunity> normalOpportunityRecords = new List<Opportunity>();

        // Split order records into channel and normal flow order.
        for(Opportunity opportunityRecord : opportunityRecords) {
            String recordTypeDevName =  Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opportunityRecord.RecordTypeId).getDeveloperName();
            if(OPPORTUNITY_APPLIANCE_RECORDTYPE == recordTypeDevName && opportunityRecord.Business_Unit__c == OPPORTUNITY_APPLIANCE_BUSINESS_UNIT) {
                channelOpportunityRecords.add(opportunityRecord);
            } else {
                normalOpportunityRecords.add(opportunityRecord);
            }
        }

        if(channelOpportunityRecords.size() > 0) {
            validateApplianceOpportunities(channelOpportunityRecords);
        }
        if(normalOpportunityRecords.size() > 0) {
            validateNormalOpportunityWarehouses(normalOpportunityRecords);
        }
    }

    private void validateApplianceOpportunities(List<Opportunity> opportunityRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Opportunity oppRecord : opportunityRecords) {
                oppRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            List<Opportunity> errorRecords = new List<Opportunity>();
            List<Branch__c> branchRecords = new List<Branch__c>();
            // Get the map of warehouse code VS warehouse Id.
            for(Opportunity opportunityRecord : opportunityRecords) {
                accountIds.add(opportunityRecord.AccountId);
            }

            // Get the map of warehouse code VS warehouse Id.
            getWarehouseRecordMapBasedOnChannel();

            if(availableChannelValues.size() > 0) {
                branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                    WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
            }

            if(branchRecords.size() > 0 && warehouseCodeVSId.size() > 0) {
                Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();

                for(Branch__c branchRecord : branchRecords) {
                    Set<String> validChannelValues = new Set<String>();
                    if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                        validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                    }
                    validChannelValues.add(branchRecord.Channel__c);
                    accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
                }

                for(Opportunity opportunityRecord : opportunityRecords) {
                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(opportunityRecord.AccountId);
                    Set<String> validWarehouseCode_ForParticularOppRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularOppRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }

                    if(!warehouseIdVSCode.containsKey(opportunityRecord.WarehouseCode__c)
                    || !validWarehouseCode_ForParticularOppRecord.contains(warehouseIdVSCode.get(opportunityRecord.WarehouseCode__c))) {
                        errorRecords.add(opportunityRecord);
                    }
                }
            } else {
                for(Opportunity opportunityRecord : opportunityRecords) {
                    errorRecords.add(opportunityRecord);
                }
            }

            // Associate error message with all those records that do not match the condition.
            if(errorRecords.size() > 0) {
                associateErrorToRecords(errorRecords, NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
            }
        }
    }

    private void validateNormalOpportunityWarehouses(List<Opportunity> opportunityRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Opportunity opportunityRecord : opportunityRecords) {
                opportunityRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(Opportunity opportunityRecord : opportunityRecords) {
                if(!warehouseIdVSCode.containsKey(opportunityRecord.WarehouseCode__c)) {
                    opportunityRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }

    // Opportunity products defaulting section for appliance and other opportunities.
    public void populateApplianceAndNormal_OppProduct_Warehouse(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        List<OpportunityLineItem> channelOppProductRecords = new List<OpportunityLineItem>();
        List<OpportunityLineItem> normalOppProductRecords = new List<OpportunityLineItem>();

        // Split order records into channel and normal flow order.
        for(OpportunityLineItem oppProductRecord : oppProductRecords) {
            Opportunity oppRecord = oppRecordMap.get(oppProductRecord.OpportunityId);
            String recordTypeDevName =  Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(oppRecord.RecordTypeId).getDeveloperName();
            if(OPPORTUNITY_APPLIANCE_RECORDTYPE == recordTypeDevName && oppRecord.Business_Unit__c == OPPORTUNITY_APPLIANCE_BUSINESS_UNIT) {
                channelOppProductRecords.add(oppProductRecord);
            } else {
                normalOppProductRecords.add(oppProductRecord);
            }
        }

        if(channelOppProductRecords.size() > 0) {
            defaultChannelBased_OppProduct_Warehouses(channelOppProductRecords, oppRecordMap);
        }
        if(normalOppProductRecords.size() > 0) {
            defaultNormalOppProductWarehouses(normalOppProductRecords, oppRecordMap);
        }
    }

    private void defaultChannelBased_OppProduct_Warehouses(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();
        List<Branch__c> branchRecords = new List<Branch__c>();

        for(Opportunity oppRecord : oppRecordMap.values()) {
            accountIds.add(oppRecord.AccountId);
        }

        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMapBasedOnChannel();

        if(availableChannelValues.size() > 0) {
            branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
        }

        if(branchRecords.size() > 0) {
            Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();
            for(Branch__c branchRecord : branchRecords) {
                Set<String> validChannelValues = new Set<String>();
                if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                    validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                }
                validChannelValues.add(branchRecord.Channel__c);
                accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
            }

            List<String> primaryWarehouseCodes = new List<String>();
            // Get the list of warehouse codes based the values mentioned in the Primary Warehouse field in user record.
            if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
            }

            // Iterate through the opportunity line item records and check if a valid warehouse record is available for it to be assigned
            // to the respective record.
            if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                for(OpportunityLineItem oppProductRecord : oppProductRecords) {

                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(oppRecordMap.get(oppProductRecord.OpportunityId).AccountId);
                    Set<String> validWarehouseCode_ForParticularOppRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularOppRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }

                    for(String primaryWarehouseCode : primaryWarehouseCodes) {
                        if(validWarehouseCode_ForParticularOppRecord.contains(primaryWarehouseCode.trim())
                        && warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                            oppProductRecord.Warehouse__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                            break;
                        }
                    }
                }
            }
        }
    }

    private void defaultNormalOppProductWarehouses(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
        }
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        oppProductRecord.Warehouse__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    // Opportunity products validation section for appliance and other opportunities.
    public void validateOpportunityProductWarehouses(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        List<OpportunityLineItem> channelOppProductRecords = new List<OpportunityLineItem>();
        List<OpportunityLineItem> normalOppProductRecords = new List<OpportunityLineItem>();

        // Split order records into channel and normal flow order.
        for(OpportunityLineItem oppProductRecord : oppProductRecords) {
            Opportunity oppRecord = oppRecordMap.get(oppProductRecord.OpportunityId);
            String recordTypeDevName =  Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(oppRecord.RecordTypeId).getDeveloperName();
            if(OPPORTUNITY_APPLIANCE_RECORDTYPE == recordTypeDevName && oppRecord.Business_Unit__c == OPPORTUNITY_APPLIANCE_BUSINESS_UNIT) {
                channelOppProductRecords.add(oppProductRecord);
            } else {
                normalOppProductRecords.add(oppProductRecord);
            }
        }

        if(channelOppProductRecords.size() > 0) {
            validateChannelBased_OppProduct_Warehouses(channelOppProductRecords, oppRecordMap);
        }
        if(normalOppProductRecords.size() > 0) {
            validateNormalOppProductWarehouses(normalOppProductRecords, oppRecordMap);
        }
    }

    private void validateChannelBased_OppProduct_Warehouses(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();

        // If the current user does not have any Primary Warehouses populated then throw error for all the records.
        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                oppProductRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            List<Branch__c> branchRecords = new List<Branch__c>();
            List<SObject> errorRecords = new List<SObject>();

            for(Opportunity oppRecord : oppRecordMap.values()) {
                accountIds.add(oppRecord.AccountId);
            }

            // Get the map of warehouse code VS warehouse Id.
            getWarehouseRecordMapBasedOnChannel();
    
            if(availableChannelValues.size() > 0) {
                branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                    WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
            }

            if(branchRecords.size() > 0 && warehouseCodeVSId.size() > 0) {
                Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();

                for(Branch__c branchRecord : branchRecords) {
                    Set<String> validChannelValues = new Set<String>();
                    if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                        validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                    }
                    validChannelValues.add(branchRecord.Channel__c);
                    accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
                }

                for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(oppRecordMap.get(oppProductRecord.OpportunityId).AccountId);
                    Set<String> validWarehouseCode_ForParticularOppRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularOppRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }

                    if(!warehouseIdVSCode.containsKey(oppProductRecord.Warehouse__c)
                    || !validWarehouseCode_ForParticularOppRecord.contains(warehouseIdVSCode.get(oppProductRecord.Warehouse__c))) {
                        errorRecords.add(oppProductRecord);
                    }
                }
            } else {
                for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                    errorRecords.add(oppProductRecord);
                }
            }

            // Associate error message with all those records that do not match the condition.
            if(errorRecords.size() > 0) {
                associateErrorToRecords(errorRecords, NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
            }
        }
    }

    private void validateNormalOppProductWarehouses(List<OpportunityLineItem> oppProductRecords, Map<Id, Opportunity> oppRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                oppProductRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(OpportunityLineItem oppProductRecord : oppProductRecords) {
                if(!warehouseIdVSCode.containsKey(oppProductRecord.Warehouse__c)) {
                    oppProductRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }

    // Quote defaulting section for appliance and other type quote records.
    public void defaultApplianceAndNormalQuoteWarehouse(List<Quote> quoteRecords) {
        List<Quote> channelQuoteRecords = new List<Quote>();
        List<Quote> normalQuoteRecords = new List<Quote>();

        // Split order records into channel and normal flow order.
        for(Quote quoteRecord : quoteRecords) {
            String recordTypeDevName =  Schema.SObjectType.Quote.getRecordTypeInfosById().get(quoteRecord.RecordTypeId).getDeveloperName();
            if(QUOTE_APPLIANCES_RECORDTYPE_APINAME == recordTypeDevName) {
                channelQuoteRecords.add(quoteRecord);
            } else {
                normalQuoteRecords.add(quoteRecord);
            }
        }

        if(channelQuoteRecords.size() > 0) {
            defaultApplianceQuoteWarehouses(channelQuoteRecords);
        }
        if(normalQuoteRecords.size() > 0) {
            defaultNormalQuoteWarehouses(normalQuoteRecords);
        }
    }

    private void defaultApplianceQuoteWarehouses(List<Quote> quoteRecords) {
        // Get the user record baed on the current action performing user.
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<Branch__c> branchRecords = new List<Branch__c>();

        List<Id> accountIds = new List<Id>();
        for(Quote quoteRecord : quoteRecords) {
            accountIds.add(quoteRecord.Account_Name__c);
        }

        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMapBasedOnChannel();

        if(availableChannelValues.size() > 0) {
            branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
        }

        if(branchRecords.size() > 0) {
            Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();
            for(Branch__c branchRecord : branchRecords) {

                Set<String> validChannelValues = new Set<String>();
                if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                    validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                }
                validChannelValues.add(branchRecord.Channel__c);
                accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
            }

            List<String> primaryWarehouseCodes = new List<String>();
            // Get the list of warehouse codes based the values mentioned in the Primary Warehouse field in user record.
            if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
            }

            // Iterate through the quote records and check if a valid warehouse record is available for it to be assigned
            // to the respective record.
            if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                for(Quote quoteRecord : quoteRecords) {
                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(quoteRecord.Account_Name__c);
                    Set<String> validWarehouseCode_ForParticularQuoteRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularQuoteRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }
                    
                    for(String primaryWarehouseCode : primaryWarehouseCodes) {
                        if(validWarehouseCode_ForParticularQuoteRecord.contains(primaryWarehouseCode.trim())
                        && warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                            quoteRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                            break;
                        }
                    }
                }
            }
        }
    }

    private void defaultNormalQuoteWarehouses(List<Quote> quoteRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
        }
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            for(Quote quoteRecord : quoteRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        quoteRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    // Quote validation section for appliance and other type quote records.
    public void validateApplianceAndNormalQuoteWarehouses(List<Quote> quoteRecords) {
        List<Quote> channelQuoteRecords = new List<Quote>();
        List<Quote> normalQuoteRecords = new List<Quote>();

        // Split order records into channel and normal flow order.
        for(Quote quoteRecord : quoteRecords) {
            String recordTypeDevName =  Schema.SObjectType.Quote.getRecordTypeInfosById().get(quoteRecord.RecordTypeId).getDeveloperName();
            if(QUOTE_APPLIANCES_RECORDTYPE_APINAME == recordTypeDevName) {
                channelQuoteRecords.add(quoteRecord);
            } else {
                normalQuoteRecords.add(quoteRecord);
            }
        }

        if(channelQuoteRecords.size() > 0) {
            validateApplianceQuoteWarehouses(channelQuoteRecords);
        }
        if(normalQuoteRecords.size() > 0) {
            validateNormalQuoteWarehouses(normalQuoteRecords);
        }
    }

    private void validateApplianceQuoteWarehouses(List<Quote> quoteRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Quote quoteRecord : quoteRecords) {
                quoteRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            List<Quote> errorRecords = new List<Quote>();
            List<Branch__c> branchRecords = new List<Branch__c>();
            // Get the map of warehouse code VS warehouse Id.
            for(Quote quoteRecord : quoteRecords) {
                accountIds.add(quoteRecord.Account_Name__c);
            }

            // Get the map of warehouse code VS warehouse Id.
            getWarehouseRecordMapBasedOnChannel();

            if(availableChannelValues.size() > 0) {
                branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                    WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
            }

            if(branchRecords.size() > 0 && warehouseCodeVSId.size() > 0) {
                Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();

                for(Branch__c branchRecord : branchRecords) {
                    Set<String> validChannelValues = new Set<String>();
                    if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                        validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                    }
                    validChannelValues.add(branchRecord.Channel__c);
                    accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
                }

                for(Quote quoteRecord : quoteRecords) {
                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(quoteRecord.Account_Name__c);
                    Set<String> validWarehouseCode_ForParticularQuoteRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularQuoteRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }

                    if(!warehouseIdVSCode.containsKey(quoteRecord.WarehouseCode__c)
                    || !validWarehouseCode_ForParticularQuoteRecord.contains(warehouseIdVSCode.get(quoteRecord.WarehouseCode__c))) {
                        errorRecords.add(quoteRecord);
                    }
                }
            }else {
                for(Quote quoteRecord : quoteRecords) {
                    errorRecords.add(quoteRecord);
                }
            }

            // Associate error message with all those records that do not match the condition.
            if(errorRecords.size() > 0) {
                associateErrorToRecords(errorRecords, NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
            }
        }
    }

    private void validateNormalQuoteWarehouses(List<Quote> quoteRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Quote quoteRecord : quoteRecords) {
                quoteRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(Quote quoteRecord : quoteRecords) {
                if(!warehouseIdVSCode.containsKey(quoteRecord.WarehouseCode__c)) {
                    quoteRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }

    // Quote Line Item defaulting section for appliance and other types of quote line item records.
    public void populateApplianceAndNormal_QLI_Warehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        List<QuoteLineItem> channelQLIProductRecords = new List<QuoteLineItem>();
        List<QuoteLineItem> normalQLIProductRecords = new List<QuoteLineItem>();

        // Split order records into channel and normal flow order.
        for(QuoteLineItem qliRecord : qliRecords) {
            Quote quoteRecord = quoteRecordMap.get(qliRecord.QuoteId);
            String recordTypeDevName =  Schema.SObjectType.Quote.getRecordTypeInfosById().get(quoteRecord.RecordTypeId).getDeveloperName();
            if(QUOTE_APPLIANCES_RECORDTYPE_APINAME == recordTypeDevName) {
                channelQLIProductRecords.add(qliRecord);
            } else {
                normalQLIProductRecords.add(qliRecord);
            }
        }

        if(channelQLIProductRecords.size() > 0) {
            defaultChannelBased_QLI_Warehouses(channelQLIProductRecords, quoteRecordMap);
        }
        if(normalQLIProductRecords.size() > 0) {
            defaultNormalQLIWarehouses(normalQLIProductRecords, quoteRecordMap);
        }
    }

    private void defaultChannelBased_QLI_Warehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();
        List<Branch__c> branchRecords = new List<Branch__c>();

        for(Quote quoteRecord : quoteRecordMap.values()) {
            accountIds.add(quoteRecord.Account_Name__c);
        }

        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMapBasedOnChannel();

        if(availableChannelValues.size() > 0 && accountIds.size() > 0) {
            branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
        }

        if(branchRecords.size() > 0) {
            Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();
            for(Branch__c branchRecord : branchRecords) {
                Set<String> validChannelValues = new Set<String>();
                if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                    validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                }
                validChannelValues.add(branchRecord.Channel__c);
                accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
            }

            List<String> primaryWarehouseCodes = new List<String>();
            // Get the list of warehouse codes based the values mentioned in the Primary Warehouse field in user record.
            if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
            }

            // Iterate through the quote line item records and check if a valid warehouse record is available for it to be assigned
            // to the respective record.
            if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
                for(QuoteLineItem qliRecord : qliRecords) {

                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(quoteRecordMap.get(qliRecord.QuoteId).Account_Name__c);
                    Set<String> validWarehouseCode_ForParticularQuoteRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularQuoteRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }

                    for(String primaryWarehouseCode : primaryWarehouseCodes) {
                        if(validWarehouseCode_ForParticularQuoteRecord.contains(primaryWarehouseCode.trim())
                        && warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                            qliRecord.Warehouse__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                            break;
                        }
                    }
                }
            }
        }
    }

    private void defaultNormalQLIWarehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
        }
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            for(QuoteLineItem qliRecord : qliRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        qliRecord.Warehouse__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    // Quote Line Item validation section for appliance and other types of quote line item records.
    public void validateApplianceAndNormal_QLI_Warehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        List<QuoteLineItem> channelQLIProductRecords = new List<QuoteLineItem>();
        List<QuoteLineItem> normalQLIProductRecords = new List<QuoteLineItem>();

        // Split order records into channel and normal flow order.
        for(QuoteLineItem qliRecord : qliRecords) {
            Quote quoteRecord = quoteRecordMap.get(qliRecord.QuoteId);
            String recordTypeDevName =  Schema.SObjectType.Quote.getRecordTypeInfosById().get(quoteRecord.RecordTypeId).getDeveloperName();
            if(QUOTE_APPLIANCES_RECORDTYPE_APINAME == recordTypeDevName) {
                channelQLIProductRecords.add(qliRecord);
            } else {
                normalQLIProductRecords.add(qliRecord);
            }
        }

        if(channelQLIProductRecords.size() > 0) {
            validateChannelBased_QLI_Warehouses(channelQLIProductRecords, quoteRecordMap);
        }
        if(normalQLIProductRecords.size() > 0) {
            validateNormalQLIWarehouses(normalQLIProductRecords, quoteRecordMap);
        }
    }

    private void validateChannelBased_QLI_Warehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        Set<Id> accountIds = new Set<Id>();
        // If the current user does not have any Primary Warehouses populated then throw error for all the records.
        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(QuoteLineItem qliRecord : qliRecords) {
                qliRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            List<Branch__c> branchRecords = new List<Branch__c>();
            List<SObject> errorRecords = new List<SObject>();

            for(Quote quoteRecord : quoteRecordMap.values()) {
                accountIds.add(quoteRecord.Account_Name__c);
            }

            // Get the map of warehouse code VS warehouse Id.
            getWarehouseRecordMapBasedOnChannel();

            if(availableChannelValues.size() > 0) {
                branchRecords = [Select Id, Channel__c, Business_Partner__c FROM Branch__c 
                    WHERE Business_Partner__c IN :accountIds AND Channel__c IN :availableChannelValues];
            }

            if(branchRecords.size() > 0 && warehouseCodeVSId.size() > 0) {
                Map<Id, Set<String>> accountIdVSValidChannelValues = new Map<Id, Set<String>>();

                for(Branch__c branchRecord : branchRecords) {
                    Set<String> validChannelValues = new Set<String>();
                    if(accountIdVSValidChannelValues.containsKey(branchRecord.Business_Partner__c)) {
                        validChannelValues = accountIdVSValidChannelValues.get(branchRecord.Business_Partner__c);
                    }
                    validChannelValues.add(branchRecord.Channel__c);
                    accountIdVSValidChannelValues.put(branchRecord.Business_Partner__c, validChannelValues);
                }

                for(QuoteLineItem qliRecord : qliRecords) {

                    Set<String> validChannelCodes = accountIdVSValidChannelValues.get(quoteRecordMap.get(qliRecord.QuoteId).Account_Name__c);
                    Set<String> validWarehouseCode_ForParticularQuoteRecord = new Set<String>();

                    // Get only those warehouse codes whose warehouse channel that matches with that of current record's channel.
                    for(Warehouse__c warehouseRecord : warehouseRecordMap.values()) {
                        for(String validChannelCode : validChannelCodes) {
                            if(warehouseRecord.Channel__c.contains(validChannelCode)) {
                                validWarehouseCode_ForParticularQuoteRecord.add(warehouseRecord.Warehouse__c);
                            }
                        }
                    }
                    if(!warehouseIdVSCode.containsKey(qliRecord.Warehouse__c)
                    || !validWarehouseCode_ForParticularQuoteRecord.contains(warehouseIdVSCode.get(qliRecord.Warehouse__c))) {
                        errorRecords.add(qliRecord);
                        qliRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                    }
                }
            } else {
                for(QuoteLineItem qliRecord : qliRecords) {
                    errorRecords.add(qliRecord);
                    qliRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                }
            }

            // Associate error message with all those records that do not match the condition.
            if(errorRecords.size() > 0) {
                associateErrorToRecords(errorRecords, NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
            }
        }
    }

    private void validateNormalQLIWarehouses(List<QuoteLineItem> qliRecords, Map<Id, Quote> quoteRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(QuoteLineItem qliRecord : qliRecords) {
                qliRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(QuoteLineItem qliRecord : qliRecords) {
                if(!warehouseIdVSCode.containsKey(qliRecord.Warehouse__c)) {
                    qliRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }

    // Order validation section for appliance and other opportunities.
    public void defaultOrderWarehouses(List<Order> orderRecords) {
        List<Order> channelOrders = new List<Order>();
        List<Order> normalOrders = new List<Order>();

        // Split order records into channel and normal flow order.
        for(Order orderRecord : orderRecords) {
            String recordTypeDevName =  Schema.SObjectType.Order.getRecordTypeInfosById().get(orderRecord.RecordTypeId).getDeveloperName();
            if(!ORDER_CHANNEL_VALIDATION_RECORD_TYPES.contains(recordTypeDevName)) {
                normalOrders.add(orderRecord);
            } else if(String.isNotBlank(orderRecord.Branch__c)) {
                channelOrders.add(orderRecord);
            }
        }

        if(channelOrders.size() > 0) {
            defaultChannelOrderWarehouses(channelOrders);
        }
        if(normalOrders.size() > 0) {
            defaultNormalOrderWarehouses(normalOrders);
        }
    }

    private void defaultChannelOrderWarehouses(List<Order> channelBasedOrderRecords) {
        Set<Id> branchIds = new Set<Id>();
        Set<String> channelValues = new Set<String>();
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
            for(Order orderRecord : channelBasedOrderRecords) {
                if(String.isNotBlank(orderRecord.Branch__c)) {
                    branchIds.add(orderRecord.Branch__c);
                }
            }
        }

        if(branchIds.size() > 0) {
            for(Branch__c branchRecord: [Select Id, Channel__c FROM Branch__c WHERE Id IN :branchIds]) {
                if(String.isNotBlank(branchRecord.Channel__c)) {
                    channelValues.add(branchRecord.Channel__c);
                }
            }
        }

        if(channelValues.size() > 0) {
            // Get the map of warehouse code VS warehouse Id.
            getWarehouseRecordMapWithChannel(new List<String>(channelValues));
        }

        if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            for(Order orderRecord : channelBasedOrderRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        orderRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    private void defaultNormalOrderWarehouses(List<Order> normalOrderRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        List<String> primaryWarehouseCodes = new List<String>();

        if(String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            primaryWarehouseCodes = (currentUser.Primary_Warehouses__c.deleteWhitespace().split(','));
        }
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(warehouseCodeVSId.size() > 0 && String.isNotBlank(currentUser.Primary_Warehouses__c)) {
            for(Order orderRecord : normalOrderRecords) {
                for(String primaryWarehouseCode : primaryWarehouseCodes) {
                    if(warehouseCodeVSId.containsKey(primaryWarehouseCode.trim())) {
                        orderRecord.WarehouseCode__c = warehouseCodeVSId.get(primaryWarehouseCode.trim());
                        break;
                    }
                }
            }
        }
    }

    // Order validation section for appliance and other opportunities.
    public void validateOrderWarehouses(List<Order> orderRecords) {
        List<Order> channelOrders = new List<Order>();
        List<Order> normalOrders = new List<Order>();
        getProfileName();
        // Split order records into channel and normal flow order.
        for(Order orderRecord : orderRecords) {
            if(profileName!=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME){
                String recordTypeDevName =  Schema.SObjectType.Order.getRecordTypeInfosById().get(orderRecord.RecordTypeId).getDeveloperName();
                if(!ORDER_CHANNEL_VALIDATION_RECORD_TYPES.contains(recordTypeDevName)) {
                    normalOrders.add(orderRecord);
                } else {
                    channelOrders.add(orderRecord);
                }
            }
        }

        if(channelOrders.size() > 0) {
            validateChannelBasedOrderWarehouses(channelOrders);
        }
        if(normalOrders.size() > 0) {
            validateNormalOrderWarehouses(normalOrders);
        }
    }

    private void validateChannelBasedOrderWarehouses(List<Order> channelBasedOrderRecords) {
        Set<Id> branchIds = new Set<Id>();
        Set<String> channelValues = new Set<String>();
        getUserRecord(Id.valueOf(UserInfo.getUserId()));

        // If user does not have any primary warehouses then throw error else progress.
        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Order orderRecord : channelBasedOrderRecords) {
                orderRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            // Get Branch ids so that we can get appropriate channel based on branch record.
            for(Order orderRecord : channelBasedOrderRecords) {
                if(String.isNotBlank(orderRecord.Branch__c)) {
                    branchIds.add(orderRecord.Branch__c);
                }
            }

            // Based on branch id's query the branch records and then of channel value is populated then add that to the set.
            if(branchIds.size() > 0) {
                for(Branch__c branchRecord: [Select Id, Channel__c FROM Branch__c WHERE Id IN :branchIds]) {
                    if(String.isNotBlank(branchRecord.Channel__c)) {
                        channelValues.add(branchRecord.Channel__c);
                    }
                }
            }

            // If channel values are present then check if proper value is assigned
            // Else throw error for all the records that the current user is not assigning proper warehouse record based on channel.
            if(channelValues.size() > 0) {
                // Get the map of warehouse code VS warehouse Id based on channel values.
                getWarehouseRecordMapWithChannel(new List<String>(channelValues));
    
                for(Order orderRecord : channelBasedOrderRecords) {
                    if(warehouseIdVSCode.size() == 0 || !warehouseIdVSCode.containsKey(orderRecord.WarehouseCode__c)) {
                        orderRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                    }
                }
            } else {
                for(Order orderRecord : channelBasedOrderRecords) {
                    orderRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                }
            }
        }
    }

    private void validateNormalOrderWarehouses(List<Order> normalOrderRecords) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(Order orderRecord : normalOrderRecords) {
                orderRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(Order orderRecord : normalOrderRecords) {
                if(!warehouseIdVSCode.containsKey(orderRecord.WarehouseCode__c)) {
                    orderRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }

    // Order Item validation section for appliance and other opportunities.
    public void validateOrderItemRecords(List<OrderItem> orderItemRecords, Map<Id, Order> orderRecordMap) {
        List<OrderItem> channelOrderItems = new List<OrderItem>();
        List<OrderItem> normalOrderItems = new List<OrderItem>();
        getProfileName();
        // Split order records into channel and normal flow order.
        for(OrderItem orderItemRecord : orderItemRecords) {
            if(profileName!=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME){
                Order orderRecord = orderRecordMap.get(orderItemRecord.OrderId);
                String recordTypeDevName =  Schema.SObjectType.Order.getRecordTypeInfosById().get(orderRecord.RecordTypeId).getDeveloperName();
                if(!ORDER_CHANNEL_VALIDATION_RECORD_TYPES.contains(recordTypeDevName)) {
                    normalOrderItems.add(orderItemRecord);
                } else if(String.isNotBlank(orderRecord.Branch__c)) {
                    channelOrderItems.add(orderItemRecord);
                }
            }
        }

        if(channelOrderItems.size() > 0) {
            validateChannelBasedOrderItemWarehouses(channelOrderItems, orderRecordMap);
        }
        if(normalOrderItems.size() > 0) {
            validateNormalOrderItemWarehouses(normalOrderItems, orderRecordMap);
        }
    }

    private void validateChannelBasedOrderItemWarehouses(List<OrderItem> orderItems, Map<Id, Order> orderRecordMap) {
        Set<Id> branchIds = new Set<Id>();
        Set<String> channelValues = new Set<String>();
        getUserRecord(Id.valueOf(UserInfo.getUserId()));

        // If user does not have any primary warehouses then throw error else progress.
        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(OrderItem orderItemRecord : orderItems) {
                orderItemRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            // Get Branch ids so that we can get appropriate channel based on branch record.
            for(OrderItem orderItemRecord : orderItems) {
                Order orderRecord = orderRecordMap.get(orderItemRecord.OrderId);
                if(String.isNotBlank(orderRecord.Branch__c)) {
                    branchIds.add(orderRecord.Branch__c);
                }
            }

            // Based on branch id's query the branch records and then of channel value is populated then add that to the set.
            if(branchIds.size() > 0) {
                for(Branch__c branchRecord: [Select Id, Channel__c FROM Branch__c WHERE Id IN :branchIds]) {
                    if(String.isNotBlank(branchRecord.Channel__c)) {
                        channelValues.add(branchRecord.Channel__c);
                    }
                }
            }

            if(channelValues.size() > 0) {
                // Get the map of warehouse code VS warehouse Id.
                getWarehouseRecordMapWithChannel(new List<String>(channelValues));
    
                for(OrderItem orderItemRecord : orderItems) {
                    if(warehouseIdVSCode.size() == 0 || !warehouseIdVSCode.containsKey(orderItemRecord.Warehouse__c)) {
                        orderItemRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                    }
                }
            } else {
                for(OrderItem orderItemRecord : orderItems) {
                    orderItemRecord.addError(NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED);
                }
            }
        }
    }

    private void validateNormalOrderItemWarehouses(List<OrderItem> orderItems, Map<Id, Order> orderRecordMap) {
        getUserRecord(Id.valueOf(UserInfo.getUserId()));
        // Get the map of warehouse code VS warehouse Id.
        getWarehouseRecordMap();

        if(String.isBlank(currentUser.Primary_Warehouses__c)) {
            for(OrderItem orderItemRecord : orderItems) {
                orderItemRecord.addError(USER_PRIMARY_WAREHOUSE_MISSING);
            }
        } else {
            for(OrderItem orderItemRecord : orderItems) {
                if(warehouseIdVSCode.size() == 0 || !warehouseIdVSCode.containsKey(orderItemRecord.Warehouse__c)) {
                    orderItemRecord.addError(NON_PRIMARY_WAREHOUSE_ADDED);
                }
            }
        }
    }
}