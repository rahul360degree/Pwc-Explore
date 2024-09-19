@isTest
public with sharing class ServiceContractManagerTest {
    
    @TestSetup static void createData(){
         Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'UserServiceContract', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        //update userToRun;
        
                System.runAs(userToRun) {
                    Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
                    setting.QuoteTriggerDisabled__c = true;
                    setting.FireQuoteValidationRules__c = false;
                    insert setting; 
                    
                    
                    
                    
            //Create Sales Office Record
            Sales_Office__c salesOffice = new Sales_Office__c();
            salesOffice.RecordTypeId = Schema.SObjectType.Sales_Office__c.getRecordTypeInfosByDeveloperName().get('Sales_Office').getRecordTypeId();
            salesOffice.Country__c = 'IND';
            salesOffice.State__c = 'IND_MH';
            salesOffice.LN_Sales_Office_Code__c = '9876qm';
            insert salesOffice;
            
            //Create Registration Number Record
            Registration_Number__c registration = new Registration_Number__c();
            registration.State__c = 'IND_MH';
            registration.Commodity_Code__c = System.Label.Commodity_Code;
            registration.Effective_Date__c = System.today().addDays(6);
            insert registration;
            
            
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
            
         //   Account accountRecordBU = new TestAccountBuilder()
          //      .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('Interio Sub-Division')
          //      .getSavedTestRecord();
    
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').getSavedTestRecord();
            
        //    Opportunity oppRecordNONMHE = new TestOpportunityBuilder().setAccountId(accountRecord.Id).setBusinessUnit('Interio Sub-Division').getSavedTestRecord();
    
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
    
    //Added By Praful - 01-March-2021
    @isTest private static void validateEndDateCalculation(){
        Test.startTest();
          
        Opportunity oppRecord = [ select Id from Opportunity ];
          
        //Added by Praful - 01-March-2021
        //Commented 4 opp Record instances by Shreela as only Month is selected value for Duration Unit for Rentrust Opportunity in all three org on 25th Jan 2023
            /*oppRecord.Duration_Unit__c = 'Year'; 
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecord;
            
            //Added by Praful - 01-March-2021
            //oppRecord.Duration_Unit__c = 'Quarter'; //Commented by Shreela on 25th Jan 2023 as Month is the only option for Rentrust in all three org
            oppRecord.Duration_Unit__c = 'Month'; //Added by Shreela on 25th Jan 2023
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecord; */
            
            //Added by Praful - 01-March-2021
            oppRecord.Duration_Unit__c = 'Month';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecord;
            
            //Added by Praful - 01-March-2021
            /*oppRecord.Duration_Unit__c = 'Week';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecord;
            
            //Added by Praful - 01-March-2021
            oppRecord.Duration_Unit__c = 'Day';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecord; */
          
        Test.stopTest();
        system.assertEquals(system.today().addMonths(1),oppRecord.Contract_Start_Date__c);//gcp22
    }
    
    
    @isTest private static void invalidQtAccountNameShouldAlertUser(){
        Quote quoteRecord = getQuote();
        Test.startTest();
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
        Test.stopTest();
        System.assertEquals(System.Label.ACCOUNT_NAME_MISING, actualErrorMessage, 'Quote without Account should alert user');
    }
    
    @isTest private static void invalidQtNoMHEeShouldAlertUser(){
        
        Account accountRecordBU = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('W')
            .getSavedTestRecord();

    Opportunity oppRecordNONMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId())
            .setAccountId(accountRecordBU.Id).setBusinessUnit('W').getSavedTestRecord();
        
        Test.startTest();
        
        Quote quoteRecordNoMHE = new TestQuoteBuilder().setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Interio_B2B_APO').getRecordTypeId())
            .setOpportunityId(oppRecordNONMHE.Id).getSavedTestRecord();
        
        
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecordNoMHE.id);
        Test.stopTest();
        System.assertEquals(System.Label.Cannot_Generate_Service_Contract, actualErrorMessage, 'Quote with non-contractual recordtype should alert user');
    }
    
    @isTest private static void invalidQtNotFinalisedShouldAlertUser(){
        Test.startTest();
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
            Account accountRecordBU = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
        
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
        Test.stopTest();
        System.assertEquals(System.Label.QUOTE_NOT_FINALIZED, actualErrorMessage, 'Quote not finalised should alert user');
        

    }
    
   @isTest private static void nonPrimaryQuoteShouldAlertUser(){
       Test.startTest();
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
        
            Account accountRecordBU = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
       
         Quote quoteRecordPrim = getQuote();
         quoteRecord.Primary_Quote__c = quoteRecordPrim.Id;
         update quoteRecord;
       
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
        Test.stopTest();
        System.assertEquals('This is not the Primary Quote.', actualErrorMessage, 'Non Primary Quote should alert user');
    }

  @isTest private static void quoteExpiredShouldAlertUser(){
        Test.startTest();
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
        
            Account accountRecordBU = new TestAccountBuilder()
                .setName('quoteExpiredShouldAlertUser') //Added name by Dipti on 11th Sep 2023 to avoid duplicacy
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
        
         quoteRecord.ExpirationDate  = System.today()-1;
         update quoteRecord;
       
        
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
        Test.stopTest();
        System.assertEquals(System.Label.QUOTE_EXPIRED , actualErrorMessage, 'Quote Expired should alert user');
    }
    
    @isTest private static void quoteWIthoutQliShouldAlertUser(){
        Test.startTest();
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
        
            Account accountRecordBU = new TestAccountBuilder()
                .setName('TEST ACCOUNT FOR MHE') //Name changed by Shreela on 30th Jan 2023 to avoid duplicacy 
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
        
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
        update quoteRecord;
        
        
          String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
        Test.stopTest();
        System.assertEquals(System.Label.NO_PRODUCT_ADDED, actualErrorMessage, 'Quote without QLIs should alert user');

    }
    
    @isTest private static void valideQuoteShouldNotAlertUser(){
        
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
           Test.startTest();
            Account accountRecordBU = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        
        
            List<PriceBookEntry> allPBEs = [Select id, priceBook2Id from PriceBookEntry];
            
            quoteRecord.Pricebook2Id = allPBEs[0].priceBook2Id;
            update quoteRecord;
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord()
            };
            insert allQLI;
            quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
            update quoteRecord;
        }
            
                String actualErrorMessage = ServiceContractManager.validateQuote(quoteRecord.id);
            Test.stopTest();
        
        System.assertEquals(null, actualErrorMessage, 'Valid Quoute');

    }
    
    @isTest private static void createServiceContractShouldCreateSerContract(){
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
            
            Account accountRecordBU = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
        
        List<PriceBookEntry> allPBEs = [Select id, priceBook2Id from PriceBookEntry];
        
        Test.startTest();
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
        quoteRecord.Pricebook2Id = allPBEs[0].priceBook2Id;
        update quoteRecord;
        
        List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
            new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord()
        };
        insert allQLI;
        
        ServiceContract serviceContractObj = ServiceContractManager.createServiceContract(quoteRecord.id);
        
        serviceContractObj.Duration_Unit__c = 'Day';
        
        update serviceContractObj;
        
        Test.stopTest();
        System.assertEquals(serviceContractObj.Associated_Quote__c, quoteRecord.Id, 'Service Contract Generated for the Quote');
       // System.assertEquals(null, actualErrorMessage, 'Valid Quoute');

    }
    
    @isTest private static void createServiceContractShouldCreateSerContractWithDuration(){
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        Quote quoteRecord;
        System.runAs(runAsUser){
            Test.startTest();
            Account accountRecordBU = new TestAccountBuilder()
                .setName('CreateSerContractWithDuration') //Added Name changed by Dipti on 12th Dec 2023 to avoid duplicacy 
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('K')
                .getSavedTestRecord();
    
            Opportunity oppRecordMHE = new TestOpportunityBuilder().setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecordBU.Id).setBusinessUnit('K ').getSavedTestRecord();
            
            oppRecordMHE.Duration_Unit__c = 'Year';
            oppRecordMHE.Duration__c = 1;
            oppRecordMHE.Contract_Start_Date__c = system.today().addMonths(1);
            
            update oppRecordMHE;
            
            quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecordMHE.Id).getSavedTestRecord();
        }
        
        List<PriceBookEntry> allPBEs = [Select id, priceBook2Id from PriceBookEntry];
        
        
        quoteRecord.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
        quoteRecord.Pricebook2Id = allPBEs[0].priceBook2Id;
       // quoteRecord.Duration_Unit__c = 'Day';
       // quoteRecord.Duration__c = 1;
       // quoteRecord.Contract_Start_Date__c = system.today().addMonths(1);
        update quoteRecord;
        
        List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
            new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord()
        };
        insert allQLI;
        
        ServiceContract serviceContractObj = ServiceContractManager.createServiceContract(quoteRecord.id);
        Test.stopTest();
        
        serviceContractObj.Duration_Unit__c = 'Year';
        
        update serviceContractObj;
        
        System.assertEquals(serviceContractObj.Associated_Quote__c, quoteRecord.Id, 'Service Contract Generated for the Quote');
       // System.assertEquals(null, actualErrorMessage, 'Valid Quoute');

    }

    
    private static Quote getQuote() {
        return [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
    }
    
    
    @isTest private static void testGetRegistrationNumberRecordId(){
        User runAsUser=[Select Id From User Where Name='Test UserServiceContract' Limit 1];
        System.runAs(runAsUser){
            Test.startTest();
            ServiceContractManager scm = new ServiceContractManager();
            Sales_Office__c salesOfficeRecord = [SELECT Id, State__c FROM Sales_Office__c LIMIT 1];
            Id registrationId =  scm.getRegistrationNumberRecordId(salesOfficeRecord);
            System.assert(registrationId != null);
            Test.stopTest();
        }
    }
    
    
}