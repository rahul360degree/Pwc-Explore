@isTest
public class QLILockedRecordsPopulatorTest {
    static testMethod void  createData(){
        Profile profile = [SELECT Id FROM Profile WHERE Name ='Locks B2C ISTD HO Team'];
        User locksHOUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Locks HO Team')
            .getTestRecord();        
        locksHOUser.IsActive = true;
        locksHOUser.Persona__c = 'Locks B2C ISTD - BDE';
        insert locksHOUser; 
        
        System.runAs(locksHOUser)
        { 
            System.assertEquals('Locks HO Team', locksHOUser.LastName);
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
            qli.List_of_Approvers__c=locksHOUser.Id;
            qli.Current_Approver__c=locksHOUser.Id;
            insert qli;
            
            Test.startTest();
            	
            	String qliRecords = '[{"fields":{"Retailer_Retention__c":0.07,"Discount__c":6,"Distributor_Retention__c":0.07,"Quantity":7,"Id":"'+qli.Id+'"}}]';
            	String recordId = String.Valueof(quoteRecord.Id);
                List<SObject> quoteLineItems = QLILockedRecordsPopulator.fetchQuoteLineItemforLocksB2CISTD(recordId);
            
                List<Quote> quoteList = [SELECT Id FROM Quote WHERE Id =: recordId];
                List<Approval.LockResult> lrList = Approval.lock(quoteList,false);
                QLILockedRecordsPopulator.updateQuoteLineItemforLocksB2CISTD(recordId, qliRecords);
          		System.assert(quoteLineItems != null && !quoteLineItems.isEmpty(), 'Quote line items list is null or empty for recordId: ' + recordId);
            Test.stopTest();
        }
        
    }

}