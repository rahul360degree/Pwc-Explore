/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test class for CalculateBundledPriceController
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class CalculateBundledPriceControllerTest {
    @TestSetup static void createData(){
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
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
    
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
    
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord(),
                new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').getTestRecord(),
                new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').getTestRecord(),
                new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').getTestRecord()
            };
            insert allProducts;
    
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord()
            };
            insert allPBEs;
    
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
    
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();
    
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

    @isTest private static void invalidQuoteIdShouldAlertUser() {
        String actualErrorMessage;
        Test.startTest();
        try {
            CalculateBundledPriceController.calculateBundledPrices(null);
        } catch (AuraHandledException ex) {
            actualErrorMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(System.Label.Import_Invalid_Quote, actualErrorMessage, 'Method tried to process an invalid quote Id');
    }

    @isTest private static void lineItemWithoutProductTypeShouldAlertUser() {
        Id quoteId = getQuote().Id;
        String actualErrorMessage;
        Product2 baseProduct = [SELECT Id, Name, Component_Type__c FROM Product2 WHERE Name = 'GX 300'];
        baseProduct.Component_Type__c = null;
        update baseProduct;
        Test.startTest();
        try {
            CalculateBundledPriceController.calculateBundledPrices(String.valueOf(quoteId));
        } catch (Exception ex) {
            actualErrorMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(System.Label.Invalid_Product_Type + ' ' + baseProduct.Name, actualErrorMessage, 'Method tried to process a line item without product type');
    }

    @isTest private static void usingProductWithDescriptionShouldUpdateLineItemDescription() {
        Id quoteId = getQuote().Id;
        Product2 baseProduct = [SELECT Id, Description FROM Product2 WHERE Name = 'GX 300'];
        Test.startTest();
        CalculateBundledPriceController.calculateBundledPrices(String.valueOf(quoteId));
        Test.stopTest();
        QuoteLineItem qli = [SELECT Description FROM QuoteLineItem WHERE Product2Id = :baseProduct.Id];
        System.assertEquals(baseProduct.Description, qli.Description, 'Description wasn\'t copied to line items');
    }

    @isTest private static void usingFractionsInTotalQuantityShouldAlertUser() {
        //create custom setting -Added next three lines by Shreela on 17th Oct 2022 for resolving 101 error issues
        /*Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.QuoteTriggerDisabled__c = true;
        insert setting;*/
        
        Id quoteId = getQuote().Id;
        String actualErrorMessage;
        QuoteLineItem qli = [SELECT Id, Quantity FROM QuoteLineItem WHERE Component_Type__c = 'Base Product'];
        qli.Quantity = 1.5;
        update qli;
        Test.startTest();
        try {
            CalculateBundledPriceController.calculateBundledPrices(quoteId);
        } catch (Exception ex) {
            actualErrorMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(System.Label.Invalid_Quantity, actualErrorMessage, 'Quantity with fractions didn\'t alert user');
    }

    @isTest private static void usingSequenceWithoutBaseProductShouldAlertUser() {
        Id quoteId = getQuote().Id;
        String actualErrorMessage;
        QuoteLineItem qli = [SELECT Id, Sequence_Number__c FROM QuoteLineItem WHERE Component_Type__c = 'Base Product'];
        qli.Sequence_Number__c = 2;
        update qli;
        Test.startTest();
        try {
            CalculateBundledPriceController.calculateBundledPrices(quoteId);
        } catch (Exception ex) {
            actualErrorMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(System.Label.No_Base_Product + ' ' + 1, actualErrorMessage, 'Quote without base product didn\'t alert user');
    }

  /*  @isTest private static void usingSequenceWithMultipleBaseProductsShouldAlertUser() {
        Quote quoteRecord = getQuote();
        String actualErrorMessage;
        Product2 newProduct = new TestProductBuilder().setName('GX 300 D').setDescription('GX 300 D Forklift').setItemCode('GX300D').setComponentType('Base Product').getSavedTestRecord();
        PriceBookEntry newPBE = new TestPriceBookEntryBuilder().setProduct2Id(newProduct.Id).setPricebook2Id(quoteRecord.PriceBook2Id).setUnitPrice(50000).getSavedTestRecord();
        QuoteLineItem qli = new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(40000).setSequenceNumber(1).setPriceBookEntryId(newPBE.Id).getSavedTestRecord();
        Test.startTest();
        try {
            CalculateBundledPriceController.calculateBundledPrices(quoteRecord.Id);
        } catch (Exception ex) {
            actualErrorMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(System.Label.Multiple_Base_Products + ' ' + 1, actualErrorMessage, 'Quote with multiple base products didn\'t alert user');
    } */

    @isTest private static void pricePerEquipmentShouldRollUpToBaseProductInSequence() {
        Id quoteId = getQuote().Id;
        Test.startTest();
        CalculateBundledPriceController.calculateBundledPrices(quoteId);
        Test.stopTest();
        QuoteLineItem baseQLi, otherQLI;
        for (QuoteLineItem each : [SELECT Id, Price_per_Equipment__c, Component_Type__c FROM QuoteLineItem WHERE QuoteId = :quoteId AND Component_Type__c IN ('Base Product', 'Attachments')]) {
            if (each.Component_Type__c == 'Base Product') {
                baseQLI = each;
            } else {
                otherQLI = each;
            }
        }
        System.assertEquals(147000, baseQLI.Price_per_Equipment__c, 'Price did not roll up to base product');
        System.assertEquals(null, otherQLI.Price_per_Equipment__c, 'Price per equipment set for non-base product');
    }
/*
    @isTest private static void productsWithoutSequenceShouldHavePricePerEquipment() {
        Id quoteId = getQuote().Id;
        CalculateBundledPriceController.calculateBundledPrices(quoteId);
        QuoteLineItem qli = [SELECT Id, Price_per_Equipment__c, Sequence_Number__c FROM QuoteLineItem WHERE Component_Type__c = 'Attachments'];
        System.assertEquals(null, qli.Price_per_Equipment__c, 'Attachment with sequence has price');
        qli.Sequence_Number__c = null;
        update qli;
        Test.startTest();
        CalculateBundledPriceController.calculateBundledPrices(quoteId);
        Test.stopTest();
        qli = [SELECT Id, Price_per_Equipment__c FROM QuoteLineItem WHERE Component_Type__c = 'Attachments'];
        System.assertEquals(3000, qli.Price_per_Equipment__c, 'Attachment without sequence doesn\'t have price');
    }

    @isTest private static void updatingProductSequenceShouldRefreshPricePerEquipment() {
        Id quoteId = getQuote().Id;
        CalculateBundledPriceController.calculateBundledPrices(quoteId);
        QuoteLineItem baseQLi, otherQLI;
        for (QuoteLineItem each : [SELECT Id, Price_per_Equipment__c, Component_Type__c FROM QuoteLineItem WHERE QuoteId = :quoteId AND Component_Type__c IN ('Base Product', 'Attachments')]) {
            if (each.Component_Type__c == 'Base Product') {
                baseQLI = each;
            } else {
                otherQLI = each;
            }
        }
        System.assertEquals(147000, baseQLI.Price_per_Equipment__c, 'Price did not roll up to base product');
        otherQLI.Sequence_Number__c = null;
        update otherQLI;
        Test.startTest();
        CalculateBundledPriceController.calculateBundledPrices(quoteId);
        Test.stopTest();
        baseQLI = [SELECT Id, Price_per_Equipment__c FROM QuoteLineItem WHERE Id = :baseQLI.Id];
        System.assertEquals(144000, baseQLI.Price_per_Equipment__c, 'Price did not refresh after sequence update');
    }
*/
    private static Quote getQuote() {
        return [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
    }
}