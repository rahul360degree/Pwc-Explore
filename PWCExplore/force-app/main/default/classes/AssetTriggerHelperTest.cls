/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Test class for AssetTriggerHelper
Inputs:            

----------------------------------------------------------------------------*/
@isTest
public class AssetTriggerHelperTest {
    @testsetup
    private static void testData() {

        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME LIMIT 1];
        // Create User record.
        User integrationUser = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id, 
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userAcc@godrej.com', username = 'test.userAcc@godrej.com', Business_Unit__c = 'W');

        integrationUser.IsActive = true;
        insert integrationUser;
        
        
        Profile userAdminProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        User userAdmin = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test1', lastname = 'User1', Alias = 'tuser1',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userAdminProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.userAdmin@godrej.com', 
                                    username = 'test.userAdmin@godrej.com',Business_Unit__c = 'K');
        userAdmin.IsActive = true;
        insert userAdmin;
        
        
        //Create Plan Record
        Plan__c stdPlan = new Plan__c();
        stdPlan.Name = 'Std Warranty';
        stdPlan.BD_Visits_Number__c = 4; 
        stdPlan.Scheduled_PM_Visits_Number__c =5;
        stdPlan.Plan_Type__c = 'Warranty';
        stdPlan.Is_Standard_Plan__c = true;
        stdPlan.Is_Active__c = true;
        stdPlan.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId();
         
        insert stdPlan;
        
        
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        //newAccount.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount.Business_Unit__c = 'K';
        insert newAccount;
        
        //Create Address record      //Added by pc
		Address__c address = new Address__c();        
        address.Address_Type__c = 'B2B';
        address.Name__c = 'Test Address';
        address.Telephone__c = '8765432111';
        address.Email__c = 'testingadd1234@nuvoco.com';
        address.Building__c = 'Testing building';
        address.Street2__c = '4th Street';
        insert address;
        
        System.runAs(integrationUser){
            //Create Asset record
            Asset newAsset = new Asset();
            newAsset.Name= 'testAsset';
            newAsset.Equipment_Serial_No__c = '1';
            newAsset.AccountId = newAccount.id;
            newAsset.Status = 'Purchased';
            newAsset.Coverage__c = 'KFGWC00600001';
            newAsset.Type_of_Warranty__c = 'Special Warranty';
            newAsset.Address_Code__c = address.id;
            insert newAsset;

            
            List<Asset_Benefit__c> assetBenefitList = new List<Asset_Benefit__c>();
        
        	for(Integer i= 1; i<4; i++){
                Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
                newAssetBenefit.Name= 'Test'+i;
                newAssetBenefit.Asset__c = newAsset.id;
                newAssetBenefit.Is_Active__c = true;  
                newAsset.Coverage__c = 'KFGWC00600001';
                newAsset.Type_of_Warranty__c = 'Special Warranty';
                assetBenefitList.add(newAssetBenefit);
            }
            insert assetBenefitList;
        
            Asset_Benefit__c AssetBenefit = new Asset_Benefit__c();
            AssetBenefit.Name= 'Test';
            AssetBenefit.Is_Active__c = false;
            AssetBenefit.Asset__c = newAsset.id;
        }
        
        System.runAs(userAdmin){
            Asset newAsset1 = new Asset();
            newAsset1.Name= 'testAsset1';
            newAsset1.Equipment_Serial_No__c='2';
            newAsset1.AccountId = newAccount.id;
            newAsset1.Status = GlobalConstants.ASSET_UNREGISTERED_STATUS;
            newAsset1.Coverage__c = 'KFGWC00600001';
            newAsset1.Type_of_Warranty__c = 'Special Warranty';
            newAsset1.Address_Code__c = address.id;  		//Added by pc
            insert newAsset1;
        }
       /* //Create Asset Benefit record
        List<Asset_Benefit__c> assetBenefitList = new List<Asset_Benefit__c>();
        
        for(Integer i= 1; i<4; i++){
            Asset_Benefit__c newAssetBenefit = new Asset_Benefit__c();
            newAssetBenefit.Name= 'Test'+i;
            newAssetBenefit.Asset__c = newAsset.id;
            newAssetBenefit.Is_Active__c = true;  
            newAsset.Coverage__c = 'KFGWC00600001';
        	newAsset.Type_of_Warranty__c = 'Special Warranty';
            assetBenefitList.add(newAssetBenefit);
        }
        insert assetBenefitList;
        
        Asset_Benefit__c AssetBenefit = new Asset_Benefit__c();
        AssetBenefit.Name= 'Test';
        AssetBenefit.Is_Active__c = false;
        AssetBenefit.Asset__c = newAsset.id;*/
                
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to test createStandardWarrantyAssetBenefits
    Inputs:            
    
    ----------------------------------------------------------------------------*/
    @isTest private static void testCreateStandardWarrantyAssetBenefits(){
        test.startTest();        
            Account acc = [SELECT Id FROM Account where Name = 'Test Account' LIMIT 1];
        	Address__c add = [select id from Address__c where Name__c = 'Test Address' LIMIT 1];
            Asset assetRec = new Asset();
            assetRec.Name= 'Asset 1';
            assetRec.AccountId = acc.id;
            assetRec.Status = GlobalConstants.ASSET_ACTIVE_STATUS;
        	assetRec.Type_of_Warranty__c = 'Std Warranty';
        	assetRec.Address_Code__c = add.id;  		//Added by pc
            insert assetRec;
            
            Asset assetwithStdWarranty = [SELECT Id, (SELECT Id, Name From Asset_Benefits__r WHERE Plan__r.Name = 'Std Warranty') FROM Asset WHERE Id =: assetRec.Id LIMIt 1];
        	System.assert(assetwithStdWarranty.Asset_Benefits__r.size() > 0);
        test.stopTest();          
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   method to test disableScrappedAssetBenefits
    Inputs:            
    
    ----------------------------------------------------------------------------*/
    @isTest private static void testDisableScrappedAssetBenefits(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];		
        
			System.runAs(contextuser) {
                
            test.startTest();      
            Account businessAcc = [SELECT Id FROM Account where Name = 'Test Account' LIMIT 1];
            Address__c add = [select id from Address__c where Name__c = 'Test Address' LIMIT 1];
            Asset newAsset = [SELECT Id, Name, Status FROM Asset WHERE accountid =: businessAcc.id LIMIT 1];
            newAsset.Address_Code__c = add.id;  		//Added by pc
            newAsset.Status = GlobalConstants.ASSET_SCRAPPED_STATUS[0];
            newAsset.Equipment_Serial_No__c='Testing';	//Added by pc
            update newAsset;  
        
        	Asset_Benefit__c assetBen = [SELECT Id, Name,Is_Active__c FROM Asset_Benefit__c where Name = 'Test1' LIMIT 1 ];
            test.stopTest(); 
            System.assert(assetBen.Is_Active__c==True);//gcp22

        }
     }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to test createInstallationServiceRequest
    Inputs:            
    
    ----------------------------------------------------------------------------*/
  @isTest private static void testCreateInstallationServiceRequest(){
        test.startTest();        
            Account acc = [SELECT Id FROM Account where Name = 'Test Account' LIMIT 1];
      		Address__c add = [select id from Address__c where Name__c = 'Test Address' LIMIT 1];
            Asset assetRec = new Asset();
            assetRec.Name= 'Asset 5';
            assetRec.AccountId = acc.id;
            assetRec.Status = GlobalConstants.ASSET_STATUS_SHIPPED;
      		assetRec.Type_of_Warranty__c = 'Special Warranty';
        	assetRec.Coverage__c = 'KFGWC00600001';
      		assetRec.Address_Code__c = add.id;		//Added by pc
            insert assetRec;
            
            Asset assetToUpdate = new Asset(Id = assetRec.Id, Status = GlobalConstants.ASSET_STATUS_SHIPPED);
        	update assetToUpdate;
        
        	list<Case> installationCases = [SELECT Id FROM Case WHERE AssetId =: assetToUpdate.Id AND Type =: GlobalConstants.CASE_TYPE_COMMISSIONING LIMIT 1];
        	System.assert(installationCases.size() > 0);
        test.stopTest();          
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to test updateAssetStatusForIntegrationUser
    Inputs:            
    
    ----------------------------------------------------------------------------*/
    @isTest private static void testUpdateAssetStatusForIntegrationUserForBusinessAccount(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            Account businessAcc = [SELECT Id FROM Account where Name = 'Test Account' LIMIT 1];
            Asset assetRec = new Asset();
            assetRec.Name= 'Asset 5';
            assetRec.AccountId = businessAcc.id;
            assetRec.Area_Code__c = 'NH1';
            //assetRec.Status = 'Purchased';
            assetRec.Status = GlobalConstants.ASSET_STATUS_SHIPPED;
            insert assetRec;

            Asset updatedAsset = [SELECT Id, Status, (SELECT Id FROM Cases WHERE Type =: GlobalConstants.CASE_TYPE_COMMISSIONING) 
                                    FROM Asset WHERE Id =: assetRec.Id 
                                    AND Status =: GlobalConstants.ASSET_STATUS_SHIPPED];
           Test.stopTest();
           system.assertEquals(assetRec.Id ,updatedAsset.Id);//gcp22
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   method to test updateAssetStatusForIntegrationUser
    Inputs:            
    
    ----------------------------------------------------------------------------*/
    @isTest private static void testUpdateAssetStatusForIntegrationUserForDealerAccount(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create Dealer Account Record
            Account dealerAccount = new Account();
            dealerAccount.Name = 'Dealer Account';
            dealerAccount.Type = 'D';
            dealerAccount.Account_Code__c ='DKX000909';
            dealerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            insert dealerAccount;

            Asset assetRec = new Asset();
            assetRec.Name= 'Asset 5';
            assetRec.AccountId = dealerAccount.id;
            assetRec.Status = 'Purchased';
            assetRec.Area_Code__c = 'NH1';
            insert assetRec;

            Asset updatedAsset = [SELECT Id, Status  
                                    FROM Asset WHERE Id =: assetRec.Id 
                                    ];

            system.assertEquals(true, updatedAsset.Status == GlobalConstants.ASSET_UNREGISTERED_STATUS);                        
            Test.stopTest();
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Priyanka Mukkavalli
    Company:       GITL
    Description:   method to test validateMHEAssetStatus Inactive -> Active
    Inputs:            
    ----------------------------------------------------------------------------*/
    @isTest private static void testUpdateAssetStatusInactiveToActive(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            Account businessAcc = [SELECT Id FROM Account where name ='Test Account' LIMIT 1];
            Asset newAsset = [SELECT Id, Name, Status FROM Asset WHERE accountid =: businessAcc.id LIMIT 1];
            newAsset.Status = 'INACTIVE';
            newAsset.Equipment_Serial_No__c = '20';
            update newAsset;  
            system.debug('testUpdateAssetStatusInactiveToActive- asset :'+newAsset);
            try{
                newAsset.Status = GlobalConstants.ASSET_ACTIVE_STATUS;
                update newAsset;  
        	}catch(Exception ex){
                system.debug('ex.getMessage()'+ex.getMessage());
                
            }
            Test.stopTest();
        }
    }

    /*------------------------------------------------------------------------
    Author:        Priyanka Mukkavalli
    Company:       GITL
    Description:   method to test validateMHEAssetStatus Scrapped -> Shipped
    Inputs:            
    ----------------------------------------------------------------------------*/
    @isTest private static void testUpdateAssetStatusScrappedToShipped(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAcc@godrej.com' LIMIT 1];
        
        System.runAs(contextuser) {
            Test.startTest();
            Account businessAcc = [SELECT Id FROM Account where name ='Test Account' LIMIT 1];
            Asset newAsset = [SELECT Id, Name, Status FROM Asset WHERE accountid =: businessAcc.id  LIMIT 1];
            newAsset.Status = 'Scrapped';
            newAsset.Equipment_Serial_No__c='Testing';		//Added by pc
            update newAsset; 
            system.debug('testUpdateAssetStatusScrappedToShipped :'+newAsset);
            try{
                newAsset.Status = 'Shipped';
                update newAsset;  
        	}catch(Exception ex){
                System.assert(ex.getMessage().contains(System.Label.Asset_Status_Backtrack_error));
            }
            Test.stopTest();
        }
    }

    /*------------------------------------------------------------------------
    Author:        Priyanka Mukkavalli
    Company:       GITL
    Description:   method to test createServiceRequest
    Inputs:            
    ----------------------------------------------------------------------------*/
    @isTest private static void testCreateServiceRequest(){
        User contextuser = [Select Id FROM User WHERE username = 'test.userAdmin@godrej.com' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            Account businessAcc = [SELECT Id FROM Account where name ='Test Account' LIMIT 1];
            Asset newAsset = [SELECT Id, Name, Status,AccountId FROM Asset where AccountId =: businessAcc.id LIMIT 1];
            system.debug('testCreateServiceRequest - asset : '+newAsset);
            newAsset.Status = 'GlobalConstants.ASSET_UNREGISTERED_STATUS ';
            update newAsset;  
            List<Case> lstCase = [SELECT Id FROM Case WHERE AccountId =: newAsset.AccountId];
            system.assertEquals(true, lstCase.size() > 0);                        
            Test.stopTest();
        }
    }
}