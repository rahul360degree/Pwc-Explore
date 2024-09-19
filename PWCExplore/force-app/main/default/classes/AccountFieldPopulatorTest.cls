@isTest
public class AccountFieldPopulatorTest {
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
                address.Name__c = 'Nuvoco Plant Pune'.toUpperCase();
                address.Telephone__c = '8765432111';
                address.Email__c = 'punetest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[0].Id;
            } else {
                address.Name__c = 'Nuvoco Plant Delhi'.toUpperCase();
                address.Telephone__c = '8765432110';
                address.Email__c = 'delhitest1234@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[1].Id;
            }
            AddressesToCreate.add(address);
        }
        insert AddressesToCreate;
        
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        // Create User record.
        User userManager = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                    languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                    timezonesidkey = 'Asia/Kolkata', email = 'test.userManager@godrej.com', username = 'test.userManager@godrej.com', Business_Unit__c = 'L');
        
        userManager.IsActive = true;
        userManager.Allow_Business_Account_Creation__c = false;
        userManager.Logistic_Company__c = '2000';
        userManager.Area_Code__c = 'WN1';
        insert userManager;
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userAccAFPT@godrej.com', username = 'test.userAccAFPT@godrej.com', Business_Unit__c = 'W');
        
        userToRun.IsActive = true;
        UserToRun.ManagerId=userManager.Id;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        
        //with name__c = null
        Address__c addr = createPrimaryAddress();
        insert addr;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25389')
            .setPersona(GlobalConstants.const_engineer_persona)
            .getSavedTestRecord();
        
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name='TestAccountConstruction', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13777',
                                      Industry='Apparel',
                                      PAN__c='CAJAJ1234T',
                                      Business_unit__c='N',
                                      Sub_Division__c='B2B',
                                      Type='I',
                                      CIN__c='124',
                                      User__c=contextuser.id,
                                      RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account')
                                     );
            
            insert acc;
            test.stopTest();
        }
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id);
        return addr;
    }
    
    @isTest private static void testPersonAccount(){
        User contextuser = [Select Id FROM User where username = 'test.userAccAFPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            test.startTest();
            Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'W', Branch_Code__c = 'P',Account_Code__c='WDX00001');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            insert accountRecord;
            RecordType keyrcdtype =[select Id, Name from RecordType where sObjectType='Account' and Name ='Key Account' Limit 1];
            Account accountRecordKey = new Account(Name='TestKey', Industry='Apparel', Type='2', Business_Unit__c = 'K');
            accountRecordKey.RecordTypeId =keyrcdtype.Id;
            insert accountRecordKey;
            test.stopTest();
        }
    }
    
    @isTest private static void test_NoPermissionToCreateBusinessAccount(){
        User contextuser = [Select Id FROM User where username = 'test.userAccAFPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            test.startTest();
            try{
                Account accountRecord = new Account(Name='TestB2B', Industry='Apparel', Type='3', Business_Unit__c = 'K');
                accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
                insert accountRecord;              
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('You do not have permission to create business account for this business unit'));
            }
            test.stopTest();
        }
    }
    
    @isTest private static void test_CreateBusinessAccount(){
        User contextuser = [Select Id FROM User where username = 'test.userAccAFPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            test.startTest();
            Account parentAcc = new Account(Name='ABCDE1234', 
                                            Account_Series__c=System.Label.Parent_Account_Series,
                                            Account_code__c=System.Label.Parent_Account_Series+'123456',
                                            Business_Unit__c=null, 
                                            Industry='Apparel',
                                            PAN__c='ABCDE1234S');
            parentAcc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert parentAcc;
            Account childAccountRecord = new Account(Name='ABCDE1234',
                                                     Industry='Apparel',
                                                     PAN__c='ABCDE1234S',
                                                     ParentId=parentAcc.Id);
            childAccountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert childAccountRecord;
            test.stopTest();
        }
    }
    
    @isTest private static void test_PopulateBUFromAccountCodeForASPType(){
        User contextuser = [Select Id, Business_Unit__c,ManagerId FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        System.runAs(contextuser) {
            test.startTest();
            Account accRec = new Account(Name='ABCDE12341', 
                                         Account_Series__c='3LA',
                                         Account_code__c='3W13451',
                                         Industry='Apparel1',
                                         PAN__c='ABCDE1234S1',
                                         Business_unit__c='L',
                                         Locks_Regional_Manager__c=contextuser.ManagerId);
            accRec.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert accRec;
            Account acc = new Account(Name='ABCDE1234', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13456',
                                      Industry='Apparel',
                                      PAN__c='ABCDE1234S');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            test.stopTest();
        }
    }
    
    @isTest private static void test_PopulateBUFromAccountCodeForNonASPType(){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name = 'ABCDE1234', 
                                      Account_code__c = 'W13456',
                                      Industry = 'Apparel',
                                      PAN__c = 'ABCDE1234S');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            test.stopTest();
        }
    }
    
    @isTest private static void test_AddessNameOnAddress(){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        List<Address__c> primaryAddress = [Select Id,Name__c From Address__c Where ZipCode__c != null And Name__c = '' limit 1];
        if(primaryAddress.size() > 0){
            System.runAs(contextuser) {
                test.startTest();
                primaryAddress[0].Name__c = 'Test'.toUpperCase();
                update primaryAddress[0];
                Account acc = new Account(Name = primaryAddress[0].Name__c, 
                                          Account_code__c = 'W13456',
                                          Industry = 'Apparel',
                                          PAN__c = 'QBCDE1234S',
                                          Primary_Address__c = primaryAddress[0].Id);
                acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
                insert acc;
                test.stopTest();
            }
            
            List<Account> acc = [Select Id, Name From Account Where Name = 'QBCDE1234' limit 1];
            if(acc.size() == 1){
                List<Address__c> add = [Select Id, Name From Address__c Where Id = :primaryAddress[0].Id limit 1];
                System.assert(String.isNotBlank(add[0].Name));
            }
        }
    }
    
    @isTest private static void test_convertAccountNameToUpperCase(){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name = 'dgf1234', 
                                      Account_code__c = 'W13456',
                                      Industry = 'Apparel',
                                      PAN__c = 'AVFDE1234S');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            Account accToUpdate = new Account(Id = acc.Id,
                                              Name = 'dgf12');
            update accToUpdate;
            test.stopTest();
        }
    }
    
    @isTest private static void accountNameUpdateShouldUpdateAddressByBPRecord(){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name = 'dgf123',
                                      Account_code__c = 'W13456',
                                      Industry = 'Apparel',
                                      PAN__c = 'AVFDE1234S',
                                      Business_Unit__c = contextuser.Business_Unit__c);
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            Address_by_BP__c abp = new Address_by_BP__c();
            abp.Account__c = acc.Id;
            abp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Address_by_BP__c', 'B2B_Additional_Address');
            AddressByBPTriggerHandler.TriggerDisabled = true;
            insert abp;
            Account accToUpdate = new Account(Id = acc.Id,
                                              Name = 'DGF12');
            update accToUpdate;
            test.stopTest();
            Address_By_BP__c abpUpdated = [SELECT Account_Text__c FROM Address_By_BP__c WHERE Id =:abp.Id];
            system.assertEquals(accToUpdate.Name.toUpperCase(), abpUpdated.Account_Text__c, 'Address By BP record has been updated with Account Name');
        }
    }
    
    @isTest
    private static void createEntitlementTest(){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name='ABCDE1234', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13456',
                                      Industry='Apparel',
                                      PAN__c='ABCDE1234S',
                                      Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT,
                                      Type = 'W');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            
            List<Entitlement> ent = [Select Id FROM Entitlement WHERE AccountId =: acc.Id];
            System.assertEquals(1, ent.size());
            test.stopTest();
        }
    }
    
    @isTest
    private static void checkMandatoryFieldsForCONSTTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25345')
            .setPersona(GlobalConstants.const_engineer_persona)
            .getSavedTestRecord();
        
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name='ABCDE1234', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13456',
                                      Industry='Apparel',
                                      PAN__c='ABCDE1234S',
                                      Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT
                                     );
            try{
                acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
                insert acc;
                
                acc.Costing_Sheet__c  = false;
                acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
                update acc;
            }catch(Exception ex)   {
                
            }
            test.stopTest();
        }
    }   
    
    @isTest
    private static void populateDefaultsConstructionTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25345')
            .setPersona(GlobalConstants.const_manager_persona)
            .getSavedTestRecord();
        
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name='ABCDE1234', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13456',
                                      Industry='Apparel',
                                      PAN__c='ABCDE1234S',
                                      Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT
                                     );
            
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            
            test.stopTest();
        }
    }
    
    @isTest private static void convertToBDAccountTest() {
        Account bDAccount = new Account(   Name='ABCDE1234', 
                                        Account_Series__c='WIX',
                                        Account_code__c='WIX123456',
                                        Industry='Apparel',
                                        PAN__c='BLYPS1234S',
                                        Is_BD_Account__c = true,
                                        Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT
                                       );
        
        bDAccount.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        test.startTest();
        insert bDAccount;
        Account accToUpdate = new Account(Id = bDAccount.Id, Name = 'Test123');          
        update accToUpdate;  
        test.stopTest();
    } 
    
    @isTest
    private static void populateDefaultsConstruction_Test() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25345')
            .setPersona(GlobalConstants.const_manager_persona)
            .getSavedTestRecord();
        
        System.runAs(contextuser) {
            test.startTest();
            Account acc = new Account(Name='ABCDE1234', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13456',
                                      Industry='Apparel',
                                      PAN__c='ABCDE1234S',
                                      Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT
                                     );
            
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
            
            test.stopTest();
            // system.assertEquals('ABCDE1234S',acc.PAN__c);//gcp22 edited by dhiren 03/04/2023
        }
    }
    
    @isTest private static void convertToBDAccount_Test() {
        Account bDAccount = new Account(   Name='ABCDE1234', 
                                        Account_Series__c='WIX',
                                        Account_code__c='WIX123456',
                                        Industry='Apparel',
                                        PAN__c='BLYPS1234S',
                                        Is_BD_Account__c = true,
                                        Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT
                                       );
        
        bDAccount.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        test.startTest();
        insert bDAccount;
        Account accToUpdate = new Account(Id = bDAccount.Id, Name = 'Test123');          
        update accToUpdate;  
        test.stopTest();
        // system.assertEquals( bDAccount.Id,accToUpdate.Id);//gcp22 edited by dhiren 03/04/2023
    } 
    //all construction test methods Added by pankaj on 3rd may 2023   
    @isTest
    private static void constructionWpsMumTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(		
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
		/*Ended by poonam (SCF - 102)*/
            
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000';
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsPuneTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){   
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_PUNE;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000';
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    
    @isTest
    private static void constructionRmcMumTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;    
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000';
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    
    @isTest
    private static void constructionRmcAmbTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){   
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_AMB;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;   
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000'; 
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    
    @isTest
    private static void constructionRmcPuneEastTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_EAST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;  
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000';
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    
    @isTest
    private static void constructionRmcPuneWestTest(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_WEST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;   
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            /*Added by poonam (SCF - 102)*/
            acc.Business_Partner_Type__c = 'RMC';
            acc.Financial_Customer_Group__c= 'C_DSL';
            acc.Credit_Rating__c = 'CNH';
            acc.Exchange_Rate_Type__c= 'SLS';
            acc.Credit_Limit__c = 36;
            acc.Invoicing_Method__c= 'AA1';
            acc.Payment_Terms__c = '000';
            /*Ended by poonam (SCF - 102)*/
            update acc;
        }
    }
    
    @isTest
    private static void constructionTest1(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_WEST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 12;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionTest2(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_WEST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionTest3(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_WEST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionTest4(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_WEST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = -6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionTest5(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_EAST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 12;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcPuneEastTest6(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_EAST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcPuneEastTest7(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_EAST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcPuneEastTest8(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){    
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_PUNE_EAST;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = -6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    
    @isTest
    private static void constructionRmcAmbTest9(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_AMB;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 12;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcAmbTest10(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_AMB;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcAmbTest11(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){   
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_AMB;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcAmbTest12(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_AMB;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = -6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcMumTest13(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
            
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 12;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcMumTest14(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 6;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcMumTest15(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){   
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionRmcMumTest16(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_RMC;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_RMC_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = -8;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsMumTest17(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){ 
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 9;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsMumTest18(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_MUM;
            acc.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
            acc.Profit__c = 3;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsMumTest19(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_MUM;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsPuneTest20(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_PUNE;
            acc.Profit__c = 3;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsPuneTest21(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){   
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_PUNE;
            acc.Profit__c = 9;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
    @isTest
    private static void constructionWpsPuneTest22(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User constructionuser = [Select id from user where Salary_code__c='25389'];
        Account acc = [Select id from Account where Name='TestAccountConstruction'];
        System.runAs(constructionuser){  
            /*Added by poonam (SCF - 102)*/
            Branch__c branchRec = new Branch__c(
            Business_Partner__c = acc.Id
        );
        insert branchRec;
            
            Tax_Number__c taxnumberRec = new Tax_Number__c(
            Business_Partner__c = acc.Id,
			Tax_Number__c = 'FGHJK4567W',
            Category__c = 'PAN',
            Un_registered__c = 'No'
        );
        insert taxnumberRec;
            /*Ended by poonam (SCF - 102)*/
            acc.Construction_LOB__c = GlobalConstants.Construction_LOB_WPS;
            acc.Construction_Sub_LOB__c = GlobalConstants.Construction_subLOB_WPS_PUNE;
            acc.Profit__c = 1;
            acc.Approval_Status__c = GlobalConstants.Submitted_for_Approval;
            update acc;
        }
    }
    
}