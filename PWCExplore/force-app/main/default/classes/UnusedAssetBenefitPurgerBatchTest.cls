/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for UnusedAssetBenefitPurgerBatch
Inputs:            

----------------------------------------------------------------------------*/
@isTest
public class UnusedAssetBenefitPurgerBatchTest {
    
    @testsetup
    private static void testData() {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
  
            insert setting ;
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'UnusedAssetBenefitPurgerBatchSize', 
                                                                            Batch_Size__c = 100);
        insert abc;
        
        //Create Plan Record
        Plan__c goldPlan = new Plan__c();
        goldPlan.Name = 'Gold';
        goldPlan.BD_Visits_Number__c = 4; 
        goldPlan.Scheduled_PM_Visits_Number__c =5;
        goldPlan.Plan_Type__c = 'Basic';
        goldPlan.Is_Active__c = true;
        goldPlan.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
         
        insert goldPlan;
        
        
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.Account_Code__c = 'Test';
        newAccount.Business_Unit__c='K';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        insert newAccount;
        
        //Create Address Record					//Added by pc 
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
        address.Street__c = '2nd street';
            insert address;
        
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Address_Code__c = address.id;		//Added by pc
        newAsset.Status = 'Unregistered';
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Product_Purchased_Warranty_Start_Date__c= Datetime.parse('11/6/2020, 10:36 AM');
        newAsset.Product_Purchased_Warranty_End_Date__c=Date.newInstance(2021,6,11);
        insert newAsset;
        
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
    
        PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
        insert rentalPriceBook;
        
        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord()
        };
        insert allProducts;
        
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord()
        };
        insert allPBEs;
        
        Opportunity oppRecord = new TestOpportunityBuilder()
            .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
            .setStageName('Closed won')
            .setName('Test Oppty')
            .setOEFStatus('OEF - Sanctioned')
            .setPONumber('PO-1234')
            .setAccountId(newAccount.id)
            .setBusinessUnit('k')
            .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();

        
        Quote quoteRecord = new TestQuoteBuilder()
            .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
            .setOpportunityId(oppRecord.Id).getSavedTestRecord();
        
        List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
            new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).setAssetId(newAsset.Id).getTestRecord()
        };
        insert allQLI;
        
        //Create Asset Benefit record
        Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
        newAssetBenefit.Name= 'Gold';
        newAssetBenefit.Quote_Line_Item__c = allQLI[0].Id;
        newAssetBenefit.Is_Active__c = true; 
        newAssetBenefit.Plan__c = goldPlan.Id;
        insert newAssetBenefit;
    }
    
    @isTest
    static void testBatch() {
        Test.StartTest();
        try{
            UnusedAssetBenefitPurgerBatch be = new UnusedAssetBenefitPurgerBatch();
            database.executeBatch(be);
        } catch(Exception e){
            
        }
    
        Test.stopTest();
    }
   
    @isTest
    static void testSchedular(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
                
        Test.startTest();
        String jobId = System.schedule('UnusedAssetBenefitPurger',  CRON_EXP, new UnusedAssetBenefitPurgerBatchSchedular());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('UnusedAssetBenefitPurgerBatchSchedular', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');   
        
        Test.stopTest();
    }
}