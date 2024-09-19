/*------------------------------------------------------------------------------------
 * Author        :        Sumit
 * Company       :        Salesforce
 * Description   :        Test class for ImportQuoteLineItemsController
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 09-07-2020      Sumit Swami     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class ImportQuoteLineItemsControllerTest {
    @TestSetup static void createData(){
        User userWithRole = new User(UserRoleId = UserInfo.getUserRoleId(), ProfileId = UserInfo.getProfileId(), 
                                     Alias = 'hasrole', Email='userwithrole1@godrej.com',
                                     EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                     TimeZoneSidKey='America/Los_Angeles',Username = 'test123456_gnbtest@godrej.com',CommunityNickname = 'test12345',
                                     Logistic_Company__c='5010',Business_Unit__c='K',Sub_Division__c='B2B',Salary_Code__c='377990',Business_Partner_Code__c='WWC000021'); 
        
        insert userWithRole;
        
        System.runAs(userWithRole){
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'MHE Lead Manager User' LIMIT 1];

            UserRole ur = new UserRole(Name = 'MHE Lead Manager HO');
            insert ur;
            
            User mheUserWithRole = new User(UserRoleId = ur.Id, ProfileId = profileId.Id, 
                                         Alias = 'hasrole', Email='userwithrole@godrej.com',
                                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                         TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test123456',
                                         Logistic_Company__c='5010',Business_Unit__c='K',Sub_Division__c='B2B',Salary_Code__c='377997',Business_Partner_Code__c='WWC000021'); 
            insert mheUserWithRole;
            
        }
        User mheUser = [Select Id FROM User WHERE UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        System.runAs(mheUser){
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
            List<PriceBookEntry> pbes = [Select Id FROM PriceBookEntry];
            
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

    @isTest private static void invalidQuoteIdfetchQuotesShouldAlertUser() {
        User usr = [Select Id From User where UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        String actualErrorMessage;
        Test.startTest();
        System.runAs(usr){
        	try {
                ImportQuoteLineItemsController.fetchQuotes(null);
            } catch (AuraHandledException ex) {
                actualErrorMessage = ex.getMessage();
            }    
        }        
        Test.stopTest();
        System.assertEquals(System.Label.Import_Invalid_Quote, actualErrorMessage, 'Method tried to process an invalid quote Id');
    }
    
    @isTest private static void invalidQuoteIdfetchQuoteLineItemsShouldAlertUser() {
        User usr = [Select Id From User where UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        String actualErrorMessage;
        Test.startTest();
        System.runAs(usr){
        	try {
                ImportQuoteLineItemsController.fetchQuoteLineItems(null);
            } catch (AuraHandledException ex) {
                actualErrorMessage = ex.getMessage();
            }    
        }        
        Test.stopTest();
        System.assertEquals(System.Label.Import_Invalid_Quote, actualErrorMessage, 'Method tried to process an invalid quote Id');
    }
    
    @isTest private static void fetchQuotesShouldcreateQuoteList() {
        User usr = [Select Id From User where UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        String actualErrorMessage;
        Test.startTest();
        System.runAs(usr){
          Id quoteId = getQuote().Id;
            Opportunity oppRecord = [SELECT Id FROM Opportunity LIMIT 1];
            Quote quoteRecordTarget = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
           	List<Quote> quoteList = ImportQuoteLineItemsController.fetchQuotes(quoteRecordTarget.Id); 
			System.assertNotEquals(quoteList.size(), 0, 'Quotes related to the parent Opportunity should be added to this list');              
        }  
        Test.stopTest();
    }
    
    @isTest private static void fetchQuoteLineItemsShouldcreateQuoteLineList() {
        User usr = [Select Id From User where UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        String actualErrorMessage;
        Test.startTest();
        System.runAs(usr){
        	Id quoteId = getQuote().Id;
        	List<QuoteLineItem> qliList = ImportQuoteLineItemsController.fetchQuoteLineItems(String.valueOf(quoteId));
          	System.assertNotEquals(qliList.size(), 0, 'Quote Lines related to the parent Quote should be added to this list');
        }
        Test.stopTest();
    }
    
    @isTest private static void importQLIRecordsShouldCloneQLIstoTargetQuote() {
        User usr = [Select Id From User where UserName = 'test12345_gnbtest@godrej.com' LIMIT 1];
        String actualErrorMessage;
        Test.startTest();
        System.runAs(usr){
          	Id quoteId = getQuote().Id;
            Opportunity oppRecord = [SELECT Id FROM Opportunity LIMIT 1];
            
            Quote quoteRecordTarget = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
            
            List<QuoteLineItem> qliListPreProcess = [Select id from QuoteLineItem WHERE QuoteId =: quoteRecordTarget.id];
            System.assertEquals(qliListPreProcess.size(), 0, 'Quote Lines have not yet been cloned to target Quote');
            
            List<QuoteLineItem> qliList = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId =:String.valueOf(quoteId)];
            ImportQuoteLineItemsController.importQLIRecords(qliList,quoteRecordTarget.Id);  
                
            List<QuoteLineItem> qliListPostProcess = [Select id from QuoteLineItem WHERE QuoteId =: quoteRecordTarget.id];
            
            System.assertNotEquals(qliListPostProcess.size(), 0, 'Quote Lines have been cloned to target Quote');
        }   
        Test.stopTest();        
    }
    
    private static Quote getQuote() {
        return [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
    }
}