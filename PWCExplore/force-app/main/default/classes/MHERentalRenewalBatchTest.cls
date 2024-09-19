/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Test Class for MHERentalRenewalBatch
Inputs:        
Test Class:   

History
23-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
@isTest
public without sharing class MHERentalRenewalBatchTest 
{
    
    @TestSetup static void createData()
    {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,Salary_code__c = 'testMHERenewalbatchTest',
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.ServiceContractTriggerDisabled__c = true; 
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            
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
            
            ServiceContract sc = ServiceContractManager.createServiceContract(quoteRecord.Id);
        }
    }
    
    //ServiceContract along with Line Items should be renewed with appropriate default values of Recordtype, MHE Division, PB
    @isTest private static void serviceContractsWithLineItemsShouldBeRenewed()
    {
        ServiceContract sc = [Select ID, Associated_Opportunity__c, MHE_Division__c, (Select Id from ContractLineItems) from ServiceContract Limit 1];
        System.assertNotEquals(sc, NULL, 'ServiceContract should be available');
        System.assertNotEquals(sc.ContractLineItems.size(), 0, 'ContractLineItems should be available');
        System.assertNotEquals(sc.Associated_Opportunity__c, NULL, 'Opportunity should be available');
        System.assertEquals(sc.MHE_Division__c, GlobalConstants.MHE_SUB_DIVISION_RENTAL, 'MHE Division should be Godrej RenTRUST');
        
        
        Integer numberOfDaysForExpiry = Integer.ValueOf(RenewalHelper.getApplicationSetting('Number_Of_Days_for_Expiry_RenTrust'));
        Date expiryDate = System.today().addDays(numberOfDaysForExpiry);
        sc.StartDate = System.today();
        sc.EndDate = expiryDate;
        update sc;
        
        Test.startTest();
        Database.executeBatch(new MHERentalRenewalBatch());
        Test.stopTest();
        
        //Query for the renewal opportunity created from the batch class - MHERentalRenewalBatch
        Opportunity opp = [Select Id, Previous_Opportunity__c, Previous_Service_Contract__c, MHE_Division__c, RecordType.DeveloperName, Pricebook2.Name,
                           (Select Id from OpportunityLineItems) 
                           From Opportunity
                           Where Previous_Service_Contract__c<>NULL LIMIT 1];
        
        System.assertNotEquals(opp, NULL, 'Renewal Opportunity should be created');
        System.assertNotEquals(opp.Previous_Opportunity__c, NULL, 'Previous Opportunity should be populated');
        System.assertNotEquals(opp.Previous_Service_Contract__c, NULL, 'Previous Service Contract should be populated');
        System.assertEquals(opp.RecordType.DeveloperName, GlobalConstants.OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME, 'Recordtype should be populated as MHE_Rental');
        System.assertEquals(opp.MHE_Division__c, GlobalConstants.MHE_SUB_DIVISION_RENTAL, 'MHE Division should be populated as Godrej RenTRUST');
        System.assertEquals(opp.PriceBook2.Name, System.Label.MHE_SF_Local_Rental_PB, 'Pricebook should be populated as Godrej RenTRUST');
        System.assertEquals(opp.OpportunityLineItems.size(), sc.ContractLineItems.size(), 'All line items should be created');
    }
    
    //Pricebookentry with active product code should be tagged - via Item_Code__c on Product2
    @isTest private static void contractLineItemShouldPickActiveProductCode()
    {
        ServiceContract sc = [Select ID, Associated_Opportunity__c, MHE_Division__c, (Select Id from ContractLineItems) from ServiceContract Limit 1];
        System.assertNotEquals(sc, NULL, 'ServiceContract should be available');
        System.assertNotEquals(sc.ContractLineItems.size(), 0, 'ContractLineItems should be available');
        System.assertNotEquals(sc.Associated_Opportunity__c, NULL, 'Opportunity should be available');
        System.assertEquals(sc.MHE_Division__c, GlobalConstants.MHE_SUB_DIVISION_RENTAL, 'MHE Division should be Godrej RenTRUST');
        
        Integer numberOfDaysForExpiry = Integer.ValueOf(RenewalHelper.getApplicationSetting('Number_Of_Days_for_Expiry_RenTrust'));
        Date expiryDate = System.today().addDays(numberOfDaysForExpiry);
        sc.StartDate = System.today();
        sc.EndDate = expiryDate;
        update sc;
        
        List<Product2> prodList = [Select Id from Product2 where Name IN ('GX 300', 'Modern GX 300') order by Name ASC];
        //Depracating existing product with Product code 'GX1F'
        prodList[0].IsActive = FALSE;
        update prodList[0];
        //Adding new product for the same Product Code 'GX1F'
        //The Active Product for 'GX1F' should be used in Renewal Opportunity
        prodList[1].IsActive = TRUE;
        prodList[1].ProductCode = 'GX1F';
        
        Test.startTest();
        update prodList[1];
        Database.executeBatch(new MHERentalRenewalBatch());
        
        /*
        Opportunity opp = [Select Id, Previous_Opportunity__c, Previous_Service_Contract__c, MHE_Division__c, RecordType.DeveloperName, Pricebook2.Name,
                           (Select Id, Product2.Name from OpportunityLineItems) 
                           From Opportunity 
                           Where Previous_Service_Contract__c<>NULL LIMIT 1];
        
        Boolean isNewProductCodeAdded = FALSE;
        for(OpportunityLineItem oli : opp.OpportunityLineItems)
        {
            if(oli.Product2.Name == 'Modern GX 300')
                isNewProductCodeAdded = TRUE;
        }
        
        System.assertNotEquals(opp, NULL, 'Renewal Opportunity should be created');
        System.assertEquals(opp.OpportunityLineItems.size(), sc.ContractLineItems.size(), 'All line items should be created');
        System.assertEquals(isNewProductCodeAdded, TRUE, 'Pricebookentry with active ProductCode should be tagged');
*/
        Test.stopTest();
    }
    
    //Fields From Parent relationships should be fetched will appropriate Null Checks
    @isTest private static void fieldsFromParentRelationshipsShouldBeFetched()
    {
        List<QuoteLineItem> qliList = [Select Id, QuoteId, 
                                       Quote.OpportunityId, 
                                       Quote.Opportunity.AccountId, 
                                       Quote.Opportunity.Account.Name,  
                                       Quote.Opportunity.Account.RecordType.DeveloperName, 
                                       Quote.Opportunity.Account.Owner.Profile.Name
                                       From QuoteLineItem Limit 1];
        
        SObject sObj = qliList[0];
        Test.startTest();
        System.assertEquals(qliList[0].QuoteId , RenewalHelper.getFieldValue(sObj, 'QuoteId') );
        System.assertEquals(qliList[0].Quote.OpportunityId , RenewalHelper.getFieldValue(sObj, 'Quote.OpportunityId') );
        System.assertEquals(qliList[0].Quote.Opportunity.AccountId , RenewalHelper.getFieldValue(sObj, 'Quote.Opportunity.AccountId'));
        System.assertEquals(qliList[0].Quote.Opportunity.Account.Name , RenewalHelper.getFieldValue(sObj, 'Quote.Opportunity.Account.Name'));
        System.assertEquals(qliList[0].Quote.Opportunity.Account.RecordType.DeveloperName , RenewalHelper.getFieldValue(sObj, 'Quote.Opportunity.Account.RecordType.DeveloperName'));
        System.assertEquals(qliList[0].Quote.Opportunity.Account.Owner.Profile.Name , RenewalHelper.getFieldValue(sObj, 'Quote.Opportunity.Account.Owner.Profile.Name'));
        Test.stopTest();
    }
    
    @isTest private static void createLogShouldReturnApplicationLog()
    {
        Test.startTest();
        Application_Log__c logRecord = RenewalHelper.createLog('MHERentalRenewalBatchTest',
                                                               'createLogShouldReturnApplicationLog()',
                                                               NULL,
                                                               'Dummy Error Message');
        Test.stopTest();
        
        System.assertNotEquals(logRecord, NULL, 'An Application Log record should be returned');
        System.assertEquals(logRecord.Message__c.contains('Dummy Error Message'), TRUE, 'Error Message should be stamped');
        
    }
    
    //Schedule Class - MHERentalRenewalScheduler should be scheduled successfully to execute batch 
    @isTest private static void scheduleClassShouldRunSuccessfully()
    {
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
        
        
        Test.startTest();
        String jobId = System.schedule('MHERentalRenewal',  CRON_EXP, new MHERentalRenewalScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('MHERentalRenewalScheduler', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    }
    
    // A Renewal Opportunity should be created even if Associated Opportunity is not tagged on Service Contract
    // This will be the case for legacy Service Contracts
    @isTest private static void renewalOpportunityShouldBeCreatedEvenIfOpportunityIsNotAvailable()
    {
        ServiceContract sc = [Select ID, Associated_Opportunity__c, MHE_Division__c, (Select Id from ContractLineItems) from ServiceContract Limit 1];
        System.assertNotEquals(sc, NULL, 'ServiceContract should be available');
        System.assertEquals(sc.MHE_Division__c, GlobalConstants.MHE_SUB_DIVISION_RENTAL, 'MHE Division should be Godrej RenTRUST');
        
        
        Integer numberOfDaysForExpiry = Integer.ValueOf(RenewalHelper.getApplicationSetting('Number_Of_Days_for_Expiry_RenTrust'));
        Date expiryDate = System.today().addDays(numberOfDaysForExpiry);
        sc.StartDate = System.today();
        sc.EndDate = expiryDate;
        sc.Associated_Opportunity__c = NULL;
        update sc;
        
        
        Test.startTest();
        Database.executeBatch(new MHERentalRenewalBatch());
        Test.stopTest();
        
        //Query for the renewal opportunity created from the batch class - MHERentalRenewalBatch
        List<Opportunity> oppList = new List<Opportunity>([Select Id, Previous_Opportunity__c, Previous_Service_Contract__c, MHE_Division__c, RecordType.DeveloperName, Pricebook2.Name,
                                                           (Select Id from OpportunityLineItems) 
                                                           From Opportunity
                                                           Where Previous_Service_Contract__c<>NULL]);
        
        System.assertNotEquals(oppList.size(), 0, 'Renewal Opportunity should be created');
        System.assertEquals(oppList[0].Previous_Opportunity__c, NULL, 'Previous Opportunity is unavailable, cant be populated');
        System.assertNotEquals(oppList[0].Previous_Service_Contract__c, NULL, 'Previous Service Contract should be populated');
        System.assertEquals(oppList[0].RecordType.DeveloperName, GlobalConstants.OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME, 'Recordtype should be populated as MHE_Rental');
        System.assertEquals(oppList[0].MHE_Division__c, GlobalConstants.MHE_SUB_DIVISION_RENTAL, 'MHE Division should be populated as Godrej RenTRUST');
        System.assertEquals(oppList[0].PriceBook2.Name, System.Label.MHE_SF_Local_Rental_PB, 'Pricebook should be populated as Godrej RenTRUST');
        System.assertEquals(oppList[0].OpportunityLineItems.size(), sc.ContractLineItems.size(), 'All line items should be created');
    }
    
    
    
    
}