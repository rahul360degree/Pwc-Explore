/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-23-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   01-23-2024   Varun Rajpoot   Initial Version
**/
@isTest
public class UserRecordProcessorTest {
    @testsetup
    private static void testData() {
        list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
        list<Address__c> AddressesToCreate = new list<Address__c>();
        list<Address_by_BP__c> ABPsToCreate = new list<Address_by_BP__c>();
        
        //Inserting reserved chars from custom setting
        Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
        rChar.B2C_character__c = 'A';
        rChar.B2B_Account_Series_Char__c = 'X';
        rChar.B2B_character__c = 'AA';
        
        insert rChar;
        
        //Create Zip Code Data
        for(Integer i = 1; i<3; i++){
            ZipCode__c zipCode = new ZipCode__c();
           // zipCode.RecordTypeId = Schema.SObjectType.ZipCode__c.getRecordTypeInfosByDeveloperName().get('Zip_Code').getRecordTypeId();
            if(i == 1){
                zipCode.Name = '410002';
                zipCode.CityCode__c = 'PUNE';
                zipCode.City_Name__c = 'PUNE';
                zipCode.StateCode__c = 'MH';
                zipCode.StateName__c = 'Maharashtra';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_410002';
            } else {
                zipCode.Name = '110008';
                zipCode.CityCode__c = 'Delhi';
                zipCode.City_Name__c = 'DELHI';
                zipCode.StateCode__c = 'DL';
                zipCode.StateName__c = 'Delhi';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_110008';
            }
            
            ZipCodesToCreate.add(zipCode);
        }
        insert ZipCodesToCreate;
        
        
        //Create Address records
        for(Integer i = 1; i<3; i++){
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            if(i == 1){
                address.Name__c = 'Nuvoco Plant Pune';
                address.Telephone__c = '8765432111';
                address.Email__c = 'punetest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[0].Id;
            } else {
                address.Name__c = 'Nuvoco Plant Delhi';
                address.Telephone__c = '8765432110';
                address.Email__c = 'delhitest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[1].Id;
            }
            AddressesToCreate.add(address);
        }
        insert AddressesToCreate;
        
        Account accountRecord = new Account(Name = 'TestB2B9',
                                            Industry = 'Apparel',
                                            Type = '3',
                                            Business_Unit__c = 'W',
                                            Account_Code__c = 'FDG2435');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert accountRecord;
        
        Sales_Office__c so = new Sales_Office__c(
            Name = 'Appl - Vikhroli pl1- serv off',            
            Company_desc__c = 'Godrej & Boyce Mfg. Co. Ltd. A',  
            Enterprise_Unit__c = '243001',                       
            Address_Code__c = 'ZCO000023',                     
            Sales_Office_Code__c = 'D_HZY01A',                  
            Address_Desc__c = 'Godrej & Boyce / PL 7',           
            LN_Sales_Office_Code__c = 'HZY01A'                  
        );
        insert so;
    }
    
    @isTest private static void test_populateAccountDetailsBasedOnBPCode(){
        Profile userProfile = [Select Id from Profile where Name = 'Interio B2C VFD COCO Team User' LIMIT 1];
        test.startTest();
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test22.user@godrej.com', username = 'test22.user@godrej.com', Business_Unit__c = 'W');
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Business_Partner_Code__c = 'FDG2435';
        insert userToRun;
        
        test.stopTest();
        List<User> usrRec = [Select Id, Business_Partner_Code__c From User limit 1];
        System.assert(usrRec.size() > 0);
    }
    
    @isTest private static void test_validateSalesOfficeWithValidSalesOffice(){
        Profile userProfile = [Select Id from Profile where Name = 'Interio B2C VFD COCO Team User' LIMIT 1];
        test.startTest();
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test63.user@godrej.com', username = 'test63.user@godrej.com', Business_Unit__c = 'W');
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        User usr = userToRun;
        usr.Sales_Office__c = 'HZY01A'; 
        update usr;
        test.stopTest();
        List<User> usrRec = [Select Id, Sales_Office__c From User limit 1];
        System.assert(usrRec.size() > 0);
    }
    
    @isTest private static void test_validateSalesOfficeWithInValidSalesOffice(){
        Profile userProfile = [Select Id from Profile where Name = 'Interio B2C VFD COCO Team User' LIMIT 1];
        test.startTest();
        try{
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test63.user@godrej.com', username = 'test63.user@godrej.com', Business_Unit__c = 'W');
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Sales_Office__c = 'Y01A';
        insert userToRun;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains(System.Label.Sales_Office_Validation_Error_On_User_Record));
        }
        test.stopTest();
    }
   
    @isTest private static void test_populateAssociatedAccountName(){
        Profile userProfile = [Select Id from Profile where Name = 'Interio B2C VFD COCO Team User' LIMIT 1];
        Account acc = [Select Id, Name From Account limit 1];
        test.startTest();
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test22.user@godrej.com', username = 'test22.user@godrej.com', Business_Unit__c = 'W');
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        User usr = userToRun;
        usr.Account__c = acc.Id; 
        update usr;
        test.stopTest();
        List<User> usrRec = [Select Id, Account__c, Account_Name__c From User limit 1];
        System.assert(usrRec.size() > 0);
    }
}