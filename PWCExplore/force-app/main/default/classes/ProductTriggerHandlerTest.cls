@IsTest
public class ProductTriggerHandlerTest {
    @TestSetup
    static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userPTHT@godrej.com', username = 'test.userPTHT@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        System.runAs(userToRun) {
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true );
            standardPricebook.PriceList_Code__c = 'SP1';
            standardPricebook.LN_PriceList_Code__c = 'SP1';
            update standardPricebook;
        }
    }

    @IsTest
    static void insertProducts() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userPTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Product2 productRecord = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
            productRecord.Is_Independent_product__c = false;
            productRecord.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            productRecord.IsActive = true;

            insert productRecord;
            System.assertEquals(true, productRecord.IsActive);
            System.assertNotEquals(null, productRecord.Id);
        }
        Test.stopTest();
    }

    /*
     * When a product is inserted with Item_Signal__c from Blocked_Item_Signals__mdt
     * Product.IsActive should be FALSE
     */ 
    @IsTest
    static void insertingAProductOfTypeBlockedStatusShouldDeactivateProduct() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userPTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Product2 productRecord = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
            productRecord.Is_Independent_product__c = false;
            productRecord.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            productRecord.IsActive = true;
            productRecord.Item_Signal__c = 'B00';

            insert productRecord;
            
            Product2 productRecordAfterUpdate = [Select Id, IsActive FROM Product2 WHERE Id = :productRecord.Id];
            System.assertEquals(false, productRecordAfterUpdate.IsActive);
        }
        Test.stopTest();
    }
    
    /*
     * When a product is updated with Item_Signal__c from Blocked_Item_Signals__mdt
     * Product.IsActive should be FALSE
     */ 
    @IsTest
    static void updatingAProductOfTypeBlockedStatusShouldDeactivateProduct() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userPTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Product2 productRecord = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
            productRecord.Is_Independent_product__c = false;
            productRecord.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            productRecord.IsActive = true;
            productRecord.Item_Signal__c = '100';

            insert productRecord;

            productRecord.Item_Signal__c = 'B00';
            update productRecord;

            Product2 productRecordAfterUpdate = [Select Id, IsActive FROM Product2 WHERE Id = :productRecord.Id];
            System.assertEquals(false, productRecordAfterUpdate.IsActive);
        }
        Test.stopTest();
    }

    @IsTest
    static void deleteProduct() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userPTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Product2 productRecord = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
            productRecord.Is_Independent_product__c = false;
            productRecord.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            productRecord.IsActive = true;
            productRecord.Item_Signal__c = '100';

            insert productRecord;

            delete productRecord;
            System.assertEquals(0, [Select Id FROM Product2].size());
        }
        Test.stopTest();
    }

    @IsTest
    static void undeleteProduct() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userPTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Product2 productRecord = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
            productRecord.Is_Independent_product__c = false;
            productRecord.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            productRecord.IsActive = true;
            productRecord.Item_Signal__c = '100';

            insert productRecord;
            delete productRecord;
            undelete productRecord;
            System.assertEquals(1, [Select Id FROM Product2 WHERE Id = :productRecord.Id LIMIT 1].size());
        }
        Test.stopTest();
    }
}