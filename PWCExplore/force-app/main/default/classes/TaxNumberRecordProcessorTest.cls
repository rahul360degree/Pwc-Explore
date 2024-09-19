@isTest
public with sharing class TaxNumberRecordProcessorTest {
    @TestSetup static void createData(){
        list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
        list<Address__c> AddressesToCreate = new list<Address__c>();
        
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
        
         //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userTNRPT@godrej.com', username = 'test.userTNRPT@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        //User and Profile added by Shreela on 10th Nov 2022
        Profile userIntProfile = [Select Id from Profile where Name = 'Integration Administrator' LIMIT 1];
        
        User userIntRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Integration', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userIntProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'integration.user@godrej.com', username = 'integration123.user@godrej.com', Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT);
        insert userIntRun;
        
        System.runAs(userToRun) {
            //Create Account
            Account acc = new Account();
            acc.Name = 'Nuvoco Plant Pune';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987Z';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = 'K'; //MHE division
            acc.Primary_Address__c = AddressesToCreate[0].Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            
            insert acc;
			//Tax record for PAN
			Tax_Number__c taxPAN = new Tax_Number__c();
            taxPAN.Business_Partner__c = acc.Id;
            taxPAN.Country__c = 'IND';
            taxPAN.Tax_Number__c = 'AASCS6585A';
            taxPAN.Category__c = 'PAN';
            taxPAN.Un_registered__c = 'No';
            taxPAN.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            //Need to insert Tax record for PAN before GST or validation error
            insert taxPAN;
            
            //Tax record for GST for the corresponding PAN
            Tax_Number__c taxGST = new Tax_Number__c();
            taxGST.Business_Partner__c = acc.Id;
            taxGST.Country__c = 'IND';
            taxGST.Tax_Number__c = '23AASCS6585A23D';
            taxGST.Category__c = 'GSTIN';
            taxGST.Un_registered__c = 'No';
            taxGST.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
            
            insert taxGST;
        }
        
    }
    
        @isTest private static void panLengthValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASCS6585';
                    tax.Category__c = 'PAN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.PAN_Number_length;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }
            System.assertEquals(expectedExceptionThrown, true, 'PAN Legth Validated'); //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    @isTest private static void panPatternFiveCharsValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASC66585A';
                    tax.Category__c = 'PAN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.PAN_first_five_characters;
                    system.debug(ex.getMessage());
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'PAN Pattern five alpha characters Validated'); //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void panPatternNumCharsValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASCSAASDA';
                    tax.Category__c = 'PAN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.PAN_five_to_nine_characters_message;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'PAN Pattern num characters Validated'); //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }	
        
    	@isTest private static void panPatternLCharValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASCS65855';
                    tax.Category__c = 'PAN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.PAN_last_character_should_be_alphabetic;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'PAN Pattern bottom Alpha character Validated'); //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void gstLengthValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASCS6585';
                    tax.Category__c = 'GSTIN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.GST_character_limit;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'GSTIN Legth Validated'); //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void gstPatternTwoCharsValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = 'AASCS6585A67584';
                    tax.Category__c = 'GSTIN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.GST_first_two_characters;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'GSTIN Num Chars Pattern Validated');//change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void gstPatternMidCharsValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = '23345675A675845';
                    tax.Category__c = 'GSTIN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.GST_three_to_seven_should_be_alphabetic;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'GSTIN Mid Alpha Chars Pattern Validated');//change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void gstPatternPostMidCharsValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Country__c = 'IND';
                    tax.Tax_Number__c = '23ASDERASDE5845';
                    tax.Category__c = 'GSTIN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.GST_character_eight_to_eleven_should_be_numeric;
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }   
            System.assertEquals(expectedExceptionThrown, true, 'GSTIN Post Mid Num Chars Pattern Validated');//change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
        }
    
    	@isTest private static void gstPatternValidationShouldAlertUser(){
            Boolean expectedExceptionTwo;
            Boolean expectedExceptionThree;
            Boolean expectedExceptionEight;
            Boolean expectedExceptionThrownTwelth;
            Boolean expectedExceptionThrownAlphaNum;
            
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                Account acc = [SELECT Id From Account Limit 1]; 
                List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
                Test.startTest();
                    Tax_Number__c tax = new Tax_Number__c();
                    tax.Business_Partner__c = acc.Id;
                    tax.Address_Code__c = AddressesToCreate[0].Id;
                    tax.Country__c = 'IND';
                    tax.State_Province_Name__c = 'IND_MH';
                    tax.Tax_Number__c = 'AA34567ASDE58_5';
                    tax.Category__c = 'GSTIN';
                	tax.Un_registered__c = 'No';
                    tax.Tax_Number_Ext__c = 'WDX001015___PAN_AASCS6585A';
                try {
                    insert tax;
                } catch (Exception ex) {
                    String errorMsgTwo = System.Label.GST_first_two_characters;
                    String errorMsgThree = System.Label.GST_three_to_seven_should_be_alphabetic;
                    String errorMsgEight = System.Label.GST_character_eight_to_eleven_should_be_numeric;
                    String errorMsgTwelth = System.Label.GST_twelfth_character_should_be_alphabetic;
                    String errorMsgAlphaNum = System.Label.GST_characters_thirteen_to_fifteen_should_be_only_alphabetic_or_numeric;
                    
                    expectedExceptionTwo =  ex.getMessage().contains(errorMsgTwo) ? true : false;
                    expectedExceptionThree =  ex.getMessage().contains(errorMsgThree) ? true : false;
                    expectedExceptionEight =  ex.getMessage().contains(errorMsgEight) ? true : false;
                    expectedExceptionThrownTwelth =  ex.getMessage().contains(errorMsgTwelth) ? true : false;
                    expectedExceptionThrownAlphaNum =  ex.getMessage().contains(errorMsgAlphaNum) ? true : false;
                }
            	Test.stopTest();
            }
            
            System.assertEquals(expectedExceptionTwo, true, 'GSTIN Num Chars Pattern Validated');  //change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX
            System.assertEquals(expectedExceptionThree, true, 'GSTIN Mid Alpha Chars Pattern Validated'); 
            System.assertEquals(expectedExceptionEight, true, 'GSTIN Post Mid Num Chars Pattern Validated'); 
            System.assertEquals(expectedExceptionThrownTwelth, true, 'GSTIN Pattern Twelth Char Validated'); 
            System.assertEquals(expectedExceptionThrownAlphaNum, true, 'GSTIN Pattern AlphaNum Validated'); 
        }
    
    	@isTest private static void taxUpdateValidationShouldAlertUser(){
            Boolean expectedExceptionThrown;
            
            User contextuser = [Select Id FROM User WHERE username = 'test.userTNRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
            
            system.runAs(contextuser){
                    Tax_Number__c tax = [SELECT Id, Tax_Number__c From Tax_Number__c WHERE Category__c = 'GSTIN' Limit 1]; 
                Test.startTest();
                    tax.Tax_Number__c = '23AASCS6585D23D';
                try {
                    update tax;
                } catch (Exception ex) {
                    String errorMsg = System.Label.No_matching_PAN_from_GST;
                    
                    expectedExceptionThrown =  ex.getMessage().contains(errorMsg) ? true : false;
                }
            	Test.stopTest();
            }
            
            System.assertEquals(expectedExceptionThrown, true, 'GSTIN No Mtaching PAN');//change assertnotequals to assertEquals by Mrunali 18 JAN 2024 HOT FIX 
           
        }
    
    /*------------------------------------------------------------------------
Author:       Shreela Nair
Company:      GITL
Description:  Method for populateDefaults and createAccountMap in TaxNumberRecordProcessor class
Inputs:       
Test Class:   TaxNumberRecordProcessorTest 
History       07-11-2022

----------------------------------------------------------------------------*/
    @isTest private static void getpopulateDefaults(){
        User contextuser = [Select Id,Name FROM User  where Profile.Name = 'Integration Administrator' AND Name = 'Integration User' LIMIT 1];
        
        system.runAs(contextuser){
            List<Address__c> AddressesToCreate = [SELECT Id from Address__c];
            Test.startTest();
            //Create Account
            Account acc = new Account();
            acc.Name = 'Nuvoco Plant Mumbai';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG0987Y';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = 'W'; 
            acc.Primary_Address__c = AddressesToCreate[0].Id;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            acc.Account_Code__c = 'WDX001016';
            insert acc;
            
            
            
            Tax_Number__c tax = new Tax_Number__c();
            tax.Business_Partner__c = acc.Id;
            tax.Country__c = 'IND';
            tax.Tax_Number__c = '23ASDERASDE5846';
            tax.Category__c = 'GSTIN';
            tax.Un_registered__c = 'No';
            tax.Tax_Number_Ext__c = 'WDX001016___PAN_AASCS6585A';
            try {
                insert tax;
            } catch (Exception ex) {
                
            }
            Test.stopTest();
                        
        }  
        System.assertEquals(contextuser.Name,'Integration User');
    }
}