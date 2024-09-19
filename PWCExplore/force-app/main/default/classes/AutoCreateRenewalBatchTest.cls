@isTest
public class AutoCreateRenewalBatchTest {
    @testSetup
    static void createData(){        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userAccACRBT@godrej.com', username = 'test.userAccACRBT@godrej.com', Business_Unit__c = 'K');

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;

        PriceBook2 contractPriceBook = new PriceBook2(Name = 'MHE Contracts PL', IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
        insert contractPriceBook;

        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
            new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord()            
        };
        insert allProducts;
                
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(50000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(3000).getTestRecord()          
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
        Date Expiry=system.Today()+60;
        system.runAs(userToRun)
        { 
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        sc.AccountId = newAccount.id;
        sc.Status__c = 'Open';
        sc.StartDate = System.today()-5;
        sc.Pricebook2Id = contractPriceBook.Id;
        sc.Duration__c = '14';
        sc.Duration_Unit__c ='Month';
        sc.EndDate = Expiry;
        insert sc;  
     
        Opportunity opp = new Opportunity();
                opp.Name = 'Renewal Opportunity for '+ sc.name;  
                opp.AccountId = sc.AccountId;
                opp.OwnerId = userToRun.Id;  
                opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('MHE').getRecordTypeId();
                opp.CloseDate = system.today();
                opp.MHE_Division__c = 'Contracts';
                opp.StageName = 'Inquiry';
                opp.Previous_Service_Contract__c = sc.Id; 
                opp.Sales_Branch_Name__c = sc.Branch__c;
                opp.Contract_Start_Date__c = sc.EndDate+1;
                opp.Duration_Unit__c = sc.Duration_Unit__c;
                opp.Duration__c = decimal.valueof(sc.Duration__c);
                opp.Competitor1__c = 'None';
                opp.Enquiry_Type__c = sc.Associated_Opportunity__r.Enquiry_Type__c;
                opp.WarehouseCode__c = sc.Associated_Opportunity__r.WarehouseCode__c;
                opp.Pricebook2Id = sc.Associated_Opportunity__r.Pricebook2Id;
        insert opp;
            
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
        newAsset.Address_Code__c = address.id;		//Added by pc
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        newAsset.Coverage__c = 'KFGWC00600001';
        insert newAsset;
        
        ContractLineItem cli = new ContractLineItem();
        cli.AssetId = newAsset.id;
        cli.ServiceContractId = sc.id; 
        cli.PricebookEntryId = allPBEs[0].Id;
        cli.UnitPrice = 10;
        cli.Quantity = 1;
        insert cli;  
         
         Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'AutoRenewalScheduler', 
                                                                            Batch_Size__c = 10);
        insert abc;

    }
    }   
     @isTest
    static void testBatch(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAccACRBT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        
        System.runAs(contextuser) {
            Test.startTest();
            AutoCreateRenewalOpportunitiesBatch be = new AutoCreateRenewalOpportunitiesBatch();
            ID batchprocessid = database.executeBatch(be);
            Test.stopTest();
                
                }  
 } 
     @isTest
    static void testSchedulerAndBatch() {
        Test.StartTest();
        AutoRenewalScheduler scheduler = new AutoRenewalScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('AutoRenewalScheduler', sch, scheduler); 
        Test.stopTest();
       }

}