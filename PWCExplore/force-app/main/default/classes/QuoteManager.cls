/*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Class to validate and generate order from quote
Inputs:        NA
Test Class:   QuoteManagerTest

History
03-04-2020      Pawan     Initial Release
----------------------------------------------------------------------------*/
public with sharing class QuoteManager {
    
    public Map<Id, QuoteLineItem> quoteLineItemMap;
    
    private static QuoteManager QUOTEMANAGER_INSTANCE = new QuoteManager();
    
    /*
* @description Get quote and quote line item records in JSON format.
* @param quote record id
* @return JSON string
*/
    @AuraEnabled
    public static String getQuoteData(String quoteId) {
        
        Map<String, String> quoteLineItemJSON = new Map<String, String>();
        Quote quoteRecord = [Select Id, ExpirationDate, Status,Transaction_Type__c, AccountId, Opportunity.Internal_Sales_Rep__c, Primary_Quote__c,Opportunity.Sales_Branch_Name__c,Sold_to_Business_Partner__c,
                             RecordType.Name, Record_Type_Developer_Name__c,
                             LD_Applicable__c, Credit_Terms__c, Special_Delivery_Period__c,
                             BG_Status__c, CG_Status__c, IsSyncing
                             FROM Quote WHERE Id = : quoteId
                            ];
        //If Condition Added by Rohit Jadhav for Locks B2C ISTD on 16/03/2023
        if(quoteRecord.Record_Type_Developer_Name__c!=GlobalConstants.RECORDTYPE_Locks_B2C_ISTD)
        {
            QUOTEMANAGER_INSTANCE.quoteLineItemMap = new Map<Id, QuoteLineItem>([Select Id, Product2.Name, Quantity, Approved_Customer_Discount__c, Product2.Item__c,Quote.Record_Type_Developer_Name__c,search_key_II__c,
                                                                             Approved_WD_Retention__c, Approved_SAC_ORC__c, (Select Id, Quantity FROM OrderItems) FROM QuoteLineItem WHERE QuoteId =: quoteId ]);
        }
        else{
            QUOTEMANAGER_INSTANCE.quoteLineItemMap = new Map<Id, QuoteLineItem>([Select Id, Product2.Name, Quantity, Approved_Customer_Discount__c, Product2.Item__c,Quote.Record_Type_Developer_Name__c,Search_Key_II__c,
                                                                             Approved_WD_Retention__c, Approved_SAC_ORC__c,Status__c, (Select Id, Quantity FROM OrderItems) FROM QuoteLineItem WHERE QuoteId =: quoteId and Status__c=:GlobalConstants.QliWonStatus]);
        }
        String message = validateQuote(quoteRecord, QUOTEMANAGER_INSTANCE.quoteLineItemMap.values());
        // If message is not null then there is an error message
        if(message != null) {
            quoteLineItemJSON.put('result', 'error');
            quoteLineItemJSON.put('error_message', message);
            quoteLineItemJSON.put('data', null);
        } else {
            List<QuoteLineItemMapper> quoteLineMapperObjList = QUOTEMANAGER_INSTANCE.createQuoteLineItemDS();
            if(quoteLineMapperObjList.size() > 0) {
                quoteLineItemJSON.put('result', 'success');
                quoteLineItemJSON.put('error_message', null);
                quoteLineItemJSON.put('data', JSON.serialize(quoteLineMapperObjList));
            } else {
                quoteLineItemJSON.put('result', 'error');
                quoteLineItemJSON.put('error_message', System.Label.Order_available_quantity_is_zero);
                quoteLineItemJSON.put('data', null);
            }
        }
        return JSON.serialize(quoteLineItemJSON);
    }
    
    /*
* @description: Create a DS to hold quote line item data which will be converted to JSON.
* @return: List<QuoteLineItemMapper>
*/
    private List<QuoteLineItemMapper> createQuoteLineItemDS() {
        List<QuoteLineItemMapper> quoteLineMapperObjList = new List<QuoteLineItemMapper>();
        for(QuoteLineItem quoteLineItem : QUOTEMANAGER_INSTANCE.quoteLineItemMap.values()) {
            // Get the total number of order placed for the particular quote line item.
            Integer totalOrderPlacedQuantity = 0;
            if(quoteLineItem.Quote.Record_Type_Developer_Name__c!=GlobalConstants.QUOTE_RECORDTYPE_SSD){
                
            for(OrderItem orderItem : quoteLineItem.OrderItems) {
                totalOrderPlacedQuantity += Integer.valueOf(orderItem.Quantity);
            }
            }
            // If the quantity of orders placed is less than respective quoteLineItem's quantity then proceed
            // else do not consider that record.
            if(totalOrderPlacedQuantity < quoteLineItem.Quantity) {
                QuoteLineItemMapper quoteLineItemMapperObj = new QuoteLineItemMapper();
                quoteLineItemMapperObj.id = quoteLineItem.Id;
                quoteLineItemMapperObj.name = quoteLineItem.Product2.Name;
                quoteLineItemMapperObj.available_quantity = Integer.valueOf(quoteLineItem.Quantity - totalOrderPlacedQuantity);
                quoteLineItemMapperObj.item_code = quoteLineItem.Product2.Item__c;
                quoteLineItemMapperObj.order_quantity = quoteLineItemMapperObj.available_quantity;
                quoteLineItemMapperObj.search_key_II = quoteLineItem.Search_Key_II__c; // Added by Rohit Jadhav for Locks B2C ISTDs
                quoteLineMapperObjList.add(quoteLineItemMapperObj);
            }
        }
        return quoteLineMapperObjList;
    }
    
    /*
* @description validate quote before creating an order from quote.
* @param quote record
* @param quote line item records
* @return error message 
*/
    @AuraEnabled
    public static String validateQuote(Quote quoteRecord, List<QuoteLineItem> quoteLineItems) {
        String value = QUOTEMANAGER_INSTANCE.validationCheck(quoteRecord, quoteLineItems);
        return value;
    }
    
    private String validationCheck(Quote quoteRecord, List<QuoteLineItem> quoteLineItems) {
        //Order cannot be generated for Contract type
        if(quoteRecord != null && quoteRecord.Record_Type_Developer_Name__c == 'MHE_Contracts'){
            return 'Order cannot be Generated for Contract Type.';
        }
        
        // if accountId is missing from quote then ask user to verify the quote
        if(quoteRecord != null && quoteRecord.Primary_Quote__c != null) {
            return 'This is not the Primary Quote.';
        }
        
        //Check CURD Permission for Order, if user should be able to create Order record or not
        Schema.DescribeSObjectResult drSObj = Schema.sObjectType.Order;
        if(!drSObj.isCreateable()){
            return System.Label.NOT_ALLOWED_TO_GENERATE_ORDER;
        }
        
        else if(quoteRecord != null && quoteRecord.AccountId == null){
            return System.Label.ACCOUNT_NAME_MISING;
        }else if(quoteRecord != null && quoteRecord.ExpirationDate != null && quoteRecord.ExpirationDate < Date.today()){//if quote expirationdate is of past then ask user to create another quote
            return System.Label.QUOTE_EXPIRED;
        }else if(quoteRecord.Status != GlobalConstants.QUOTE_STATUS_FINALIZED){//Check for quote status as finalized to generate order
            return System.Label.QUOTE_NOT_FINALIZED;
        }else if(quoteLineItems == null || quoteLineItems.size() == 0 ){//ask user to add if no products added 
            return System.Label.NO_PRODUCT_ADDED;
        }else if(quoteRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && !quoteRecord.IsSyncing){ //Checking Quote either synced or not before generating order for SSD
            return System.Label.Synced_Quote_can_generate_Order;
        }
        
        //Check Active Sold To Role(Branch) only for Primary Orders
        if(quoteRecord != null 
           && String.isNotBlank(quoteRecord.Opportunity.Sales_Branch_Name__c) 
           && quoteRecord.Sold_to_Business_Partner__c != null 
           && String.isNotBlank(quoteRecord.Transaction_Type__c)
           && (quoteRecord.Transaction_Type__c == GlobalConstants.ORDER_TYPE_PRIMARY 
               || System.Label.Interio_B2B_Parimary.contains(quoteRecord.Transaction_Type__c))){
                   //Check for Business Partner Status for Sold To and Ship To
                   List<Branch__c> branches = [Select Id,Branch_Name__c, Business_Partner_Status_Ship_To__c, Business_Partner_Status__c 
                                               FROM Branch__c 
                                               WHERE Branch_Name__c =: quoteRecord.Opportunity.Sales_Branch_Name__c
                                               AND Business_Partner__c =: quoteRecord.Sold_to_Business_Partner__c
                                               AND Business_Partner_Status__c = 'Open' 
                                               LIMIT 1];
                   if(branches == null || branches.size() == 0 && quoteRecord.Record_Type_Developer_Name__c !=  GlobalConstants.QUOTE_RECORDTYPE_SSD){
                       return System.Label.Order_for_Inactive_Business_Partner_Status_Branch_error;
                   }        
               }
        //SMF-59:Adding sanction for MHE. Added validation for MHE Sanction
        if(quoteRecord.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS && 
               (
                quoteRecord.LD_Applicable__c || quoteRecord.Credit_Terms__c || quoteRecord.Special_Delivery_Period__c ||
                quoteRecord.BG_Status__c==GlobalConstants.STATUS_REQUESTED || quoteRecord.CG_Status__c==GlobalConstants.STATUS_REQUESTED
               )
        ){
            String error='';
            if(quoteRecord.LD_Applicable__c){
                String errorMessageText = 'LD Approval is Pending.';
                error= String.isBlank(error)?errorMessageText: error+' '+errorMessageText;
            }
            if(quoteRecord.Credit_Terms__c){
                String errorMessageText = 'CT Approval is Pending.';
                error= String.isBlank(error)?errorMessageText: error+' '+errorMessageText;
            }
            if(quoteRecord.Special_Delivery_Period__c){
                String errorMessageText = 'Special Delievery Approval is Pending.';
                error= String.isBlank(error)?errorMessageText: error+' '+errorMessageText;
            }
            if(quoteRecord.BG_Status__c==GlobalConstants.STATUS_REQUESTED){
                String errorMessageText = 'BG Approval is Pending.';
                error= String.isBlank(error)?errorMessageText: error+' '+errorMessageText;
            }
            if(quoteRecord.CG_Status__c==GlobalConstants.STATUS_REQUESTED){
                String errorMessageText = 'CG Approval is Pending.';
                error= String.isBlank(error)?errorMessageText: error+' '+errorMessageText;
            }
            return error;
        }
        return null;
    }
    
    /*
* @description create order record DS.
* @param quote record id
* @return order record 
*/
    private SObjectMapperConfigurator createOrderDS(String quoteId) {
        //quoteKey = quoteRecordType + Transaction Type i.e Primary or Secondary
        String quoteKey;
        //Store quoteKey to Order record type to create order of that record type. use 'Quote To Order RecordType Mapping'
        Map<String,String> quoteToOrderRecordTypeMapping = new Map<String,String>();   
        List<Quote_To_Order_RecordType_Mapping__mdt> rtMapping = [Select Id,Quote_RecordType_Key__c,Order_Record_Type_Name__c 
                                                                  FROM Quote_To_Order_RecordType_Mapping__mdt];
        for(Quote_To_Order_RecordType_Mapping__mdt rtMap : rtMapping){
            quoteToOrderRecordTypeMapping.put(rtMap.Quote_RecordType_Key__c,rtMap.Order_Record_Type_Name__c);
        }
        
        //Fetch quote details to construct quoteKey
        List<Quote> quoteRec = [Select Id,RecordType.DeveloperName,Transaction_Type__c,
                                AccountId,OpportunityId,Opportunity.Internal_Sales_Rep__c,Sold_To_Business_Partner__c,
                                Opportunity.OwnerId,Record_Type_Developer_Name__c FROM Quote WHERE Id =: quoteId];
        if(quoteRec != null){
            String sTxntype=quoteRec[0].Transaction_Type__c;
            for(String sTxnTypeVar:GlobalConstants.TRANSACTION_TYPE_INTERIO_B2B.keySet()){
                if(sTxnTypeVar.contains(sTxntype) && quoteRec[0].RecordType.DeveloperName != GlobalConstants.QUOTE_RECORDTYPE_SSD){ //SSD Record Type Added by Sreekanth Jujare){
                    sTxntype=GlobalConstants.TRANSACTION_TYPE_INTERIO_B2B.get(sTxnTypeVar);
                }
                quoteKey = String.isBlank(quoteRec[0].Transaction_Type__c) ? quoteRec[0].RecordType.DeveloperName : quoteRec[0].RecordType.DeveloperName+'-'+sTxntype;/*quoteRec[0].Transaction_Type__c;*/
            }
        } 
        
        //Store order RecordTypeId based on order record type dev name
        Id recordTypeId;
        String orderRecordType;
        if(quoteToOrderRecordTypeMapping.containsKey(quoteKey)){
            orderRecordType = quoteToOrderRecordTypeMapping.get(quoteKey);
            recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(quoteToOrderRecordTypeMapping.get(quoteKey)).getRecordTypeId();
        }
        
        //This user will be used to get user related details for order mapping
        String userId = quoteRec[0].Opportunity.Internal_Sales_Rep__c != null ? quoteRec[0].Opportunity.Internal_Sales_Rep__c : quoteRec[0].Opportunity.OwnerId;
        
        //Build SObjectConfig for mapping of fields and create order
        SObjectMapperConfigurator config = new SObjectMapperConfigurator();
        User usr = [Select Id,Logistic_Company__c FROM USER Where id =: UserInfo.getUserId() LIMIT 1];
        String branchName = usr.Logistic_Company__c;
        //Added by subhojit
        config.quoteRecordTypeDeveloperName=quoteRec[0].RecordType.DeveloperName ;
        //traget object name for which record will be created i.e. Order 
        config.targetObjectName = GlobalConstants.ORDER_SOBJECT_API_NAME;
        //Default values for target object
        config.defaultValues = new Map<String,Object>{
            'EffectiveDate'=>GlobalConstants.ORDER_DEFAULT_STARTDATE,//Default as Today
                'Status'=>GlobalConstants.ORDER_DEFAULT_STATUS,//Default as Draft
                'RecordTypeId'=>recordTypeId//Based on quoteKey
                };
                    //Custom metadata name which will be used for field mapping i.e 'SObject To Order Mapping'                            
                    config.metadataName = GlobalConstants.ORDER_MAPPING_METADATA;
        config.objetNameVsWhereClause = new Map<String,String>{
            GlobalConstants.QUOTE_SOBJECT_API_NAME => 'Id =\'' + quoteId +'\' LIMIT 1',
                GlobalConstants.USER_SOBJECT_API_NAME => 'Id =\''+ userId +'\'',
                GlobalConstants.AccountObjApiName =>'Id =\''+quoteRec[0].AccountId + '\'',
                GlobalConstants.OPPORTUNITY_SOBJECT_API_NAME => 'Id =\''+quoteRec[0].OpportunityId + '\''
                };
                    if(quoteRec[0].Sold_To_Business_Partner__c != null && String.isNotBlank(branchName)){
                        config.objetNameVsWhereClause.put(GlobalConstants.BRANCH_SOBJECT_API_NAME,
                                                          'Branch_Name__c =\''+branchName+'\' AND Business_Partner__c =\''+quoteRec[0].Sold_To_Business_Partner__c+'\' LIMIT 1');                                        
                    }
        //Source object name from where record is being created i.e Quote                                    
        config.sourceObjectName = GlobalConstants.QUOTE_SOBJECT_API_NAME;                                    
        config.sourceObjectUniqueField = GlobalConstants.QUOTE_ORDER_MAPPING_UNIQUE_FIELD;
        List<String> transactionType = new List<String>();
        //Updated by Subhoji
        if(quoteKey.contains('-'))
            transactionType=quoteKey.split('-');
        config.transactionType = transactionType.size() > 1 && GlobalConstants.TRANSACTION_TYPE.containsKey(transactionType[1]) ? GlobalConstants.TRANSACTION_TYPE.get(transactionType[1]) : GlobalConstants.ALL_TRANSACTION_TYPE;
        
        return config;
    }
    
    /*
* @description create OrderItem record DS.
* @param OrderId,QuoteId,TransactionType,OrderRecordType
* @return List<OrderItem>
*/
    private List<OrderItem> createOrderItemDS(String orderId, String quoteId, String transactionType, String sRecordType) {
        SObjectMapperConfigurator config = new SObjectMapperConfigurator();
        config.targetObjectName = GlobalConstants.ORDER_ITEM_SOBJECT_API_NAME;
        config.defaultValues = new Map<String,Object>{
            'OrderId'=>orderId
                };
                    config.metadataName = GlobalConstants.ORDER_LINE_ITEM_MAPPING_METADATA;
        config.objetNameVsWhereClause = new Map<String,String>{
            GlobalConstants.QUOTE_LINE_ITEM_SOBJECT_API_NAME => 'QuoteId =\'' + quoteId +'\''                                            
                };
                    config.sourceObjectName = GlobalConstants.QUOTE_LINE_ITEM_SOBJECT_API_NAME;                                    
        config.sourceObjectUniqueField = GlobalConstants.QUOTE_ORDER_MAPPING_UNIQUE_FIELD;
        config.transactionType = transactionType;
        config.quoteRecordTypeDeveloperName=sRecordType;
        List<OrderItem> newOrderItems = (List<OrderItem>)SObjectMappingManager.doMapping(config);
        return newOrderItems;
    }
    
    private Map<Id, OrderItem> createQuoteVSOrderItemMap(List<OrderItem> newOrderItems) {
        Map<Id, OrderItem> quoteIdVSOrderItemMap = new Map<Id, OrderItem>();
        for(OrderItem orderItem : newOrderItems) {
            quoteIdVSOrderItemMap.put(orderItem.QuoteLineItemId, orderItem);
        }
        return quoteIdVSOrderItemMap;
    }
    
    @AuraEnabled
    public static Order createOrder(String quoteId, String quoteToOrderRecordsJSON,Opportunity opportunityRecord, Order orderRecFromLWC) {
        try {
            QUOTEMANAGER_INSTANCE.quoteLineItemMap = new Map<Id, QuoteLineItem>([Select Id, Product2.Name, Quantity, Approved_Customer_Discount__c, Product2.Item__c,
                                                                                 Approved_WD_Retention__c, Approved_SAC_ORC__c, (Select Id, Quantity FROM OrderItems) FROM QuoteLineItem WHERE QuoteId =: quoteId ]);
            
            quote quo = [select id,OpportunityId,Sold_to_Address__r.Integration_Status__c, Ship_To_Address__r.Integration_Status__c,Record_Type_Developer_Name__c from quote where Id =: quoteId];
            
            Id OppId=quo.OpportunityId;
            
             //Added by rohit jadhav to bypass for PED on 07 September 2023
            if(quo.Record_Type_Developer_Name__c != GlobalConstants.PED_QUOTE_RT){
                List<Opportunity> oppRecords=[select id,Opportunity_Status__c from Opportunity where Id =:OppId];
                oppRecords[0].Opportunity_Status__c='Closed Won';
                update oppRecords;
            }
            
            string errorMessage = '';
             if (quo.Sold_to_Address__r.Integration_Status__c != 'Synced' && quo.Ship_to_Address__r.Integration_Status__c != 'Synced'
              //Condition added by Sreekanth Jujare on 08/07/2022 for SSD and Interio B2C VFD
                && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_INTERIO_B2C_VFD
                && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD){
               errorMessage = 'Sold to address and ship to address are not synced. ';
               AuraHandledException auraEx = new AuraHandledException(errorMessage);
               auraEx.setMessage(errorMessage);
               throw auraEx;
            }else   //Record Type Condition IF condition  added by Sreekanth Jujare on 03/10/2022 to skip the error for Interio B2C VFD and SSD
            if (quo.Sold_to_Address__r.Integration_Status__c != 'Synced' && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_INTERIO_B2C_VFD
               && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD){
               errorMessage = 'Sold to address is not synced. ';
               AuraHandledException auraEx = new AuraHandledException(errorMessage);
               auraEx.setMessage(errorMessage);
               throw auraEx;
            }else
                    //Record Type Condition IF condition  added by Sreekanth Jujare on 03/10/2022 to skip the error for Interio B2C VFD and SSD
            if (quo.Ship_To_Address__r.Integration_Status__c != 'Synced' && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_INTERIO_B2C_VFD
               && quo.Record_Type_Developer_Name__c != GlobalConstants.QUOTE_RECORDTYPE_SSD){
               errorMessage = 'Ship to address is not synced';
               AuraHandledException auraEx = new AuraHandledException(errorMessage);
               auraEx.setMessage(errorMessage);
               throw auraEx;
            } else if
             (!String.isBlank(errorMessage)){
                 errorMessage = 'Please maintain sold to address or ship to address';
                AuraHandledException auraEx = new AuraHandledException(errorMessage);
                auraEx.setMessage(errorMessage);
                throw auraEx;
            
             }
            SObjectMapperConfigurator config = QUOTEMANAGER_INSTANCE.createOrderDS(quoteId);
            List<Order> newOrder = (List<Order>)SObjectMappingManager.doMapping(config);
            String orderRecordType = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosById().get(newOrder[0].RecordTypeId).getDeveloperName();
            //added by Shreela 
            Id currentUserId = UserInfo.getUserId();
            Id userProfileId = UserInfo.getProfileId();
            List<User> userType = [Select Profile.UserType from User where  ProfileId=:userProfileId and Id=:currentUserId];
            for(User usr : userType){
                
                String userTypeName = usr.Profile.UserType;
                if(userTypeName=='PowerPartner'){
                    newOrder[0].External_Sales_Representative__c = currentUserId;
                }
            }
            
            //ended by Shreela
            
            //Get mtd which will be used to validate if OrderItem records to be created or not
            List<Create_Order_Line_Item__mdt> orderLineMtd = [Select Id,DeveloperName,Create__c,Do_not_send_to_Infor__c 
                                                              FROM Create_Order_Line_Item__mdt WHERE DeveloperName =:orderRecordType LIMIT 1];
            if(orderLineMtd != null && orderLineMtd.size() > 0) {
                newOrder[0].Do_not_send_to_Infor__c = orderLineMtd[0].Do_not_send_to_Infor__c;
            }
            
            //Added by Rohit Jadhav for Locks B2C ISTD on 16/03/2023 
            if(opportunityRecord.RecordType.DeveloperName==GlobalConstants.RECORDTYPE_Locks_B2C_ISTD){
                newOrder[0].Area_Code_For_IGST__c=opportunityRecord.Area_Code_For_IGST__c;
                newOrder[0].Logistics_Company_Branch__c=opportunityRecord.Sales_Branch_Name__c;
            }
            if(quo.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && orderRecFromLWC != null){
                newOrder[0].Order_Won_Lost__c=orderRecFromLWC.Order_Won_Lost__c;
                newOrder[0].Reason_for_Lost__c=orderRecFromLWC.Reason_for_Lost__c;
                newOrder[0].Reason_for_Lost_If_others__c=orderRecFromLWC.Reason_for_Lost_If_others__c;
            }
            insert newOrder;
            //create order line items
            if(orderLineMtd != null && orderLineMtd.size() > 0 && orderLineMtd[0].Create__c){
                QUOTEMANAGER_INSTANCE.createOrderLineItems_WithDefaultValues(newOrder[0].Id, quoteId, config, quoteToOrderRecordsJSON);
            }
            return newOrder[0];
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public void createOrderLineItems_WithDefaultValues(String orderId, String quoteId, SObjectMapperConfigurator config, String quoteToOrderRecordsJSON) {
        List<OrderItem> newOrderItems = QUOTEMANAGER_INSTANCE.createOrderItemDS(orderId, quoteId, config.transactionType, config.quoteRecordTypeDeveloperName);
        Map<Id, OrderItem> quoteIdVSOrderItemMap = QUOTEMANAGER_INSTANCE.createQuoteVSOrderItemMap(newOrderItems);
        List<QuoteLineItemMapper> quoteLineItemMapperList = (List<QuoteLineItemMapper>)JSON.deserialize(quoteToOrderRecordsJSON, List<QuoteLineItemMapper>.class);
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        //Added by anupam to create order with single line item for construction division B2B
        List<pricebookEntry> prcbokEntry = [Select Id, ProductCode, Pricebook2.Name from PricebookEntry where ProductCode =: System.Label.Construction_SO_from_SF_to_LN and Pricebook2.Name like '%Construction%' limit 1];
        List<Product2> pdt=[select Id, Item__c from product2 where Item__c =: System.Label.Construction_SO_from_SF_to_LN limit 1];
        if(config.quoteRecordTypeDeveloperName ==GlobalConstants.RECORDTYPE_Construction_B2B && !prcbokEntry.isEmpty() &&  !pdt.isEmpty()){
            OrderItem oLIobj = new OrderItem();
            oLIobj.OrderId=orderId;
            oLIobj.Product2Id=pdt[0].Id;
            oLIobj.PricebookEntryId=prcbokEntry[0].Id;
            oLIobj.Quantity =1;
            oLIobj.UnitPrice=1;           
            orderItemsToInsert.add(oLIobj);
        }else{
            for(QuoteLineItemMapper quoteLineMapperObj : quoteLineItemMapperList) {
                OrderItem orderItemObj = quoteIdVSOrderItemMap.get(quoteLineMapperObj.id);
                orderItemObj.Quantity = quoteLineMapperObj.order_quantity;
                orderItemsToInsert.add(orderItemObj);                
            }
        }
        insert orderItemsToInsert;
    }
    
    // Added new method to getOpportunityData in generateOrderLWC component.
     @AuraEnabled
    public static Opportunity getOpportunityData(String quoteId) {        
        Quote quoteRecord = [Select Id, OpportunityId FROM Quote WHERE Id = : quoteId limit 1];
        Opportunity opportunityRecord =[Select Id, Sales_Branch_Name__c,Area_Code_For_IGST__c,RecordTypeId,RecordType.DeveloperName
                                         FROM Opportunity WHERE Id = : quoteRecord.OpportunityId limit 1];
        return opportunityRecord;                           
    }
    @AuraEnabled(cacheable=true)
    public static String getOrderRecordTypeIdLabel() { 
        return Label.SSD_Order_Record_Type_Id; 
    }
}