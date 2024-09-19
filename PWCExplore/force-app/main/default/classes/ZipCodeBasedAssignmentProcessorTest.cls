@isTest
private class ZipCodeBasedAssignmentProcessorTest {

    @testSetup
    private static void createTestRecords(){
        Runtime_Execution__c runTimeExecution = new Runtime_Execution__c();
        list<User> usersToInsert = new list<User>();
        GroupMember LeadMember1;
        GroupMember caseMember1;
        list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
        list<Zip_Code_Rule__c> ZipCodeRulesToCreate = new list<Zip_Code_Rule__c>();
        
        //Fetch Profile details
        Profile p = [select id from profile where name = 'INTERIO B2B Branch KAM User' limit 1];
        Profile applianceProfile = [select id from profile where name = 'Appliances Marketing and Service Revenue User' limit 1];
        Profile userAdminProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        
        //Create Interio B2B user record
        User r = new User();
        r.business_unit__C = 'W';
        r.email = 'ruchita.kalkar@godrej.com';
        r.lastName = 'test';
        r.firstName = 'test';
        r.profileId = p.Id;
        r.username = 'territory.salesmanager@godrej.com';
        r.Alias = 'jmx';
        r.EmailEncodingKey = 'UTF-8';
        r.LanguageLocaleKey = 'en_US';
        r.TimeZoneSidKey= 'Asia/Kolkata';
        r.LocaleSidKey = 'en_US';
        r.IsActive = true;
        r.Persona__c='Business Head';
        usersToInsert.add(r);
        
        //Create Appliance user record
        User applianceUser = r.clone(false);
        applianceUser.business_unit__C = 'H';
        applianceUser.profileId = applianceProfile.Id;
        applianceUser.username = 'territory.salemanager@godrej.com';
       
        usersToInsert.add(applianceUser);
        
        // Create admin profile Users record.
        User userToRun = r.clone(false);
        userToRun.profileid = userAdminProfile.id;
        userToRun.username = 'test.userAcc6@godrej.com';
        userToRun.Business_Unit__c = 'H';
        
        //Create Another admin profile user
        User userToRun2 = userToRun.clone(false);
        userToRun2.username = 'test.userAcc8@godrej.com';

        usersToInsert.add(userToRun);
        usersToInsert.add(userToRun2);
        
        //Insert users
        insert usersToInsert;
        
        system.runAs(userToRun){
            //Create Custom Setting Record for RunTime Execution
             runTimeExecution = new Runtime_Execution__c(Name = 'leadAssignmentTest', FireCaseValidationRules__c = true,
                                                                                FireLeadValidationRules__c = true);
            insert runTimeExecution;
        }
        
        system.runAs(userToRun2){
            //Insert Group/queues
            list<QueuesObject> queuesToInsert = new list<QueuesObject>();
            list<Group> groupsToInsert = new list<Group>();
            Group g1 = new Group(Name='Test Lead Group Q1', type='Queue');
            groupsToInsert.add(g1);
            Group g2 = new Group(Name='Test Lead Group Q2', type='Queue');
            groupsToInsert.add(g2);
            
            //Create Groups for Case
            Group g3 = new Group(Name='Test Case Group Q1', type='Queue');
            groupsToInsert.add(g3);
            Group g4 = new Group(Name='Test Case Group Q2', type='Queue');
            groupsToInsert.add(g4);
            
            insert groupsToInsert;
            
            //Create Queue for Lead
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Lead');
            queuesToInsert.add(q1);
            
            QueuesObject q2 = new QueueSObject(QueueID = g2.id, SobjectType = 'Lead');
            queuesToInsert.add(q2);
            
            //Craete Queue for Case
            QueuesObject q3 = new QueueSObject(QueueID = g3.id, SobjectType = 'Case');
            queuesToInsert.add(q3);
            
            QueuesObject q4 = new QueueSObject(QueueID = g4.id, SobjectType = 'Case');
            queuesToInsert.add(q4);
            
            insert queuesToInsert;
            
            //Insert Group Member for Lead Queue
            list<GroupMember> groupMembers = new list<GroupMember>();
            LeadMember1 = new GroupMember();
            LeadMember1.UserOrGroupId = userToRun2.Id;
            LeadMember1.GroupId = g1.Id;
            groupMembers.add(LeadMember1);
            
            //Insert Group Member for Case Queue
            caseMember1 = new GroupMember();
            caseMember1.UserOrGroupId = userToRun2.Id;
            caseMember1.GroupId = g3.Id;
            groupMembers.add(caseMember1);
            
            insert groupMembers;
            
        }
        
        //Fetch Group details
        list<Group> leadGroups = [SELECT Id, Name, DeveloperName, Type FROM Group Where Type = 'Queue' AND Name LIKE'Test Lead Group Q%'];
        list<Group> caseGroups = [SELECT Id, Name, DeveloperName, Type FROM Group Where Type = 'Queue' AND Name LIKE'Test Case Group Q%'];
        
        //Create Zip Code records
        for(Integer i = 1; i<3; i++){
            ZipCode__c zipCode = new ZipCode__c();
            if(i == 1){
                zipCode.Name = '392140';
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
        
        //Create Zip Code Rule records for Lead
        for(Integer i=0; i <2; i++){
            Zip_Code_Rule__c z = new Zip_Code_Rule__c();
            if(i==0){
                z.name = 'K-B2B-392140';
            } else {
                z.name = 'H-B2C-392140';
            }
            
            z.Queue_1__c = leadGroups[0].DeveloperName;
            z.Queue_2__c = leadGroups[1].DeveloperName;
            z.Effective_Till__c = Date.today().addDays(100);
            z.Run_Round_Robin_on_Queue1__c = true;
            z.Run_Round_Robin_on_Queue2__c = true;
            z.Queues_And_LastAssignedId__c = '{"'+leadGroups[0].DeveloperName+'":\"'+ LeadMember1 +'\","'+ leadGroups[0].DeveloperName+'":"'+LeadMember1+'","Lead_queue_MHE":""}';
            z.Object_Name__c = 'Lead';
            if(z.name.containsIgnoreCase('H-B2C')) {
            	z.Channel__c = 'HEX';
            }
            
            ZipCodeRulesToCreate.add(z);
        }
        
        //Create Zip Code Rule records for Case
        for(Integer i=0; i <2; i++){
            Zip_Code_Rule__c z = new Zip_Code_Rule__c();
            if(i==0){
                z.name = 'W-Scripts-392140';
            } else {
                z.name = 'K-B2B-392140';
            }
            
            z.Queue_1__c = caseGroups[0].DeveloperName;
            z.Queue_2__c = caseGroups[1].DeveloperName;
            z.Effective_Till__c = Date.today().addDays(100);
            z.Run_Round_Robin_on_Queue1__c = true;
            z.Run_Round_Robin_on_Queue2__c = true;
            z.Queues_And_LastAssignedId__c = '{"'+caseGroups[0].DeveloperName+'":\"'+ caseMember1 +'\","'+ caseGroups[0].DeveloperName+'":"'+caseMember1+'","Case_queue_MHE":""}';
            z.Object_Name__c = 'Case';
            
            ZipCodeRulesToCreate.add(z);
        }
        
        //Insert Zip Code Rule records
        insert ZipCodeRulesToCreate;
        
        system.runAs(applianceUser){
            List<Lead> leadsToInsert=new List<Lead>(); 
            Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'H', Branch_Code__c = 'P');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            AccountTriggerHandler.TriggerDisabled = true;
            insert accountRecord;
            
            //Create Lead record
            Lead Ld = new Lead();
            Ld.LastName='Rao';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378400';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'H';
            Ld.Status='New';
            Ld.Zip_Code_Rule__c = ZipCodeRulesToCreate[0].Id;
            Ld.Company__c = 'ABCj';
            Ld.sub_division__C = 'B2C';
            Ld.Email='testLeadAssignment1@godrej.com';
            leadsToInsert.add(Ld); 
            
            //Create another lead 
            Lead Ld1 = Ld.clone(false);
            ld1.Email='testLeadAssignment2@godrej.com';
            Ld1.MobilePhone= '9561371400';
            leadsToInsert.add(Ld1);
            
            insert leadsToInsert;
        }
        
        system.runAs(r){
            Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'W', Branch_Code__c = 'P');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            AccountTriggerHandler.TriggerDisabled = true;
            insert accountRecord;
            
            Lead Ld = new Lead();
            Ld.LastName='Rao';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378400';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'K';
            Ld.Status='New';
            ld.Zip_Code_Rule__c = ZipCodeRulesToCreate[0].Id;
            ld.Company__c = 'ABCDXY';
            ld.sub_division__C = 'B2B';
            ld.Email='testLeadAssignment@godrej.com';
            insert Ld; 
        }
        
        /*
         * Create Case related records
         */
        //Create Address Record
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'NUVOCO LIMITED';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.ZipCode__c = ZipCodesToCreate[0].Id;
        address.Building__c = 'Avenues';
        address.Street2__c = '1st Street';
        address.Street__c = '2nd street';
        insert address;
        
       //Create Account
        Account acc = new Account();
        acc.Name = 'NUVOCO LIMITED';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        acc.PAN__c = 'ASDFG0987Z';
        acc.Type = 'D';//Dealer Type
        acc.Business_Unit__c = 'K'; //MHE division
        acc.Primary_Address__c = address.Id;
        acc.Business_Partner_Status__c = 'Open';
        acc.Sub_Division__c = 'B2B';
        
        insert acc;
        
    }

    @isTest
    private static void test_LeadAssignmentProcessor(){
        test.startTest(); 
        List<Lead> lList = [SELECT lastName,Age__C,MobilePhone,Source_of_Awareness__c,
                                LeadSource,Business_Unit__c,Interio_Sub_Division__c,
                                Zip_Code_Rule__c,Zip_Code_Rule__r.Id,Zip_Code_Rule__r.name,
                                Zip_Code_Rule__r.Queue_1__c,Zip_Code_Rule__r.Queue_2__c,
                                Zip_Code_Rule__r.Queue_3__c,Zip_Code_Rule__r.Queue_4__c,
                                Zip_Code_Rule__r.Queue_5__c,Zip_Code_Rule__r.Queue_6__c,Zip_Code_Rule__r.Queue_7__c,
                                Zip_Code_Rule__r.Queues_And_LastAssignedId__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue2__c,
                                Zip_Code_Rule__r.Run_Round_Robin_on_Queue3__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue4__c,
                                Zip_Code_Rule__r.Run_Round_Robin_on_Queue5__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue6__c,
                                Zip_Code_Rule__r.Run_Round_Robin_on_Queue7__c,Zip_Code_Rule__r.Sequence__c
                            FROM lead 
                            WHERE lastName = 'Rao' ];

        List<Account> acc = [Select Id From Account limit 1];
        ZipCodeBasedAssignmentProcessor c = new ZipCodeBasedAssignmentProcessor();
        c.processAssignment(lList);
        
        User r = [select id from user where userName =  'territory.salesmanager@godrej.com' limit 1];
        system.runas(r){
            try{
                LeadConversionController.convertLead(lList.get(0).Id, acc[0].Id);
            }
            catch(Exception e){
            }
        }
        test.stopTest(); 
    }
    
    
    @isTest
    private static void test_CaseAssignmentProcessorForInsert(){
        User contextuser = [SELECT Id FROM User WHERE Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME AND IsActive = true LIMIT 1];
        system.runAs(contextuser){
            //Fetching the assignment rules on case
            AssignmentRule AR = new AssignmentRule();
            AR = [SELECT Id from AssignmentRule WHERE SobjectType = 'Case' AND Name ='Case Assignment' AND Active = true limit 1];
            
            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
                       
            //Fetch Account detail
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'NUVOCO LIMITED' LIMIT 1];

            //Fetch address details
            list<Address__c> addresses = [SELECT Id FROM Address__c WHERE Name__c = 'NUVOCO LIMITED' LIMIT 1];

            //Create Asset records
            Asset assetRec = new Asset();
            assetRec.Name = 'Asset 11';
            assetRec.AccountId = accounts[0].Id;
            assetRec.Address_Code__c = addresses[0].Id;
            assetRec.Product_Family__c = 'Equipment';
            assetRec.Product_Category__c = 'Warehousing';
            assetRec.Product_Sub_Category__c = 'Stacker';
            assetRec.Equipment_Category__c = 'WE';
            insert assetRec;

            //Create Case record
            Case caseRec = new Case();
            caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
            caseRec.AccountId = accounts[0].Id;
            caseRec.AssetId = assetRec.Id;
            caseRec.Applicable_For_Pincode_Based_Assignment__c = true;
            caseRec.Email__c = 'asdf@godrej.com';
            caseRec.Mobile__c = '9087654321';
            caseRec.Subject = 'Test Subject';
            caseRec.Description = 'Test Description';
            //Setting the DMLOption on Case instance
            caseRec.setOptions(dmlOpts);
            test.startTest(); 
            insert caseRec;
            test.stopTest();
        }
    }
    
    @isTest
    private static void test_CaseAssignmentProcessorForUpdate(){
        User contextuser = [SELECT Id FROM User WHERE Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME AND IsActive = true LIMIT 1];
        system.runAs(contextuser){
            //Fetching the assignment rules on case
            AssignmentRule AR = new AssignmentRule();
            AR = [SELECT Id from AssignmentRule WHERE SobjectType = 'Case' AND Name ='Case Assignment' AND Active = true limit 1];
            
            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
                        
            //Fetch Account detail
            list<Account> accounts = [SELECT Id FROM Account WHERE Name = 'NUVOCO LIMITED' LIMIT 1];

            //Fetch address details
            list<Address__c> addresses = [SELECT Id FROM Address__c WHERE Name__c = 'NUVOCO LIMITED' LIMIT 1];

            //Create Asset records
            Asset assetRec = new Asset();
            assetRec.Name = 'Asset 12';
            assetRec.AccountId = accounts[0].Id;
            assetRec.Address_Code__c = addresses[0].Id;
            assetRec.Product_Family__c = 'Equipment';
            assetRec.Product_Category__c = 'Warehousing';
            assetRec.Product_Sub_Category__c = 'Stacker';
            assetRec.Equipment_Category__c = 'WE';
            insert assetRec;
            
            //Create Case record
            Case caseRec = new Case();
            caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
            caseRec.AccountId = accounts[0].Id;
            caseRec.Applicable_For_Pincode_Based_Assignment__c = true;
            caseRec.AssetId = assetRec.Id;
            caseRec.Email__c = 'asdf@godrej.com';
            caseRec.Mobile__c = '9087654321';
            caseRec.Subject = 'Test Subject';
            caseRec.Description = 'Test Description';
            //Setting the DMLOption on Case instance
            caseRec.setOptions(dmlOpts);
            Test.startTest();
            insert caseRec;
            
            //Update Pincode to check assignment rule 
            Case caseRecToUpdate = new Case(Id = caseRec.Id);
            //caseRecToUpdate.Zip_Code__c = '392140';
            update caseRecToUpdate;
            test.stopTest(); 
        }
    }
    
}