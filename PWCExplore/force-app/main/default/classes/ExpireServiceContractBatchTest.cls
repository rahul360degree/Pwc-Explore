/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Test class for ExpireServiceContractBatch and ExpireServiceContractBatch.
Inputs:        
Test Class:   
----------------------------------------------------------------------------*/
@isTest
public class ExpireServiceContractBatchTest {
    @testSetup
    static void createData(){
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'ExpireServiceContractBatch', 
                                                                            Batch_Size__c = 100);
        insert abc;
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userESCBT@godrej.com', username = 'test.userESCBT@godrej.com', Business_Unit__c = 'W');

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;

        PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
        insert rentalPriceBook;

        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
            new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord()            
        };
        insert allProducts;
                
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord()          
        };
        insert allPBEs;
        
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount.Business_Unit__c = 'K';
        insert newAccount;
        
        //Dealer RT account
        Account dealerAccount = new Account(Name='TestB2B Dealer', Industry='Apparel', Type='3', Business_Unit__c = 'K',
                                           Account_Series__c=System.Label.Parent_Account_Series,
                                                Account_code__c=System.Label.Parent_Account_Series+'123456');
        dealerAccount.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
        insert dealerAccount;
        
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        sc.AccountId = newAccount.id;
        sc.Status__c = 'Open';
        sc.EndDate = System.today()-2;
        sc.StartDate = System.today()-5;
        sc.Pricebook2Id = rentalPriceBook.Id;
        insert sc;  
        
        //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
        
        Asset newAsset = new Asset();
        newAsset.Name= 'Asset 1';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Purchased';
        newAsset.Primary_Dealer__c = dealerAccount.Id;
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Coverage__c = 'KFGWC00600001';
        newAsset.Address_Code__c = address.id;		//Added by pc
        insert newAsset;
        
        ContractLineItem cli = new ContractLineItem();
        cli.AssetId = newAsset.id;
        cli.ServiceContractId = sc.id; 
        cli.PricebookEntryId = allPBEs[0].Id;
        cli.UnitPrice = 10;
        cli.Quantity = 1;
        insert cli;  
    }
    
    @isTest
    static void testBatch(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userESCBT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            Test.startTest();
            ExpireServiceContractBatch be = new ExpireServiceContractBatch();
            database.executeBatch(be);
            Test.stopTest();
            ServiceContract serviceContractRec = [SELECT Id, Name, Status__c, 
                                                    (SELECT Id, AssetId, Asset.Primary_Dealer__c FROM ContractLineItems WHERE Asset.Primary_Dealer__c != null ) 
                                                  FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
            System.assertEquals(serviceContractRec.Status__c, 'Expired');
            system.assertEquals(serviceContractRec.ContractLineItems.size(), 0);
        }
    }
    
    @isTest
    static void testSchedular(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userESCBT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            String CRON_EXP = '0 0 0 15 3 ? *';
            
            List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
            System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
                    
            Test.startTest();
            String jobId = System.schedule('serviceContractBatch', CRON_EXP, new ExpireServiceContractBatchSchedular());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            Test.stopTest();
            
            List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
            System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
            System.assertEquals('ExpireServiceContractBatchSchedular', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');    
        }
    }
}