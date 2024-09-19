public with sharing class ClaimRequestTriggerDefaultHelper {
    public static final Id WARRANTY_TYPE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_WARRANTY).getRecordTypeId();
    public static final Id ADHOC_CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_ADHOC).getRecordTypeId();
    public static final Id INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST).getRecordTypeId();
    public static final Id CONTRACT_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_CONTRACTS).getRecordTypeId();
    public static final Id CREDIT_NOTE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE).getRecordTypeId();
    public static final Id SCC_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_SCC).getRecordTypeId();
    public static final Id CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST).getRecordTypeId();
    public static final String SCC_DEFAULT_COMPANY_FLT = '2000';
    public static final String SCC_DEFAULT_COMPANY_WAREHOUSE = '2010';
    public static final String DEFAULT_WARRANTY_CONTRACT_CLAIM_COMPANY='5000';

    
    public void populateAnnexureTypeOnClaimRequest(List<Claim_Requests__c> newItems) {
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        Id claimReqRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Id cNRecordTypeId = CREDIT_NOTE_RECORDTYPE_ID;
        Set<Id> orderIds = new Set<Id>();
        
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.Godrej_Order_Product__c != NULL) {
                if(newItem.recordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimReqRecordTypeId || newItem.recordTypeId == cNRecordTypeId ) {
                    orderIds.add(newItem.Godrej_Order_Product__c);
                }
            }   
        }

        if(orderIds.size() > 0) {
            Map<Id,OrderItem> orderProducts = new Map<Id,OrderItem>([SELECT Id,Product_Storage_Classification__c,UnitPrice FROM OrderItem WHERE Id IN :orderIds]);
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.Godrej_Order_Product__c != NULL) {
                    if(newItem.recordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimReqRecordTypeId || newItem.recordTypeId == cNRecordTypeId ) {
                        OrderItem orderProduct = orderProducts.get(newItem.Godrej_Order_Product__c);
                        if(orderProduct != NULL) {
                            newItem.Annexure_Type__c = orderProduct.Product_Storage_Classification__c;
                        }
                    }
                }   
            }
        }
    }

    public void populateBundlePriceOnAnnexureARequests(List<Claim_Requests__c> newItems) {
        Set<Id> orderProductIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL) {
                orderProductIds.add(newItem.Order_Product__c);
                orderIds.add(newItem.Order__c);
            } else if(newItem.Godrej_Order_Product__c != NULL && newItem.Godrej_Sales_Order__c != NULL) {
                orderProductIds.add(newItem.Godrej_Order_Product__c);
                orderIds.add(newItem.Godrej_Sales_Order__c);
            }
        }

        if(orderProductIds.size() > 0) {
            Map<Id,Integer> orderItemVsSequenceNumbers = new Map<Id,Integer>();
            Set<Integer> sequenceNumbers = new set<Integer>();
            List<OrderItem> orderItems = [SELECT Id,OrderId,QuoteLineItemId,QuoteLineItem.Sequence_Number__c FROM OrderItem WHERE Id IN :orderProductIds];
            for(OrderItem orderItem : orderItems) {
                orderItemVsSequenceNumbers.put(orderItem.Id,Integer.valueOf(orderItem.QuoteLineItem.Sequence_Number__c));
                sequenceNumbers.add(Integer.valueOf(orderItem.QuoteLineItem.Sequence_Number__c));
            }

            List<OrderItem> orderItemsWithSameSequence = [SELECT Id,UnitPrice,Discount_Amount__c,ListPrice,OrderId,QuoteLineItemId,QuoteLineItem.Sequence_Number__c FROM OrderItem WHERE OrderId IN :orderIds AND QuoteLineItem.Sequence_Number__c IN :sequenceNumbers];
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL && orderItemVsSequenceNumbers.containsKey(newItem.Order_Product__c)) {
                    Integer seqNumber = orderItemVsSequenceNumbers.get(newItem.Order_Product__c);
                    Decimal total = 0;
                    for(OrderItem otherItem : orderItemsWithSameSequence) {
                        if(otherItem.Id != newItem.Order_Product__c && otherItem.OrderId == newItem.Order__c && seqNumber == Integer.valueOf(otherItem.QuoteLineItem.Sequence_Number__c)) {
                            total += (otherItem.UnitPrice - otherItem.Discount_Amount__c);
                        }
                    }
                    newItem.Secondary_Order_Product_Bundle_Price__c = total;
                } else if(newItem.Godrej_Order_Product__c != NULL && newItem.Godrej_Sales_Order__c != NULL && orderItemVsSequenceNumbers.containsKey(newItem.Godrej_Order_Product__c)) {
                    Integer seqNumber = orderItemVsSequenceNumbers.get(newItem.Godrej_Order_Product__c);
                    Decimal total = 0;
                    Decimal totalDiscount = 0;
                    for(OrderItem otherItem : orderItemsWithSameSequence) {
                        if(otherItem.OrderId == newItem.Godrej_Sales_Order__c && seqNumber == Integer.valueOf(otherItem.QuoteLineItem.Sequence_Number__c)) {
                            total += otherItem.ListPrice;
                            totalDiscount += otherItem.Discount_Amount__c;
                        }
                    }
                    newItem.First_Offer_Price__c = total;
                    newItem.Bundle_Discount__c = totalDiscount;
                }
            }
        }
    }

    //Category A can be Stock & Sell(Annexure A) or Non Stock & Sell(Annexure B)
    //For Annexure A : Order and Order Product are populated along with Godrej sales Order and godrej order product
    //For annexure B : Only Godrej Sales order and godrej Order product are populated
    public void populateBusinessPartnerOnNewClaimRequestRecord(List<Claim_Requests__c> newItems) {
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        Id claimReqRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Id cNRecordTypeId = CREDIT_NOTE_RECORDTYPE_ID;
        Set<Id> godrejOrderProducts = new Set<Id>();
        Set<Id> secondaryOrderProducts = new Set<Id>();
        
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.recordTypeId == claimReqRecordTypeId) {
                if(newItem.Annexure_Type__c != NULL) {
                    if(newItem.Annexure_Type__c.equalsIgnoreCase('Category A')) {
                        if(newItem.Order__c != NULL) {
                            godrejOrderProducts.add(newItem.Godrej_Order_Product__c);
                            secondaryOrderProducts.add(newItem.Order_Product__c);
                        } else {
                            if(newItem.Godrej_Sales_Order__c != NULL) {
                            }
                            if(newItem.Godrej_Order_Product__c != NULL) {
                                godrejOrderProducts.add(newItem.Godrej_Order_Product__c);
                            }
                        }
                    }
                    if(newItem.Annexure_Type__c.equalsIgnoreCase('Category B')) {
                        if(newItem.Godrej_Sales_Order__c != NULL) {
                            godrejOrderProducts.add(newItem.Godrej_Order_Product__c);
                        }
                    }
                }
                
            }
        }
        godrejOrderProducts.addAll(secondaryOrderProducts);
        if(godrejOrderProducts.size() > 0) {
            Map<Id,OrderItem> orderProducts = new Map<Id,OrderItem>([SELECT Id,UnitPrice,Discount_Amount__c,Quantity FROM OrderItem WHERE Id IN :godrejOrderProducts]);
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.recordTypeId == claimReqRecordTypeId) {
                    if(orderProducts.containsKey(newItem.Godrej_Order_Product__c)) {
                        OrderItem godrejOrderProduct = orderProducts.get(newItem.Godrej_Order_Product__c);
                        //Annexure A - Get quantity from Secondary Order Product
                        if(newItem.Order_Product__c != NULL && orderProducts.get(newItem.Order_Product__c) != NULL) {
                            newItem.Quantity__c = orderProducts.get(newItem.Order_Product__c).Quantity;
                        //Annexure B - Get quantity from Primary Order Product
                        } else if(newItem.Order_Product__c == NULL && orderProducts.containsKey(newItem.Godrej_Order_Product__c)) {
                            newItem.Quantity__c = orderProducts.get(newItem.Godrej_Order_Product__c).Quantity;
                        }
                    
                        if(godrejOrderProduct != NULL) {
                           newItem.Order_Booked_Price_in_LN__c = godrejOrderProduct.UnitPrice; 
                        }
                    }
                }
            }
        }

        Id loggedInUserId = UserInfo.getUserId();
        User loggedInUser  = [SELECT Id,ContactId,Contact.AccountId FROM User WHERE Id =: loggedInUserId];
        if(loggedInUser != NULL && loggedInUser.ContactId != NULL && loggedInUser.Contact.AccountId != NULL) {
            List<Account> loggedInUserAccount = [SELECT Dealer_Type__c FROM Account WHERE Id =: loggedInUser.Contact.AccountId];
            if(loggedInUserAccount.size() > 0) {
                for(Claim_Requests__c newItem : newItems) {
                    if(newItem.recordTypeId == claimReqRecordTypeId) {
                        if(newItem.Annexure_Type__c != NULL) {
                            newItem.Business_Partner_Name__c = loggedInUser.Contact.AccountId;
                            newItem.Dealer_Type__c = loggedInUserAccount[0].Dealer_Type__c;
                        }
                    }
                }
            }
        }

        Set<Id> accountsToQuery = new Set<Id>();
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.recordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimReqRecordTypeId || newItem.recordTypeId == cNRecordTypeId ) {
                if(newItem.Business_Partner_Name__c != NULL && String.isBlank(newItem.Dealer_Type__c)) {
                    accountsToQuery.add(newItem.Business_Partner_Name__c);       
                }
            }
        }

        if(accountsToQuery.size() > 0) {
            Map<Id,Account> accounts = new Map<Id,Account>([SELECT Id,Dealer_Type__c FROM Account WHERE Id IN :accountsToQuery]);
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.recordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimReqRecordTypeId || newItem.recordTypeId == cNRecordTypeId ) {
                    if(newItem.Business_Partner_Name__c != NULL && String.isBlank(newItem.Dealer_Type__c)) {
                        newItem.Dealer_Type__c = accounts.get(newItem.Business_Partner_Name__c).Dealer_Type__c;    
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will prepopulate claim values from service contract
                   User Story => W-000279 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    24-11-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public void prepopulateContractClaimRequestValues(List<Claim_Requests__c> claimRequests){
        List<Claim_Requests__c> ewpClaims=new List<Claim_Requests__c>();
        Set<Id> serviceContractIds=new Set<Id>();
        Set<String> companies=new Set<String>();
        Id contractRecordTypeId=CONTRACT_RECORDTYPE_ID;
        for(Claim_Requests__c request:claimRequests){
            if(request.RecordTypeId==contractRecordTypeId){
                serviceContractIds.add(request.Service_Contract__c);
                request.Company__c=DEFAULT_WARRANTY_CONTRACT_CLAIM_COMPANY;
                companies.add(request.company__c);
            }
        }
        Map<Id,ServiceContract> idVsSCRecord=getServiceContractData(serviceContractIds);
        for(Id scId:idVsSCRecord.Keyset()){
            if(idVsSCRecord.get(scId).Associated_Opportunity__r.Sales_Branch_Name__c!=null){
                companies.add(idVsSCRecord.get(scId).Associated_Opportunity__r.Sales_Branch_Name__c);
            }
        }
        Map<String,Id> companyVsWarehouse=getWarehouse(companies);
        for(Claim_Requests__c request:claimRequests){
            if(request.RecordTypeId==contractRecordTypeId){
                if(idVsSCRecord.containsKey(request.Service_Contract__c)){
                    ServiceContract scRec=idVsSCRecord.get(request.Service_Contract__c);
                    request.Customer_Name__c=scRec.AccountId;
                    request.Number_of_PM_Visits__c=scRec.Number_of_PM_Visits__c;
                    request.Area_Code__c=scRec.Associated_Opportunity__r.Area_Code__c;
                    
                    //request.Company__c=idVsSCRecord.get(request.Service_Contract__c).Associated_Opportunity__r.Sales_Branch_Name__c;
                    if( request.Company__c!=null)
                    request.Location__c=companyVsWarehouse.containsKey(request.Company__c)?companyVsWarehouse.get(request.Company__c):null;
                    if(request.Is_System_Generated__c){
                        request.Business_Partner_Name__c=scRec.Business_Partner__c;
                        request.Number_Of_Equipment__c=scRec.LineItemCount;
                        List<String> serialNos=new List<String>();
                        for(ContractLineItem item:scRec.ContractLineItems){
                            if(item.Asset.Equipment_serial_No__c!=null){
                                serialNos.add(item.Asset.Equipment_serial_No__c);
                            }
                        }
                        if(serialNos.size()>0){
                        string serialNo=String.join(serialNos, ',');
                        if(serialNo.length()>155){
                        string subSerialNo = serialNo.subString(0,155);
                        request.Equipment_Serial_No__c = subSerialNo.subString(0,subSerialNo.lastIndexOf(',')); 
                        }else {                                              
                            request.Equipment_Serial_No__c=String.join(serialNos, ',');
                          }
                        }                    
                    }
                    Integer tempQuantity;
                    if(scRec.Contract_Type__c==GlobalConstants.EWP_CONTRACT_TYPE){
                        ewpClaims.add(request);
                    }
                    if(scRec.Billing_Frequency__c!=null){
                        if(GlobalConstants.billingFreqVsQuantity.containsKey(scRec.Billing_Frequency__c)){
                            tempQuantity=GlobalConstants.billingFreqVsQuantity.get(scRec.Billing_Frequency__c);
                        }
                        else if(scRec.Billing_Frequency__c==GlobalConstants.BILLING_FREQUENCY_MONTHLY_M20 || scRec.Billing_Frequency__c==GlobalConstants.BILLING_FREQUENCY_MONTHLY_M10){
                            //Added plus 1 to resolve the error of 1 month less getting displayed in quantity
                            tempQuantity=Utility.getMonthsBetween(scRec.startDate,scRec.EndDate) + 1;
                        }
                        if(request.Is_System_Generated__c){
                            request.Quantity__c=tempQuantity;
                        }
                    }
                }
                else{
                     request.addError(System.label.Claim_Request_Cannot_be_Created);
                }
            }

        }
        if(ewpClaims.size()>0){
            checkDuplicateWarrantyClaimForEWPContracts(ewpClaims,idVsSCRecord);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will check duplicate EWP Contracts against a warranty for an Asset
                   Defectt => W-000700
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    24-11-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public Static void checkDuplicateWarrantyClaimForEWPContracts(List<Claim_Requests__c> claimRequests,Map<Id,ServiceContract> idVsSCRecord){  
        Set<String> equipmentSerialNos=new Set<String>();
        Set<String> equipmentSerialNosWithWarrantyClaims=new Set<String>();
        Map<String,Id> equipmentNoVsAssetId=new Map<String,Id>();
        for(Claim_Requests__c cr:claimRequests){
            if(idVsSCRecord.containsKey(cr.Service_Contract__c) 
               && idVsSCRecord.get(cr.Service_Contract__c).StartDate!=null 
               && idVsSCRecord.get(cr.Service_Contract__c).EndDate!=null 
               && cr.Equipment_Serial_No__c!=null){
                equipmentSerialNos.add(cr.Equipment_Serial_No__c);
            }
        }
        for(Claim_Requests__c existingWarrantyClaim:[Select Id,Asset__c,Asset__r.Equipment_Serial_No__c,Asset__r.Product_Purchased_Warranty_Start_Date__c,Asset__r.Product_Purchased_Warranty_End_Date__c,Asset__r.Status
                                                        From Claim_Requests__c
                                                        Where Asset__r.Equipment_Serial_No__c in :equipmentSerialNos
                                                        And RecordTypeId=: WARRANTY_TYPE_RECORDTYPE_ID
                                                        And Asset__r.Product_Purchased_Warranty_Start_Date__c!=null
                                                        And Asset__r.Product_Purchased_Warranty_End_Date__c!=null
                                                        And Asset__r.Product_Purchased_Warranty_Start_Date__c <= TODAY
                                                        And Asset__r.Product_Purchased_Warranty_End_Date__c >= TODAY
                                                        And Asset__r.Status= :GlobalConstants.ASSET_ACTIVE_STATUS
                                                        And Approval_Status__c!=:GlobalConstants.CANCELLED]){
                                                            if(!equipmentNoVsAssetId.containsKey(existingWarrantyClaim.Asset__r.Equipment_Serial_No__c)){
                                                                equipmentNoVsAssetId.put(existingWarrantyClaim.Asset__r.Equipment_Serial_No__c,existingWarrantyClaim.Asset__c);
                                                            }
                                                            equipmentSerialNosWithWarrantyClaims.add(existingWarrantyClaim.Asset__r.Equipment_Serial_No__c);

                                                        }
        Set<Id> scIds=new Set<Id>();
        for(Claim_Requests__c cr:claimRequests){
           if( cr.Equipment_Serial_No__c!=null
              && idVsSCRecord.containsKey(cr.Service_Contract__c)
              && equipmentSerialNosWithWarrantyClaims.contains(cr.Equipment_Serial_No__c)
              ){
                  if(!cr.Is_System_Generated__c){ 
                    cr.addError(System.label.Duplicate_Warranty_Claim);
                  }
                  else{
                      scIds.add(cr.Service_Contract__c);
                  }
              }
        }
       ServiceContractTriggerHelper.duplicateFoundSCIds=scIds;
       ServiceContractTriggerHelper.serialNoVsAssetId=equipmentNoVsAssetId;
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will check duplicate warranty against EWP Contracts for an Asset
                   Defect => W-000700
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    24-11-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public static void checkDuplicateEWPContractForWarrantyClaim(List<Claim_Requests__c> claims,Map<Id,Asset> idVsAsset){
        Set<Id> assetIds=new Set<Id>();
        Set<String> equipmentSerialNos=new Set<String>();
        Set<String> equipmentSerialNosHavingContractClaim=new Set<String>();
        for(Asset asset:idVsAsset.values()){
            if(asset.Equipment_Serial_No__c!=null && asset.Product_Purchased_Warranty_End_Date__c!=null && asset.Product_Purchased_Warranty_Start_Date__c!=null){
                equipmentSerialNos.add(asset.Equipment_Serial_No__c);
            }
        }
        for(claim_Requests__c cr:[Select Id,Equipment_Serial_No__c,Service_Contract__r.Contract_Type__c,Service_Contract__r.StartDate,Service_Contract__r.EndDate 
                                    From Claim_Requests__c 
                                    Where Equipment_Serial_No__c in :equipmentSerialNos
                                    And RecordTypeId=:CONTRACT_RECORDTYPE_ID
                                    And Service_Contract__r.Contract_Type__c=:GlobalConstants.EWP_CONTRACT_TYPE
                                    And Service_Contract__r.StartDate!=null
                                    And Service_Contract__r.EndDate!=null
                                    And Service_Contract__r.StartDate <= TODAY
                                    And Service_Contract__r.EndDate >= TODAY
                                    And Approval_Status__c!=:GlobalConstants.CANCELLED]){
            equipmentSerialNosHavingContractClaim.add(cr.Equipment_Serial_No__c);
        }
        Set<Id> duplicateEWPassetIds=new Set<Id>();
        for(Claim_Requests__c warranty:claims){
            Asset asset;
            if(warranty.Asset__c!=null && idVsAsset.containsKey(warranty.Asset__c)){
               asset=idVsAsset.get(warranty.Asset__c);
            }
            if(asset!=null
            && equipmentSerialNosHavingContractClaim.contains(idVsAsset.get(warranty.Asset__c).Equipment_Serial_No__c)
           ){
                if(!warranty.Is_System_Generated__c){
                    warranty.addError(System.label.Duplicate_EWP_Contract);
                }
                else{
                    duplicateEWPassetIds.add(warranty.Asset__c);
                }
            }
        }
        CreateWarrantyClaimRequestForAsset.duplicateEWPContractsAssetIds=duplicateEWPassetIds;
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate price based on Item code and Pricebook populated on record
                   Before Insert    
                   User Story => W-000287 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    26-11-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
    public void populatePriceOnWarrantyClaim(List<Claim_Requests__c> claimRequests){
        Map<Id, Double> itemCodeVsPrice = new Map<Id, Double>(); 
        for(Claim_Requests__c cr : claimRequests){
            if(cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && cr.Product_Item_Code__c != null){
                if(!itemCodeVsPrice.containsKey(cr.Product_Item_Code__c)){
                    itemCodeVsPrice.put(cr.Product_Item_Code__c, 0);
                }else {
                    itemCodeVsPrice.put(cr.Product_Item_Code__c, cr.Price__c);
                }
            }
        }
        
        for(PriceBookEntry pbe : [Select Id, Product2Id, Pricebook2Id, UnitPrice from PricebookEntry Where Pricebook2.Name = :Label.MHE_SF_Local_Contract_PB And Product2Id IN: itemCodeVsPrice.keySet()]){
            if(itemCodeVsPrice.containsKey(pbe.Product2Id)){
                itemCodeVsPrice.put(pbe.Product2Id, pbe.UnitPrice);
            }
        }
        
        if(!itemCodeVsPrice.isEmpty()){
            for(Claim_Requests__c cr : claimRequests){
                if(cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && itemCodeVsPrice.containsKey(cr.Product_Item_Code__c)){
                    cr.Price__c = itemCodeVsPrice.get(cr.Product_Item_Code__c);
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Populate defaults on Warranty Claims from Asset
                   Before Insert    
                   User Story => W-000287 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    01-12-2020      Shailja Mishra      Initial Release
    -----------------------------------------------------------------------*/
    public void populateDefaultsOnWarrantyClaimFromAsset(List<Claim_Requests__c> claimRequests){
        List<Id> assetIds = new List<Id>();
        Map<Id, Asset> idVsAsset = new Map<Id, Asset>();
        Set<String> companies = new Set<String>();
        for(Claim_Requests__c cr : claimRequests){
            if(cr.RecordTypeId == WARRANTY_TYPE_RECORDTYPE_ID && cr.Asset__c != null){
                assetIds.add(cr.Asset__c);
            }
        }
        
        if(assetIds.size() > 0){
            idVsAsset = new Map<Id, Asset>([Select Id, Product2.Name, AccountId, Area_Code__c, Primary_Dealer__c, Equipment_Serial_No__c, Date_of_Commissioning__c,Status,
                                            Product_Purchased_Warranty_End_Date__c,Product_Purchased_Warranty_Start_Date__c 
                                            From Asset 
                                            Where Id IN: assetIds]);
        }
        checkDuplicateEWPContractForWarrantyClaim(claimRequests,idVsAsset);
        companies.add(DEFAULT_WARRANTY_CONTRACT_CLAIM_COMPANY);
        Map<String,Id> companyVsWarehouse = getWarehouse(companies);
        if(!idVsAsset.isEmpty()){
            for(Claim_Requests__c cr : claimRequests){
                if(idVsAsset.containsKey(cr.Asset__c)){
                    if(idVsAsset.get(cr.Asset__c).Status==GlobalConstants.ASSET_ACTIVE_STATUS){
                        if (cr.Is_System_Generated__c) {
                            cr.Customer_Name__c = idVsAsset.get(cr.Asset__c).AccountId;
                            cr.Business_Partner_Name__c = idVsAsset.get(cr.Asset__c).Primary_Dealer__c;
                            cr.Area_Code__c = idVsAsset.get(cr.Asset__c).Area_Code__c;
                            cr.Equipment_Serial_No__c = idVsAsset.get(cr.Asset__c).Equipment_Serial_No__c;
                            cr.Date_of_Commissioning__c = Date.valueOf(idVsAsset.get(cr.Asset__c).Date_of_Commissioning__c);
                            cr.Equipment_Model__c = idVsAsset.get(cr.Asset__c).Product2.Name;
                        }
                        cr.Location__c = companyVsWarehouse.containsKey(DEFAULT_WARRANTY_CONTRACT_CLAIM_COMPANY) ? companyVsWarehouse.get(DEFAULT_WARRANTY_CONTRACT_CLAIM_COMPANY) : null;
                    }
                    else{
                        cr.addError(System.label.Inactive_Asset_Error_Message);
                    }
                }                
                
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Abhishek Chaturvedi
    Company:       Salesforce
    Description:   
                   User Story => W-000365 Sprint 3
    Inputs:        list of inserted records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    16-12-2020      Abhishek Chaturvedi      Initial Release
    -----------------------------------------------------------------------*/
    public void populateMarketingManagerAndFinanceEmailOnCreditNote(List<Claim_Requests__c> newItems) {
        Map<String,String> MHEDivisionVsMetadataMapping = new Map<String,String>{
            'Outright Equipment' => 'Marketing_Manager_Equipments',
            'Spare Parts' => 'Marketing_Manager_Parts',
            'Contracts' => 'Marketing_Manager_Contracts',
            'Equipment Rental' => 'Marketing_Manager_Rentals',
            'Godrej RenTRUST' => 'Marketing_Manager_Rentals',
            'Outright Sales' =>'Marketing_Manager_Equipments'

        };
        Id creditNoteRecordTypeId = CREDIT_NOTE_RECORDTYPE_ID;
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        Set<Id> sccRecordsToQuery = new Set<Id>();

        for(Claim_Requests__c newItem : newItems) {
            if(newItem.recordTypeId == creditNoteRecordTypeId || newItem.recordTypeId == sccRecordTypeId) {
                sccRecordsToQuery.add(newItem.Claim_Request__c);
            }
        }

        if(sccRecordsToQuery.size() > 0) {
            Map<Id,Claim_Requests__c> sccRecordMap = new Map<Id,Claim_Requests__c>([SELECT Id,Sanctioned_Amount__c,Order__r.MHE_Division__c,Order__r.Area__c,Order__c,Branch__c FROM Claim_Requests__c WHERE Id IN :sccRecordsToQuery]);
            Map<String,String> areaVsFinancialEmailAddressMap = new Map<String,String>();
            Set<String> mheDivisionsToQueryFromMetadata = new Set<String>();
            Set<String> areas = new Set<String>();
            for(Claim_Requests__c sccRecord : sccRecordMap.values()) {
                mheDivisionsToQueryFromMetadata.add(MHEDivisionVsMetadataMapping.get(sccRecord.Order__r.MHE_Division__c));
                areas.add(sccRecord.Branch__c);
            }

            List<Application_Settings__mdt> marketingUsers = [SELECT Id, DeveloperName, Value__c, Description__c 
                                                    FROM Application_Settings__mdt 
                                                    WHERE DeveloperName IN :mheDivisionsToQueryFromMetadata];

            Map<String,String> divisionVsUser = new Map<String,String>();
            for(Application_Settings__mdt userDivision : marketingUsers) {
                divisionVsUser.put(userDivision.DeveloperName,userDivision.Value__c);
            }

            List<Area_Code_Branch_Champion__mdt> areaBranchMetadata = [SELECT Id,DeveloperName,Finance_User_Email__c,Area_Code__c FROM Area_Code_Branch_Champion__mdt WHERE Area_Code__c IN :areas and BU_Division__c='MHE'];
            for(Area_Code_Branch_Champion__mdt branchMetadata : areaBranchMetadata) {
                areaVsFinancialEmailAddressMap.put(branchMetadata.Area_Code__c,branchMetadata.Finance_User_Email__c);
            }

            for(Claim_Requests__c newItem : newItems) {
                if(newItem.recordTypeId == creditNoteRecordTypeId) {
                    if(newItem.Claim_Request__c != NULL && sccRecordMap.get(newItem.Claim_Request__c) != NULL) {
                        Claim_Requests__c sccRecord = sccRecordMap.get(newItem.Claim_Request__c);
                        string financialUserEmail = areaVsFinancialEmailAddressMap.get(sccRecord.Branch__c);
                        string mheDivision = MHEDivisionVsMetadataMapping.get(sccRecord.Order__r.MHE_Division__c);
                        string marketingUser = divisionVsUser.get(mheDivision);
                        newItem.Marketing_Manager__c = marketingUser;
                        newItem.Finance_Email__c = financialUserEmail; 
                        newItem.CN_Amount__c = sccRecord.Sanctioned_Amount__c;
                    }
                }
                if(newItem.RecordTypeId == sccRecordTypeId) {
                    Claim_Requests__c sccRecord = sccRecordMap.get(newItem.Claim_Request__c);
                    string financialUserEmail = areaVsFinancialEmailAddressMap.get(sccRecord.Branch__c);
                    newItem.Finance_Email__c = financialUserEmail; 
                }
            }
        }
    }

    public void populateSCCActivitiesOnSCCRecords(List<Claim_Requests__c> newItems) {
        Set<Id> claimRequestsToQuery = new Set<Id>();
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.recordTypeId == sccRecordTypeId && newItem.Claim_Request__c != NULL) {
                claimRequestsToQuery.add(newItem.Claim_Request__c);
            }
        }
        if(claimRequestsToQuery.size() > 0){
            Map<Id,Claim_Requests__c> claimRequestRecords = new Map<Id,Claim_Requests__c>([SELECT Id,SCC_Activities__c FROM Claim_Requests__c WHERE Id IN :claimRequestsToQuery]);
            for(Claim_Requests__c newItem : newItems) {
                if(newItem.recordTypeId == sccRecordTypeId && newItem.Claim_Request__c != NULL) {
                    newItem.SCC_Activities__c = claimRequestRecords.get(newItem.Claim_Request__c).SCC_Activities__c;
                }
            }
        }
    }

    //To populate godrej sales invoice, get the orderreferencenumber on from the primary sales order.
    // Find a line item that has the same value on Order__c field and use the Billed_Sales_Outstanding record that it is a child of
    public void populateGodrejSalesInvoiceOnClaimRequest(List<Claim_Requests__c> newItems) {
        Set<Id> orderIds = new Set<Id>();
        Id claimRecRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        for(Claim_Requests__c newItem : newItems) {
            if((newItem.RecordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimRecRecordTypeId) && newItem.Godrej_Sales_Order__c != NULL) {
                orderIds.add(newItem.Godrej_Sales_Order__c);
            }
        }

        if(orderIds.size() > 0) {
            Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,OrderReferenceNumber FROM Order WHERE Id IN :orderIds]);
            Map<Id,String> orderIdVsExternalId = new Map<Id,String>();
            Set<String> externalIds = new Set<String>();
            Map<String,Id> externalIdVsInvoiceId = new Map<String,Id>();
            for(Order orderRec : orderMap.values()) {
                if(String.isNotBlank(orderRec.OrderReferenceNumber)) {
                    orderIdVsExternalId.put(orderRec.Id,orderRec.OrderReferenceNumber);
                    externalIds.add(orderRec.OrderReferenceNumber);
                }
            }
            if(externalIds.size() > 0) {
                Map<Id,Receivable__c> lineItems = new Map<Id,Receivable__c>([SELECT Id,Invoice__c,Order__c FROM Receivable__c WHERE Order__c IN :externalIds]);
                
                for(Receivable__c lineItem : lineItems.values()) {
                    if(!externalIdVsInvoiceId.containsKey(lineItem.Order__c)) {
                        externalIdVsInvoiceId.put(lineItem.Order__c,lineItem.Invoice__c);
                    }
                }
            }
            for(Claim_Requests__c newItem : newItems) {
                if((newItem.RecordTypeId == sccRecordTypeId || newItem.RecordTypeId == claimRecRecordTypeId) && newItem.Godrej_Sales_Order__c != NULL) {
                    if(orderIdVsExternalId.containsKey(newItem.Godrej_Sales_Order__c)) {
                       String externalId = orderIdVsExternalId.get(newItem.Godrej_Sales_Order__c);
                       if(externalIdVsInvoiceId.containsKey(externalId)) {
                            Id invoiceId = externalIdVsInvoiceId.get(externalId);
                            newItem.Godrej_Sales_Invoice__c = invoiceId;
                        } else if(newItem.RecordTypeId == sccRecordTypeId) {
                            newItem.addError(System.Label.InvoiceAssociationMandatoryForSCC);
                        } 
                    } else if(newItem.RecordTypeId == sccRecordTypeId) {
                        newItem.addError(System.Label.InvoiceAssociationMandatoryForSCC);
                    } 
                }
            }
        }
    }

    //For annexure B. Difference % = ((godrejOrderItem.UnitPrice - (godrejOrderItem.UnitPrice - godrejOrderItem.Discount_Amount__c))/godrejOrderItem.UnitPrice) * 100;
    //Commission is determined by the difference %. An application setting is used to state the ranges of difference % and the corresponding Commission %
    public void populateCommissionOnAnnexureB(List<Claim_Requests__c> newItems){
        Id claimReqRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        List<Application_Settings__mdt> applicationSettings = [SELECT Id,DeveloperName,Value__c FROM Application_Settings__mdt WHERE DeveloperName LIKE 'AnnexureBCommPercent%'];
        List<Claim_Requests__c> claimRequestsToUpdate = new List<Claim_Requests__c>();
        Set<Id> orderProductIds = new Set<Id>();
        Map<Id,OrderItem> orderProductMap = new Map<Id,OrderItem>();
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.RecordTypeId == claimReqRecordTypeId && newItem.Annexure_Type__c != NULL 
            && newItem.Order__c == NULL && newItem.Order_Product__c == NULL
            && newItem.Godrej_Order_Product__c != NULL) {
                orderProductIds.add(newItem.Godrej_Order_Product__c);
            }
        }

        if(orderProductIds.size() > 0) {
            orderProductMap = new Map<Id,OrderItem>([SELECT Id,UnitPrice,Discount_Amount__c FROM OrderItem WHERE Id IN :orderProductIds]);
        }

        for(Claim_Requests__c newItem : newItems) {
            if(newItem.RecordTypeId == claimReqRecordTypeId && newItem.Annexure_Type__c != NULL 
            && newItem.Order__c == NULL && newItem.Order_Product__c == NULL) {
                Decimal difference = ((newItem.First_Offer_Price__c - (newItem.First_Offer_Price__c - newItem.Bundle_Discount__c))/newItem.First_Offer_Price__c) * 100;

                for(Application_Settings__mdt setting : applicationSettings){
                    string recordName = setting.DeveloperName;
                    List<string> stringWithLimits = recordName.split('_');
                    integer lowerLimit = Integer.valueOf(stringWithLimits[1]);
                    integer upperLimit = Integer.valueOf(stringWithLimits[2]);
                    if(lowerLimit <= difference && difference <=  upperLimit) {
                        newItem.Commission__c =Decimal.valueOf(setting.Value__c);
                        break;
                    }
                }
            }
        }
    }

    //When a SCC record is created or company on an exisitng SCC record is updated, re-evaluate Item code.
    //Company can have 2 values, these 2 values are defined in a static string. Each company value has a corresponding Item code value.
    //If company is forklift, query the application settings to get default item code for forklift : SCCDefaultItemCodeForklift
    //Same for werehouse : SCCDefaultItemCodeWareHouse
    public void populateItemCodeByCompanyOnSCCRecords(List<Claim_Requests__c> newRequests) {
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        String forkliftString = '';
        String warehouseString = '';
        Set<String> applicationSettingsToQuery = new Set<String>{'SCCDefaultItemCodeForklift','SCCDefaultItemCodeWareHouse'};
        Map<String,String> applicationSettingMap = new Map<String,String>();
        Set<String> productCodesToQuery = new Set<String>();
        Map<String,String> productNameVsId = new Map<String,String>();
        for(Application_Settings__mdt applicationSetting : [SELECT Id,DeveloperName,Value__c FROM Application_Settings__mdt WHERE DeveloperName IN :applicationSettingsToQuery]) {
            if(applicationSetting.DeveloperName.equalsIgnoreCase('SCCDefaultItemCodeForklift')) {
                forkliftString = applicationSetting.Value__c;
                productCodesToQuery.add(forkliftString);
            } else if(applicationSetting.DeveloperName.equalsIgnoreCase('SCCDefaultItemCodeWareHouse')) {
                warehouseString = applicationSetting.Value__c;
                productCodesToQuery.add(warehouseString);
            }
        }
        if(productCodesToQuery.size() > 0) {
            for(Product2 product : [SELECT Id,Item__c FROM Product2 WHERE Item__c IN :productCodesToQuery]) {
                productNameVsId.put(product.Item__c, product.Id);
            }
        }
        for(Claim_Requests__c newRequest : newRequests) {
            if(newRequest.RecordTypeId == sccRecordTypeId) {
                if(productNameVsId.size() > 0) {
                    if(newRequest.Company__c == SCC_DEFAULT_COMPANY_FLT && String.isNotBlank(forkliftString) && productNameVsId.containsKey(forkliftString)) {
                        newRequest.Product_Item_Code__c = productNameVsId.get(forkliftString);
                    } else if(newRequest.Company__c == SCC_DEFAULT_COMPANY_WAREHOUSE && String.isNotBlank(warehouseString) && productNameVsId.containsKey(warehouseString)) {
                        newRequest.Product_Item_Code__c = productNameVsId.get(warehouseString);
                    }
                }
            }      
        }
    }

    //In SCC records, Item code, Location and Requisition have to be populated through consultation of Application Settings metadata.
    //Developer names of metadata records are known.
    //SCCDefaultLocation : A value of Warehouse__c field on Warehouse__c Object
    //SCCDefaultRequisitionSeries : Directly copied as text
    public void populateDefaultsOnSCCRecords(List<Claim_Requests__c> newClaimRequests) {
        Id sccRecordTypeId = SCC_RECORDTYPE_ID;
        String locationString = '';
        String requisitionSeries = '';
        List<Warehouse__c> defaultWarehouse = new List<Warehouse__c>();
        Set<String> applicationSettingsToQuery = new Set<String>{'SCCDefaultLocation','SCCDefaultRequisitionSeries'};
        Map<String,String> applicationSettingMap = new Map<String,String>();
        for(Application_Settings__mdt applicationSetting : [SELECT Id,DeveloperName,Value__c FROM Application_Settings__mdt WHERE DeveloperName IN :applicationSettingsToQuery]) {
            if(applicationSetting.DeveloperName.equalsIgnoreCase('SCCDefaultLocation')) {
                locationString = applicationSetting.Value__c;
            } else if(applicationSetting.DeveloperName.equalsIgnoreCase('SCCDefaultRequisitionSeries')) {
                requisitionSeries = applicationSetting.Value__c;
            }
        }
        if(String.isNotBlank(locationString)) {
            defaultWarehouse = [SELECT Id FROM Warehouse__c WHERE Warehouse__c =: locationString LIMIT 1];
        }
        
        for(Claim_Requests__c newRequest : newClaimRequests) {
            if(newRequest.RecordTypeId == sccRecordTypeId) {
                if(defaultWarehouse.size() > 0) {
                    newRequest.Location__c = defaultWarehouse[0].Id;
                }
                if(String.isNotBlank(requisitionSeries)) {
                    newRequest.Requisition_Series__c = requisitionSeries;
                }
            }
        }
        populateItemCodeByCompanyOnSCCRecords(newClaimRequests);
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

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   This method will return map of Service contract Id And its data.
                   User Story => W-000279 Sprint 3
    Inputs:        list of new records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    24-11-2020      Manasi Londhe     Initial Release
    -----------------------------------------------------------------------*/
    public static Map<Id,ServiceContract> getServiceContractData(Set<Id> serviceContractIds){
          Set<String> applicableContractTypes=new Set<String>{GlobalConstants.CMT_CONTRACT_TYPE,
                                                            GlobalConstants.CMP_CONTRACT_TYPE,
                                                            GlobalConstants.CMD_CONTRACT_TYPE,
                                                            GlobalConstants.CMG_CONTRACT_TYPE,
                                                            GlobalConstants.PMC_CONTRACT_TYPE,
                                                            GlobalConstants.EWP_CONTRACT_TYPE};
        return new Map<Id,ServiceContract>([Select Id,Name,Infor_Service_Contract_ID__c,AccountId,LineItemCount,startDate,EndDate,Billing_Frequency__c,MHE_Division__c,
                                           Associated_Opportunity__r.Area_Code__c,Associated_Opportunity__r.Sales_Branch_Name__c,Business_Partner__c,
                                            (Select Id,Serial_Number__c,Asset.Equipment_serial_No__c From ContractLineItems),Number_of_PM_Visits__c,Contract_Type__c
                                            From ServiceContract Where Contract_Type__c In :applicableContractTypes 
                                            And  MHE_Division__c = :GlobalConstants.MHE_DIVISION_CONTRACTS
                                            And Id in :serviceContractIds]);
    }
    
}