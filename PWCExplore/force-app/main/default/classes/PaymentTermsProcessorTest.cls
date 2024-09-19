/*------------------------------------------------------------------------
Author:        Anupam Mishra
Company:       GITL
Description:   Test Class for Payment Terms
----------------------------------------------------------------------------*/

@isTest
public class PaymentTermsProcessorTest {

   @testSetup
    private static void createTestRecords(){
       
       Payment_Term__c pt = new Payment_Term__c ( 
                                       Name='No Discount', 
                                       Payment_Terms__c='000', 
                                       Zone__c='NOR',
                                       Channel__c='AMC',  
                                       Status__c='Active', 
                                       Start_Date__c=system.today(),
                                       Payment_Code__c='H-00024'
                              );
       insert pt ;
        
         
       Discount_Matrix__c dm = new Discount_Matrix__c( 
                                       Name='No Discount', 
                                       Discount_Percent__c=0, 
                                       Discount_Amount__c=1,
                                       Gross_Net__c='1', 
                                       Level__c='3', 
                                       Stage__c='Active', 
                                       Start_Date__c=system.today(),
                                       Discount_Code__c='HDH'
                              );
       insert dm;
       
        //get standart price book
       Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,PriceList_Code__c='123',LN_PriceList_Code__c='456');
       Update standardPricebook;
       
       //insert product
       Product2 product = new Product2(Name = 'test product', Family = 'Mobile',Item__c='mob123',Is_Generic_Product__c=true);
       Insert product;
       
         List<Payment_Term__c> matrixList=new List<Payment_Term__c>();
        Payment_Term__c matrix=new Payment_Term__c();
        matrix.Name='Test Appliance Matrix';
        matrix.Payment_Terms__c='000';
        matrix.Payment_Code__c='H-00017';
        matrix.Channel__c='ASP';
        matrix.Start_Date__c=(date.today()).addDays(-5);
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Status__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Area_Code__c='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrixList.add(matrix);
        //Insert matrix;
        
        Payment_Term__c matrix2=new Payment_Term__c();
        matrix2.Name='Test Appliance Matrix2';
        matrix.Payment_Terms__c='106';
        matrix.Payment_Code__c='H-00017';
        matrix.Channel__c='COC';
        matrix.Start_Date__c=(date.today()).addDays(-5);
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Status__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Area_Code__c='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrixList.add(matrix2);
        
         Payment_Term__c matrix1=new Payment_Term__c ();
        matrix1.Name='Test Appliance Matrix1';
        matrix.Payment_Terms__c='106';
        matrix.Payment_Code__c='H-00017';
        matrix.Channel__c='CCP';
        matrix.Start_Date__c=(date.today()).addDays(-5);
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Status__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Area_Code__c='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrixList.add(matrix1);
        Insert matrixList;
        
       Account acct=new Account();
       acct.Name='test Account';
       acct.Pan__c='AFDCS5354R';    
       acct.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId();
       acct.Business_Unit__c='H';
       Insert acct;
    }
   
 
    @isTest
   public static void insertOrderAndOrderItems(){
       
       account acct = [select id from account where Pan__c='AFDCS5354R' limit 1];
       
       Product2 product = [select id from product2 where item__c = 'mob123' limit 1];
       
       Id appliancePrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId();
       //insert order
       Order order=new Order();
       order.RecordTypeId=appliancePrimaryRecordTypeId;
       order.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
       order.Business_Unit__c='H';
       order.AccountId=acct.Id;
       order.Payment_Terms__c ='100';
       order.Status='Draft';
       order.Sales_Price_List__c=Test.getStandardPricebookId();
       order.Area__c ='EA2';
       order.EffectiveDate = date.today();
       order.Pricebook2Id = Test.getStandardPricebookId();
       order.order_currency__c = 'INR';
       Insert order;       
       order.Area__c = 'EA1';
       update order;
      
       
       //insert orderLineItem
       OrderItemTriggerHandler.TriggerDisabled=true;
       List<OrderItem> itemList = new List<OrderItem>();
       OrderItem lineItem=new OrderItem();
       lineItem.Product2Id=product.Id;
       lineItem.Quantity=1;
       lineItem.Payment_terms__c ='000';
       lineItem.orderId=order.Id;
       lineItem.Product2Id=product.Id;
       lineItem.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
       lineItem.UnitPrice=30;
       lineItem.Price_origin__c= 'extern';
       itemList.add(lineItem);
       OrderItem lineItem1=new OrderItem();
       lineItem1.Product2Id=product.Id;
       lineItem1.Quantity=3;
       lineItem.Payment_terms__c ='15';
       lineItem1.orderId=order.Id;
       lineItem1.Product2Id=product.Id;
       lineItem1.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
       lineItem1.UnitPrice=50;
       lineItem1.Price_origin__c= 'extern';
       itemList.add(lineItem1);
       
        OrderItem lineItem2=new OrderItem();
       lineItem2.Product2Id=product.Id;
       lineItem2.Quantity=3;
       lineItem2.orderId=order.Id;
       lineItem.Payment_terms__c ='14';
       lineItem2.Product2Id=product.Id;
       lineItem2.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
       lineItem2.UnitPrice=50;
       lineItem2.Price_origin__c= 'extern';
       itemList.add(lineItem2);
       Insert itemList;       
       lineItem.UnitPrice=40;
       update lineItem;
       
      
       Map<Id,OrderItem> orderItemMap = new Map<Id,OrderItem>();
       orderItemMap.put(lineItem.Id,lineItem);
       PaymentTermProcess c = new PaymentTermProcess();
       c.processPaymentTerm(orderItemMap);       
       List<Payment_Term__c > cList = [select id,name from Payment_Term__c where name like '%Test Appliance%' ];
       for(Payment_Term__c v:cList){
               v.Name='Test';
               v.Payment_Terms__c= '009';
               v.Status__c= 'Inactive';
               v.Payment_Code__c= 'H-00017';
       }
       update cList; 
   }

}