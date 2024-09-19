@isTest
private class LeadAssignmentProcessorTest {

    @testSetup
    private static void createTestRecords(){
        
        Runtime_Execution__c runTimeExecution = new Runtime_Execution__c(Name = 'leadAssignmentTest', 
                                                                            FireLeadValidationRules__c = true);
        insert runTimeExecution;
        
        Profile applianceProfile = [select id from profile where name = 'Appliances Marketing and Service Revenue User' limit 1];
        
        User user1 = new User();
        user1.business_unit__C = 'K';
        user1.email = 'ruchita.kalkar1@godrej.com';
        user1.lastName = 'test';
        user1.firstName = 'test';
        user1.profileId = applianceProfile.Id;
        user1.username = 'territory.salemanager1@godrej.com';
        user1.Alias = 'jmx';
        user1.EmailEncodingKey = 'ISO-8859-1';
        user1.LanguageLocaleKey = 'en_US';
        user1.TimeZoneSidKey= 'GMT';
        user1.LocaleSidKey = 'en_US';
        insert user1;
        
       
        Profile mheProfile = [select id from profile where name = 'MHE Sales User' limit 1];
        User MHEuser = new User();
        MHEuser.business_unit__C = 'K';
        MHEuser.email = 'nnegi@godrej.com';
        MHEuser.lastName = 'MHEtest';
        MHEuser.firstName = 'MHEtest';
        MHEuser.profileId = mheProfile.Id;
        MHEuser.username = 'MHEtest123@godrej.com';
        MHEuser.Alias = 'MHEt';
        MHEuser.EmailEncodingKey = 'ISO-8859-1';
        MHEuser.LanguageLocaleKey = 'en_US';
        MHEuser.TimeZoneSidKey= 'GMT';
        MHEuser.LocaleSidKey = 'en_US';
        insert MHEuser;
       

        
        list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
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

        Zip_Code_Rule__c z = new Zip_Code_Rule__c();
        z.name = 'K-B2B-392140';
        z.Queue_1__c = 'Cross_BU_Lead_queue_Appliances';
        z.Queue_2__c = 'Cross_BU_Lead_queue_Interio_B2B';
        Date myDate = Date.today();
        myDate = myDate.addDays(100);
        z.Effective_Till__c = myDate;
        z.Run_Round_Robin_on_Queue1__c = true;
        z.Run_Round_Robin_on_Queue2__c = true;
        z.Queues_And_LastAssignedId__c = '{"Cross_BU_Lead_queue_MHE":"0052h000000prLaAAI","KAM_Queue_MHE_Division":"0052h000000prLaAAI","Lead_queue_MHE":""}';
        z.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',user1.Id);
        z.Object_Name__c = 'Lead';
        insert z;
        
        user1.Business_Unit__c='H';
        Update user1;
        
        Zip_Code_Rule__c z1 = new Zip_Code_Rule__c();
        z1.name = 'H-B2C-392140';
        z1.Queue_1__c = 'Cross_BU_Lead_queue_Appliances';
        z1.Queue_2__c = 'Cross_BU_Lead_queue_Interio_B2B';
        Date myDate1 = Date.today();
        myDate1 = myDate.addDays(100);
        z1.Effective_Till__c = myDate1;
        z1.Run_Round_Robin_on_Queue1__c = true;
        z1.Run_Round_Robin_on_Queue2__c = true;
        z1.Queues_And_LastAssignedId__c = '{"Cross_BU_Lead_queue_MHE":"0052h000000prLaAAI","KAM_Queue_MHE_Division":"0052h000000prLaAAI","Lead_queue_MHE":""}';
        z1.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',user1.Id);
        z1.Object_Name__c = 'Lead';
        z1.Channel__c = 'HEX';
        insert z1;
        
        Profile p = [select id from profile where name = 'INTERIO B2B Branch KAM User' limit 1];
        User r = new User();
        r.business_unit__C = 'W';
        r.email = 'ruchita.kalkar@godrej.com';
        r.lastName = 'test';
        r.firstName = 'test';
        r.profileId = p.Id;
        r.username = 'territory.salesmanager@godrej.com';
        r.Alias = 'jmx';
        r.EmailEncodingKey = 'ISO-8859-1';
        r.LanguageLocaleKey = 'en_US';
        r.TimeZoneSidKey= 'GMT';
        r.LocaleSidKey = 'en_US';
        r.Persona__c='Business Head';
        insert r;
        
        User applianceUser = new User();
        applianceUser.business_unit__C = 'H';
        applianceUser.email = 'ruchita.kalkar@godrej.com';
        applianceUser.lastName = 'test';
        applianceUser.firstName = 'test';
        applianceUser.profileId = applianceProfile.Id;
        applianceUser.username = 'territory.salemanager@godrej.com';
        applianceUser.Alias = 'jmx';
        applianceUser.EmailEncodingKey = 'ISO-8859-1';
        applianceUser.LanguageLocaleKey = 'en_US';
        applianceUser.TimeZoneSidKey= 'GMT';
        applianceUser.LocaleSidKey = 'en_US';
        insert applianceUser;

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
            //Ld.Interio_Sub_Division__c='B2B';
            ld.Zip_Code_Rule__c = z.id;
            ld.Company__c = 'ABCj';
            //ld.segment__C = 'NA';
            ld.sub_division__C = 'B2B';
            ld.Email='testLeadAssignment@godrej.com';
            //ld.Business_Unit__c 
            insert Ld; 
        }
        
        system.runAs(applianceUser){
            List<Lead> leadsToInsert=new List<Lead>(); 
            Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'H', Branch_Code__c = 'P');
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
            Ld.Business_Unit__c= 'H';
            Ld.Status='New';
            //Ld.Interio_Sub_Division__c='B2B';
            ld.Zip_Code_Rule__c = z.id;
            ld.Company__c = 'ABCj';
            //ld.segment__C = 'NA';
            ld.sub_division__C = 'B2C';
            ld.Email='testLeadAssignment1@godrej.com';
            //ld.Business_Unit__c 
            leadsToInsert.add(Ld); 
            Lead Ld1 = new Lead();
            ld.Email='testLeadAssignment2@godrej.com';
            Ld1.LastName='Rao';
            Ld1.Age__c='21-30';
            Ld1.MobilePhone= '9561371400';
            Ld1.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld1.Source_of_Awareness__c='Exhibitions';
            Ld1.LeadSource='Email';
            Ld1.Business_Unit__c= 'H';
            Ld1.Status='New';
            //Ld.Interio_Sub_Division__c='B2B';
            ld1.Zip_Code_Rule__c = z.id;
            ld1.Company__c = 'ABCj';
            //ld.segment__C = 'NA';
            ld1.sub_division__C = 'B2C';
            //ld.Business_Unit__c 
            leadsToInsert.add(Ld1);
            insert leadsToInsert;
        }
    }

    @isTest
    private static void test_LeadAssignmentProcessor(){
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
        LeadAssignmentProcessor c = new LeadAssignmentProcessor();
        c.processAssignment(lList);

        User r = [select id from user where userName =  'territory.salesmanager@godrej.com' limit 1];
        system.runas(r){
            try{
                LeadConversionController.convertLead(lList.get(0).Id, acc[0].Id);
            }
            catch(Exception e){
            }
        }
    }
    
    @isTest
    private static void testSkipCreateAccount(){
  		User MHEuser = [select id from user where userName =  'MHEtest123@godrej.com' limit 1];
        system.runas(MHEuser){
            try{
                 Test.startTest();
                 Boolean isFinalized = LeadConversionController.skipCreateNewAccount();
        		 System.assert(isFinalized == false);
        		 Test.stopTest();
            	}
            		catch(Exception e){
                }
        }
     
     } 
}