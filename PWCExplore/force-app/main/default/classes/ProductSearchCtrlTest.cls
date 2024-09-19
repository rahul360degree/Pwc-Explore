@isTest
public class ProductSearchCtrlTest {
    @TestSetup static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'UserServiceContract', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = GlobalConstants.MHE_GODREJ_BRANCH_CHAMPION;
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WP1';
        insert userToRun;
        
        System.runAs(userToRun) {
            // Create Account
            Account accountRecord = createAccountRecord();
            insert accountRecord;
            
            //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;

            // Create Products
            List<Product2> products = createProductRecords();
            insert products;

            // Create standard pricebook record for the products created
            List<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(products);
            insert standardPricebookEntries;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;
            
            // Create PricebookEntry for the above products and pricebook
            List<PricebookEntry> pricebookEntryRecords = createPricebookEntryRecords(products, pricebookRecord);
            insert pricebookEntryRecords;
            
            Asset assetRecord = createAssetRecord(accountRecord.Id);
            assetRecord.Address_Code__c = address.id;			//added by pc
            insert assetRecord;

            Plan__c planRecord = createPlanRecord();
            insert planRecord;

            Asset_Benefit__c assetBenefit = createAssetBenefit(assetRecord.Id, planRecord.Id);
            insert assetBenefit;

            List<Inclusion_List__c> inclusionList = createInclusionList(planRecord.Id, products[0].Id, products[1].Id);
            insert inclusionList;

            Case caseRecord = createCaseRecord(accountRecord.Id);
            caseRecord.AssetId = assetRecord.Id;
            insert caseRecord;

            Service_Form__c serviceFormRecord = createServiceFormRecord(caseRecord.Id);
            insert serviceFormRecord;
            
            ContentDocumentLink cdl = createFormSignature();
            cdl.LinkedEntityId = serviceFormRecord.Id;
            insert cdl;
            
        }
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        return accountRecord;
    }

    private static List<Product2> createProductRecords() {
        List<Product2> products = new List<Product2>();

        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Family = 'Equipment';
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
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'KC1_3000 / MHE SALES PRICE BRANCH', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
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

    private static Asset createAssetRecord(Id accountId) {
        Asset assetRecord = new Asset();
        assetRecord.Name = 'Test Asset record';
        assetRecord.SerialNumber = 'AX001';
        assetRecord.AccountId = accountId;
        assetRecord.Area_Code__c = 'WP1';
        assetRecord.Product_Purchased_Warranty_Start_Date__c = System.today().addMonths(-1);
        assetRecord.Product_Purchased_Warranty_End_Date__c = System.today().addMonths(6);
        assetRecord.Status = GlobalConstants.ASSET_ACTIVE_STATUS;
        assetRecord.Type_of_Warranty__c = 'Std Warranty';
        return assetRecord;
    }

    private static Plan__c createPlanRecord() {
        Plan__c planRecord = new Plan__c();
        planRecord.Name = 'Test Plan';
        planRecord.Plan_Identifier__c = 'Test_Plan';
        planRecord.Is_Active__c = true;
        planRecord.Plan_Type__c = 'Warranty';
        return planRecord;
    }

    private static Asset_Benefit__c createAssetBenefit(Id assetId, Id planId) {
        Asset_Benefit__c assetBenefit = new Asset_Benefit__c();
        assetBenefit.Name = 'Test Asset Benefit';
        assetBenefit.Plan__c = planId;
        assetBenefit.Asset__c = assetId;
        assetBenefit.Is_Active__c = true;
        return assetBenefit;
    }

    private static List<Inclusion_List__c> createInclusionList(Id planId, Id primaryProductId, Id secondaryProductId) {
        Inclusion_List__c inclusionList1 = new Inclusion_List__c();
        inclusionList1.Plan__c = planId;
        inclusionList1.Primary_Product__c = primaryProductId;
        inclusionList1.Secondary_Product__c = secondaryProductId;
        return new List<Inclusion_List__c>{inclusionList1};
    }

    private static Case createCaseRecord(Id accountId) {
        Case caseRecord = new Case();
        caseRecord.AccountId = accountId;
        caseRecord.Origin = 'Phone';
        caseRecord.Status = 'New';
        caseRecord.Priority = 'Medium';
        caseRecord.Case_Category__c = 'Others';
        caseRecord.Mobile__c = '9999999990';
        caseRecord.Email__c = 'test.customer@customerworld.com';
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        
        return caseRecord;
    }

    private static Service_Form__c createServiceFormRecord(Id caseRecordId) {
        Service_Form__c serviceFormRecord = new Service_Form__c();
        serviceFormRecord.RecordTypeId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get('Job_Card').getRecordTypeId();
        serviceFormRecord.Customer_Name_For_Signature__c = 'Test Customer';
        serviceFormRecord.Customer_Mobile__c = '9999999990';
        serviceFormRecord.Hour_Meter_Condition__c = 'Not Available';
        serviceFormRecord.Problem_Summary__c = 'Test';
        serviceFormRecord.Resolution_Summary__c = 'Test';
        serviceFormRecord.Parts_Required__c = 'Yes';
        serviceFormRecord.Case__c = caseRecordId;

        return serviceFormRecord;
    }
    
    private static ContentDocumentLink createFormSignature() {
        ContentVersion contentVersion = new ContentVersion(
            Title = System.Label.Signature_Prefix + '%',
            PathOnClient = 'test_signature.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            Is_System_Generated_Signature__c = true
        );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        return cdl;
    }

    @isTest
    private static void recordShouldBeOpen() {
        String response = null;
        Test.startTest();
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id FROM Service_Form__c LIMIT 1];
            response = ProductSearchCtrl.checkForRecordLock(serviceFormRecord.Id);
        }
        Test.stopTest();
        System.assertEquals('RECORD_OPEN', response);
    }

    @isTest
    private static void recordShouldBeLocked() {
        Test.startTest();
        String response = null;
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        userToRun.Persona__c = null;
        update userToRun;
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id, Status__c FROM Service_Form__c LIMIT 1];
            serviceFormRecord.Status__c = 'Submitted';
            update serviceFormRecord;
            response = ProductSearchCtrl.checkForRecordLock(serviceFormRecord.Id);
        }
        System.assertEquals('RECORD_LOCKED', response);
        Test.stopTest();
    }

    @isTest
    private static void getProductsData() {
        List<ProductWrapper.product> response = null;
        Test.startTest();
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id, Status__c FROM Service_Form__c LIMIT 1];
            response = ProductSearchCtrl.getProductsWithOffset(null, '20', '1', null, null);
        }
        Test.stopTest();
        System.assertNotEquals(null, response);
    }

    @isTest
    private static void getProductsDataWithFilters() {
        List<ProductWrapper.product> response = null;
        Test.startTest();
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id, Status__c FROM Service_Form__c LIMIT 1];
            response = ProductSearchCtrl.getProductsWithOffset('Test Base Product 1', '20', '1', '00001', 'Equipment');
        }
        Test.stopTest();
        System.assertNotEquals(null, response);
    }

    @isTest
    private static void createSRProducts() {
        String result = null;
        Test.startTest();
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id, Status__c FROM Service_Form__c LIMIT 1];
            List<ProductWrapper.product> productWrapper = ProductSearchCtrl.getProductsWithOffset(null, '20', '1', null, null);
            result = ProductSearchCtrl.addProductsAsLines(productWrapper, serviceFormRecord.Id);
        }
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    private static void createSRProducts_ByInsertingSameProductsMultipleTimes() {
        String result = null;
        Test.startTest();
        User userToRun = [Select Id FROM User WHERE Username = 'test.user@godrej.com' LIMIT 1];
        System.runAs(userToRun){
            Service_Form__c serviceFormRecord = [Select Id, Status__c FROM Service_Form__c LIMIT 1];
            List<ProductWrapper.product> productWrapper = ProductSearchCtrl.getProductsWithOffset(null, '20', '1', null, null);
            result = ProductSearchCtrl.addProductsAsLines(productWrapper, serviceFormRecord.Id);
            result = ProductSearchCtrl.addProductsAsLines(productWrapper, serviceFormRecord.Id);
        }
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}