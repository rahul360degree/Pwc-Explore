@isTest
public class SyncQuoteCustomFieldTest {
     @istest
   public static void quoteLineItemShouldSyncWithOpportunityLineItem(){
        list<Account> accounts = new list<Account>();
        list<Opportunity> Opportunities = new list<Opportunity>();
        list<Quote> quotes = new list<Quote>();
        
        //Interio - VFD Dealer user
        User userToRun = createUserRecord(null, '', 'InterioVFD- Dealer', GlobalConstants.INTERIO_BUSINESS_UNIT);
        
        System.runAs(userToRun) {
            // Create Products.
            Product2 product = createProductRecords();
            product.Product_Storage_Clasification__c='Category A';
            
                
            // Create standard pricebook record for the products created.
            PricebookEntry standardPricebookEntry = createStandardPricebookEntries(product);
          //  insert standardPricebookEntry; 
                
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
           // insert pricebookRecord;
                
            // Create PricebookEntry for the above products and pricebook.
            PricebookEntry pricebookEntryRecord = createPricebookEntryRecords(product, pricebookRecord);
        //    insert pricebookEntryRecord;
       
       
       
    
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getTestRecord();
            accounts.add(accountRecord);
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('W').getTestRecord();
                oppRecord.Name = 'VFD Opp';
            Opportunities.add(oppRecord);
            
            insert Opportunities;
            
            OpportunityLineItem oppProduct=new OpportunityLineItem();
            oppProduct.OpportunityId=Opportunities[0].Id;
            oppProduct.PriceBookEntryId=pricebookEntryRecord.Id;
            insert oppProduct; 

 //Create Interio B2C VFD Quote
            Test.startTest();
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getTestRecord();
            quotes.add(quoteRecord);
            
            insert quotes;
            
            quoteRecord.Pricebook2Id=pricebookRecord.Id;
            Update quoteRecord;
             
             QuoteLineItem qli=new QuoteLineItem();
            qli.QuoteId=quotes[0].Id;
            qli.OpportunityLineItemId=oppProduct.Id;
            qli.PricebookEntryId=pricebookEntryRecord.Id;
            qli.Quantity=2;
            qli.UnitPrice=3000;
            Insert qli;
          /*  QuoteLineItem lineItem=[Select id,Opportunity_Line_Item_ID__c,Number_Of_Shifts__c from quoteLineItem Limit 1];
            lineItem.Number_Of_Shifts__c=5;
            Update lineItem; */
            List<OpportunityLineItem> oppLineItems=[Select Id From OpportunityLineItem Where Number_Of_Shifts__c=5];
        //    System.assertEquals(1,oppLineItems.Size());  
                              
        }
        Test.stopTest();
    }
    
    
    
    
    
    private static Product2 createProductRecords() {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='DTWHAA';
        baseproduct1.Is_Generic_Product__c=true;
        insert baseproduct1;
        return baseproduct1;
    }
    
    private static PricebookEntry createStandardPricebookEntries(Product2 product) {
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = product.Id,
            UnitPrice = 10000, IsActive = true);
            insert standardPriceEntry;

        return standardPriceEntry;
    }

    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'test price book 1', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true
                                    );
        insert pricebookRecord;
                         
        return pricebookRecord;
    }

    private static PricebookEntry createPricebookEntryRecords(Product2 product, Pricebook2 pricebook) {
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = product.Id;
            pbe.Pricebook2Id = pricebook.Id;
            pbe.UnitPrice = 1000.00;
            pbe.IsActive = true;
            insert pbe;

        return pbe;
    }
    
    private static user createUserRecord(Id managerUserId, String userNameAddOnString, String persona, String BU){
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.user17@godrej.com');
        
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.ManagerId = managerUserId;
        userRec.Persona__c = persona;
        userRec.username = 'test.user18@godrej.com';
        userRec.Business_Unit__c = BU;
        userRec.IsActive = true;
        
        if(String.isNotBlank(userNameAddOnString))
            userRec.username = 'test.user18@godrej.com.'+userNameAddOnString;
        
        insert userRec;
        
        return userRec;
    }
}