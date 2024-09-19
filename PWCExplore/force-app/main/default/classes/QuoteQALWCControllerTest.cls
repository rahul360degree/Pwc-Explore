/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for QuoteQALWCController
Inputs:            

----------------------------------------------------------------------------*/
@isTest
public class QuoteQALWCControllerTest {
	
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
        
        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
            insert setting; //Added trigger disable by Dipti on 19th October 2022 for resolving 101 error issue in prod
        
            //Create Plan Record
            Plan__c plan = new Plan__c();
            plan.Name = 'Diamond';
            plan.BD_Visits_Number__c = 4; 
            plan.Scheduled_PM_Visits_Number__c =5;
            plan.Plan_Type__c = 'Basic';
            plan.Is_Active__c = true;
            plan.Plan_Identifier__c = 'Diamond';
            plan.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
             
            insert plan;
            
            
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
                allProducts[0].Plan_Type__c = 'Diamond';
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
            
            //Create Address Record			//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
            
            //Create Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'testAsset';
            newAsset.AccountId = accountRecord.id;
            newAsset.Address_Code__c = address.id;		//Added by pc
            newAsset.Status = 'Unregistered';  
            newAsset.Product_Purchased_Warranty_Start_Date__c = system.now().addDays(-35);
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(12);
            newAsset.Coverage__c = 'KFTWC01200001';
        	newAsset.Type_of_Warranty__c = 'Special Warranty';
            newAsset.Date_of_Commissioning__c = System.today();
            newAsset.Product_Sub_Category__c = 'Medium Diesel';
            newAsset.Equipment_Category__c = 'CB-D';
            newAsset.Product_Category__c = ' Counterbalanced Diesel';
            newAsset.Product_Family__c = 'Equipment';
            newAsset.zip_code__c = '400001';  
            insert newAsset;
    
            newAsset.Status = 'Active';  
            update newAsset;
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setAccountId(accountRecord.id).getSavedTestRecord();
                
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
            
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).setAssetId(newAsset.Id).getTestRecord()
            };
            allQLI[0].Product2Id = allProducts[0].Id;
            insert allQLI;
            
            //Create Asset Benefit record
            Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
            newAssetBenefit.Name= 'Diamond';
            newAssetBenefit.Asset__c = newAsset.id;
            newAssetBenefit.Is_Active__c = true; 
            newAssetBenefit.Plan__c = plan.Id;
            newAssetBenefit.Quote_Line_Item__c = allQLI[0].Id;
            newAssetBenefit.BD_Visits_Number__c = plan.BD_Visits_Number__c;
            newAssetBenefit.Scheduled_PM_Visits_Number__c = plan.Scheduled_PM_Visits_Number__c;
            insert newAssetBenefit;
        }
    }
    
    //Method to test getQuoteLineItemsFromQuoteRecId
    @isTest private static void testGetQuoteLineItemsFromQuoteRecId(){
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        Test.startTest();
        	List<QuoteQALWCController.LineItemInitWrapper> wrapperlist = QuoteQALWCController.getQuoteLineItemsFromQuoteRecId(quoteRecord.id);
        	System.assert(wrapperlist.size() > 0);
        Test.stopTest();
    }
    
    //Method to test getQuoteLineItemsFromQuoteRecId
    @isTest private static void testSaveQuoteLineItems(){
        
        Boolean errorOccurred = false;
        list<QuoteQALWCController.LineItemWrapper> lineItemWrappers = new list<QuoteQALWCController.LineItemWrapper>();
        
        Account acc =[SELECT Id From Account LIMIT 1];
        QuoteLineItem qli = [SELECT Id, Asset__c FROM QuoteLineItem LIMIT 1];
        list<Plan__c> plans = [SELECT Id FROM Plan__c LIMIT 1 ];
        Asset selectedAsset = [SELECT Id FROM Asset LIMIT 1];

        Test.startTest();
        Address__c add = [select id from Address__c where Name__c = 'Nuvoco Plant Pune' LIMIT 1];		//Added by pc
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'Asset 2';
        newAsset.AccountId = acc.id;
        newAsset.Address_Code__c = add.id;		//Added by pc
        newAsset.Status = 'Active';
        newAsset.Product_Purchased_Warranty_Start_Date__c = system.now().addDays(-35);
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(12);
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        insert newAsset;
        
        //Create Asset Benefit record
        Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
        newAssetBenefit.Name= 'Gold';
        newAssetBenefit.Asset__c = newAsset.id;
        newAssetBenefit.Is_Active__c = true; 
        newAssetBenefit.Plan__c = plans[0].Id;
        newAssetBenefit.Quote_Line_Item__c = qli.Id;
        insert newAssetBenefit;
        
        //update asset on QLI
        QuoteLineItem qliToUpdate = new QuoteLineItem(Id =qli.Id, Asset__c= newAsset.Id);
        update qliToUpdate;
        
        lineItemWrappers.add(new QuoteQALWCController.LineItemWrapper(qli.Id, new list<Id>{plans[0].Id}, selectedAsset.Id));
        
        try{
            QuoteQALWCController.saveQuoteLineItems(lineItemWrappers);
            errorOccurred = false;
        } catch(Exception ex){
            errorOccurred = true;
        }
        Test.stopTest();
        System.assert(errorOccurred == false);
    }
    
    //Method to test handleCancel
    @isTest private static void testHandleCancel(){
        Test.startTest();
        Boolean errorOccurred = false;
        Quote quoteRecord = [SELECT Id, PriceBook2Id FROM Quote LIMIT 1];
        
        Account acc =[SELECT Id From Account LIMIT 1];
        QuoteLineItem qli = [SELECT Id, Asset__c FROM QuoteLineItem LIMIT 1];
        list<Plan__c> plans = [SELECT Id FROM Plan__c LIMIT 1 ];
        Asset selectedAsset = [SELECT Id FROM Asset LIMIT 1];
        
       
        Address__c add = [select id from Address__c where Name__c = 'Nuvoco Plant Pune' LIMIT 1];		//Added by pc
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'Asset 2';
        newAsset.AccountId = acc.id;
        newAsset.Address_Code__c = add.id;		//added by pc
        newAsset.Status = 'Active';
        newAsset.Product_Purchased_Warranty_Start_Date__c = system.now().addDays(-35);
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(12);
        newAsset.Coverage__c = 'KFTWC01200001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        insert newAsset;
        
        //Create Asset Benefit record
        Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
        newAssetBenefit.Name= 'Gold';
        newAssetBenefit.Asset__c = newAsset.id;
        newAssetBenefit.Is_Active__c = true; 
        newAssetBenefit.Plan__c = plans[0].Id;
        newAssetBenefit.Quote_Line_Item__c = qli.Id;
        insert newAssetBenefit;
        
        //update asset on QLI
        QuoteLineItem qliToUpdate = new QuoteLineItem(Id =qli.Id, Asset__c= newAsset.Id);
        update qliToUpdate;
        
        
        try{
            QuoteQALWCController.handleCancel(quoteRecord.Id);
            errorOccurred = false;
        } catch(Exception ex){
            errorOccurred = true;
        }
        
        system.assert(errorOccurred == false);
        Test.stopTest();
    }
    
    
    //Method to test getPlanSelectionComponentColumns
    @isTest private static void testGetPlanSelectionComponentColumns(){
        Test.startTest();
        	List<QuoteQALWCController.PlanSelectionColumnWrapper> planSelectionColWrapper = QuoteQALWCController.getPlanSelectionComponentColumns();
        	System.assert(planSelectionColWrapper.size() > 0);
        Test.stopTest();
    }
    
    //Method to test getAssetBenefitComponentColumns
    @isTest private static void testGetAssetBenefitComponentColumns(){
        Test.startTest();
        	List<QuoteQALWCController.PlanSelectionColumnWrapper> assetBenefitColWrapper = QuoteQALWCController.getAssetBenefitComponentColumns();
        	System.assert(assetBenefitColWrapper.size() > 0);
        Test.stopTest();
    }
    
    //Method to test getLineItemColumns
    @isTest private static void testGetLineItemColumns(){
        Test.startTest();
        	List<QuoteQALWCController.PlanSelectionColumnWrapper> lineItemColWrapper = QuoteQALWCController.getLineItemColumns();
        	System.assert(lineItemColWrapper.size() > 0);
        Test.stopTest();
    }
    
    //Method to test getAllPlansForLineItem
    @isTest private static void testGetAllPlansForLineItem(){
        Test.startTest();
            QuoteLineItem qli = [SELECT Id, Asset__c FROM QuoteLineItem LIMIT 1];
            Asset selectedAsset = [SELECT Id FROM Asset LIMIT 1];
            
            List<QuoteQALWCController.AssetBenefitWrapper> assetBenefitWrapper = QuoteQALWCController.getAllPlansForLineItem(qli.Id, selectedAsset.Id);
        	System.assert(assetBenefitWrapper.size() > 0);
        
        Test.stopTest();
    }
    
    //Method to test saveSelectedPlans
    @isTest private static void testSaveSelectedPlans(){
        Boolean errorOccurred = false;
        QuoteLineItem qli = [SELECT Id, Asset__c FROM QuoteLineItem LIMIT 1];
        Asset selectedAsset = [SELECT Id FROM Asset LIMIT 1];        
        Asset_Benefit__c selectedAssetBenefit =[SELECT Id, Name, Plan__c, Plan__r.Name, Plan__r.BD_Visits_Number__c, Quote_Line_Item__c, Scheduled_PM_Visits_Number__c, BD_Visits_Number__c 
                                                		FROM Asset_Benefit__c LIMIT 1];
        Test.startTest();
        
        //Create Plan Record
        Plan__c plan = new Plan__c();
        plan.Name = 'Gold';
        plan.BD_Visits_Number__c = 5; 
        plan.Scheduled_PM_Visits_Number__c =5;
        plan.Plan_Type__c = 'Basic';
        plan.Is_Active__c = true;
        plan.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
        
        insert plan;
        
        
        try{
            QuoteQALWCController.saveSelectedPlans(new List<SObject>{plan, selectedAssetBenefit}, qli.Id, selectedAsset.Id);
            errorOccurred = false;
        } catch(Exception ex){
            errorOccurred = true;
        }
       // system.assert(errorOccurred == false);

        Test.stopTest();
    }
    
    //Method to test isQuoteFinalized
    @isTest private static void testIsQuoteFinalized(){
        Quote quoteRecord = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        	Boolean isFinalized = QuoteQALWCController.isQuoteFinalized(quoteRecord.id);
        	System.assert(isFinalized == false);
        Test.stopTest();
    }
    
    //Method to test getselectOptions
    @isTest private static void testGetselectOptions(){
        Test.startTest();
        	map <String, String> options = QuoteQALWCController.getselectOptions(new Asset(), 'Status');
        	System.assert(!options.isEmpty());
        Test.stopTest();
    }
    
    //Method to test finalizeQuote
    @isTest private static void testQuoteFinalize(){
        Quote quoteRecord = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        	Boolean isFinalized = QuoteQALWCController.finalizeQuote(quoteRecord.id);
        	System.assert(isFinalized == true);
        Test.stopTest();
    }
    
    //Method to test finalizeQuote With CLI
    @isTest private static void testQuoteFinalizeWithCLI(){
        Boolean errorOccurred = false;
        Quote quoteRecord = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        try{
           	ServiceContract serviceContractObj = ServiceContractManager.createServiceContract(quoteRecord.id);
        	Boolean isFinalized = QuoteQALWCController.finalizeQuote(quoteRecord.id);
        } catch(Exception ex){
            errorOccurred = true;
        }
        	System.assert(errorOccurred == true);
        Test.stopTest();
    }
    
    //Method to test addDefaultBenefits
    @isTest private static void testAddDefaultBenefits(){
        Quote quoteRecord = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        Boolean defaultBenefitAdded = QuoteQALWCController.addDefaultBenefits(quoteRecord.id);
        System.assert(defaultBenefitAdded == false);
        Test.stopTest();
    }
    
    //Method to test addDefaultBenefits without Asset Benefits
    @isTest private static void testAddDefaultBenefits2(){
        Boolean defaultBenefitAdded = false;
        Quote quoteRecord = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id, Asset__c FROM QuoteLineItem WHERE QuoteId =: quoteRecord.id LIMIT 1];
        list<Asset_Benefit__c> assetBenefits =[SELECT Id, Name   
                                                		FROM Asset_Benefit__c WHERE Quote_Line_Item__c =: qli.Id LIMIT 1];
        
        Test.startTest();
        try{
            delete assetBenefits;
        	defaultBenefitAdded = QuoteQALWCController.addDefaultBenefits(quoteRecord.id);
        } catch(Exception ex){
            defaultBenefitAdded = false;
        }
        
        System.assert(defaultBenefitAdded == true);
        Test.stopTest();
    }
    
    
    
}