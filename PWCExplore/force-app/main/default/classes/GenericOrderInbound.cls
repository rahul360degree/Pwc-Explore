/*
 * @Description:The purpose of the GenericOrderInbound class is to handle incoming REST requests
 * 				for creating orders along with associated account and order item data in Salesforce
 * @Author: 	Anshita Motiramani
 * @CreatedDate:10th April 2024
 */

@RestResource(urlMapping='/createaccountorder')
global class GenericOrderInbound {

    // This method is invoked when a POST request is sent to the specified URL.
    @HttpPost
        global static void createOrder() {
            try{
               	// Obtain the incoming REST request.
                RestRequest req = RestContext.request;
                
                RestResponse res = RestContext.response;
             
                // Deserialize the JSON request body into a list of AccountWrapper objects.
                List<AccountWrapper> accountWrappers = (List<AccountWrapper>) JSON.deserialize(req.requestbody.toString(), List<AccountWrapper>.class);            
                
                Map<String, AccountWrapper> wrapperAccMap = new Map<String,AccountWrapper>();
                List<Account> newAccListToInsert = new List<Account>();
                
                // Iterate through each AccountWrapper object to create or update Account records.
                for(AccountWrapper eachAcc : accountWrappers){
                    
                    if(eachAcc.accountId == null || eachAcc.accountId == ''){
                        Account acc = new Account();                        
                       // acc.Id = eachAcc.accountId != null && String.isNotBlank(eachAcc.accountId) ? eachAcc.accountId: null;
                        acc.Salutation = String.isNotBlank(eachAcc.salutation) ? eachAcc.salutation: null;
                        acc.FirstName = String.isNotBlank(eachAcc.firstName) ? eachAcc.firstName: null;
                        acc.LastName = String.isNotBlank(eachAcc.lastName) ? eachAcc.lastName: null;
                        acc.PersonMobilePhone = String.isNotBlank(eachAcc.personMobilePhone) ? eachAcc.personMobilePhone: null;
                        acc.PersonEmail = String.isNotBlank(eachAcc.personEmail) ? eachAcc.personEmail: null;
                        acc.Sub_Division__c = String.isNotBlank(eachAcc.subDivision) ? eachAcc.subDivision: null;
                        acc.RecordTypeId = String.isNotBlank(eachAcc.RecordTypeId) ? eachAcc.RecordTypeId: null;
                        acc.Type = String.isNotBlank(eachAcc.type) ? eachAcc.type: null;
                        acc.Payment_Terms__c = String.isNotBlank(eachAcc.paymentTerms) ? eachAcc.paymentTerms: null;
                        
                        newAccListToInsert.add(acc);
                    } else {
                        wrapperAccMap.put(eachAcc.accountId, eachAcc);
                    }                    
                }
                
                // Insert the new Account records.
                if(newAccListToInsert.size()>0){
                    insert newAccListToInsert;
                    // Map Account IDs to AccountWrappers for further processing.
                    for(Account eachAcc : newAccListToInsert){
                        for(accountWrapper wrappers: accountWrappers){
                            if(wrappers.personMobilePhone == eachAcc.personMobilePhone){
                                //wrappers.accountId = eachAcc.id;
                                wrapperAccMap.put(eachAcc.id , wrappers);
                            }
                        }
                    }
                }
                
                
                List<Order> orderToInsert = new List<Order>();
                
                // Iterate through the mapped AccountWrappers to create Order records.
                for(Id accId : wrapperAccMap.keySet()){
                    Order ordObj = new Order();
                    ordObj.AccountId = accId;
                    ordObj.Type = String.isNotBlank(wrapperAccMap.get(accId).Order.type) ? wrapperAccMap.get(accId).Order.type: null;
                    ordObj.Payment_Terms__c = String.isNotBlank(wrapperAccMap.get(accId).Order.paymentTerms) ? wrapperAccMap.get(accId).Order.paymentTerms: null;
                    ordObj.EffectiveDate = String.isNotBlank(wrapperAccMap.get(accId).Order.effectiveDate.format()) ? wrapperAccMap.get(accId).Order.effectiveDate: null;
                    ordObj.Status = String.isNotBlank(wrapperAccMap.get(accId).Order.status) ? wrapperAccMap.get(accId).Order.status: null;
                    ordObj.Sales_Price_List__c = String.isNotBlank(wrapperAccMap.get(accId).Order.salesPriceList) ? wrapperAccMap.get(accId).Order.salesPriceList: null;
                    ordObj.Ship_To_Address__c = String.isNotBlank(wrapperAccMap.get(accId).Order.shipToAddress) ? wrapperAccMap.get(accId).Order.shipToAddress: null;
                    ordObj.Ship_To_Account__c = accId;
                    ordObj.Pricebook2Id = String.isNotBlank(wrapperAccMap.get(accId).Order.Pricebook2Id) ? wrapperAccMap.get(accId).Order.Pricebook2Id: null;     
                    ordObj.Ship_to_Area_code__c = String.isNotBlank(wrapperAccMap.get(accId).Order.shiptoAreacode) ? wrapperAccMap.get(accId).Order.shiptoAreacode: null;
                    ordObj.Sold_to_Business_Partner__c = accId;
                    ordObj.Sold_To_Address__c = String.isNotBlank(wrapperAccMap.get(accId).Order.soldToAddress) ? wrapperAccMap.get(accId).Order.soldToAddress: null;
                    ordObj.MHE_Division__c = String.isNotBlank(wrapperAccMap.get(accId).Order.MHEDivision) ? wrapperAccMap.get(accId).Order.MHEDivision: null;
                    ordObj.Logistics_Company_Branch__c = String.isNotBlank(wrapperAccMap.get(accId).Order.logisticsCompanyBranch) ? wrapperAccMap.get(accId).Order.logisticsCompanyBranch: null;
                    ordObj.Line_of_Business__c = String.isNotBlank(wrapperAccMap.get(accId).Order.lineofBusiness) ? wrapperAccMap.get(accId).Order.lineofBusiness: null;
                    ordObj.Area__c = String.isNotBlank(wrapperAccMap.get(accId).Order.area) ? wrapperAccMap.get(accId).Order.area: null;
                    ordObj.Sales_Office__c = String.isNotBlank(wrapperAccMap.get(accId).Order.salesOffice) ? wrapperAccMap.get(accId).Order.salesOffice: null;
                    ordObj.Sales_Order_Series__c = String.isNotBlank(wrapperAccMap.get(accId).Order.salesOrderSeries) ? wrapperAccMap.get(accId).Order.salesOrderSeries: null;
                    ordObj.Business_Unit__c = String.isNotBlank(wrapperAccMap.get(accId).Order.businessUnit) ? wrapperAccMap.get(accId).Order.businessUnit: null;
                    ordObj.Sub_Division__c = String.isNotBlank(wrapperAccMap.get(accId).Order.subDivision) ? wrapperAccMap.get(accId).Order.subDivision: null;
                    ordObj.Order_Currency__c = String.isNotBlank(wrapperAccMap.get(accId).Order.orderCurrency) ? wrapperAccMap.get(accId).Order.orderCurrency: null;
                    orderToInsert.add(ordObj);
                }
                
                Map<String, AccountWrapper> wrapperOrderMap = new Map<String,AccountWrapper>();
                
                // Insert the new Order records.
                if(orderToInsert.size()>0){
                    insert orderToInsert;
                    // Map Order IDs to AccountWrappers for further processing.
                     for(id accId : wrapperAccMap.keySet()){
                        for(Order ord : orderToInsert){
                            if(accId == ord.AccountId){
                                wrapperAccMap.get(accId).Order.orderId = ord.Id;
                                wrapperOrderMap.put(ord.Id, wrapperAccMap.get(accId));
                            }
                        }
                    }
                }
                              
                List<OrderItem> orderItemToInsert = new List<OrderItem>();
               // Iterate through AccountWrappers and their OrderItems to create OrderItem records.
                for(AccountWrapper eachWrapper: wrapperAccMap.Values()){
                    for(OrderItemWrapper eachItem: eachWrapper.OrderItems){
                        OrderItem itemObj = new OrderItem();
                        itemObj.Quantity = eachItem.Quantity;
                        itemObj.Product2Id = eachItem.Product2Id;
                        itemObj.ListPrice = eachItem.ListPrice;
                        itemObj.PricebookEntryId = eachItem.PricebookEntryId;
                        itemObj.UnitPrice = eachItem.UnitPrice;
                        itemObj.OrderId = eachWrapper.Order.orderId;
                        system.debug('itemObj -->'+itemObj);
                        orderItemToInsert.add(itemObj);
                    }
                }
                
                // Insert the new OrderItem records.
                if(orderItemToInsert.size()>0){
                    insert orderItemToInsert;
                } 
                
                res.statusCode = 200;
        		res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'true', 'message'=>'Account(s) created and corresponding Order and Order Item(s) created successfully !'}));
            }catch(Exception e){
                System.debug('Error '+e.getMessage());
                System.debug('Error '+e.getLineNumber());
                RestResponse res = RestContext.response;
                res.statusCode = 500;
        		res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'false', 'message'=>e.getMessage()}));
            }
            
            
        }
    
    
    
    
    
    //Wrapper to map Account Data
    public class AccountWrapper{
        public String accountId;
        public String salutation;
        public String firstName;
        public String lastName;
        public String personMobilePhone;
        public String personEmail;
        public String businessUnit;
        public String subDivision;
        public String RecordTypeId;
        public String type;
        public String paymentTerms;
        public String lineOfBusiness;
        public OrderWrapper Order;
        public List<OrderItemWrapper> OrderItems;
    }
    
    //Wrapper to map OrderItem Data
    public class OrderItemWrapper {
        public Decimal Quantity;
        public String Product2Id;
        public Decimal ListPrice;
        public String PricebookEntryId;
        public Decimal UnitPrice;
        
    }
    
    //Wrapper to map Order Data
    public class OrderWrapper {
        public String orderId;
        public String type;
        public String Pricebook2Id;
        public String paymentTerms;
        public Date effectiveDate;
        public String status;
        public String salesPriceList;
        public String shipToAddress;
        public String shipToAccount;
        public String shiptoAreacode;
        public String soldtoBusinessPartner;
        public String soldToAddress;
        public String MHEDivision;
        public String logisticsCompanyBranch;
        public String lineofBusiness;
        public String area;
        public String salesOffice;
        public String salesOrderSeries;
        public String businessUnit;
        public String subDivision;
        public String orderCurrency;
    }
    
}