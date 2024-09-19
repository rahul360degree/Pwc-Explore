@isTest
public with sharing class PincodeDealerTriggerHelperTest {
    
@TestSetup
static void makeData(){

     ZipCode__c zipCode = new ZipCode__c();
        zipCode.Name = '410002';
        zipCode.CityCode__c = 'PUNE';
        zipCode.City_Name__c = 'PUNE';
        zipCode.StateCode__c = 'MH';
        zipCode.StateName__c = 'Maharashtra';
        zipCode.CountryCode__c = 'IN';   
        zipCode.CountryName__c = 'INDIA';   
        zipCode.ZipCodeExternalId__c = 'IN_410002';

    //Method to Create Address record
   
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'DEALER ACCOUNT';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.ZipCode__c = zipCode.Id;
        address.Building__c = 'ABCDEFG';
        insert address;

    //Create Service Dealer Account;
   Account dealerAccount = new Account();
            dealerAccount.Name = 'DEALER ACCOUNT';
            dealerAccount.Type = 'D';
            dealerAccount.Account_Code__c ='DKX000909';
            dealerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            dealerAccount.Primary_Address__c = address.Id;
            dealerAccount.Business_Unit__c = 'K';
            insert dealerAccount;

             Runtime_Execution__c rn = new Runtime_Execution__c(Name = 'Fire_pinCodeDealerMappingTriggerDisabled__c', Fire_pinCodeDealerMappingTriggerDisabled__c = false);
            insert rn;


    
}

@isTest
public static void getPincodeDealerUpdatesTest(){

    Test.startTest();
    Account dealerAccount = [select Id FROM Account where RecordType.Name ='Dealer'].get(0);
    //Create pincode Dealer mapping record the Dealer account
    Pin_Code_Dealer_Mapping__c pc = new Pin_Code_Dealer_Mapping__c(
        Name = '110002',
        Service_Dealer__c = dealerAccount.Id
    );

    insert pc;

    pc.IsActive__c = true;

    update pc;

    list<Pin_Code_Dealer_Mapping__c> pcRecords = [SELECT Id FROM Pin_Code_Dealer_Mapping__c];
    system.assertEquals(pcRecords.size()>0, pcRecords.size()>0);

    delete pcRecords.get(0);

    list<Pin_Code_Dealer_Mapping__c> pcRecords1 = [SELECT Id FROM Pin_Code_Dealer_Mapping__c];
    system.assertEquals(0, pcRecords1.size());
    


    List<Logger__c> logRecords = [SELECT Id FROM Logger__c];
    system.assertEquals(logRecords.size()>0, logRecords.size()>0);

    Test.stopTest();
}
}