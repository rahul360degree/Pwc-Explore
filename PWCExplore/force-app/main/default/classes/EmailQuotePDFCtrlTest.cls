/*------------------------------------------------------------------------------------
* Author        :        Sumit
* Company       :        Salesforce
* Description   :        Test class for EmailQuotePDFCtrl
* Inputs        :        
* Test Class    :    
* History
* --------
* 09-07-2020      Sumit Swami     Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class EmailQuotePDFCtrlTest {
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
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
        }
    }
    
    @isTest private static void generateQuotePDFShouldInsertQuoteTemplateStdUser(){
        Id quoteId = getQuote().Id;
        
        Test.startTest();
        EmailQuotePDFCtrl.generateQuotePDF(String.valueOf(quoteId),'templateid');
        Test.stopTest();
        
        List<QuoteDocument> qdList = [Select id from QuoteDocument Limit 1];
        List<ContentDocument> cdList = [Select id from ContentDocument Limit 1];
        System.assertNotEquals(qdList.size(), 0, 'Quote Document has been generated');
        System.assertNotEquals(cdList.size(), 0, 'Content Document has been generated');
    }
    
    @isTest private static void generateQuotePDFShouldInsertQuoteTemplatePortalUser(){
        
        User pu = new TestUserBuilder().getPartnerUser();
        Id quoteId = getQuote().Id;
        Test.startTest();
        system.runAs(pu){
            EmailQuotePDFCtrl.generateQuotePDF(String.valueOf(quoteId),'templateid');
        }
        Test.stopTest();
        
        List<QuoteDocument> qdList = [Select id from QuoteDocument Limit 1];
        List<ContentDocument> cdList = [Select id from ContentDocument Limit 1];
        System.assertEquals(qdList.size(), 0, 'Quote Document has been generated');
        System.assertEquals(cdList.size(), 0, 'Content Document has been generated');
        
    }
    
    @isTest private static void getQuoteTemplateIdsShouldReturnTemplateIdWrapper(){
        Id quoteId = getQuote().Id;
        
        Test.startTest();
        List<EmailQuotePDFCtrl.ValueWrapper> templateWrapper = EmailQuotePDFCtrl.getQuoteTemplateIds(String.valueOf(quoteId));
        Test.stopTest();
        
        System.assertNotEquals(templateWrapper.size(), 0, 'Template Wrapper has been generated');
        
    }
    
    private static Quote getQuote() {
        return [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
    }
}