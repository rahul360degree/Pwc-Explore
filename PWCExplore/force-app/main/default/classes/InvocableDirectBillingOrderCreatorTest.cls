/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 02-15-2023
 * @last modified by  : vrajpoot@godrej.com
**/
@isTest
public class InvocableDirectBillingOrderCreatorTest {
    @testSetup
    public static void createData(){       
        Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance();
            setting2.OrderTriggerDisabled__c = true;
            setting2.QuoteTriggerDisabled__c = true;
            insert setting2;
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id).setUserName('test@godrej.com')// set userName by Mrunali Chaudhari at 18 JAN 2024
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        runningAdminUser.Logistic_Company__c='2400';
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        {   /*          
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OrderTriggerDisabled__c = true;
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            */
            Account accountRecord = createAccountRecord();
            
            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord); 
            
            List<Product2> productList = createProductRecords();         
            
            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            
            Pricebook2 pricebookRecord = createPricebookRecord();
            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            
            Opportunity oppRecord = createApplianceOpportunity(accountRecord, runningAdminUser, pricebookRecord);
            
            Warehouse__c warehouseRecord = createWarehouseRecords();
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                            Gross_Net__c='1', Level__c='2', Stage__c='Active');
            Insert defaultDiscountMatrix;
            
            createApplianceOrderAndOrderItemRecords(oppRecord, pbeEntries[0], branchRecord,warehouseRecord);
        }
    }
    
    static testMethod void test_InvocableDirectBillingOrderCreator(){
        User usr = [SELECT Id FROM User WHERE username ='test@godrej.com' Limit 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(usr)
        {  
            Account accountRecord=[Select Id from Account limit 1];
            Branch__c branchRecord=[Select Id from Branch__c limit 1];
            Warehouse__c warehouseRecord=[Select Id,Warehouse__c from Warehouse__c limit 1];
              // PricebookEntry pricebookEntryRecord=[Select Id,UnitPrice,Product2Id from PricebookEntry limit 1];
            List<OrderItem> orderItemRecordList=[Select Id,Item_Code__c,Quantity,Stock_File__c,Warehouse__c,Warehouse__r.Warehouse__c from OrderItem];
            
            InvocableDirectBillingOrderCreator.FlowInput flowIn=new InvocableDirectBillingOrderCreator.FlowInput();
            flowIn.accountId=accountRecord.Id;
            flowIn.accountChannel='DLR';
            flowIn.fromLogisticsCompany='2400';
            flowIn.headerWarehouseCode=warehouseRecord.Id;
            flowIn.toBranchId=branchRecord.Id;
            flowIn.internalSalesRep=null;
            flowIn.lstOrderItems=orderItemRecordList;
            //		flowIn.lstOrderItems=createApplianceOrderAndOrderItemRecords(pricebookEntryRecord,warehouseRecord);
            test.startTest();
            InvocableDirectBillingOrderCreator.FlowInput[] arrFlowInput =new InvocableDirectBillingOrderCreator.FlowInput[]{flowIn};
            InvocableDirectBillingOrderCreator.createDirectBillingOrder(arrFlowInput);
            test.stopTest();
            List<Order> o=[select Business_Unit__c,Is_Exchange_order__c from order where Logistics_Company_Branch__c = '2400' and Line_of_Business__c = 'CMC'];
            //system.assertEquals('no', o[0].Is_Exchange_order__c);//gcp22
        }
     }
    
    private static Account createAccountRecord() {
        Account accountRecord = new Account(FirstName='Test', LastName='Account', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
        insert accountRecord;
        return accountRecord;
    }
    
    private static Branch__c createBranchRecordWithAddress(Account accountRecord) {
        
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Building__c = '12345';  
        address.Street__c = '2nd street';
        insert address;
        
        Branch__c branch = new Branch__c();
        branch.Business_Partner__c = accountRecord.Id;
        branch.Business_Partner_Status__c = 'Open';
        branch.Business_Partner_Status_Ship_To__c = 'Open';
        //branch.Branch_Name__c = '5010';
        branch.Branch_Name__c = '2400';
        branch.Channel__c = 'DLR';
        branch.Line_of_Business__c = 'AGRO';
        branch.Area__c = 'WN1';
        branch.Ship_To_Address__c = address.Id;
        branch.Sold_To_Address__c = address.Id;
        insert branch;
        return branch;
    }
    
    private static Warehouse__c createWarehouseRecords() {
        Warehouse__c warehouseRecord = new Warehouse__c();
        warehouseRecord.Channel__c = 'DLR';
        warehouseRecord.Channel_Type__c = 'Institution';
        warehouseRecord.Hub__c = 'North Hub';
        warehouseRecord.Logistic_Company__c = '2400';
        warehouseRecord.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord.Warehouse__c = 'ZXF001';
        warehouseRecord.Zone__c = 'North Hub';
        insert warehouseRecord;
        return warehouseRecord;
    }    
    
    private static void createApplianceOrderAndOrderItemRecords(Opportunity opportunityRecord, PricebookEntry pricebookEntryRecord, Branch__c branchRecord,Warehouse__c warehouseRecord) {
        Order orderRecord = new Order( Logistics_Company_Branch__c = '2400',
                                      Line_of_Business__c = 'CMC', PriceBook2Id = pricebookEntryRecord.Pricebook2Id,
                                      Business_Unit__c = 'H', Sub_Division__c = 'B2B',
                                      Branch__c = branchRecord.Id, AccountId = opportunityRecord.AccountId, OpportunityId = opportunityRecord.Id,
                                      RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Order', 'Direct_Billing_Order_Appliances'),
                                      EffectiveDate = System.today(),Status = 'Draft',
                                     	Sold_to_Business_Partner__c= opportunityRecord.AccountId
                                     ); 
        insert orderRecord;
        
        List<OrderItem> allOLI = new List<OrderItem> {
            new OrderItem(OrderId = orderRecord.Id, 
                          Quantity  = 1, PriceBookEntryId = pricebookEntryRecord.Id,
                          UnitPrice =  pricebookEntryRecord.UnitPrice,
                          Warehouse__c=warehouseRecord.Id)
                };
                    insert allOLI;
    }
    
    private static Opportunity createApplianceOpportunity(Account accountRecord, User userToRun, Pricebook2 pricebookRecord) {
        Opportunity opp = new Opportunity(Name = 'Test Appliance Opportunity', AccountId = accountRecord.Id, StageName = 'Qualification');
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'Interio_B2C_Appliances');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = 'H';
        opp.CloseDate = (Date.today()).addDays(10);
        opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
        insert opp;
        return opp;
    } 
    
    private static List<Product2> createProductRecords() {
        List<Product2> products = new List<Product2>();
        
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001',Commodity_Set__c='R18I');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        products.add(baseproduct1);
        insert products;
        return products;
    }
    
    private static List<PricebookEntry> createStandardPricebookEntries(List<Product2> products) {
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        
        for(Product2 product : products) {
            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = pricebookId, Product2Id = product.Id,
                UnitPrice = 10000, IsActive = true);
            
            standardPricebookEntries.add(standardPrice);
        }
        insert standardPricebookEntries;
        return standardPricebookEntries;
    }
    
    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = 'HD1_3000', 
                                                    IsActive = true, Business_Unit__c = 'H', 
                                                    Market_Pricelist__c = true
                                                   );
        insert pricebookRecord;
        return pricebookRecord;
    }
    
    private static List<PricebookEntry> createPricebookEntryRecords(List<Product2> products, Pricebook2 pricebook) {
        List<PricebookEntry> pricebookEntryRecords = new List<PricebookEntry>();
        for(Product2 product : products) {
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = product.Id;
            pbe.Pricebook2Id = pricebook.Id;
            pbe.UnitPrice = 1000.00;
            pbe.IsActive = true;
            pricebookEntryRecords.add(pbe);
        }
        insert pricebookEntryRecords;
        return pricebookEntryRecords;
    }    
}