@isTest
public class InventoryUtilityControllerTest {
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

        Warehouse__c warehouseRecord3 = new Warehouse__c();
        warehouseRecord3.Channel__c = 'VAS';
        warehouseRecord3.Channel_Type__c = 'Institution';
        warehouseRecord3.Hub__c = 'North Hub';
        warehouseRecord3.Logistic_Company__c = '5010';
        warehouseRecord3.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord3.Warehouse__c = 'ZXF004';
        warehouseRecord3.Zone__c = 'North Hub';
        warehouseRecordList.add(warehouseRecord3);

        Warehouse__c warehouseRecord4 = new Warehouse__c();
        warehouseRecord4.Channel__c = 'VAS';
        warehouseRecord4.Channel_Type__c = 'Institution';
        warehouseRecord4.Hub__c = 'North Hub';
        warehouseRecord4.Logistic_Company__c = '5010';
        warehouseRecord4.Stock_Category__c = 'Finished Goods -Branches';
        warehouseRecord4.Warehouse__c = 'ZXF007';
        warehouseRecord4.Zone__c = 'North Hub';
        warehouseRecordList.add(warehouseRecord4);

        return warehouseRecordList;
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(FirstName='Test', LastName='Account', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
        return accountRecord;
    }

    private static List<ZipCode__c> createZipCodes() {
        List<ZipCode__c> zipCodesToCreate = new List<ZipCode__c>();
        for(Integer i = 1; i<3; i++){
            ZipCode__c zipCode = new ZipCode__c();
            if(i == 1){
                zipCode.Name = '410002';
                zipCode.CityCode__c = 'PUNE';
                zipCode.City_Name__c = 'PUNE';
                zipCode.StateCode__c = 'MH';
                zipCode.StateName__c = 'Maharashtra';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_410002';
            } else {
                zipCode.Name = '110008';
                zipCode.CityCode__c = 'Delhi';
                zipCode.City_Name__c = 'DELHI';
                zipCode.StateCode__c = 'DL';
                zipCode.StateName__c = 'Delhi';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_110008';
            }
             
            zipCodesToCreate.add(zipCode);
        }
        return zipCodesToCreate;
    }

    private static Branch__c createBranchRecordWithAddress(Account accountRecord) {
        List<ZipCode__c> zipCodesToCreate = createZipCodes();
        insert zipCodesToCreate;

        List<Address__c> addressesToCreate = new List<Address__c>();

        for(Integer i = 1; i<3; i++) {
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Building__c = '12345';
            address.Street__c = '2nd street';
            if(i == 1){
                address.Name__c = 'Nuvoco Plant Pune';
                address.Telephone__c = '8765432111';
                address.Email__c = 'punetest1234@nuvoco.com';
                address.ZipCode__c = zipCodesToCreate[0].Id;
                address.Street__c = '2nd street';
            } else {
                address.Name__c = 'Nuvoco Plant Delhi';
                address.Telephone__c = '8765432110';
                address.Email__c = 'delhitest1234@nuvoco.com';
                address.ZipCode__c = zipCodesToCreate[1].Id;
                address.Street__c = '2nd street';
            }
            addressesToCreate.add(address);
        }
        insert addressesToCreate;

        //Create Tax Number record
        Tax_Number__c tax = new Tax_Number__c();
        tax.Business_Partner__c = accountRecord.Id;
        //tax.Address_Code__c = AddressesToCreate[0].Id;
        tax.Country__c = 'IND';
        //tax.State_Province_Name__c = 'IND_MH'; 
        tax.Tax_Number__c = 'AASCS6585A';
        tax.Category__c = 'PAN';
        tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
        
        insert tax;

        Branch__c branch = new Branch__c();
        branch.Business_Partner__c = accountRecord.Id;
        branch.Business_Partner_Status__c = 'Open';
        branch.Business_Partner_Status_Ship_To__c = 'Open';
        branch.Branch_Name__c = '5010';
        branch.Channel__c = 'VAS';
        branch.Line_of_Business__c = 'AGRO';
        branch.Area__c = 'WN1';
        branch.Ship_To_Address__c = addressesToCreate[0].Id;
        branch.Sold_To_Address__c = addressesToCreate[0].Id;
        
        return branch;
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
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'MHE');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE;
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

    private static Opportunity createApplianceOpportunity(Account accountRecord, User userToRun, Pricebook2 pricebookRecord) {
        Opportunity opp = new Opportunity(Name = 'Test Appliance Opportunity', AccountId = accountRecord.Id, StageName = 'Qualification');
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'Interio_B2C_Appliances');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = 'H';
        opp.CloseDate = (Date.today()).addDays(10);
        opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
        return opp;
    }

    private static List<OpportunityLineItem> createApplianceOpportunityLineItems(List<PricebookEntry> pricebookEntries, Opportunity oppRecord) {
        List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
        for(PricebookEntry pbe : pricebookEntries) {
            OpportunityLineItem oppProduct = new OpportunityLineItem();
            oppProduct.PricebookEntryId = pbe.Id;
            oppProduct.Quantity = 1;
            oppProduct.UnitPrice = pbe.UnitPrice;
            oppProduct.OpportunityId = oppRecord.Id;
            oppProducts.add(oppProduct);
        }
        return oppProducts;
    }

    private static Quote createQuoteRecord(Opportunity oppRecord, User userRecord) {
        Quote quoteRecord = new Quote();
        quoteRecord.Name = 'Test Quote';
        quoteRecord.OpportunityId = oppRecord.Id;
        quoteRecord.Pricebook2Id = oppRecord.Pricebook2Id;
        quoteRecord.ExpirationDate = oppRecord.CloseDate;
        quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'MHE_Equipments');
        quoteRecord.Sold_To_Business_Partner__c = oppRecord.AccountId;
        quoteRecord.Ship_To_Account__c = oppRecord.AccountId;
        quoteRecord.Area_Code__c = userRecord.Area_Code__c;
        quoteRecord.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;

        return quoteRecord;
    }

    private static List<QuoteLineItem> createQuoteLineItemRecords(Quote quoteRecord, List<PricebookEntry> pricebookEntryRecords) {
        List<QuoteLineItem> quoteLineItemRecords = new List<QuoteLineItem>();
        Integer quantityMultiplier = 1;
        for(PricebookEntry pricebookEntryRecord : pricebookEntryRecords) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = quoteRecord.Id;
            qli.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli.Product2Id = pricebookEntryRecord.Product2Id;
            qli.Quantity = 1 * quantityMultiplier;
            qli.PricebookEntryId = pricebookEntryRecord.Id;
            quoteLineItemRecords.add(qli);
        }

        return quoteLineItemRecords;
    }

    private static void init(User userRecord) {
        Account accountRecord = createAccountRecord();
        insert accountRecord;

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

        Opportunity oppRecord = createOpportunityRecord(accountRecord, userRecord, pricebookRecord);
        insert oppRecord;

        List<OpportunityLineItem> oppLineItems = createOpportunityLineItems(pricebookEntryRecords, oppRecord);
        insert oppLineItems;

        Quote quoteRecord = createQuoteRecord(oppRecord, userRecord);
        insert quoteRecord;

        List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pricebookEntryRecords);
        insert quoteLineItems;
    }

    private static void createNormalOrderAndOrderItemRecords(Opportunity opportunityRecord, PricebookEntry pricebookEntryRecord) {
        Order orderRecord = new Order( Logistics_Company_Branch__c = '5010',
            Line_of_Business__c = 'CHEM', PriceBook2Id = pricebookEntryRecord.Pricebook2Id,
            Business_Unit__c = 'K', Sub_Division__c = 'B2B',
            AccountId = opportunityRecord.AccountId, OpportunityId = opportunityRecord.Id,
            RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Order', 'MHE_Order_Primary'),EffectiveDate = System.today(),Status = 'Draft');
        insert orderRecord;

        List<OrderItem> allOLI = new List<OrderItem> {
            new OrderItem(OrderId = orderRecord.Id, 
            Quantity  = 1, PriceBookEntryId = pricebookEntryRecord.Id,
            UnitPrice =  pricebookEntryRecord.UnitPrice ),

            new OrderItem(OrderId = orderRecord.Id,
            Quantity  = 1, PriceBookEntryId = pricebookEntryRecord.Id,
            UnitPrice =  pricebookEntryRecord.UnitPrice)
        };
        insert allOLI;
    }

    private static void createApplianceOrderAndOrderItemRecords(Opportunity opportunityRecord, PricebookEntry pricebookEntryRecord, Branch__c branchRecord) {
        Order orderRecord = new Order( Logistics_Company_Branch__c = '2400',
            Line_of_Business__c = 'CMC', PriceBook2Id = pricebookEntryRecord.Pricebook2Id,
            Business_Unit__c = 'H', Sub_Division__c = 'B2B',
            Branch__c = branchRecord.Id, AccountId = opportunityRecord.AccountId, OpportunityId = opportunityRecord.Id,
            RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Order', 'Appliance_Primary'),
            EffectiveDate = System.today(),Status = 'Draft'); //added EffectiveDate and Status by Shreela on 25th May 2022
        insert orderRecord;

        List<OrderItem> allOLI = new List<OrderItem> {
            new OrderItem(OrderId = orderRecord.Id, 
            Quantity  = 1, PriceBookEntryId = pricebookEntryRecord.Id,
            UnitPrice =  pricebookEntryRecord.UnitPrice ),

            new OrderItem(OrderId = orderRecord.Id,
            Quantity  = 1, PriceBookEntryId = pricebookEntryRecord.Id,
            UnitPrice =  pricebookEntryRecord.UnitPrice)
        };
        insert allOLI;
    }

    @IsTest
    static void testWarehouseDefaultingLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            setting.CaseTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true;
            setting.AddressByBPTriggerDisabled__c = true;
            setting.BranchTriggerDisabled__c = true; //added by shreela on 25th May 2022
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            Test.startTest();
            init(userToRun);
            Test.stopTest();
        }
    }

    @IsTest
    static void defaultChannelOpportunityWarehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            List<Opportunity> opportunityRecords = [Select Id, RecordTypeId, Business_Unit__c, AccountId, WarehouseCode__c 
                FROM Opportunity LIMIT 1];
            (new InventoryUtilityController()).populateApplianceAndNormalOpportunityWarehouse(opportunityRecords);
        }
    }

    @IsTest
    static void validateApplianceOpportunities_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            List<Opportunity> opportunityRecords = [Select Id, RecordTypeId, Business_Unit__c, AccountId, WarehouseCode__c 
                FROM Opportunity LIMIT 1];
            
            opportunityRecords[0].WarehouseCode__c = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ZXF002' LIMIT 1][0].Id;
            try {
                (new InventoryUtilityController()).validateApplianceAndNormalOpportunityWarehouse(opportunityRecords);
            } catch(Exception ex) {
                Boolean isException = true;
                System.assertEquals(true, isException);
            }
        }
    }

    @IsTest
    static void defaultChannelBased_OppProduct_Warehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>([Select Id, RecordTypeId, Business_Unit__c, AccountId, WarehouseCode__c 
                FROM Opportunity LIMIT 1]);
            
            List<OpportunityLineItem> oppLineItems = createApplianceOpportunityLineItems(pbeEntries, (opportunityRecordMap.values())[0] );
            
            (new InventoryUtilityController()).populateApplianceAndNormal_OppProduct_Warehouse(oppLineItems, opportunityRecordMap);
        }
    }

    @IsTest
    static void validateChannelBased_OppProduct_Warehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Map<Id, Opportunity> opportunityRecordMap = new Map<Id, Opportunity>([Select Id, RecordTypeId, Business_Unit__c, AccountId, WarehouseCode__c 
                FROM Opportunity LIMIT 1]);
            
            List<OpportunityLineItem> oppLineItems = createApplianceOpportunityLineItems(pbeEntries, (opportunityRecordMap.values())[0] );
            insert oppLineItems;

            List<OpportunityLineItem> updatedOppLineItem = [Select Id, OpportunityId, Warehouse__c FROM OpportunityLineItem
                WHERE OpportunityId = :oppRecord.Id LIMIT 1];
            
            updatedOppLineItem[0].Warehouse__c = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ZXF002' LIMIT 1][0].Id;
            
            try {
                (new InventoryUtilityController()).validateOpportunityProductWarehouses(oppLineItems, opportunityRecordMap);
            } catch(Exception ex) {
                Boolean isException = true;
                System.assertEquals(true, isException);
            }
        }
    }

    @IsTest
    static void defaultApplianceQuoteWarehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            accountRecord.Business_Unit__c='H';
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun);
            quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'Appliances');
            quoteRecord.Account_Name__c = accountRecord.Id;

            List<Quote> quoteRecordList = new List<Quote>();
            quoteRecordList.add(quoteRecord);
            (new InventoryUtilityController()).defaultApplianceAndNormalQuoteWarehouse(quoteRecordList);
        }
    }

    @IsTest
    static void validateApplianceQuoteWarehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            accountRecord.Business_Unit__c='H';
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun);
            quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'Appliances');
            quoteRecord.Account_Name__c = accountRecord.Id;
            insert quoteRecord;

            List<Quote> quoteRecordList = new List<Quote>([Select Id, RecordTypeId, WarehouseCode__c, Account_Name__c FROM Quote LIMIT 1]);
            quoteRecordList[0].WarehouseCode__c = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ZXF002' LIMIT 1][0].Id;
            (new InventoryUtilityController()).validateApplianceAndNormalQuoteWarehouses(quoteRecordList);
        }
    }

    @IsTest
    static void defaultChannelBased_QLI_Warehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c ='H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Account accountRecord = createAccountRecord();
            accountRecord.Business_Unit__c='H';
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun);
            quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'Appliances');
            quoteRecord.Account_Name__c = accountRecord.Id;
            insert quoteRecord;

            List<PricebookEntry> pbeRecordList = [Select Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookRecord.Id];

            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pbeRecordList);

            Map<Id, Quote> quoteRecordMap = new Map<Id, Quote>([Select Id, RecordTypeId, Account_Name__c, WarehouseCode__c 
                FROM Quote LIMIT 1]);
            
            (new InventoryUtilityController()).populateApplianceAndNormal_QLI_Warehouses(quoteLineItems, quoteRecordMap);
        }
    }

    @IsTest
    static void validateChannelBased_QLI_Warehouses_Test() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            setting.CaseTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true;
            setting.AddressByBPTriggerDisabled__c = true;
            setting.BranchTriggerDisabled__c = true; //added by shreela on 25th May 2022
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            Account accountRecord = createAccountRecord();
            accountRecord.Business_Unit__c = 'H';
            insert accountRecord;

            List<Product2> productList = createProductRecords();
            insert productList;

            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            List<PricebookEntry> standardPBEntries = createStandardPricebookEntries(productList);
            insert standardPBEntries;

            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;

            List<PricebookEntry> pbeEntries = createPricebookEntryRecords(productList, pricebookRecord);
            insert pbeEntries;

            Opportunity oppRecord = createApplianceOpportunity(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;

            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun);
            quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'Appliances');
            quoteRecord.Account_Name__c = accountRecord.Id;
            insert quoteRecord;

            List<PricebookEntry> pbeRecordList = [Select Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookRecord.Id];

            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pbeRecordList);
            insert quoteLineItems;

            Map<Id, Quote> quoteRecordMap = new Map<Id, Quote>([Select Id, RecordTypeId, Account_Name__c, WarehouseCode__c 
                FROM Quote LIMIT 1]);

            List<QuoteLineItem> updatedQuoteLineItem = [Select Id, QuoteId, Warehouse__c FROM QuoteLineItem
            WHERE QuoteId = :quoteRecord.Id LIMIT 1];
            
            updatedQuoteLineItem[0].Warehouse__c = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ZXF002' LIMIT 1][0].Id;
            
            try {
                (new InventoryUtilityController()).validateApplianceAndNormal_QLI_Warehouses(updatedQuoteLineItem, quoteRecordMap);
            } catch(Exception ex) {
                Boolean isException = true;
                System.assertEquals(true, isException);
            }
        }
    }

    @IsTest
    static void testNormalOrderAndOrderLineDefaultingLogic() {
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c ='H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance();
            setting2.QLITriggerDisabled__c = true;
            setting2.LeadTriggerDisabled__c = true;
            insert setting2 ;
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];

            Test.startTest();
            createNormalOrderAndOrderItemRecords(opp, pbeRecords[0]);

            Order orderRecord = [Select Id, WarehouseCode__c FROM Order LIMIT 1];
            orderRecord.WarehouseCode__c = null;
            update orderRecord;

            List<OrderItem> orderItemRecords = [Select Id, Warehouse__c FROM OrderItem];
            List<OrderItem> orderItemRecordsToUpdate = new List<OrderItem>();
            for(OrderItem orderItemRecord : orderItemRecords) {
                orderItemRecord.Warehouse__c = null;
                orderItemRecordsToUpdate.add(orderItemRecord);
            }
            update orderItemRecordsToUpdate;

            Test.stopTest();
        }
    }

    @IsTest
    static void testNormalOrderValidationLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Warehouse__c newWarehouse = new Warehouse__c();
        newWarehouse.Channel__c = 'VAS';
        newWarehouse.Channel_Type__c = 'Institution';
        newWarehouse.Hub__c = 'North Hub';
        newWarehouse.Logistic_Company__c = '5010';
        newWarehouse.Stock_Category__c = 'Finished Goods -Branches';
        newWarehouse.Warehouse__c = 'ZXF003';
        newWarehouse.Zone__c = 'North Hub';
        insert newWarehouse;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance(); //Added by Shreela on 25th Jan 2023 for resolving 101 soql query iss
            setting2.QLITriggerDisabled__c = true;
            setting2.LeadTriggerDisabled__c = true;
            insert setting2 ;
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];

            Test.startTest();
            createNormalOrderAndOrderItemRecords(opp, pbeRecords[0]);
            Order orderRecord = [Select Id, WarehouseCode__c FROM Order LIMIT 1];
            orderRecord.WarehouseCode__c = newWarehouse.Id;
            try {
                update orderRecord;
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(System.Label.NON_PRIMARY_WAREHOUSE_ADDED) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testNormalOrderItemValidationLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Warehouse__c newWarehouse = new Warehouse__c();
        newWarehouse.Channel__c = 'VAS';
        newWarehouse.Channel_Type__c = 'Institution';
        newWarehouse.Hub__c = 'North Hub';
        newWarehouse.Logistic_Company__c = '5010';
        newWarehouse.Stock_Category__c = 'Finished Goods -Branches';
        newWarehouse.Warehouse__c = 'ZXF003';
        newWarehouse.Zone__c = 'North Hub';
        insert newWarehouse;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance(); //Added by Shreela on 25th Jan 2023 for resolving 101 soql query issue
            setting2.QLITriggerDisabled__c = true;
            setting2.LeadTriggerDisabled__c = true;
            insert setting2 ;
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];

            Test.startTest();
            createNormalOrderAndOrderItemRecords(opp, pbeRecords[0]);
            List<OrderItem> orderItemRecords = [Select Id, Warehouse__c FROM OrderItem LIMIT 1];
            List<OrderItem> ordeItemRecordsToUpdate = new List<OrderItem>();

            for(OrderItem orderItemRecord : orderItemRecords) {
                orderItemRecord.Warehouse__c = newWarehouse.Id;
                ordeItemRecordsToUpdate.add(orderItemRecord);
            }

            try {
                update ordeItemRecordsToUpdate;
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(System.Label.NON_PRIMARY_WAREHOUSE_ADDED) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testChannelOrderAndOrderLineDefaultingLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance(); //Added by Shreela on 25th Jan 2023 for resolving 101 soql query iss
            setting2.OpportunityTriggerDisabled__c = true;
            //setting2.FireQLIValidationRules__c = false;
            setting2.BranchTriggerDisabled__c = true;
            //setting2.UserTriggerDisabled__c = true;
            setting2.OpportunityProductTriggerDisabled__c = true;
            setting2.AddressByBPTriggerDisabled__c = true;
            setting2.QuoteTriggerDisabled__c = true;//Added by pankaj on 10 april 2023
            insert setting2 ;
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];
            
            Test.startTest();
            Account accountRecord = [Select Id, Name FROM Account LIMIT 1];
            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            
            createApplianceOrderAndOrderItemRecords(opp, pbeRecords[0], branchRecord);

            Order orderRecord = [Select Id, WarehouseCode__c FROM Order LIMIT 1];
            orderRecord.WarehouseCode__c = null;
            update orderRecord;

            List<OrderItem> orderItemRecords = [Select Id, Warehouse__c FROM OrderItem];
            List<OrderItem> orderItemRecordsToUpdate = new List<OrderItem>();
            for(OrderItem orderItemRecord : orderItemRecords) {
                orderItemRecord.Warehouse__c = null;
                orderItemRecordsToUpdate.add(orderItemRecord);
            }
            update orderItemRecordsToUpdate;

            Test.stopTest();
        }
    }

    @IsTest
    static void testChannelOrderValidationLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Warehouse__c newWarehouse = new Warehouse__c();
        newWarehouse.Channel__c = 'VAS';
        newWarehouse.Channel_Type__c = 'Institution';
        newWarehouse.Hub__c = 'North Hub';
        newWarehouse.Logistic_Company__c = '5010';
        newWarehouse.Stock_Category__c = 'Finished Goods -Branches';
        newWarehouse.Warehouse__c = 'ZXF003';
        newWarehouse.Zone__c = 'North Hub';
        insert newWarehouse;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance(); //Added by Shreela on 25th Jan 2023 for resolving 101 soql query iss
            //setting2.OpportunityTriggerDisabled__c = true;
            //setting2.FireQLIValidationRules__c = false;
            setting2.BranchTriggerDisabled__c = true;
            setting2.UserTriggerDisabled__c = true;
            //setting2.PricingApprovalRequestTriggerDisabled__c = true;
            //setting2.AddressByBPTriggerDisabled__c = true;
            setting2.QLITriggerDisabled__c = true;
            insert setting2 ;
                    
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];
            
            Test.startTest();
            Account accountRecord = [Select Id, Name FROM Account LIMIT 1];
            Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord;

            //Test.startTest();
            createApplianceOrderAndOrderItemRecords(opp, pbeRecords[0], branchRecord);

            Order orderRecord = [Select Id, WarehouseCode__c FROM Order LIMIT 1];
            orderRecord.WarehouseCode__c = newWarehouse.Id;
            try {
                update orderRecord;
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = true;
                System.AssertEquals(true, expectedExceptionThrown);
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void testChannelOrderItemValidationLogic() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'WarehouseTest', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'warehousetest.user@godrej.com', Business_Unit__c = 'H');

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Primary_Warehouses__c = 'ZXF001';
        userToRun.Secondary_Warehouses__c = 'ZXF002';
        insert userToRun;

        Warehouse__c newWarehouse = new Warehouse__c();
        newWarehouse.Channel__c = 'VAS';
        newWarehouse.Channel_Type__c = 'Institution';
        newWarehouse.Hub__c = 'North Hub';
        newWarehouse.Logistic_Company__c = '5010';
        newWarehouse.Stock_Category__c = 'Finished Goods -Branches';
        newWarehouse.Warehouse__c = 'ZXF003';
        newWarehouse.Zone__c = 'North Hub';
        insert newWarehouse;

        System.runAs(userToRun) {
            Runtime_Execution__c setting2 = Runtime_Execution__c.getInstance(); //Added by Shreela on 25th Jan 2023 for resolving 101 soql query iss
            //setting2.OpportunityTriggerDisabled__c = true;
            //setting2.FireQLIValidationRules__c = false;
            //setting2.BranchTriggerDisabled__c = true;
            //setting2.UserTriggerDisabled__c = true;
            //setting2.PricingApprovalRequestTriggerDisabled__c = true;
            //setting2.ProductTriggerDisabled__c = true;
            //setting2.OpportunityProductTriggerDisabled__c = true;
            //setting2.AddressByBPTriggerDisabled__c = true;
             setting2.QLITriggerDisabled__c = true;
            //setting2.LeadTriggerDisabled__c = true;
            insert setting2 ;
            init(userToRun);
            Opportunity opp = [Select Id, AccountId FROM Opportunity LIMIT 1];
            List<PricebookEntry> pbeRecords = [Select Id, Name, PriceBook2Id, UnitPrice  FROM PricebookEntry];
            
            Test.startTest();
            Account accountRecord = [Select Id, Name FROM Account LIMIT 1];
            //Added by Shreela on 27th Jan 2023
            List<ZipCode__c> zipCodesToCreate = createZipCodes();
            insert zipCodesToCreate;


            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Building__c = '12345';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Street__c = '2nd street';
            address.ZipCode__c = zipCodesToCreate[0].Id;
            
            insert address; 
            
            //Create Tax Number record
            Tax_Number__c tax = new Tax_Number__c();
            tax.Business_Partner__c = accountRecord.Id;
            //tax.Address_Code__c = address.Id;
            tax.Country__c = 'IND';
            tax.State_Province_Name__c = 'IND_MH';
            tax.Tax_Number__c = 'AASCS6585A';
            //tax.Category__c = 'PAN';
            tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            
            insert tax; //End by Shreela on 27th Jan 2023
            /*Branch__c branchRecord = createBranchRecordWithAddress(accountRecord);
            insert branchRecord; */
            
            Branch__c branchRecord= new Branch__c(); //Addede by Shreela on 27th Jan 2023
            branchRecord.Business_Partner__c = accountRecord.Id;
            branchRecord.Business_Partner_Status__c = 'Open';
            branchRecord.Business_Partner_Status_Ship_To__c = 'Open';
            branchRecord.Branch_Name__c = '5010';
            branchRecord.Channel__c = 'VAS';
            branchRecord.Line_of_Business__c = 'AGRO';
            branchRecord.Area__c = 'WN1';
            branchRecord.Ship_To_Address__c = address.Id;
            branchRecord.Sold_To_Address__c = address.Id;
            insert branchRecord;  //Ended by Shreela on 27th Jan 2023

            
            createApplianceOrderAndOrderItemRecords(opp, pbeRecords[0], branchRecord);
            List<OrderItem> orderItemRecords = [Select Id, Warehouse__c FROM OrderItem LIMIT 1];
            List<OrderItem> ordeItemRecordsToUpdate = new List<OrderItem>();

            for(OrderItem orderItemRecord : orderItemRecords) {
                orderItemRecord.Warehouse__c = newWarehouse.Id;
                ordeItemRecordsToUpdate.add(orderItemRecord);
            }

            try {
                update ordeItemRecordsToUpdate;
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(System.Label.NON_PRIMARY_CHANNEL_WAREHOUSE_ADDED) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
        }
    }
}