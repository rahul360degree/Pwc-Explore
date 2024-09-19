@isTest
public class QLIRecordProcessorTest {
    
    @testSetup
    public static void createData(){
        list<Account> accounts = new list<Account>();
        list<Opportunity> Opportunities = new list<Opportunity>();
        list<Quote> quotes = new list<Quote>();
        
        Account locks_BU = new Account(Name='Locks Business Account',Business_Unit__c='L',Industry='Manufacturing', Account_Code__c='TPL',PAN__c='AABFA2957L',
                                       RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId());
        accounts.add(locks_BU);
        
        Account locks_influencer = new Account(Name='Influencer',Business_Unit__c='L',Industry='Manufacturing',PAN__c='AABFA2957L',
                                               RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Influencer').getRecordTypeId());
        accounts.add(locks_influencer);
        
        //Interio - VFD Dealer user
        User userToRun = createUserRecord(null, '', 'InterioVFD- Dealer', GlobalConstants.INTERIO_BUSINESS_UNIT);
        
        //Interio - Kitchen user
        User kitchenZonalHeadUser = createUserRecord(null, 'ZonalHead', 'Interio Kitchen-Zonal Head', GlobalConstants.INTERIO_BUSINESS_UNIT);
        
        System.runAs(userToRun) {
            
            // Create Products.
            Product2 product = createProductRecords(true);
            product.Product_Storage_Clasification__c='Category A';
            product.Lead_Time__c = 5;
            product.BOM_Cost__c = 5000;
            insert product;
            
            //added by pankaj on 30 nov 2021
            Product2 productAttachment = createProductRecord2(true);
            productAttachment.Product_Storage_Clasification__c='Category B';
            productAttachment.Lead_Time__c = 7;
            productAttachment.BOM_Cost__c = 7000;
            insert productAttachment;
            
            Product2 productAttachmentCategoryA = createProductRecord3(true);
            productAttachmentCategoryA.Product_Storage_Clasification__c='Category A';
            productAttachmentCategoryA.Lead_Time__c = 10;
            productAttachmentCategoryA.BOM_Cost__c = 10000;
            insert productAttachmentCategoryA;
            //end by pankaj
            
            // Create standard pricebook record for the products created.
            PricebookEntry standardPricebookEntry = createStandardPricebookEntries(product);
            insert standardPricebookEntry;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;
            
            // Create PricebookEntry for the above products and pricebook.
            PricebookEntry pricebookEntryRecord = createPricebookEntryRecords(product, pricebookRecord);
            insert pricebookEntryRecord;
            //added by pankaj on 30 nov 2021
            PricebookEntry standardPricebookEntry2 = createStandardPricebookEntries(productAttachment);
            insert standardPricebookEntry2;
            PricebookEntry priceBookEntryAttach =createPricebookEntryRecord2(productAttachment, pricebookRecord);
            insert priceBookEntryAttach;
            
            PricebookEntry standardPricebookEntry3 = createStandardPricebookEntries(productAttachmentCategoryA);
            insert standardPricebookEntry3;
            PricebookEntry priceBookEntryAttach3 =createPricebookEntryRecord2(productAttachmentCategoryA, pricebookRecord);
            insert priceBookEntryAttach3;
            //end by pankaj
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getTestRecord();            
            accounts.add(accountRecord);
            
            /*   Account kitchenAccount = new TestAccountBuilder()
.setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
.setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT).getTestRecord();
accounts.add(kitchenAccount);*/
            
            insert accounts;
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('W').getTestRecord();
            oppRecord.Name = 'VFD Opp';
            
            //Added by Praful - 02-March-2021
            oppRecord.Duration_Unit__c = 'Year';
            oppRecord.Duration__c = 1;
            oppRecord.Contract_Start_Date__c = system.today().addMonths(1);
            
            Opportunities.add(oppRecord);
            
            Opportunity kitchenOppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('W').setAccountId(accountRecord.Id).getTestRecord();
            kitchenOppRecord.Sub_Division__c = GlobalConstants.B2C_SUBDIVISION;
            kitchenOppRecord.Interio_Sub_Division__c = GlobalConstants.INTERIO_KITCHEN;
            kitchenOppRecord.AccountId = accountRecord.Id;
            kitchenOppRecord.Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT;
            kitchenOppRecord.Name = 'Kitchen Opp record';
            kitchenOppRecord.Pricebook2Id=pricebookRecord.Id;
            Opportunities.add(kitchenOppRecord);
            
            //Added Appliance B2B Opportunity by Shreela on 15th Dec 2022
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            Opportunities.add(oppApplB2BRecord);
            
            insert Opportunities;
            
            //Create Interio B2C VFD Quote
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getTestRecord();
            quotes.add(quoteRecord);
            
            //Create Interio Kitchen Quote
            Quote kitchenQuote = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN).getRecordTypeId())
                .setOpportunityId(kitchenOppRecord.Id).getTestRecord();
            kitchenQuote.Name = 'Interio Kitchen Quote test';
            kitchenQuote.Pricebook2Id=pricebookRecord.Id;
            quotes.add(kitchenQuote);
            
            insert quotes;
            
            quoteRecord.Pricebook2Id=pricebookRecord.Id;
            Update quoteRecord;
        }
    }
    
    @isTest
    public static void qliApprovalProductLineShouldBeHomeFurniture(){
        User runningUser=[Select Id From User Where Persona__c='InterioVFD- Dealer' And Profile.Name='System Administrator' limit 1];
        System.runAs(runningUser){
            Id quoteId=[Select Id From Quote where RecordType.DeveloperName='Interio_B2C_VFD' Limit 1].Id;
            priceBookEntry priceBookEntryRecord=[Select Id, Product2Id From PriceBookEntry Where PriceBook2.Name='test price book 1' Limit 1];
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteId).setSequenceNumber(1).setUnitPrice(32000).setPriceBookEntryId(priceBookEntryRecord.Id).setProductLine('Mattress').getTestRecord()
                    };
                        allQLI[0].Product2Id=priceBookEntryRecord.Product2Id;
            test.startTest();
            insert allQLI;
            test.stopTest();
            QuoteLineItem qli=[Select Id,Approval_Product_Line__c From QuoteLineItem Limit 1];
            System.assertEquals('Home Furniture 3',qli.Approval_Product_Line__c);
            Update qli;
            Delete qli;
        }
    }
    
    @isTest
    public static void testUpdateSequence(){
        
        List<Quote> quotesToInsert=new List<Quote>();
        
        User runningUser=[Select Id From User Where Persona__c='InterioVFD- Dealer' And Profile.Name='System Administrator' limit 1];
        
        Opportunity opp=[Select Id From Opportunity WHERE Name = 'VFD Opp' Limit 1];
        
        Opportunity oppApplRecord =[Select Id From Opportunity WHERE Name = 'Appl B2B Opp record' Limit 1];//Added by Shreela on 15th Dec 2022
        
        PriceBookEntry priceBookEntry=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where PriceBook2.Name='test price book 1' Limit 1]; 
        //added by pankaj 
        PriceBookEntry priceBookEntry2=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where Product2.component_type__c='attachments' Limit 1]; 
        
        PriceBookEntry priceBookEntry3=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where Product2.component_type__c='attachments' and Product2.Product_Storage_Clasification__c='Category A' Limit 1]; 
        //end
        Quote quote1=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote1);
        
        Quote quote2=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_WITH_ORC_TO_DEALER,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote2);
        
        Quote quote3=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote3);
        
        Quote quote4=createQuote(GlobalConstants.DIRECT_BILLING_TO_DEALER_PRIMARY_WITH_SCHEME,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote4);
        
        Quote quote5=createQuote(GlobalConstants.BILLING_TO_DEALER_WITH_ADDITIONAL_DISCOUNT,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote5);
        
        Quote quote6=createQuote(GlobalConstants.DIRECT_BILLING_TO_DEALER_WITH_NO_DISCOUNT,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote6);
        
        Quote quote7=createQuote(GlobalConstants.ORDER_TYPE_Secondary,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote7);
        
        Quote quote8=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS);
        quotesToInsert.add(quote8);
        
        Quote quote9=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_CONTRACTS);
        quotesToInsert.add(quote9);
        
        Quote quote10=createQuote('',priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME);
        quotesToInsert.add(quote10);
        
        Quote quote11=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS);
        quotesToInsert.add(quote11);
        //added by pankaj on 30 nov 2021
        Quote quote12=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote12);
        
        Quote quote13=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry2.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote13);
        
        
        Quote quote14=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry3.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote14);
        
        Quote quote15=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry3.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote15);
        //end by pankaj 
        
        //Added Quote 16 by Shreela
        Quote quote16=createQuote(GlobalConstants.ORDER_TYPE_SECONDARY,priceBookEntry3.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE);
        quote16.Last_Approved_Date__c = System.today()-1 ; //Added by Shreela on 13th Dec 2022
        quote16.OpportunityId = oppApplRecord.Id; //Added by Shreela on 15th Dec 2022
        quotesToInsert.add(quote16);
        
        System.runAs(runningUser){
            QuoteTriggerHandler.TriggerDisabled=true;
            Insert quotesToInsert;
            QuoteTriggerHandler.TriggerDisabled=false; 
        }
        
        List<QuoteLineItem> qliToInsert=new List<QuoteLineItem>();
        
        QuoteLineItem qliSequence1Quote1=setQLIValues(3,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence1Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote1);
        
        QuoteLineItem qliSequence2Quote1=setQLIValues(6,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence2Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote1);
        
        QuoteLineItem qliSequence3Quote1=setQLIValues(11,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence3Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote1);
        
        QuoteLineItem qliSequence4Quote1=setQLIValues(16,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence4Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence4Quote1);
        
        QuoteLineItem qliSequence5Quote1=setQLIValues(26,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence5Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence5Quote1);
        
        QuoteLineItem qliSequence0Quote1=setQLIValues(0,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence0Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote1);
        
        QuoteLineItem qliSequence1Quote2=setQLIValues(6,0,1,priceBookEntry.Id,quote2.Id,'',0);
        qliSequence1Quote2.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote2);
        
        QuoteLineItem qliSequence0Quote2=setQLIValues(0,0,0,priceBookEntry.Id,quote2.Id,'',0);
        qliSequence0Quote2.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote2);
        
        QuoteLineItem qliSequence1Quote3=setQLIValues(12,4,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence1Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote3);
        
        QuoteLineItem qliSequence2Quote3=setQLIValues(16,4,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence2Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote3);
        
        QuoteLineItem qliSequence3Quote3=setQLIValues(16,4,1,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence3Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote3);
        
        QuoteLineItem qliSequence0Quote3=setQLIValues(0,0,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence0Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote3);
        
        QuoteLineItem qliSequence1Quote4=setQLIValues(9,5,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence1Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote4);
        
        QuoteLineItem qliSequence2Quote4=setQLIValues(99,5,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence2Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote4);
        
        QuoteLineItem qliSequence1Quote5=setQLIValues(9,5,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence1Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote5);
        
        QuoteLineItem qliSequence2Quote5=setQLIValues(99,5,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence2Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote5);
        
        QuoteLineItem qliSequence1Quote6=setQLIValues(2,1,0,priceBookEntry.Id,quote6.Id,'',0);
        qliSequence1Quote6.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote6);
        
        QuoteLineItem qliSequence1Quote7=setQLIValues(6,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence1Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote7);
        
        QuoteLineItem qliSequence2Quote7=setQLIValues(10,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence2Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote7);
        
        QuoteLineItem qliSequence3Quote7=setQLIValues(14,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence3Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote7);
        
        QuoteLineItem qliSequence1Quote8=setQLIValues(16,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence1Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote8);
        
        QuoteLineItem qliSequence2Quote8=setQLIValues(21,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence2Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote8);
        
        QuoteLineItem qliSequence3Quote8=setQLIValues(26,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence3Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote8);
        
        QuoteLineItem qliSequence1Quote9=setQLIValues(1,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence1Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote9);
        
        QuoteLineItem qliSequence2Quote9=setQLIValues(6,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence2Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote9);
        
        QuoteLineItem qliSequence3Quote9=setQLIValues(16,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence3Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote9);
        
        QuoteLineItem qliSequence1Quote11=setQLIValues(4,0,0,priceBookEntry.Id,quote11.Id,'',4);
        qliSequence1Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote11);
        
        QuoteLineItem qliSequence2Quote11=setQLIValues(6,0,0,priceBookEntry.Id,quote11.Id,'',6);
        qliSequence2Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote11);
        
        QuoteLineItem qliSequence3Quote11=setQLIValues(11,0,0,priceBookEntry.Id,quote11.Id,'',11);
        qliSequence3Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote11);
        
        QuoteLineItem qliSequence0Quote4=setQLIValues(0,0,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence0Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote4);
        
        QuoteLineItem qliSequence0Quote5=setQLIValues(0,0,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence0Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote5);
        
        QuoteLineItem qliSequence0Quote6=setQLIValues(0,0,0,priceBookEntry.Id,quote6.Id,'',0);
        qliSequence0Quote6.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote6);
        
        QuoteLineItem qliSequence0Quote7=setQLIValues(0,0,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence0Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote7);
        
        QuoteLineItem qliSequence0Quote8=setQLIValues(0,0,0,priceBookEntry.Id,quote8.Id,'Silver',0);
        qliSequence0Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote8);
        
        QuoteLineItem qliSequence0Quote9=setQLIValues(0,0,0,priceBookEntry.Id,quote9.Id,'Platinum',0);
        qliSequence0Quote9.Product2Id=priceBookEntry.Product2Id;
        qliSequence0Quote9.Application__c = 'Warehouse';//added by pankaj on 10th april 2023
        qliSequence0Quote9.Uptime_Required__c = 2;//added by pankaj on 10th april 2023
        qliToInsert.add(qliSequence0Quote9);
        
        QuoteLineItem qliSequence0Quote10=setQLIValues(0,0,0,priceBookEntry.Id,quote10.Id,'Gold',0);
        qliSequence0Quote10.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote10);
        
        QuoteLineItem qliSequence0Quote11=setQLIValues(0,0,0,priceBookEntry.Id,quote11.Id,'',0);
        qliSequence0Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote11);
        
        QuoteLineItem testQli=setQLIValues(0,0,0,priceBookEntry.Id,quote9.Id,'Titanium',0);
        testQli.Product2Id=priceBookEntry.Product2Id;
        testQli.Application__c = 'Warehouse';//added by pankaj on 10th april 2023
        testQli.Uptime_Required__c = 2;//added by pankaj on 10th april 2023
        qliToInsert.add(testQli);
        
        //Added by pankaj on 30 nov 2021
        QuoteLineItem qliSequence0Quote12=setQLIValues(10,0,0,priceBookEntry.Id,quote12.Id,'',0);
        qliSequence0Quote12.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote12);
        
        QuoteLineItem qliSequence0Quote13=setQLIValues(10,0,0,priceBookEntry2.Id,quote13.Id,'',0);
        qliSequence0Quote13.Product2Id=priceBookEntry2.Product2Id;
        qliToInsert.add(qliSequence0Quote13);
        
        QuoteLineItem qliSequence0Quote14=setQLIValues(6,0,0,priceBookEntry3.Id,quote13.Id,'',0);
        qliSequence0Quote14.Product2Id=priceBookEntry3.Product2Id;
        qliToInsert.add(qliSequence0Quote14);
        
        QuoteLineItem qliSequence0Quote15=setQLIValues(12,0,0,priceBookEntry3.Id,quote13.Id,'',0);
        qliSequence0Quote15.Product2Id=priceBookEntry3.Product2Id;
        qliToInsert.add(qliSequence0Quote15);
        //ended by pankaj
        
        
        //Added by Shreela on 13th Dec 2022
        
        QuoteLineItem qliSequence1Quote16=setQLIValues(0.3,0,0,priceBookEntry3.Id,quote16.Id,'',0);
        qliSequence1Quote16.Product2Id=priceBookEntry.Product2Id;
        qliSequence1Quote16.Payment_Terms__c = GlobalConstants.Payment_Terms_Value_Greater_than_25_Days ; 
        qliToInsert.add(qliSequence1Quote16);
        
        QuoteLineItem qliSequence2Quote16=setQLIValues(2.5,0,0,priceBookEntry3.Id,quote16.Id,'',0);
        qliSequence2Quote16.Product2Id=priceBookEntry.Product2Id;
        qliSequence2Quote16.Payment_Terms__c = GlobalConstants.Payment_Terms_Value_Within_7_Days; 
        qliToInsert.add(qliSequence2Quote16);
        
        QuoteLineItem qliSequence3Quote16=setQLIValues(4.2,0,0,priceBookEntry3.Id,quote16.Id,'',0);
        qliSequence3Quote16.Product2Id=priceBookEntry.Product2Id;
        qliSequence3Quote16.Payment_Terms__c = GlobalConstants.PAYMENT_MODE_OTHERS ; 
        qliToInsert.add(qliSequence3Quote16);
        
        //Added by Shreela on 23rd Nov 22
        System.runAs(runningUser){
            //added by pankaj on 10th april 2023
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;               
            insert setting; 
            //end by pankaj
            test.startTest();
            Insert qliToInsert;
            //List<QuoteLineItem> qLIs=[Select Id From QuoteLineItem where Sequence__c=null]; //Commented by Shreela for SMEPB 111 on 13th Dec 2023
            List<QuoteLineItem> qLIs=[Select Id From QuoteLineItem where Quote.Transaction_Type__c =: GlobalConstants.ORDER_TYPE_Secondary]; //Added by Shreela for SMEPB 111 on 13th Dec 2023
            System.assertNotEquals(0,qLIs.size());
            test.stopTest();
        }
    }
    
    static testMethod void test_validateAndAutoapproveForKitchen(){
        map<Id,QuoteLineItem> newMap = new map<Id,QuoteLineItem>();
        map<Id,QuoteLineItem> oldMap = new map<Id,QuoteLineItem>();
        
        Id quoteRTId =  Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN).getRecordTypeId();
        PriceBookEntry pricebookEntryRecord = [SELECT Id,Product2Id, UnitPrice 
                                               FROM PriceBookEntry 
                                               WHERE PriceBook2.Name='test price book 1' Limit 1];
        User contextuser = [SELECT Id, Persona__c FROM User 
                            WHERE username = 'test.user18@godrej.com.ZonalHead' LIMIT 1];
        
        Quote kitchenQuote = [SELECT Id  FROM Quote
                              WHERE Name = 'Interio Kitchen Quote test' 
                              AND RecordTypeId =: quoteRTId LIMIT 1];
        
        
        System.runAs(contextuser) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true; //Added by Shreela on 23rd November 2022 to avoid 101 error
            insert setting; 
            
            Test.startTest();
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = kitchenQuote.Id;
            qli.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli.Product2Id = pricebookEntryRecord.Product2Id;
            qli.Quantity = 1 ;           
            qli.PricebookEntryId = pricebookEntryRecord.Id;
            qli.Requested_Customer_Discount__c = 10;
            
            insert qli;
            
            oldMap.put(qli.Id, qli);
            
            QuoteLineItem qli2 = new QuoteLineItem();
            qli2.Id = qli.Id;
            qli2.Requested_Customer_Discount__c = 20;            
            newMap.put(qli2.Id, qli2);
            
            QuoteLineItem qli3 = new QuoteLineItem();
            qli3.QuoteId = kitchenQuote.Id;
            qli3.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli3.Product2Id = pricebookEntryRecord.Product2Id;
            qli3.Quantity = 1 ;           
            qli3.PricebookEntryId = pricebookEntryRecord.Id;
            qli3.Requested_Customer_Discount__c = null;
            
            insert qli3;           
            
            QuoteLineItem qli4 = new QuoteLineItem();
            qli4.QuoteId = kitchenQuote.Id;
            qli4.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli4.Product2Id = pricebookEntryRecord.Product2Id;
            qli4.Quantity = 1 ;           
            qli4.PricebookEntryId = pricebookEntryRecord.Id;
            qli4.Requested_Customer_Discount__c = null;
            qli4.Requested_CustomerAmount__c=8;
            insert qli4; 
            QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
            qliProcessor.validateAndAutoapproveForKitchen(newMap, oldMap);
            //system.assertEquals(8,qli4.Requested_CustomerAmount__c);//gcp22
            //System.assertEquals(1, newMap.size());//gcp22
            // System.assertEquals(1, oldMap.size());//gcp22
            Test.stopTest();
            
        }
    }
    
    //Modified from Integer to Decimal for RequestedCustomerDiscount Parameter by Shreela on 20th Dec 2022
    public static QuoteLineItem setQLIValues(Decimal RequestedCustomerDiscount,Integer RequestedWDRetention,Integer RequestedSACORC,Id priceBookEntryId,Id quoteId,String contractType,
                                             Integer resquestedDealerDiscount){
                                                 QuoteLineItem qli=new TestQuoteLineItemBuilder().setQuoteId(quoteId).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(priceBookEntryId).setProductLine('HealthCare').getTestRecord();
                                                 qli.Requested_Customer_Discount__c=RequestedCustomerDiscount;
                                                 qli.Requested_WD_Retention__c=RequestedWDRetention;
                                                 qli.Requested_SAC_ORC__c=RequestedSACORC;
                                                 qli.Contract_Type__c=contractType;
                                                 qli.Requested_Dealer_Discount__c=resquestedDealerDiscount;
                                                 // qli.Application__c='Warehouse';
                                                 // qli.Uptime_Required__c=90;
                                                 return qli;
                                             }
    
    public static quote createQuote(String transactionType,Id pricebook,Id oppId,String recordType){
        Quote quote=new TestQuoteBuilder()
            .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(RecordType).getRecordTypeId())
            .setOpportunityId(oppId).getTestRecord();
        quote.Pricebook2Id=pricebook;
        quote.Transaction_Type__c=TransactionType;
        
        return quote;
    }
    
    private static Product2 createProductRecords(Boolean isGeneric) {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='DTWHAA';
        baseproduct1.Product_Class__c='DTWHAA';
        baseproduct1.Is_Generic_Product__c= isGeneric;
        baseproduct1.Is_New_Equipment__c=true;
        baseproduct1.Item__c='Test';
        return baseproduct1;
    }
    
    //added by pankaj for product name as attachment    
    private static Product2 createProductRecord2(Boolean isGeneric) {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = 'attachment', ProductCode = 'attachment');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.ATTACHMENT_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='DTWHAA';
        baseproduct1.Product_Class__c='DTWHAA';
        baseproduct1.Is_Generic_Product__c= isGeneric;
        baseproduct1.Is_New_Equipment__c=true;
        return baseproduct1;
    }
    
    private static Product2 createProductRecord3(Boolean isGeneric) {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = 'attachment2', ProductCode = 'attachment2');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.ATTACHMENT_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='DTWHAA';
        baseproduct1.Product_Class__c='DTWHAA';
        baseproduct1.Is_Generic_Product__c= isGeneric;
        baseproduct1.Is_New_Equipment__c=true;
        return baseproduct1;
    }
    //end by pankaj 30 oct 2021
    
    private static PricebookEntry createStandardPricebookEntries(Product2 product) {
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = product.Id,
            UnitPrice = 10000, IsActive = true);
        
        return standardPriceEntry;
    }
    
    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'test price book 1', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                                    IsActive = true
                                                   );
        return pricebookRecord;
    }
    
    private static PricebookEntry createPricebookEntryRecords(Product2 product, Pricebook2 pricebook) {
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = product.Id;
        pbe.Pricebook2Id = pricebook.Id;
        pbe.UnitPrice = 1000.00;
        pbe.IsActive = true;
        return pbe;
    }
    
    //added by pankaj on 30 nov 2021
    private static PricebookEntry createPricebookEntryRecord2(Product2 productAttachment, Pricebook2 pricebook) {
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = productAttachment.Id;
        pbe.Pricebook2Id = pricebook.Id;
        pbe.UnitPrice = 1000.00;
        pbe.IsActive = true;
        return pbe;
    }
    //end by pankaj
    
    private static user createUserRecord(Id managerUserId, String userNameAddOnString, String persona, String BU){
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.user17@godrej.com');
        
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.ManagerId = managerUserId;
        userRec.Persona__c = persona;
        userRec.username = 'test.user18@godrej.com';
        userRec.Business_Unit__c = BU;
        userRec.IsActive = true;
        
        if(String.isNotBlank(userNameAddOnString))
            userRec.username = 'test.user18@godrej.com.'+userNameAddOnString;
        
        insert userRec;
        
        return userRec;
    }
    
    public static testmethod void testContractWithGenericProduct() {
        List<Quote> quotesToInsert=new List<Quote>();
        List<QuoteLineItem> qliToInsert=new List<QuoteLineItem>();
        PriceBook2 pb = [select id from Pricebook2 limit 1];
        Opportunity opp=[Select Id From Opportunity WHERE Name = 'VFD Opp' Limit 1];
        
        Product2 productRec = createProductRecords(false);
        productRec.name = 'Non Generic Test Product';
        productRec.Item__c = '00002';
        productRec.ProductCode = '00002';
        insert productRec;
        
        PricebookEntry standardPricebookEntry = createStandardPricebookEntries(productRec);
        insert standardPricebookEntry;
        PriceBookEntry priceBookEntry = createPricebookEntryRecords( productRec, pb);
        insert priceBookEntry; 
        
        Quote quote8=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS);
        quotesToInsert.add(quote8);
        
        Quote quote9=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_CONTRACTS);
        quotesToInsert.add(quote9);
        
        Quote quote10=createQuote('',priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME);
        quotesToInsert.add(quote10);
        
        QuoteLineItem qliSequence0Quote8=setQLIValues(0,0,0,priceBookEntry.Id,quote8.Id,'Silver',0);
        qliSequence0Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote8);
        
        QuoteLineItem qliSequence0Quote9=setQLIValues(0,0,0,priceBookEntry.Id,quote9.Id,'Platinum',0);
        qliSequence0Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote9);
        
        QuoteLineItem qliSequence0Quote10=setQLIValues(0,0,0,priceBookEntry.Id,quote10.Id,'Gold',0);
        qliSequence0Quote10.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote10);
        
        QliRecordProcessor qlip = new QliRecordProcessor();
        qlip.prepopulateContractRelatedFields(qliToInsert, true);
        system.assertEquals(qliToInsert[0].Distance__c , '<100 Km');    
    }   
    
    
    static testMethod void test_setPriceBookForKitchenFileUpload(){
        map<Id,QuoteLineItem> newMap = new map<Id,QuoteLineItem>();
        map<Id,QuoteLineItem> oldMap = new map<Id,QuoteLineItem>();
        
        Id quoteRTId =  Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN).getRecordTypeId();
        PriceBookEntry pricebookEntryRecord = [SELECT Id,Product2Id, UnitPrice 
                                               FROM PriceBookEntry 
                                               WHERE PriceBook2.Name='test price book 1' Limit 1];
        User contextuser = [SELECT Id, Persona__c FROM User 
                            WHERE username = 'test.user18@godrej.com.ZonalHead' LIMIT 1];
        
        Quote kitchenQuote = [SELECT Id  FROM Quote
                              WHERE Name = 'Interio Kitchen Quote test' 
                              AND RecordTypeId =: quoteRTId LIMIT 1];
        
        
        System.runAs(contextuser) {
            
            Test.startTest();
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = kitchenQuote.Id;
            qli.UnitPrice = pricebookEntryRecord.UnitPrice;
            //qli.Product2Id = pricebookEntryRecord.Product2Id;
            qli.Quantity = 1 ;           
            qli.PricebookEntryId = pricebookEntryRecord.Id;
            qli.Requested_Customer_Discount__c = 10;
            insert qli;
            
            
            QLIRecordProcessor qliProcessor = new QLIRecordProcessor();
            qliProcessor.validateAndAutoapproveForKitchen(newMap, oldMap);
            System.debug([Select Id,Product2Id,Item__c,QuoteId,PricebookEntryId,UnitPrice from QuoteLineItem]);
            qliProcessor.setPriceBookForKitchenFileUpload([Select Id,Product2Id,Item__c,QuoteId,PricebookEntryId,UnitPrice from QuoteLineItem]);
            qliProcessor.setPriceBookForKitchenFileUpload(new list<QuotelineItem>());
            System.assertEquals(10, qli.Requested_Customer_Discount__c); //gcp22
            // QuoteLineItem updatedQli = [SELECT Id, PricebookEntryId, UnitPrice FROM QuoteLineItem WHERE Id =: qli.Id];//gcp22
            //  System.assertEquals(pricebookEntryRecord.Id, updatedQli.PricebookEntryId);//gcp22
            // System.assertEquals(pricebookEntryRecord.UnitPrice, updatedQli.UnitPrice);//gcp22 edited by dhiren 04/04/2023
            Test.stopTest();
        }
    }
    @isTest
    public static void testUpdateSequence_Primary(){
        
        List<Quote> quotesToInsert=new List<Quote>();
        
        User runningUser=[Select Id From User Where Persona__c='InterioVFD- Dealer' And Profile.Name='System Administrator' limit 1];
        
        Opportunity opp=[Select Id From Opportunity WHERE Name = 'VFD Opp' Limit 1];
        
        PriceBookEntry priceBookEntry=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where PriceBook2.Name='test price book 1' Limit 1]; 
        //added by pankaj 
        PriceBookEntry priceBookEntry2=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where Product2.component_type__c='attachments' Limit 1]; 
        
        PriceBookEntry priceBookEntry3=[Select Id,Product2Id, PriceBook2Id From PriceBookEntry Where Product2.component_type__c='attachments' and Product2.Product_Storage_Clasification__c='Category A' Limit 1]; 
        //end
        Quote quote1=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote1);
        
        Quote quote2=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_WITH_ORC_TO_DEALER,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote2);
        
        Quote quote3=createQuote(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote3);
        
        Quote quote4=createQuote(GlobalConstants.DIRECT_BILLING_TO_DEALER_PRIMARY_WITH_SCHEME,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote4);
        
        Quote quote5=createQuote(GlobalConstants.BILLING_TO_DEALER_WITH_ADDITIONAL_DISCOUNT,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote5);
        
        Quote quote6=createQuote(GlobalConstants.DIRECT_BILLING_TO_DEALER_WITH_NO_DISCOUNT,priceBookEntry.PriceBook2Id,opp.Id,'Interio_B2B_APO');
        quotesToInsert.add(quote6);
        
        Quote quote7=createQuote(GlobalConstants.ORDER_TYPE_Secondary,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote7);
        
        Quote quote8=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS);
        quotesToInsert.add(quote8);
        
        Quote quote9=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_CONTRACTS);
        quotesToInsert.add(quote9);
        
        Quote quote10=createQuote('',priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME);
        quotesToInsert.add(quote10);
        
        Quote quote11=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS);
        quotesToInsert.add(quote11);
        //added by pankaj on 30 nov 2021
        Quote quote12=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote12);
        
        Quote quote13=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry2.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote13);
        
        
        Quote quote14=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry3.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote14);
        
        Quote quote15=createQuote(GlobalConstants.ORDER_TYPE_PRIMARY,priceBookEntry3.PriceBook2Id,opp.Id,GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS);
        quotesToInsert.add(quote15);
        //end by pankaj 
        System.runAs(runningUser){
            QuoteTriggerHandler.TriggerDisabled=true;
            Insert quotesToInsert;
            QuoteTriggerHandler.TriggerDisabled=false;
        }
        
        List<QuoteLineItem> qliToInsert=new List<QuoteLineItem>();
        
        QuoteLineItem qliSequence1Quote1=setQLIValues(3,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence1Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote1);
        
        QuoteLineItem qliSequence2Quote1=setQLIValues(6,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence2Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote1);
        
        QuoteLineItem qliSequence3Quote1=setQLIValues(11,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence3Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote1);
        
        QuoteLineItem qliSequence4Quote1=setQLIValues(16,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence4Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence4Quote1);
        
        QuoteLineItem qliSequence5Quote1=setQLIValues(26,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence5Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence5Quote1);
        
        QuoteLineItem qliSequence0Quote1=setQLIValues(0,0,0,priceBookEntry.Id,quote1.Id,'',0);
        qliSequence0Quote1.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote1);
        
        QuoteLineItem qliSequence1Quote2=setQLIValues(6,0,1,priceBookEntry.Id,quote2.Id,'',0);
        qliSequence1Quote2.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote2);
        
        QuoteLineItem qliSequence0Quote2=setQLIValues(0,0,0,priceBookEntry.Id,quote2.Id,'',0);
        qliSequence0Quote2.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote2);
        
        QuoteLineItem qliSequence1Quote3=setQLIValues(12,4,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence1Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote3);
        
        QuoteLineItem qliSequence2Quote3=setQLIValues(16,4,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence2Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote3);
        
        QuoteLineItem qliSequence3Quote3=setQLIValues(16,4,1,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence3Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote3);
        
        QuoteLineItem qliSequence0Quote3=setQLIValues(0,0,0,priceBookEntry.Id,quote3.Id,'',0);
        qliSequence0Quote3.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote3);
        
        QuoteLineItem qliSequence1Quote4=setQLIValues(9,5,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence1Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote4);
        
        QuoteLineItem qliSequence2Quote4=setQLIValues(99,5,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence2Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote4);
        
        QuoteLineItem qliSequence1Quote5=setQLIValues(9,5,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence1Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote5);
        
        QuoteLineItem qliSequence2Quote5=setQLIValues(99,5,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence2Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote5);
        
        QuoteLineItem qliSequence1Quote6=setQLIValues(2,1,0,priceBookEntry.Id,quote6.Id,'',0);
        qliSequence1Quote6.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote6);
        
        QuoteLineItem qliSequence1Quote7=setQLIValues(6,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence1Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote7);
        
        QuoteLineItem qliSequence2Quote7=setQLIValues(10,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence2Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote7);
        
        QuoteLineItem qliSequence3Quote7=setQLIValues(14,1,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence3Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote7);
        
        QuoteLineItem qliSequence1Quote8=setQLIValues(16,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence1Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote8);
        
        QuoteLineItem qliSequence2Quote8=setQLIValues(21,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence2Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote8);
        
        QuoteLineItem qliSequence3Quote8=setQLIValues(26,1,0,priceBookEntry.Id,quote8.Id,'',0);
        qliSequence3Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote8);
        
        QuoteLineItem qliSequence1Quote9=setQLIValues(1,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence1Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote9);
        
        QuoteLineItem qliSequence2Quote9=setQLIValues(6,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence2Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote9);
        
        QuoteLineItem qliSequence3Quote9=setQLIValues(16,1,0,priceBookEntry.Id,quote9.Id,'',0);
        qliSequence3Quote9.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote9);
        
        QuoteLineItem qliSequence1Quote11=setQLIValues(4,0,0,priceBookEntry.Id,quote11.Id,'',4);
        qliSequence1Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence1Quote11);
        
        QuoteLineItem qliSequence2Quote11=setQLIValues(6,0,0,priceBookEntry.Id,quote11.Id,'',6);
        qliSequence2Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence2Quote11);
        
        QuoteLineItem qliSequence3Quote11=setQLIValues(11,0,0,priceBookEntry.Id,quote11.Id,'',11);
        qliSequence3Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence3Quote11);
        
        QuoteLineItem qliSequence0Quote4=setQLIValues(0,0,0,priceBookEntry.Id,quote4.Id,'',0);
        qliSequence0Quote4.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote4);
        
        QuoteLineItem qliSequence0Quote5=setQLIValues(0,0,0,priceBookEntry.Id,quote5.Id,'',0);
        qliSequence0Quote5.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote5);
        
        QuoteLineItem qliSequence0Quote6=setQLIValues(0,0,0,priceBookEntry.Id,quote6.Id,'',0);
        qliSequence0Quote6.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote6);
        
        QuoteLineItem qliSequence0Quote7=setQLIValues(0,0,0,priceBookEntry.Id,quote7.Id,'',0);
        qliSequence0Quote7.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote7);
        
        QuoteLineItem qliSequence0Quote8=setQLIValues(0,0,0,priceBookEntry.Id,quote8.Id,'Silver',0);
        qliSequence0Quote8.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote8);
        
        QuoteLineItem qliSequence0Quote9=setQLIValues(0,0,0,priceBookEntry.Id,quote9.Id,'Platinum',0);
        qliSequence0Quote9.Product2Id=priceBookEntry.Product2Id;
        qliSequence0Quote9.Application__c = 'Warehouse';//added by pankaj on 10th april 2023
        qliSequence0Quote9.Uptime_Required__c = 2;//added by pankaj on 10th april 2023
        qliToInsert.add(qliSequence0Quote9);
        
        QuoteLineItem qliSequence0Quote10=setQLIValues(0,0,0,priceBookEntry.Id,quote10.Id,'Gold',0);
        qliSequence0Quote10.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote10);
        
        QuoteLineItem qliSequence0Quote11=setQLIValues(0,0,0,priceBookEntry.Id,quote11.Id,'',0);
        qliSequence0Quote11.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote11);
        
        QuoteLineItem testQli=setQLIValues(0,0,0,priceBookEntry.Id,quote9.Id,'Titanium',0);
        testQli.Product2Id=priceBookEntry.Product2Id;
        testQli.Application__c = 'Warehouse';//added by pankaj on 10th april 2023
        testQli.Uptime_Required__c = 2;//added by pankaj on 10th april 2023
        qliToInsert.add(testQli);
        
        //Added by pankaj on 30 nov 2021
        QuoteLineItem qliSequence0Quote12=setQLIValues(10,0,0,priceBookEntry.Id,quote12.Id,'',0);
        qliSequence0Quote12.Product2Id=priceBookEntry.Product2Id;
        qliToInsert.add(qliSequence0Quote12);
        
        QuoteLineItem qliSequence0Quote13=setQLIValues(10,0,0,priceBookEntry2.Id,quote13.Id,'',0);
        qliSequence0Quote13.Product2Id=priceBookEntry2.Product2Id;
        qliToInsert.add(qliSequence0Quote13);
        
        QuoteLineItem qliSequence0Quote14=setQLIValues(6,0,0,priceBookEntry3.Id,quote13.Id,'',0);
        qliSequence0Quote14.Product2Id=priceBookEntry3.Product2Id;
        qliToInsert.add(qliSequence0Quote14);
        
        QuoteLineItem qliSequence0Quote15=setQLIValues(12,0,0,priceBookEntry3.Id,quote13.Id,'',0);
        qliSequence0Quote15.Product2Id=priceBookEntry3.Product2Id;
        qliToInsert.add(qliSequence0Quote15);
        //ended by pankaj
        System.runAs(runningUser){
            test.startTest();
            
            Insert qliToInsert;
            //   List<QuoteLineItem> qLIs=[Select Id From QuoteLineItem where Sequence__c=null];
            //    System.assertNotEquals(0,qLIs.size());
            test.stopTest();
        }
    } 
    
    //Added by Shreela on 15th September 2022
    @isTest
    public static void testpopulateNPPFieldForAppliances(){
        Test.startTest();
        
        //Added by Shreela on 23rd Nov 2022
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.QuoteTriggerDisabled__c = true;
        insert setting; 
        
        Product2 product1 = new Product2(Name = 'Test Product 10', Item__c = '00010', ProductCode = '00010',Commodity_Set__c='SCR18%',Is_Generic_Product__c=true);
        insert product1;        
        
        Discount_Matrix__c dm = new Discount_Matrix__c(Item_Code__c=product1.Id,Area__c='WN1',Stage__c='Active',
                                                       Discount_Amount__c=12000,Channel__c='D2D',
                                                       Discount_Code__c='HA9', Gross_Net__c='2', Level__c='2', 
                                                       Start_Date__c=(date.today()).addDays(-5));
        //Added End and Start Date by Shreela on 23rd Nov 2022
        dm.End_Date__c = System.today();
        dm.Start_Date__c = System.today();
        insert dm;
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'test price book 10', LN_PriceList_Code__c = '010', PriceList_Code__c = '010', 
                                                    IsActive = true
                                                   );
        insert pricebookRecord; 
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Product2Id = product1.Id;
        pbe2.Pricebook2Id = pricebookId;
        pbe2.UnitPrice = 1180.00;
        pbe2.IsActive = true;
        insert pbe2;
        
        
        Account accountRecord = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            .getTestRecord();
        accountRecord.Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        insert accountRecord;
        
        Opportunity objApplOpp1 = new Opportunity(Name = 'Test Appliance', Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,
                                                  Sales_Branch_Name__c='5010',Sales_Zone__c ='EST',StageName ='Probing',Area_Code__c='WN1',
                                                  AccountId = accountRecord.Id,
                                                  RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId(),
                                                  CloseDate = System.today()+1,Sub_Division__c='B2B');
        insert objApplOpp1;  
        
        Quote objApplQuote1 = new Quote(Name='Appl Quote',OpportunityId=objApplOpp1.id,ExpirationDate=System.today()+1,Payment_Terms__c='10',
                                        RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE).getRecordTypeId(),
                                        Dealer_Name__c= Null);
        objApplQuote1.Pricebook2Id=pbe2.Pricebook2Id;
        objApplQuote1.OpportunityId = objApplOpp1.Id;
        objApplQuote1.Area_Code__c='WN1';
        insert objApplQuote1;
        
        
        QuoteLineItem qli2=new TestQuoteLineItemBuilder().setQuoteId(objApplQuote1.Id).setUnitPrice(1000).setSequenceNumber(1).setPriceBookEntryId(pbe2.Id).getTestRecord();
        qli2.Product2Id=pbe2.Product2Id;
        qli2.Requested_Customer_Discount__c=10;
        qli2.Requested_WD_Retention__c=0;
        qli2.Requested_SAC_ORC__c=0;
        qli2.Requested_Dealer_Discount__c=0;
        insert qli2;
        
        
        Test.stopTest();
        
    }
    //Added by Shreela on 20th December 2022
    @isTest
    public static void testupdateCustomerDiscount(){
        
        List<Quote> qRecord = new List<Quote>();
        List<QuoteLineItem> qliRecord = new List<QuoteLineItem>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        insert setting;  
        
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            //setting1.UserTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            //setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);
            
            insert pbeList;
            
            
            //Added Appliance B2B Opportunity by Shreela 
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
            //Added Quote by Shreela 
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote);
            
            insert qRecord;
            
            List<QuoteLineItem> qliRecord3 = new List<QuoteLineItem>();
            List<QuoteLineItem> qliRecordToBeUpdated = new List<QuoteLineItem>();
            for (PricebookEntry pricebookEntryRecord : pbeList) {
              QuoteLineItem qli = new QuoteLineItem();
              qli.QuoteId = applQuote.Id;
              qli.UnitPrice = pricebookEntryRecord.UnitPrice;
              qli.Product2Id = pricebookEntryRecord.Product2Id;
              qli.Quantity = 1;
              qli.PricebookEntryId = pricebookEntryRecord.Id;
              qli.Requested_Customer_Discount__c = 10;
              qli.Requested_CustomerAmount__c = 1800;
              qli.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
              qliRecord3.add(qli);
             }

             // Insert the new QuoteLineItem records
             insert qliRecord3;

            
             // Update the existing QuoteLineItem records
            for (QuoteLineItem qli : qliRecord3) {
                qli.Requested_Customer_Discount__c = 12;                          
                qliRecordToBeUpdated.add(qli);
            }
           
            update qliRecordToBeUpdated;           
 
    
                        
            List<QuoteLineItem> qliRecord2 = [Select Id,Quote.Record_Type_Developer_Name__c,Quote.OpportunityId,Approval_Status__c,Quote_Record_Type__c  from QuoteLineItem where   Quote_Record_Type__c = 'Appliances' Limit 1];
            System.debug('qliRecord.size() qlirptest:'+qliRecord.size());
            System.debug('qliRecord2.size() qlirptest:'+qliRecord2.size());
            qliRecord2[0].Approval_Status__c =GlobalConstants.APPROVED;
            update qliRecord2;
            
            QLIRecordProcessor qlirp = new QLIRecordProcessor();
            qlirp.updateCustomerDiscount(qliRecord,'update');
            Test.stopTest();
            
        }
        
    }
    @isTest
    static void testPopulateRetentionValues() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser1 =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User 1')
            .getTestRecord();        
        runningAdminUser1.IsActive = true;
        insert runningAdminUser1;
        
        User runningAdminUser2 =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User 2')
            .getTestRecord();        
        runningAdminUser2.IsActive = true;
        runningAdminUser2.ManagerId = runningAdminUser1.Id;
        insert runningAdminUser2;
        
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        runningAdminUser.ManagerId = runningAdminUser2.Id;
        insert runningAdminUser;
        System.runAs(runningAdminUser){
            
            SSDRetentions__c retention = new SSDRetentions__c(
                Name = 'Disc+Sal==10', 
                Disc_Sales_Expenses__c = 10, 
                Minimum_Retention__c = 5, 
                Delivery_and_Installation__c = 2
            );
            insert retention;
            
            Runtime_Execution__c setting = new Runtime_Execution__c();
            setting.FireQuoteValidationRules__c = false;
            setting.FireAccountValidationRules__c = false;
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            Test.startTest();
            Product2 product1 = new Product2(Name = 'Test Product 10', Item__c = '00010', ProductCode = '00010',Commodity_Set__c='SCR18%',Is_Generic_Product__c=true);
            insert product1;        
            Discount_Matrix__c dm = new Discount_Matrix__c(Item_Code__c=product1.Id,Area__c='WN1',Stage__c='Active',
                                                           Discount_Amount__c=12000,Channel__c='D2D',
                                                           Discount_Code__c='HA9', Gross_Net__c='2', Level__c='2', 
                                                           Start_Date__c=(date.today()).addDays(5));
            insert dm;
            Pricebook2 pricebookRecord = new Pricebook2(Name = 'test price book 10', LN_PriceList_Code__c = '010', PriceList_Code__c = '010', 
                                                        IsActive = true
                                                       );
            insert pricebookRecord; 
            Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = product1.Id;
            pbe2.Pricebook2Id = pricebookId;
            pbe2.UnitPrice = 1180.00;
            pbe2.IsActive = true;
            insert pbe2;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getTestRecord();
            accountRecord.GSTN__c = '29AABCJ1087G1ZJ';
            accountRecord.Business_Unit__c = GlobalConstants.SSD_BUSINESS_UNIT;
            insert accountRecord;
            
            
            Opportunity Opp = new Opportunity(Name = 'Test Security Solutions', Business_Unit__c = GlobalConstants.SSD_BUSINESS_UNIT,
                                              Sales_Branch_Name__c='5010',Sales_Zone__c ='EST',StageName ='Demand generated',Area_Code__c='WN1',
                                              AccountId = accountRecord.Id,Order_Type__c = 'R series Billing', Booking_Option__c = 'Special Price', Customer_Type_SSD__c = 'BFSI', End_Customer_Segment_SSD__c = 'BNKPSU',
                                              RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSD).getRecordTypeId(),
                                              CloseDate = System.today()+1,Sub_Division__c='B2B',Dealer_Name__c=accountRecord.Id);
            insert Opp;  
            OpportunityLineItem oppProduct1 = new OpportunityLineItem();
            oppProduct1.PricebookEntryId = pbe2.Id;
            oppProduct1.Quantity = 1;
            oppProduct1.UnitPrice = pbe2.UnitPrice;
            oppProduct1.Sequence_Number__c = 1;
            oppProduct1.OpportunityId = opp.Id;
            oppProduct1.Product2Id = pbe2.product2Id;
            insert oppProduct1;
            
            Quote Qvar = new Quote(Name='My Quote',OpportunityId=Opp.id,ExpirationDate=System.today()+1,
                                   RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSD).getRecordTypeId());
            Qvar.Pricebook2Id=pbe2.Pricebook2Id;
            Qvar.OpportunityId = Opp.Id;
            Qvar.Area_Code__c='WN1';
            insert Qvar;
            
            QuoteLineItem lineItem = new TestQuoteLineItemBuilder()
                .setQuoteId(Qvar.Id)
                .setUnitPrice(1000)
                .setPriceBookEntryId(pbe2.Id)
                .getTestRecord();
            lineItem.Product2Id = pbe2.Product2Id;
            lineItem.Requested_Customer_Discount__c = 0;  
            insert lineItem;
            
            QLIRecordProcessor processor = new QLIRecordProcessor();
            processor.populateRetentionValues(new Map<Id, QuoteLineItem>{ lineItem.Id => lineItem }, new Map<Id, QuoteLineItem>());
            Test.stopTest();
            lineItem = [SELECT Min_Retention_SSD__c, Regular_Delivery_and_Installation_SSD__c FROM QuoteLineItem WHERE Id = :lineItem.Id];
        }
    }
        //Added by pankaj on 8th June 2023
    @isTest
    public static void testupdateCustomerDiscount2(){
        
        List<Quote> qRecord = new List<Quote>();
        List<QuoteLineItem> qliRecord = new List<QuoteLineItem>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        insert setting;  
        
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            //setting1.UserTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            //setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);
            
            insert pbeList;
            
            
            //Added Appliance B2B Opportunity by Shreela 
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;
            
           
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote);
            
            insert qRecord;
            
            List<QuoteLineItem> qliRecord3 = new List<QuoteLineItem>();
            List<QuoteLineItem> qliRecordToBeUpdated = new List<QuoteLineItem>();
            for (PricebookEntry pricebookEntryRecord : pbeList) {
              QuoteLineItem qli = new QuoteLineItem();
              qli.QuoteId = applQuote.Id;
              qli.UnitPrice = pricebookEntryRecord.UnitPrice;
              qli.Product2Id = pricebookEntryRecord.Product2Id;
              qli.Quantity = 1;
              qli.PricebookEntryId = pricebookEntryRecord.Id;
              qli.Requested_Customer_Discount__c = 10;              
              qli.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
              qliRecord3.add(qli);
             }          
             insert qliRecord3;   
            
            for (QuoteLineItem qli : qliRecord3) {
                qli.Requested_Customer_Discount_Amount_Unit__c = 1222;                       
                qliRecordToBeUpdated.add(qli);
            }
           
            update qliRecordToBeUpdated;     
            Test.stopTest();
            
        }
        
    }
    
         //Added by pankaj on 8th June 2023
    @isTest
    public static void testupdateCustomerDiscount3(){
        
        List<Quote> qRecord = new List<Quote>();
        List<QuoteLineItem> qliRecord = new List<QuoteLineItem>();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.UserTriggerDisabled__c = true;
        insert setting;  
        
        
        Profile appProfile = [Select Id, Name from Profile where Name ='Appliances Regional Service Manager D2D User' limit 1]; 
        User usrAppl = new User(EmailEncodingKey = 'UTF-8', firstName = 'aAppl tests', lastname = 'User', Alias = 'apltuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = appProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'appltest.user@godrej.com', username = 'appltest.user@godrej.com', 
                                Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT,Persona__c = 'Appliances- Direct Sales Manager (DSM)',
                                Sub_Division__c = 'B2B',Logistic_Company__c = '2000',Area_Code__c = 'WN1',Zone__c= 'MUM',salary_code__c='11223');
        insert usrAppl;
        
        
        System.runAs(usrAppl){
            Test.startTest();
            Runtime_Execution__c setting1 = Runtime_Execution__c.getInstance();
            setting1.AccountTriggerDisabled__c = true;
            setting1.DiscountMatrixTriggerDisabled__c = true;
            setting1.BranchTriggerDisabled__c = true;
            //setting1.UserTriggerDisabled__c = true;
            setting1.PricingApprovalRequestTriggerDisabled__c = true;
            setting1.ProductTriggerDisabled__c = true;
            setting1.OpportunityProductTriggerDisabled__c = true;
            setting1.OpportunityTriggerDisabled__c = true;
            setting1.AddressByBPTriggerDisabled__c = true;
            setting1.QuoteTriggerDisabled__c = true;
            //setting1.QLITriggerDisabled__c = true;
            upsert setting1; 
            
            // Create Product.
            Product2 baseproduct2 = new Product2(Name = 'Test Base Product 2', Item__c = '00002', ProductCode = '00002');
            baseproduct2.Is_Independent_product__c = false;
            baseproduct2.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
            insert baseproduct2;
            
            //Create standardPricebookEntry
            Id pricebookId2 = Test.getStandardPricebookId();
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = pricebookId2, Product2Id = baseproduct2.Id,UnitPrice = 20000, IsActive = true);
            insert standardPrice2;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord2 = new Pricebook2(Name = 'Test Pricebook 2', LN_PriceList_Code__c = '002', PriceList_Code__c = '002', 
                                                         IsActive = true, Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT, 
                                                         Market_Pricelist__c = true);
            insert pricebookRecord2;
            
            // Create PricebookEntry for the above products and pricebook.
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = baseproduct2.Id;
            pbe2.Pricebook2Id = pricebookRecord2.Id;
            pbe2.UnitPrice = 2000.00;
            pbe2.IsActive = true;
            pbeList.add(pbe2);            
            insert pbeList;            
             
            Opportunity oppApplB2BRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setBusinessUnit('H').getTestRecord();
            oppApplB2BRecord.Name = 'Appl B2B Opp record';
            oppApplB2BRecord.Pricebook2Id = pricebookRecord2.Id; 
            oppApplB2BRecord.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
            
            insert oppApplB2BRecord;            
            
            Quote applQuote=new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId())
                .setOpportunityId(oppApplB2BRecord.Id).getTestRecord();
            applQuote.Name = 'Appl B2B Quote record'; 
            applQuote.Status = GlobalConstants.ORDER_DEFAULT_STATUS; 
            applQuote.Pricebook2Id = oppApplB2BRecord.Pricebook2Id; 
            applQuote.Last_Approved_Date__c = System.today()-1 ; 
            qRecord.add(applQuote);
            
            insert qRecord;
            
            List<QuoteLineItem> qliRecord3 = new List<QuoteLineItem>();
            List<QuoteLineItem> qliRecordToBeUpdated = new List<QuoteLineItem>();
            for (PricebookEntry pricebookEntryRecord : pbeList) {
              QuoteLineItem qli = new QuoteLineItem();
              qli.QuoteId = applQuote.Id;
              qli.UnitPrice = pricebookEntryRecord.UnitPrice;
              qli.Product2Id = pricebookEntryRecord.Product2Id;
              qli.Quantity = 1;
              qli.PricebookEntryId = pricebookEntryRecord.Id;
              qli.Requested_Customer_Discount__c = 10;              
              qli.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
              qliRecord3.add(qli);
             }
             
             insert qliRecord3;            
             
            for (QuoteLineItem qli : qliRecord3) {
                qli.Requested_CustomerAmount__c = 1534;                       
                qliRecordToBeUpdated.add(qli);
            }           
            update qliRecordToBeUpdated; 
            Test.stopTest();            
        }
        
    }
}