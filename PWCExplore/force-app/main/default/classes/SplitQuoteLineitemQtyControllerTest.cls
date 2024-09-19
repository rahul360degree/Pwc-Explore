/*------------------------------------------------------------------------
Author:        Anupam Mishra && Varun Rajpoot
Description:   Test class for SplitQuoteLineitemQtyController
Date       :   05-06-2022
----------------------------------------------------------------------------*/

@isTest
public class SplitQuoteLineitemQtyControllerTest {
    
    @TestSetup 
    static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'LocksHoTeamUser', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT);  
        userToRun.Persona__c = 'Locks-Ho Team';
        userToRun.LastName='Admin User';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '1400';
        userToRun.Area_Code__c = 'HZ1';
        userToRun.Salary_Code__c = '001100';
        insert userToRun; 
        
        System.runAs(userToRun) {
            
            //added by mrunali 28-11-2022
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
                
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 locksPriceBook = new PriceBook2(Name = 'LC2_3000 / LOCKS B2B', IsActive = true, LN_PriceList_Code__c = 'LC2', PriceList_Code__c = 'LC2');
            insert locksPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('DC 3145 CL PC K 60mm A').setDescription('DC 3145 CL PC K 60mm A').setItemCode('5808').getTestRecord(),
                    new TestProductBuilder().setName('10 Duo Superbolt SUPERBOLT').setItemCode('567').setDescription('GX 300 Forklift Attachment').getTestRecord(),
                    new TestProductBuilder().setName('12 Duo Superbolt SUPERBOLT').setItemCode('6789').setDescription('12 Duo Superbolt SUPERBOLT').getTestRecord(),
                    new TestProductBuilder().setName('DC 3145 CL PC K 60').setItemCode('9098').setDescription('DC 3145 CL PC K 60').getTestRecord(),
                    new TestProductBuilder().setName('DD 3145 CL PC K 60').setItemCode('8765').setDescription('DD 3145 CL PC K 60').getTestRecord()
                    };
                        insert allProducts;
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(locksPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(locksPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(locksPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(locksPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(locksPriceBook.Id).setUnitPrice(32000).getTestRecord()
                    };
                        insert allPBEs;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId())
                .getSavedTestRecord();
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getTestRecord();
            QuoteRecord.Pricebook2Id =locksPriceBook.Id;
            quoteRecord.Disable_PC_Sync__c=false;
            quoteRecord.Delivery_Type__c = 'Branch Billing';
            quoteRecord.Expected_Date_of_Delivery__c = Date.today().addMonths(4);
            quoteRecord.Branch_Locks_B2B__c = 'Bangalore';
            quoteRecord.Channel__c = 'B2B';
            quoteRecord.Segment__c = 'Logistics';
            quoteRecord.Remarks__c = 'Test';
            quoteRecord.Special_remarks__c = 'Test';
            quoteRecord.Agreed_by_customer__c = True;
            insert QuoteRecord;
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).getTestRecord()
                    };
                        allQLI[0].Product2Id = allProducts[0].Id;
            allQLI[0].Status__c = 'Won';
            insert allQLI;
            
            Blob bodyBlob=Blob.valueOf('Dummy Body'); 
            
            ContentVersion contentVersion = new ContentVersion(
                Title='Payment', 
                PathOnClient ='SampleTitle.pdf',
                VersionData = bodyBlob, 
                origin = 'H',
                Type__c ='PO'
            );
            
            insert contentVersion;
            contentVersion = [SELECT Id, Title, ContentDocumentId 
                              FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId =quoteRecord.id;
            contentlink.contentdocumentid = contentVersion.contentdocumentid;
            contentlink.ShareType = 'V';
            
            insert contentlink;
        }
    }
    //Method to test getQuoteLineItemsFromQuoteRecId
    @isTest private static void testGetQuoteLineItemsFromQuoteRecId(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        List<QuoteLineItem> qLIlist = SplitQuoteLineitemQtyController.getQuoteLineItemFromQuote(quoteRecord.id);
        SplitQuoteLineitemQtyController.ContentDocumentLinkFn(quoteRecord.id);
        System.assert(qLIlist.size() > 0);
        Test.stopTest();
    }
    
    @isTest private static void testGetQuoteLineItemsFromQuoteRecId_ExceptionHandling(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        try{
            delete [Select Id from ContentDocument limit 1];
            quoteRecord.Disable_PC_Sync__c = true;
            quoteRecord.Expected_Date_of_Delivery__c = null;
            quoteRecord.Branch_Locks_B2B__c = null;
            quoteRecord.Channel__c = null;
            quoteRecord.Segment__c = null;
            quoteRecord.Remarks__c = null;
            quoteRecord.Special_Remarks__c = null;
            update quoteRecord;
            List<QuoteLineItem> qLIlist = SplitQuoteLineitemQtyController.getQuoteLineItemFromQuote(quoteRecord.id);
            SplitQuoteLineitemQtyController.ContentDocumentLinkFn(quoteRecord.id);
            System.assert(qLIlist.size() > 0);
        }catch(Exception ex){
            
        }
        Test.stopTest();
        
    }
    
    @isTest private static void testDisablePCSync(){
        Boolean errorOccurred = false;
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c FROM Quote LIMIT 1];
        Test.startTest();
        try{
            quoteRecord.Disable_PC_Sync__c= true;
            update quoteRecord;
            
            SplitQuoteLineitemQtyController.getQuoteLineItemFromQuote(quoteRecord.id);
        } catch(Exception ex){
            errorOccurred = true;
        }
        System.assert(errorOccurred == true);  
        Test.stopTest();
    } 
    
    
    @isTest private static void testDisablePCSync_tryCatchCover(){
        Boolean errorOccurred = false;
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c FROM Quote LIMIT 1];
        
        Test.startTest();
        try{
            delete [Select Id from QuoteLineItem limit 1000];
            SplitQuoteLineitemQtyController.getQuoteLineItemFromQuote(quoteRecord.id);
        } catch(Exception ex){
            errorOccurred = true;
        }
        System.assert(errorOccurred == true);  
        Test.stopTest();
    } 
    
    
    
    @isTest private static void testdisableEnableQuoteSync(){
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        SplitQuoteLineitemQtyController.disableEnableQuoteSync(quoteRecord.id,'Test');
        Test.stopTest();
    }
    
    @isTest private static void testdisableEnableQuoteSync_TryCatch(){
        try{
            Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c, PriceBook2Id FROM Quote LIMIT 1];
            Test.startTest();
            quoteRecord.ExpirationDate = date.today().addDays(-1);
            update quoteRecord;
            
            Runtime_Execution__c cs = new Runtime_Execution__c();
            cs.FireQuoteValidationRules__c = true;
            insert cs;
            SplitQuoteLineitemQtyController.disableEnableQuoteSync(quoteRecord.id,'true');
            Test.stopTest();
        }catch(Exception ex){
        }
    }
    
    
    @isTest private static void testsyncRecord(){
        Test.startTest();
        User adminUser = [Select Id,Name,LastName,Salary_Code__c From User where LastName='Admin User' Limit 1];  
        System.runAs(adminUser){        
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c, PriceBook2Id FROM Quote LIMIT 1];
        Boolean errorOccurred = false;
        List<QuoteLineItem> qLIList =[select 
                                      Id,Product_Name__c,Remaining_Quantity__c,Previous_Split_Quantitiy__c,
                                      Search_Key_II__c, Item_Code__c,Quantity,MRP__c,Ordered_Quantity__c,
                                      UnitPrice, Discount__c
                                      from QuotelineItem where QuoteID =:quoteRecord.Id limit 1];   
        
        try{
            Test.setMock(HttpCalloutMock.class, new MockFocResponseGenerator()); 
            SplitQuoteLineitemQtyController.syncRecord(qLIList,quoteRecord.id,'Test');
            String abc = 'Q9+qJ2TKbwFl5Y7IH3ZTrM9Erq5sTVJrbJLkFIMMC9/BMQljEwpDXfHBStAYjQz+qRBRaP7Ui0kktdwEjA/w7e6OAsJra9MzR5USJ//dfugm7VaDtCvIr60LRLFMrWXYS7HxnSln6YM4ph2VUdH37gXY01pJl6Dc78UODpmzgWM=';
            SplitQuoteLineitemQtyController.parseLWCCalloutResponse(abc);
        } catch(Exception ex){
        }
        }
        Test.stopTest();
    }
    
    @isTest private static void testupdateQuoteAndLineItem(){
        Test.startTest();
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c, PriceBook2Id FROM Quote LIMIT 1];
        Boolean errorOccurred = false;
        List<QuoteLineItem> qLIList =[select Id,QuoteId,Unitprice from QuotelineItem where QuoteID =:quoteRecord.Id limit 1];
        
        try{
            SplitQuoteLineitemQtyController.updateQuoteAndLineItem(qLIList,quoteRecord.id,'Test','Test2');
            
        } catch(Exception ex){
            errorOccurred = true;
        }
        Test.stopTest();
        
    }
    
    
    @isTest private static void testupdateQuoteAndLineItem_TryCatch(){
        Test.startTest();
        Quote quoteRecord = [SELECT Id,Disable_PC_Sync__c, PriceBook2Id FROM Quote LIMIT 1];
        List<QuoteLineItem> qLIList =[select Id,QuoteId,Unitprice from QuotelineItem where QuoteID =:quoteRecord.Id limit 1];
        try{
            
            Runtime_Execution__c obj = new Runtime_Execution__c();
            obj.FireQLIValidationRules__c = true;
            insert obj;
            
            qLIList[0].Contract_End_Date__c = Date.today().addDays(-5);
            SplitQuoteLineitemQtyController.updateQuoteAndLineItem(qLIList,quoteRecord.id,'Test','Test2');
        } catch(Exception ex){
        }
        Test.stopTest();
        
    }
    
    @isTest 
    private static void ProductConfig_QuoteJson_Test(){
        ProductConfig_QuoteJson jsonParser = new ProductConfig_QuoteJson();
        jsonParser.customerCode = 'Test';
        jsonParser.billingAddress = 'Test';
        jsonParser.deliveryAddress = 'Test';
        jsonParser.customerOrderNumber = 'Test';
        jsonParser.vertical = 'Test';
        jsonParser.branchWarehouse = 'Test';
        jsonParser.customerExpDelDate = 'Test';
        jsonParser.aidNumber = 'Test';
        jsonParser.commentsHO = 'Test';
        jsonParser.commentsMFG = 'Test';
        jsonParser.user = 'Test';
        jsonParser.channel = 'Test';
        jsonParser.sfQuotationID = 'Test';
        jsonParser.sfQuotationPos = 'Test';
        jsonParser.remarks = 'Test';
        jsonParser.deliveryType = 'Test';
        
        ProductConfig_QuoteJson.ProductDetails wrapper = new ProductConfig_QuoteJson.ProductDetails();
        wrapper.productCode = 'Test';
        wrapper.unspscCode = 'Test';
        wrapper.qty = 'Test';
        wrapper.mrp = 'Test';
        wrapper.basic = 'Test';
        wrapper.discPerc = 'Test';
        wrapper.remarks = 'Test';
        jsonParser.productDetails = new List<ProductConfig_QuoteJson.ProductDetails>{wrapper};
            
            String JSON = JSON.serialize(jsonParser);
        ProductConfig_QuoteJson.parse(JSON);
        Blob bodyBlob=Blob.valueOf('Dummy Body'); 
        Generic_HTTPCalloutService obj = new Generic_HTTPCalloutService();
        obj.setRequestTimeout(2000);
        obj.setRequestBody(bodyBlob);
    }
    
    
}