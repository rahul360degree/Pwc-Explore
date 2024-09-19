@isTest
public class IsobControllerTest {
    @TestSetup
    Public static void createData(){
        Test.startTest();
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.QLITriggerDisabled__c = true;
        Insert setting;
        
        //Create Account Record
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        Account accObj = new Account();
        accObj.Name = 'Test ISOB Account';
        accObj.Business_Unit__c = 'G';
        accObj.RecordTypeId = AccountRecordTypeId;
        Insert accObj;
        
        //Create Opportunity Record
        Id OpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('SSG').getRecordTypeId();       
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test ISOB Opportunity';
        oppObj.RecordTypeId = OpportunityRecordTypeId;
        oppObj.StageName = 'Qualification';
        oppObj.CloseDate = System.today();
        insert oppObj;
        
        //Create Standard PriceBook Record       
         PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
         update standardPriceBook;
         
        //Create SSG PriceBook Record 
        PriceBook2 SSGPriceBook = new PriceBook2(Name = 'SSG Pricebook', IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
        insert SSGPriceBook;
            
        //Create Product Record 
         List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord(),
                new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').getTestRecord(),
                new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').getTestRecord(),
                new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').getTestRecord()
         };
         insert allProducts;
    
        //Create PriceBookEntry Record 
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
        	new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(SSGPriceBook.Id).setUnitPrice(50000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(SSGPriceBook.Id).setUnitPrice(3000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(SSGPriceBook.Id).setUnitPrice(30000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(SSGPriceBook.Id).setUnitPrice(32000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(SSGPriceBook.Id).setUnitPrice(32000).getTestRecord()
        };
        insert allPBEs;
        
        //Create Quote Record
        Quote quoteObj = new Quote();
        quoteObj.Name = 'Test ISOB Quote';
        quoteObj.OpportunityId = oppObj.Id;
        quoteObj.Pricebook2Id = SSGPriceBook.Id;
        Insert quoteObj;
        
         //Create Quote Line Item Record
        QuoteLineItem qliObj  = new QuoteLineItem();
        qliObj.product2Id = allProducts[0].Id;
        qliObj.QuoteId = quoteObj.Id;
        qliObj.Quantity = 1;
        qliObj.PricebookEntryId = allPBEs[0].Id;
        qliObj.UnitPrice = 10000;
        Insert qliObj;
        
        //Create Order Record
        Order orderObj = new Order();
        orderObj.Business_Unit__c = 'G';
        orderObj.OpportunityId = oppObj.Id;
        orderObj.QuoteId = quoteObj.Id;
        orderObj.AccountId = accObj.Id;
        insert orderObj; 
        
        //Create Order Specification Record
        Order_Specification__c ordSpecObj = new Order_Specification__c();
        ordSpecObj.Quote__c = quoteObj.Id;
        ordSpecObj.Order__c = orderObj.Id;
        Insert ordSpecObj;

        Test.stopTest();
    }
    
    @isTest
    Public static void testMethod1(){
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test ISOB Quote' LIMIT 1];
        List<Id> lstQuoteId = new List<Id>();
        lstQuoteId.add(quote.Id);
        IsobController.getProductSpecifications(quote.Id);       
        IsobController.updateJsonField(quote.Id,'test');
        IsobController.jsonMerger(lstQuoteId);
    }
    
    @isTest
    Public static void testMethod2(){
        Order orderObj = [SELECT Id FROM Order];
        IsobController.getProductSpecifications(orderObj.Id);
        IsobController.getOrderSpecificationDetails(orderObj.Id);
    }	
}