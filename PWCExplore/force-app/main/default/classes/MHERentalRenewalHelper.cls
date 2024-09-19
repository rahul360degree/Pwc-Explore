/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Helper for MHERentalRenewalBatch, creates renewal opportunities for Godrej RenTRUST
Inputs:        
Test Class:    MHERentalRenewalBatchTest

History
23-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public  without sharing class MHERentalRenewalHelper {

    /* 
     * processRenewalForRenTRUST()
     * Purpose - Method to orchestrate the creation of renewal Opportunities for Godrej RenTRUST
     */
    public static void processRenewalForRenTRUST(List<ServiceContract> scList) {
        
        // 0. Generate Field Mapping
        Map<String, String> scMap = RenewalHelper.prepareMetadata('ServiceContract', 'Opportunity', 'Contract');
        Map<String, String> cliMap = RenewalHelper.prepareMetadata('ContractLineItem', 'OpportunityLineItem', 'Contract');
        
        // 1. Generate Query
        String subquery = 'SELECT ' + String.join(new List<String>(cliMap.keyset()), ',') + ' FROM ContractLineItems';  
        String query = 'SELECT (' + subquery + '), '  + String.join(new List<String>(scMap.keyset()), ',') + ' FROM ServiceContract WHERE ID IN :scList';
        
        // 2. Query Records
        List<ServiceContract> extendedList = Database.query(query);
        
        // 3. Create Opportunities
        List<Opportunity> oppList = RenewalHelper.processOpportunities(extendedList, scMap);
        oppList = MHERentalRenewalHelper.addDefaultValuesForRenTRUST(oppList);
        Map<ID,Database.SaveResult> createOpportunityResult = new Map<ID,Database.SaveResult>();
        Database.SaveResult[] opptyInsertResult = Database.insert(oppList, false);
        for(integer i = 0 ; i < extendedList.size(); i++) {
              createOpportunityResult.put(extendedList[i].Id, opptyInsertResult[i]);
        }
        
        //Request line items only where opportunity is created successfully
        Map<ID,ID> contractID_SuccessOpptyID_Map = MHERentalRenewalHelper.handleSaveResult(createOpportunityResult);

        
        // 4. Create OpportunityLineItems
        List<OpportunityLineItem> oliInitialList = RenewalHelper.processOpportunityLineItems( extendedList, 
                                                                                              cliMap, 
                                                                                              contractID_SuccessOpptyID_Map, 
                                                                                              'ContractLineItems');
        List<OpportunityLineItem> oliList = MHERentalRenewalHelper.reviseOLIwithProductCode(oliInitialList);
        Database.SaveResult[] oliInsertResult = Database.insert(oliList, false);
        
        Map<ID, Database.SaveResult> opptyId_FailedLineItems_Map = new Map<ID, Database.SaveResult>();
        for(Integer i = 0; i < oliList.size(); i++) {
            if(oliInsertResult[i].isSuccess() == FALSE)
                opptyId_FailedLineItems_Map.put(oliList[i].OpportunityId, oliInsertResult[i]);
        }
        
        List<Application_Log__c> errorLogList = MHERentalRenewalHelper.errorLoggingHelper(contractID_SuccessOpptyID_Map,opptyId_FailedLineItems_Map,opptyInsertResult,extendedList );
        
        if(!errorLogList.isEmpty())
            Database.insert(errorLogList, false);
    }

    /* 
     * reviseOLIwithProductCode()
     * Purpose - Revise line items for MHE Rentals with the active product & price with the same Product Code - Item_Code__c
     * @return List<OpportunityLineItem> - List of OLI with revised prices/products. 
     *                                     Some OLI may be removed if no active ProductCode is available.
     */
    public static List<OpportunityLineItem> reviseOLIwithProductCode(List<OpportunityLineItem> oliList) {
        List<OpportunityLineItem> revisedLineItemList = new List<OpportunityLineItem>();
        
        String mheRentalPriceBookName = System.Label.MHE_SF_Local_Rental_PB;
        Set<ID> priceBookEntryIdSet = new Set<ID>();
        for(OpportunityLineItem oliObj : oliList) {
            if(String.isNotBlank(oliObj.pricebookEntryId))
                priceBookEntryIdSet.add(oliObj.pricebookEntryId);
        }
        List<PriceBookEntry> oldPBEList = new List<PriceBookEntry>([Select Id, Name, Product2.ProductCode
                                                                    From PriceBookEntry
                                                                    Where ID IN :priceBookEntryIdSet]);
        Map<Id,String> productCodeMap = new Map<Id,String>();
        for(PriceBookEntry pbe : oldPBEList) {
            if(String.isNotBlank(pbe.Product2.ProductCode))
                productCodeMap.put(pbe.Id, pbe.Product2.ProductCode);
        }
        
        Map<String, PriceBookEntry> newPriceEntryMap = new Map<String,PriceBookEntry>();
        List<PriceBookEntry> newPBEList = new List<PriceBookEntry>([Select Id, Name, UnitPrice, PriceBook2Id, Product2Id, 
                                                                           Product2.ProductCode, Product2.Item_Code__c
                                                                    From PriceBookEntry
                                                                    Where Product2.Item_Code__c IN :productCodeMap.values() 
                                                                    And IsActive = TRUE
                                                                    And PriceBook2.Name = :mheRentalPriceBookName]);
        for(PriceBookEntry pbeNew : newPBEList) {
            newPriceEntryMap.put(pbeNew.Product2.Item_Code__c, pbeNew);
        }
        
        for(OpportunityLineItem oliObj : oliList) {
            if(String.isNotBlank(oliObj.pricebookEntryId)
               && (productCodeMap.get(oliObj.pricebookEntryId) <> NULL)
               && (newPriceEntryMap.get(productCodeMap.get(oliObj.pricebookEntryId)) <> NULL)
              ) {
                PriceBookEntry newPBE = newPriceEntryMap.get(productCodeMap.get(oliObj.pricebookEntryId));
                oliObj.PriceBookEntryId = newPBE.Id;
                oliObj.UnitPrice = newPBE.UnitPrice;
                oliObj.TotalPrice = NULL;
                revisedLineItemList.add(oliObj);
            }
        }
        return revisedLineItemList;
    }
    
    public static List<Opportunity> addDefaultValuesForRenTRUST(List<Opportunity> oppList) {
        ID mheRentalRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME).getRecordTypeId();
        Integer numberOfDaysForCloseDate = Integer.ValueOf(RenewalHelper.getApplicationSetting('MHERentalRenewal_DefaultCloseDate'));
        Date closeDateVal = System.today().addDays(numberOfDaysForCloseDate); 
        String defaultOwnerUsername = RenewalHelper.getApplicationSetting('MHERentalRenewal_DefaultOpporyinityOwner');
        String defaultStageName = RenewalHelper.getApplicationSetting('MHERentalRenewal_DefaultOpporyinityStage');
        String defaultType = RenewalHelper.getApplicationSetting('MHERentalRenewal_DefaultOpporyinityType');
        String namePrefix = RenewalHelper.getApplicationSetting('MHERentalRenewal_OpportunityNamePrefix');
        List<User> defaultUserL = new List<User>([Select Id from User where username = :defaultOwnerUsername]);
        
        for(Opportunity opp : oppList) {
            opp.Name = namePrefix + ' '+ opp.Name;
            opp.recordTypeId = mheRentalRecordTypeId;
            opp.StageName = defaultStageName; 
            opp.CloseDate = closeDateVal;
            opp.Type = defaultType; 
            opp.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
            if(!defaultUserL.isEmpty())
                opp.OwnerId = defaultUserL[0].Id;
            
        }
        return oppList;
    }
    
    
    
    /* 
     * handleSaveResult()
     * @param saveResultMap - List of ServiceContracts ID mapped to corresponding opportunity insert result
     * @return Map<Id,Id> - Just the service contract ID mapped to the successfully created opportunity ID
     */
    public static Map<Id,Id> handleSaveResult(Map<ID,Database.SaveResult> saveResultMap) {
        Map<Id,Id> contractID_opptyID_Map = new Map<Id,Id>();
        for(ID scID : saveResultMap.keyset()) {
            if(saveResultMap.get(scID).isSuccess())
                contractID_opptyID_Map.put(scID, saveResultMap.get(scID).getId());
        }
        return contractID_opptyID_Map;
    }
    
    
    /* 
     * errorLoggingHelper()
     * Purpose - Catches error at Opportunity/LineItem level per Service Contract, creates log records
     * @return List<Application_Log__c> - List of application log records to be inserted
     */
    public static List<Application_Log__c> errorLoggingHelper(Map<Id,Id> recordId_OppId_Map,
                                          Map<ID, Database.SaveResult> opptyId_FailedLineItems_Map,
                                          Database.SaveResult[] opptyInsertResult,
                                          List<SObject> extendedList) {
        List<Application_Log__c> errorLogList = new List<Application_Log__c>();
        
        for(integer i = 0 ; i < extendedList.size(); i++) {
            String errorMessage;
            
            if(recordId_OppId_Map.containsKey(extendedList[i].Id) == FALSE) {
                //log error - at opportunity level
                Database.SaveResult sr = opptyInsertResult[i];
                errorMessage = 'Error creating Opportunity - '+ sr.getErrors().toString();
            }
            else if( (recordId_OppId_Map.containsKey(extendedList[i].Id) )
                      && opptyId_FailedLineItems_Map.containsKey( recordId_OppId_Map.get(extendedList[i].Id) )
                   ) {
                //log error - at opportunity line item level
                Database.SaveResult sr_lineItem = opptyId_FailedLineItems_Map.get( recordId_OppId_Map.get(extendedList[i].Id) );
                errorMessage = 'Error creating Opportunity Line Item - '+ sr_lineItem.getErrors().toString();
            }
            
            if(String.isNotBlank(errorMessage)) {
               errorLogList.add( RenewalHelper.createLog('RenewalHelper', 
                                                        'processRenewalForRenTRUST()', 
                                                         extendedList[i].Id, 
                                                         errorMessage) );
            }

        }
        
        return errorLogList;
    }
}