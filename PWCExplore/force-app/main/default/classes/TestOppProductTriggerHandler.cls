@isTest
public class TestOppProductTriggerHandler {
    @testSetup
    public static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userTOPTH@godrej.com', username = 'test.userTOPTH@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        // Create Account.
        System.runAs(userToRun) {
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'TEST ATTACH PAYMENT';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';            
            insert address;     
            
            Account accountRecord = createAccountRecord();
            accountRecord.Primary_Address__c = address.Id;
            insert accountRecord;
            
            List<Branch__c> branchRecords = createBranchRecords(accountRecord.Id, userToRun);
            insert branchRecords;
            
            Contact contactRecord = createContactRecord(accountRecord.Id);
            insert contactRecord;
            
            // Create Products.
            List<Product2> products = createProductRecords();
            insert products;
            
            // Create standard pricebook record for the products created.
            List<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(products);
            insert standardPricebookEntries;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pricebookEntryRecords = createPricebookEntryRecords(products, pricebookRecord);
            insert pricebookEntryRecords;
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;
            
            oppRecord.Duration_Unit__c = 'Year';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            update oppRecord;            
             
            Asset assetRecord = createAssetRecord(accountRecord.Id, contactRecord.Id);
            assetRecord.Address_Code__c = address.id;			//Added by pc
            insert assetRecord;
            
        }        

    }
    
    //Added by Srini
    
    public static void createTestData1() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT);

        userToRun.Persona__c = 'Construction-Sales Engineer';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        // Create Account.
        System.runAs(userToRun){	
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'TEST ATTACH PAYMENT';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';            
            insert address;  
            
            Product2 product = new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift')
                .setItemCode('GX1').setComponentType('Base Product')
                .setProductCode('GX1F').getTestRecord();
            insert product;
            
            Account accountRecord1 = createAccountRecord();
            accountRecord1.Primary_Address__c = address.Id;
            insert accountRecord1;
            
            List<Branch__c> branchRecords = createBranchRecords(accountRecord1.Id, userToRun);
            insert branchRecords;
            
            Contact contactRecord = createContactRecord(accountRecord1.Id);
            insert contactRecord;
            
            // Create Products.
            List<Product2> products = createProductRecords();
            insert products;
            
            // Create standard pricebook record for the products created.
            List<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(products);
            insert standardPricebookEntries;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord1 = createPricebookRecord();
            insert pricebookRecord1;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pricebookEntryRecords = createPricebookEntryRecords(products, pricebookRecord1);
            insert pricebookEntryRecords;
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord1, userToRun, pricebookRecord1);
            insert oppRecord;
            
            oppRecord.Duration_Unit__c = 'Year';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            update oppRecord;            
            
            //Added for CalculateSalesAmount - created Opportunity for Construction BU
            Opportunity oppRecord1 = createOpportunityRecordforCon(accountRecord1, userToRun, pricebookRecord1);
            insert oppRecord1;
            oppRecord1.Duration_Unit__c = 'Year';
            oppRecord1.Duration__c = 1;
            oppRecord1.Contract_Start_Date__c = system.today().addMonths(1);
            update oppRecord1;
            
            Opportunity_Landed_Rate__c olr = createOpportunityLandedRateRecord(oppRecord1);
            insert olr;
            
            Asset assetRecord = createAssetRecord(accountRecord1.Id, contactRecord.Id);
            insert assetRecord;
            
            OpportunityLineItem oppProduct1 = new OpportunityLineItem();
            oppProduct1.PricebookEntryId = pricebookEntryRecords[0].Id;
            oppProduct1.Quantity = 1;
            oppProduct1.UnitPrice = 10;
            oppProduct1.Sequence_Number__c = 1;
            oppProduct1.OpportunityId = oppRecord.Id;
            oppProduct1.Product2Id = product.id;
            insert oppProduct1;       
        }
    }


    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        return accountRecord;
    }

    private static List<Branch__c> createBranchRecords(Id accountId, User userRecord) {
        List<Branch__c> branchList = new List<Branch__c>();
        Branch__c branchRecord1 = new Branch__c();
        branchRecord1.Business_Partner__c = accountId;
        branchRecord1.Branch_Name__c = userRecord.Logistic_Company__c;
        branchRecord1.Area__c = userRecord.Area_Code__c;
        branchRecord1.Business_Partner_Status_Ship_To__c = 'Open';
        branchRecord1.Business_Partner_Status__c = 'Open';

        branchList.add(branchRecord1);
        return branchList;
    }
    
    private static Contact createContactRecord(Id accountId) {
        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'John';
        contactRecord.LastName='Doe';
        contactRecord.Active__c = true;
        contactRecord.MobilePhone = '9012342120';
        contactRecord.Email = 'john.doe@godrej.com';
        contactRecord.AccountId = accountId;
        return contactRecord;
    }

    private static Opportunity createOpportunityRecord(Account accountRecord, User userToRun, Pricebook2 pricebookRecord) {
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = accountRecord.Id, StageName = 'Qualification');
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'MHE');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE;
        opp.MHE_Division__c = 'Outright Sales';
        opp.CloseDate = (Date.today()).addDays(10);
        opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
        return opp;
    }
    
    //Added for CalculateSalesAmount
    private static Opportunity createOpportunityRecordforCon(Account accountRecord, User userToRun, Pricebook2 pricebookRecord) {
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = accountRecord.Id, StageName = 'Qualification');
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'MHE');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
        opp.CloseDate = (Date.today()).addDays(10);
        return opp;
    }
    
     private static Opportunity_Landed_rate__c createOpportunityLandedRateRecord(opportunity opp){
        Opportunity_Landed_Rate__c olr = new Opportunity_Landed_Rate__c(Name='Test', Related_Opportunity__c=opp.Id);
        olr.Landed_Rate__c = 1000;
        return olr;
    }

    private static List<Product2> createProductRecords() {
        List<Product2> products = new List<Product2>();
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Category__c = 'WPS'; //Added to cover CalculateSalesAmount
        baseproduct1.Product_Sub_Category__c = 'RCM'; //Added to cobver CalculateSalesAmount
        baseproduct1.Commodity_Set__c = 'R12V'; //added for Tax rate.
        baseproduct1.Type__c = 'Broken_Blocks'; //Added to cover CalculateSalesAmount logic
        baseproduct1.Volume__c = 2;
        products.add(baseproduct1);

        Product2 variantproduct1 = new Product2(Name = 'Test Variant Product 1', Item__c = '000021', ProductCode = '000021');
        variantproduct1.Is_Independent_product__c = true;
        variantproduct1.Component_Type__c = GlobalConstants.VARIANT_PRODUCT_COMPONENT_TYPE;
        variantproduct1.IsActive = true;
        variantproduct1.Product_Category__c = 'WPS'; //Added to cobver CalculateSalesAmount
        variantproduct1.Product_Sub_Category__c = 'RCM'; //Added to cover CalculateSalesAmount
        variantproduct1.Commodity_Set__c = 'R18I'; //added for Tax rate
        variantproduct1.Type__c = 'TUFF_ACC_Block_Landed_Rate'; //Added to cover CalculateSalesAmount logic
        variantproduct1.Associated_Base_Product__c = '00001';
        variantproduct1.Variant_Type__c = 'MAST';
        products.add(variantproduct1);

        Product2 variantproduct2 = new Product2(Name = 'Test Variant Product 1', Item__c = '000022', ProductCode = '000022');
        variantproduct2.Is_Independent_product__c = true;
        variantproduct2.Component_Type__c = GlobalConstants.VARIANT_PRODUCT_COMPONENT_TYPE;
        variantproduct2.IsActive = true;
        variantproduct2.Product_Category__c = 'WPS'; //Added to cobver CalculateSalesAmount
        variantproduct2.Product_Sub_Category__c = 'RCM'; //Added to cover CalculateSalesAmount
        variantproduct2.Commodity_Set__c = 'R18IV';//Added for Tax rate.
        variantproduct2.Associated_Base_Product__c = '00001';
        variantproduct2.Variant_Type__c = 'TYRE';
        products.add(variantproduct2);

        Product2 attachmentproduct1 = new Product2(Name = 'Test Attachment Product 1', Item__c = '00003', ProductCode = '00003');
        attachmentproduct1.Is_Independent_product__c = false;
        attachmentproduct1.Component_Type__c = GlobalConstants.ATTACHMENT_PRODUCT_COMPONENT_TYPE;
        attachmentproduct1.IsActive = true;
        attachmentproduct1.Product_Category__c = 'WPS'; //Added to cobver CalculateSalesAmount
        attachmentproduct1.Product_Sub_Category__c = 'RCM'; //Added to cover CalculateSalesAmount
        attachmentproduct1.Commodity_Code__c = 'R28III';//Added for tax rate
        attachmentproduct1.Associated_Base_Product__c = '00001';

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
    
    private static Asset createAssetRecord(Id accountId, Id contactId) {
        Asset assetRecord = new Asset();
        assetRecord.Name = 'Test Asset record';
        assetRecord.SerialNumber = 'AX001';
        assetRecord.AccountId = accountId;
        assetRecord.ContactId = contactId;
        assetRecord.Coverage__c = 'KFGWC00600001';
        assetRecord.Type_of_Warranty__c = 'Special Warranty';
        return assetRecord;
    }

    static testMethod void testAddingBaseProductAndItsAssociatedProducts(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userTOPTH@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Pricebook2 pricebookRecord = [Select Id FROM Pricebook2 LIMIT 1];
            Opportunity opp = [Select Id FROM Opportunity LIMIT 1];
            List<PricebookEntry> pricebookEntries = [Select Id, Product2Id, ProductCode, Pricebook2Id, UnitPrice FROM PricebookEntry 
                WHERE IsActive = true AND Pricebook2Id = :pricebookRecord.Id];
            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
            for(PricebookEntry pbe : pricebookEntries) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = opp.Id;
                oppProducts.add(oppProduct);
            }
            
            insert oppProducts;
            
            System.assertEquals(pricebookEntries.size(), [Select ID FROM OpportunityLineItem WHERE OpportunityId = :opp.Id].size());
        }
        Test.stopTest();
    }
    
    static testMethod void addingOpporunityProductsWithAsset_shouldpopulateAssetSerialNumberInThem(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userTOPTH@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Pricebook2 pricebookRecord = [Select Id FROM Pricebook2 LIMIT 1];
            Asset assetRecord = [Select Id, SerialNumber FROM Asset LIMIT 1];
            Opportunity opp = [Select Id FROM Opportunity LIMIT 1];
            List<PricebookEntry> pricebookEntries = [Select Id, Product2Id, ProductCode, Pricebook2Id, UnitPrice FROM PricebookEntry 
                WHERE IsActive = true AND Pricebook2Id = :pricebookRecord.Id];
            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
            for(PricebookEntry pbe : pricebookEntries) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = opp.Id;
                oppProduct.Asset__c = assetRecord.Id;
                oppProducts.add(oppProduct);
            }
            
            insert oppProducts;

            List<OpportunityLineItem> oppProductsAfterInsert = [Select Id, Asset_Serial_Number__c FROM OpportunityLineItem 
                WHERE OpportunityId = :opp.Id];
            System.assertEquals(pricebookEntries.size(), oppProductsAfterInsert.size());
            System.assertEquals(assetRecord.SerialNumber, oppProductsAfterInsert[0].Asset_Serial_Number__c);
            
        }
        Test.stopTest();
    }
    
    
    
    static testMethod void updateOpportunityProductQuantities() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userTOPTH@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {

            List<Product2> productList = [Select Id, Name, Is_Generic_Product__c FROM Product2];
            for(Product2 product : productList) {
                product.Is_Generic_Product__c = true;
            }
            update productList;
            
            Pricebook2 pricebookRecord = [Select Id FROM Pricebook2 LIMIT 1];
            Asset assetRecord = [Select Id, SerialNumber FROM Asset LIMIT 1];
            Opportunity opp = [Select Id FROM Opportunity LIMIT 1];
            List<PricebookEntry> pricebookEntries = [Select Id, Product2Id, ProductCode, Pricebook2Id, UnitPrice FROM PricebookEntry 
                WHERE IsActive = true AND Pricebook2Id = :pricebookRecord.Id];
            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    
            for(PricebookEntry pbe : pricebookEntries) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = opp.Id;
                oppProduct.Asset__c = assetRecord.Id;
                oppProducts.add(oppProduct);
            }          
            insert oppProducts;
            for(OpportunityLineItem oppProduct : oppProducts) {
                oppProduct.UnitPrice *= 2;
                oppProduct.Quantity += 1;
            }
            update oppProducts;

            List<OpportunityLineItem> oppProductsAfterInsert = [Select Id, Quantity, Asset_Serial_Number__c FROM OpportunityLineItem 
                WHERE OpportunityId = :opp.Id];
            System.assertEquals(pricebookEntries.size(), oppProductsAfterInsert.size());
            System.assertEquals(assetRecord.SerialNumber, oppProductsAfterInsert[0].Asset_Serial_Number__c);
            
        }
        Test.stopTest();
    }
    
     static testmethod void upsertReecordCoverage_TUFFDuroplast(){
        Test.startTest();
        user userToRun = [Select Id from User where username='test.userTOPTH@godrej.com' LIMIT 1];
 			Product2 product = [Select Id from Product2 limit 1];
            product.Type__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            product.Commodity_Set__c = 'R12V';
            product.Volume__c = 36.23;
            update product;
          
            Opportunity_Landed_rate__c landedRate = new Opportunity_Landed_rate__c();
            landedRate.Landed_rate__c = 100;
            landedRate.Related_Opportunity__c = [Select Id from Opportunity limit 1].Id;
            landedRate.Label__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            landedRate.Name = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            insert landedRate;           
      
            List<Opportunity_Landed_rate__c> landedRateList = [Select Id, Name, Label__c,Landed_Rate__c,Related_Opportunity__c from Opportunity_Landed_rate__c] ;
         Test.stopTest();
    }
}