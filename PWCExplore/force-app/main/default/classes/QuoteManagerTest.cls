/**
* @description       : 
* @author            : Varun Rajpoot
* @group             : 
* @last modified on  : 10-01-2023
* @last modified by  : Varun Rajpoot
**/
@isTest
private class QuoteManagerTest {
    
    @TestSetup
    static void prepareData(){
        Test.startTest();
        //Added by Shreela on 16th Dec 2022
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.DiscountMatrixTriggerDisabled__c = true;
        setting.BranchTriggerDisabled__c = true;
        setting.UserTriggerDisabled__c = true;
        setting.PricingApprovalRequestTriggerDisabled__c = true;
        setting.ProductTriggerDisabled__c = true;
        setting.OpportunityProductTriggerDisabled__c = true;
        setting.OpportunityTriggerDisabled__c = true;
        setting.AddressByBPTriggerDisabled__c = true;
        setting.QLITriggerDisabled__c = true;
        setting.LeadTriggerDisabled__c = true;
        setting.QuoteTriggerDisabled__c = true;
        insert setting;
        QuoteTriggerHandler.TriggerDisabled = True;
        QLITriggerHandler.TriggerDisabled = True;
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userQMT@godrej.com', username = 'test.userQMT@godrej.com', Business_Unit__c = GlobalConstants.MHE_BUSINESS_UNIT);
        
        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            
            //Create Address Record
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'TEST ATTACH PAYMENT';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street'; 
            address.Integration_Status__c = 'synced';
            insert address;
            
            Warehouse__c whouse = new Warehouse__c();
            whouse.Warehouse__c='ABCDGY';
            insert whouse;
            
            List<Account> accList = new List<Account>();
            
            Account accountRecord = createAccountRecord();
            accountRecord.Primary_Address__c = address.Id;
            accList.add(accountRecord);
            Account accMHE = new Account(Name='MHE Business Account',Primary_Address__c = address.Id,Business_Unit__c='K',Industry='Manufacturing', Account_Code__c='ABC',
                                         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            
            Account accSSG = new Account(Name='SSG Business Account',Primary_Address__c = address.Id,Business_Unit__c='G',Industry='Manufacturing', Account_Code__c='PQR',
                                         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            accList.add(accMHE);
            accList.add(accSSG);
            Account locks_BU = new Account(Name='Locks Business Account',Primary_Address__c = address.Id,Business_Unit__c='L',Industry='Manufacturing', Account_Code__c='TPL',PAN__c='AABFA2957L',
                                           RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            accList.add(locks_BU);
            
            Account locks_influencer = new Account(Name='Influencer',Primary_Address__c = address.Id,Business_Unit__c='L',Industry='Manufacturing',PAN__c='AABFA2957L',
                                                   RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Influencer').getRecordTypeId());
            accList.add(locks_influencer);
            Account accConsM = new Account(Name='Construction Business Account',Primary_Address__c = address.Id,Business_Unit__c='N',Industry='Manufacturing', Account_Code__c='XYZ',
                                           RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            accList.add(accConsM);
            
             //Added by Rohit Jadhav for PED on 13 July 2023
            Account accPED = new Account(Name='PED Business Account',Primary_Address__c = address.Id,Business_Unit__c='P',Industry='Manufacturing', Account_Code__c='PYZ',
                                           RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            accList.add(accPED);
            
            insert accList;
            
            
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
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Discount_amount__c=200,Discount_percent__c=0,
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                            Gross_Net__c='1',Level__c='2', Stage__c='Active');
            Insert defaultDiscountMatrix;
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            insert oppRecord; 
            //Added by pankaj to add shipping branch on primary order
            ZipCode__c zipCode = new ZipCode__c(Name='110001',Shipping_branch__c='NG1');
            insert zipCode;
            //end by pankaj
            Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B',Building__c='Raevenues',ZipCode__c=zipCode.Id);
            insert firstaddress;
            
            Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id, Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, Ship_To__c = TRUE, Sold_To__c  = TRUE,Integration_Status__c ='Synced',Branch__c = branchRecords[0].Id);
            insert firstAddressByBp; //Added branch Id by Shreela on 15th Dec 2022 to bypass Update Real Account and Branch on Address By BP Process Builder
            
            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun,firstAddressByBp);
            insert quoteRecord;
            
            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pricebookEntryRecords);
            insert quoteLineItems;
            
        }
        Test.stopTest();
        
    }
    
    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment'.toUpperCase(), Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        return accountRecord;
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Name__c='Account for test class');
        return addr;
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
        
        //Added by Praful - 02-March-2021
        opp.Duration_Unit__c = 'Year';
        opp.Duration__c = 1;
        opp.Contract_Start_Date__c = system.today().addMonths(1);
        
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
    
    //Added by Praful - 02-March-2021
    @IsTest
    static void testPopulateEndDateDay(){
        
        //Added by Shreela on 16th Dec 2022
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.DiscountMatrixTriggerDisabled__c = true;
        setting.BranchTriggerDisabled__c = true;
        setting.UserTriggerDisabled__c = true;
        setting.PricingApprovalRequestTriggerDisabled__c = true;
        setting.ProductTriggerDisabled__c = true;
        setting.OpportunityProductTriggerDisabled__c = true;
        setting.OpportunityTriggerDisabled__c = true;
        setting.AddressByBPTriggerDisabled__c = true;
        setting.QLITriggerDisabled__c = true;
        setting.LeadTriggerDisabled__c = true;
        update setting; 
        
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        
        Test.startTest();
        quoteRecord.Duration_Unit__c = 'Day';
        update quoteRecord;
        Test.stopTest();
    }
    
    @IsTest
    static void testPopulateEndDateWeek(){
        
        //Added by Shreela on 16th Dec 2022
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.DiscountMatrixTriggerDisabled__c = true;
        setting.BranchTriggerDisabled__c = true;
        setting.UserTriggerDisabled__c = true;
        setting.PricingApprovalRequestTriggerDisabled__c = true;
        setting.ProductTriggerDisabled__c = true;
        setting.OpportunityProductTriggerDisabled__c = true;
        setting.OpportunityTriggerDisabled__c = true;
        setting.AddressByBPTriggerDisabled__c = true;
        setting.QLITriggerDisabled__c = true;
        setting.LeadTriggerDisabled__c = true;
        update setting;
        
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        
        Test.startTest();
        quoteRecord.Duration_Unit__c = 'Week';
        update quoteRecord;
        Test.stopTest();
    }
    
    @IsTest
    static void testPopulateEndDateMonth(){ 
        
        //Added by Shreela on 16th Dec 2022
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.DiscountMatrixTriggerDisabled__c = true;
        setting.BranchTriggerDisabled__c = true;
        setting.UserTriggerDisabled__c = true;
        setting.PricingApprovalRequestTriggerDisabled__c = true;
        setting.ProductTriggerDisabled__c = true;
        setting.OpportunityProductTriggerDisabled__c = true;
        setting.OpportunityTriggerDisabled__c = true;
        setting.AddressByBPTriggerDisabled__c = true;
        setting.QLITriggerDisabled__c = true;
        setting.LeadTriggerDisabled__c = true;
        update setting;
        
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        
        Test.startTest();
        quoteRecord.Duration_Unit__c = 'Month';
        update quoteRecord;
        Test.stopTest();
    }
    
    @IsTest
    static void testPopulateEndDateQuarter(){
        
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        
        Test.startTest();
        quoteRecord.Duration_Unit__c = 'Quarter';
        update quoteRecord;
        Test.stopTest();
    }
    
    @IsTest
    static void testPopulateEndDateYear(){
        
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        
        Test.startTest();
        quoteRecord.Duration_Unit__c = 'Month';
        update quoteRecord;
        quoteRecord.Duration_Unit__c = 'Year';
        update quoteRecord;
        Test.stopTest();
    }
    
    @IsTest
    static void getQuoteDataTest(){
        Test.startTest();
        User contextuser = [Select Id FROM User LIMIT 1];
        Map<String, String> jsonResponse = new Map<String, String>();
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
        update quoteRecord;
        
        
        
        string QuotedId =quoteRecord.Id;
        List<QuoteLineItemMapper> quoteLineItemMapperList = new List<QuoteLineItemMapper>();
        for(QuoteLineItem qli : quoteRecord.QuoteLineItems) {
            QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
            qliMapper.id = qli.Id;
            qliMapper.name = qli.Product2.Name;
            qliMapper.item_code='Test';
            qliMapper.Description = 'Test Desription';
            qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
            qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
            
            quoteLineItemMapperList.add(qliMapper);
        }
        
        jsonResponse.put('result', 'success');
        jsonResponse.put('error_message', null);
        jsonResponse.put('data', JSON.serialize(quoteLineItemMapperList));          
        QuoteManager.getQuoteData(QuotedId);
        Test.stopTest();
    } 
    
    
    @IsTest
    static void getQuoteDataSanctionTest(){
        Test.startTest();
        User contextuser = [Select Id FROM User LIMIT 1];
        Map<String, String> jsonResponse = new Map<String, String>();
        Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity FROM QuoteLineItems) FROM 
                             Quote WHERE Name = 'Test Quote' LIMIT 1
                            ];
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
        
        quoteRecord.LD_Applicable__c = true;
        quoteRecord.Credit_Terms__c = true;
        quoteRecord.Special_Delivery_Period__c = true;
        quoteRecord.BG_Status__c =GlobalConstants.STATUS_REQUESTED;
        quoteRecord.CG_Status__c = GlobalConstants.STATUS_REQUESTED;
        update quoteRecord;
        
        
        
        string QuotedId =quoteRecord.Id;
        List<QuoteLineItemMapper> quoteLineItemMapperList = new List<QuoteLineItemMapper>();
        for(QuoteLineItem qli : quoteRecord.QuoteLineItems) {
            QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
            qliMapper.id = qli.Id;
            qliMapper.name = qli.Product2.Name;
            qliMapper.item_code='Test';
            qliMapper.Description = 'Test Desription';
            qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
            qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
            
            quoteLineItemMapperList.add(qliMapper);
        }
        
        jsonResponse.put('result', 'success');
        jsonResponse.put('error_message', null);
        jsonResponse.put('data', JSON.serialize(quoteLineItemMapperList));          
        QuoteManager.getQuoteData(QuotedId);
        Test.stopTest();
    } 
    
    @IsTest
    static void createOrderTest(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userQMT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {           
            
            List<QuoteLineItem> qlit;
            Quote quoteRecord = [Select Id, Name FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
            List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];
            qlit = quoteLineItems;
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
            
            try{
                Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
                QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord, null);
            } catch (DmlException e) {
                String message = e.getMessage();
                System.assert(e.getMessage().contains('ERROR'), 'message=' + e.getMessage());
            }
            List<Order> orderRecord = new List<Order>([Select Id, (Select Id FROM OrderItems) FROM Order LIMIT 1]);
            System.assertEquals(1, orderRecord.size());
            System.assertEquals(qLit.size(), (orderRecord[0].OrderItems).size());
        }
        Test.stopTest();
    }
    
    //created on 16-03-2023b
    
    @IsTest
    static void createOrderNewTest(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userQMT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {           
            
            List<QuoteLineItem> qlit;
            Quote quoteRecord = [Select Id, Sold_to_Address__c,Ship_to_Address__c, Name, LD_Applicable__c,Credit_Terms__c,Special_Delivery_Period__c,BG_Status__c,CG_Status__c FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
            quoteRecord.LD_Applicable__c = True;
            quoteRecord.Credit_Terms__c = True;
            quoteRecord.Special_Delivery_Period__c = True; 
            quoteRecord.BG_Status__c = GlobalConstants.STATUS_REQUESTED;
            quoteRecord.CG_Status__c = GlobalConstants.STATUS_REQUESTED;
            update quoteRecord;
            
            Address_by_BP__c obj = new Address_by_BP__c(Id = quoteRecord.Sold_to_Address__c, Integration_Status__c = 'Draft');
            //Address_by_BP__c obj1 = new Address_by_BP__c(Id = quoteRecord.Ship_to_Address__c, Integration_Status__c = 'Draft');
            update obj;
            
            
            List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];
            qlit = quoteLineItems;
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
            
            try{
                Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
                QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord, null);
            } catch (Exception e) {
                String message = e.getMessage();
                
            }
            List<Order> orderRecord = new List<Order>([Select Id, (Select Id FROM OrderItems) FROM Order LIMIT 1]);
            //System.assertEquals(1, orderRecord.size());
            //System.assertEquals(qLit.size(), (orderRecord[0].OrderItems).size());
        }
        Test.stopTest();
    }
    
    
    //Added by siddhesh on 28/04/2022 to cover Locks & construction code on QuoteRecordProcessor test
    @IsTest
    static void CreateQuote_LocksBDE(){
        
        profile locksBDEProfile = [Select Id, Name from Profile where Name ='Locks branch user-BDE/BDM/BH/ZH/RH' limit 1]; 
        
        User objLocksBDE = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = locksBDEProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'loc.user@godrej.com', 
                                    Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT,Persona__c = 'Locks-BDE',
                                    Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert objLocksBDE;
        System.runAs(objLocksBDE){
            Test.startTest();
            ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
            insert zipcd;
            Account acc = [Select Id, name  from Account where name='Locks Business Account' Limit 1];
            Account acc_inf = [Select Id, name  from Account where name='Influencer' Limit 1];    
            Opportunity objLocksOpp = new Opportunity(Name = 'Test Opportunity', Business_Unit__c = 'L',OEM__c=acc.id,Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Dealer_Involved_Y_N__c ='No', AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Locks_B2B').getRecordTypeId(),LocksSegment__c='Logistics',Sub_segment__c='Others',CloseDate = System.today()+1,Influencer__c=acc_inf.id,Dealer_Name__c=acc.Id,ZipCode__c=zipcd.id);
            Insert objLocksOpp;
            Quote objLocksQuote = new Quote(Name='Locks Quote',OpportunityId=objLocksOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',Payment_Terms__c='10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Locks_B2B').getRecordTypeId(),Dealer_Name__c= null);
            Insert objLocksQuote;
            Test.stopTest();
        }
        
    } 
    
    @IsTest
    static void CreateQuote_LocksBDM(){
        profile locksBDMProfile = [Select Id, Name from Profile where Name ='Locks branch user-BDM' limit 1]; 
        User objLocksBDM = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = locksBDMProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'loc.user@godrej.com', 
                                    Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT,Persona__c = 'Locks-BDM',Sub_Division__c = 'B2B',
                                    Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert objLocksBDM;
        System.runAs(objLocksBDM){
            Test.startTest();
            ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
            insert zipcd;
            Account acc = [Select Id, name  from Account where name='Locks Business Account' Limit 1];
            Account acc_inf = [Select Id, name  from Account where name='Influencer' Limit 1];    
            Opportunity objLocksOpp = new Opportunity(Name = 'Test Opportunity', Business_Unit__c = 'L',OEM__c=acc.id,Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Dealer_Involved_Y_N__c ='Yes', AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId(),LocksSegment__c='Logistics',Sub_segment__c='Others',CloseDate = System.today()+1,Influencer__c=acc_inf.Id,Dealer_Name__c=acc.Id,ZipCode__c=zipcd.id);
            Insert objLocksOpp;
            Quote objLocksQuote = new Quote(Name='Locks Quote',OpportunityId=objLocksOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',Payment_Terms__c='10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId(),Dealer_Name__c= null);
            Insert objLocksQuote;
            Test.stopTest();
        }
        
    } 
    
    //Added by Srini for Creating Quote with Locks-ZM persona on 18th May 2023
   @IsTest
    static void CreateQuote_LocksZM(){
        profile locksZMProfile = [Select Id, Name from Profile where Name ='Locks branch user-BDE/BDM/BH/ZH/RH' limit 1]; 
        User objLocksZM = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = locksZMProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'loc.user@godrej.com', 
                                    Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT,Persona__c = 'Locks-ZM',Sub_Division__c = 'B2B',
                                    Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert objLocksZM;
        System.runAs(objLocksZM){
            Test.startTest();
            ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
            insert zipcd;
            Account acc = [Select Id, name  from Account where name='Locks Business Account' Limit 1];
            Account acc_inf = [Select Id, name  from Account where name='Influencer' Limit 1];    
            Opportunity objLocksOpp = new Opportunity(Name = 'Test Opportunity', Business_Unit__c = 'L',OEM__c=acc.id,Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Dealer_Involved_Y_N__c ='Yes', AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId(),LocksSegment__c='Logistics',Sub_segment__c='Others',CloseDate = System.today()+1,Influencer__c=acc_inf.Id,Dealer_Name__c=acc.Id,ZipCode__c=zipcd.id);
            Insert objLocksOpp;
            Quote objLocksQuote = new Quote(Name='Locks Quote',OpportunityId=objLocksOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',Payment_Terms__c='10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId(),Dealer_Name__c= null);
            Insert objLocksQuote;
            Test.stopTest();
        }      
    }
    @IsTest
    static void CreateSSGQuote(){
        profile SSGProfile = [Select Id, Name from Profile where Name ='SSG Supply & Design User' limit 1]; 
        User usrSSG = new User(EmailEncodingKey = 'UTF-8', firstName = 'SSG', lastname = 'User', Alias = 'Suser',
                               languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = SSGProfile.id,
                               timezonesidkey = 'Asia/Kolkata', email = 'SSG.user@godrej.com', username = 'SSG.user@godrej.com', 
                               Business_Unit__c = GlobalConstants.SSG_BUSINESS_UNIT,persona__c='SSG- Sales Engineer',
                               Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert usrSSG;
        System.runAs(usrSSG){
            Test.startTest();
            Account acc = [Select Id, name  from Account where name='SSG Business Account' Limit 1];
            Opportunity objSSGOpp = new Opportunity(Name = 'SSG Opportunity', Business_Unit__c = 'G',Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Dealer_Involved_Y_N__c ='Yes', AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId(),CloseDate = System.today()+1,Dealer_Name__c=acc.Id);
            Insert objSSGOpp;
            Quote objSSGQuote = new Quote(Name='SSG Quote',OpportunityId=objSSGOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',
                                          Payment_Terms__c='10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId(),
                                          Dealer_Name__c= null,Category__c = 'SFS Imported',Dealer_Margin_Dealer_order__c=10);
            Insert objSSGQuote;
            Test.stopTest();
        }
        
    } 
    
    @IsTest
    static void CreateMHEQuote(){
        profile MHEProfile = [Select Id, Name from Profile where Name ='MHE SOSer Engineer' limit 1]; 
        User objMHESerEngg = new User(EmailEncodingKey = 'UTF-8', firstName = 'MHE SOSer Engineer', lastname = 'User', Alias = 'tuser',
                                      languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = MHEProfile.id,
                                      timezonesidkey = 'Asia/Kolkata', email = 'senth.user@godrej.com', username = 'senth.user@godrej.com', 
                                      Business_Unit__c = GlobalConstants.MHE_BUSINESS_UNIT,Sub_Division__c = 'B2B',
                                      Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert objMHESerEngg;
        System.runAs(objMHESerEngg){
            Test.startTest();
            Account acc = [Select Id, name  from Account where name='MHE Business Account' Limit 1];  
            Opportunity objMHEOpp = new Opportunity(Name = 'Test Opportunity', Business_Unit__c = 'K',Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId(),CloseDate = System.today()+1);
            Insert objMHEOpp;
            Quote objMHEQuote = new Quote(Name='MHE Quote',OpportunityId=objMHEOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',
                                          Payment_Terms__c='Q10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId(),
                                          Contract_Start_Date__c=System.today()-1,Contract_End_Date__c=System.today()-100,
                                          Dealer_Name__c= null,Commission__c=1,SCC_Activities__c='Enquiry Generation;Demo Conducted;Commissioning of the equipment');
            Insert objMHEQuote;
            Quote objMHEQuote1 =[select id , name , (Select Id, Product2.Name, Quantity FROM QuoteLineItems)from Quote where Name='MHE Quote'];
            objMHEQuote1.Contract_End_Date__c=System.today() + 370;
            update objMHEQuote1;
            Test.stopTest();
        }  
    }
    
    @IsTest
    static void CreateConstructionMaterialsQuote(){
        profile ConstMProfile = [Select Id, Name from Profile where Name ='Construction Sales Head' limit 1]; 
        User usrConstM = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = ConstMProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'loc.user@godrej.com', 
                                  Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT,Persona__c = 'Construction-Sales Engineer',
                                  Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='123');
        insert usrConstM;
        
        System.runAs(usrConstM){
            Test.startTest();
            Account acc = [Select Id, name  from Account where name='Construction Business Account' Limit 1];
            Id warehouseid = [Select Id, Warehouse__c FROM Warehouse__c WHERE Warehouse__c = 'ABCDGY' LIMIT 1][0].Id;
            Opportunity objConstMOpp = new Opportunity(Name = 'Test ConstM', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT,
                                                       Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Project_qty_m3_1000__c=76,
                                                       AccountId = acc.Id,LOB_N__c='RMC',Site__c='Mumbai',Plant_Location__c='Nande',G_B_qty_m3_300__c=67,
                                                       RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId(),
                                                       CloseDate = System.today()+1,cluster__c = 'MUM',Internal_Sales_Rep__c=usrConstM.id,
                                                       WarehouseCode__c=warehouseid);
            Insert objConstMOpp;
            
            Opportunity objConstMDupOpp = new Opportunity(Name = 'Testdup ConstM', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT,
                                                     LOB_N__c='WPS',Estimated_Project_AAC_Qty_in_CBM__c=55,Estimated_Project_Duroplast_Qty_Bag__c=87,
                                                     Estimated_Project_EasyFix_Qty_Bag__c=45,G_B_Quantity_AAC_Qty_in_CBM__c=48,G_B_Quantity_Duroplast_Qty_Bags__c=81,
                                                     Est_Project_Solid_Concrete_Block_Nos__c=78,G_B_Quantity_Solid_Concrete_Block_Nos__c=60,Estimated_Project_Pavers_in_Sqm__c=90,
                                                     G_B_Quantity_Pavers_in_Sqm__c=96, Estimated_Project_Curb_Stone_in_Nos__c=83, G_B_Quantity_Curb_Stone_in_Nos__c=75,
                                                     G_B_Quantity_EasyFix_Qty_Bags__c=96,Estimated_Project_Tilefix_Qty_Bag__c=99,G_B_Quantity_Tilefix_Qty_Bags__c=29,CloseDate = System.today()+1,cluster__c = 'MUM',StageName ='Probing',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId());
                                                                                                                                                                                                                
            Insert objConstMDupOpp;				 //Added by Poonam for SCF - 69
            
            Quote objConstMQuote = new Quote(Name='ConstM Quote',OpportunityId=objConstMOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',Payment_Terms__c='10',
                                             RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId(),
                                             Dealer_Name__c= null);
            Insert objConstMQuote;
            Test.stopTest();
        }
        
    }
    
    @IsTest
    static void getEndDateBasedOnDurationTest(){
        
        Test.startTest(); //Added by shreela on 16th Dec 2022
        QuoteRecordProcessor QuoteRp = new QuoteRecordProcessor();
        QuoteRp.getEndDateBasedOnDuration(null,null,null);
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'Day');
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'Week');
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'Month');
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'Quarter');
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'Year');
        QuoteRp.getEndDateBasedOnDuration(Date.today(),1,'else');
        Test.stopTest(); //Added by shreela on 16th Dec 2022
        
    }
    
    //Added by Shreela on 16th December 2022
    @isTest
    public static void testupdateOpportunityStage(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.DiscountMatrixTriggerDisabled__c = true;
        setting.BranchTriggerDisabled__c = true;
        setting.UserTriggerDisabled__c = true;
        setting.PricingApprovalRequestTriggerDisabled__c = true;
        setting.ProductTriggerDisabled__c = true;
        setting.OpportunityProductTriggerDisabled__c = true;
        setting.OpportunityTriggerDisabled__c = true;
        setting.AddressByBPTriggerDisabled__c = true;
        setting.QLITriggerDisabled__c = true;
        setting.QuoteTriggerDisabled__c = true;
        setting.LeadTriggerDisabled__c = true;
        update setting;
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS;
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            
            insert applQuote;
            
            
            List<Quote> qRecord = [Select Id,Status,Record_Type_Developer_Name__c,OpportunityId  from Quote where name='Appl B2B Quote record' Limit 1];
            qRecord[0].Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
            update qRecord;
            QuoteRecordProcessor qrp = new QuoteRecordProcessor();
            qrp.updateOpportunityStage(qRecord);
            Test.stopTest();
            
        }
        
    } 
    
    //Added by Shreela on 16th December 2022
    @isTest
    public static void testupdatePaymentTermsofQLI(){
        
        List<Quote> qRecord = new List<Quote>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        update setting;  
        
        //Added profile and user By Shreela on 19th Dec 2022
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);
            
            insert pbeList;
            
            
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote);
            
            Quote applQuote2=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote2.Name = 'Appl B2B Quote record 2'; 
            applQuote2.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote2.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote2.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote2);
            insert qRecord; 
            
            QuoteLineItem qli = new QuoteLineItem();
            for(PricebookEntry pricebookEntryRecord : pbeList) {
                qli.QuoteId = applQuote.Id;
                qli.UnitPrice = pricebookEntryRecord.UnitPrice;
                qli.Product2Id = pricebookEntryRecord.Product2Id;
                qli.Quantity = 1;
                qli.PricebookEntryId = pricebookEntryRecord.Id;
            }
            insert qli;
            
            QuoteLineItem qli2 = new QuoteLineItem();
            for(PricebookEntry pricebookEntryRecord : pbeList) {
                qli2.QuoteId = applQuote2.Id;
                qli2.UnitPrice = pricebookEntryRecord.UnitPrice;
                qli2.Product2Id = pricebookEntryRecord.Product2Id;
                qli2.Quantity = 1;
                qli2.PricebookEntryId = pricebookEntryRecord.Id;
            }
            insert qli2; 
            
            
            
            List<Quote> qRecord2 = [Select Id,Status,Payment_Terms__c,Record_Type_Developer_Name__c,OpportunityId  from Quote where Record_Type_Developer_Name__c = 'Appliances' Limit 2];
            Map<Id,Quote> oldRecord = new  Map<Id,Quote>();
            for(Quote qRec : qRecord){
                oldRecord.put(qRec.Id,qRec);
            }
            for(Integer i =0;i<qRecord2.size();i++){
                if(i==0){
                    qRecord2[i].Payment_Terms__c  = GlobalConstants.PAYMENT_MODE_OTHERS;
                }
                else if(i==1){
                    qRecord2[i].Payment_Terms__c  = GlobalConstants.Payment_Terms_Value_C28; 
                }
            }
            update qRecord2;
            
            QuoteRecordProcessor qrp = new QuoteRecordProcessor();
            qrp.updatePaymentTermsofQLI(qRecord2,oldRecord);
            Test.stopTest();
            
        }
        
    }
    
    //Added by Shreela on 20th December 2022
    @isTest
    public static void testupdateLastApprovedDate(){
        
        List<Quote> qRecord = new List<Quote>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        update setting;  
        
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);
            
            insert pbeList;
            
            
            //Added Appliance B2B Opportunity
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
            //Added Quote 
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            applQuote.Approval_Status__c = GlobalConstants.Submitted_for_Approval; 
            qRecord.add(applQuote);
            
            insert qRecord; 
            
            
            List<Quote> qRecord2 = [Select Id,Status,Payment_Terms__c,Record_Type_Developer_Name__c,OpportunityId  from Quote where Record_Type_Developer_Name__c = 'Appliances' Limit 1];
            Map<Id,Quote> qRecordMap = new Map<Id,Quote>();
            Map<Id,Quote> oldRecord = new  Map<Id,Quote>();
            for(Quote qRec : qRecord){
                oldRecord.put(qRec.Id,qRec);
            }
            
            for(Quote qRec : qRecord2){
                qRec.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                qRecordMap.put(qRec.Id,qRec);
            }
            
            QuoteRecordProcessor qrp = new QuoteRecordProcessor();
            qrp.updateLastApprovedDate(qRecordMap,oldRecord);
            Test.stopTest();
            
        }
        
    }
    
    //Added by Shreela on 20th December 2022
    @isTest
    public static void testupdatePaymentTermsofQuote(){
        
        List<Quote> qRecord = new List<Quote>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        update setting;  
        
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);
            
            insert pbeList;
            
            
            //Added Appliance B2B Opportunity 
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
            //Added Quote
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote);
            
            Quote applQuote2=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote2.Name = 'Appl B2B Quote record 2'; 
            applQuote2.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote2.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote2.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote2);
            
            insert qRecord; 
            
            
            List<Quote> qRecord2 = [Select Id,Status,Payment_Terms__c,Record_Type_Developer_Name__c,OpportunityId  from Quote where Record_Type_Developer_Name__c = 'Appliances' Limit 2];
            Map<Id,Quote> oldRecord = new  Map<Id,Quote>();
            for(Quote qRec : qRecord){
                oldRecord.put(qRec.Id,qRec);
            }
            
            for(Integer i =0;i<qRecord2.size();i++){
                if(i==0){
                    qRecord2[i].Payment_Terms__c  = GlobalConstants.PAYMENT_MODE_OTHERS;
                }
                else if(i==1){
                    qRecord2[i].Payment_Terms__c  = GlobalConstants.Payment_Terms_Value_C28; 
                }
            }
            update qRecord2;
            
            QuoteRecordProcessor qrp = new QuoteRecordProcessor();
            qrp.updatePaymentTermsofQuote(qRecord2,oldRecord);
            Test.stopTest();
            
        }
        
    }
    
    //Added by Rohit Jadhav on 01/06/2023 to cover sendEmailNotificationOnLocksB2BQuoteApproval method on QuoteRecordProcessor test
    @IsTest
    static void testSendEmailNotificationOnLocksB2BQuoteApproval(){
        
        profile locksBDEProfile = [Select Id, Name from Profile where Name ='Locks branch user-BDE/BDM/BH/ZH/RH' limit 1];
                
        User objLocksBDE = new User(EmailEncodingKey = 'UTF-8', firstName = 'tests', lastname = 'User3', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = locksBDEProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test3.user@godrej.com', username = 'loc3.user@godrej.com', 
                                    Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT,Persona__c = 'Locks-BDE',
                                    Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        insert objLocksBDE;
        
        List<PricebookEntry> pricebookEntryList=[Select Id,UnitPrice,Product2Id,Pricebook2Id from PricebookEntry limit 1];
        
        Test.startTest();
        System.runAs(objLocksBDE){            
            ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
            insert zipcd;
            Account acc = [Select Id, name  from Account where name='Locks Business Account' Limit 1];
            Account acc_inf = [Select Id, name  from Account where name='Influencer' Limit 1]; 
            
            
            Opportunity objLocksOpp = new Opportunity(Name = 'Test Send Email Locks Opportunity', Business_Unit__c = 'L',OEM__c=acc.id,Sales_Branch_Name__c='1400',Sales_Zone__c ='EST',StageName ='Probing',Dealer_Involved_Y_N__c ='No', AccountId = acc.Id,RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Locks_B2B').getRecordTypeId(),LocksSegment__c='Logistics',Sub_segment__c='Others',CloseDate = System.today()+1,Influencer__c=acc_inf.id,Dealer_Name__c=acc.Id,ZipCode__c=zipcd.id);
            objLocksOpp.Pricebook2Id=pricebookEntryList[0].Pricebook2Id;
            Insert objLocksOpp;
            
            Quote objLocksQuote = new Quote(Name='Test Send Email Locks Quote',OpportunityId=objLocksOpp.id,ExpirationDate=System.today()+1,Delivery_Period__c='35',Payment_Terms__c='10',RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Locks_B2B').getRecordTypeId(),Dealer_Name__c= null);
            objLocksQuote.Pricebook2Id=pricebookEntryList[0].Pricebook2Id;
            Insert objLocksQuote;     
            
            QLITriggerHandler.TriggerDisabled=true;
            List<QuoteLineItem> quoteLineItemList=createQuoteLineItemRecords(objLocksQuote, pricebookEntryList);
            insert quoteLineItemList;         
            
            objLocksQuote.Approval_Status__c='Approved';
            update objLocksQuote;
        }
        
    }
    
      //Added by Rohit Jadhav for Creating Quote for PED on 13th July 2023
   @IsTest
    static void CreateQuote_PED(){
        profile pedProfile = [Select Id, Name from Profile where Name ='PED Regional Head Sales Mktg' limit 1]; 
         User pedTBandUser = new TestUserBuilder()
                .setProfileId(pedProfile.Id)
                .setLastName('T Band User')
               .setUserName('ped.TBandUser@godrej.com')
                .setLogisticCompany('1700')
                .setBusinessUnit('P')
              .setPersona('PED Head Sales - T Band')
                .getTestRecord();        
        pedTBandUser.IsActive = true; 
        insert pedTBandUser;
        
        User pedPBandUser = new TestUserBuilder()
                .setProfileId(pedProfile.Id)
                .setLastName('P Band User')
              .setUserName('ped.PBandUser@godrej.com')
                .setLogisticCompany('1700')
                .setBusinessUnit('P')
              .setPersona('PED Manager - P Band')
                .getTestRecord();        
        pedPBandUser.IsActive = true; 
        insert pedPBandUser;
        
        User pedOBandUser = new TestUserBuilder()
                .setProfileId(pedProfile.Id)
                .setLastName('O Band User')
              .setUserName('ped.OBandUser@godrej.com')
                .setLogisticCompany('1700')
                .setBusinessUnit('P')
              .setPersona('PED Asst Manager - O Band')
                .getTestRecord();        
        pedOBandUser.IsActive = true; 
        insert pedOBandUser;
        
        System.runAs(pedOBandUser){
            Test.startTest();
            Account acc = [Select Id, name  from Account where name='PED Business Account' Limit 1];   
            Lead leadRecord=new TestLeadBuilder()
                .setBusinessUnit('P')              
                .setProjectName('Test Project')
                .setPedRegion('DOMESTIC')
                .setPedSector('REFINERY')
                .setEndUser('NEW END USER')
                .setNameOfNewEndUser('Test User')
                .setEquipmentName('Test REACTOR')
                .setEquipmentType('REACTOR')
                .setProjectValue(2000)
                .setProjectValue(1000)
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PED_Lead').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setAccountId(acc.Id)
                .setConvertedLeadId(leadRecord.Id)
                .setBusinessUnit('P')
                .setSalesBranchName('1700')
                .setEquipmentName('Test REACTOR')
                .setEquipmentType('REACTOR')
                .setStageName('In Process')
                .setCloseDate(system.today() + 1)
                .setProjectValue(2000)
                .setOpportunityValue(100)
                .setGeographicalLocation('Conducive')
                .setExportControlEndUseCertificate('YES')
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_BQ_OPPORTUNITY_RT).getRecordTypeId())
                .getSavedTestRecord();
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setOpportunityId(oppRecord.id)
                .setExpectedDateOfDelivery(System.today()+30)
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.PED_QUOTE_RT).getRecordTypeId())
                .setExpirationDate(System.today()+30)
                .getSavedTestRecord();
            
             Assert.areNotEqual(null, quoteRecord.Id, 'Quote creation failed');
            
            quoteRecord.Offer_Date__c=System.today();
            quoteRecord.Level_1_Approver__c=pedTBandUser.id;
            quoteRecord.Approval_Status__c=GlobalConstants.Submitted_for_Approval;
            update quoteRecord;
            Test.stopTest();
        }      
    }    
}