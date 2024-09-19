/*------------------------------------------------------------------------
Author:        Anupam Mishra
Description:   Test class for AttachQuotationController and QuotationController Class
Date       :   05-06-2022
----------------------------------------------------------------------------*/
@isTest
private class AttachQuotationControllerTest {
    
    @TestSetup
    static void prepareData(){
           Runtime_Execution__c csdata = new Runtime_Execution__c ();
        csdata.AddressByBPTriggerDisabled__c = true;
        csdata.UserTriggerDisabled__c  = true;
        csdata.ProductTriggerDisabled__c  = true;    
        csdata.ZipCodeRuleTriggerDisabled__c  = true;    
        csdata.AssetTriggerDisabled__c = true;
        csdata.OpportunityProductTriggerDisabled__c = true;
        csdata.OpportunityTriggerDisabled__c = true;
        csdata.BranchTriggerDisabled__c=true;
        csdata.QuoteTriggerDisabled__c=true;
        csdata.QLITriggerDisabled__c=true;
        //csdata.FireAccountValidationRules__c = false;
        insert   csdata;
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT);
        
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
            
            Account accConsM = new Account(Name='Construction Business Account',Primary_Address__c = address.Id,Business_Unit__c='N',Industry='Manufacturing', Account_Code__c='XYZ',Construction_LOB__c = 'RMC',Type='E',
                                           RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
            accList.add(accConsM);
            // insert accountRecords;
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
            
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            insert oppRecord;
            
            Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B',Building__c='Raevenues');
            insert firstaddress;
            
            
            Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id, Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, Ship_To__c = TRUE, Sold_To__c  = TRUE,Integration_Status__c ='Synced');
            insert firstAddressByBp;
            
            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun,firstAddressByBp);
            insert quoteRecord;
            
            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pricebookEntryRecords);
            insert quoteLineItems;
            
            
        }
    }
    
    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment'.toUpperCase(), Industry='Apparel', Type='I', Account_Code__c='TPA',Construction_LOB__c = 'RMC');
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
        opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'Construction_Materials');
        opp.Pricebook2Id = pricebookRecord.Id;
        opp.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT ;
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
                                                    IsActive = true, Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT, 
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
        user salesRep =[select Id  from User limit 1];
        Quote quoteRecord = new Quote();
        quoteRecord.Name = 'Test Quote';
        quoteRecord.OpportunityId = oppRecord.Id;
        quoteRecord.Internal_Sales_Representative__c = salesRep.Id;
        quoteRecord.Pricebook2Id = oppRecord.Pricebook2Id;
        quoteRecord.ExpirationDate = oppRecord.CloseDate;
        quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'Construction_Materials');
        quoteRecord.Sold_To_Business_Partner__c = oppRecord.AccountId;
        quoteRecord.Ship_To_Address__c = address.Id;
        quoteRecord.Sold_to_Address__c = address.Id;
        quoteRecord.Ship_To_Account__c = oppRecord.AccountId;
        quoteRecord.Area_Code__c = userRecord.Area_Code__c;
        quoteRecord.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
        quoteRecord.LOB_N__c = 'WPS';               
        
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
    
    @isTest private static void createAttachmentRecordtest(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote where LOB_N__c = 'WPS' LIMIT 1];
        Test.startTest();
        AttachQuotationController.createAttachmentRecord(quoteRecord.id);
        Test.stopTest();
    }
    
    @isTest private static void createAttachmentRecordtest2(){
        try{
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote where LOB_N__c = 'WPS' LIMIT 1];
        quoteRecord.Internal_Sales_Representative__c = null;
        update quoteRecord;
        Test.startTest();
        AttachQuotationController.createAttachmentRecord(quoteRecord.id);
        Test.stopTest();
        }
        catch(Exception e){
		} 
    }
    
    @isTest private static void createAttachmentRecordtest3(){
        try{
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote where LOB_N__c = 'WPS' LIMIT 1];
        quoteRecord.LOB_N__c='RMC';
        quoteRecord.Pumping_charges_per_cuM__c = null;
        update quoteRecord;
        Test.startTest();
        AttachQuotationController.createAttachmentRecord(quoteRecord.id);
        Test.stopTest();
        }
        catch(Exception e){
		} 
    }
    
    @isTest private static void testgeneratePDF(){
        Quote quoteRecord = [SELECT Id,LOB_N__c,QuoteNumber, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        Product2 product = [Select Id from Product2 limit 1];
        product.Product_Category__c = 'WPS';
        product.Commodity_Set__c = 'R12V';
        product.Volume__c = 36.23;
        update product;   
        Blob bodyBlob=Blob.valueOf('Dummy Body'); 
        
        ContentVersion contentVersion = new ContentVersion(
            Title='Payment', 
            PathOnClient ='SampleTitle.pdf',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        
        insert contentVersion;
        
        contentVersion = [SELECT Id, Title, ContentDocumentId 
                          FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId =quoteRecord.id;
        contentlink.contentdocumentid = contentVersion.contentdocumentid;
        contentlink.ShareType = 'V';
        
        insert contentlink;
        AttachQuotationController.generatePDF('Test',quoteRecord.Id,quoteRecord);
        Test.stopTest();
    }
    

    
    @isTest private static void testQuotationControllerIf(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        quoteRecord.Special_Remarks__c ='Test';
        quoteRecord.Payment_Terms_more_Information__c='Test'; 
        update quoteRecord;
        PageReference pageRef = Page.construction_AAC_quotation;  
        pageRef.getParameters().put('id', String.valueOf(quoteRecord.Id));
        Test.setCurrentPage(pageRef);
        QuotationController Quotc = new QuotationController();
        Quotc.Address = new Address__c();
        Test.stopTest();
    }
    
        @isTest private static void testQuotationControllerelse(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        PageReference pageRef = Page.construction_AAC_quotation;  
        pageRef.getParameters().put('id', String.valueOf(quoteRecord.Id));
        Test.setCurrentPage(pageRef);
        QuotationController Quotc = new QuotationController();
        Test.stopTest();
    }
}