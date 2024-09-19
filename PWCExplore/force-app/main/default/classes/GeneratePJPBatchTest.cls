@isTest
private class GeneratePJPBatchTest {
    @testsetup
    public static void testData() {
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
                address.Name__c = 'Nuvoco Plant Pune';
                address.Telephone__c = '8765432111';
                address.Email__c = 'punetest6534@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[0].Id;
            } else {
                address.Name__c = 'Nuvoco Plant Delhi';
                address.Telephone__c = '8765432110';
                address.Email__c = 'delhitest8934@nuvoco.com';
                address.ZipCode__c = ZipCodesToCreate[1].Id;
            }
            AddressesToCreate.add(address);
        }
        insert AddressesToCreate;
        List<User> Users = new List<User>();
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        Profile userProfile2 = [Select Id from Profile where Name = 'Appliances Sales User' LIMIT 1];
        // Create User record.
        User userAsAccountTeamMember = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                                timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com',
                                                Business_Unit__c = 'W',Logistic_Company__c = '2000',Area_Code__c = 'WN1');
        
        Users.add(userAsAccountTeamMember);
        //user added by pankaj on 26-10-2021 for appliances different with team role
        User userAsAccountTeamMember2 = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                                 languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile2.id,
                                                 timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'testPartner.user@godrej.com', 
                                                 Business_Unit__c = 'H',Logistic_Company__c = '2000',Area_Code__c = 'WN1');     
        Users.add(userAsAccountTeamMember2);
        
        User userAsAccountTeamMember3 = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                                 languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile2.id,
                                                 timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'testPartner2.user@godrej.com',
                                                 Business_Unit__c = 'H',Logistic_Company__c = '2000',Area_Code__c = 'WN1');       
        Users.add(userAsAccountTeamMember3);
        
        insert Users;
        //ended by pankaj
        Contact primaryContact = new Contact(LastName='TestCon' ,                 
                                             Active__c = true,                          
                                             MobilePhone = '9012342120',                 
                                             Email = 'test.con@godrej.com'  
                                            );
        insert primaryContact;
        
        List<Account> accounts = new List<Account>();
        //Interio Account Record
        Account ac = new Account(Name = 'TestB2C34',
                                 Business_Unit__c = 'W',
                                 Interio_Sub_Division__c = 'Scripts',
                                 Primary_Contact__c = primaryContact.Id);
        
        ac.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
        accounts.add(ac);
        //Appliance Account Record added by Pankaj on 26-10-2021
        Account ApplianceAccount = new Account(Name = 'TestB2C345',
                                               Business_Unit__c = 'H',
                                               Interio_Sub_Division__c = 'Scripts',
                                               Primary_Contact__c = primaryContact.Id);
        
        ApplianceAccount.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Dealer');
        accounts.add(ApplianceAccount);
        //end by Pankaj
        AccountTriggerHandler.TriggerDisabled = true;
        insert accounts;
        
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accounts[0].Id;
        atm.TeamMemberRole = 'Visual Merchandiser';
        atm.UserId = userAsAccountTeamMember.Id;
        atms.add(atm);
        
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.AccountId = accounts[1].Id;
        atm1.TeamMemberRole = 'Visual Merchandiser';
        atm1.UserId = userAsAccountTeamMember.Id;
        atms.add(atm1);
        //TeamMember added by pankaj on 26-10-2021
        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.AccountId = accounts[1].Id;
        atm2.TeamMemberRole = 'RSO';
        atm2.UserId = userAsAccountTeamMember2.Id;
        atms.add(atm2);
        
        
        AccountTeamMember atm3 = new AccountTeamMember();
        atm3.AccountId = accounts[1].Id;
        atm3.TeamMemberRole = 'Sales/Service Manager';
        atm3.UserId = userAsAccountTeamMember3.Id;
        atms.add(atm3);
        //end by Pankaj
        insert atms;
        
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'GeneratePJPApexScheduler', 
                                                                            Batch_Size__c = 10);
        insert abc;
        
        
    }
    
    
    @isTest private static void testBatch(){
        Test.startTest();
        //Error handling mechanism to default the batch size
        Integer pjpBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('GeneratePJPApexScheduler').Batch_Size__c) != null){
            pjpBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('GeneratePJPApexScheduler').Batch_Size__c);
        }
        GeneratePJPBatch b = new GeneratePJPBatch();
        database.executebatch(b, pjpBatchSize);
        Test.stopTest();
        List<PJP__c> pjps = [Select Id From PJP__c limit 5];
        System.assert(pjps.size() > 0);
    }
    
    @isTest private static void testSchedular() {
        Test.StartTest();
        GeneratePJPApexScheduler scheduler = new GeneratePJPApexScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('pjp batch Scheduler', sch, scheduler); 
        Test.stopTest();
    }
}