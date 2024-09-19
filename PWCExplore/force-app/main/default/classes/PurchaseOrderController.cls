/*
@Author : Deep Banerjee
@description : Purchase Order VF page controller to set data for VF page , invoked from Flow: "Resync Sales Order with PO Details"
@last modified by : vrajpoot@godrej.com
@ last modified on : 02.02.23
*/

public class PurchaseOrderController {
    public PurchaseOrder purchaseOrd {get; set;}
    
    public PurchaseOrderController(ApexPages.StandardController stdController) {
        Purchase_Order__c purchaseOrder = (Purchase_Order__c)stdController.getRecord(); 
        purchaseOrd = PurchaseOrderController.setPurchaseOrder(purchaseOrder.Id,apexpages.currentpage().getparameters().get('poNumber'));
    }
    
    /*
	* params : Id
	* return : PurchaseOrder record 
	* purpose: this method sets the record data of Purchase Order for the VF page based on the record's Id
	*/ 
    public static PurchaseOrder setPurchaseOrder(Id recordId,String poNumber){      
        if(recordId == null) return NULL;  // check if Id is null 
        System.debug(poNumber);
        try{
            Purchase_Order__c purchasedOrder = [SELECT Id,
                                                Item_Code__c, 
                                                Address_Code__c, 
                                                Quantity__c, 
                                                CreatedDate,
                                                Line_Number__c,
                                                Purchase_Price__c,
                                                Purchase_Office__c,
                                                PO_Number__c,
                                                Warehouse__c,
                                                Order_Product__r.Product2.Name, 
                                                Order_Product__r.Product2.Description, 
                                                Order_Product__r.Product2.Commodity_Code__c,
                                                Order__r.Ship_To_Address__r.Address_Code__r.State_Province__c,
                                                Order__r.Account.Name,
                                                Business_Partner_Code__c,
                                                Order__r.CreatedDate,
                                                Order__r.OrderReferenceNumber,
                                                Order__r.Ship_To_Address__r.Address_Code__c,
                                                Order__r.Sold_to_Business_Partner__c
                                                FROM Purchase_Order__c 
                                                WHERE Id =: recordId];
            Map<String,Map<String,String>> metadataMap = PurchaseOrderController.getValuesFromMetadata();
            Map<String,String> billToCityMap = metadataMap?.get('billCity');
            Map<String,String> deliveryAddMap = metadataMap?.get('deliveryAdd');
            Map<String,String> gstMap = metadataMap?.get('gst');
            Map<String,String> billToAddressMap= metadataMap?.get('billToAddress');
            Map<String,String> effDateMap= metadataMap?.get('effDate');
            Map<String,String> gettoAddressFull = PurchaseOrderController.getToAddressMap(purchasedOrder.Order__r.Ship_To_Address__r.Address_Code__c);
            
            String state = gettoAddressFull.get('state');
            String supplierGstState = '';
            String taxNumberEffDate = '';
            if(String.isNotBlank(purchasedOrder?.Order__r?.Sold_to_Business_Partner__c)){
                 Map<String,String> supplierGstStateMap = PurchaseOrderController.getSupplierGSTState(purchasedOrder.Order__r.Sold_to_Business_Partner__c, state);
                 supplierGstState = supplierGstStateMap?.get('SupplierGSTState');
                 taxNumberEffDate = supplierGstStateMap?.get('EffDate');
            }
           
            PurchaseOrder purchaseOrd = new PurchaseOrder();
            purchaseOrd.itemCode = String.isNotBlank(purchasedOrder?.Item_Code__c) ? purchasedOrder?.Item_Code__c : '' ;
            purchaseOrd.addressCode = String.isNotBlank(purchasedOrder?.Address_Code__c) ? purchasedOrder?.Address_Code__c : '';
            purchaseOrd.quantity = String.isNotBlank(purchasedOrder?.Quantity__c) ? purchasedOrder?.Quantity__c : '';
            purchaseOrd.poNO = poNumber; 
            DateTime dT = (purchasedOrder?.CreatedDate != null) ? purchasedOrder?.CreatedDate : null; 
            purchaseOrd.createdDate = (dT != null) ? DateTime.newInstance(dt.year(), dt.month(), dt.day()).format('dd-MM-yyyy') : '';
            purchaseOrd.purchasePrice = String.isNotBlank(purchasedOrder?.Purchase_Price__c) ? purchasedOrder?.Purchase_Price__c : '';
            if(String.isNotBlank(purchasedOrder?.Quantity__c) && String.isNotBlank(purchasedOrder?.Purchase_Price__c)){
                purchaseOrd.subTotal = Integer.valueOf(purchasedOrder?.Quantity__c) * Integer.valueOf(purchasedOrder?.Purchase_Price__c); 
            }
            purchaseOrd.shortDescription = String.isNotBlank(purchasedOrder?.Order_Product__r?.Product2?.Name) ? purchasedOrder?.Order_Product__r?.Product2?.Name : '';
            purchaseOrd.longDescription = String.isNotBlank(purchasedOrder?.Order_Product__r?.Product2?.Description) ? purchasedOrder?.Order_Product__r?.Product2?.Description : '';
            purchaseOrd.hsnCode = String.isNotBlank(purchasedOrder?.Order_Product__r?.Product2?.Commodity_Code__c) ? purchasedOrder?.Order_Product__r?.Product2?.Commodity_Code__c : '';
            purchaseOrd.name =  String.isNotBlank(purchasedOrder?.Order__r?.Account?.Name ) ? purchasedOrder?.Order__r?.Account?.Name : '' ;
            purchaseOrd.businessPartnerCode =  String.isNotBlank(purchasedOrder?.Business_Partner_Code__c ) ? purchasedOrder?.Business_Partner_Code__c : '' ;
            DateTime ordDT = (purchasedOrder.Order__r.CreatedDate != null) ? purchasedOrder.Order__r.CreatedDate : null; 
            purchaseOrd.orderCreatedDate= (ordDT != null) ? DateTime.newInstance(ordDT.year(), ordDT.month(), ordDT.day()).format('dd-MM-yyyy') : '';
            purchaseOrd.orderRefNo= String.isNotBlank(purchasedOrder.Order__r.OrderReferenceNumber) ? purchasedOrder.Order__r.OrderReferenceNumber : '';         
            purchaseOrd.deliveryAddress= String.isNotBlank(purchasedOrder?.Warehouse__c) ? deliveryAddMap?.get(purchasedOrder.Warehouse__c) : '';
            purchaseOrd.gstNo= String.isNotBlank(purchasedOrder?.Purchase_Office__c) ? gstMap?.get(purchasedOrder.Purchase_Office__c) : '';
            purchaseOrd.lineNo= String.isNotBlank(purchasedOrder.Line_Number__c) ? purchasedOrder.Line_Number__c : '10';
            purchaseOrd.billToAddress= String.isNotBlank(purchasedOrder.Purchase_Office__c) ? billToAddressMap.get(purchasedOrder.Purchase_Office__c) : '';         
            purchaseOrd.billToCity= String.isNotBlank(purchasedOrder.Purchase_Office__c) ? billToCityMap.get(purchasedOrder.Purchase_Office__c) : '';
            purchaseOrd.telephone= gettoAddressFull?.get('mobile');
            purchaseOrd.houseFloorBuildingToAddress= gettoAddressFull.get('houseFloorBuilding');
            purchaseOrd.streetToAddress= gettoAddressFull.get('street');
            purchaseOrd.cityStateZipCodeToAddress= gettoAddressFull.get('cityStateZipCode');
            purchaseOrd.state= gettoAddressFull.get('state');
            purchaseOrd.country= gettoAddressFull.get('country');
            purchaseOrd.effDate=String.isNotBlank(purchasedOrder.Purchase_Office__c) ? effDateMap.get(purchasedOrder.Purchase_Office__c) : '';
            purchaseOrd.supplierGSTState = String.isNotBlank(supplierGstState) ? supplierGstState : '';
            purchaseOrd.taxNumberEffDate = String.isNotBlank(taxNumberEffDate) ? taxNumberEffDate : '';
      
            return purchaseOrd; 
        }catch(exception e){
            system.debug('exception occured due to '+e.getMessage() + ' '+e.getLineNumber());
            throw e;
        }
    }
    
    // purchase order wrapper
    @TestVisible
    public class PurchaseOrder {
        @AuraEnabled
        public String itemCode {get; set;}
        @AuraEnabled
        public String addressCode {get; set;}
         @AuraEnabled
        public String poNO {get; set;}
        @AuraEnabled
        public String quantity {get; set;}
        @AuraEnabled
        public String createdDate {get; set;}
        @AuraEnabled
        public String purchasePrice {get; set;}
        @AuraEnabled
        public String basicPrice {get; set;}
        @AuraEnabled
        public Integer subTotal {get; set;}
        @AuraEnabled
        public String shortDescription {get; set;}
        @AuraEnabled
        public String longDescription {get; set;}
        @AuraEnabled
        public String hsnCode {get; set;}
        @AuraEnabled
        public String supplierGSTState {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String businessPartnerCode {get; set;}
        @AuraEnabled
        public String orderCreatedDate{get;set;}
        @AuraEnabled
        public String orderRefNo{get;set;}
        @AuraEnabled
        public String deliveryAddress{get;set;}
        @AuraEnabled
        public String gstNo{get;set;}
        @AuraEnabled
        public String lineNo{get;set;}
        @AuraEnabled
        public String toAddress{get;set;}
        @AuraEnabled
        public String billToAddress{get;set;}
        @AuraEnabled
        public String telephone{get;set;}
        @AuraEnabled
        public String billToCity{get;set;}
        @AuraEnabled
        public String houseFloorBuildingToAddress{get;set;}
        @AuraEnabled
        public String streetToAddress{get;set;}
        @AuraEnabled
        public String cityStateZipCodeToAddress{get;set;}
        @AuraEnabled
        public String state{get;set;}
        @AuraEnabled
        public String country{get;set;}
        @AuraEnabled
        public String effDate{get;set;}
        @AuraEnabled
        public String taxNumberEffDate{get;set;}
        
    }
    
    /*
	* params : List<Id> 
	* return : List<ContentVersion>
	* purpose: to create purchase order pdf when the integration status changes to synced from flow - Resync Sales Order with PO Details
	*/ 
    @InvocableMethod
    public static List<ContentVersion> createPOPDF(List<Id> lstId){
        try{            
            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            List<ContentVersion> cvList = new List<ContentVersion>();
            Set<String> contentDocumentSet = new Set<String>();
            List<ContentDocument> contentDocumentToDelete = new List<ContentDocument>();
            //Get all content document link where linkedEntityid IN  lstId
            for(ContentDocumentLink doc : [SELECT ContentDocumentId,ContentDocument.title,Id,LinkedEntityId,ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :lstId ] )  {
                contentDocumentToDelete.add(doc.ContentDocument);
            }        
            
            if(contentDocumentToDelete.size() > 0) delete contentDocumentToDelete;
            
            List<Purchase_Order__c> exchangeOrders = [Select Id,Name,Order__r.OrderReferenceNumber,Logistics_Company_Branch__c,PO_Number__c FROM Purchase_Order__c WHERE ID IN: lstId];
            System.debug(':::::');
            System.debug(exchangeOrders);
            // generate new file 
            for(Purchase_Order__c purchaseOrder : exchangeOrders){
                PageReference pageRef = Page.PurchaseOrder;
                pageRef.getParameters().put('id' , purchaseOrder.Id);
                pageRef.getParameters().put('poNumber' , purchaseOrder.PO_Number__c);
                ContentVersion cv = new ContentVersion();
                cv.Title = purchaseOrder.PO_Number__c +'-'+purchaseOrder.Order__r?.OrderReferenceNumber+'-'+purchaseOrder?.Logistics_Company_Branch__c;
                cv.PathOnClient = purchaseOrder.PO_Number__c +'-'+purchaseOrder.Order__r.OrderReferenceNumber+'-'+purchaseOrder.Logistics_Company_Branch__c+'.pdf';
                
                if(Test.isRunningTest()) {
                    cv.VersionData = blob.valueOf('PDF Content');
                }else{
                    cv.VersionData = pageRef.getContent();    
                }
                
                cv.IsMajorVersion = true; 	
                cvList.add(cv);
            }
            insert cvList; // creating contentversion
            
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN : cvList].ContentDocumentId;
            for(Id purchaseOrderId :lstId){
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = purchaseOrderId;
                cdl.ContentDocumentId = conDocId;
                cdl.shareType = 'V';
                cdList.add(cdl);
            }
            insert cdList;
            return cvList; // returning the file created 
        }catch(exception e){
            system.debug('exception occured due to : '+e.getMessage() +'  --at --'+e.getLineNumber());
            throw e;
        }
    }
    
    /*
	* description : method to retrieve data from Metadata: "Exchange PO Logistic settings" for billTo,delivery and GSTIN
	* return : Map<String,Map<String,String>>
	*/
    private static Map<String,Map<String,String>> getValuesFromMetadata(){
        
        List<Exchange_PO_Logistics_Setting__mdt > logisticSettings= [select id,label,Purchase_Office__c,Bill_To_City__c,
                                                                     Godrej_Bill_To_Address__c,Delivery_Address__c, Eff_Date__c, 
                                                                     Warehouse_Code__c,GSTIN__c FROM Exchange_PO_Logistics_Setting__mdt];
        Map<String,String> billToCityMapping  = new Map<String,String>();
        Map<String,String> deliveryAddressMapping  = new Map<String,String>();
        Map<String,String> gstMapping  = new Map<String,String>();
        Map<String,String> billToAddressMapping = new Map<String,String>();
        Map<String,String> effDateMapping = new Map<String,String>();
        for(Exchange_PO_Logistics_Setting__mdt data : logisticSettings){
            if(data.Purchase_Office__c!=null){
                billToCityMapping.put(data.Purchase_Office__c ,data.Bill_To_City__c);
                gstMapping.put(data.Purchase_Office__c,data.GSTIN__c );
                billToAddressMapping.put(data.Purchase_Office__c,data.Godrej_Bill_To_Address__c );
                if(data.Eff_Date__c != null){
                    Date effDate =  data.Eff_Date__c;
                    String dtConverted = Datetime.newInstance(effDate.year(),effDate.month(),effDate.day()).format('dd-MM-yyyy');
                    effDateMapping.put(data.Purchase_Office__c,dtConverted);
                }
            }
            if(data.Warehouse_Code__c !=null){
                deliveryAddressMapping.put(data.Warehouse_Code__c ,data.Delivery_Address__c);
            }
        }
        
        Map<String,Map<String,String>> allDataMap = new Map<String,Map<String,String>>();
        allDataMap.put('billCity',billToCityMapping);
        allDataMap.put('billToAddress',billToAddressMapping);
        allDataMap.put('deliveryAdd',deliveryAddressMapping);
        allDataMap.put('gst',gstMapping);
        allDataMap.put('effDate',effDateMapping);
        return allDataMap;
    }
    
    /*
	* description : method to get Address from PO> Order> Ship to > Address Code > fields
	* return : String
	*/ 
    private static Map<String,String> getToAddressMap(Id recordId){
        
        Address__c addRecord = [Select Id,Name,House_Number__c,Building__c,
                                Floor__c,Street__c,Street2__c,CityName__c,
                                StateName__c,ZipCode__r.Name,Country__c ,Telephone__c 
                                FROM Address__c WHERE ID=:recordId ];
        
        String houseFloorBuilding = '';
        String street = '';
        String cityStateZipCode = '';
        String state = '';
        String country = '';
        String telephone='';
        houseFloorBuilding += String.isNotBlank(addRecord.House_Number__c) ? addRecord.House_Number__c+' '  :'';
        houseFloorBuilding += String.isNotBlank(addRecord.Floor__c) ? addRecord.Floor__c+' '  : '';
        houseFloorBuilding += String.isNotBlank(addRecord.Building__c) ? addRecord.Building__c+' '  : '';
        
        street += String.isNotBlank(addRecord.Street__c) ? addRecord.Street__c+' '  : '';
        street += String.isNotBlank(addRecord.Street2__c) ? addRecord.Street2__c+' '  : '';
        
        cityStateZipCode += String.isNotBlank(addRecord.CityName__c) ? addRecord.CityName__c+' '  : '';
        cityStateZipCode += String.isNotBlank(addRecord.StateName__c) ? addRecord.StateName__c+' '  : '';
        cityStateZipCode += String.isNotBlank(addRecord.ZipCode__r?.Name) ? addRecord.ZipCode__r.Name+' '  : '';
        
        state = String.isNotBlank(addRecord.StateName__c) ? addRecord.StateName__c: '';
        country = String.isNotBlank(addRecord.Country__c) ? addRecord.Country__c: '';
        telephone= String.isNotBlank(addRecord.Telephone__c) ? addRecord.Telephone__c: '';
        
        Map<String,String> addressMap = new Map<String,String>();     
        addressMap.put('houseFloorBuilding', houseFloorBuilding);
        addressMap.put('street', street);
        addressMap.put('cityStateZipCode', cityStateZipCode);
        addressMap.put('state', state);
        addressMap.put('country', country);
        addressMap.put('mobile',telephone);     
        return addressMap;        
    }
    
    /*
	* description : method to get Supplier GST State from PO> Order> Account > Tax Number > fields
	* return : String
	*/ 
    private static Map<String,String> getSupplierGSTState(Id accountId, String state){
        
        if(accountId == null || String.isBlank(state)) return null;
        
        List<Tax_Number__c> taxNumbers = [SELECT Id, 
                                          Name, 
                                          Business_Partner__c, 
                                          toLabel(State_Province_Name__c),
                                          Category__c, 
                                   		  Expiry_Date__c,
                                          Effective_Date__c,
                                   		  Tax_Number_Ext__c,
                                   		  Tax_Number__c,
                                   		  State_Province__c
                                          FROM Tax_Number__c
                                 		  WHERE Business_Partner__c =: accountId 
                                   		  AND Expiry_Date__c = null
                                          AND Category__c = 'GSTIN'
                                          AND Tax_Number__c = 'URP'
                                       ];
        
        String taxNumberString = '';
        String taxNumberEffDate = '';
    
        for(Tax_Number__c taxNumber : taxNumbers){
            if(taxNumber.State_Province_Name__c.equalsIgnoreCase(state)){
                 taxNumberString = taxNumber?.State_Province__c + '/' + taxNumber?.Tax_Number__c;
                 DateTime effDate =  taxNumber?.Effective_Date__c;
                 taxNumberEffDate = (effDate != null) ? DateTime.newInstance(effDate.year(), effDate.month(), effDate.day()).format('dd-MM-yyyy') : '';
            }
        }
        
        Map<String,String> taxNumberMap = new Map<String,String>();  
        taxNumberMap.put('SupplierGSTState', taxNumberString);
        taxNumberMap.put('EffDate', taxNumberEffDate);
        return taxNumberMap; 
    }
}