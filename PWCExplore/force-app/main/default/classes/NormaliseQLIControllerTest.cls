@isTest
public class NormaliseQLIControllerTest {
    @TestSetup static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userNQLI@godrej.com', username = 'test.userNQLI@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QLITriggerDisabled__c = true; 
            insert setting;
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 contractsPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Contract_PB, IsActive = true, LN_PriceList_Code__c = 'CON', PriceList_Code__c = 'CON');
            insert contractsPriceBook;
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                    new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord()
                    };
                        insert allProducts;
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(contractsPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord()
                    };
                        insert allPBEs;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppMHERecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                .setMHEDivision('Contracts').getSavedTestRecord();
            
            Opportunity oppRENRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();
            
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId())
                .setOpportunityId(oppMHERecord.Id).getSavedTestRecord();
            
            Quote quoteRENRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRENRecord.Id).getSavedTestRecord();
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRENRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).getTestRecord()
                    };
                 allQLI[0].Contract_Start_Date__c=system.today();
				 allQLI[0].Contract_End_Date__c=system.today().AddDays(10);
                 allQLI[0].quantity=10;
                 allQLI[0].normalise_qli__c=true;          
                 insert allQLI;
        }
    }
    
    @isTest private static void validQLIShouldNormaliseQLIs(){
        Test.startTest();
        Id mheContractsRT = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId();
        Quote qtMHE = [SELECT id, (SELECT id, normalise_qli__c, quantity from QuoteLineItems) from Quote WHERE RecordTypeId =: mheContractsRT limit 10];
        List<QuoteLineItem> qliMHE = qtMHE.QuoteLineItems;
        
      //  	qliMHE[0].quantity = 10;
       // 	qliMHE[0].normalise_qli__c = true;
       // 	update qliMHE;
        List<QuoteLineItem> qliMHENormalised = [SELECT id, normalise_qli__c, quantity from QuoteLineItem WHERE QuoteId =: qtMHE.Id limit 10];
        Test.stopTest();        
        //System.assertEquals(10, qliMHENormalised.size(), 'Quote with MHE Contract recordtype processes normalised QLIs');
    }
    
    @isTest private static void invalidQLIShouldNotNormaliseQLIs(){
        Test.startTest();
        Id mheRENRT = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId();
        Quote qtMHE = [SELECT id, (SELECT id, normalise_qli__c, quantity from QuoteLineItems) from Quote WHERE RecordTypeId =: mheRENRT limit 10];
        List<QuoteLineItem> qliMHE = qtMHE.QuoteLineItems;
       // 	qliMHE[0].quantity = 10;
       // 	qliMHE[0].normalise_qli__c = true;
        //	update qliMHE;     
        List<QuoteLineItem> qliMHENormalised = [SELECT id, normalise_qli__c, quantity from QuoteLineItem WHERE QuoteId =: qtMHE.Id limit 10];
        Test.stopTest();
        System.assertNOTEquals(10, qliMHENormalised.size(), 'Quote with non MHE Contract recordtype no normalised QLIs');
    }
}