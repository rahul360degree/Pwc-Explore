/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Test Class for CustomQuoteSyncController

History
13-07-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class CustomQuoteSyncControllerTest {
    
    @TestSetup static void createData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').setProductCode('GX1F').getTestRecord(),
                    new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').setProductCode('GX300A').getTestRecord(),
                    new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').setProductCode('Op1').getTestRecord(),
                    new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').setProductCode('Tc1').getTestRecord(),
                    new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').setProductCode('Su1').getTestRecord(),
                    new TestProductBuilder().setName('Modern GX 300').setDescription('GX 300 Forklift').setItemCode('GX11').setComponentType('Base Product').getTestRecord()
                    };
                        insert allProducts;
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[5].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(2200000).getTestRecord()
                    };
                        insert allPBEs;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
            update accountRecord;
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecord.Id).getSavedTestRecord();
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(30000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[2].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[3].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[4].Id).getTestRecord()
            };
            insert allQLI;
        }
    }
    
    //Calling startSyncWithQuote with a valid Quote Id should populate
    //SyncedQuoteId on related Opportunity
    @isTest private static void startSyncWithQuoteShouldTagSyncedQuoteId() {
        List<Quote> quoteList = new List<Quote>([Select Id, OpportunityId, Opportunity.SyncedQuoteId from Quote]);
        if(!quoteList.isEmpty() && (quoteList[0].Opportunity.SyncedQuoteId == NULL)) {
            Test.startTest();
            CustomQuoteSyncController.startSyncWithQuote(quoteList[0].id);
            Test.stopTest();
            Quote revisedQuote = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteList[0].id];
            System.assertEquals(quoteList[0].id, revisedQuote.Opportunity.SyncedQuoteId, 'Quote Id should be tagged on Opportunity SyncedQuoteId');
            
        }
    }
    
  /*  
    //Calling stopSyncWithQuote with a valid Quote Id should remove
    //SyncedQuoteId on related Opportunity
    @isTest private static void stopSyncWithQuoteShouldRemoveSyncedQuoteId() {
        List<Quote> quoteList = new List<Quote>([Select Id, OpportunityId, Opportunity.SyncedQuoteId from Quote]);
        if(!quoteList.isEmpty() && (quoteList[0].Opportunity.SyncedQuoteId == NULL)) {
            CustomQuoteSyncController.startSyncWithQuote(quoteList[0].id);
            
            Test.startTest();
            CustomQuoteSyncController.stopSyncWithQuote(quoteList[0].id);
            Test.stopTest();
            
            Quote revisedQuote = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteList[0].id];
            System.assertEquals(NULL, revisedQuote.Opportunity.SyncedQuoteId, 'Quote Id should be removed on Opportunity SyncedQuoteId');
            
        }
    }
    */
    
    //Calling stopSyncWithQuote with a invalid Quote Id should not remove
    //SyncedQuoteId on related Opportunity
    @isTest private static void stopSyncWithUnsyncedQuoteShouldNotRemoveSyncedQuoteId() {
        List<Quote> quoteList = new List<Quote>([Select Id, OpportunityId, Opportunity.SyncedQuoteId from Quote]);
        if(!quoteList.isEmpty() && (quoteList[0].Opportunity.SyncedQuoteId == NULL)) {
            Test.startTest();
            CustomQuoteSyncController.startSyncWithQuote(quoteList[0].id);
            Quote revisedQuote1 = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteList[0].id];
            
            System.assertEquals(quoteList[0].id, revisedQuote1.Opportunity.SyncedQuoteId, 'Quote Id should be tagged on Opportunity SyncedQuoteId');
            
            //Creating another quote for the same opportunity
            Quote quoteRecord2 = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(quoteList[0].OpportunityId).getSavedTestRecord();
            
            
            
            CustomQuoteSyncController.stopSyncWithQuote(quoteRecord2.Id);
            Test.stopTest();
            
            Quote revisedQuote2 = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteRecord2.Id];
            System.assertNotEquals(NULL, revisedQuote2.Opportunity.SyncedQuoteId, 'Quote Id should be NOT be removed on Opportunity SyncedQuoteId for unsynced Quote');
            
        }
    }
    
    //Calling startSyncWithQuote with a another Quote Id should tag
    //SyncedQuoteId on related Opportunity with the provided quoteId
    @isTest private static void startSyncWithAnotherQuoteShouldTagSyncedQuoteId() {
        List<Quote> quoteList = new List<Quote>([Select Id, OpportunityId, Opportunity.SyncedQuoteId from Quote]);
        if(!quoteList.isEmpty() && (quoteList[0].Opportunity.SyncedQuoteId == NULL)) {
            Test.startTest();
            CustomQuoteSyncController.startSyncWithQuote(quoteList[0].id);
            Quote revisedQuote1 = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteList[0].id];
            
            System.assertEquals(quoteList[0].id, revisedQuote1.Opportunity.SyncedQuoteId, 'Quote 1 : Id should be tagged on Opportunity SyncedQuoteId');
            
            //Creating another quote for the same opportunity
            Quote quoteRecord2 = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(quoteList[0].OpportunityId).getSavedTestRecord();
            
            
            
            CustomQuoteSyncController.startSyncWithQuote(quoteRecord2.Id);
            Test.stopTest();
            
            Quote revisedQuote2 = [Select Id, Opportunity.SyncedQuoteId From Quote where Id = :quoteRecord2.Id];
            System.assertEquals(revisedQuote2.Id, revisedQuote2.Opportunity.SyncedQuoteId, 'Quote 2: Id should be be tagged on Opportunity SyncedQuoteId for a different Quote');
            
        }
    }
}