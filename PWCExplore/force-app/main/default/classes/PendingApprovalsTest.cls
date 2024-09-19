@istest
public class PendingApprovalsTest {
    @testsetup
    private static void testData() {
        Profile userAdminProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        User userAdmin = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test1', lastname = 'User1', Alias = 'tuser1',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userAdminProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userAdmin@godrej.com', 
                                  username = 'test.userAdmin@godrej.com',Business_Unit__c = 'K');
        userAdmin.IsActive = true;
        insert userAdmin;
        
        System.runAs(userAdmin) {
                    Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    
                    setting.AccountTriggerDisabled__c = true;
            		setting.OpportunityTriggerDisabled__c = true;
            		setting.ProductTriggerDisabled__c = true;
            		setting.PricingApprovalRequestTriggerDisabled__c = true;
                    insert setting; 
        
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        newAccount.Business_Unit__c = 'K';
        insert newAccount;
        
        // Create Products
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
        
        insert products;
        
        // Create standard pricebook record for the products created.
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();
        
        for(Product2 product : products) {
            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = pricebookId, Product2Id = product.Id,
                UnitPrice = 10000, IsActive = true);
            
            standardPricebookEntries.add(standardPrice);
        }
        insert standardPricebookEntries;
        
        // Create Pricebook.
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                                    Market_Pricelist__c = true);
        insert pricebookRecord;
        
        
        // Create PricebookEntry for the above products and pricebook.        
        List<PricebookEntry> pricebookEntryRecords = new List<PricebookEntry>();
        for(Product2 product : products) {
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = product.Id;
            pbe.Pricebook2Id = pricebookRecord.Id;
            pbe.UnitPrice = 1000.00;
            pbe.IsActive = true;
            pricebookEntryRecords.add(pbe);
        }
        insert pricebookEntryRecords; 
        
        //Create opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'Test Opportunity';
        newOpp.AccountId = newAccount.Id;
        newOpp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'MHE');
        newOpp.Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE;
        newOpp.MHE_Division__c = 'Outright Sales';
        newOpp.CloseDate = (Date.today()).addDays(10);
        newOpp.Sales_Branch_Name__c = userAdmin.Logistic_Company__c;
        newOpp.StageName = 'Qualification';
        insert newOpp;
        Test.startTest();
        //Create Quote   
        Quote quoteRecord = new Quote();
        quoteRecord.Name = 'Test Quote';
        quoteRecord.OpportunityId = newOpp.Id;
        //quoteRecord.Pricebook2Id = newOpp.Pricebook2Id;
        quoteRecord.Pricebook2Id = pricebookRecord.Id;
        quoteRecord.ExpirationDate = newOpp.CloseDate;
        quoteRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Quote', 'MHE_Equipments');
        quoteRecord.Sold_To_Business_Partner__c = newOpp.AccountId;
        quoteRecord.Ship_To_Account__c = newOpp.AccountId;
        quoteRecord.Area_Code__c = userAdmin.Area_Code__c;
        quoteRecord.Transaction_Type__c = GlobalConstants.ORDER_TYPE_PRIMARY;
        insert quoteRecord;
        
        //Create QLIs
        List<QuoteLineItem> quoteLineItemRecords = new List<QuoteLineItem>();
        Integer quantityMultiplier = 1;
        for(PricebookEntry pricebookEntryRecord : pricebookEntryRecords) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = quoteRecord.Id;
            qli.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli.Product2Id = pricebookEntryRecord.Product2Id;
            qli.Quantity = 1 * quantityMultiplier;
            qli.PricebookEntryId = pricebookEntryRecord.Id;
            qli.Sequence__c = 1;
            quoteLineItemRecords.add(qli);
        }
        insert quoteLineItemRecords;
        Test.stopTest();
        Pricing_approval_request__c par = [Select Id from Pricing_approval_request__c limit 1];
        par.Is_Generic_Product__c = true;
        par.MHE_Sales_Manager__c = userAdmin.id;//Added by pankaj on 10th april
        update par;
        System.debug([Select Id,Quote_Record_Type_Developer_Name__c,Quote_Order_Type__c,Is_Generic_Product__c,Sequence__c from Pricing_approval_request__c limit 1]);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments( 'Submitting request for approval' );
        //req1.setObjectId( quoteRecord.id );
        req1.setObjectId(par.Id);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process( req1 );
    }
    }
    
    @istest static void PendingApprovalsMHEtest(){
        User user = [Select Id from User where username='test.userAdmin@godrej.com'];
        System.runAs(user){
            Test.StartTest();
            PendingApprovalsMHE.doInit('test');
            Test.StopTest();
        }
    }
}