////******************************************************************************************************
/**
* @Author            : Ashwin Thale
* @class name  : BatchLocksB2BQuotesExpRemTest.apxc
* @description  : This is a Test Class for BatchLocksB2BQuotesExpirationReminder.apxc
* @created date  : 06-11-2023
* @last modified on  : 06-11-2023
* @last modified by  : Ashwin Thale
* Modifications Log	 :
* Ver   Date         Author          Modification
* 1.0   31-10-2023   Ashwin Thale   Initial Version
**/
////******************************************************************************************************
@isTest
public with sharing class BatchLocksB2BQuotesExpRemTest {

    @TestSetup 
    public static void testDataMethod(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        User managerToRun = createManagerData(userProfile);
        User userToRun = createUserData(userProfile,managerToRun);
        
        System.runAs(userToRun) {
            
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.QuoteTriggerDisabled__c = true;
        insert setting;
            
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;
            
        PriceBook2 rentalPriceBook = new PriceBook2(Name = 'LC2_3000 / LOCKS B2B', IsActive = true, LN_PriceList_Code__c = 'LC2', PriceList_Code__c = 'LC2_3000', Business_Unit__c = 'L');
        insert rentalPriceBook;
            
        List<Product2> allProducts = createProductData();
        List<PriceBookEntry> allPBEs = createPricebookData(allProducts,rentalPriceBook);
            
        Account acc = new TestAccountBuilder()
        .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
        .getSavedTestRecord();
            
        Opportunity opp = createOpportunityData(acc,rentalPriceBook);
        createQuoteData(opp,rentalPriceBook,allPBEs);
            
        }
    }
    //This method is used to create Manager User Data.
    public static User createManagerData(Profile userProfile){
        User managerToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test Manager B2B', lastname = 'Locks B2B', Alias = 'tmangB2B', Persona__c = 'Locks-BDE', Logistic_Company__c = '2000', IsActive = TRUE, 
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, Sub_Division__c = GlobalConstants.B2B_SUBDIVISION, Area_Code__c = 'WN1', 
                                  timezonesidkey = 'Asia/Kolkata', email = 'checkB2BLocksManagers@godrej.com', username = 'testB2B01112300.manager@godrej.com', Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT);
        insert managerToRun;
        return managerToRun;
    }
    //This method is used to create User Data.
    public static User createUserData(Profile userProfile, User managerToRun){
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test User B2B', lastname = 'Locks B2B', Alias = 'tuserB2B', Persona__c = 'Locks-BDE', Logistic_Company__c = '2000', IsActive = TRUE, 
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, Sub_Division__c = GlobalConstants.B2B_SUBDIVISION, Area_Code__c = 'WN1', ManagerId = managerToRun.Id, 
                                  timezonesidkey = 'Asia/Kolkata', email = 'checkB2BLocksUsers@godrej.com', username = 'testB2B01112300.user@godrej.com', Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT);
        insert userToRun;
        return userToRun;
    }
    //This method is used to create Product Data.
    public static List<Product2> createProductData(){
        List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                    new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord(),
                    new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').getTestRecord(),
                    new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').getTestRecord(),
                    new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').getTestRecord()
                    };
        insert allProducts;
        return allProducts;
    }
    //This method is used to create Pricebook Entry Data.
    public static List<PriceBookEntry> createPricebookData(List<Product2> allProducts,PriceBook2 rentalPriceBook){
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord()
                    };
        insert allPBEs;
        return allPBEs;
    }
    //This method is used to create Opportunity Data.
    public static Opportunity createOpportunityData(Account acc,PriceBook2 rentalPriceBook){
        Opportunity opp = new Opportunity(Name = 'Test Opportunity - B2B', StageName = 'Qualification');
			opp.CloseDate = (Date.today()).addMonths(10);
			opp.Segment__c = 'FMCG';                    
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId();
            opp.Pricebook2Id = rentalPriceBook.Id;
            opp.Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT;
            opp.Sub_Division__c = 'B2B';
            opp.LocksSegment__c='OEM';
            opp.Sub_segment__c = 'Wooden Door OEM';
        	opp.Dealer_Name__c = acc.id;
            opp.AccountId = acc.id; 
            opp.Project_Details__c = 'Test';
            opp.OEM__c = acc.Id;
        insert opp;
        return opp;
    }
	//This method is used to create Quote Data.
    public static void createQuoteData(Opportunity opp,PriceBook2 rentalPriceBook,List<PriceBookEntry> allPBEs){
        Quote quoteRecord = new Quote();
            quoteRecord.OpportunityId = opp.Id;
            quoteRecord.Pricebook2Id = rentalPriceBook.Id;
            quoteRecord.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId();
            quoteRecord.Name = 'SSD Quote Test';
            quoteRecord.Agreed_by_customer__c = TRUE;
            quoteRecord.Delivery_Type__c = 'Branch Billing';
            quoteRecord.ExpirationDate = System.Today();
            insert quoteRecord;
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(30000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[2].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[3].Id).getTestRecord(),
                    new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[4].Id).getTestRecord()
                    };
          insert allQLI;
    }

    @isTest
    public static void testSchedulable() {
        BatchLocksB2BQuotesExpirationReminder scheduler = new BatchLocksB2BQuotesExpirationReminder();
        String cronExpression = '0 0 0 15 3 ? 2024'; 
        System.schedule('MyTestJob', cronExpression, scheduler);
    }
    @isTest
    public static void testBatch() {
        BatchLocksB2BQuotesExpirationReminder batch = new BatchLocksB2BQuotesExpirationReminder();
        Database.executeBatch(batch);
    }
}