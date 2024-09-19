/*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   Helper class for ClaimRequestTrigger
    Inputs:        NA
    Test Class:   
    ---------------------------------------------------------------------------
    History
    19-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/

public without sharing class ClaimRequestTriggerHelper {
    public static final Id WARRANTY_TYPE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_WARRANTY).getRecordTypeId();
    public static final Id ADHOC_CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_ADHOC).getRecordTypeId();
    public static final Id INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST).getRecordTypeId();
    public static final Id CONTRACT_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_CONTRACTS).getRecordTypeId();
    public static final Id CREDIT_NOTE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE).getRecordTypeId();
    public static final Id SCC_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_SCC).getRecordTypeId();
    public static final Id CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST).getRecordTypeId();
    
    public static final String STOCK_AND_SELL_CATEGORY_A = 'Stock & Sell - Category A';
    public static final String RECORD_TYPE_CUSTOM_FIELD_VALUE_CREDIT_NOTE = 'Credit Note';
    public Set<Id> integrationRecordTypeIds = new Set<Id>{WARRANTY_TYPE_RECORDTYPE_ID, CONTRACT_RECORDTYPE_ID, SCC_RECORDTYPE_ID};
    public static final String APPROVAL_STATUS_CANCELLED = 'Cancelled';

    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will update warehouse on company update
                   User Story => W-000278 Sprint 3
    Inputs:        list of new and old updated records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    4-12-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public void updateWarehouseOnCompanyUpdate(List<Claim_Requests__c> claimRequests,Map<Id,Claim_Requests__c> oldItems){
        List<Claim_Requests__c> finalClaimRequests=new List<Claim_Requests__c>();
        Id contractsRecordTypeId=CONTRACT_RECORDTYPE_ID;
        Set<String> companies=new Set<String>();
        for(Claim_Requests__c cr:claimRequests){
            if((cr.RecordTypeId==contractsRecordTypeId || cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID) && cr.Company__c!=oldItems.get(cr.Id).Company__c){
                finalClaimRequests.add(cr);
                if(cr.company__c!=null){
                    companies.add(cr.Company__c);
                }
                else{
                    cr.Location__c=null;
                }
            }
        }
        Map<String,Id> companyVsWarehouse=getWarehouse(companies);
        for(Claim_Requests__c cr:finalClaimRequests){
            cr.Location__c=companyVsWarehouse.containsKey(cr.Company__c)?companyVsWarehouse.get(cr.Company__c):null;
        }

    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will validate if a cancelled claim request is submitted for approval
    Inputs:        list of new and old updated records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    4-12-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public void validateSubmittedForApprovalClaimRequest(List<Claim_Requests__c> claimRequests,Map<Id,Claim_Requests__c> oldItems){
        for(Claim_Requests__c cr:claimRequests){
            if(cr.Approval_Status__c!=oldItems.get(cr.Id).Approval_Status__c && oldItems.get(cr.Id).Approval_Status__c=='Cancelled' && cr.Approval_Status__c=='Submitted For Approval'){
                cr.addError(System.label.Cancelled_Claim_Request_Cannot_Be_Submitted_For_Approval);
            }
        }
    }
    //18-08-2021
    // Check to create manual claim for rejected claim
    public void AllowManualClaimRequestCreation(List<Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> oldItems){
       
          //  if(oldItems.get(cr.Id).Approval_Status__c=='Submitted For Approval' )
          //  {              
                for(Claim_Requests__c claim : newItems) {
                system.debug('claim.Approval_Status__c');
                      
                  if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED ||
                    claim.Approval_Status__c == GlobalConstants.Rejected ) 
                   {
                     claim.Unique_Key__c = '';
                    system.debug('Inside if handleUniqueKeyPopulationOnContractRecords');
                   }
            }
                
         //   }
       
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will return Map of company and its warehouse record
                   User Story => W-000278 Sprint 3
    Inputs:        set of companies
    Test Class:   
    ---------------------------------------------------------------------------
    History
    4-12-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public Map<String,Id> getWarehouse(Set<String> companies){
        Map<String,Id> companyVsWarehouseSFId=new Map<String,Id>();
        Map<String,String> companyVsWarehouseExternalId=new Map<String,String>();
        Set<String> warehouseExternalIds=new Set<String>();
        Map<String,Id> externalIdVsSFId=new Map<String,Id>();
        for(Warehouse_defaults__mdt mdt:[Select Location_Id__c,Warehouse_code__c From Warehouse_defaults__mdt Where Location_Id__c in:companies]){
            if(mdt.Warehouse_code__c!=null){
                companyVsWarehouseExternalId.put(mdt.Location_Id__c,mdt.Warehouse_code__c);
            }
        }
        for(Warehouse__c warehouseRec:[Select Id,Warehouse__c From Warehouse__c Where Warehouse__c in:companyVsWarehouseExternalId.values()]){
            externalIdVsSFId.put(warehouseRec.Warehouse__c,warehouseRec.Id);
        }

        for(String company :companyVsWarehouseExternalId.keyset()){
            if(externalIdVsSFId.containsKey(companyVsWarehouseExternalId.get(company))){
                companyVsWarehouseSFId.put(company,externalIdVsSFId.get(companyVsWarehouseExternalId.get(company)));
            }
        }
        return companyVsWarehouseSFId;
    }   

     /*--------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Set Dealer Basic Amount For Warranty/Contracts ISR
                   
    Inputs:        list of new and old claimRequests
    ---------------------------------------------------------------------------
    History
    22-01-2021      Manasi Londhe     Initial Release
    --------------------------------------------------------------------------*/
    public void setDealerBasicAmount(List<Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> olditems){
        List<Claim_Requests__c> applicableClaims=new List<Claim_Requests__c>();
        Set<Id> associatedClaimIds=new Set<Id>();
        Map<Id,Claim_Requests__c> idVsAssociatedCLaim=new Map<Id,Claim_Requests__c>();
        if(olditems==null){
            system.debug('new Items---->'+newItems);
            for(Claim_Requests__c cr:newItems){
                
                system.debug('RecordTypeId----->'+cr.RecordTypeId);
                system.debug('INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID'+INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID);
                if(cr.RecordTypeId==INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID){
                    associatedClaimIds.add(cr.Claim_Request__c);
                    applicableClaims.add(cr);
                }
            }
        }
        else{
            for(Claim_Requests__c cr:newItems){
                if(cr.RecordTypeId==INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID
                && (cr.Dealer_Invoice_Basic_amount__c!=olditems.get(cr.Id).Dealer_Invoice_Basic_amount__c || cr.Quantity__c!=olditems.get(cr.Id).Quantity__c)){
                    applicableClaims.add(cr);
                    associatedClaimIds.add(cr.Claim_Request__c);
                }
            }
            system.debug('problem statement is here ' + associatedClaimIds.size());
        }
        if(associatedClaimIds.size()>0){
            idVsAssociatedCLaim=new Map<Id,Claim_Requests__c>([Select RecordTypeId,Total_Basic_Amount__c,Price__c From Claim_Requests__c 
                                                              Where Id in :associatedClaimIds
                                                              And RecordTypeId in (:WARRANTY_TYPE_RECORDTYPE_ID,:CONTRACT_RECORDTYPE_ID)]);
        }

        for(Claim_Requests__c cr:applicableClaims){
            if(idVsAssociatedCLaim.Keyset().contains(cr.Claim_Request__c)){
                claim_Requests__c associatedClaim=idVsAssociatedCLaim.get(cr.Claim_Request__c);
                Double dealerInvoiceBasicAmount;
                if((associatedClaim.RecordTypeId==CONTRACT_RECORDTYPE_ID || associatedClaim.RecordTypeId==WARRANTY_TYPE_RECORDTYPE_ID) 
                    && olditems!=null && cr.Dealer_Invoice_Basic_amount__c!=olditems.get(cr.Id).Dealer_Invoice_Basic_amount__c){
                        cr.addError(System.Label.Cannot_Edit_Dealer_Invoice_Basic_Amount_For_Warranty_Contracts_ISR);
                }
                if(associatedClaim.RecordTypeId==CONTRACT_RECORDTYPE_ID){
                    dealerInvoiceBasicAmount=(cr.Quantity__c!=null && associatedClaim.Total_Basic_Amount__c!=null)?(cr.Quantity__c*associatedClaim.Total_Basic_Amount__c):null;
                }
                else if(associatedClaim.RecordTypeId==WARRANTY_TYPE_RECORDTYPE_ID){
                    dealerInvoiceBasicAmount=(cr.Quantity__c!=null && associatedClaim.Price__c!=null)?(cr.Quantity__c*associatedClaim.Price__c):null;
                }
                cr.Dealer_Invoice_Basic_amount__c=dealerInvoiceBasicAmount;
                cr.Dealer_Invoice_Total_amount__c=cr.Dealer_Invoice_Basic_amount__c * 1.18;
            }
        }
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   
                   Before Update    
                   User Story => W-000287 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    25-11-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
     public void validateWarrantyClaimRequest(Map<Id,Claim_Requests__c> newItems, Map<Id,Claim_Requests__c> oldItems){
        List<Claim_Requests__c> requests = new List<Claim_Requests__c>();
        for(Claim_Requests__c cr : newItems.values()){
            if( cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID
               && (cr.Approval_Status__c != oldItems.get(cr.Id).Approval_Status__c && cr.Approval_Status__c == GlobalConstants.APPROVED)){
                requests.add(cr);
            }
        }
        
        if(requests != null && requests.size() > 0){
            validateWarrantyClaimRequest(requests);
        }
    }
    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   
                   Before Insert    
                   User Story => W-000287 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    25-11-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
    public void validateWarrantyClaimRequest(List<Claim_Requests__c> claimRequests){
        List<Claim_Requests__c> warrantyClaims=new List<Claim_Requests__c>();
        List<Id> assetIds = new List<Id>();
        List<Id> claimrequestIds = new List<Id>();
        for(Claim_Requests__c cr : claimRequests){
            if(cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && cr.Asset__c != null){
                warrantyClaims.add(cr);
                assetIds.add(cr.Asset__c);
                if(cr.Id != null)
                    claimrequestIds.add(cr.Id);
            }
        }
        //checkDuplicateEWPContractForWarrantyClaim(warrantyClaims);
        Map<Id, List<Claim_Requests__c>> assetIdVClaimRequests = getAssetIdVsClaimRequests(assetIds, claimrequestIds);
        if(!assetIdVClaimRequests.isEmpty()){
            for(Claim_Requests__c cr : claimRequests){
                if(assetIdVClaimRequests.containsKey(cr.Asset__c) && cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID){
                    if(assetIdVClaimRequests.get(cr.Asset__c).size() > 0){
                        cr.addError(System.Label.Approved_Warranty_Claim_Request_Error_Message);
                    }
                }
            }
        }
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   
                   User Story => W-000287 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    25-11-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
    public Map<Id, List<Claim_Requests__c>> getAssetIdVsClaimRequests(List<Id> assetIds, List<Id> claimrequestIds){
        Map<Id, List<Claim_Requests__c>> assetIdVsClaimRequests = new Map<Id, List<Claim_Requests__c>>();
        for(Claim_Requests__c cr : [Select Id, Approval_Status__c, Asset__c 
                                    From Claim_Requests__c
                                    Where Asset__c IN: assetIds And RecordTypeId = :WARRANTY_TYPE_RECORDTYPE_ID
                                    AND Id NOT IN: claimrequestIds And Approval_Status__c = :GlobalConstants.APPROVED]){
                                        if(assetIdVsClaimRequests.containsKey(cr.Asset__c)){
                                            assetIdVsClaimRequests.get(cr.Asset__c).add(cr);
                                        }else{
                                            assetIdVsClaimRequests.put(cr.Asset__c, new List<Claim_Requests__c>{cr});
                                        }
                                    }
        return assetIdVsClaimRequests;
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate price based on Item code and Pricebook populated on record
                   Before Update    
                   User Story => W-000287 Sprint 3
    Inputs:        Map<Id,Claim_Requests__c> newItems, Map<Id,Claim_Requests__c> oldItems
    Test Class:   
    ---------------------------------------------------------------------------
    History
    26-11-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
    public void populatePriceOnWarrantyClaim(Map<Id,Claim_Requests__c> newItems, Map<Id,Claim_Requests__c> oldItems){
        List<Claim_Requests__c> requests = new List<Claim_Requests__c>();
        for(Claim_Requests__c cr : newItems.values()){
            if(cr.Product_Item_Code__c != null 
                && cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID 
                && (cr.Product_Item_Code__c != oldItems.get(cr.Id).Product_Item_Code__c)){
                requests.add(cr);
            }
        }
        
        if(requests != null && requests.size() > 0){
            new ClaimRequestTriggerDefaultHelper().populatePriceOnWarrantyClaim(requests);
        }
    }   
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar 
    Company:       Salesforce
    Description:   Populate Primary dealer on Asset for offloaded contracts
                   After Insert & After update  
                   
    Inputs:        New & Old map of inserted records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    01-12-2020      Kishor Kumar     Initial Release
    -----------------------------------------------------------------------*/
    public void populatePrimaryDealerOnAsset(map<Id, Claim_Requests__c> claimRequests, map<Id, Claim_Requests__c> oldClaimRequests){
        map<String,Id> assetSerialNumberVsDealerId = new map<String,Id>();
        list<Asset> assetsToUpdate = new list<Asset>();
        
        //fetch asset & Dealer Ids
        for(Id crId : claimRequests.Keyset()){
            if(claimRequests.get(crId).Approval_Status__c == 'Approved' && (oldClaimRequests == null || (oldClaimRequests.containsKey(crId) 
                                                && (oldClaimRequests.get(crId).Approval_Status__c != claimRequests.get(crId).Approval_Status__c
                                                || oldClaimRequests.get(crId).Equipment_Serial_No__c!=null && !((oldClaimRequests.get(crId).Equipment_Serial_No__c).equalsIgnoreCase(claimRequests.get(crId).Equipment_Serial_No__c))
                                                || oldClaimRequests.get(crId).Business_Partner_Name__c != claimRequests.get(crId).Business_Partner_Name__c )
                                           )) && String.isNotBlank(claimRequests.get(crId).Equipment_Serial_No__c)   
                                            && claimRequests.get(crId).Business_Partner_Name__c != null){
                                                
                //Spilt comma separated Asset Serial Number & add it to map
                for(String assetSrNo : (claimRequests.get(crId).Equipment_Serial_No__c).Split(',')){
                    assetSerialNumberVsDealerId.put(assetSrNo.toUpperCase(), claimRequests.get(crId).Business_Partner_Name__c);
                }                                
                
            }
        }        

        //Logic to populate Primary dealers on Asset
        if(!assetSerialNumberVsDealerId.isEmpty()){
            for(Asset assetRec : [SELECT Id, Primary_Dealer__c, Equipment_Serial_No__c FROM Asset WHERE Equipment_Serial_No__c IN : assetSerialNumberVsDealerId.Keyset()]){
                assetRec.Primary_Dealer__c = assetSerialNumberVsDealerId.get(assetRec.Equipment_Serial_No__c.toUpperCase());
                assetsToUpdate.add(assetRec);
            }
        }
        
        try{
            update assetsToUpdate;
        }catch(Exception ex){
            Logger.logError('ClaimRequestTriggerHelper', 'populatePrimaryDealerOnAsset', '', ex);
        }
    }   

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Grants ISR edit access to branch champion.
                   User Story => W-000299 Sprint 3
    Inputs:        list of inserted and updated records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    08-12-2020      Manasi Londhe      Initial Release
    -----------------------------------------------------------------------*/
    public void grantISREditAccessToBranchChampion(List<Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> oldItems){
        List<Claim_Requests__c> claimRequestsApplicable=new List<Claim_Requests__c>();
        if(oldItems==null){
            for(Claim_Requests__c cr:newItems){
               if(cr.RecordTypeId==INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID && cr.Level_1__c!=null){
                   claimRequestsApplicable.add(cr);
               } 
            }
        }
        else{
            for(Claim_Requests__c cr:newItems){
                if(cr.RecordTypeId==INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID && cr.Level_1__c!=oldItems.get(cr.Id).Level_1__c && cr.Level_1__c!=null){
                    claimRequestsApplicable.add(cr);
                }
            }
        }
        List<Claim_Requests__Share> isrShares = new List<Claim_Requests__Share>();
        Set<Id> isrSharesToDeleteIds=new Set<Id>();
        List<Claim_Requests__Share> isrSharesToDelete = new List<Claim_Requests__Share>();
        for(Claim_Requests__c isr:claimRequestsApplicable){
            if(oldItems!=null){
                isrSharesToDeleteIds.add(isr.Id);
            }
            Claim_Requests__Share isrShare=new Claim_Requests__Share();
            isrShare.ParentId=isr.Id;
            isrShare.UserOrGroupId=isr.Level_1__c;
            isrShare.AccessLevel = 'Edit';
            isrShare.RowCause = Schema.Claim_Requests__Share.RowCause.Branch_Champion__c;
            isrShares.add(isrShare);
        }
        if(isrSharesToDeleteIds.size()>0){
            isrSharesToDelete=[Select Id,ParentId 
                               From Claim_Requests__Share 
                               Where ParentId In :isrSharesToDeleteIds
                               And  RowCause = :Schema.Claim_Requests__Share.RowCause.Branch_Champion__c];
            if(isrSharesToDelete.size()>0){
                Delete isrSharesToDelete;
            }
        }
        if(isrShares.size()>0){
            Insert isrShares;
        }
    }

    //When company is updated, evaluate Item code accordingly
    public void handleCompanyChangeOnSCCRecord(Map<Id,Claim_Requests__c> newMap,Map<Id,Claim_Requests__c> oldMap) {
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        List<Claim_Requests__c> recordsToProcess = new List<Claim_Requests__c>();
        for(Claim_Requests__c newRequest : newMap.values()) {
            if(newRequest.RecordTypeId == sccRecordTypeId && newRequest.Company__c != NULL && newRequest.Company__c != oldMap.get(newRequest.Id).Company__c) {
                recordsToProcess.add(newRequest);
            }
        }
        if(recordsToProcess.size() > 0) {
            new ClaimRequestTriggerDefaultHelper().populateItemCodeByCompanyOnSCCRecords(recordsToProcess);
        }
    }

    
    public void handleGodrejSalesOrderUpdated(Map<Id,Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> oldItems) {
        List<Claim_Requests__c> requestsWithOrderUpdated = new List<Claim_Requests__c>();
        Id claimRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        for(Claim_Requests__c newItem : newItems.values()) {
            if(newItem.RecordTypeId == claimRecordTypeId && newItem.Godrej_Sales_Order__c != NULL
            && newItem.Godrej_Sales_Order__c != oldItems.get(newItem.Id).Godrej_Sales_Order__c) {
                requestsWithOrderUpdated.add(newItem);
            }
        }
        if(requestsWithOrderUpdated.size() > 0) {
            new ClaimRequestTriggerDefaultHelper().populateGodrejSalesInvoiceOnClaimRequest(requestsWithOrderUpdated);
        }
    }
    
    public void integrationUpdateHelper(List<Claim_Requests__c> newClaimRequests, Map<Id, Claim_Requests__c> oldClaimRequests) {
        for (Claim_Requests__c each : newClaimRequests) {
            if (each.LN_PR_number__c != oldClaimRequests.get(each.Id).LN_PR_number__c && String.isNotBlank(each.LN_PR_number__c)) {
                each.PRNumber_Company__c = each.LN_PR_number__c + '_' + each.Company__c;
            }
            if (((each.Approval_Status__c != oldClaimRequests.get(each.Id).Approval_Status__c && each.Approval_Status__c == GlobalConstants.APPROVED_STATUS)
                || (each.Integration_Status__c == GlobalConstants.INTEGRATION_STATUS_READY_TO_SYNC && each.Integration_Status__c != oldClaimRequests.get(each.Id).Integration_Status__c))
                && integrationRecordTypeIds.contains(each.RecordTypeId) && (String.isBlank(each.Item_Unit__c) || String.isBlank(each.Business_Partner_Code__c)
                || String.isBlank(each.Company__c) || String.isBlank(each.Salary_Code__c) || each.Effective_Date_Time__c == null || each.Quantity__c == null
                || each.Quantity__c <= 0 || String.isBlank(each.Product_Item_Code__c) || String.isBlank(each.Requisition_Series__c) || String.isBlank(each.Location__c))) {
                each.addError(Label.PR_Integration_Validation);
            }
        }
    }

    public void handleBusinessPartnerUpdatedForClaimRequestSccAndCreditNote(Map<Id,Claim_Requests__c> newClaimRequests, Map<Id, Claim_Requests__c> oldClaimRequests) {
        Set<Id> accountsToQuery = new Set<Id>();
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        Id claimReqRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Id cNRecordTypeId = CREDIT_NOTE_RECORDTYPE_ID;

        for(Claim_Requests__c newClaim : newClaimRequests.values()) {
            if(newClaim.recordTypeId == claimReqRecordTypeId || newClaim.recordTypeId == SCC_RECORDTYPE_ID || newClaim.recordTypeId == cNRecordTypeId) {
                if(newClaim.Business_Partner_Name__c != oldClaimRequests.get(newClaim.Id).Business_Partner_Name__c && newClaim.Business_Partner_Name__c != NULL) {
                    accountsToQuery.add(newClaim.Business_Partner_Name__c);
                }
            }
        }
        if(accountsToQuery.size() > 0) {
            Map<Id,Account> accounts = new Map<Id,Account>([SELECT Id,Dealer_Type__c FROM Account WHERE Id IN :accountsToQuery]);
            for(Claim_Requests__c newItem : newClaimRequests.values()) {
                if(newItem.recordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimReqRecordTypeId || newItem.recordTypeId == cNRecordTypeId ) {
                    if(newItem.Business_Partner_Name__c != oldClaimRequests.get(newItem.Id).Business_Partner_Name__c && newItem.Business_Partner_Name__c != NULL) {
                        newItem.Dealer_Type__c = accounts.get(newItem.Business_Partner_Name__c).Dealer_Type__c;    
                    }
                }
            }
        }
    }
    
    //Unique key is populated based on record type. Helps prevent duplicate records
    public void populateUniqueKeyValueOnNewClaimRequestRecord(List<Claim_Requests__c> newItems) {
        List<Claim_Requests__c> sccAndCreditNoteRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> warrantyRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> isrRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> contractRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> claimRequestRecords = new List<Claim_Requests__c>();
        Set<Id> associatedClaimsForIsrRecords = new Set<Id>();

        for(Claim_Requests__c claim : newItems) {
            if(claim.RecordTypeId == SCC_RECORDTYPE_ID || claim.RecordTypeId == CREDIT_NOTE_RECORDTYPE_ID) {
                sccAndCreditNoteRecords.add(claim);
            } else if(claim.RecordTypeId == INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID) {
                isrRecords.add(claim);
                associatedClaimsForIsrRecords.add(claim.Claim_Request__c);
            } else if(claim.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && claim.Approval_Status__c == GlobalConstants.APPROVED) {
                warrantyRecords.add(claim);
            } else if(claim.RecordTypeId == CONTRACT_RECORDTYPE_ID) {
                contractRecords.add(claim);
            } else if(claim.RecordTypeId == CLAIM_REQUEST_RECORDTYPE_ID) {
                claimRequestRecords.add(claim);
            }   
        }
        if(sccAndCreditNoteRecords.size() > 0) {
            handleUniqueKeyPopulationOnSccAndCreditNoteRecords(sccAndCreditNoteRecords);
        }
        if(isrRecords.size() > 0) {
            handleUniqueKeyPopulationOnIsrRecords(isrRecords, associatedClaimsForIsrRecords);
        }
        if(warrantyRecords.size() > 0) {
            handleUniqueKeyPopulationForWarrantyRecords(warrantyRecords);
        }
        if(contractRecords.size() > 0) {
            system.debug('Calllllllllllllllll handleUniqueKeyPopulationOnContractRecords');
            handleUniqueKeyPopulationOnContractRecords(contractRecords);
        }
        if(claimRequestRecords.size() > 0) {
            handleUniqueKeyPopulationForClaimRequestRecords(claimRequestRecords);
        }
    }

    public void populateUniqueKeyValueOnUpdatedClaimRequestRecord(Map<Id,Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> oldItems) {
        List<Claim_Requests__c> sccAndCreditNoteRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> warrantyRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> isrRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> contractRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> claimRequestRecords = new List<Claim_Requests__c>();
        Set<Id> associatedClaimsForIsrRecords = new Set<Id>();
         system.debug('Inside populateUniqueKeyValueOnUpdatedClaimRequestRecord');
        for(Claim_Requests__c claim : newItems.values()) {
            if((claim.RecordTypeId == SCC_RECORDTYPE_ID || claim.RecordTypeId == CREDIT_NOTE_RECORDTYPE_ID) 
            && claim.Claim_Request__c != NULL && claim.Claim_Request__c != oldItems.get(claim.Id).Claim_Request__c) {
                sccAndCreditNoteRecords.add(claim);
            } else if(claim.RecordTypeId == INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID 
            && claim.Claim_Request__c != NULL && claim.Claim_Request__c != oldItems.get(claim.Id).Claim_Request__c) {
                isrRecords.add(claim);
                associatedClaimsForIsrRecords.add(claim.Claim_Request__c);
            } else if(claim.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && claim.Approval_Status__c == GlobalConstants.APPROVED 
            && claim.Approval_Status__c != oldItems.get(claim.Id).Approval_Status__c) {
                warrantyRecords.add(claim);
            } else if(claim.RecordTypeId == CONTRACT_RECORDTYPE_ID && 
            ((claim.Business_Partner_Name__c != NULL && claim.Business_Partner_Name__c != oldItems.get(claim.Id).Business_Partner_Name__c) 
            || (claim.Service_Contract__c != NULL && claim.Service_Contract__c != oldItems.get(claim.Id).Service_Contract__c))
            ) {
                contractRecords.add(claim);
            } else if(claim.RecordTypeId == CLAIM_REQUEST_RECORDTYPE_ID 
            && ((claim.Order_Product__c != NULL && claim.Order_Product__c != oldItems.get(claim.Id).Order_Product__c) 
            || (claim.Godrej_Order_Product__c != NULL && claim.Godrej_Order_Product__c != oldItems.get(claim.Id).Godrej_Order_Product__c)) ) {
                claimRequestRecords.add(claim);
            }   
        }
        if(sccAndCreditNoteRecords.size() > 0) {
            handleUniqueKeyPopulationOnSccAndCreditNoteRecords(sccAndCreditNoteRecords);
        }
        if(isrRecords.size() > 0) {
            handleUniqueKeyPopulationOnIsrRecords(isrRecords, associatedClaimsForIsrRecords);
        }
        if(warrantyRecords.size() > 0) {
            handleUniqueKeyPopulationForWarrantyRecords(warrantyRecords);
        }
        if(contractRecords.size() > 0) {
           
            handleUniqueKeyPopulationOnContractRecords(contractRecords);
        }
        if(claimRequestRecords.size() > 0) {
            handleUniqueKeyPopulationForClaimRequestRecords(claimRequestRecords);
        }
    }

    public void handleUniqueKeyPopulationOnSccAndCreditNoteRecords(List<Claim_Requests__c> newItems) {
        for(Claim_Requests__c claim : newItems) {
            if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED) {
                claim.Unique_Key__c = '';
            } else {
                claim.Unique_Key__c = claim.Claim_Request__c;
            }
        }
    }

    public void handleUniqueKeyPopulationOnIsrRecords(List<Claim_Requests__c> newItems,Set<Id> associatedClaimIds) {
        Map<Id,Claim_Requests__c> idVsClaimRequest = new Map<Id,Claim_Requests__c>([SELECT Id,RecordTypeId FROM Claim_Requests__c WHERE Id IN :associatedClaimIds]);
        for(Claim_Requests__c claim : newItems) {
            if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED) {
                claim.Unique_Key__c = '';
            } else if(idVsClaimRequest.containsKey(claim.Claim_Request__c) && idVsClaimRequest.get(claim.Claim_Request__c).RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID) {
                claim.Unique_Key__c = claim.Claim_Request__c;
            }
        }
    }

    public void handleUniqueKeyPopulationOnContractRecords(List<Claim_Requests__c> newItems) {
    system.debug('Inside handleUniqueKeyPopulationOnContractRecords');
    
    
    system.debug('claim.Approval_Status__c');
    //18-08-2021
    // Check to create manual claim for rejected claim
        for(Claim_Requests__c claim : newItems) {
            if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED ||
            claim.Approval_Status__c == GlobalConstants.Rejected ) 
             {
                claim.Unique_Key__c = '';
                 system.debug('Inside if handleUniqueKeyPopulationOnContractRecords');
             } else {
                claim.Unique_Key__c = String.valueOf(claim.Service_Contract__c)+String.valueOf(claim.Business_Partner_Name__c);
             system.debug('Inside else handleUniqueKeyPopulationOnContractRecords');
            }
        }
    }

    public void handleUniqueKeyPopulationForWarrantyRecords(List<Claim_Requests__c> newItems){
        for(Claim_Requests__c claim : newItems) {
            if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED) {
                claim.Unique_Key__c = '';
            } else {
                claim.Unique_Key__c = claim.Asset__c+'Warranty';
            }
            
        }
    }

    public void handleUniqueKeyPopulationForClaimRequestRecords(List<Claim_Requests__c> newItems) {
        for(Claim_Requests__c claim : newItems) {
            if(claim.Approval_Status__c == APPROVAL_STATUS_CANCELLED) {
                claim.Unique_Key__c = '';
                system.debug('claim.Approval_Status__c');
            } else {
                if(claim.Order_Product__c != NULL) {
                    claim.Unique_Key__c = claim.Order_Product__c;
                } else if(claim.Godrej_Order_Product__c != NULL) {
                    claim.Unique_Key__c = claim.Godrej_Order_Product__c;
                }
            }
        }
    }

    public void updateApproversOnClaimRequestIfBranchOrAreaUpdated(Map<Id,Claim_Requests__c> newItems,Map<Id,Claim_Requests__c> oldItems) {
        List<Claim_Requests__c> claimWithAreaOrBranchUpdated = new List<Claim_Requests__c>();
        for(Claim_Requests__c claim : newItems.values()) {
            if(claim.RecordTypeId == CLAIM_REQUEST_RECORDTYPE_ID) {
                if((claim.Area_Code__c != oldItems.get(claim.Id).Area_Code__c && claim.Area_Code__c != NULL) 
                || (claim.Branch__c != oldItems.get(claim.Id).Branch__c && claim.Branch__c != NULL)) {
                    claimWithAreaOrBranchUpdated.add(claim);
                }
            }
        }
        if(claimWithAreaOrBranchUpdated.size() > 0) {
            new ClaimRequestTriggerApproverHelper().populateApproversOnClaimRequestRecords(claimWithAreaOrBranchUpdated);
        }
    }

    public void classifyNewRecordsAndPerformActions(List<Claim_Requests__c> newItems) {
        ClaimRequestTriggerDefaultHelper defaultHelper = new ClaimRequestTriggerDefaultHelper();
        ClaimRequestTriggerApproverHelper approverHelper = new ClaimRequestTriggerApproverHelper();
        ClaimRequestTriggerValidationHelper validationHelper = new ClaimRequestTriggerValidationHelper();
        List<Claim_Requests__c> claimRequestRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> sccRecordsAndCnRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> contractRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> warrantyRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> adhocRecords = new List<Claim_Requests__c>();
        List<Claim_Requests__c> isrRecords = new List<Claim_Requests__c>();

        for(Claim_Requests__c newItem : newItems) {
            if(newItem.RecordTypeId == CLAIM_REQUEST_RECORDTYPE_ID) {
                claimRequestRecords.add(newItem);
            } else if(newItem.RecordTypeId == SCC_RECORDTYPE_ID || newItem.RecordTypeId == CREDIT_NOTE_RECORDTYPE_ID) {
                sccRecordsAndCnRecords.add(newItem);
            } else if(newItem.RecordTypeId == CONTRACT_RECORDTYPE_ID) {
                contractRecords.add(newItem);
            } else if(newItem.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID) {
                warrantyRecords.add(newItem);
            } else if(newItem.RecordTypeId == ADHOC_CLAIM_REQUEST_RECORDTYPE_ID) {
                adhocRecords.add(newItem);
            } else if(newItem.RecordTypeId == INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID) {
                isrRecords.add(newItem);
            }
        }

        if(claimRequestRecords.size() > 0) {
            defaultHelper.populateAnnexureTypeOnClaimRequest(claimRequestRecords);
            defaultHelper.populateBundlePriceOnAnnexureARequests(claimRequestRecords);
            validationHelper.validateAnnexureAAndBClaimRequest(claimRequestRecords);
            defaultHelper.populateBusinessPartnerOnNewClaimRequestRecord(claimRequestRecords);
            approverHelper.populateApproversOnClaimRequestRecords(claimRequestRecords);
            defaultHelper.populateGodrejSalesInvoiceOnClaimRequest(claimRequestRecords);
            defaultHelper.populateCommissionOnAnnexureB(claimRequestRecords);
        }

        if(sccRecordsAndCnRecords.size() > 0) {
            defaultHelper.populateAnnexureTypeOnClaimRequest(sccRecordsAndCnRecords);
            approverHelper.populateApproversForCreditNoteAndSCCClaims(sccRecordsAndCnRecords);
            defaultHelper.populateMarketingManagerAndFinanceEmailOnCreditNote(sccRecordsAndCnRecords);
            defaultHelper.populateSCCActivitiesOnSCCRecords(sccRecordsAndCnRecords);
            defaultHelper.populateGodrejSalesInvoiceOnClaimRequest(sccRecordsAndCnRecords);
            defaultHelper.populateDefaultsOnSCCRecords(sccRecordsAndCnRecords);
        }

        if(contractRecords.size() > 0) {
            defaultHelper.prepopulateContractClaimRequestValues(contractRecords);
            approverHelper.populateApproversForAMC_CMC_ServiceContractsAndWarranty(contractRecords);
        }

        if(isrRecords.size() > 0) {
            approverHelper.populateISRApprovers(isrRecords);
        }

        if(warrantyRecords.size() > 0) {
            approverHelper.populateApproversForAMC_CMC_ServiceContractsAndWarranty(warrantyRecords);
            defaultHelper.populatePriceOnWarrantyClaim(warrantyRecords);
            defaultHelper.populateDefaultsOnWarrantyClaimFromAsset(warrantyRecords);
        }

        if(adhocRecords.size() > 0) {
            approverHelper.populateApproversForAdHocClaims(adhocRecords);
        }
    }
}