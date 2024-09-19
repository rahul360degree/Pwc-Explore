@isTest
public class OLAPInventoryExtensionTest {
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

            List<Product2> productRecords = createProductRecords();
            insert productRecords;

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
        System.runAs(userToRun) {
            Test.startTest();
            String fieldString = InventoryCheckController.getFilterFieldsInfo(String.valueOf(userToRun.Id));
            Test.stopTest();
            System.assertNotEquals(null, fieldString);
        }
    }

    @IsTest
    static void getProductsInformation() {
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
        System.runAs(userToRun) {
            Test.startTest();
            String fieldString = InventoryCheckController.getFilterFieldsInfo(String.valueOf(userToRun.Id));
            Map<String, String> productFilters = new Map<String, String>{'Component_Type__c' => GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE};
            String productsJSON = InventoryCheckController.getProducts(JSON.serialize(productFilters));
            Test.stopTest();
            System.assertNotEquals(null, productsJSON);
        }
    }

    @IsTest
    static void getStockProducts() {
        //getStockProducts
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
        System.runAs(userToRun) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockInventoryVisibilityResponseGenerator());
            String requestObj = '{CompanyCodes: "5000",ItemCodes: "31391599DG00209,31391599DG01048",WarehouseCodes: "Z2F09S,Z2F18S,Z2F1XE"}';
            String response = InventoryCheckController.getStockProducts(requestObj);
            Test.stopTest();
            System.assertNotEquals(null, response);
        }
    }
    
    @isTest
    static void testExceptionClass() {
            InventoryCheckerException exceptionObj = new InventoryCheckerException('msg', 'error');
    }
}