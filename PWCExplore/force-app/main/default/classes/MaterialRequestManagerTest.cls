@isTest
public with sharing class MaterialRequestManagerTest {
         public static final Id targetRecordTypeId=Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().
         get(GlobalConstants.RECEIVABLE_TARGET).getRecordTypeId();
    
  @TestSetup
    public static void prepareData(){
        
        Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                            Gross_Net__c='1', Level__c='2', Stage__c='Active');
        Insert defaultDiscountMatrix;
        
        List<User> usersToInsert=new List<User>();
        Id profileId=[Select Id,Name From Profile Where Name = 'System Administrator'].Id;
        TestUserBuilder tub = new TestUserBuilder();
        tub.setProfileId(profileId);
        User salesUser = tub.getTestRecord();
        salesUser.IsActive=true;
        salesUser.LastName='Branch champion';
        usersToInsert.add(salesUser);
        Insert usersToInsert;
        
        Account newAccount = new TestAccountBuilder()
        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
        .setBusinessUnit('K').setName('test Acc').getSavedTestRecord();
        
        Branch__c branch=new Branch__c(Branch_Name__c='2010',Business_Partner__c=newAccount.id);
        Insert branch;
        
        Address__c address=new Address__c(Address_Code__c='TestAdd');
        insert address;
        
        Address_By_BP__c addressByBp=new Address_By_BP__c(branch__c=branch.Id,Account__c=newAccount.Id,Address_Code__c=address.Id);
        Insert addressByBp;
        
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.Area_Code__c='EA1';
        newAsset.AccountId = newAccount.id;
        newAsset.Address_Code__c=address.Id;
        insert newAsset;
        //Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        //setting.AssetTriggerDisabled__c = true;
        //setting.AccountTriggerDisabled__c = true;
        //insert setting;
        Case caseRec = new TestCaseBuilder()
        .setRecordTypeId(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId())
        .setAccountId(newAccount.Id).setBranch('2010').setMHEDivision(GlobalConstants.MHE_SUB_DIVISION_RENTAL).setAsset(newAsset.Id).getSavedTestRecord();
        
        Service_Form__c form;
            form = new TestServiceFormBuilder()
            .setCaseId(caseRec.Id).setRecordTypeId(Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get('Job_Card').getRecordTypeId()).getSavedTestRecord();
        
        Warehouse__c warehouse=new TestWarehouseBuilder().setName('test warehouse').setWarehouseCode('KBAC1Z').getSavedRecord();
        
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;
        PriceBook2 dealerPriceBook = new PriceBook2(Name = 'KD1_3000 / MHE DEALER PRICE BRANCH', IsActive = true, LN_PriceList_Code__c = 'KD1', PriceList_Code__c = 'KD1_3000');
        insert dealerPriceBook;
        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('02015497 Tyre Sld blk Tread').setDescription('Tyre Sld blk 6.50x10" Tread 5.00F-10 577mm W:160mm 0.99 2340Kg A5 Emrald').setItemCode('25172503SD00026').setComponentType('').getTestRecord()
        };
       insert allProducts;
        
       List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {   
          new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(dealerPriceBook.Id).setUnitPrice(32000).getTestRecord()
       };
       insert allPBEs;
      
       List<SR_Products__c> srProducts = new List<SR_Products__c> {
           new SR_Products__C(Product__c=allProducts[0].Id,Quantify__c=2,Service_Form__c=form.Id,Product_Type__c =GlobalConstants.PRODUCT_TYPE_INCLUSION)          
       };
       insert srProducts;
       
    }
     @isTest
    public static void orderShouldGetCreated() { 
        User u=[Select Id From User where profile.name = 'System Administrator' and IsActive=true limit 1];
        System.runas(u){
            Test.StartTest();
            Service_Form__c form = [Select Id,case__r.AccountId From Service_Form__c Limit 1];
            Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();
            MaterialRequestManager.setPriceBookForDealerConsumption(orderRec);
            orderRec.Logistics_Company_Branch__c = '2010';
            boolean isDealerConsumption = true;          
            orderRec.Sub_Division__c ='B2B';
            orderRec.Record_Types__c='MHE Order - Primary';
            MaterialRequestManager.getRecordTyID(false);                        
            try{
               MaterialRequestManager.insertRecord(form.Id,orderRec, 'Dealer',isDealerConsumption);              
            }
            Catch(exception e){
                
            }
           List<Warehouse__c> warehouses = [Select Id, Warehouse__c From Warehouse__c Limit 1];
            if(warehouses != null){
             orderRec.WarehouseCode__c =  warehouses[0].Id;
            }
            
            
            List<Order> orderCreated=[Select Id,RecordTypeId From Order limit 1];
            MaterialRequestManager.updateServiceForm(form,orderRec.Id);
            Test.StopTest();
        } 
    }
     @isTest
    public static void recordTypeShouldBeMHEPrimaryOrder() {
        String MHE_ORDER_PRIMARY_RECORDTYPEID = string.valueOf(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY));
        Service_Form__c form = [Select Id,case__r.AccountId,Case__r.Asset.Product_Purchased_Warranty_Start_Date__c,
                                Case__r.Asset.Product_Purchased_Warranty_End_Date__c From Service_Form__c Limit 1];
        
        Order  orderRec1=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();
            MaterialRequestManager.setPriceBookForDealerConsumption(orderRec1);
            orderRec1.Logistics_Company_Branch__c = '2010';
            boolean isDealerConsumptionFalse = false;          
            orderRec1.Sub_Division__c ='B2B';
            orderRec1.Record_Types__c='MHE Order - Primary';
            MaterialRequestManager.getRecordTyID(false);
        
        Test.StartTest();
        MaterialRequestManager.InitReturnWrapper wrapper=new  MaterialRequestManager.InitReturnWrapper();
        Sales_Office__c salesOffice = new Sales_Office__c();
        salesOffice.Name = 'K2Y001 / MHE West Zone Hub - Ser Off';
        salesOffice.LN_Sales_Office_Code__c='K2Y001';
        insert salesOffice;
        wrapper.salesServiceOfficeId=salesOffice.id;
                try{
        MaterialRequestManager.insertRecord(form.Id,orderRec1, 'Customer',isDealerConsumptionFalse);    
        wrapper=MaterialRequestManager.init(form.Id);
           MaterialRequestManager.getMRType(form);
        }catch(exception e){
   
        }
          System.assertEquals(GlobalConstants.MHE_PRIMARY,'MHE_Order_Primary');
        Test.StopTest();
        
    }
     //Added by sumith sharma - 9 -05 -2021
    @isTest
    public static void shareOrderWithApprovertest() {
         
        User u=[Select Id From User where profile.name = 'System Administrator' and IsActive=true limit 1];
        Test.startTest();
        System.runas(u){
        Service_Form__c form = [Select Id,case__r.AccountId From Service_Form__c Limit 1];
        Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();
        orderRec.Logistics_Company_Branch__c = '2010';
        boolean isDealerConsumption = true;
        orderRec.Sub_Division__c ='B2B';
            
        MaterialRequestManager.shareOrderWithApprover(orderRec.Id,u.id); 
        }
        Test.stopTest();
    }
      
    @isTest
    public static void InsertOrderProductsTest(){
        Service_Form__c form = [Select Id,case__r.AccountId,Case__r.Asset.Product_Purchased_Warranty_Start_Date__c,
                                Case__r.Asset.Product_Purchased_Warranty_End_Date__c,case__r.AssetId,case__r.Asset.Address_Code__c From Service_Form__c Limit 1];
        Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();   
        Test.startTest();
        MaterialRequestManager.insertOrderProducts(orderRec,form.id,False);
        Test.stopTest();
    }
    
       
   @isTest
   public static void populateSoldToShipToAddresstest(){
       Test.startTest();
       Service_Form__c form = [Select Id,case__r.AccountId,Case__r.Asset.Product_Purchased_Warranty_Start_Date__c,
                                Case__r.Asset.Product_Purchased_Warranty_End_Date__c,case__r.AssetId,case__r.Asset.Address_Code__c From Service_Form__c Limit 1];
        Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();
         Account newAccount = new TestAccountBuilder()
        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
        .setBusinessUnit('K').setName('test Acc').getSavedTestRecord();                             
       
       try{           
            MaterialRequestManager.populateSoldToShipToAddress(form,orderRec, 'Customer');                  
       } catch(exception e){ 
       Test.stopTest();            
       }
   } 
    
   @isTest
   public static void validateOrderProductstest(){
       List<OrderItem> oi=[Select Id,Quantity,OrderId,Product2Id,unitprice From OrderItem ];     
       MaterialRequestManager m = new MaterialRequestManager();
       Test.startTest();
       m.validateOrderProducts(oi); 
       Test.stopTest();
   }
  
    @isTest
       public static void updateSRProductstest(){
       List<OrderItem> oi=[Select Id,Quantity,OrderId,Product2Id From OrderItem Limit 1];
       Test.startTest();
       Service_Form__c form = [Select Id,case__r.AccountId,Order__c From Service_Form__c Limit 1];
        if(oi.size()>0)
           form.Order__c= oi[0].OrderId;      
        
           Map<Id, OrderItem> newItems = new Map<Id, OrderItem>();
            for(OrderItem o :oi ){
               newItems.put(o.orderid,o);             
           }
           MaterialRequestManager mm = new MaterialRequestManager();
           
           mm.updateSRProducts(newItems);
           Test.stopTest();
       }
    
     @isTest
   public static void updateServiceFormtest(){ 
        Service_Form__c form = [Select Id,case__r.AccountId,Order__c From Service_Form__c Limit 1];
        Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).getTestRecord();
        
        Test.startTest();
        MaterialRequestManager.updateServiceForm(form,orderRec.id);
      
        Test.stopTest(); 
                     
   }
      @isTest
    public static void orderProductsShouldBeValidatedOnUpdate() {
        Service_Form__c form = [Select Id,case__r.AccountId From Service_Form__c Limit 1];        
        Test.StartTest();
            Id priceBookId=[Select id from pricebook2 where Name= 'KD1_3000 / MHE DEALER PRICE BRANCH' Limit 1].Id;
            Id SoldTo =  [select Id from Address_By_Bp__c limit 1].Id;
            Id ShipTo =  [select Id from Address_By_Bp__c limit 1].Id;                            
            Order  orderRec=new TestOrderBuilder().setAccountId(form.case__r.AccountId).setBusinessUnit('K').setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(GlobalConstants.MHE_PRIMARY).getRecordTypeId()).getTestRecord();
            orderRec.PriceBook2Id=priceBookId;
            orderRec.Logistics_Company_Branch__c = '6010';
            orderRec.Sub_Division__c = 'B2B';
            boolean isDealerConsumption = false;
            orderRec.Sold_To_Address__c =SoldTo;
            orderRec.Ship_To_Address__c=ShipTo;             
            
            id orderId=MaterialRequestManager.insertRecord(form.Id,orderRec, 'Customer', isDealerConsumption);
            
            MaterialRequestManager.insertOrderProducts(form.Id,orderId,isDealerConsumption);            
            List<OrderItem> oi=[Select Id,Quantity,OrderId,Product2Id From OrderItem Limit 1];
            System.debug('oi'+oi);  
            Test.StopTest();
    }
    
         @isTest
    public static void newAddressByBPRecordShouldBeReturned() {
        test.startTest();
        List<Account> acct=[Select Id From Account Limit 1];
        Address_by_BP__c abp = MaterialRequestManager.getAddressByBP(acct[0].Id,'1000');
        System.assert(abp.Account__c==null);
        test.stopTest();
    }
    
     @isTest
    public static void getdefaultLogisticCompanyTest() {       
       user usr = [SELECT Logistic_Company__c,Sales_Order_Series__c,Business_Line__c,
        Business_Unit__c,Sub_Division__c From User WHERE username=:UserInfo.getUsername()];
        Test.StartTest();
        MaterialRequestManager.getdefaultLogisticCompany();    
        Test.StopTest();
    }

}