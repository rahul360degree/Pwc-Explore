@isTest
public class GenericLookupComponentControllerTest {
    @testSetup
    static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userGLCCT@godrej.com', username = 'test.userGLCCT@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        System.runAs(userToRun) {
            // Create Products.
            List<Product2> products = createProductRecords();
            insert products;
        }
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

    @isTest
    static void getProductsBasedOnSearchTerm() {
        User userToRun = [Select Id FROM User WHERE username = 'test.userGLCCT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(userToRun) {
            String searchKey = 'Test Base Product 1';
            String objectName = 'Product2';
            String fieldNames = 'Name';
            String additionalFieldsToGet = 'IsActive';

            List<Product2> productRecords = (List<Product2>) GenericLookupComponentController.findRecords(searchKey, objectName, fieldNames, additionalFieldsToGet);
            Test.startTest();
            System.assertNotEquals(0, productRecords.size());
            Test.stopTest();
        }
    }

    @isTest
    static void getNonExistentObjectRecords() {
        User userToRun = [Select Id FROM User WHERE username = 'test.userGLCCT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(userToRun) {
            String searchKey = 'Test Record';
            String objectName = 'Test_Object_Non_Existent__c';
            String fieldNames = 'Name';
            String additionalFieldsToGet = null;

            Test.startTest();
            try {
                List<Product2> productRecords = (List<Product2>) GenericLookupComponentController.findRecords(searchKey, objectName, fieldNames, additionalFieldsToGet);
            } catch(Exception ex) {
                Boolean isException = true;
                System.assertEquals(true, isException);
            }
            Test.stopTest();
        }
    }
}