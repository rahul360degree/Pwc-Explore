/*------------------------------------------------------------------------
Author:        Saurabh Mehta, Jayasurya Gunasekharan
Company:       Stetig, Stetig
Description:   Trigger runs after the  bill is approved for generating orders and order line items
Inputs:        NA
Last Modified: 26/11/2021
Test Class:    
----------------------------------------------------------------------------*/

public class PrimaryRecordCreationHandler {
    
    // Method is used to createPrimaryRecord for generating orders and order line items
    public static void createOrderandLineItem(List<Billing__c> newBillingList, Map<id,Billing__c> oldBillingMap){
        
        Set<Id> setUpdateBillingRec = new Set<Id>();
        Set<Id> addOrderLineItem = new Set<Id>();
        
        Map<Id, Order> billingOrderMap = new  Map<Id, Order>();
        Map<Id, Billing__c> billingList = new Map<Id, Billing__c>();
        
        List<Billing__c> billingList2 = new List<Billing__c>();
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        List<Pricebook2> priceBookList = new List<Pricebook2>();
        
        for(Billing__c b : newBillingList){
            
            if(b.Approval_Status__c == ElbConstantsClass.APPROVED && oldBillingMap.get(b.id).Approval_Status__c != ElbConstantsClass.APPROVED){
                setUpdateBillingRec.add(b.Id);
            }
        }
        
        //if status is approved
        if(!setUpdateBillingRec.isEmpty()){
            
            billingList = new Map<Id, Billing__c>([SELECT Id, Amount__c, Charge__c, Charge__r.Charge_CCode__c, opportunity__c, opportunity__r.Account.Account_Code__c,
                                                   opportunity__r.Leasing_Sales_Service_Office__c,
                                                   opportunity__r.Account.Integration_Status__c, Total_Amount__c, Narration__c,  opportunity__r.Ship_To_Address__c,
                                                   LastModifiedById, Amount_Payable__c
                                                   FROM Billing__c 
                                                   WHERE ID IN :setUpdateBillingRec LIMIT 20000]); 
            
            
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get(ElbConstantsClass.ORDER_CONSTRUCTION_LEASING).getRecordTypeId();
            
            priceBookList = [Select Id, Name, Business_unit__c
                             from Pricebook2
                             //where Business_unit__c =: ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING];
                             //where name = 'CON_2110 / CONSTRUCTION LEASING PB'];
            				   where Business_unit__c =: ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING and LN_PriceList_Code__c = 'CON']; //and  name like '%LEASING PB'];
            /*List<Sales_Office__c> salesOfficeList = [Select Id, Name 
                                                     from Sales_Office__c 
                                                     where LN_Sales_Office_Code__c =: ElbConstantsClass.SALES_OFFICE_CODE LIMIT 1];*/    //Added by Poonam
            
            //List<Opportunity> salesOfficeList = [Select Id, Name, Sales_Service_Office__c 
                                                     //from Opportunity where Business_unit__c =: ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING  LIMIT 1 ];    //Added by poonam
            
            List<User> userList = [Select Id, Name, Business_Unit__c, Salary_Code__c
                                   from User 
                                   where Business_Unit__c=: ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING AND 
                                   Salary_Code__c =: ElbConstantsClass.USER_SALARY_CODE_RAJEEV LIMIT 1];
            
            for(Billing__c bills : billingList.values()) {
                String intgSTatus = bills.opportunity__r.Account.Integration_Status__c;
                String acctCode = bills.opportunity__r.Account.Account_Code__c;
                if((ElbConstantsClass.SYNCED).equalsIgnoreCase(intgSTatus) && String.isNotBlank(acctCode) && acctCode.startsWithIgnoreCase(ElbConstantsClass.ACCOUNT_SERIES_CHILD)) {
                    Order ord =  new Order();
                    
                    ord.RecordTypeId = orderRecordTypeId;
                    ord.Logistics_Company_Branch__c = ElbConstantsClass.LOGISTICS_COMPANY_BRANCH;
                    ord.Sales_Order_Series__c = ElbConstantsClass.SALES_ORDER_SERIES;
                    ord.Record_Types__c = ElbConstantsClass.ORDER_CONSTRUCTION_LEASING;
                    ord.Business_Unit__c = ElbConstantsClass.BUSINESS_UNIT_CONSTRUCTION_LEASING; 
                    //ord.Sub_Division__c = 'B2B';
                    //ord.Line_of_Business__c = 'BP';
                    //ord.Order_Currency__c = 'INR';
                    //ord.Payment_Terms__c = '360';
                    ord.AccountId = bills.opportunity__r.AccountId;
                    ord.Header_Text__c = bills.Narration__c;
                    ord.Ship_To_Address__c = bills.opportunity__r.Ship_To_Address__c;
                    ord.EffectiveDate = Date.TODAY();
                    ord.Status = ElbConstantsClass.ORDER_STATUS;
                    ord.Sales_Price_List__c = priceBookList[0].Id;
                    //ord.field = salesOfficeList[0].Id;    //earlier
                    ord.Sales_Office__c = bills.opportunity__r.Leasing_Sales_Service_Office__c; // Added by poonam SCF-73
                    ord.Type = ElbConstantsClass.ORDER_TYPE_NOI;
                    if(Test.isRunningTest()){
                        ord.Internal_Sales_Representative__c = userinfo.getuserid();
                    } else {
                        ord.Internal_Sales_Representative__c = userList[0].Id;
                    }
                    billingOrderMap.put(bills.Id, ord);
                }
            }
        }
        
        if(!billingOrderMap.isEmpty()) {
            //insert Order
            try {
                insert billingOrderMap.values();
            } catch(DmlException e) {
                System.debug('The following exception has occurred while inserting billingOrderMapvalues: ' + e.getMessage());
            }
            
            //udpate order in billing
            List<Billing__c> billListToUpdate = new List<Billing__c>();
            for(Id bId : billingOrderMap.keySet()) {
                Billing__c bill = new Billing__c(id=bId);
                if (Schema.sObjectType.Billing__c.fields.Posting_Status__c.isAccessible() && Schema.sObjectType.Billing__c.fields.order__c.isUpdateable()){ 
                    bill.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                    bill.order__c = billingOrderMap.get(bId).id;//assign order
                }
                billListToUpdate.add(bill);
            }
            
            if(!billListToUpdate.isEmpty()) {
                try {
                    update billListToUpdate; 
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while Updating billListToUpdate: ' + e.getMessage());
                }
                
            }
            
            //Mapping Order to Bill
            List<OrderItem> orderItemList = new List<OrderItem>();
            Map<id,Billing__c> orderBillMap = new Map<id,Billing__c>();
            List<Order> OrderObject = new List<Order>();
            
            for(String key : billingOrderMap.keySet()){
                orderBillMap.put(billingOrderMap.get(key).Id, billingList.get(key));
            }
            
            pbeList = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry where Pricebook2Id =: priceBookList[0].Id LIMIT 1000];
            
            
            for(Order ord : billingOrderMap.values()){
                OrderItem lineItem = new OrderItem();
                lineItem.OrderId = ord.id;
                lineItem.Quantity = 1;
                lineItem.UnitPrice =  orderBillMap.get(ord.Id).Amount_Payable__c;
                lineItem.product2Id = orderBillMap.get(ord.Id).Charge__r.Charge_CCode__c;
                lineItem.Price_Origin__c = ElbConstantsClass.ORDER_ITEM_PRICE_ORIGIN_MANUAL;
                for(PricebookEntry pbe: pbeList){
                    if(pbe.Product2Id == orderBillMap.get(ord.Id).Charge__r.Charge_CCode__c){
                        lineItem.PricebookEntryId = pbe.Id;  
                    }
                }
                orderItemList.add(lineItem);
                
                //udpate order Integration Status
                Order orderItem = new Order();
                orderItem.Id = ord.id;
                orderItem.Integration_Status__c = ElbConstantsClass.READ_TO_BE_SYNCED;
                OrderObject.add(orderItem);
            }
            
            //insert Order line item
            try {
                insert orderItemList;
            } catch(DmlException e) {
                System.debug('The following exception has occurred while inserting orderItemList: ' + e.getMessage());
            }
            
            //Update Order
            if(!OrderObject.isEmpty()) {
                try {
                    update OrderObject; 
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while Updating OrderObject: ' + e.getMessage());
                }
                
            }
        }    
    }
}