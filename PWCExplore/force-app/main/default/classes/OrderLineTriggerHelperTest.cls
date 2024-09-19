@isTest
public class OrderLineTriggerHelperTest {
    @testSetup
    public static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userOLTHT@godrej.com', username = 'test.userOLTHT@godrej.com',Business_Unit__c = 'K');

        //userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        // Create Account.
        System.runAs(userToRun) {
                        
            Account accountRecord = createAccountRecord();
            insert accountRecord;

            List<Branch__c> branchRecords = createBranchRecords(accountRecord.Id, userToRun);
            insert branchRecords;
            
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
            //Added by pankaj to add shipping branch on primary order on 10/3/2022
            ZipCode__c zipCode = new ZipCode__c(Name='110001',Shipping_branch__c='NG1');
            insert zipCode;
            //End by pankaj
            Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B',Building__c='Daisy',zipCode__c=zipCode.Id); //added Building__c by Shreela on 11th April 2022
            insert firstaddress;
            
            Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id, Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, Ship_To__c = TRUE, Sold_To__c  = TRUE,Integration_Status__c ='Synced');
            insert firstAddressByBp;
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;
            test.startTest();
            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun, firstAddressByBp);
            insert quoteRecord;

            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pricebookEntryRecords);
            insert quoteLineItems;
            test.stopTest();
        }
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA',Business_Unit__c = 'K');
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

    private static Quote createQuoteRecord(Opportunity oppRecord, User userRecord,Address_by_BP__c address) {
        Quote quoteRecord = new Quote();
        quoteRecord.Name = 'Test Quote';
        quoteRecord.OpportunityId = oppRecord.Id;
        quoteRecord.Pricebook2Id = oppRecord.Pricebook2Id;
        quoteRecord.ExpirationDate = oppRecord.CloseDate;
        quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'MHE_Equipments');
        quoteRecord.Sold_To_Business_Partner__c = oppRecord.AccountId;
        quoteRecord.Ship_To_Address__c = address.Id;
        quoteRecord.Sold_to_Address__c = address.Id;
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

    @IsTest
    static void createOrderTest(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userOLTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                           Gross_Net__c='1', Level__c='2', Stage__c='Active');
            insert defaultDiscountMatrix;

            Quote quoteRecord = [Select Id, Name FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
            List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];

            // Create quote line item data mapper in JSON format.
            List<QuoteLineItemMapper> qliMapperList = new List<QuoteLineItemMapper>();
            for(QuoteLineItem qli : quoteLineItems) {
                QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
                qliMapper.id = qli.Id;
                qliMapper.name = quoteRecord.Name;
                qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
                qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
                qliMapperList.add(qliMapper);
            }
            
            Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
            QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord, Null);
            List<Order> orderRecord = new List<Order>([Select Id, (Select Id FROM OrderItems) FROM Order LIMIT 1]);
            System.assertEquals(1, orderRecord.size());
            System.assertEquals(quoteLineItems.size(), (orderRecord[0].OrderItems).size());
        }
        Test.stopTest();
    }

    @IsTest
    static void createOrderAndUpdate_OLI_UnitPrice() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userOLTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                           Gross_Net__c='1', Level__c='2', Stage__c='Active');
            insert defaultDiscountMatrix;

            List<Product2> productList = [Select Id, Name, Is_Generic_Product__c FROM Product2];
            for(Product2 product : productList) {
                product.Is_Generic_Product__c = true;
            }

            update productList;

            Quote quoteRecord = [Select Id, Name FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
            List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];

            // Create quote line item data mapper in JSON format.
            List<QuoteLineItemMapper> qliMapperList = new List<QuoteLineItemMapper>();
            for(QuoteLineItem qli : quoteLineItems) {
                QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
                qliMapper.id = qli.Id;
                qliMapper.name = quoteRecord.Name;
                qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
                qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
                qliMapperList.add(qliMapper);
            }
            
            Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
            QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord,Null);
            List<Order> orderRecord = new List<Order>([Select Id, (Select Id, UnitPrice,Line_Discount__c,Discount_Amount__c,ListPrice   FROM OrderItems) FROM Order LIMIT 1]);
            List<OrderItem> oliList = new List<OrderItem>();
			for(OrderItem oli : orderRecord[0].OrderItems) {
                oli.UnitPrice *= 2;
                oliList.add(oli);
            }
            update oliList;	
            System.assertEquals(1, orderRecord.size());
            System.assertEquals(quoteLineItems.size(), (orderRecord[0].OrderItems).size());
        }
        Test.stopTest();
    }

    @IsTest
    static void createAnOrderWithAnExchangeItem() {
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userOLTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            //added by Shreela on 11th April 2022
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OrderTriggerDisabled__c = true;
            insert setting;
            //ended by Shreela on 11th April 2022
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                           Gross_Net__c='1', Level__c='2', Stage__c='Active',Discount_Amount__c=3400); //added Discount_Amount__c by Shreela on 11th April 2022
            insert defaultDiscountMatrix;

            List<Product2> productList = [Select Id, Name, Is_Generic_Product__c FROM Product2];
            for(Product2 product : productList) {
                product.Is_Generic_Product__c = true;
            }

            update productList;

            Quote quoteRecord = [Select Id, Name ,Sold_to_Address__r.Integration_Status__c ,Ship_To_Address__r.Integration_Status__c FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
            quoteRecord.Sold_to_Address__r.Integration_Status__c = 'Synced';
            quoteRecord.Ship_To_Address__r.Integration_Status__c = 'Synced';
            List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];

            // Create quote line item data mapper in JSON format.
            List<QuoteLineItemMapper> qliMapperList = new List<QuoteLineItemMapper>();
            for(QuoteLineItem qli : quoteLineItems) {
                QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
                qliMapper.id = qli.Id;
                qliMapper.name = quoteRecord.Name;
                qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
                qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
                qliMapperList.add(qliMapper);
            }
            
            Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
            QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord,Null);
            List<Order> orderRecord = new List<Order>([Select Id, (Select Id, UnitPrice FROM OrderItems) FROM Order LIMIT 1]);
            List<OrderItem> oliList = new List<OrderItem>();

            for(OrderItem oli : orderRecord[0].OrderItems) {
                oli.UnitPrice *= 2;
                oli.Old_Appliance_Brand__c = 'LG';
                oliList.add(oli);
            }
            update oliList;

            System.assertEquals(1, orderRecord.size());
            System.assertEquals(quoteLineItems.size(), (orderRecord[0].OrderItems).size());
        }
        Test.stopTest();
    }
}