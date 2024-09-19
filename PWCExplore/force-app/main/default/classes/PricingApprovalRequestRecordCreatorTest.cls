/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for PricingApprovalRequestRecordCreator
Inputs:        NA
Test Class:    
History
11-07-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
@isTest
private class PricingApprovalRequestRecordCreatorTest {
    
    @TestSetup static void createData(){
        Runtime_Execution__c csdata = new Runtime_Execution__c ();
        csdata.AccountTriggerDisabled__c = true;
        csdata.AddressByBPTriggerDisabled__c = true;
        csdata.UserTriggerDisabled__c  = true;
        csdata.ProductTriggerDisabled__c  = true;    
        csdata.ZipCodeRuleTriggerDisabled__c  = true;    
        csdata.AssetTriggerDisabled__c = true;
        csdata.OpportunityProductTriggerDisabled__c = true;
        csdata.OpportunityTriggerDisabled__c = true;
        insert   csdata;
        
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User with manager records.
        
        User level4Manager = createUserRecord(null, 'level4Manager',userProfile.Id);
        User level3Manager = createUserRecord(level4Manager.Id, 'level3Manager',userProfile.Id);
        User level2Manager = createUserRecord(level3Manager.Id, 'level2Manager',userProfile.Id);
        User level1Manager = createUserRecord(level2Manager.Id, 'level1Manager',userProfile.Id);
        User userToRun = createUserRecord(level1Manager.Id, '',userProfile.Id);
        List<User> userList = new List<User>{level4Manager ,level3Manager,level2Manager,level1Manager,userToRun};
            insert userList;
        System.runAs(userToRun) {
            // Create Products.
            Product2 product = createProductRecords();
            insert product;
            
            // Create standard pricebook record for the products created.
            PricebookEntry standardPricebookEntry = createStandardPricebookEntries(product);
            insert standardPricebookEntry;
            
            // Create Pricebook.
            Pricebook2 pricebookRecord = createPricebookRecord();
            insert pricebookRecord;
            
            // Create PricebookEntry for the above products and pricebook.
            PricebookEntry pricebookEntryRecord = createPricebookEntryRecords(product, pricebookRecord);
            insert pricebookEntryRecord;
            
            
            //Inserting reserved chars from custom setting
            Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
            rChar.B2C_character__c = 'A';
            rChar.B2B_Account_Series_Char__c = 'X';
            rChar.B2B_character__c = 'AA';
            
            insert rChar;
            
            //Create Zip Code Data
            ZipCode__c zipCode = new ZipCode__c();
            zipCode.Name = '410002';
            zipCode.CityCode__c = 'PUNE';
            zipCode.City_Name__c = 'PUNE';
            zipCode.StateCode__c = 'MH';
            zipCode.StateName__c = 'Maharashtra';
            zipCode.CountryCode__c = 'IN';   
            zipCode.CountryName__c = 'INDIA';   
            zipCode.ZipCodeExternalId__c = 'IN_410002';
            
            insert zipCode;
            
            
            //Create Address records
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'NUCOVA LIMITED';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.ZipCode__c = zipCode.Id;
            address.Building__C='12345';
            
            insert address;
            
            
            //Create Account
            Test.starttest();
            Account acc = new Account();
            acc.Name = 'NUCOVA LIMITED'; 
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987Z';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = 'K'; //MHE division
            acc.Primary_Address__c = Address.Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            
            insert acc; 
            
            Asset assetRecord = new Asset();
            assetRecord.Name = 'Test Asset record';
            assetRecord.SerialNumber = 'AX001';
            assetRecord.AccountId = acc.Id;
            assetRecord.Address_Code__c = address.id;		//Added by pc
            // assetRecord.Coverage__c = 'KFGWC00600001';
            //assetRecord.Type_of_Warranty__c = 'Special Warranty';
            insert assetRecord;
            
            //Create Opportunity
            Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Qualification');
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId();
            opp.Pricebook2Id = pricebookRecord.Id;
            opp.Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE;
            opp.MHE_Division__c = 'Outright Sales';
            opp.CloseDate = (Date.today()).addMonths(10);
            opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
            
            insert opp;
            
            OpportunityLineItem oppProduct = new OpportunityLineItem();
            oppProduct.PricebookEntryId = pricebookEntryRecord.Id;
            oppProduct.Quantity = 1;
            oppProduct.UnitPrice = pricebookEntryRecord.UnitPrice;
            oppProduct.Sequence_Number__c = 1;
            oppProduct.OpportunityId = opp.Id;
            oppProduct.Asset__c = assetRecord.Id;
            insert oppProduct;
            
            //Create Quote Records
            list<Quote> quoteRecords = new list<Quote>();
            
            for(Integer i = 0; i<2; i++){
                Quote quoteRecord = new Quote();
                quoteRecord.OpportunityId = opp.Id;
                
                if(i == 0){
                    //Create Primary 
                    quoteRecord.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Equipments').getRecordTypeId();
                    quoteRecord.Name = 'Quote -'+ system.today();
                } else {
                    //Create Secondary 
                    quoteRecord.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Parts').getRecordTypeId();
                    quoteRecord.Name = 'Quote sec -'+ system.today();
                    quoteRecord.Transaction_Type__c = GlobalConstants.ORDER_TYPE_SECONDARY;
                }
                quoteRecords.add(quoteRecord);
            }
            
            insert quoteRecords; 
            Test.stoptest();
        }
        
    }
    
    private static Product2 createProductRecords() {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        
        return baseproduct1;
    }
    
    private static PricebookEntry createStandardPricebookEntries(Product2 product) {
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = product.Id,
            UnitPrice = 10000, IsActive = true);
        
        return standardPriceEntry;
    }
    
    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                                    Market_Pricelist__c = true);
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
    
    private static user createUserRecord(Id managerUserId, String userNameAddOnString,Id ProfileId){
        //Fetch System Profile
        
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = ProfileId,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com',  Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userRec.Persona__c = 'MHE Sales-KAM';
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.ManagerId = managerUserId;
        userRec.username = 'test.user5@godrej.com';
        
        if(String.isNotBlank(userNameAddOnString))
            userRec.username = 'test.user5@godrej.com.'+userNameAddOnString;
        
        //insert userRec;        
        return userRec;
    }
    
    static testMethod void test_createPricingApprovalRequestRecord(){
        User contextuser = [Select Id FROM User WHERE username = 'test.user5@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            List<Quote> quotes = [Select Id, RecordTypeId, CreatedById, Record_Type_Developer_Name__c,
                                  Transaction_Type__c, OpportunityId  
                                  FROM Quote];
            Test.startTest();
            PricingApprovalRequestRecordCreator parCreator = new PricingApprovalRequestRecordCreator();
            parCreator.createPricingApprovalRequestRecord(quotes);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id FROM Pricing_approval_request__c WHERE Quote__c IN :quotes];
            System.assertEquals(quotes.size(), pars.size());
            
        }
    }
    
    static testMethod void test_createPricingApprovalRequestRecordException(){
        boolean exceptionOccurred;
        User contextuser = [Select Id FROM User WHERE username = 'test.user5@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            
            Test.startTest();
            PricingApprovalRequestRecordCreator parCreator = new PricingApprovalRequestRecordCreator();
            try{
                parCreator.createPricingApprovalRequestRecord(null); 
            }catch(Exception ex){
                system.debug('=====ex============'+ex.getMessage());
                exceptionOccurred = ex.getMessage().contains('Attempt to de-reference a null object') ? true : false;
            }
            
            Test.stopTest();
            System.assertEquals(exceptionOccurred, true);
        }
    }
    
}