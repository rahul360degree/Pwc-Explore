/*------------------------------------------------------------------------
Author:        Kishor Kumar 
Company:       Salesforce
Description:   Test class for AddressByBPTriggerHelper
Inputs:        NA
Test Class:    
History
11-07-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
@isTest
private class AddressByBPTriggerHelperTest {

    @testSetup
    private static void createTestRecords(){
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
                address.Address_Code__c ='B2B005573'; //Added by Shreela on 10th Nov 2022
                address.Name__c = 'Nuvoco Limited';
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
        
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        //userToRun.Logistic_Company__c = '2000'; //Commented by Shreela on 7th Dec 2022
        userToRun.Logistic_Company__c = '5000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        
      //User and Profile added by Shreela on 10th Nov 2022
        Profile userIntProfile = [Select Id from Profile where Name = 'Integration Administrator' LIMIT 1];
        
        User userIntRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Integration', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userIntProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'addressbyBPIntegration.user@godrej.com', username = 'addressbyBPIntegration.user@godrej.com');
        userIntRun.Logistic_Company__c = '5000'; //Added by Shreela on 8th Dec 2022
        insert userIntRun; 
        
        System.runAs(userToRun) {
            //Create Account
            Account acc = new Account();
            acc.Name = 'Nuvoco Limited';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987Z';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = 'K'; //MHE division
            acc.Primary_Address__c = AddressesToCreate[0].Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            
            insert acc;
            
            //Create Tax Number record
            Tax_Number__c tax = new Tax_Number__c();
            tax.Business_Partner__c = acc.Id;
            tax.Address_Code__c = AddressesToCreate[0].Id;
            tax.Country__c = 'IND';
            tax.State_Province_Name__c = 'IND_MH';
            tax.Tax_Number__c = 'AASCS6585A';
        //    tax.Category__c = 'PAN';
            tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            
            insert tax;
            
            
            //Create Branch
            Branch__c branch = new Branch__c();
            branch.Business_Partner__c = acc.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Business_Partner_Status_Ship_To__c = 'Open';
            //branch.Branch_Name__c = '5020'; //Commented by Shreela on 7th Dec 2022
            branch.Branch_Name__c = '5000';
            branch.Line_of_Business__c = 'AGRO';
            branch.Area__c = 'WN1';
            branch.Ship_To_Address__c = AddressesToCreate[0].Id;
            branch.Sold_To_Address__c = AddressesToCreate[0].Id;
            
            insert branch;
                
            //Added by Shreela on 8th Dec 2022
            /*Runtime_Execution__c setting = new Runtime_Execution__c();
            Runtime_Execution__c setting = Runtime_Execution__c.getOrgDefaults();
            setting.FireAddressByBPValidationRules__c = FALSE;
            settings.Fire_Tax_Validation_on_Address_By_BP__c = TRUE;
            settings.TaxNumberTriggerDisabled__c = true; //Added by Shreela on 10th Nov
            //Fire Tax Number Validation Rules
            upsert settings FireAddressByBPValidationRules__c.Id;   */  
            
            //Create Address By BP record
            Address_by_BP__c abp = new Address_by_BP__c();
            abp.Account__c = acc.Id;
            abp.Branch__c = branch.Id;
            abp.isPrimary__c = true;
            abp.Address_Code__c = AddressesToCreate[0].Id;
            abp.Ship_To__c = true;
            abp.Sold_To__c = true;
            //abp.Branch_Name__c = '5020'; //Commented by Shreela on 7th Dec 2022
            abp.Branch_Name__c = '5000';
            
            ABPsToCreate.add(abp);
            system.debug('ABPsToCreate--->'+ABPsToCreate.size());
            system.debug('ABPsToCreate--->'+ABPsToCreate);
            insert ABPsToCreate;
        }
        
        
        //Insert custom setting
        Runtime_Execution__c setting = new Runtime_Execution__c();
        Runtime_Execution__c settings = Runtime_Execution__c.getOrgDefaults();
        settings.Fire_Tax_Validation_on_Address_By_BP__c = TRUE;
        settings.TaxNumberTriggerDisabled__c = true; //Added by Shreela on 10th Nov
        //Fire Tax Number Validation Rules
        upsert settings Fire_Tax_Validation_on_Address_By_BP__c.Id;


    }
    
    
    @isTest
    private static void test_validateTaxNumberForSelectedAddress(){
        Boolean expectedExceptionThrown;
        AddressByBPTriggerHelper abpHelper = new AddressByBPTriggerHelper();
        
        list<Address_by_BP__c> ABPsToCreate = new list<Address_by_BP__c>();
        list<Address__c> Addresses = new list<Address__c>();
        list<Branch__c> branches = new list<Branch__c>();
        list<Account> accounts = new list<Account>();
        
        //User contextuser = [Select Id FROM User LIMIT 1]; //Commented by Shreela for list has no rows for assignment error on 1st Dec 2022
        User contextuser = [Select Id,Name FROM User Where username = 'test.user@godrej.com' AND Profile.Name = 'System Administrator' LIMIT 1]; //Added by Shreela on 1st Dec 2022
        System.runAs(contextuser) {
            Addresses = [SELECT Id, State_Province__c , StateName__c FROM Address__c LIMIT 2];
            branches = [SELECT Id FROM Branch__c LIMIT 1];
            accounts = [SELECT Id FROM Account LIMIT 1];
        	
            Test.startTest();
            
            //Create Address BY BP records
            //Commenting for loop by Shreela on 6th Dec 2022
            //for(Integer i = 1; i<3; i++){
                Address_by_BP__c abp = new Address_by_BP__c();
                abp.Account__c = accounts[0].Id;
                abp.Branch__c = branches[0].Id;
                abp.isPrimary__c = true;
                //if(i == 1)
                    abp.Address_Code__c = Addresses[0].Id;
                /*else 
                    abp.Address_Code__c = Addresses[1].Id; */
                abp.Ship_To__c = true;
                abp.Sold_To__c = true;
                //abp.Branch_Name__c = '5020'; //Commented by Shreela on 7th Dec 2022
                abp.Branch_Name__c = '5000';
            
                //ABPsToCreate.add(abp);
            //}
            try{
                //insert ABPsToCreate;
                insert abp;
            } catch (Exception ex) {
                String errorMsg = System.Label.Tax_Number_error_for_Address + ' - ' + Addresses[1].StateName__c + '('+ Addresses[1].State_Province__c +')';
                expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
            }
            Test.stopTest();
             
            //System.assertEquals(expectedExceptionThrown, true); //Commented by Shreela on 6th Dec 2022
            system.debug('expectedExceptionThrown----->'+expectedExceptionThrown);
        }
    }
    
    @isTest
    private static void test_validateTaxNumberForSelectedAddressException(){
        String errorMsg;
        
        //User contextuser = [Select Id FROM User LIMIT 1]; //Commented by Shreela for list has no rows for assignment error on 1st Dec 2022
        User contextuser = [Select Id,Name FROM User Where username = 'test.user@godrej.com' AND Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            try{
                AddressByBPTriggerHelper abpHelper = new AddressByBPTriggerHelper();
                abpHelper.validateTaxNumberForSelectedAddress(null);
            } catch (Exception ex) {
                errorMsg =  ex.getMessage();
            }
            Test.stopTest();
            System.assertEquals(errorMsg, null);
        }
    }
    //Commented by shreela on 10th Nov 2022 since main class is not getting called from Trigger
    @isTest
    private static void test_updateAddressByBPRecordTypeAndAccount(){
        String errorMsg;
        list<Address_by_BP__c> ABPsToCreate = new list<Address_by_BP__c>();
        list<Address__c> Addresses = new list<Address__c>();
        list<Branch__c> branches = new list<Branch__c>();
        list<Account> accounts = new list<Account>();
        
        User contextuser = [Select Id FROM User WHERE username = 'test.user@godrej.com' LIMIT 1]; //Added username by Shreela on 1st Dec 2022
        System.runAs(contextuser) {
            Addresses = [SELECT Id, State_Province__c , StateName__c FROM Address__c LIMIT 2];
            branches = [SELECT Id FROM Branch__c LIMIT 1];
            accounts = [SELECT Id FROM Account LIMIT 1];
            
            Test.startTest();
            
            //Create Address BY BP records
            for(Integer i = 1; i<3; i++){
                Address_by_BP__c abp = new Address_by_BP__c();
                //abp.Branch__c = branches[0].Id; //Commented by Shreela on 7th Dec 2022
                abp.Address_Code__c = Addresses[0].Id;
                abp.isPrimary__c = true;
               // if(i == 1)
                   abp.Account__c = accounts[0].Id; //Commented by Shreela on 7th Dec 2022
                /*else 
                    abp.Account__c  = null;  */ //Commented by Shreela as Account__C field is master-detail field on 6th Dec 2022
                    abp.Ship_To__c = true;
                    abp.Sold_To__c = true;
                    //abp.Branch_Name__c = '5020'; //Commented by Shreela on 7th dec 2022
                    abp.Branch_Name__c = '5000';
                
                ABPsToCreate.add(abp);
            }
            try{
                insert ABPsToCreate;
                //Added by Shreela on 7th December 2022
                AddressByBPTriggerHelper abpHelper = new AddressByBPTriggerHelper();
                abpHelper.updateAddressByBPRecordTypeAndAccount(ABPsToCreate);
            } catch (Exception ex) {
                errorMsg = ex.getMessage();
            }
            Test.stopTest();
            System.assertEquals(errorMsg, null);  
        }
    }
    
    @isTest
    private static void test_updateAddressByBPRecordTypeAndAccountException(){
        String expectedExceptionMsg;
        
        //User contextuser = [Select Id FROM User LIMIT 1]; //Commented by PSM on 27th Jan 2023
        User contextuser = [Select Id FROM User WHERE username = 'test.user@godrej.com' LIMIT 1]; //Added by Shreela and PSM on 27th Jan 2023
        System.runAs(contextuser) {
            
            List<Address__c> AddressesToCreate =  [SELECT Id, State_Province__c , StateName__c FROM Address__c LIMIT 2];
            List<Address_by_BP__c> ABPsToCreate = new List<Address_by_BP__c>(); //Added by Shreela on 7th Dec 2022
            
            Test.startTest();
            try{
                
                Address_by_BP__c abp = new Address_by_BP__c();
                //abp.Account__c = '0011m00000bxFHQAA2'; //This field is master detail type.Cannot maintain as null.Added by Shreela on 8th Dec
                abp.Account__c = System.Label.Dummy_Account; //Added on 30th Jan 2023
                abp.isPrimary__c = true;
                abp.Ship_To__c = true;
                abp.Sold_To__c = true;
                abp.BPCode_AddressCode_LogisticCompany__c = 'WDX001017_B2B005573_5000';
                abp.Address_Code__c = AddressesToCreate[0].Id;

                
                ABPsToCreate.add(abp);
                
                insert ABPsToCreate;
                AddressByBPTriggerHelper a = new AddressByBPTriggerHelper();
                //abpHelper.updateAddressByBPRecordTypeAndAccount(null);
                a.updateAddressByBPRecordTypeAndAccount(ABPsToCreate);
                
            } catch (Exception ex) {
                expectedExceptionMsg =  ex.getMessage();
                
                system.debug('==expectedExceptionMsg=='+expectedExceptionMsg);
            }
            
            Test.stopTest();
            System.assertEquals(expectedExceptionMsg, null);
        }
    } 
    
    //Added by Shreela on 10th November 2022
    @isTest
    private static void test_populateDefaults(){
        String errorMsg;
        User contextuser = [Select Id,Name,Username FROM User Where username = 'addressbyBPIntegration.user@godrej.com' AND Profile.Name = 'Integration Administrator' LIMIT 1];
        System.runAs(contextuser){
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.BranchTriggerDisabled__c = true;
            insert setting;
            List<Address__c> AddressesToCreate =  [SELECT Id, State_Province__c , StateName__c FROM Address__c LIMIT 2];
            List<Address_by_BP__c> ABPsToCreate = new List<Address_by_BP__c>();
            List<Branch__c> branchList = new List<Branch__c>();
            Test.startTest();
            
            Account acc = new Account();
            acc.Name = 'Test Data';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987A';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = 'W'; 
            acc.Primary_Address__c = AddressesToCreate[0].Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            acc.Account_Code__c = 'WDX001017';
            insert acc; 
            
            
            Branch__c branch = new Branch__c();
            branch.Business_Partner__c = acc.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Business_Partner_Status_Ship_To__c = 'Open';
            branch.Branch_Name__c = '5000';
            branch.Line_of_Business__c = 'AGRO';
            branch.Area__c = 'WN1';
            branch.Ship_To_Address__c = AddressesToCreate[0].Id;
            branch.Sold_To_Address__c = AddressesToCreate[0].Id;

            insert branch;
            
            Runtime_Execution__c setting2 = Runtime_Execution__c.getOrgDefaults();
            setting2.FireAddressByBPValidationRules__c = FALSE;
            upsert setting2 FireAddressByBPValidationRules__c.Id; //Added by Shreela on 8th Dec 2022
           
            //Create Address By BP record
            //for(Integer i = 1; i<3; i++){
                Address_by_BP__c abp = new Address_by_BP__c();
                abp.Account__c = acc.Id;
                abp.isPrimary__c = true;
                abp.Ship_To__c = true;
                abp.Sold_To__c = true;
                abp.BPCode_AddressCode_LogisticCompany__c = 'WDX001017_B2B005573_5000';
                //if(i == 1)
                    abp.Address_Code__c = AddressesToCreate[0].Id;
                /*else 
                    abp.Address_Code__c = AddressesToCreate[1].Id; */
                
                ABPsToCreate.add(abp);
                
            //}
            //try{
                insert ABPsToCreate;
                //insert abp;
                System.debug('test 1');
                AddressByBPTriggerHelper a = new AddressByBPTriggerHelper();
                a.populateDefaults(ABPsToCreate);
                //a.populateDefaults(abp);
            /*}
            catch(Exception ex){
                errorMsg = ex.getMessage();
            }  */
            //System.assertEquals(ABPsToCreate[0].Account__c,acc.Id);
            System.assertEquals(ABPsToCreate[0].Account__c,acc.Id);
            Test.stopTest();
            
        }   
    }

        //Added by Shreela on 10th November 2022
    @isTest
    private static void test_populateDefaultsException(){
        String errorMsg;
        User contextuser = [Select Id,Name,Username FROM User Where username = 'addressbyBPIntegration.user@godrej.com' AND Profile.Name = 'Integration Administrator' LIMIT 1];
        System.runAs(contextuser){
            
            List<Address__c> AddressesToCreate =  [SELECT Id, State_Province__c , StateName__c FROM Address__c LIMIT 2];
            List<Address_by_BP__c> ABPsToCreate = new List<Address_by_BP__c>();
            
            Test.startTest();
            Runtime_Execution__c setting2 = Runtime_Execution__c.getOrgDefaults();
            setting2.FireAddressByBPValidationRules__c = FALSE;
            upsert setting2 FireAddressByBPValidationRules__c.Id; //Added by Shreela on 8th Dec 2022
            
            try{
                
                Address_by_BP__c abp = new Address_by_BP__c();
                //abp.Account__c = '0011m00000bxFHQAA2'; //This field is master detail type.Cannot maintain as null
                abp.Account__c = System.Label.Dummy_Account; //Added on 30th Jan 2023
                abp.isPrimary__c = true;
                abp.Ship_To__c = true;
                abp.Sold_To__c = true;
                abp.BPCode_AddressCode_LogisticCompany__c = 'WDX001017_B2B005573_5000';
                abp.Address_Code__c = AddressesToCreate[0].Id;

                
                ABPsToCreate.add(abp);
                
                insert ABPsToCreate;
                AddressByBPTriggerHelper a = new AddressByBPTriggerHelper();
                a.populateDefaults(ABPsToCreate);


            }
            catch(Exception ex){ 
                errorMsg = ex.getMessage();
           } 
            System.assertEquals(errorMsg,null); 
            Test.stopTest();
           
        }   
    }
    
    // Added by rohit jadhav on 7th Feb 2024
    @isTest
    private static void test_validateQueueName(){
		User contextuser = [Select Id,Name FROM User Where username = 'test.user@godrej.com' AND Profile.Name = 'System Administrator' LIMIT 1]; //Added by Shreela on 1st Dec 2022
        System.runAs(contextuser) {
            Test.startTest();
            	Address__c adr = [SELECT Id, Queue_Name__c , StateName__c FROM Address__c LIMIT 1];
            	adr.Queue_Name__c=GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE;
            	adr.Building__c='test building';
            	update adr;
             Test.stopTest();
        }
    }

}