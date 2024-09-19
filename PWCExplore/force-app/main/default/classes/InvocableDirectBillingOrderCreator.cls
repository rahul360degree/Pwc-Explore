/**
 * @description       : 
 * @author            : Varun Rajpoot
 * @group             : 
 * @last modified on  : 01-02-2024
 * @last modified by  : Varun Rajpoot
**/
global class InvocableDirectBillingOrderCreator {
    private static Id pricebookId;
    global class FlowInput {                  
        @InvocableVariable(required=true)
        global Id accountId;
        @InvocableVariable
        global String accountChannel;        
        @InvocableVariable
        global String fromLogisticsCompany; 
        @InvocableVariable
        global Id headerWarehouseCode;
        @InvocableVariable(required=true)
        global Id toBranchId;        
        @InvocableVariable
        global Id internalSalesRep;         
        @InvocableVariable
        global List<OrderItem> lstOrderItems;        
        
  }
  

  
  

    @InvocableMethod(label='Create Direct Billing Order with Lines' description='Used to Create Direct Billing Order with Lines') 
    global static List<List<Order>> createDirectBillingOrder(FlowInput[] arrFlowInput){
        pricebookId = [Select Id,PriceList_Code__c from Pricebook2 where PriceList_Code__c='HD1_3000'].Id;
        Set<Id> accountIds = new Set<Id>(); 
        Set<Id> branchIds = new Set<Id>();
        Map<Id, Id> mapAccountAddress = new Map<Id, Id>();
        Map<Id, List<OrderItem>> mapOrderToOLI = new Map<Id, List<OrderItem>>();
    
        List<Order> lstOrdersOutput = new List<Order>();
        List<List<Order>> lstOrdersReturn = new List<List<Order>>();
        
       for(integer j=0;j<arrFlowInput.size();j++){
           accountIds.add(arrFlowInput[j].accountId);
             branchIds.add(arrFlowInput[j].toBranchId);
       
       }
       
       mapAccountAddress = generateAccountAddressMap(accountIds,branchIds);
       Map < String, Logistics_Company_Sales_Office_DBO__mdt > mapCompanySalesOffice = Logistics_Company_Sales_Office_DBO__mdt.getAll();
        
        for(integer i=0;i<arrFlowInput.size();i++){
            if( !(mapCompanySalesOffice.containsKey('X'+arrFlowInput[i].fromLogisticsCompany))){
                throw new CustomException('Did not find any record in Logistics_Company_Sales_Office_DBO__mdt metadata for X'+arrFlowInput[i].fromLogisticsCompany);
            }

            Order o = new Order();
            o.AccountId = arrFlowInput[i].accountId;
            o.Business_Unit__c = 'H';
            o.Logistics_Company_Branch__c = arrFlowInput[i].fromLogisticsCompany;
            o.Sales_Office__c = (mapCompanySalesOffice.get('X'+arrFlowInput[i].fromLogisticsCompany)).Sales_Office_ID__c;
            o.Line_of_Business__c = (arrFlowInput[i].accountChannel == null || arrFlowInput[i].accountChannel == '')?'DLR':arrFlowInput[i].accountChannel;
            o.Approval_Status__c = 'Product Manager Approved';
            o.Pricebook2Id = pricebookId;
            o.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Direct_Billing_Order_Appliances').getRecordTypeId();
            o.Sales_Order_Series__c = 'HOA';
            o.Ship_To_Account__c = arrFlowInput[i].accountId;
            o.Sold_to_Business_Partner__c = arrFlowInput[i].accountId;
            o.Type = 'NOR';
            o.Status = 'Draft';
            o.WarehouseCode__c = arrFlowInput[i].headerWarehouseCode;
            o.Internal_Sales_Representative__c = arrFlowInput[i].internalSalesRep;

            o.Sold_To_Address__c = mapAccountAddress.get(arrFlowInput[i].accountId);
            o.Ship_To_Address__c = mapAccountAddress.get(arrFlowInput[i].accountId);
            o.Sub_Division__c = 'B2B';
            o.Is_Exchange_order__c = 'no';
            o.Sales_Type__c = 'Primary';
            lstOrdersOutput.add(o);

            
            
        }
        insert lstOrdersOutput;
        
        Set<String> itemCodes = new Set<String>();
        
        for(Integer o = 0; o < lstOrdersOutput.size(); o++){
    
            mapOrderToOLI.put(lstOrdersOutput[o].Id, arrFlowInput[o].lstOrderItems);
            for (Integer k = 0; k < arrFlowInput[o].lstOrderItems.size(); k++)
            {
                itemCodes.add(arrFlowInput[o].lstOrderItems[k].Item_Code__c);
            }
    
        }
    
        processOrderItems(mapOrderToOLI,itemCodes);
        lstOrdersReturn.add(lstOrdersOutput);
        return lstOrdersReturn;

    }
    
    private static Map<Id, Id> generateAccountAddressMap(Set<Id> accountIds, Set<Id> branchIds){
    
            Map<Id, Id> mapAccountAddress = new Map<Id, Id>();
    
    List<Address_by_BP__c> lstAddressByBP = new List<Address_by_BP__c>([Select Id, Name, Account__c 
                                                                    From Address_by_BP__c  Where                                                                    
                                                                    Account__c IN :accountIds  And 
                                                                    //isPrimary__c = TRUE And 
                                                                    Branch__c IN :branchIds]);
    for(Address_by_BP__c abp : lstAddressByBP) {
    
        mapAccountAddress.put(abp.Account__c, abp.Id);
    
    }
    
    return mapAccountAddress;
    }
    
    //
    
    



    
    //

    private static void processOrderItems(Map<Id, List<OrderItem>> mapOrderToOLI, Set<String> itemCodes){
        List<OrderItem> lstOrderItemsToInsert = new List<OrderItem>();
        Map<String, Id> mapPriceBookEntry = new Map<String, Id>();
                Map<String, Double> mapPriceBookUnitPrice = new Map<String, Double>();
                Map<String, Double> mapProductTaxRate = new Map<String, Double>();

        
       List<PriceBookEntry> lstPBE = new List<PriceBookEntry>([Select Id, Name, UnitPrice, PriceBook2Id, Product2.Item__c,
                                                                       Product2.Tax_Rate__c 
                                                                    From PriceBookEntry  Where                                                                    
                                                                    IsActive = TRUE  And
                                                                    Pricebook2Id =: pricebookId And 
                                                                    Product2.Item__c IN :itemCodes]);
        for(PriceBookEntry pbe : lstPBE) {
            mapPriceBookEntry.put(pbe.Product2.Item__c, pbe.Id);
            mapPriceBookUnitPrice.put(pbe.Product2.Item__c, pbe.UnitPrice);
            mapProductTaxRate.put(pbe.Product2.Item__c, pbe.Product2.Tax_Rate__c);            
            
        }

        
        for(Id id: mapOrderToOLI.keyset()){
            List<OrderItem> lstOI = mapOrderToOLI.get(id);
            for(OrderItem oi: lstOI){
                OrderItem oiToInsert = new OrderItem();
                oiToInsert.OrderId = id;
                oiToInsert.Quantity = oi.Quantity;
                oiToInsert.Stock_File__c = oi.Stock_File__c;
                oiToInsert.Product2 = new Product2(Item__c = oi.Item_Code__c);
                oiToInsert.PriceBookEntryId = mapPriceBookEntry.get(oi.Item_Code__c);
                oiToInsert.UnitPrice = mapPriceBookUnitPrice.get(oi.Item_Code__c);
                
                //To set Tax Before for NLC calculation
                System.debug(oi.Item_Code__c);
                System.debug(mapPriceBookUnitPrice);
                System.debug(mapProductTaxRate);
                System.debug(oi.Quantity);
                if(mapPriceBookUnitPrice<>null && mapPriceBookUnitPrice.keyset()<>null && mapPriceBookUnitPrice.containsKey(oi.Item_Code__c) && mapProductTaxRate.containsKey(oi.Item_Code__c)){
                	oiToInsert.Tax_Before__c = (mapPriceBookUnitPrice.get(oi.Item_Code__c) * mapProductTaxRate.get(oi.Item_Code__c)/100)*oi.Quantity;
                }
                System.debug(oi.Warehouse__c);
                if(!test.isRunningTest())
                    oiToInsert.Warehouse__r = new Warehouse__c(Warehouse__c = oi.Warehouse__c);
                System.debug(oiToInsert.Warehouse__r);
                //oiToInsert.Warehouse__r = new Warehouse__c(Warehouse__c = oi.Warehouse__r.Warehouse__c);
                lstOrderItemsToInsert.add(oiToInsert);
                
               }   
    
        }
        insert lstOrderItemsToInsert;

    
}
}