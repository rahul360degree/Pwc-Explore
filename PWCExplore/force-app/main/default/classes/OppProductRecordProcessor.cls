/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Class to contain business logic for Opportunity Product Trigger
Inputs:        NA
Test Class:    
History
23-04-2020      Kartik Shetty     Initial Release.
26-05-2020      Kartik Shetty     Added method to update Asset Serial Number.
03-06-2020      Kartik Shetty     Moved the product bundling logic to it's own helper class.
13-08-2020      Kartik Shetty     Fixed an issue in updateAssetSerialNumber method.
----------------------------------------------------------------------------*/
public class OppProductRecordProcessor{
    private Map<Id,Opportunity> IdVsOpportunity=new Map<Id,Opportunity>();
    public static Boolean fireSalesPriceValidation=true;
    private static Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>();

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to update Asset Serial Number field on Opportunity Line Item if Asset is populated.
    Inputs:        NA
    Test Class:    
    History
    26-05-2020      Kartik Shetty     Initial Release.
    13-08-2020      Kartik Shetty     Fixed an issue where if multiple opportunity line items share a common asset then it only updates 
                                      last / latest opportunity line item.
    ----------------------------------------------------------------------------*/
    public void updateAssetSerialNumber(List<OpportunityLineItem> opportunityLineItems) {
        Map<Id, List<OpportunityLineItem>> assetIdVSopportunityLineItem = new Map<Id, List<OpportunityLineItem>>();
        for(OpportunityLineItem oli : opportunityLineItems) {
            // Store opportunities that are using similar assets.
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            if(assetIdVSopportunityLineItem.containsKey(oli.Asset__c)) {
                oliList = assetIdVSopportunityLineItem.get(oli.Asset__c);
            }

            oliList.add(oli);
            assetIdVSopportunityLineItem.put(oli.Asset__c, oliList);
        }
        if(assetIdVSopportunityLineItem.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>([Select Id, SerialNumber FROM Asset WHERE Id IN :assetIdVSopportunityLineItem.keySet()]);

            // Update those Opportunity Line Items that have asset records populated.
            for(Id assetId : assetMap.keySet()) {
                Asset assetRecord = assetMap.get(assetId);
                List<OpportunityLineItem> oliList = assetIdVSopportunityLineItem.get(assetId);
                for(OpportunityLineItem oli : oliList) {
                    oli.Asset_Serial_Number__c = assetRecord.SerialNumber;
                }
            }
        }
    }

    // Main Function where processing for opportunity products related to MHE equipment type opportunity records is done.
    public void productBundlingLogicFor_MHE_Equipments(List<OpportunityLineItem> newRecords, String context) {
        MHEProductBundlingHelper helperObject = new MHEProductBundlingHelper();
        helperObject.mainFunction(newRecords, context);
    }
    
    /* Updates Sales Price (UnitPrice) on OpportunityLineItems if Market Pricelist is used
     * As Market Pricelist always has GST added, the Sales Price is removed with logic
     */
    public void updateSalesPrice(List<OpportunityLineItem> newLineItems) {
        Set<Id> pBEIds = new Set<Id>();
        for (OpportunityLineItem oppProduct : newLineItems) {
            pBEIds.add(oppProduct.PricebookEntryId);
        }
        Map<Id, PriceBookEntry> taxRateMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c FROM PriceBookEntry WHERE Id IN :pBEIds 
                                    AND PriceBook2.Market_Pricelist__c = true]);
        User loggedInUser=[Select Id,Persona__c,ContactId From User Where Id=:UserInfo.getUserId()];
        List<String> d2dPersonas=System.label.D2D_Personas.Split(';');
        // Will be true only if the related Pricebook is a Market Pricelist
        if (!taxRateMap.isEmpty()){
            for (OpportunityLineItem each : newLineItems) {
                if (taxRateMap.containsKey(each.PricebookEntryId) 
                   && taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c != null && taxRateMap.get(each.PricebookEntryId).UnitPrice != null && loggedInUser.Persona__c!=null && d2dPersonas!=null && !(d2dPersonas.contains(loggedInUser.Persona__c)) && loggedInUser.ContactId!=null
                   ) {
                    each.UnitPrice = ((taxRateMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                }
            }
        }
    }
    
     /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to validate Sales Price on before update
     Inputs:        Map<OppProducts>
    ----------------------------------------------------------------------------*/
    public void validateSalesPrice(Map<Id, OpportunityLineItem> newItems, Map<Id,OpportunityLineItem> oldItems){
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : newItems.values()){
            if(oli.unitPrice != oldItems.get(oli.Id).unitPrice){
                oppLineItems.add(oli);
            }
        }
        if(oppLineItems.size() > 0)
            validateSalesPrice(oppLineItems);
    }

    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to validate Sales Price on before insert -
                    for standard/SKU products other than generic and MRP.
                    For - MRP pricebook unitprice = PBE.unitprice minus tax
                          other pricebook unitprice = PBE.unitprice
     Inputs:        List<OppProducts>
    ----------------------------------------------------------------------------*/
    public void validateSalesPrice(List<OpportunityLineItem> newLineItems){
         //if profile(listed in custom label) is not allowed to edit SalesPrice then only validation should fire
        if(!IsProfileAllowedToEditSalesPrice() && fireSalesPriceValidation){
            Set<Id> pBEIds = new Set<Id>();
            Set<Id> optyIds = new Set<Id>();
            for (OpportunityLineItem oppProduct : newLineItems) {
                optyIds.add(oppProduct.OpportunityId);
                pBEIds.add(oppProduct.PricebookEntryId);
            }
            Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c, PriceBook2.Market_Pricelist__c, PriceBook2.Consumer_Pricelist__c FROM PriceBookEntry WHERE Id IN :pBEIds
                                                                                     And Product2.Is_Generic_Product__c = false]);
            User loggedInUser=[Select Id,Persona__c,ContactId From User Where Id=:UserInfo.getUserId()];
            List<String> d2dPersonas=System.label.D2D_Personas.Split(';');
            Map<Id, Opportunity> opptyMap = getOpportunities(optyIds);
            if (!priceBookEntryMap.isEmpty()){
                for (OpportunityLineItem each : newLineItems) {
                    if(priceBookEntryMap.containsKey(each.PricebookEntryId) && opptyMap.containsKey(each.OpportunityId)){
                        Decimal expectedUnitPrice=priceBookEntryMap.get(each.PricebookEntryId).UnitPrice;
                        if(loggedInUser.Persona__c!=null && d2dPersonas!=null && !(d2dPersonas.contains(loggedInUser.Persona__c)) && loggedInUser.ContactId!=null && priceBookEntryMap.get(each.PricebookEntryId).PriceBook2.Market_Pricelist__c && priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c!=null && priceBookEntryMap.get(each.PricebookEntryId).UnitPrice!=null){
                            expectedUnitPrice=((priceBookEntryMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                        }
                        // Added by Anupam mishra on 25/03/2022 to allow construction and locks users to modify Sales Price & Added by Sreekanth Jujare on 02/09/2022 to allow Interio B2B and SSD user to modify Salesprice.
                        if(((Decimal)each.unitPrice) != expectedUnitPrice && opptyMap.get(each.OpportunityId).Business_Unit__c != GlobalConstants.Locks_BUSINESS_UNIT  && opptyMap.get(each.OpportunityId).Business_Unit__c != GlobalConstants.INTERIO_BUSINESS_UNIT  && opptyMap.get(each.OpportunityId).Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT){
                            if(opptyMap.get(each.OpportunityId).SyncedQuoteId == NULL && opptyMap.get(each.OpportunityId).Business_Unit__c != GlobalConstants.Construction_BUSINESS_UNIT){ each.addError(System.Label.Order_SalesPrice_Validation_Error_Message);}
                        }
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to get MHE opportunities
     Inputs:        List<OppProducts>
    ----------------------------------------------------------------------------*/
    public Map<Id, Opportunity> getOpportunities(Set<Id> oppIds){
        return (new Map<Id, Opportunity>([Select Id, SyncedQuoteId,Business_Unit__c From Opportunity Where Id IN: oppIds AND RecordType.DeveloperName != :GlobalConstants.OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME])); //And RecordType.Name = :GlobalConstants.OPPORTUNITY_RECORDTYPE_MHE]));
    }
    
    public Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIds) {
        opportunityRecordMap = new Map<Id, Opportunity>([Select Id, SyncedQuoteId, RecordTypeId, Business_Unit__c, 
            WarehouseCode__c, AccountId,
            //Added by Praful - 22-Feb-2021
            Duration__c, Duration_Unit__c, Contract_Start_Date__C, Contract_End_Date__C
            FROM Opportunity Where Id IN: oppIds]);
        return opportunityRecordMap;
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method is responsible for checking if SalesPrice is allowed to edit
     Inputs:        NA
    ----------------------------------------------------------------------------*/
    private Boolean IsProfileAllowedToEditSalesPrice(){
        String profilesLabel = System.Label.Profiles_Allow_To_Edit_SalesPrice;
        List<String> profiles = profilesLabel.split('\\,');
        List<User> usr = [Select Id, Profile.Name From User Where Id = :UserInfo.getUserId() AND Profile.Name IN :profiles ];
        //If Profile mentioned in Custom Label is Current User's profile then allow to edit Sales Price
        if(usr.size() > 0) return true;
        return false;
    }
    
    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to autopopulate the warehouse lookup field in opportunity products by copying it from related Opportunity record.
     Inputs:        List<OpportunityLineItem>
    ----------------------------------------------------------------------------*/
    public void setDefaultWarehousesBasedOnOpportunity(List<OpportunityLineItem> newLineItems) {
        Set<Id> oppIds = new Set<Id>();
        for(OpportunityLineItem oppLineItem : newLineItems) {
            oppIds.add(oppLineItem.OpportunityId);
        }
        Map<Id, Opportunity> oppRecordMap = getOpportunityMap(oppIds);
        for(OpportunityLineItem oppLineItem : newLineItems) {
            Opportunity oppRecord = oppRecordMap.get(oppLineItem.OpportunityId);
            if(oppLineItem.Warehouse__c == null && oppRecord.WarehouseCode__c != null) {oppLineItem.Warehouse__c = oppRecord.WarehouseCode__c;}
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to autopopulate the warehouse lookup field in opportunity products.
     Inputs:        List<OpportunityLineItem>
    ----------------------------------------------------------------------------*/
    public void populateDefaultOpportunityProductWarehouses(List<OpportunityLineItem> newLineItems) {
        List<OpportunityLineItem> oppProductWarehousesToDefault = new List<OpportunityLineItem>();
        Set<Id> oppIds = new Set<Id>();
        for(OpportunityLineItem oppLineItem : newLineItems) {
            oppIds.add(oppLineItem.OpportunityId);
        }
        Map<Id, Opportunity> oppRecordMap = getOpportunityMap(oppIds);

        for(OpportunityLineItem oppProduct : newLineItems) {
            if(oppProduct.Warehouse__c == null) {
                oppProductWarehousesToDefault.add(oppProduct);
            }
        }

        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        if(oppProductWarehousesToDefault.size() > 0) {
            inventoryUtilityControllerObj.populateApplianceAndNormal_OppProduct_Warehouse(oppProductWarehousesToDefault, oppRecordMap);
        }

    }


    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to validate whether the currect warehouse lookup field is populated in opportunity products.
     Inputs:        Map<Id, OpportunityLineItem>, List<OpportunityLineItem>
    ----------------------------------------------------------------------------*/
    public void validateOpportunityProductWarehouses(Map<Id, OpportunityLineItem> newLineItemMap, List<OpportunityLineItem> oldLineItems) {
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();

        for(OpportunityLineItem oppProductRecord : newLineItemMap.values()) {
            opportunityIds.add(oppProductRecord.OpportunityId);
        }
        opportunityRecordMap = getOpportunityMap(opportunityIds);

        if(oldLineItems.size() == 0) {
            inventoryUtilityControllerObj.validateOpportunityProductWarehouses(newLineItemMap.values(), opportunityRecordMap);
        } else {
            List<OpportunityLineItem> oppProductWarehousesToValidate = new List<OpportunityLineItem>();

            for(OpportunityLineItem oldOppProductRecord : oldLineItems) {
                OpportunityLineItem newOppProductRecord = newLineItemMap.get(oldOppProductRecord.Id);
                if(newOppProductRecord.Warehouse__c != null && oldOppProductRecord.Warehouse__c != newOppProductRecord.Warehouse__c) {oppProductWarehousesToValidate.add(newOppProductRecord);}
            }
    
            if(oppProductWarehousesToValidate.size() > 0) {inventoryUtilityControllerObj.validateOpportunityProductWarehouses(oppProductWarehousesToValidate, opportunityRecordMap);}
        }
    }
    
    //Added by Praful - 22-Feb-2021
    public void populateDefaultDurationFields(List<OpportunityLineItem> newOLI){
        
        Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for(OpportunityLineItem oppProductRecord : newOLI) {
            opportunityIds.add(oppProductRecord.OpportunityId);
        }
        opportunityRecordMap = getOpportunityMap(opportunityIds);
        
        for(OpportunityLineItem oli : newOLI) {
            oli.Duration__c = opportunityRecordMap.get(oli.OpportunityId).Duration__c;
            oli.Duration_Unit__c = opportunityRecordMap.get(oli.OpportunityId).Duration_Unit__c;
            oli.Contract_Start_Date__C = opportunityRecordMap.get(oli.OpportunityId).Contract_Start_Date__C;
            oli.Contract_End_Date__C = opportunityRecordMap.get(oli.OpportunityId).Contract_End_Date__C;
        }
    }
  /*------------------------------------------------------------------------
     Author:        Varun Rajpoot & Anupam Mishra
     Company:       GITL
     Description:   Method to calculate Sales Amount and Sales Price on opportunity products.
     Inputs:        List<OpportunityLineItem>
    ----------------------------------------------------------------------------*/
    public void calculateSalesAmount(List<OpportunityLineItem> newLineItems){
        map<Id,Product2> productMap;
        set<Id> productset = new set<Id>();
        Map<string, decimal> OLRrecordmap = new Map<string, decimal>();
        Id opprId = newLineItems[0].OpportunityId; 
        List<Opportunity_Landed_rate__c> LandedRecords=[select Id,Name,Landed_rate__c,Related_Opportunity__c from Opportunity_Landed_rate__c where Related_Opportunity__c= :opprId];
        for(Opportunity_Landed_Rate__c OLR: LandedRecords){ OLRrecordmap.put(OLR.Name,OLR.Landed_rate__c);                  }
        for(OpportunityLineItem oppProduct :newLineItems){
            productset.add(oppProduct.Product2Id);
        }
        productMap = new map<Id,Product2>([select id,Type__c,Search_Key_II__c,Volume__c,Tax_Rate__c,Product_Category__c, Product_Sub_category__c from product2 where Id IN:productset]);
        try{
            for(OpportunityLineItem oppProduct :newLineItems){
                Product2 prod = productMap.get(oppProduct.Product2Id);  
                decimal landedRate = OLRrecordmap.get(prod.Type__c);
                oppProduct.Search_Key_II__c=prod.Search_Key_II__c;
                oppProduct.Type_Construction__c = prod.Type__c;
                oppProduct.Product_Sub_Category__c = prod.Product_Sub_Category__c;
                if((prod.Product_Category__c =='WPS' && prod.Product_Sub_Category__c=='RCM') || prod.Product_Category__c =='RMC'){
                    decimal SalesPrice =oppProduct.UnitPrice;
                    decimal taxRate =prod.Tax_Rate__c;
                    decimal Qty =oppProduct.Quantity;
                    SalesAmountAndBasicRateCalculation.SalesAmountTuff_RMC_RCM(oppProduct,SalesPrice,taxRate, Qty); 
                }else if(prod.Type__c==GlobalConstants.TUFF_Duroplast_Landed_Rate || prod.Type__c== GlobalConstants.TUFF_Easy_Fix_Landed_Rate || prod.Type__c== GlobalConstants.Broken_Blocks || prod.Type__c== GlobalConstants.TUFF_TILE_FIX_PREMIUM_20_KG ||
                           prod.Type__c== GlobalConstants.TUFF_TILEFIX_PREMIUM_40_KG || prod.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_20_KG || prod.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_40_KG || 
                           prod.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_20_KG || prod.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_40_KG){ 			  //Added condition for Tilefix product (SCF - 102)
                    if(landedRate != null && prod.Tax_Rate__c != null && oppProduct != null )
                        SalesAmountAndBasicRateCalculation.BasicRate_AAC_WPS(oppProduct,landedRate,prod.Tax_Rate__c);
                } else if(prod.Type__c==GlobalConstants.TUFF_ACC_Block_Landed_Rate){ 
                    Opportunity opportunity = new Opportunity(Id=oppProduct.OpportunityId); 
                    if(landedRate != null && prod.Tax_Rate__c != null  && prod.Volume__c != null)                  
                        SalesAmountAndBasicRateCalculation.BasicRatePerCbm_TuffAACBlock(Prod.Type__c, landedRate, opportunity); 
                        SalesAmountAndBasicRateCalculation.BasicRatePerUnit_TuffAccBlock(oppProduct,landedRate,prod.Tax_Rate__c,prod.Volume__c );                       
                }
            }
        }catch(Exception ex){
            Logger.logError('OppProductRecordProcessor', 'calculateSalesAmount', '', ex);
        }
    }
     /*------------------------------------------------------------------------
     Author:        Snehal W
     Company:       GITL
     Description:   called Autolaunch flow(Subflow_Populate_Opportunity_Product_and_Opportunity_Field_Values_for_Locks_B2B) on after delete event
     Test class :   OppProductRecordProcessorTest
     Last modified Date : 07-02-2024
    ----------------------------------------------------------------------------*/
    public void callAutoLaunchFlow(List<OpportunityLineItem> oldLineItems) {
        
        Id InterioB2BRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.OPPORTUNITY_Interio_B2B_RECORDTYPE).getRecordTypeId();
        
        String flowApiName = 'Subflow_Populate_Opportunity_Product_and_Opportunity_Field_Values_for_Locks_B2B';
        Map<String, Object> inputs = new Map<String, Object>();// To store input variables for the auto launch flow.
        
        Set<Id> opportunityIds = new Set<Id>();// To store Opportunity ID's
        for (OpportunityLineItem oli : oldLineItems) {
            opportunityIds.add(oli.OpportunityId);
        }
        
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([SELECT Id, RecordTypeId FROM Opportunity WHERE Id IN :opportunityIds]);// Retrieve records with the specified Opportunity Id and their associated recordtypeId 
        
        for (OpportunityLineItem oli : oldLineItems) {
            Opportunity opp = opportunitiesMap.get(oli.OpportunityId);// Retreive related opportunity from opportunitiesMap  
            if (opp != null && opp.RecordTypeId == InterioB2BRecordTypeId) {
                inputs.put('OppProductRecord', oli);
            }
        }
        try {
            Flow.Interview interview = Flow.Interview.createInterview(flowApiName, inputs);
            interview.start();
        } catch (Exception e) {
            // Handle exceptions and log error details
            System.debug('Flow execution failed: ' + e.getMessage());
        }
    }

    public virtual class OppProductRecordException extends Exception {}
}