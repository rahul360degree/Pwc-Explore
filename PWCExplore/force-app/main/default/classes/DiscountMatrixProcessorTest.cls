@isTest
public class DiscountMatrixProcessorTest {

   @testSetup
    private static void createTestRecords(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'AppUser', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.Appuser@godrej.com', username = 'test.Appuser@godrej.com', Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT);

        userToRun.Persona__c = 'Appliances- Self Calling Executive';
        userToRun.Logistic_Company__c = '5020';
        userToRun.IsActive = true; 
        insert userToRun;
        
        
                System.runAs(userToRun) {
                    Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.DiscountMatrixTriggerDisabled__c = true;
                    setting.OrderProductTriggerDisabled__c = true;
                    insert setting;
                
                    
        //added by Shreela on 5th August 2022
        //Create Account
        Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
        insert newAccount;
        
        Opportunity newOpp = new Opportunity(Name = 'Test Opp',AccountId = newAccount.Id, Sales_Branch_Name__c = '3010',               
                                         LeadSource = 'Advertisement',Business_Unit__c = 'H',Organization_Name__c = '18-30 Lakhs',         
                                         Birthdate__c = Date.valueOf('1992-01-23'),Amount = 8866.85,Anniversary__c = Date.valueOf('2019-11-07'),  
                                         CloseDate = Date.today().addDays(28),StageName = 'Meeting Scheduled',ForecastCategoryName = 'Pipeline',            
                                         Probability = 35,Occupation__c = 'Business',Area_Code__c = 'EA1',Room_Planner_Demo_Done__c = 'No',             
                                         Product_Configuration_Demo_Given__c = 'Yes',Exchange_Order__c = 'No',                     
                                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId());
        
        insert newOpp;
        
        Quote newQuote = new Quote(Name = 'Test Quote',Opportunity_Owner__c = UserInfo.getUserId(),Status = 'Draft',                             
                             OpportunityId = newOpp.Id,Approval_Status__c = 'Approval Not Required',ExpirationDate = Date.today().addDays(20),      
                             Area_Code__c = 'EA1',Quote_Type__c = 'Customer Facing');
        insert newQuote;
        
        //Create Order 
        Order newOrder = new Order( Logistics_Company_Branch__c = '3010',Line_of_Business__c = 'E&P',Business_Unit__c = 'H',                                                
                                   AccountId = newAccount.Id,EffectiveDate = System.today(),Status = 'Draft',  
                                   QuoteId = newQuote.Id,OpportunityId = newOpp.Id,Owner_Manager_Email__c='abc@gmail.com',
                                   Area__c = 'WN1',
                                   RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId());
        insert newOrder;
        
        //ended by Shreela on 5th August 2022
        
        
        Discount_Matrix__c dm = new Discount_Matrix__c( 
                                       Name='No Discount', 
                                       Discount_Percent__c=0, 
                                       Discount_Amount__c=1,
                                       Gross_Net__c='2', 
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
        matrix.Discount_amount__c=6000;
        matrix.Level__c='2';
        matrix.Start_Date__c=(date.today()).addDays(5); //replace with 5 
        matrix.End_Date__c=(date.today()).addDays(5);
        matrix.Stage__c='Active';
        matrix.Business_Unit__c='H';
        matrix.Matrix_Source__c='Salesforce';
        matrix.Type__c='Discount';
        matrix.Gross_Net__c='2';
        matrix.code__c = 'W56';
        matrix.Area__c ='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrix.order_Currency__C = 'INR';
        matrixList.add(matrix);
        //Insert matrix;
        
        Discount_Matrix__c matrix2=new Discount_Matrix__c();
        matrix2.Name='Test Appliance Matrix2';
        matrix2.Discount_Amount__c=2000;
        matrix2.Level__c='2';
        matrix2.Discount_Code__c='HA9';
        matrix2.Start_Date__c=(date.today()).addDays(5); //replace with 5 
        matrix2.End_Date__c=(date.today()).addDays(5);
        matrix2.Stage__c='Active';
        matrix2.Business_Unit__c='H';
        matrix2.Matrix_Source__c='Infor';
        matrix2.Type__c='Discount';
        matrix2.Gross_Net__c='2';
        matrix2.code__c = 'W56';
        matrix2.Area__c ='EA2';
        matrix2.price_list__c = Test.getStandardPricebookId();
        matrix2.order_Currency__C = 'INR';
        matrixList.add(matrix2);
         Discount_Matrix__c matrix1=new Discount_Matrix__c();
        matrix1.Name='Test Appliance Matrix1';
        matrix1.Discount_Code__c='HA9';
        matrix1.Discount_amount__c=8000;
        matrix1.Level__c='3';
        matrix1.Start_Date__c=(date.today()).addDays(5); //replace with 5 
        matrix1.End_Date__c=(date.today()).addDays(5);
        matrix1.Stage__c='Active';
        matrix1.Business_Unit__c='H';
        matrix1.Matrix_Source__c='Infor';
        matrix1.Type__c='Discount';
        matrix1.Gross_Net__c='2';
        matrix1.code__c = 'W56';
        matrix1.Area__c ='EA1';
        matrix1.price_list__c = Test.getStandardPricebookId();
        matrix1.order_Currency__C = 'INR';
         matrixList.add(matrix1);
        Insert matrixList;
        
       Account acct=new Account();
       acct.Name='test Account';
       acct.Pan__c='AFDCS5354R';    
       acct.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId();
       acct.Business_Unit__c='H';
       Insert acct;
    }
    }
    
   
 
    @isTest
   public static void insertOrderAndOrderItems(){
       Test.startTest();
       User runAsUser=[Select Id From User Where username = 'test.Appuser@godrej.com' Limit 1];
        System.runAs(runAsUser){
       account acct = [select id from account where Pan__c='AFDCS5354R' limit 1];
       
       Product2 product = [select id from product2 where item__c = 'mob123' limit 1];
       
       Id appliancePrimaryRecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId();
       //insert order
       OrderTriggerHandler.triggerDisabled = true; //uncommented by Shreela on 11th April 2022
       Order order=new Order();
       order.RecordTypeId=appliancePrimaryRecordTypeId;
       order.Sales_Type__c=GlobalConstants.SALES_TYPE_PRIMARY;
       order.Business_Unit__c='H';
       order.AccountId=acct.Id;
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
       List<OrderItem> itemList = new List<OrderItem>();
       OrderItem lineItem=new OrderItem();
       lineItem.Product2Id=product.Id;
       lineItem.Quantity=1;
       lineItem.orderId=order.Id;
       lineItem.Product2Id=product.Id;
       lineItem.PricebookEntryId=[Select Id From PriceBookEntry Limit 1].Id;
       lineItem.UnitPrice=30;
       lineItem.Price_origin__c= 'extern';
       //lineItem.area__c = 'EA2';
       itemList.add(lineItem);
       OrderItem lineItem1=new OrderItem();
       lineItem1.Product2Id=product.Id;
       lineItem1.Quantity=3;
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

       DiscountMatrixProcessor c = new DiscountMatrixProcessor();
       c.processDiscountMatrix(orderItemMap);
       
       List<Discount_Matrix__c> cList = [select id,name from Discount_Matrix__c where name like '%Test Appliance%' ];
       for(Discount_Matrix__c v:cList){
           
               v.Stage__c = 'Inactive';
               v.Discount_Amount__c = 16000;
       }
       update cList; 
       
   }
	Test.stopTest();
   }
    
     /*------------------------------------------------------------------------
    Author     :  Shreela Nair
    Date       :  05/08/2022
    Description:  Test  Method to update Discount Code
    Inputs     :  
----------------------------------------------------------------------------*/       

        @isTest
        public static void updateDiscountCodeOnOrderUpdateTest() {
            Order ApplOrder = [SELECT Id,Business_unit__c,Area__c FROM Order WHERE Business_Unit__c =: GlobalConstants.APPLIANCE_BUSINESS_UNIT  Limit 1];
        	ApplOrder.Area__c = 'WP1';
            update ApplOrder;
        }
        

}