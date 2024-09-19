/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-19-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-19-2023   Varun Rajpoot   Initial Version
**/
public with sharing class OrderLineTriggerHelper {
    public void populateExchangeNotificationId(Map<Id, SObject> newItems) {
    Boolean isExchangeOrder = false;
    Set<Id> tobeUpdatedIds = new Set<Id>();
        for(OrderItem oli : (List<OrderItem>)newItems.values()) {
            if(null != oli.Old_Appliance_Brand__c || null != oli.Old_Appliance_Capacity__c 
            ||  null != oli.Old_Appliance_Colour__c ||  null != oli.Old_Appliance_Model__c 
            ){
                isExchangeOrder = true;
                tobeUpdatedIds.add(oli.orderId);
            }
        }
        //check if it is an exchange order
        if(isExchangeOrder) {
            //query order for branch details
            Map<Id,Order> ordersToBeUpdated = new Map<Id,Order>([select id,Logistics_Company_Branch__c  from Order 
            where id in: tobeUpdatedIds]);
        Set<String> branchNames = new Set<String>();
        //if the metadata contains the branch "All" it means that email id to be used for 
        //all the exchange notifications
        branchNames.add('All');
        for(Order order : ordersToBeUpdated.values()) {
        branchNames.add(order.Logistics_Company_Branch__c);
        }
        List<BranchEmailMapping__mdt> mappings = [select branch__c, email__c from BranchEmailMapping__mdt
        where branch__c in: branchNames];
        //Flag to be set true if Branch name "All" found in the custom 
        //metadata mapping
        
        Boolean isCommonEmailForAllBranches = false;
        Map<String,String> branchEmailMap = new Map<String,String>();
        for(BranchEmailMapping__mdt mapping : mappings) {
            if(mapping.branch__c == 'All') {
                //if All is found then break;
                isCommonEmailForAllBranches = true;
                branchEmailMap.put(mapping.branch__c, mapping.email__C);
            break;
            } 
            //else populate a map of branch vs email ids
            branchEmailMap.put(mapping.branch__c, mapping.email__C);

        }
        String branchName;
        
        if(isCommonEmailForAllBranches) {
            for(Order order : ordersToBeUpdated.values()) {
                order.ExchangeOrderNotificationEmail__c  = branchEmailMap.get('All');
            }
        } else {
            for(Order order : ordersToBeUpdated.values()) {
                order.ExchangeOrderNotificationEmail__c  = branchEmailMap.get(order.Logistics_Company_Branch__c);
            }
        }
            //Update orders
             update ordersToBeUpdated.values();  
        }
        
    }
    
    /* Updates Sales Price (UnitPrice) on OrderItem if Market Pricelist is used
     * As Market Pricelist always has GST added, the Sales Price is removed with logic
     */
    public void updateSalesPrice(List<OrderItem> newLineItems) {
        Set<Id> pBEIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem each : newLineItems) {
            pBEIds.add(each.PricebookEntryId);
            orderIds.add(each.OrderId);
        }
        Map<Id, Order> orderMap = getOrders(orderIds);
        Map<Id, PriceBookEntry> taxRateMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c FROM PriceBookEntry WHERE Id IN :pBEIds 
                                    AND PriceBook2.Market_Pricelist__c = true]);
        // Will be true only if the related Pricebook is a Market Pricelist
        if (!taxRateMap.isEmpty()){
            for (OrderItem each : newLineItems) {
                if (taxRateMap.containsKey(each.PricebookEntryId) 
                    && taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c != null 
                    && taxRateMap.get(each.PricebookEntryId).UnitPrice != null
                    && orderMap!=null 
                    && orderMap.containsKey(each.OrderId) 
                    && orderMap.get(each.OrderId).Sales_Type__c==GlobalConstants.SALES_TYPE_SECONDARY) {
                    each.UnitPrice = ((taxRateMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                }
            }
        }
    }
    
     /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to validate Sales Price on before update -
                    for standard/SKU products other than generic and MRP.
                    For - MRP pricebook unitprice = PBE.unitprice minus tax
                          other pricebook unitprice = PBE.unitprice
     Inputs:        Map<Id, OrderItem>, Map<Id,OrderItem> 
    ----------------------------------------------------------------------------*/
    public void validateSalesPrice(Map<Id, OrderItem> newItems, Map<Id,OrderItem> oldItems){
        List<OrderItem> orderItems = new List<OrderItem>();
        for(OrderItem oli : newItems.values()){
            if(oli.unitPrice != oldItems.get(oli.Id).unitPrice){
                orderItems.add(oli);
            }
        }
        if(orderItems.size() > 0)
            validateSalesPrice(orderItems);
    }

    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to validate Sales Price before Insert
     Inputs:        List<OrderItem>
    ----------------------------------------------------------------------------*/
    public void validateSalesPrice(List<OrderItem> newLineItems){
        //if profile(listed in custom label) is not allowed to edit SalesPrice then only validation should fire
        if(!IsProfileAllowedToEditSalesPrice()){
            Set<Id> pBEIds = new Set<Id>();
            Set<Id> orderIds = new Set<Id>();
            for (OrderItem oi : newLineItems) {
                orderIds.add(oi.OrderId);
                pBEIds.add(oi.PricebookEntryId);
            }
            Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c, PriceBook2.Market_Pricelist__c, PriceBook2.Consumer_Pricelist__c FROM PriceBookEntry WHERE Id IN :pBEIds
                                                                                     And Product2.Is_Generic_Product__c = false]);
            Map<Id, Order> orderMap = getOrders(orderIds);
            if (!priceBookEntryMap.isEmpty()){
                for (OrderItem each : newLineItems) {
                    if(priceBookEntryMap.containsKey(each.PricebookEntryId) && orderMap.containsKey(each.OrderId)){
                        Decimal expectedUnitPrice=priceBookEntryMap.get(each.PricebookEntryId).UnitPrice;
                        if(orderMap.get(each.OrderId).Sales_Type__c==GlobalConstants.SALES_TYPE_SECONDARY
                        && priceBookEntryMap.get(each.PricebookEntryId).PriceBook2.Market_Pricelist__c
                        && priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c!=null
                        && priceBookEntryMap.get(each.PricebookEntryId).UnitPrice!=null){
                            expectedUnitPrice=((priceBookEntryMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                        }
                        if(((Decimal)each.unitPrice) != expectedUnitPrice
                          && orderMap.get(each.OrderId).MHE_Division__c!=GlobalConstants.MHE_SUB_DIVISION_RENTAL
                            && orderMap.get(each.OrderId).Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT //SSD condition added by Sreekanth Jujare to allow SSD users to edit Sales Price on OLI
                          && orderMap.get(each.OrderId).Business_Unit__c !=GlobalConstants.Locks_BUSINESS_UNIT
                           && (String.isBlank(orderMap.get(each.OrderId).Intent__c))){
                            each.addError(System.Label.Order_SalesPrice_Validation_Error_Message);
                        }
                        else if(orderMap.get(each.OrderId).Intent__c != null && !orderMap.get(each.OrderId).Intent__c.equalsIgnoreCase('true')){
                               each.addError(System.Label.Order_SalesPrice_Validation_Error_Message);
                        }
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method to get Orders
     Inputs:        List<OrderItem>
    ----------------------------------------------------------------------------*/
    public Map<Id, Order> getOrders(Set<Id> orderIds){
        return (new Map<Id, Order>([Select Id, Planned_delivery_Date__c, Intent__c, Business_Unit__c,
            RecordTypeId, WarehouseCode__c, Branch__c, Sales_Type__c, MHE_Division__c 
            FROM Order Where Id IN: orderIds])); //And RecordType.Name Like '%MHE%']));
    }
    
    /*------------------------------------------------------------------------
     Author:        Shailja
     Company:       Salesforce
     Description:   Method is responsible for checking if SalesPrice is allowed to edit
     Inputs:        List<OrderItem>
    ----------------------------------------------------------------------------*/
    private Boolean IsProfileAllowedToEditSalesPrice(){
        String profilesLabel = System.Label.Profiles_Allow_To_Edit_SalesPrice;
        List<String> profiles = profilesLabel.split('\\,');
        List<User> usr = [Select Id, Profile.Name From User Where Id = :UserInfo.getUserId() AND Profile.Name IN :profiles ];
        //If Profile mentioned in Custom Label is Current User's profile then allow to edit Sales Price
        if(usr.size() > 0) return true;
        return false;
    }
    
    public void updateDiscountFieldsOnUnitPriceUpdate(List<OrderItem> newItems,Map<Id,OrderItem> oldItems){
        List<OrderItem> applicableOrderItems=new List<OrderItem>();
        for(OrderItem item:newItems){
            if(item.UnitPrice!=oldItems.get(item.Id).UnitPrice)
               applicableOrderItems.add(item); 
        }
        for(OrderItem item:applicableOrderItems){
            for(integer i=2;i<12;i++){
                if(item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c')!=null && item.UnitPrice!=null){
                    Decimal levelDiscountAmt=(((Decimal)item.get('Applied_Discount_Matrix_L'+i+'_Percentage__c'))/100)*(item.UnitPrice);
                    item.put('Applied_Discount_Matrix_Level_'+i+'_Amount__c',levelDiscountAmt);
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to prepopulate warehouse lookup based on the parent order record.
     Inputs:        List<OrderItem> orderProducts
    ----------------------------------------------------------------------------*/
    public void populateOLIWarehouse(List<OrderItem> orderProducts) {
        Set<Id> orderIds = new Set<Id>();
        for(OrderItem orderProduct : orderProducts) {
            orderIds.add(orderProduct.OrderId);
        }
        Map<Id, Order> orderRecordsMap = getOrders(orderIds);

        if(orderRecordsMap != null && orderRecordsMap.size() > 0) {
            for(OrderItem orderProduct : orderProducts) {
                if(orderRecordsMap.containsKey(orderProduct.OrderId)) {
                    if(orderProduct.Warehouse__c == null) {
                        orderProduct.Warehouse__c = orderRecordsMap.get(orderProduct.OrderId).WarehouseCode__c;
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
     Author:        Kartik Shetty
     Company:       Salesforce
     Description:   Method to validate whether the correct warehouse record is being populated on order item records. 
     Inputs:        Map<Id, OrderItem> newLineItemMap, List<OrderItem> oldLineItems
    ----------------------------------------------------------------------------*/
    public void validateOLIWarehouses(Map<Id, OrderItem> newLineItemMap, List<OrderItem> oldLineItems) {
        Set<Id> orderIds = new Set<Id>();
        Map<Id, Order> orderRecordsMap = new Map<Id, Order>();
        List<OrderItem> orderItemsToValidate = new List<OrderItem>();

        for(OrderItem oldOrderItemRecord : oldLineItems) {
            OrderItem newOrderItemRecord = newLineItemMap.get(oldOrderItemRecord.Id);
            if(newOrderItemRecord.Warehouse__c != null && oldOrderItemRecord.Warehouse__c != newOrderItemRecord.Warehouse__c) {
                orderItemsToValidate.add(newOrderItemRecord);
                orderIds.add(oldOrderItemRecord.OrderId);
            }
        }
        if(orderIds.size() > 0) {
            orderRecordsMap = getOrders(orderIds);
            (new InventoryUtilityController()).validateOrderItemRecords(orderItemsToValidate, orderRecordsMap);
        }
    }

    //Disable the trigger execution
    public void disableTriggerExecution() {
        OrderItemTriggerHandler.TriggerDisabled = true;
    }
}