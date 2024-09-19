@isTest
public class TestDataFactory {
    public static Discount_Matrix__c createDiscountMatric(){
        Discount_Matrix__c dm = new Discount_Matrix__c( 
                Name='No Discount',  Discount_Percent__c=0,  Discount_Amount__c=1, Gross_Net__c='1',  Level__c='3',  Stage__c='Active', 
                Start_Date__c=system.today(),Discount_Code__c='HDH');
            insert dm;
        return dm;
    }
    
    public static User createUser(){
        Profile mheProfile = [SELECT Id FROM Profile WHERE Name = 'MHE Sales User'];
        Id roleId = [SELECT Id FROM UserRole WHERE Name = 'MHE Service CSG HO'].Id;
        
        User mheUser = new TestUserBuilder().setProfileId(mheProfile.Id)
            .setBusinessUnit('K').setSalaryCode('13245').setUserRoleId(roleId).getSavedTestRecord();
        return mheUser;
    }
    
    
    public static Account createAccount(){
        Account partnerAccount = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
            .setBusinessUnit('K').getSavedTestRecord();
        return partnerAccount;
    }
    
    public static Product2 createProduct(){
        Product2 prod = new TestProductBuilder().setItemCode('H').getSavedTestRecord();
        prod.Product_Storage_Clasification__c = 'Category A';
        prod.Is_generic_Product__c = true;
        update prod;
        return prod;
    }
    
    public static Order createOrder(Id accountId,String recordType){
        List<Area_Code_Branch_Champion__mdt> areaMappings = [Select Area_Code__c,Branch_head_Salary_code__c,Regional_Manager_Salary_Code__c,Branch_Champion_salary_code__c 
                                                             From Area_Code_Branch_Champion__mdt Where Area_Code__c != NULL AND Branch_head_Salary_code__c != NULL AND Regional_Manager_Salary_Code__c != NULL
                                                             AND Branch_Champion_salary_code__c != NULL
                                                             AND BU_Division__c='MHE'
                                                            ];
        Order orderRecord= new TestOrderBuilder().setAccountId(accountId)
            .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId())
            .setBusinessUnit('K').getSavedTestRecord();
        
        if(areaMappings.size() > 1) {
            orderRecord.Area__c = areaMappings[0].Area_Code__c;
        } else {
            orderRecord.Area__c = 'NG3';
        }
        orderRecord.MHE_Division__c = 'Spare Parts';
        update orderRecord;
        return orderRecord;
    }
    
    public static Warehouse__c createWarehouse(){
        Warehouse__c warehouseRecord1 = new Warehouse__c();
        warehouseRecord1.Channel__c = 'VAS';
        warehouseRecord1.Channel_Type__c = 'Institution';
        warehouseRecord1.Hub__c = 'North Hub';
        warehouseRecord1.Logistic_Company__c = '2010';
        warehouseRecord1.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord1.Warehouse__c = 'KBAC1Z';
        warehouseRecord1.Zone__c = 'North Hub';
        insert warehouseRecord1;
        return warehouseRecord1;
    }
    
    public static void createSampleData(){
        Discount_Matrix__c dm = TestDataFactory.createDiscountMatric();            
        Product2 prod = TestDataFactory.createProduct();
        PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
        
        Account partnerAccount = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
            .setBusinessUnit('K').getSavedTestRecord();
        
        //create Order
        Order orderRecord= TestDataFactory.createOrder(partnerAccount.Id,'MHE_Order_Primary');
        System.debug(orderRecord);
        OrderItem oitem = new OrderItem(Orderid = orderRecord.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
        
        Warehouse__c warehouseRecord1 = TestDataFactory.createWarehouse();
        
    }
}