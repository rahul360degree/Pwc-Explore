@isTest
private class CreateServiceRequestsFromFlowTest {

   @testSetup
   private static void testDataSetup(){
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
       
         List<Discount_Matrix__c> matrixList=new List<Discount_Matrix__c>();
        Discount_Matrix__c matrix=new Discount_Matrix__c();
        matrix.Name='Test Appliance Matrix';
        matrix.Discount_Code__c='HA9';
        matrix.Discount_Percent__c=8;
        matrix.Level__c='2';
        matrix.Start_Date__c=(date.today()).addDays(-5);
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Stage__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Matrix_Source__c='Salesforce';
        matrix.Type__c='Discount';
        matrix.Gross_Net__c='1';
        matrix.code__c = 'W56';
        matrix.Area__c ='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrix.order_Currency__C = 'INR';
        matrixList.add(matrix);
        //Insert matrix;
        Insert matrixList;
        
       Account acct=new Account();
       acct.Name='test Account';
       acct.Pan__c='AFDCS5354R';    
       acct.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId();
       acct.Business_Unit__c='H';
       Insert acct;
       
       Contact con = new Contact(LastName = 'testContact4', AccountId = acct.Id);
       insert con;
       
       Id applianceTertiaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Tertiary').getRecordTypeId();
       
       Order order=new Order();
       order.RecordTypeId=applianceTertiaryRecordTypeId;
       order.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
       order.Business_Unit__c='H';
       order.AccountId=acct.Id;
       order.Status='Draft';
       order.Is_Create_Demo_Installation_Request__c = true;
       order.Sales_Price_List__c=Test.getStandardPricebookId();
       order.Area__c ='EA2';
       order.EffectiveDate = date.today();
       order.Pricebook2Id = Test.getStandardPricebookId();
       order.order_currency__c = 'INR';
       Insert order;
       
       order.Area__c = 'EA1';
       update order;
       
       /*Payment_Term__c paymentTerm=new Payment_Term__c(Business_Unit__c='H',Area_Code__c='EA1');
       insert paymentTerm;*/
       
       List<OrderItem> itemList = new List<OrderItem>();
       OrderItem lineItem=new OrderItem();
       lineItem.Product2Id=product.Id;
       lineItem.Quantity=1;
       lineItem.orderId=order.Id;
       lineItem.Product2Id=product.Id;
       lineItem.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
       lineItem.UnitPrice=30;
       lineItem.Price_origin__c= 'extern';
       //lineItem.Is_payment_available__c = true;
       //lineItem.area__c = 'EA2';
       itemList.add(lineItem);
       Insert itemList;
       
   }
   
    @isTest private static void createCasesTest(){
        CreateServiceRequestsFromFlow.ServiceRequestWrapper srw = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
        srw.isFromOrderSaleCapture = true;
        srw.isClone = true;
        srw.isQuickCreate = true;
        CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{srw});
    }
    
    @isTest private static void captureOrderSalesTest(){
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isFromOrderSaleCapture = true;
       wrapper.quantities = new List<Integer>{1};
       wrapper.recordIds = new List<String>{[Select id From OrderItem limit 1].id};
       wrapper.recordId = [Select id From Order limit 1].id;
       wrapper.assetSerialNumbers = new List<String>{'dfdg545'};
       Test.startTest();
       CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper});
       Test.stopTest();
       System.assert([Select id from Case limit 1].size() > 0);  
    }
    
    @isTest private static void captureOrderSalesTestNullOrderId(){
        CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
        wrapper.isFromOrderSaleCapture = true;
        wrapper.quantities = new List<Integer>{1};
        wrapper.recordIds = new List<String>{[Select id From OrderItem limit 1].id};
        wrapper.assetSerialNumbers = new List<String>{'dfdg545'};
        Test.startTest();
            CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper});
        Test.stopTest();
        System.assert([Select id from Case limit 1].size() > 0);  
    }
    
     @isTest private static void captureOrderSalesTestExceptionInCaseCreation(){
       Id orderItemId = [Select id from OrderItem limit 1].id;
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isFromOrderSaleCapture = true;
       wrapper.quantities = new List<Integer>{1};
       wrapper.recordIds = new List<String>{orderItemId};
       Test.startTest();
         try{
             CreateServiceRequestsFromFlow.captureOrderSales(wrapper); 
         }catch(Exception ex){
             System.assert(ex.getMessage() != null);
         }
       Test.stopTest();
    }
    
    @isTest private static void cloneCasesTest(){
        Test.startTest();
        Id serviceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        Case cs = new Case(AccountId = [Select id from Account limit 1].Id,
                           ContactId = [Select id from Contact limit 1].Id,
                           RecordTypeId = serviceRequestRecordTypeId);  
        insert cs;
        CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
        wrapper.isClone = true;
        wrapper.quantities = new List<Integer>{1};
        wrapper.recordId = cs.id;
        wrapper.serialNumbers = 'dsdgsdg123';
        //Test.startTest();
            CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper});
        Test.stopTest();
        System.assert([Select id from Case limit 1].size() > 0);  
    }
    
    @isTest private static void createCaseRecordsTest(){
        Test.startTest();
       Id serviceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        Case cs = new Case(AccountId = [Select id from Account limit 1].Id,
                           ContactId = [Select id from Contact limit 1].Id,
                           Service_Request_Type__c = 'Repair', Service_Required_For__c = 'repair',
                           RecordTypeId = serviceRequestRecordTypeId);  
        insert cs;
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isQuickCreate = true;
       wrapper.quantities = new List<Integer>{1};
       wrapper.recordIds = new List<String>{[Select id From Product2 limit 1].id};
       wrapper.caseRecord = [Select id, Status, Service_Request_Type__c, Service_Required_For__c, ContactId, Address_By_BP__c From Case limit 1];
       wrapper.assetSerialNumbers = new List<String>{'dfdg545'};
       wrapper.productCategories = new List<String>{'REFRIGERATOR', 'WASHER', 'DVD'};
       //Test.startTest();
       CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper});
       Test.stopTest();
       System.assert([Select id from Case limit 1].size() > 0);  
    }
    
    @isTest private static void createCaseRecordsTestExceptionInCaseInsert(){
       Test.startTest();
       Id serviceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
       Case cs = new Case(AccountId = [Select id from Account limit 1].Id,
                          ContactId = [Select id from Contact limit 1].Id,
                          Service_Request_Type__c = 'Repair', Service_Required_For__c = 'repair',
                          RecordTypeId = serviceRequestRecordTypeId);  
       insert cs;
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isQuickCreate = true;
       wrapper.quantities = new List<Integer>{1};
       wrapper.recordIds = new List<String>{[Select id From Product2 limit 1].id};
       wrapper.caseRecord = [Select id, Status, Service_Request_Type__c, Service_Required_For__c, ContactId, Address_By_BP__c From Case limit 1];
       wrapper.assetSerialNumbers = new List<String>{'dfdg545'};
       wrapper.productCategories = new List<String>{'REFRIGERATOR', 'WASHER', 'DVD'};
       //Test.startTest();
        try{
            CreateServiceRequestsFromFlow.createCaseRecords(wrapper); 
        }catch(Exception ex){
            System.assert(ex.getMessage() != null);
        }
       Test.stopTest(); 
    }
    
    @isTest private static void createCaseRecordsWithPersonAccount(){
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isQuickCreate = true;
       wrapper.quantities = new List<Integer>{1};
       wrapper.recordIds = new List<String>{[Select id From Product2 limit 1].id};
       wrapper.personAccount = new Account(FirstName = 'Test First', LastName = 'LastTest', PersonMobilePhone = '9878988911');
       wrapper.addressRecord = new Address__c(Building__c = 'Test Building');
       wrapper.caseRecord = new Case(Service_Request_Type__c = 'Repair', Service_Required_For__c = 'Test');
       wrapper.assetSerialNumbers = new List<String>{'dfdg545'};
       wrapper.productCategories = new List<String>{'REFRIGERATOR', 'WASHER', 'DVD'};
       Test.startTest();
       try{
            CreateServiceRequestsFromFlow.createCaseRecords(wrapper); 
       } catch(Exception ex){
           System.assert(ex.getMessage() != null);
       }
       Test.stopTest(); 
    }
    
    @isTest private static void createTertiaryOrderTest(){
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isTertiaryOrderCreation = true;
       wrapper.personAccount = new Account(FirstName = 'Test First', LastName = 'LastTest', PersonMobilePhone = '9878988911');
       wrapper.addressRecord = new Address__c(Building__c = 'Test Building');
       wrapper.orderRecord = new Order(Is_Create_Demo_Installation_Request__c = true);
       Test.startTest();
       try{
            CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper}); 
       } catch(Exception ex){
           System.assert(ex.getMessage() != null);
       }
       Test.stopTest(); 
    }
    
    @isTest private static void createTertiaryOrderWithAccountTest(){
       CreateServiceRequestsFromFlow.ServiceRequestWrapper wrapper = new CreateServiceRequestsFromFlow.ServiceRequestWrapper();
       wrapper.isTertiaryOrderCreation = true;
       wrapper.recordId = [SELECT Id FROM Account LIMIT 1].Id;
       wrapper.orderRecord = new Order();
       Test.startTest();
       try{
            CreateServiceRequestsFromFlow.createCases(new List<CreateServiceRequestsFromFlow.ServiceRequestWrapper>{wrapper}); 
       } catch(Exception ex){
           System.assert(ex.getMessage() != null);
       }
       Test.stopTest(); 
    }
}