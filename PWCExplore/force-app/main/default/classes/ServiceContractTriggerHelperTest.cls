/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Test class for Service Contract Trigger Helper
Inputs:            

----------------------------------------------------------------------------*/
@isTest
public class ServiceContractTriggerHelperTest {
    @testsetup
    private static void testData() {
       
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;

        PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
        insert rentalPriceBook;
        
        //new
        PriceBook2 localContractPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Contract_PB, IsActive = true, LN_PriceList_Code__c = 'LC', PriceList_Code__c = 'LC');
        insert localContractPriceBook;

        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
            new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord()            
        };
        insert allProducts;
                
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),  
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(localContractPriceBook.Id).setUnitPrice(3000).getTestRecord()    //new
        };
        insert allPBEs;   
       
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount.Business_Unit__c = 'K';
        insert newAccount;
        
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        //sc.Status__c = GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS;
        sc.Status__c = 'Open';
        sc.AccountId = newAccount.id;
        sc.Pricebook2Id = rentalPriceBook.Id;
        sc.Integration_Status__c = 'Not Synced';
        insert sc;
        
        //Create Address Record					//Added by pc
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
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Address_Code__c = address.id;			//Added by pc
        newAsset.Status = 'Purchased';
        newAsset.Coverage__c = 'KFGWC00600001';
        newAsset.Type_of_Warranty__c = 'Special Warranty';
        insert newAsset;
        
        ContractLineItem cli = new ContractLineItem();
        cli.AssetId = newAsset.id;
        cli.ServiceContractId = sc.id; 
        cli.PricebookEntryId = allPBEs[0].Id;
        cli.UnitPrice = 1011;
        cli.Quantity = 1;
        insert cli;   
        
        List<Asset_Benefit__c> assetBenefitList = new List<Asset_Benefit__c>();
        
        for(Integer i= 1; i<4; i++){
            Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
            newAssetBenefit.Name= 'Test'+i;
            newAssetBenefit.Asset__c = newAsset.id;
            newAssetBenefit.Is_Active__c = true;  
            newAssetBenefit.Contract_Line_Item__c= cli.id;
            assetBenefitList.add(newAssetBenefit);          
        }
        insert assetBenefitList;
               
    }
/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Methode to test that all the associated asset Benefit records becomes inactive
			   once the service contract becomes inactive
Inputs:            

----------------------------------------------------------------------------*/
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContract(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Status__c= 'Expired';
        
        update newServiceContract;
        test.stopTest();
        Asset_Benefit__c assetBen = [SELECT Id, Name,Is_Active__c FROM Asset_Benefit__c where name = 'Test1' LIMIT 1 ];
        System.assert(assetBen.Is_Active__c==false);        
    }
    
    @isTest private static void testPopulateIntegrationDefaults(){
        
        Profile userProfile = [Select Id from Profile where Name =: System.Label.Integration_User_Profile_Name LIMIT 1];
        UserRole role = [SELECT Id, Name, DeveloperName FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1];
        // Create User record.
        User newUser = new User(EmailEncodingKey = 'UTF-8', firstName = 'Adwait', lastname = 'Rao', Alias = 'Arao',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, UserRoleId = role.Id,
                            timezonesidkey = 'Asia/Kolkata', email = 'adu.rao@godrej.com', username = 'adi.rao@godrej.com.onecrm2b', Business_Unit__c = 'K');

        newUser.IsActive = true;
        newUser.Allow_Business_Account_Creation__c = true;
        newUser.Logistic_Company__c = '2000';
        newUser.Area_Code__c = 'WN1';
        insert newUser;
        //User testUser = [Select Id FROM User WHERE username = 'adi.rao@godrej.com.onecrm2b' LIMIT 1];
        System.runAs(newUser) {
         
        test.startTest();    
        Account acc = [Select Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        PriceBook2 pB = [Select Id FROM PriceBook2 WHERE Name =: System.Label.MHE_SF_Local_Contract_PB LIMIT 1];
         
        ServiceContract scc = new ServiceContract();
        scc.Name = 'Test2 Service Contract';
        //scc.Status__c = GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS;
        scc.Status__c = 'Open';
        scc.AccountId = acc.id;
        scc.Pricebook2Id = pB.Id;
        //scc.Sales_Rep_Code__c = '';
        insert scc;
         
        test.stopTest();
        }
        ServiceContract sc = [SELECT Id, Name, Status__c, Pricebook2Id FROM ServiceContract WHERE Name = 'Test2 Service Contract' LIMIT 1];
        PriceBook2 pB = [Select Id FROM PriceBook2 WHERE Name =: System.Label.MHE_SF_Local_Contract_PB LIMIT 1];
        System.assertEquals(pB.id, sc.Pricebook2Id);
        
    }
    
    
    @isTest private static void populateDefaultsOnLines(){
        test.startTest();
        ServiceContract newServiceContract = [SELECT Id, Name, Contract_Template__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Contract_Template__c = 'MHECOMPRDAY' ;
        update newServiceContract;
        test.stopTest();
        
        ContractLineItem cli = [SELECT Id, Contract_Template__c,UnitPrice FROM ContractLineItem WHERE UnitPrice = 1011 LIMIT 1];
        
        System.assertEquals('MHECOMPRDAY', cli.Contract_Template__c);        
    }
    
    @isTest private static void populateIntegrationStatusOnLines(){
        test.startTest();
        ServiceContract newServiceContract = [SELECT Id, Name, Integration_Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Integration_Status__c = 'Synced' ;
        update newServiceContract;
        test.stopTest();
        
        ContractLineItem cli = [SELECT Id, Integration_Status__c,UnitPrice FROM ContractLineItem WHERE UnitPrice = 1011 LIMIT 1];
        System.assertEquals('Synced', cli.Integration_Status__c);
    }
    
    
    @isTest private static void populatePriceBookEntryForIntegrationUserTest(){
        test.startTest();
        ServiceContract newServiceContract = [SELECT Id, Name, Integration_Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Integration_Status__c = 'Synced' ;
        update newServiceContract;
        test.stopTest();
        
        ContractLineItem cli = [SELECT Id, Integration_Status__c,UnitPrice FROM ContractLineItem WHERE UnitPrice = 1011 LIMIT 1];
        System.assertEquals('Synced', cli.Integration_Status__c);
    }
    
    //Added by Praful - 03-march-2021
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContractForDurationY(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Duration_Unit__c = 'Year';
        newServiceContract.Duration__c = '1';
        newServiceContract.startDate = date.today();
        update newServiceContract;
        test.stopTest();
         
    }
    
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContractForDurationM(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Duration_Unit__c = 'Month';
        newServiceContract.Duration__c = '1';
        newServiceContract.startDate = date.today();
        update newServiceContract;
        test.stopTest();
    }
    
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContractForDurationQ(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Duration_Unit__c = 'Quarter';
        newServiceContract.Duration__c = '1';
        newServiceContract.startDate = date.today();
        update newServiceContract;
        test.stopTest();
    }
    
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContractForDurationD(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Duration_Unit__c = 'Day';
        newServiceContract.Duration__c = '1';
        newServiceContract.startDate = date.today();
        update newServiceContract;
        test.stopTest();
    }
    
    @isTest private static void testdeactivateAllAssetBenefitsForInactiveServiceContractForDurationW(){
        test.startTest();        
        ServiceContract newServiceContract = [SELECT Id, Name, Status__c FROM ServiceContract WHERE Name = 'Test Service Contract' LIMIT 1];
        newServiceContract.Duration_Unit__c = 'Week';
        newServiceContract.Duration__c = '1';
        newServiceContract.startDate = date.today();
        update newServiceContract;
        test.stopTest();
    }

}