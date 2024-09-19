/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-22-2023
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-22-2023   Varun Rajpoot   Initial Version
**/
@isTest
public class OLIFieldPopulatorTest {
    @TestSetup static void createData(){
        Test.startTest();
        
        Product2 prd =  new Product2(Is_Generic_Product__c=True,Product_Type__c = 'HFF',Item_Group__c = '52REFG', name = 'viktest',Description='Test Product',productCode = 'ABC', item__c = 'abctest',isActive = true);
        insert prd;
        
        Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                        Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                        Gross_Net__c='1', Level__c='2', Stage__c='Active');
        DiscountMatrixTriggerHandler.TriggerDisabled=TRUE;
        Insert defaultDiscountMatrix;
        DiscountMatrixTriggerHandler.TriggerDisabled=FALSE;
        
        Address__c addr = createPrimaryAddress();
        insert addr;
        
        Account accountrecord = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
        insert accountrecord;
        
        
        Branch__c branch = new Branch__c();
        branch.Business_Partner__c = accountRecord.Id;
        branch.Business_Partner_Status__c = 'Open';
        branch.Branch_Name__c = '3010';
        insert branch;
        
        PriceBook2 appliancepricebook = new PriceBook2(Id = Test.getStandardPricebookId(), IsActive = true, LN_PriceList_Code__c = 'HD1',PriceList_Code__c = 'HD1_3000');
        update appliancepricebook;
        
        Order order4 = new Order(
            AccountId = accountRecord.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            PriceBook2Id = appliancepricebook.id,
            Business_Unit__c = 'H', Sub_Division__c = 'B2C',Logistics_Company_Branch__c = '3010',
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Direct_Billing_Order_Appliances').getRecordTypeId()
        );
        insert order4;
        
        /*Order order5 = new Order(
            AccountId = accountRecord.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            PriceBook2Id = appliancepricebook.id,
            Business_Unit__c = 'H', Sub_Division__c = 'B2C',Logistics_Company_Branch__c = '3010',
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Direct_Billing_Order_Appliances').getRecordTypeId()
        );
        insert order5;*/
       
        List<Quantity_split__c> qtysplit = new List<Quantity_split__c> {
            new Quantity_split__c(branch__c = '3010', Division__c ='H', Item_Group__c ='52REFG',Product_type__c ='HFF',Quantity_Split__c= 20),
                new Quantity_split__c(branch__c = order4.Logistics_Company_Branch__c, Division__c =order4.Business_Unit__c, Item_Group__c =prd.Item_Group__c,Product_type__c =prd.Product_Type__c,Quantity_Split__c= 20)
                };
                    insert qtysplit;
        
        
        Warehouse__c objWar = new Warehouse__c();
		objWar.Name='ZAF28S / SUNIRMAN';
		objWar.Logistic_Company__c='4010';
		objWar.Stock_Category__c='Showroom Display/Retailing';
		objWar.Warehouse_Description__c='SUNIRMAN';
		objWar.Warehouse__c='ZAF28S';
		objWar.Zone__c='East Zone';
		Insert objWar;
		
        
        Stock_File__c stockFileRec = new Stock_File__c();
        stockFileRec.Name='TEST200';
        stockFileRec.Applicable_Date__c=SYSTEM.TODAY();
        stockFileRec.From_Logistics_Company__c='2400';
        stockFileRec.Consumed_Quantity__c=10;
        stockFileRec.Is_Active__c=TRUE;
        stockFileRec.Quantity__c=150;
        stockFileRec.To_Logistics_Company__c='5000';
        stockFileRec.Quantity_Split_Required__c=TRUE;
        stockFileRec.Item__c=prd.Id;
        stockFileRec.From_Warehouse__c=objWar.Id;
        Insert stockFileRec;
        Test.stopTest();
        
        //Update new pricebookEntry(id=pbeList[0].id, Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prd.Id);
        
    }
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class');
        return addr;
    }
    
    @isTest private static void setorderlineitem1(){
        Account accountrecord = [Select Id from Account LIMIT 1];
        Product2 prd = [Select Id,Item_Group__c,Product_Type__c from Product2 LIMIT 1];
        
        Stock_File__c stockFile = [SELECT Applicable_Date__c, Consumed_Quantity__c, Description__c, From_Logistics_Company__c, From_Warehouse__c, 
                                                       Is_Active__c, Item__c, Quantity__c, Stockfile_Number__c, To_Logistics_Company__c, is_Hub__c, Item_Code__c, 
                                                       Item_Name__c, Remaining_Quantity__c, Warehouse_Code__c, Quantity_Split_Required__c, Name, Id FROM Stock_File__c LIMIT 1];
        
        PriceBook2 appliancepricebook = [Select Id from PriceBook2];
        
        Order order4 = [Select Id From Order];//Where RecordTypeId =: GlobalConstants.APPLIANCE_PRIMARY
        
        PricebookEntry apppricebookentry = new PricebookEntry(Pricebook2Id = appliancepricebook.id, Product2Id = prd.id, UnitPrice = 25.25,IsActive = true );
        Insert apppricebookentry;
        List<OrderItem> allOLI = new List<OrderItem> {
            new OrderItem(OrderId = order4.Id, Stock_File__c = stockFile.Id, Quantity = 56, PriceBookEntryId = apppricebookentry.Id, UnitPrice = apppricebookentry.UnitPrice , Product2id = prd.Id)
                };
                    Insert allOLI;
         //list<OrderItem> orderItm = [Select Id from OrderItem Limit 1];
            //Delete orderItm;
    }
    
    @isTest private static void setorderlineitem2(){
        Account accountrecord = [Select Id from Account LIMIT 1];
        Product2 prd = [Select Id,Item_Group__c,Product_Type__c from Product2 LIMIT 1];
        
        Stock_File__c stockFile = [SELECT Applicable_Date__c, Consumed_Quantity__c, Description__c, From_Logistics_Company__c, From_Warehouse__c, 
                                                       Is_Active__c, Item__c, Quantity__c, Stockfile_Number__c, To_Logistics_Company__c, is_Hub__c, Item_Code__c, 
                                                       Item_Name__c, Remaining_Quantity__c, Warehouse_Code__c, Quantity_Split_Required__c, Name, Id FROM Stock_File__c LIMIT 1];
        
        PriceBook2 appliancepricebook = [Select Id from PriceBook2];
        
        Order order4 = [Select Id From Order];//Where RecordTypeId =: GlobalConstants.APPLIANCE_PRIMARY
        
        PricebookEntry apppricebookentry = new PricebookEntry(Pricebook2Id = appliancepricebook.id, Product2Id = prd.id, UnitPrice = 25.25,IsActive = true );
        Insert apppricebookentry;
        List<OrderItem> allOLI = new List<OrderItem> {
            new OrderItem(OrderId = order4.Id, Quantity = 56, PriceBookEntryId = apppricebookentry.Id, UnitPrice = apppricebookentry.UnitPrice , Product2id = prd.Id)
                };
                    OrderItemTriggerHandler.TriggerDisabled=TRUE;
                    Insert allOLI;
        			OrderItemTriggerHandler.TriggerDisabled=FALSE;
         list<OrderItem> orderItm = [Select Id from OrderItem Limit 1];
            Delete orderItm;
    }
}