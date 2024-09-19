@isTest
public with sharing class AssetSharingPlatformEventTriggerTest {
    
    
    @TestSetup
    static void makeData(){
        List<ZipCode__c> zipCodeList = new List<ZipCode__c>(); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        ZipCode__c zipCode = new ZipCode__c();
        zipCode.Name = '410002';
        zipCode.CityCode__c = 'PUNE';
        zipCode.City_Name__c = 'PUNE';
        zipCode.StateCode__c = 'MH';
        zipCode.StateName__c = 'Maharashtra';
        zipCode.CountryCode__c = 'IN';   
        zipCode.CountryName__c = 'INDIA';   
        zipCode.ZipCodeExternalId__c = 'IN_410002';
        zipCodeList.add(zipCode); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        
        //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        ZipCode__c zipCode2 = new ZipCode__c();
        zipCode2.Name = '110002';
        zipCode2.CityCode__c = 'Delhi';
        zipCode2.City_Name__c = 'Delhi';
        zipCode2.StateCode__c = '';
        zipCode2.StateName__c = '';
        zipCode2.CountryCode__c = 'IN';   
        zipCode2.CountryName__c = 'INDIA';   
        zipCode2.ZipCodeExternalId__c = 'IN_110002';
        zipCodeList.add(zipCode2); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        
        insert zipCodeList; //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        //Ended by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        //Method to Create Address record
        
        List<Address__c> addList = new List<Address__c>(); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'Test Account';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.ZipCode__c = zipCodeList[0].Id; //Modified by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        address.Building__c = 'ABCDEFG';
        addList.add(address); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        
        //Added by Dhiren,Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        Address__c address2 = new Address__c();
        address2.Address_Type__c = 'B2B';
        address2.Address_Format__c = 'ADR';
        address2.Name__c = 'Test Account 2';
        address2.Telephone__c = '8765432112';
        address2.Email__c = 'punetest1234@nuvoco.com';
        address2.ZipCode__c = zipCodeList[1].Id;
        address2.Building__c = 'ABCDEFG';
        addList.add(address2);
        
        
        insert addList;
        //Ended by Dhiren,Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        
        //Create Service Dealer Account;
        Account dealerAccount = new Account();
        dealerAccount.Name = 'Test Account';
        dealerAccount.Type = 'D';
        dealerAccount.Account_Code__c ='KDX000909'; //Modified by Namrata and Shreela for SMEPB 134 on 5th Jan 2024
        dealerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
        dealerAccount.Primary_Address__c = address.Id;
        dealerAccount.Business_Unit__c = 'K';
        insert dealerAccount;
        
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Key_Account').getRecordTypeId();
        newAccount.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount.Business_Unit__c = 'K';
        newAccount.Service_Key__c = false;
        insert newAccount;


        //Create Account Record
        Account newAccount1 = new Account();
        newAccount1.Name = 'Test Account';
        newAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Key_Account').getRecordTypeId();
        newAccount1.Interio_Sub_Division__c= 'B2B-KAM';
        newAccount1.Business_Unit__c = 'K';
        newAccount1.Service_Key__c = false;
        insert newAccount1;
        
        //Create pincode Dealer mapping record the Dealer account
        Pin_Code_Dealer_Mapping__c pc = new Pin_Code_Dealer_Mapping__c(
            Name = '110003',
            Service_Dealer__c = dealerAccount.Id,
            IsActive__c = true
        );
        
        insert pc;
        
        Pin_Code_Dealer_Mapping__c pc1 = new Pin_Code_Dealer_Mapping__c(
            Name = '110002',
            IsActive__c = true
            
        );
        
        insert pc1;
        
        List<Asset> assetRecords = AssetSharingPlatformEventTriggerTest.createAssets(10,dealerAccount.Id,newAccount.Id);
        insert assetRecords;
        
        List<Asset> assetRecords1 = AssetSharingPlatformEventTriggerTest.createAssets(10,null,newAccount1.Id);
        insert assetRecords1;
        
        List<Asset> assetList = new List<Asset>(); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.Id;
        newAsset.Address_Code__c = address.id;			//Added by pc
        newAsset.Status = 'Active';
        newAsset.Product_Purchased_Warranty_Start_Date__c = Datetime.newInstance(2020, 11, 17, 1, 6, 8); 
        newAsset.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021, 11, 17);
        newAsset.Scheduled_PM_Visits_Number__c = 0;
        newAsset.Coverage__c = null;
        newAsset.Zip_Code__c = '110002';
        newAsset.Primary_Dealer__c = dealerAccount.Id;
        newAsset.Service_Dealer__c = null;
        newAsset.Type_of_Warranty__c = 'Not Applicable';
        assetList.add(newAsset); //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        
        //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        Asset newAsset2 = new Asset();
        newAsset2.Name= 'testAsset2';
        newAsset2.AccountId = dealerAccount.Id;
        newAsset2.Address_Code__c = addList[1].id;			//Added by pc
        newAsset2.Status = 'Active';
        newAsset2.Product_Purchased_Warranty_Start_Date__c = Datetime.newInstance(2020, 11, 17, 1, 6, 8); 
        newAsset2.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021, 11, 17);
        newAsset2.Scheduled_PM_Visits_Number__c = 0;
        newAsset2.Coverage__c = null;
        newAsset2.Zip_Code__c = '110002';
        newAsset2.Service_Dealer__c = null;
        newAsset2.Type_of_Warranty__c = 'Not Applicable';
        assetList.add(newAsset2);
        
        insert assetList;
        //Added by Namrata and Shreela on 5th Jan 2024 for SMEPB 134
        partial_transaction_control__c rn = new partial_transaction_control__c(Name = 'Asset Sharing', Batch_Size__c = 1);
        insert rn;
        
    }
    
    public static list<Asset> createAssets(Integer numOfAssets, Id dealerAccountId,Id customerId){
        Address__c add = [select id from Address__c where Name__c = 'Test Account' LIMIT 1];		//Added by pc
        List<Asset> assetsList = new List<Asset>();
        
        for(Integer i=0;i<numOfAssets;i++){
            Asset newAsset = new Asset();
            newAsset.Name= 'testAsset';
            newAsset.AccountId = customerId;
            newAsset.Address_Code__c = add.id;		//Added by pc
            newAsset.Status = 'Active';
            newAsset.Product_Purchased_Warranty_Start_Date__c = Datetime.newInstance(2020, 11, 17, 1, 6, 8); 
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.newInstance(2021, 11, 17);
            newAsset.Scheduled_PM_Visits_Number__c = 0;
            newAsset.Coverage__c = null;
            newAsset.Zip_Code__c = '110002';
            newAsset.Primary_Dealer__c = dealerAccountId;
            newAsset.Service_Dealer__c = dealerAccountId;
            newAsset.Type_of_Warranty__c = 'Not Applicable';
            assetsList.add(newAsset);
        }
        return assetsList;
        
    }
    
    @isTest
    public static void sharingTest(){
        Test.startTest();
        
        list<Logger__c> logRecords = [SELECT Id,Type__c,Account__c,Pin_Code_Dealer_Mapping__r.Name,Pin_Code_Dealer_Mapping__c ,SubType__c ,Deleted_PinCode__c FROM Logger__c];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent);
        }
        Eventbus.publish(insertList);
        Test.stopTest();
       	System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/02/2023
    }
    
    @isTest
    public static void metadataChangeTest(){
        Test.startTest();
        
        list<Asset> assetsList = [select Id,Service_Dealer__c,Primary_Dealer__c FROM Asset LIMIT 10];
        assetsList.get(0).Service_Dealer__c = null;
        assetsList.get(1).Primary_Dealer__c = null;
        
        update assetsList;
        
        Logger__c log1 = new Logger__c(Type__c='Metadata change - P1',Status__c='Pending');
        insert log1;
        
        
        list<Logger__c> logRecords = [SELECT Id,Type__c,Status__c FROM Logger__c where Type__c='Metadata change - P1' AND Status__c='Pending'];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){
            
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent);
        }
        Eventbus.publish(insertList);
        Test.stopTest();
       	System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/04/2023
    }
    
    @isTest
    public static void metadataChangeTes2(){
        Test.startTest();
        
        Account customerAccount = [select Id,Name, Service_Key__c  FROM Account where Name = 'Test Account' and Interio_Sub_Division__c= 'B2B-KAM'].get(0);
        customerAccount.Service_Key__c = true;
        update customerAccount;
        
        list<Asset> assetsList = [select Id,Service_Dealer__c,Primary_Dealer__c FROM Asset LIMIT 10];
        assetsList.get(0).Service_Dealer__c = null;
        assetsList.get(1).Primary_Dealer__c = null;
        
        update assetsList;
        
        Logger__c log1 = new Logger__c(Type__c='Metadata change - P1',Status__c='Pending');
        insert log1;
        
        
        list<Logger__c> logRecords = [SELECT Id,Type__c,Status__c FROM Logger__c where Type__c='Metadata change - P1' AND Status__c='Pending'];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){
            
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent);
        }
        Eventbus.publish(insertList);
        Test.stopTest();
        System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/04/2023
    }
    
    @isTest
    public static void deletePincodeDealerMappingTest(){
        Test.startTest();
        delete [SELECT Id FROM Pin_Code_Dealer_Mapping__c WHERE Name ='110002'];
        
        list<Asset> assetsList = [select Id,Primary_Dealer__c FROM Asset LIMIT 10];
        for(asset a:assetsList){
            a.Primary_Dealer__c = null;
        }
        update assetsList;
     
        list<Logger__c> logRecords = [SELECT Id,Type__c,Account__c,Pin_Code_Dealer_Mapping__r.Name,Pin_Code_Dealer_Mapping__c ,SubType__c ,Deleted_PinCode__c  FROM Logger__c];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){
            
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent);
        }
        Eventbus.publish(insertList);
        Test.stopTest();
       	System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/04/2023
    }
    
    @isTest
    public static void keyAccountChangeTest(){
        Test.startTest(); 
        Account customerAccount = [select Id,Name, Service_Key__c  FROM Account where Name = 'Test Account' and Interio_Sub_Division__c= 'B2B-KAM'].get(0);
        customerAccount.Service_Key__c = true;
        update customerAccount;
        list<Logger__c> logRecords = [SELECT Id,Type__c,Account__c,Status__c,Pin_Code_Dealer_Mapping__r.Name,Pin_Code_Dealer_Mapping__c ,SubType__c ,Deleted_PinCode__c  FROM Logger__c 
                                      where Type__c = 'Key Account change - P2' AND Status__c='Pending'];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){          
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent);
        }
        Eventbus.publish(insertList);
        Test.stopTest();
        System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/04/2023
    }
    
    @isTest
    public static void pincodeDealerChangeTest(){
        Test.startTest();
        Pin_Code_Dealer_Mapping__c pincode = [ SELECT Id,Service_Dealer__c FROM Pin_Code_Dealer_Mapping__c WHERE Name ='110002'].get(0);
        
        pincode.Service_Dealer__c = [select id,Name from Account where Name='Test Account' and Type = 'D'].get(0).Id;
        update pincode;
        
        list<Logger__c> logRecords = [SELECT Id,Type__c,Account__c,Pin_Code_Dealer_Mapping__r.Name,Pin_Code_Dealer_Mapping__c ,SubType__c ,Deleted_PinCode__c  FROM Logger__c];
        list<Asset_Sharing__e> insertList = new list<Asset_Sharing__e>();
        for(Logger__c l:logRecords){
            Asset_Sharing__e newEvent = new Asset_Sharing__e();
            newEvent.Logger_recordId__c = l.Id;
            insertList.add(newEvent); 
        }
        Eventbus.publish(insertList);
        Test.stopTest();
        System.assert(insertList.size() >0);//gcp22 edited by dhiren 03/04/2023
    }
    
}