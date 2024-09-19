/*------------------------------------------------------------------------------------
 * Author        :        Nupoor
 * Company       :        Salesforce
 * Description   :        Test class for SoldToPricebookUtility
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 10-07-2020      Nupoor Sharma     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class SoldToPricebookUtilityTest {
    
    @TestSetup static void createData(){
        
         Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'UserServiceContract', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userSTPBUT@godrej.com', username = 'test.userSTPBUT@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
       	Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = true;
            setting.Fire_Address_Validation_Rules__c = false;
            insert setting;
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
    
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            PriceBook2 contractPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Contract_PB, IsActive = true, LN_PriceList_Code__c = 'CON', PriceList_Code__c = 'CON');
            insert contractPriceBook;
            
            PriceBook2 eqqPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Equipment_PB, IsActive = true, LN_PriceList_Code__c = 'EQQ', PriceList_Code__c = 'EQQ');
            insert eqqPriceBook;
    
            PriceBook2 consumerPriceBook = new PriceBook2(Name = 'Consumer sample', IsActive = true,Business_Unit__c = 'K', LN_PriceList_Code__c = 'dM1', PriceList_Code__c = 'dM1', Consumer_Pricelist__c = TRUE);
            insert consumerPriceBook;
            
            PriceBook2 marketPriceBook = new PriceBook2(Name = 'Market Sample', IsActive = true,Business_Unit__c = 'K', LN_PriceList_Code__c = 'dM2', PriceList_Code__c = 'dM2', Market_Pricelist__c = TRUE);
            insert marketPriceBook;
    
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
                .setBusinessUnit('K')
                .setName('firstaddress SoldToPricebookUtility')
                .setPanNumber('ABDFR1234R').getSavedTestRecord();
            
            Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B');
            insert firstaddress;
            
            Branch__c firstBranch = new Branch__c(Branch_Name__c = '5010', Business_Partner__c  = accountRecord.Id, Sales_Price_List__c = rentalPriceBook.Id, Sold_To_Address__c = firstaddress.Id );
            insert firstBranch;
            
            Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id, Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, 
                                                                     Branch__c = firstBranch.Id, Ship_To__c = TRUE, Sold_To__c  = TRUE);
            insert firstAddressByBp;
            
            //Tax record for PAN
            Tax_Number__c taxPAN = new Tax_Number__c();
            taxPAN.Business_Partner__c = accountRecord.Id;
            taxPAN.Country__c = 'IND';
            taxPAN.Tax_Number__c = 'AASCS6585A';
            taxPAN.Category__c = 'PAN';
            taxPAN.Un_registered__c = 'No';
            taxPAN.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            //Need to insert Tax record for PAN before GST or validation error
            insert taxPAN;
            
            Tax_Number__c firstTaxNumber = new Tax_Number__c(Business_Partner__c =accountRecord.Id, Category__c = 'GSTIN', Tax_Number__c = '23AASCS6585A23D');
            insert firstTaxNumber;
            
    
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setMHEDivision('Godrej RenTRUST').setBusinessUnit('K')
                .setAccountId(accountRecord.Id).getSavedTestRecord();
            
          /*  Opportunity oppRecordEq = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                .setMHEDivision('Equipment Rental').setBusinessUnit('K')
                .setAccountId(accountRecord.Id).getSavedTestRecord();
            oppRecordEq.Name ='Equipement';
            update oppRecordEq;
            
              Opportunity oppRecordCon = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                .setMHEDivision('Contracts').setBusinessUnit('K')
                .setAccountId(accountRecord.Id).getSavedTestRecord();
              oppRecordCon.Name ='Contracts';
              update oppRecordCon; */
    
    
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getSavedTestRecord();
            quoteRecord.Pricebook2Id=rentalPriceBook.Id;
            quoteRecord.Sales_Branch_Name__c = '5010';
            update quoteRecord;
    
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
    
    private static List<Order> createOrderRecords(Integer noOfRecords, Account accountRecord, Opportunity opportunityRecord, User u) {
        List<Order> orderRecords = new List<Order>();
        for(Integer i=1; i<=noOfRecords; i++) {
            Order orderRecord = new Order();
            orderRecord.AccountId = accountRecord.Id;
            orderRecord.OpportunityId = opportunityRecord.Id;
            orderRecord.Business_Unit__c = 'K';
            orderRecord.Logistics_Company_Branch__c = '5010';
            orderRecord.Sold_to_Business_Partner__c = accountRecord.Id;
            orderRecord.Record_Types__c = 'MHE Order - Primary';
            orderRecord.Order_Amount__c = 100000 + (1000*i) + 350.75;
            orderRecord.EffectiveDate = Date.today();
            orderRecord.Status = 'Draft';
            orderRecords.add(orderRecord);
        }
        return orderRecords;
    }

    
    @isTest private static void testSetSoldtoShiptoAtQuoteAtInsert() {
        Test.startTest();
        Map<Id, Quote> mapQuote = new Map<Id, Quote>([Select Id, AccountId, OpportunityId, Opportunity_Owner__c, Transaction_type__c,Sales_Branch_Name__c, 
                                                      Sold_To_Business_Partner__c,Invoice_To__c,Invoice_To_Address__c, Ship_To_Account__c, Ship_To_Address__c, Sold_to_Address__c 
                                                      from Quote ]);
        List<Opportunity> oppList = new List<Opportunity>([Select Id from Opportunity ]);
        oppList[0].Sales_Branch_Name__c = '5010';
        update oppList[0];
        List<Account> accList = new List<Account>([Select Id From Account]);
        
        //Test.startTest();
        SoldToPricebookUtility.setSoldtoShiptoAtQuote(mapQuote.values(), null);
        Test.stopTest();
        
        for(Quote q : mapQuote.values()){
            System.assertEquals(NULL, q.Ship_To_Address__c, 'Ship to address should be populated');
        }

    }
    
    @isTest private static void testSetSoldtoShiptoAtQuoteAtUpdate() {
        Test.startTest();
        Map<Id, Quote> mapQuote = new Map<Id, Quote>([Select Id, AccountId, OpportunityId, Opportunity_Owner__c, Transaction_type__c, Associated_Dealer__c,
                                                      Sold_To_Business_Partner__c,Invoice_To__c,Invoice_To_Address__c, Ship_To_Account__c, Ship_To_Address__c, 
                                                      Sold_to_Address__c from Quote]);
                                                     
        List<Opportunity> oppList = new List<Opportunity>([Select Id from Opportunity]);
        oppList[0].Sales_Branch_Name__c = '5010';
        update oppList[0];
        List<Account> accList = new List<Account>([Select Id From Account]);
        
        for(Quote q : mapQuote.values())
        {
            // just 1 quote record in the list
            q.Transaction_type__c = 'Equipment with crew';
            update q;
        }
        
        for(Quote q : [Select Id, Associated_Dealer__c From Quote ]){
            System.assertEquals(NULL, q.Associated_Dealer__c, 'Associated Dealer should be populated');
        }
        Test.stopTest();

    }

    @isTest private static void testSetDefaultAtOrderB2B() {
        Account accountRecord = [Select Id from Account Limit 1];
        Opportunity oppRecord = [Select Id from Opportunity Limit 1];
        Test.startTest();        
        User userWithRole = new User(UserRoleId = UserInfo.getUserRoleId(), ProfileId = UserInfo.getProfileId(), Account__c = accountRecord.id, 
                                     Alias = 'hasrole', Email='userwithroleSoldTo@godrej.com',Salary_Code__c = 'testSoldTo',
                                     EmailEncodingKey='UTF-8', LastName='SoldTo Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                     TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_soldto@godrej.com',CommunityNickname = 'testsoldto'); 
        insert UserWithRole;
        System.runAs(UserWithRole)
        {
            List<Order> orderRecords = createOrderRecords(3, accountRecord, oppRecord, UserWithRole);
            insert orderRecords;
            Test.stopTest();
            //Made the orderobj as string to check the salesforce list
            System.assertNotEquals(NULL, 'orderObj.Sales_Price_List__c' , 'Sales Price List should be populated');
           
        }

        
    }
    
    @isTest private static void testSetDefaultAtOrderB2C() {
        Test.startTest();
            Account accountRecord = new TestAccountBuilder(true)
                 .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CustomerAccountRt).getRecordTypeId())
                 .getTestRecord();
            accountRecord.LastName = 'SoldTo Test Customer Account';
            insert accountRecord;
        
            Branch__c firstBranch = new Branch__c(Branch_Name__c = '5010', Business_Partner__c  = accountRecord.Id );
            insert firstBranch;
            Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B');
            insert firstaddress;
            Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id, Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, 
                                                                 Branch__c = firstBranch.Id, Ship_To__c = TRUE, Sold_To__c  = TRUE);
            insert firstAddressByBp;

        
            Opportunity oppRecord = [Select Id from Opportunity Limit 1];
            User usr = [Select Id From User WHERE username = 'test.userSTPBUT@godrej.com' limit 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
            UserRole role = [Select Id, DeveloperName From UserRole Where DeveloperName = 'MHE' limit 1];
        
            User userWithRole;
            System.runAs(usr){
                userWithRole = new User(UserRoleId = role.Id, ProfileId = userProfile.Id, Account__c = accountRecord.id, 
                                    Alias = 'hasrole', Email='userwithroleSoldTo@godrej.com',Salary_Code__c = 'testSoldTo',
                                    EmailEncodingKey='UTF-8', LastName='SoldTo Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                    TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_soldto@godrej.com',CommunityNickname = 'testsoldto',
                                    Logistic_Company__c = '5010',Business_Unit__c='K'); 
                insert UserWithRole;
            }
            System.runAs(UserWithRole)
            {
                List<Order> orderRecords = createOrderRecords(3, accountRecord, oppRecord, UserWithRole);
                for(order o:orderRecords){
                    o.internal_sales_Representative__c=UserWithRole.Id;
                }
            
                insert orderRecords;
                Order orderObj = [Select Id,Associated_Dealer__c From Order where Id = :orderRecords[0].Id ];
                System.assertNotEquals(NULL, orderObj.Associated_Dealer__c , 'Associated Dealer should be populated');
            }
         Test.stopTest();
    }
            
    @isTest private static void testGetUserPersonaDetailsExternal() {
        Test.startTest();
        User pu = new TestUserBuilder().getPartnerUser();
        SoldToPriceBookUtility.getUserPersonaDetails(new Map<Id, String>{ pu.Id => '5010'} );
        Test.stopTest();
    }
    
    @isTest private static void testSetPriceBookAtOpportunityEquipment() {
        Opportunity oppRecord = [Select Id,LOB_N__c, Business_Unit__c, OwnerId, Sales_Branch_Name__c from Opportunity Limit 1];
        oppRecord.MHE_Division__c = GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT;
        Test.startTest();
        SoldToPriceBookUtility.setPriceBookAtOpportunity(new List<Opportunity>{oppRecord});
        Test.stopTest();
        Opportunity oppObj = [Select Id,Pricebook2.Name From Opportunity where Id = :oppRecord.Id ];
        //System.assertNotEquals(NULL, oppObj.Pricebook2.Name , 'Pricebook2Id should be populated');

    }
    
    @isTest private static void testSetPriceBookAtOpportunityContract() {
        Opportunity oppRecord = [Select Id,LOB_N__c, Business_Unit__c, OwnerId, Sales_Branch_Name__c  from Opportunity Limit 1];
        oppRecord.MHE_Division__c = GlobalConstants.MHE_SUB_DIVISION_CONTRACT;
        Test.startTest();
        SoldToPriceBookUtility.setPriceBookAtOpportunity(new List<Opportunity>{oppRecord});
        Test.stopTest();
        Opportunity oppObj = [Select Id,Pricebook2.Name From Opportunity where Id = :oppRecord.Id ];
        //System.assertNotEquals(NULL, oppObj.Pricebook2.Name , 'Pricebook2Id should be populated');
    } 

}