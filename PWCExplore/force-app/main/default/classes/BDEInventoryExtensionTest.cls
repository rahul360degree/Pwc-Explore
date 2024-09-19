@isTest
public class BDEInventoryExtensionTest {
    @testSetup
    static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        System.runAs(userToRun) {
            List<Warehouse__c> warehouseRecords = createWarehouseRecords();
            insert warehouseRecords;
//added by shankar 9-6-2021
             Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            
           // Account accountRecord = createAccountRecord();
            //insert accountRecord;
//end by shankar 9-6-2021
            List<Product2> productRecords = createProductRecords();
            insert productRecords;

            // Create standard pricebook record for the products created.
            List<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(productRecords);
            insert standardPricebookEntries;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pricebookEntryRecords = createPricebookEntryRecords(productRecords, pricebookRecord);
            insert pricebookEntryRecords;

            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            List<OpportunityLineItem> oppLineItems = createOpportunityLineItems(pricebookEntryRecords, oppRecord);
            insert oppLineItems;

            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                            Gross_Net__c='1', Level__c='2', Stage__c='Active');
            Insert defaultDiscountMatrix;
        }
    }

    private static List<Warehouse__c> createWarehouseRecords() {
        List<Warehouse__c> warehouseRecordList = new List<Warehouse__c>();

        Warehouse__c warehouseRecord1 = new Warehouse__c();
        warehouseRecord1.Channel__c = 'VAS';
        warehouseRecord1.Channel_Type__c = 'Institution';
        warehouseRecord1.Hub__c = 'North Hub';
        warehouseRecord1.Logistic_Company__c = '5010';
        warehouseRecord1.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord1.Warehouse__c = 'ZXF001';
        warehouseRecord1.Zone__c = 'North Hub';
        warehouseRecordList.add(warehouseRecord1);

        Warehouse__c warehouseRecord2 = new Warehouse__c();
        warehouseRecord2.Channel__c = 'DST';
        warehouseRecord2.Channel_Type__c = 'Institution';
        warehouseRecord2.Hub__c = 'South Hub';
        warehouseRecord2.Logistic_Company__c = '5010';
        warehouseRecord2.Stock_Category__c = 'Finished Goods Manufactured Plant';
        warehouseRecord2.Warehouse__c = 'ZXF002';
        warehouseRecord2.Zone__c = 'South Hub';
        warehouseRecordList.add(warehouseRecord2);

        return warehouseRecordList;
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(FirstName='Test', LastName='Account', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        return accountRecord;
    }

    private static List<Product2> createProductRecords() {
        List<Product2> products = new List<Product2>();

        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        products.add(baseproduct1);

        Product2 variantproduct1 = new Product2(Name = 'Test Variant Product 1', Item__c = '000021', ProductCode = '000021');
        variantproduct1.Is_Independent_product__c = true;
        variantproduct1.Component_Type__c = GlobalConstants.VARIANT_PRODUCT_COMPONENT_TYPE;
        variantproduct1.IsActive = true;
        variantproduct1.Associated_Base_Product__c = '00001';
        variantproduct1.Variant_Type__c = 'MAST';
        products.add(variantproduct1);

        Product2 variantproduct2 = new Product2(Name = 'Test Variant Product 1', Item__c = '000022', ProductCode = '000022');
        variantproduct2.Is_Independent_product__c = true;
        variantproduct2.Component_Type__c = GlobalConstants.VARIANT_PRODUCT_COMPONENT_TYPE;
        variantproduct2.IsActive = true;
        variantproduct2.Associated_Base_Product__c = '00001';
        variantproduct2.Variant_Type__c = 'TYRE';
        products.add(variantproduct2);

        Product2 attachmentproduct1 = new Product2(Name = 'Test Attachment Product 1', Item__c = '00003', ProductCode = '00003');
        attachmentproduct1.Is_Independent_product__c = false;
        attachmentproduct1.Component_Type__c = GlobalConstants.ATTACHMENT_PRODUCT_COMPONENT_TYPE;
        attachmentproduct1.IsActive = true;
        attachmentproduct1.Associated_Base_Product__c = '00001';
        products.add(attachmentproduct1);

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
        return standardPricebookEntries;
    }

    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                    Market_Pricelist__c = true);
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
        return pricebookEntryRecords;
    }

    private static Opportunity createOpportunityRecord(Account accountRecord, User userToRun, Pricebook2 pricebookRecord) {
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = accountRecord.Id, StageName = 'Qualification');
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId();
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = 'K';
        opp.MHE_Division__c = 'Outright Sales';
        opp.CloseDate = (Date.today()).addDays(10);
        opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
        return opp;
    }

    private static List<OpportunityLineItem> createOpportunityLineItems(List<PricebookEntry> pricebookEntries, Opportunity oppRecord) {
        List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
            for(PricebookEntry pbe : pricebookEntries) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = oppRecord.Id;
                oppProducts.add(oppProduct);
            }
            
            return oppProducts;
    }

    @IsTest
    static void getFilterFieldsInformation() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Opportunity opp = [Select Id, Name FROM Opportunity];
        System.runAs(userToRun) {
            Test.startTest();
            String recordId = String.valueOf(opp.Id);
            String userId = String.valueOf(userToRun.Id);
            String fieldString = InventoryCheckController.getProductsBasedOnDefaultValues(recordId, userId);
            Test.stopTest();
            System.assertNotEquals(null, fieldString);
        }
    }

    @IsTest
    static void getStockProductsForOpportunity() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Opportunity opp = [Select Id, Name FROM Opportunity];
        System.runAs(userToRun) {
            String recordId = String.valueOf(opp.Id);
            String userId = String.valueOf(userToRun.Id);
            String productsToGet = '{"CompanyCodes":"5010","ItemCodes":"00001","WarehouseCodes":"ZNF11T"}';

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockBDEResponseGenerator());
            String stockProductJSON = InventoryCheckController.getStockProductsForBDE(productsToGet, recordId, 'OPPORTUNITY');
            Test.stopTest();
            System.assertNotEquals(null, stockProductJSON);
        }
    }
    
    
//added by shreela 8-6-2021
@IsTest
    static void isGodrejRenTRUSTTest() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        
        insert userToRun;
        System.runAs(userToRun) {
            Test.startTest();
            String recordId ='0062h00000EeEwdAAF';
            String objectName ='Opportunity';
            Boolean  fieldString = BDEInventoryExtension.isGodrejRenTRUST(recordId,objectName);
            Test.stopTest();
            System.assertNotEquals(null, fieldString);
        }
    }
//end by shreela  8-6-2021
}