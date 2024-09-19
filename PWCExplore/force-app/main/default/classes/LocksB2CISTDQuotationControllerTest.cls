/**
* @description       : 
* @author            : jadhavr@godrej.com
* @group             : 
* @last modified on  : 03-10-2023
* @last modified by  : jadhavr@godrej.com
**/

@isTest
public class LocksB2CISTDQuotationControllerTest {    
    static testMethod void createQuotePDF(){
       Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        { 
            System.assertEquals('Admin User', runningAdminUser.LastName);
            // Created Business Account.
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId())
                .setBusinessUnit(GlobalConstants.Locks_BUSINESS_UNIT)
                .getSavedTestRecord();
            
            // Created Opportunity for Locks B2C ISTD.
            Opportunity oppRecord=new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId())
                .setAccountId(acc.Id)
                .setBusinessUnit(GlobalConstants.Locks_BUSINESS_UNIT)
                .getSavedTestRecord();
            
            // Created Product
            Product2 product = new TestProductBuilder().setName('ELB ITPrk C AC Chrgs Main')
                .setItemCode('80131801SD00048').setDescription('ELB ITPrk C AC Chrgs Main').getTestRecord();
            insert product;
            
            // Fetch Standard Price Book.
            Id pricebookId = Test.getStandardPricebookId();
            
            // Created Price Book Entry for Product
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
            insert pbe;            
            
            // Created Quote for Locks B2C ISTD.
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2C_ISTD).getRecordTypeId())
                .setOpportunityId(oppRecord.Id)
                .setPricebook2Id(pricebookId)                  
                .getTestRecord();  
            quoteRecord.ExpirationDate=system.today()+30;
            insert quoteRecord;
            
            GlobalConstants.SKIP_QUOTE_LOCK = true;            
            QliTriggerHandler.TriggerDisabled = true;
            
            // Created QuoteLineItem for Locks B2C ISTD.
            QuoteLineItem qli = new TestQuoteLineItemBuilder()
                .setQuoteId(quoteRecord.Id)
                .setPriceBookEntryId(pbe.Id)
                .setUnitPrice(pbe.UnitPrice)
                .getTestRecord();  
            
            qli.Product2Id = pbe.Product2Id;                
            qli.Discount__c = 20;
            qli.Tax_Rate_Percentage__c=10;
            qli.Distributor_Retention__c=3;
            qli.UnitPrice=100;
            qli.List_of_Approvers__c=runningAdminUser.Id;
            qli.Current_Approver__c=runningAdminUser.Id;
            insert qli;
            
            Test.startTest();
            	// Created Instance of StandardController class.
                ApexPages.StandardController sc = new ApexPages.standardController(quoteRecord);
            	
            	// Created Instance of LocksB2CISTDQuotationController class.
                LocksB2CISTDQuotationController controller = new LocksB2CISTDQuotationController(sc);
            
            	ApexPages.StandardController sc1 = new ApexPages.standardController(qli);
                LocksB2CISTDQuotationController controller1 = new LocksB2CISTDQuotationController(sc1);
          		system.assertEquals('List has no rows for assignment to SObject', controller1.errorMessage);
            Test.stopTest();
        }
    }
}