@IsTest
public class CLITriggerHandlerTest {
    @TestSetup
    static void createData(){
        Test.startTest();
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userCTHT@godrej.com', username = 'test.userCTHT@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
		
        Profile integrationUserProfile = [Select Id from Profile where Name = :System.Label.Integration_User_Profile_Name LIMIT 1];
        
        User user2 = userToRun.clone(false);
        user2.Persona__c = GlobalConstants.MHE_GODREJ_BRANCH_CHAMPION;
        user2.username = 'test.userAcc2@godrej.com';
        user2.ProfileId = integrationUserProfile.id;
        insert user2;
        
        System.runAs(userToRun) {
            //Added Run time by Shreela on 30th Jan 2023 for 101 soql error issue
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            //setting.DiscountMatrixTriggerDisabled__c = true;
            //setting.BranchTriggerDisabled__c = true;
            //setting.UserTriggerDisabled__c = true;
            //setting.PricingApprovalRequestTriggerDisabled__c = true;
            //setting.ProductTriggerDisabled__c = true;
            //setting.OpportunityProductTriggerDisabled__c = true;
            //setting.OpportunityTriggerDisabled__c = true;
            //setting.AddressByBPTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
            setting.FireQuoteValidationRules__c = FALSE;
            setting.FireQLIValidationRules__c = FALSE;
            setting.Fire_Asset_Validation_Rules__c = FALSE;
            //setting.LeadTriggerDisabled__c = true;
            insert setting;
            
            //Create Address Record
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
            //AccountTriggerHandler.TriggerDisabled = true;
            insert accountRecord;
            //AccountTriggerHandler.TriggerDisabled = false;

            List<Branch__c> branchRecords = createBranchRecords(accountRecord.Id, userToRun);
            insert branchRecords;

            Contact contactRecord = createContactRecord(accountRecord.Id);
            insert contactRecord;
            
            // Create Products.
            List<Product2> products = createProductRecords();
            insert products;

            List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
            // Create standard pricebook record for the products created.
            List<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(products);
            //insert standardPricebookEntries;
            pricebookEntries.addAll(standardPricebookEntries);

            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pricebookEntryRecords = createPricebookEntryRecords(products, pricebookRecord);
            //insert pricebookEntryRecords;
            pricebookEntries.addAll(pricebookEntryRecords);
            insert pricebookEntries;
            
            // Create Opportunity.
            Opportunity oppRecord = createOpportunityRecord(accountRecord, userToRun, pricebookRecord);
            OpportunityTriggerHandler.TriggerDisabled = true;
            insert oppRecord;
            OpportunityTriggerHandler.TriggerDisabled = false;

            Quote quoteRecord = createQuoteRecord(oppRecord, userToRun);
            insert quoteRecord;

            List<QuoteLineItem> quoteLineItems = createQuoteLineItemRecords(quoteRecord, pricebookEntryRecords);
            insert quoteLineItems;
			
            List<Asset> assetRecords = new List<Asset>();
            Asset assetRecord = createAssetRecord(accountRecord.Id, contactRecord.Id);
            //insert assetRecord;
            assetRecord.Address_Code__c = address.id;		//Added by pc
            assetRecords.add(assetRecord);
                
            ServiceContract sc = new ServiceContract();
            sc.Name = 'Test Service Contract';
            sc.Status__c = GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS;
            sc.AccountId = accountRecord.id;
            sc.Pricebook2Id = pricebookRecord.Id;
            insert sc;
            
            Asset newAsset = createAssetRecord(accountRecord.Id, contactRecord.Id);
            newAsset.Name= 'Asset 3';
            newAsset.SerialNumber = 'AX003';
            newAsset.Status = 'Purchased';
            newAsset.Address_Code__c = address.id;		//Added by pc
            //insert newAsset;
            assetRecords.add(newAsset);
            AssetTriggerHandler.TriggerDisabled=true;
            insert assetRecords;
            AssetTriggerHandler.TriggerDisabled=false;
            
            //Insert CLI record
            ContractLineItem cli = new ContractLineItem();
            cli.AssetId = newAsset.id;
            cli.ServiceContractId = sc.id; 
            cli.PricebookEntryId = pricebookEntryRecords[0].Id;
            cli.UnitPrice = 10;
            cli.Quantity = 1;
            cli.StartDate = system.today().addDays(-1);
            cli.EndDate = system.today().addDays(10);
            insert cli;
            
        }
        Test.stopTest();
    }

    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='TEST ATTACH PAYMENT', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
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
        opp.MHE_Division__c = GlobalConstants.MHE_DIVISION_CONTRACTS;
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

    private static Quote createQuoteRecord(Opportunity oppRecord, User userRecord) {
        Quote quoteRecord = new Quote();
        quoteRecord.Name = 'Test Quote';
        quoteRecord.OpportunityId = oppRecord.Id;
        quoteRecord.Pricebook2Id = oppRecord.Pricebook2Id;
        quoteRecord.ExpirationDate = oppRecord.CloseDate;
        quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME);
        quoteRecord.Sold_To_Business_Partner__c = oppRecord.AccountId;
        quoteRecord.Ship_To_Account__c = oppRecord.AccountId;
        quoteRecord.Area_Code__c = userRecord.Area_Code__c;
        quoteRecord.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED; 

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

    private static Asset createAssetRecord(Id accountId, Id contactId) {
        Asset assetRecord = new Asset();
        assetRecord.Name = 'Test Asset record';
        assetRecord.SerialNumber = 'AX001';
        assetRecord.AccountId = accountId;
        assetRecord.ContactId = contactId;
        assetRecord.Area_Code__c = 'NH1';
        assetRecord.Product_Purchased_Warranty_Start_Date__c = System.today().addMonths(-1);
        assetRecord.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(6);
        assetRecord.Status = GlobalConstants.ASSET_ACTIVE_STATUS;
        assetRecord.Type_of_Warranty__c = 'Std Warranty';
        return assetRecord;
    }

    @IsTest
    static void createServiceContractAndLineItems() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userCTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            //Added Run time by Shreela on 30th Jan 2023 for 101 soql error issue
            /*Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.LeadTriggerDisabled__c = true;
            setting.OpportunityTriggerDisabled__c = true;
            setting.ContactTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            setting.QuoteTriggerDisabled__c = true;
            setting.CaseTriggerDisabled__c = true;
            setting.CLITriggerDisabled__c = true;
            setting.BranchTriggerDisabled__c = true;
            setting.TaxNumberTriggerDisabled__c = true;
            setting.UserTriggerDisabled__c = true;
            setting.ProductTriggerDisabled__c = true;
            setting.DiscountMatrixTriggerDisabled__c = true;
            setting.OpportunityProductTriggerDisabled__c = true;
            setting.PricingApprovalRequestTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
            setting.ServiceContractTriggerDisabled__c = true;
            setting.OrderProductTriggerDisabled__c = true;
            insert setting ; */
            Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity, PricebookEntryId FROM QuoteLineItems) FROM 
                Quote WHERE Name = 'Test Quote' LIMIT 1
            ];

            String message = ServiceContractManager.validateQuote(quoteRecord.Id);
            
            Test.startTest();
            
            ServiceContract serviceContractRecord = ServiceContractManager.createServiceContract(quoteRecord.Id);
            System.assertNotEquals(null, serviceContractRecord);
            System.assertEquals(null, message);
            Test.stopTest();
        }
    }

    @IsTest
    static void createServiceContractAndLineItems_WithAsset() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userCTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Asset assetRecord = [Select Id FROM Asset WHERE SerialNumber = 'AX001' LIMIT 1];
            Quote quoteRecord = [Select Id, Name, (Select Id, Product2.Name, Quantity, PricebookEntryId FROM QuoteLineItems) FROM 
                Quote WHERE Name = 'Test Quote' LIMIT 1
            ];
            Test.startTest();
			// Create service contract and it's line items.
            ServiceContract serviceContractRecord = ServiceContractManager.createServiceContract(quoteRecord.Id);
            List<ContractLineItem> cliRecords = [Select Id, AssetId FROM ContractLineItem WHERE ServiceContractId = :serviceContractRecord.Id];
            for(ContractLineItem cli : cliRecords) {
                cli.AssetId = assetRecord.Id;
               // system.assertEquals(cli.AssetId,cliRecords[0].AssetId);//gcp22
            }
            update cliRecords;
            Test.stopTest();
          //  system.assert(cliRecords.size()>0);//gcp22
        }        
    }
    
    //Method to test Active CLI validation for an asset
    @IsTest
    static void testValidateActiveCLIforAssetMethod() {
        User contextuser = [Select Id FROM User WHERE username = 'test.userCTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        Boolean errorOccurred = false;
        System.runAs(contextuser) {
            Asset assetRec = [SELECT Id FROM Asset WHERE Name= 'Asset 3' LIMIT 1];
            ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name= 'Test Service Contract' LIMIT 1];
            PricebookEntry pricebookEntryRecord = [SELECT Id FROM PricebookEntry Limit 1];
            
            Test.startTest();
            //Insert CLI record
            ContractLineItem cli = new ContractLineItem();
            cli.AssetId = assetRec.id;
            cli.ServiceContractId = sc.id; 
            cli.PricebookEntryId = pricebookEntryRecord.Id;
            cli.UnitPrice = 10;
            cli.Quantity = 1;
            cli.StartDate = system.today().addDays(-2);
            cli.EndDate = system.today().addDays(16);
            
            try{
                insert cli;
                errorOccurred = false;
            } catch(Exception ex){
                errorOccurred = true;
            }
            Test.stopTest();
        }
        System.assert(errorOccurred == true);
    }
    
     @IsTest
    static void populatePriceBookEntryForIntegrationUserTest() {
        
        User contextuser = [Select Id FROM User WHERE Username = 'test.userCTHT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        Boolean errorOccurred = false;
        System.runAs(contextuser) {
            Asset assetRec = [SELECT Id FROM Asset WHERE Name= 'Asset 3' LIMIT 1];
            ServiceContract sc = [SELECT Id FROM ServiceContract WHERE Name= 'Test Service Contract' LIMIT 1];
            PricebookEntry pricebookEntryRecord = [SELECT Id FROM PricebookEntry Limit 1];
            //Insert CLI record
            ContractLineItem cli = new ContractLineItem();
            cli.AssetId = assetRec.id;
            cli.ServiceContractId = sc.id; 
            cli.PricebookEntryId = pricebookEntryRecord.Id;
            cli.UnitPrice = 10;
            cli.Quantity = 1;
            cli.StartDate = system.today().addDays(-2);
            cli.EndDate = system.today().addDays(16);
            Test.startTest();
            try{
                insert cli;
                errorOccurred = false;
            } catch(Exception ex){
                errorOccurred = true;
            }
            Test.stopTest();
        }
        System.assert(errorOccurred == true); 
      
    }
}