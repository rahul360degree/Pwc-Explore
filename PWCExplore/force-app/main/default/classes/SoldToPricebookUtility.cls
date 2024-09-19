/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 10-17-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class SoldToPricebookUtility{
    /* Method to set following defaults on Quote -
     * Sold To & Ship To BP - Quote's Account for secondary quotes and COCO/Dealer account/Quote's 
     *              account depending on the opportunity owner for primary quotes
     * Sold To Address - For B2B accounts, set this to primary Address by BP and for B2C, related address by BP
     * Ship To Address - Same as above, but only if ship to is set to true
     * Ship To GSTN - GSTIN from Tax number for related state (on ship to)
     * Sold To GSTN - GSTIN from Tax number for related state (on sold to)
     */
  public static void setSoldtoShiptoAtQuote(List<Quote> lstQuote,map<Id,Quote> mapOldQuote) {
        Id userId = Userinfo.getUserId();
        List<User> lstUser = new List<User>();
        List<Quote> lstQuoteToUpdate = new List<Quote>();
        Set<Id> setOppOwner = new Set<Id>();
        Map<Id,String> mapUserAccountId = new Map<Id,String> ();
        Set<String> allBranches = new Set<String>();
        Set<Id> setOpp = new Set<Id>();
        Set<String> allAccountIds = new Set<String>();
        Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>();
        Map<String, Address_by_BP__c> shipToAddressMap = new Map<String, Address_by_BP__c>();
        Map<String, Address_by_BP__c> soldToAddressMap = new Map<String, Address_by_BP__c>();
        Map<String, Address_by_BP__c> shipToAddressMapGSTN = new Map<String, Address_by_BP__c>();
        Map<String, Address_by_BP__c> soldToAddressMapGSTN = new Map<String, Address_by_BP__c>();
        Map<String, String> taxNumbersMap = new Map<String, String>();
        String fraAccountId = '';
        String branchChannel = '';
        String fraBranchName = '';
        String dealerBranchName = ''; //Added by Sreekanth Jujare for SSD
        Boolean isKitchenDealer=false;

        for (Quote oQuoteVar: lstQuote) {
            if (oQuoteVar.Opportunity_Owner__c != null && oQuoteVar.Transaction_type__c != null) {
                if (mapOldQuote!=null) {
                    if (mapOldQuote.get(oQuoteVar.Id).Opportunity_Owner__c != oQuoteVar.Opportunity_Owner__c
                       || mapOldQuote.get(oQuoteVar.Id).Transaction_type__c != oQuoteVar.Transaction_type__c
                       || mapOldQuote.get(oQuoteVar.Id).Sold_to_Address__c != oQuoteVar.Sold_to_Address__c
                       || mapOldQuote.get(oQuoteVar.Id).Ship_To_Address__c != oQuoteVar.Ship_To_Address__c) {
                        lstQuoteToUpdate.add(oQuoteVar);
                    }
                } else {
                      lstQuoteToUpdate.add(oQuoteVar);
                }
                //Added by Anupam Mishra to deal with Interio Kitchen Issue
                if(oQuoteVar.Transaction_type__c == 'Secondary' && oQuoteVar.Quote_Key__c== GlobalConstants.QUOTE_INTERIO_KITCHEN_QUOTEKEY && mapUserAccountId.get(userinfo.getUserId())!=''){
                    isKitchenDealer=true;
                }
                setOppOwner.add(oQuoteVar.Opportunity_Owner__c);
                setOpp.add(oQuoteVar.OpportunityId);
                allBranches.add(oQuoteVar.Sales_Branch_Name__c);
            }
        }
        //Dealer_Name__r.Id, Order_Type__c,Business_Unit__c are added in following query by Sreekanth Jujare for SSD
        for (Opportunity each : [SELECT Id, AccountId,Dealer_Name__r.Id,Business_Unit__c, Order_Type__c, Account.RecordType.Name,
                                 Sub_Division__c,Distributor_1__c,Sales_Branch_Name__c FROM Opportunity WHERE Id IN :setOpp]) {
            mapOpp.put(each.Id, each);
            allAccountIds.add(each.AccountId);
            //Following If condition added by Sreekanth Jujare for SSD Order Type Dealer billing
            //Else if condition added by rohit jadhav for Locks B2C ISTD
            If(each.Business_Unit__c == GlobalConstants.SSD_BUSINESS_UNIT && each.Order_Type__c ==GlobalConstants.DIRECT_BILLING_TO_DEALER){
                allAccountIds.add(each.Dealer_Name__r.Id); 
            }
            else if(each.Business_Unit__c == GlobalConstants.Locks_BUSINESS_UNIT && each.Sub_Division__c ==GlobalConstants.B2C_ISTD){
                allAccountIds.add(each.Distributor_1__c); 
            }
        }
        
        lstUser = [SELECT Id, Account__c, Contact.AccountId,Business_Unit__c  FROM User WHERE Id IN :setOppOwner]; //Added Business_Unit__c  by Shreela on 20th October 2022
        for (User oUser : lstUser) {
            if (oUser.Account__c != null) {
                mapUserAccountId.put(oUser.Id, oUser.Account__c);               
            } else if(oUser.Contact.AccountId != null ) { 
               mapUserAccountId.put(oUser.Id, oUser.Contact.AccountId); 
                   if(oUser.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT) //Added Business_Unit__c  check  by Shreela on 20th October 2022
                   fraAccountId = oUser.Contact.AccountId;        
            } else {
                mapUserAccountId.put(oUser.Id, '');
                
            }
        }
        allAccountIds.addAll(mapUserAccountId.values());

        // Get sold to and ship to address for following scenarios - 
        // B2B Accounts if Sold To and Ship To is set to true and address by BP is marked primary
        // B2C Accounts will only have one related address record, so always pick that
        // Use branch + account ID as key for B2B as B2B can have multiple addresses by branch
        for(Account each : [SELECT Id, RecordType.DeveloperName,
                                (SELECT Id, Ship_To__c, Sold_To__c, Branch__r.Branch_Name__c, Branch__r.Channel__c, Address_Code__r.State_Province__c,isPrimary__c
                                 FROM Addresses_by_BP__r 
                                 WHERE (Branch__r.Branch_Name__c IN :allBranches OR Account__r.RecordType.DeveloperName = :GlobalConstants.CustomerAccountRt)
                                 ORDER BY CreatedDate),
                                (SELECT Id, Tax_Number__c, State_Province__c, Business_Partner__c
                                 FROM Tax_Numbers__r
                                 WHERE Category__c = 'GSTIN')
                            FROM Account WHERE Id IN :allAccountIds]) {
                                
                                
            for (Address_by_BP__c eachAddress : each.Addresses_by_BP__r) {
                String branchName = '';
                if (eachAddress.Branch__r.Channel__c != Null)
                {
                   branchChannel = eachAddress.Branch__r.Channel__c;
                   fraBranchName = eachAddress.Branch__r.Branch_Name__c;
                }                    
               

                if (each.RecordType.DeveloperName != GlobalConstants.CustomerAccountRt) {
                    branchName = eachAddress.Branch__r.Branch_Name__c;
                    if (eachAddress.Ship_To__c && eachAddress.isPrimary__c) {
                        shipToAddressMap.put(each.Id + branchName, eachAddress);
                    }
                    if(eachAddress.Ship_To__c){
                        shipToAddressMapGSTN.put(each.Id +''+ eachAddress.Id, eachAddress);
                    }
                    if (eachAddress.Sold_To__c && eachAddress.isPrimary__c) {
                        soldToAddressMap.put(each.Id + branchName, eachAddress);
                       
          }
                      if(eachAddress.Sold_To__c){
                        soldToAddressMapGSTN.put(each.Id +''+ eachAddress.Id, eachAddress);
                    }

                } else {
                    if (eachAddress.isPrimary__c) {
                        shipToAddressMap.put(each.Id, eachAddress);
                        //Added by Anupam Mishra to deal with Interio Kitchen Issue
                        /* Added by Alpana for SIF-76 on 3rd October 2022
                           Added condition[Channel as COCO] to set default for CRA as internal Godrej user 
                           because they are provisioned as Partner User */ 
                        if ((branchChannel != GlobalConstants.ChannelFranchisee || branchChannel != GlobalConstants.ChannelCocoStores) && isKitchenDealer ==false )
                        {
                           soldToAddressMap.put(each.Id, eachAddress);
                        }
                    }
                }
            }
            for (Tax_Number__c eachTaxNumber : each.Tax_Numbers__r) {
                if (String.isNotBlank(eachTaxNumber.Business_Partner__c) && String.isNotBlank(eachTaxNumber.State_Province__c) && String.isNotBlank(eachTaxNumber.Tax_Number__c)) {
                    taxNumbersMap.put(eachTaxNumber.Business_Partner__c + eachTaxNumber.State_Province__c, eachTaxNumber.Tax_Number__c);
                }
            }            
        }
        for (Quote oQVar : lstQuoteToUpdate) {
            if (mapUserAccountId.containsKey(oQVar.Opportunity_Owner__c)) {
                Boolean isB2CQuote = mapOpp.get(oQVar.OpportunityId).Account.RecordType.Name == GlobalConstants.CustomerAccountRt;
                String sAccountId = mapUserAccountId.get(oQVar.Opportunity_Owner__c);
                String dealerAccId =  (mapOpp.get(oQVar.OpportunityId).Dealer_Name__c != null)?mapOpp.get(oQVar.OpportunityId).Dealer_Name__r.Id : null;//Added by Sreekanth Jujare for SSD
                if (String.isBlank(sAccountId)) {
                    sAccountId = mapOpp.get(oQVar.OpportunityId).AccountId;
                }
                //Following if condition added by rohit jadhav for Locks B2C ISTD
                if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.RECORDTYPE_Locks_B2C_ISTD){
                    sAccountId=mapOpp.get(oQVar.OpportunityId).Distributor_1__c!=null ? mapOpp.get(oQVar.OpportunityId).Distributor_1__c : null;
                }  
               //If condition is added by Sreekanth Jujare to skip for SSD and else if condition is for SSD
                if(oQVar.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD){
                    oQVar.Associated_Dealer__c = sAccountId;
                } 
                else if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && (oQVar.Transaction_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER || oQVar.Transaction_Type__c == GlobalConstants.R_SERIES_BILLING)){
                    oQVar.Associated_Dealer__c = dealerAccId;  
                }
                //Added by Alpana Sahay for SAEPB - 44
                if(!isB2CQuote && oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE
                  && !mapOpp.isEmpty() && mapOpp.get(oQVar.OpportunityId).AccountId!=null){
                    sAccountId = mapOpp.get(oQVar.OpportunityId).AccountId;
                 } //Ended by Alpana Sahay for SAEPB - 44
                

                // Set branch name only if account is B2C - as map uses only account ID as key
                String branchName = mapOpp.get(oQVar.OpportunityId).Account.Recordtype.Name == GlobalConstants.CustomerAccountRt ? 
                                    '' : mapOpp.get(oQVar.OpportunityId).Sales_Branch_Name__c;
                
                //Following If condition is added by Sreekanth Jujare for SSD Dealer Billings
                if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && oQVar.Sales_Branch_Name__c != null && oQVar.Transaction_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER){
                    dealerBranchName = oQVar.Sales_Branch_Name__c;
                }
                //Added by Anupam Mishra to deal with Interio Kitchen Issue 
                /* Added by Alpana for SIF-76 on 3rd October 2022
                   Added condition[Channel as COCO] to set default for CRA as internal Godrej user 
                   because they are provisioned as Partner User */                    
                if (System.label.Interio_B2B_Secondary.contains(oQVar.Transaction_type__c) || (oQVar.Transaction_type__c == 'Secondary' && (branchChannel != GlobalConstants.ChannelFranchisee || branchChannel != GlobalConstants.ChannelCocoStores)&& isKitchenDealer==false)) {
                    sAccountId = mapOpp.get(oQVar.OpportunityId).AccountId;
                }
                                
                //Updated by Pawan:: DE707:: Populate only if not selected by User
                if(oQVar.Sold_To_Business_Partner__c == null) {
                    oQVar.Sold_To_Business_Partner__c = sAccountId;
                    oQVar.Invoice_To__c  = sAccountId;
                }
                //Added by Amit for the service contract integration
                if(oQVar.Invoice_To__c == null) {
                    oQVar.Invoice_To__c = sAccountId;
                }
                
                //Updated by Pawan:: DE707:: Populate only if not selected by User    
                if(oQVar.Ship_To_Account__c == null)
                    oQVar.Ship_To_Account__c = sAccountId;
                
                //Following If condition is written by Sreekanth Jujare for SSD to set Dealer accounts in following fields
                if(oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD  && mapOpp.get(oQVar.OpportunityId).Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER){
                    oQVar.Sold_To_Business_Partner__c = dealerAccId;
                    oQVar.Ship_To_Account__c = dealerAccId;
                    oQVar.Invoice_To__c = dealerAccId;
                }
                // Updating account ID for B2C Quotes - this will be required for COCO
                // scenarios - this will ensure address is always retrieved by Account Id and not
                // Sold To
                if (isB2CQuote) {
                    sAccountId = mapOpp.get(oQVar.OpportunityId).AccountId;
                }
                 //Following SSD and Order Type conditions and else if condition added by Sreekanth Jujare for SSD     
                if (shipToAddressMap.containsKey(sAccountId + branchName) && mapOpp.get(oQVar.OpportunityId).Order_Type__c != GlobalConstants.DIRECT_BILLING_TO_DEALER ||shipToAddressMap.containsKey(dealerAccId + dealerBranchName)&& oQVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && mapOpp.get(oQVar.OpportunityId).Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER) {
                    //Updated by Pawan:: DE707:: Populate only if not selected by User    
                    if(oQVar.Ship_To_Address__c == null && mapOpp.get(oQVar.OpportunityId).Order_Type__c != GlobalConstants.DIRECT_BILLING_TO_DEALER){
                        oQVar.Ship_To_Address__c = shipToAddressMap.get(sAccountId + branchName).Id;
                    }
                    else if(!soldToAddressMap.isempty() && soldToAddressMap.get(dealerAccId + dealerBranchName)!= null && !mapOpp.isempty() && oQVar.Sold_To_Address__c == null && mapOpp.get(oQVar.OpportunityId).Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER){
                        oQVar.Sold_To_Address__c = soldToAddressMap.get(dealerAccId + dealerBranchName).Id;
                        oQVar.Ship_To_Address__c = soldToAddressMap.get(dealerAccId + dealerBranchName).Id;
                        oQVar.Invoice_To_Address__c = soldToAddressMap.get(dealerAccId + dealerBranchName).Id;
                    }
                }
                if (shipToAddressMap.containsKey(sAccountId + branchName)) {
                    //Updated by Pawan:: DE707:: Populate only if not selected by User    
                    if(oQVar.Ship_To_Address__c == null)
                        oQVar.Ship_To_Address__c = shipToAddressMap.get(sAccountId + branchName).Id;
                    
                }

                if(shipToAddressMapGSTN.containsKey(sAccountId+oQVar.Ship_To_Address__c)){
                    String stateCode = shipToAddressMapGSTN.get(sAccountId + oQVar.Ship_To_Address__c).Address_Code__r.State_Province__c;
                    if (String.isNotBlank(stateCode) && taxNumbersMap.containsKey(sAccountId + stateCode)) {
                        oQVar.Ship_To_GSTN__c = taxNumbersMap.get(sAccountId + stateCode);
                    }
                }
               //Added by Anupam Mishra to deal with Interio Kitchen Issue
                 /* Added by Alpana for SIF-76 on 3rd October 2022
                   Added condition[Channel as COCO] to set default for CRA as internal Godrej user 
                   because they are provisioned as Partner User  */ 
                   if (   (!soldToAddressMap.isEmpty() && ( soldToAddressMap.containsKey(sAccountId + branchName ) || soldToAddressMap.containsKey(fraAccountId + branchName) ))  && (branchChannel != GlobalConstants.ChannelFranchisee || branchChannel != GlobalConstants.ChannelCocoStores || isKitchenDealer==True)) { 
                    if(oQVar.Sold_to_Address__c == null){
                        if( soldToAddressMap.containsKey(sAccountId + branchName ) && ((branchChannel != GlobalConstants.ChannelFranchisee || branchChannel != GlobalConstants.ChannelCocoStores) && isKitchenDealer==false)){                          
                            oQVar.Sold_to_Address__c = soldToAddressMap.get(sAccountId + branchName).Id;
                        }                          
                        else if(soldToAddressMap.containsKey(fraAccountId + branchName )){ 
                            oQVar.Sold_to_Address__c = soldToAddressMap.get(fraAccountId + fraBranchName).Id;  
                        }  
                        
                    }
                    
                    if(soldToAddressMap.containskey(sAccountId + branchName) && (oQVar.Invoice_To_Address__c  == null && ((branchChannel != GlobalConstants.ChannelFranchisee || branchChannel != GlobalConstants.ChannelCocoStores) && isKitchenDealer== false))){
                        oQVar.Invoice_To_Address__c  = soldToAddressMap.get(sAccountId + branchName).Id;
                    }
                }

                if(soldToAddressMapGSTN.containsKey(sAccountId+oQVar.Sold_To_Address__c)){
                    String stateCode = soldToAddressMapGSTN.get(sAccountId + oQVar.Sold_To_Address__c).Address_Code__r.State_Province__c;
                    if (String.isNotBlank(stateCode) && taxNumbersMap.containsKey(sAccountId + stateCode)) {
                        oQVar.Sold_To_GSTN__c = taxNumbersMap.get(sAccountId + stateCode);                    
                    }
                }
            }
            
        }
    }

    /* Method to identify if user is an internal Godrej user
     * Internal Godrej comprises of both Internal users & D2D/Franchisee/COCO (who're provisioned as partners)
     */
    public static Map<Id, Boolean> getUserPersonaDetails(Map<Id, String> userToBranchMap) {
        Map<Id, Boolean> userMap = new Map<Id, Boolean>();
        Map<Id, List<Id>> partnerAccountToUserIdMap = new Map<Id, List<Id>>();
        for (User each : [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id IN :userToBranchMap.keySet()]) {
            if (String.isBlank(each.ContactId)) {
                // For all internal users, set to true
                userMap.put(each.Id, true);
            } else {
                // For all external users set to false and add another item later if D2D
                userMap.put(each.Id, false);
                if (partnerAccountToUserIdMap.containsKey(each.Contact.AccountId)) {
                    partnerAccountToUserIdMap.get(each.Contact.AccountId).add(each.Id);
                } else {
                    partnerAccountToUserIdMap.put(each.Contact.AccountId, new List<Id>{each.Id});
                }
            }
        }
         /*Added On 13-04-2021 for Interio B2C FRANCHISEE
          *Added By Alpana S
           Added condition to set Default PriceBook as Consumer Price list for the Franchisee */
           /* Added by Alpana for SIF-76 on 29th September 2022
              Added condition [Channel as COCO] to set Default PriceBook as Consumer Price list for the CRA */
        for (Account each : [SELECT Id, (SELECT Id, Branch_Name__c FROM Branches__r WHERE Branch_Name__c IN :userToBranchMap.values() 
                                         AND (Channel__c = :GlobalConstants.D2D_CHANNEL 
                                         OR Channel__c  = :GlobalConstants.ChannelFranchisee
                                         OR Channel__c  = :GlobalConstants.ChannelCocoStores
                                         )) 
                             FROM Account WHERE Id IN :partnerAccountToUserIdMap.keySet()]) {
            // If a Branch with Channel D2D/FRA/COC exists with the Sales Branch Names            
            if (!each.Branches__r.isEmpty()) {
                // Ideally, there should be only one branch, so though a for loop is used, the following code is executed only once
                for (Branch__c eachBranch : each.Branches__r) {
                    // For every partner user related to that partner account, if the branch name matches sales branch passed as param,
                    // update the map value
                    for (Id eachId: partnerAccountToUserIdMap.get(each.Id)) {
                        if (eachBranch.Branch_Name__c == userToBranchMap.get(eachId)) {
                            userMap.put(eachId, true);
                        }                        
                    }
                }
            }
        }
        return userMap;
    }
    
    
    /* Method to set price book on Opportunity during opportunity creation. Price book is defaulted based on this criteria:
     * 1. Internal Users - Default to Consumer Price list for the Business Unit
     * 2. Partner Users - Default to Market Price list for the Business Unit
     * 3. Door to Door - Default to Consumer Price list for the Business Unit
     * 
     * Modification Log
     * ----------------
     * Subhojit         May-20          Created
     * Joshna           May-26          Added Market Price List logic
     */
    public static void setPriceBookAtOpportunity(List<Opportunity> lstOpp){ 
        Set<String> setDivsion=new Set<String>();
        List<Pricebook2> lstCSPricebook=new List<Pricebook2>();
        Map<String,Id> mapConsumerPricebook=new Map<String,Id> ();
        Map<String,Id> mapMarketPricebook=new Map<String,Id> ();
        Map<String,String> mapMHEPBName=new Map<String,String>();
        mapMHEPBName.put(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT,Label.MHE_SF_Local_Equipment_PB);
        mapMHEPBName.put(GlobalConstants.MHE_SUB_DIVISION_CONTRACT,Label.MHE_SF_Local_Contract_PB);
        mapMHEPBName.put(GlobalConstants.MHE_SUB_DIVISION_RENTAL, Label.MHE_SF_Local_Rental_PB);
        Set<String> setD2DAccount = new Set<String>();
        Map<Id, String> ownerToSalesBranchMap = new Map<Id, String>();
        
        for (Opportunity oOppVar : lstOpp) {
            if (String.isNotBlank(ooppVar.Business_Unit__c)) {
                setDivsion.add(ooppVar.Business_Unit__c);
            }
            ownerToSalesBranchMap.put(oOppVar.OwnerId, oOppVar.Sales_Branch_Name__c);
        }
        Map<Id, Boolean> userPersonaMap = getUserPersonaDetails(ownerToSalesBranchMap);

        //Get Consumer & Market Pricebook
        lstCSPricebook = [select Id, Business_Unit__c, Consumer_Pricelist__c, Market_Pricelist__c from Pricebook2 
                          where (Consumer_Pricelist__c = true OR Market_Pricelist__c = true) and Business_Unit__c IN :setDivsion];
        for (Pricebook2 pbVar: lstCSPricebook) {
            if (pbVar.Consumer_Pricelist__c) {
                mapConsumerPricebook.put(pbVar.Business_Unit__c, pbVar.Id);
            }
            if (pbVar.Market_Pricelist__c) {
                mapMarketPricebook.put(pbVar.Business_Unit__c, pbVar.Id);
            }
        }
        lstCSPricebook = [select Id,Name from Pricebook2 where Name IN :mapMHEPBName.values()];
        for (Pricebook2 pbVar : lstCSPricebook) {
            if (pbVar.name == Label.MHE_SF_Local_Contract_PB) {
                mapConsumerPricebook.put(GlobalConstants.MHE_SUB_DIVISION_CONTRACT, pbVar.Id);
            } else if(pbVar.name==Label.MHE_SF_Local_Equipment_PB) {
                mapConsumerPricebook.put(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT, pbVar.Id);
            } else if(pbVar.name==Label.MHE_SF_Local_Rental_PB) {
                mapConsumerPricebook.put(GlobalConstants.MHE_SUB_DIVISION_RENTAL, pbVar.Id);
            }

        }
        
        for (Opportunity oppVar : lstOpp) {
            String sDivision=oppVar.Business_Unit__c;
            Id pricebookId;
            // If internal user, get from Consumer Pricelist
            if (userPersonaMap.containsKey(oppVar.OwnerId) && userPersonaMap.get(oppVar.OwnerId)) {
                pricebookId = mapConsumerPricebook.get(sDivision);
            } else {
                //else from Market Pricelist
                pricebookId = mapMarketPricebook.get(sDivision);
            }
            
            // For MHE, continue using labels unless it is parts. As by default pricebookId is set, it will be set for parts
            // The following if block only updates price book ID for MHE Equipment & Contract
            if(oppVar.Business_Unit__c == GlobalConstants.MHE_DIVISION_CODE){
                if(oppvar.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT &&
                        mapConsumerPricebook.containskey(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT)) {
                    pricebookId = mapConsumerPricebook.get(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT);
                } else if(oppvar.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_CONTRACT &&
                        mapConsumerPricebook.containskey(GlobalConstants.MHE_SUB_DIVISION_CONTRACT)) {
                    pricebookId = mapConsumerPricebook.get(GlobalConstants.MHE_SUB_DIVISION_CONTRACT);
                } else if(oppvar.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_RENTAL &&
                        mapConsumerPricebook.containskey(GlobalConstants.MHE_SUB_DIVISION_RENTAL)) {
                    pricebookId = mapConsumerPricebook.get(GlobalConstants.MHE_SUB_DIVISION_RENTAL);
                }
                //Added the else if to handle spare part opportunities created through Service. Pricebook should always get set to MRP Pricebook
                else if(oppvar.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_PARTS && 
                        oppvar.Service_Form__c != null){
                    pricebookId = mapMarketPricebook.get(sDivision);    
                }
                //End of code block to handle spare part opportunities created through Service. Pricebook should always get set to MRP Pricebook
            }
            //Added the else if to handle Kitchen opportunity pricebook to be defaulted to consumer pricelist
            else if (oppVar.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT && 
            oppVar.Interio_Sub_Division__c == GlobalConstants.INTERIO_KITCHEN){
                pricebookId = mapConsumerPricebook.get(sDivision);
            }
            if(oppVar.LOB_N__c !=GlobalConstants.Construction_LOB_RMC  && oppVar.LOB_N__c !=GlobalConstants.Construction_LOB_WPS){           
            oppVar.Pricebook2Id = pricebookId;
            } 
            //End of code block to handle Kitchen opportunity pricebook to be defaulted to consumer pricelist
        }
    }
    
    //added by pankaj on 13 aug for Ticket#30417363 — Pricelist for Dealer Annexure
    Public static String getOrderAnnextureType(id orderId){
        //Checking base product and storage classification
        List<orderItem> orderLine = [select id,Product2.Product_Storage_Clasification__c,Product2.Component_Type__c,Business_unit__c from orderitem where OrderId=:orderId and Product2.Component_Type__c='Base product'];
        if(orderLine != null && orderLine.size()>0){
             return orderLine[0].Product2.Product_Storage_Clasification__c;
        }
        else{
            return '';
        }
    }  
    //Ended by pankaj on 13 aug 
    
    public static void setDefaultAtOrder(List<Order> lstOrder){
        Id userId=userinfo.getUserId();
        Map<Id,String> mapAccountBranch=new  Map<Id,String>();
        Map<Id,Account> mapAccount=new map<Id,Account>();
        Map<Id,Id> mapAccountSoldToAddress=new map<Id,Id>();
        Map<Id,Id> mapAccountShipToAddress=new map<Id,Id>();
        Map<Id,String> mapAccountStateAddress=new map<Id,String>();
        Map<Id,Map<String,Id>> mapAccountBranchPricebook=new Map<Id,Map<String,Id>>();
        Map<Id,User> mapUser=new Map<Id,User>();
        List<Branch__c> lstBranch=new List<Branch__c> ();
        List<Address_by_BP__c> lstAddressByBP=new List<Address_by_BP__c> ();
        List<Account> lstAllAccount=new List<Account>();
        Map<Id,Account> mapB2CAccount=new Map<Id,Account> ();
        Map<Id,Account> mapB2BAccount=new Map<Id,Account> ();
        Map<Id,Order> mapMisisngSoldTo=new Map<Id,Order> ();
        Map<Id,Branch__c> mapBranch=new Map<Id,Branch__c>();
        Set<Id> setUserId=new Set<Id>();
        Set<String> setDivsion=new Set<String>();
        List<Pricebook2> lstCSPricebook=new List<Pricebook2>();
        Map<String,Id> mapConsumerPricebook=new Map<String,Id> ();
        Map<String, Id> mapMarketPricebook = new Map<String, Id>();
        //Update Line of Business && Area code
        Set<Id> orderSoldToAccount = new set<Id>();
        Map<String, Branch__c> logisticsVsBranch = new map<String, Branch__c>();
        Map<String, Order> logisticsVsOrder = new map<String, Order>();
        Map<Id, String> ownerToSalesBranchMap = new Map<Id, String>();
        Set<Id> setOppId=new Set<id>();
        Map<Id,opportunity> mapOpp=new Map<Id,opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Order orderVar : lstOrder) {
            accountIds.add(orderVar.AccountId);
            setUserId.add(orderVar.OwnerId);
            setUserId.add(orderVar.Internal_Sales_Representative__c);
            setUserId.add(orderVar.External_Sales_Representative__c);
            ownerToSalesBranchMap.put(orderVar.OwnerId, orderVar.Logistics_Company_Branch__c);
            if(orderVar.OpportunityId!=null)
             setOppId.add(orderVar.OpportunityId);
        }
        if(setOppId.size()>0)
          mapOpp=new Map<Id,opportunity>([select Id,MHE_Division__c from opportunity where Id In :setOppId]);
        Map<Id, Boolean> userPersonaMap = getUserPersonaDetails(ownerToSalesBranchMap);
        if (setUserId.size() > 0) {
            mapUser = new Map<Id,User>([select Id,account__c,contact.AccountId from User where Id In :setUserId]);
        }
        Map<Id,Account> customerAccounts = new Map<Id,Account>();
        if(accountIds.size() > 0){
            customerAccounts = new Map<Id,Account>([Select Id FROM Account 
                                                    WHERE Id IN:accountIds 
                                                    AND RecordType.DeveloperName =: GlobalConstants.CustomerAccountRt ]);
        }
        // For Primary Account from Account page directly
        for (Order orderVar : lstOrder) {
            String sAccountId;
            if  (orderVar.Record_Types__c!=null &&
                 !orderVar.Record_Types__c.contains('Secondary') && !orderVar.Record_Types__c.contains('Tertiary')){
                user oUser=mapUser.get(orderVar.OwnerId);
                if(oUser.Account__c!=null)
                    sAccountId=oUser.Account__c;
                else if (oUser.contact.AccountId!=null)
                    sAccountId=oUser.contact.AccountId;
                else if(!customerAccounts.containsKey(orderVar.AccountId))
                    sAccountId = orderVar.AccountId;
                
                //For MR, SoldToBp & ShipToAccount is defaulted in MaterialRequestManager class. 
                //For rest, default Sold_To_Business_Partner__c & Ship_To_Account__c through sAccountId
                if(orderVar.Service_Form__c == null){
                   orderVar.Sold_To_Business_Partner__c= sAccountId;
                   orderVar.Ship_To_Account__c=sAccountId;
                }
                 System.debug('sAccountId---ALPANA'+sAccountId);
               
            }
        }
        for(Order orderVar: lstOrder){
            if(orderVar.Logistics_Company_Branch__c!=null ) {
                mapAccountBranch.put(orderVar.Sold_to_Business_Partner__c,orderVar.Logistics_Company_Branch__c);
                mapAccountBranch.put(orderVar.Ship_To_Account__c,orderVar.Logistics_Company_Branch__c);
                mapAccountBranch.put(orderVar.AccountId,orderVar.Logistics_Company_Branch__c); // For B2C Scenario
            }
            if(orderVar.Business_Unit__c!=null ){
                String sDivision=orderVar.Business_Unit__c;
                setDivsion.add(sDivision);
            }
        }
     
        lstAllAccount=[select Id,recordtype.developerName from Account where Id IN :mapAccountBranch.keySet()];
        for (Account accVar: lstAllAccount){
            if(accVar.recordtype.developerName==GlobalConstants.CustomerAccountRt) {
                mapB2CAccount.put(accVar.Id,accVar);
            } else {
                mapB2BAccount.put(accVar.Id,accVar);
            }  
        }
        lstCSPricebook=[select Id,Business_Unit__c, Consumer_Pricelist__c, Market_Pricelist__c from Pricebook2 
                        where (Consumer_Pricelist__c=true OR Market_Pricelist__c = true) and Business_Unit__c IN :setDivsion];
        for(Pricebook2 pbVar: lstCSPricebook){
            if (pbVar.Consumer_Pricelist__c) {
                mapConsumerPricebook.put(pbVar.Business_Unit__c,pbVar.Id);
            }  
            if (pbVar.Market_Pricelist__c) {
                mapMarketPricebook.put(pbVar.Business_Unit__c, pbVar.Id);
            }
        }
        //For B2B  
        if(mapB2BAccount.size()>0){
            lstBranch=[select Id,Sales_Price_List__c,Business_Partner__c,Branch_Name__c,Business_Partner__r.recordtype.developerName,Business_Partner__r.Type,
                 Business_Partner__r.Currency__c,Area__c,Sales_office__c,Delivery_terms__c,Business_Partner__r.payment_terms__c,Sales_Order_Type__c,
                (select Id,Address_Code__c,Ship_To__c,Sold_To__c from Addresses_by_BP__r where isPrimary__c=true order by createddate desc limit 1) from Branch__c where Branch_Name__c In :mapAccountBranch.values()
                                        and Business_Partner__c In :mapB2BAccount.keySet()];

            for(Branch__c brVar: lstBranch){
                Id accId=brVar.Business_Partner__c;
                mapBranch.put(accId,brVar);
                Map<String,Id> mapBranchPricebook=new Map<String,Id>();
                if(brVar.Sales_Price_List__c!=null && brVar.Branch_Name__c!=null)
                    mapBranchPricebook.put(brVar.Branch_Name__c,brVar.Sales_Price_List__c);
                if(mapBranchPricebook.size()>0)
                    mapAccountBranchPricebook.put(accId,mapBranchPricebook);
                for(Address_by_BP__c addrBPVar: brVar.Addresses_by_BP__r){
                    if(addrBPVar.Sold_To__c)
                        mapAccountSoldToAddress.put(accId,addrBPVar.Id);
                    if(addrBPVar.Ship_To__c)
                        mapAccountShipToAddress.put(accId,addrBPVar.Id);  
                }
            }
            for(Order orderVar: lstOrder){
                String sDivision='';
                if(orderVar.Business_Unit__c!=null ){
                    sDivision=orderVar.Business_Unit__c;
                }
                if(orderVar.Related_Secondary_Order__c!=null)
                    orderVar.Sales_price_List__c=null;
                if(orderVar.Sold_To_Business_Partner__c!=null && mapBranch.containsKey(orderVar.Sold_To_Business_Partner__c)){
          if(orderVar.Delivery_terms__c == null)
            orderVar.Delivery_terms__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Delivery_terms__c;
                    
          if(orderVar.Order_Currency__c == null)
            orderVar.Order_Currency__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Business_Partner__r.Currency__c;
                    
          if(orderVar.Area__c == null)
            orderVar.Area__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Area__c;
                    
          if(orderVar.payment_terms__c == null)
            orderVar.payment_terms__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Business_Partner__r.payment_terms__c;
                    
          if(orderVar.Sales_office__c == null)
            orderVar.Sales_office__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Sales_office__c;
                    
          if(orderVar.Type == null)
            orderVar.Type=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Sales_Order_Type__c;
                }        
                if(orderVar.Associated_Dealer__c==null){
                    if(orderVar.Internal_Sales_Representative__c!=null &&
                            mapUser.containsKey(orderVar.Internal_Sales_Representative__c)){
                        user userTmpVar=mapUser.get(orderVar.Internal_Sales_Representative__c);
                        if(userTmpVar.account__c!=null)
                            orderVar.Associated_Dealer__c=userTmpVar.account__c;
                    } else if(orderVar.External_Sales_Representative__c!=null &&
                            mapUser.containsKey(orderVar.External_Sales_Representative__c)) {
                        user userTmpVar=mapUser.get(orderVar.External_Sales_Representative__c); 
                        if(userTmpVar.Contact.AccountId!=null)  
                            orderVar.Associated_Dealer__c=userTmpVar.Contact.AccountId;
                    }
                }
                if(orderVar.Sold_To_Business_Partner__c!=null && mapAccountBranchPricebook.containsKey(orderVar.Sold_To_Business_Partner__c)){
                    Map<String,Id> mapBranchPricebook=new Map<String,Id>();
                    mapBranchPricebook=mapAccountBranchPricebook.get(orderVar.Sold_To_Business_Partner__c);
                    if(orderVar.Logistics_Company_Branch__c!=null &&
                        mapBranchPricebook.containsKey(orderVar.Logistics_Company_Branch__c) && orderVar.Sales_Price_List__c==null) {
                        orderVar.Sales_Price_List__c= mapBranchPricebook.get(orderVar.Logistics_Company_Branch__c);
                        orderVar.pricebook2Id=orderVar.Sales_Price_List__c;

                    }
                }  
                if(orderVar.Sold_to_Business_Partner__c!=null && 
                   mapAccountSoldToAddress.containsKey(orderVar.Sold_to_Business_Partner__c)){
                    //Default from Quote if not then populate
                    if(orderVar.Sold_To_Address__c == null){
                      orderVar.Sold_To_Address__c=mapAccountSoldToAddress.get(orderVar.Sold_to_Business_Partner__c);    
                    }
                }
                if(orderVar.Ship_To_Account__c!=null && 
                   mapAccountShipToAddress.containsKey(orderVar.Ship_To_Account__c)
                  && orderVar.Ship_To_Address__c == null){
                    if ((orderVar.Related_Secondary_Order__c != null) && (orderVar.recordtypeid == System.Label.Primary_Order_Record_type )
                            && (orderVar.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT) 
                            && (orderVar.Sub_Division__c == GlobalConstants.B2C_SUBDIVISION) 
                    
                    )
                    {
                        Map <String, String> secOrderMap = new Map<String, String>();
                        for (Order o: [select id, Ship_To_Address__c from Order where id = :orderVar.Related_Secondary_Order__c]){
                            secOrderMap.put(o.id, o.Ship_To_Address__c);
                        }
                        if (secOrderMap.size() > 0){
                        orderVar.Ship_To_Address__c= secOrderMap.get(orderVar.Related_Secondary_Order__c);
                        }
                    }
                    else
                    {
                        orderVar.Ship_To_Address__c=mapAccountShipToAddress.get(orderVar.Ship_To_Account__c);
                    }
                    }
                    
                if(orderVar.Record_Types__c!=null && 
                   (orderVar.Record_Types__c.contains('Secondary') || orderVar.Record_Types__c.contains('Tertiary') )) {
                    if (userPersonaMap.containsKey(orderVar.OwnerId) && userPersonaMap.get(orderVar.OwnerId)) {
                          orderVar.Pricebook2Id = mapMarketPricebook.get(sDivision);
                    }  else if (orderVar.Pricebook2Id == null) {  
                        orderVar.Pricebook2Id = mapMarketPricebook.get(sDivision);  
                    }
                }
            }
        } 
        //For B2C
        if(mapB2CAccount.size()>0){
            map<String, String> rtMap = new map<String, String>();
            for(RecordType rt : [select Id, Name, DeveloperName from RecordType where sObjectType='Order']){
                rtMap.put(rt.Id, rt.DeveloperName);                                    
            }
            lstAddressByBP=[select Id,Ship_To__c,Sold_To__c,account__c,Address_Code__c,Address_Code__r.StateName__c ,isPrimary__c
                        from Address_by_BP__c where IsPrimary__c = true AND account__c In :mapB2CAccount.values() order by createddate ];
            for(Address_by_BP__c addrVar: lstAddressByBP){
                mapAccountSoldToAddress.put(addrVar.account__c,addrVar.Id);
                mapAccountShipToAddress.put(addrVar.account__c,addrVar.Id);
                if(addrVar.Address_Code__r.StateName__c!=null)  
                    mapAccountStateAddress.put(addrVar.Id,addrVar.Address_Code__r.StateName__c);
            }
            for(Order orderVar:lstOrder){
                String sStateFilterPB;
                String sDivision='';
                if(orderVar.Business_Unit__c!=null){
                    sDivision=orderVar.Business_Unit__c;
                }
                if(orderVar.Related_Secondary_Order__c!=null)
                    orderVar.Sales_price_List__c=null;
                if(orderVar.Sold_To_Business_Partner__c!=null && mapBranch.containsKey(orderVar.Sold_To_Business_Partner__c)){
          if(orderVar.Delivery_terms__c == null)
            orderVar.Delivery_terms__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Delivery_terms__c;
                    
          if(orderVar.Order_Currency__c == null)
            orderVar.Order_Currency__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Business_Partner__r.Currency__c;
                    
          if(orderVar.Area__c == null)
            orderVar.Area__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Area__c;
                    
          if(orderVar.payment_terms__c == null)
          orderVar.payment_terms__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Business_Partner__r.payment_terms__c;
                    
          if(orderVar.Sales_office__c == null)
            orderVar.Sales_office__c=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Sales_office__c;
                    
          if(orderVar.Type == null)
            orderVar.Type=mapBranch.get(orderVar.Sold_To_Business_Partner__c).Sales_Order_Type__c;
                }
                if(orderVar.Associated_Dealer__c==null){
                    if(orderVar.Internal_Sales_Representative__c!=null &&
                            mapUser.containsKey(orderVar.Internal_Sales_Representative__c)){
                        user userTmpVar=mapUser.get(orderVar.Internal_Sales_Representative__c);
                        if(userTmpVar.account__c!=null)
                            orderVar.Associated_Dealer__c=userTmpVar.account__c;
                    } else if(orderVar.External_Sales_Representative__c!=null &&
                            mapUser.containsKey(orderVar.External_Sales_Representative__c)){  
                        user userTmpVar=mapUser.get(orderVar.External_Sales_Representative__c); 
                        if(userTmpVar.Contact.AccountId!=null)  
                            orderVar.Associated_Dealer__c=userTmpVar.Contact.AccountId;
                    }
                }
                    if(orderVar.Ship_To_Address__c == null && mapAccountShipToAddress.containsKey(orderVar.AccountId)){
                        orderVar.Ship_To_Address__c=mapAccountShipToAddress.get(orderVar.AccountId);
                    }
                        
                    if(mapAccountSoldToAddress.containsKey(orderVar.AccountId) ){     
                        if(mapBranch.containsKey(orderVar.Sold_to_Business_Partner__c)){
                            if(mapBranch.get(orderVar.Sold_to_Business_Partner__c).Business_Partner__r.Type!=GlobalConstants.Franchisee){
                                //default from Quote if not then populate
                                if(orderVar.Sold_To_Address__c == null){
                                  orderVar.Sold_To_Address__c=mapAccountSoldToAddress.get(orderVar.AccountId);    
                                }                                  
                            }
                        } else {
                            //default from Quote if not then populate
                            if(orderVar.Sold_To_Address__c == null){
                              orderVar.Sold_To_Address__c=mapAccountSoldToAddress.get(orderVar.AccountId);
                            }
                        }
                    }
                    if(orderVar.Record_Types__c!=null && 
                       (orderVar.Record_Types__c.contains('Secondary') || orderVar.Record_Types__c.contains('Tertiary'))) {
                         orderVar.Pricebook2Id = mapMarketPricebook.get(sDivision);
                    }
            }
        }
        Map<String,String> mapMHEPBName=new Map<String,String>();
        mapMHEPBName.put(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT,Label.MHE_SF_Local_Equipment_PB);
        mapMHEPBName.put(GlobalConstants.MHE_SUB_DIVISION_CONTRACT,Label.MHE_SF_Local_Contract_PB);
         lstCSPricebook = [select Id,Name from Pricebook2 where Name IN :mapMHEPBName.values()];
          for (Pricebook2 pbVar : lstCSPricebook) {
            if (pbVar.name == Label.MHE_SF_Local_Contract_PB) {
                mapConsumerPricebook.put(GlobalConstants.MHE_SUB_DIVISION_CONTRACT, pbVar.Id);
            } else if(pbVar.name==Label.MHE_SF_Local_Equipment_PB) {
                mapConsumerPricebook.put(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT, pbVar.Id);
            }
        }
        //Update Line of Business && Area code
        for(Order orderVar : lstOrder){
            if(orderVar.Sold_to_Business_Partner__c != null){  
                if(String.isNotBlank(orderVar.Logistics_Company_Branch__c)){
                    orderSoldToAccount.add(orderVar.Sold_to_Business_Partner__c);
                    logisticsVsOrder.put(orderVar.Logistics_Company_Branch__c, orderVar);
                }
                if(orderVar.Business_Unit__c == GlobalConstants.MHE_DIVISION_CODE){
                    String ssubDivsion='';
                    if(OrderVar.OpportunityId!=null && mapOpp.containsKey(OrderVar.OpportunityId))
                        ssubDivsion=mapOpp.get(OrderVar.OpportunityId).MHE_Division__c;
                    if(ssubDivsion== GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT &&
                       mapConsumerPricebook.containskey(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT) && orderVar.RECORDTYPEID ==Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Secondary_Order').getRecordTypeId()) {
                           orderVar.Pricebook2Id = mapConsumerPricebook.get(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT);
                       }
                    
                    //start added by pankaj on 12 aug Ticket#30417363 — Pricelist for Dealer Annexure
                    else if(ssubDivsion== GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT &&
                       mapConsumerPricebook.containskey(GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT) && orderVar.RECORDTYPEID ==Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Primary_Order').getRecordTypeId() && orderVar.Related_Secondary_Order__c != null) {
                           String strAnnexture = String.valueOf(getOrderAnnextureType(orderVar.Related_Secondary_Order__c));
                           if(strAnnexture=='Category A'){
                                orderVar.Sales_Price_List__c = Label.Annexture_A_Pricebook;
                                orderVar.Pricebook2Id = Label.Annexture_A_Pricebook;
                           }else if(strAnnexture=='Category B')
                           {
                               orderVar.Sales_Price_List__c = Label.Annexture_B_Pricebook;
                               orderVar.Pricebook2Id = Label.Annexture_B_Pricebook;
                           }else {
                               orderVar.Sales_Price_List__c = Label.Annexture_A_Pricebook;
                               orderVar.Pricebook2Id = Label.Annexture_A_Pricebook;
                           } 
                          
                       }
                    //end added by pankaj on 12 aug
                    //Specific to Phase 3B, part of MR Creation (where MHE_Division = Parts and ServiceForm != null) 
                        else if(orderVar.MHE_Division__c == GlobalConstants.MHE_SUB_DIVISION_PARTS && orderVar.Pricebook2Id == null && orderVar.Service_Form__c != null){
                           // If internal user, get from Consumer Pricelist
                           if (userPersonaMap.containsKey(orderVar.OwnerId) && userPersonaMap.get(orderVar.OwnerId)) {
                               orderVar.Pricebook2Id = mapConsumerPricebook.get(orderVar.Business_Unit__c);
                           } else {
                               //else from Market Pricelist
                               orderVar.Pricebook2Id = mapMarketPricebook.get(orderVar.Business_Unit__c);
                           }
                       } 
                }
            }
        }
      
        if(orderSoldToAccount.size() > 0){
            for(Branch__c branch : [Select Branch_Name__c, Business_Partner__c, Area__c, Line_of_Business__c 
                                    FROM Branch__c 
                                    WHERE Business_Partner__c IN : orderSoldToAccount
                                    AND Branch_Name__c IN : logisticsVsOrder.keySet()]){
                for(Order orderRec : logisticsVsOrder.values()){
                    if(orderRec.Sold_to_Business_Partner__c == branch.Business_Partner__c &&
                        orderRec.Logistics_Company_Branch__c == branch.Branch_Name__c){
                        //logic to update LOB only if not populated
                        if(String.isBlank(orderRec.Line_of_Business__c))
                        orderRec.Line_of_Business__c = branch.Line_of_Business__c;
                        //logic to update Area Code only if not populated
                        if(String.isBlank(orderRec.Area__c))
                        orderRec.Area__c = branch.Area__c;
                    }                   
                }
            }
        }
    }
}