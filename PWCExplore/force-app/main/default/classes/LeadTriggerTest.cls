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
public class LeadTriggerTest {
    @testSetup
    private static void createTestRecords(){
Account acc = new Account(Name='TestAccountConstruction', 
                                      Account_Series__c='3WA',
                                      Account_code__c='3W13777',
                                      Industry='Apparel',
                                      PAN__c='CAJAJ1234T',
                                      Business_unit__c='N',
                                      Sub_Division__c='B2B',
                                      Type='I',
                                      CIN__c='124',                                      
                                      RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account')
                                     );
            
            insert acc;
        
        list<ZipCode__c> ZipCodesToCreate = new list<ZipCode__c>();
        for(Integer i = 1; i<=3; i++){
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
            } else if(i==2){
                zipCode.Name = '110008';
                zipCode.CityCode__c = 'Delhi';
                zipCode.City_Name__c = 'DELHI';
                zipCode.StateCode__c = 'DL';
                zipCode.StateName__c = 'Delhi';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_110008';
            }
            else if(i==3){
                zipCode.Name = '411001';
                zipCode.CityCode__c = 'MUMBAI';
                zipCode.City_Name__c = 'MUMBAI';
                zipCode.StateCode__c = 'MH';
                zipCode.StateName__c = 'Maharashtra';
                zipCode.CountryCode__c = 'IN';   
                zipCode.CountryName__c = 'INDIA';   
                zipCode.ZipCodeExternalId__c = 'IN_411001';      
            }
            
            ZipCodesToCreate.add(zipCode);
        }
        
        insert ZipCodesToCreate;
        
        List<Zip_Code_Rule__c> rulesToInsert=new List<Zip_Code_Rule__c>(); 
        Zip_Code_Rule__c z = new Zip_Code_Rule__c();
        z.name = 'K-B2B-392140';
        z.Queue_1__c = 'Cross_BU_Lead_queue_Appliances';
        z.Queue_2__c = 'Cross_BU_Lead_queue_Interio_B2B';
        Date myDate = Date.today();
        myDate = myDate.addDays(100);
        z.Effective_Till__c = myDate;
        z.Object_Name__c = 'Lead';
        z.Run_Round_Robin_on_Queue1__c = true;
        z.Run_Round_Robin_on_Queue2__c = true;
        z.Queues_And_LastAssignedId__c = '{"Cross_BU_Lead_queue_MHE":"0052h000000prLaAAI","KAM_Queue_MHE_Division":"0052h000000prLaAAI","Lead_queue_MHE":""}';
        z.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',UserInfo.getUserId());
        rulesToInsert.add(z);
        
        Zip_Code_Rule__c rule = new Zip_Code_Rule__c();
        rule.name = 'H-B2C-392140-ALL';
        rule.channel__c='AMC';
        rule.Queue_1__c = 'Cross_BU_Lead_queue_Appliances';
        rule.Queue_2__c = 'Cross_BU_Lead_queue_Interio_B2B';
        rule.Object_Name__c = 'Lead';
        myDate = Date.today();
        myDate = myDate.addDays(100);
        rule.Effective_Till__c = myDate;
        rule.Run_Round_Robin_on_Queue1__c = true;
        rule.Run_Round_Robin_on_Queue2__c = true;
        rule.Queues_And_LastAssignedId__c = '{"Cross_BU_Lead_queue_MHE":"0052h000000prLaAAI","KAM_Queue_MHE_Division":"0052h000000prLaAAI","Lead_queue_MHE":""}';
        rule.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',UserInfo.getUserId());
        rulesToInsert.add(rule);
        
        Zip_Code_Rule__c rule1 = new Zip_Code_Rule__c();
        rule1.name = 'H-B2C-411001-AMC';
        rule1.channel__c='AMC';
        rule1.Queue_1__c = 'Cross_BU_Lead_queue_Appliances';
        rule1.Queue_2__c = 'Cross_BU_Lead_queue_Interio_B2B';
        rule1.Object_Name__c = 'Lead';
        myDate = Date.today();
        myDate = myDate.addDays(100);
        rule1.Effective_Till__c = myDate;
        rule1.Run_Round_Robin_on_Queue1__c = true;
        rule1.Run_Round_Robin_on_Queue2__c = true;
        rule1.Queues_And_LastAssignedId__c = '{"Cross_BU_Lead_queue_MHE":"0052h000000prLaAAI","KAM_Queue_MHE_Division":"0052h000000prLaAAI","Lead_queue_MHE":""}';
        rule1.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',UserInfo.getUserId());
        rulesToInsert.add(rule1);

        Group queue = new Group(Name='testgroup', type='Queue');
        insert queue;
        
        Zip_Code_Rule__c ruleW = new Zip_Code_Rule__c();
        ruleW.name = 'W-VFD-110008';
        ruleW.Object_Name__c = 'Lead';
        ruleW.Account__c = acc.Id;
        ruleW.Run_Round_Robin_on_Queue1__c = true;
        ruleW.Queue_1__c = 'testgroup';
        myDate = Date.today();
        myDate = myDate.addDays(100);
        ruleW.Effective_Till__c = myDate;
        rulesToInsert.add(ruleW);
        
        Zip_Code_Rule__c ruleW1 = new Zip_Code_Rule__c();
        ruleW1.name = 'W-VFD-411001';
        ruleW1.Object_Name__c = 'Lead';
        ruleW1.Account__c = acc.Id;
        ruleW1.Effective_Till__c = myDate;
        
        rulesToInsert.add(ruleW1);
        
        
        
        insert rulesToInsert;
        
        Profile p = [select id from profile where name = 'Interio B2C VFD COCO Team User' limit 1];
        User r = new User();
        r.business_unit__C = 'W';
        r.email = 'r.kal@godrej.com';
        r.lastName = 'test';
        r.firstName = 'test';
        r.profileId = p.Id;
        r.username = 'territory.salesmanager@godrej.com';
        r.Alias = 'jmx';
        r.EmailEncodingKey = 'ISO-8859-1';
        r.LanguageLocaleKey = 'en_US';
        r.TimeZoneSidKey= 'GMT';
        r.LocaleSidKey = 'en_US';
        r.Persona__c = 'CST';
r.Account__c = acc.Id;
        insert r;

        GroupMember member = new GroupMember();
		member.UserOrGroupId = r.Id;
		member.GroupId = queue.Id;
        
    }
    @isTest static void testInsertLead(){
        User contextuser = [Select Id FROM User where username = 'territory.salesmanager@godrej.com' LIMIT 1];
        test.startTest();
        system.runAs(contextuser){
            Lead Ld = new Lead();
            Ld.LastName='Rao';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378400';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Facebook/ Instagram';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'W';
            Ld.Status='New';
            ld.Company__c = 'ABCj';
            ld.Applicable_For_Pincode_Based_Assignment__c = false;
            // ld.Channel__c='AMC'; 
            //ld.segment__C = 'NA';
            ld.sub_division__C = 'B2C';
            //ld.Business_Unit__c 
            insert Ld; 
        }
        Test.stopTest();
        List<Lead> insertedLead=[Select Id From Lead limit 1];
        System.assert(insertedLead.size() > 0);
    }
   //Following method is written for  calculateQualifiedDate method in LeadFieldPopulator class by Sreekanth Jujare on 12/12/2022
    @isTest static void testCalculateQualifiedDate(){
        User contextuser = [Select Id FROM User where username = 'territory.salesmanager@godrej.com' LIMIT 1];
        test.startTest();
        system.runAs(contextuser){
            Lead Ld = new Lead();
            Ld.LastName='Jsb';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378401';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'W';
            Ld.Status='New';
            Ld.Company__c = 'My Company';
            Ld.Channel__c='DLR';				//Added by pc 
            Ld.sub_division__C = 'B2C';
            insert Ld; 
            Ld.Status = 'Qualified';
            update Ld;
          Test.stopTest();
        List<Lead> insertedLead=[Select Id,Status,Qualified_unqualified_Date__c From Lead WHERE Status ='Qualified' OR Status = 'Unqualified' limit 1];
        //System.assertEquals(system.Now(),insertedLead[0].Qualified_unqualified_Date__c); //Commented by Shreela on 27th Feb 2023 as there was slight difference in seconds causing assertion error.
        System.assertEquals(Date.Today(),insertedLead[0].Qualified_unqualified_Date__c.Date()); //Added by Shreela on 27th Feb 2023
        }
    }
    @isTest static void testLeadConversion(){
        Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
        User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
            .setBusinessUnit('H').getSavedTestRecord();
        System.runAs(appliancesUser) {
            Lead b2cLead = new TestLeadBuilder()
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Appliances_B2C_Lead').getRecordTypeId())
                .setBusinessUnit('H').setChannel('AMC').getSavedTestRecord();
            b2cLead.Appointment_Date__c = Date.today().addDays(1);
            b2cLead.Time_Slot__c = '6PM - 8PM';
            update b2cLead;
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(b2cLead.Id);
           LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            try
            {
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.assert(lcr.isSuccess());//gcp22
            }catch(exception ex){
                System.debug(ex);
            }
            
        }
    }
    
    @isTest static void leadShouldBeSetWithAllRule(){
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='392140'];
        Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
        User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
            .setBusinessUnit('H').getSavedTestRecord();
        System.runAs(appliancesUser) {
            Test.startTest();
            Lead Ld = new Lead();
            Ld.LastName='Rao';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378401';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'H';
            Ld.Status='New';
            ld.Company__c = 'ABCj';
            ld.Applicable_For_Pincode_Based_Assignment__c = true;
            ld.sub_division__C = 'B2C';
            ld.Channel__c='AMC';
            ld.ZipCode__c=zipcode.Id;
            insert Ld;
            Test.stopTest();
        }
        List<Lead> l=[Select Id,Zip_Code_Rule__r.Name From Lead where Zip_Code_Rule__r.Name='H-B2C-392140-ALL'];
        System.assertEquals(1,l.size());
    }
    
    @isTest static void leadShouldBeSetWithAMCRule(){
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='411001'];
        Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
        User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
            .setBusinessUnit('H').getSavedTestRecord();
        System.runAs(appliancesUser) {
            Test.startTest();
            Lead Ld = new Lead();
            Ld.LastName='Rao';
            Ld.Age__c='21-30';
            Ld.MobilePhone= '9561378411';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'H';
            Ld.Status='New';
            ld.Company__c = 'ABCj';
            ld.Applicable_For_Pincode_Based_Assignment__c = true;
            ld.sub_division__C = 'B2C';
            ld.Channel__c='AMC';
            ld.ZipCode__c=zipcode.Id;
            insert Ld;
            Test.stopTest();
        }
        List<Lead> l=[Select Id,Zip_Code_Rule__r.Name From Lead where Zip_Code_Rule__r.Name='H-B2C-411001-AMC'];
        System.assertEquals(1,l.size());
    }
    @isTest static void findDuplicateLead(){
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='411001'];
        Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
        User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
            .setBusinessUnit('H').getSavedTestRecord();
        List<String> PhoneList = new List<String>();
        List<String> zipCodeList = new List<String>();
        System.runAs(appliancesUser) {
            Test.startTest();
            Lead Ld = new Lead();
            Ld.LastName='pankaj';
            Ld.Age__c='21-30';
            Ld.Phone= '9561378411';
            Ld.MobilePhone= '9561378412';
            Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            Ld.Source_of_Awareness__c='Exhibitions';
            Ld.LeadSource='Email';
            Ld.Business_Unit__c= 'H';
            Ld.Status='New';
            ld.Company__c = 'ABCj';
            ld.Applicable_For_Pincode_Based_Assignment__c = true;
            ld.sub_division__C = 'B2C';
            ld.Channel__c='AMC';
            ld.ZipCode__c=zipcode.Id;
            PhoneList.add(Ld.Phone);
            zipCodeList.add(ld.ZipCode__c);
            insert Ld;
            Lead ld1 = new Lead();
            ld1.LastName='pankaj';
            ld1.Age__c='21-30';
            ld1.Phone= '9561378412';
            ld1.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            ld1.Source_of_Awareness__c='Exhibitions';
            ld1.LeadSource='Email';
            ld1.Business_Unit__c= 'H';
            ld1.Status='New';
            {}
            ld1.Company__c = 'ABCj';
            ld1.Applicable_For_Pincode_Based_Assignment__c = true;
            ld1.sub_division__C = 'B2C';
            ld1.Channel__c='AMC';
            ld1.ZipCode__c=zipcode.Id;
            PhoneList.add(ld1.Phone);
            zipCodeList.add(ld1.ZipCode__c);
            insert ld1;
            Test.stopTest();
        }
        List<Lead> l=[Select Id,Zip_Code_Rule__r.Name From Lead where Phone in:PhoneList and ZipCode__c in:zipCodeList];
        System.assertEquals(2,l.size());
        
        
        
    }
    
    //Added sendCouponCodeEmailToGeneratedLeadsTest() for SIEPB 70  by Shreela on 23rd Feb 2023
    @isTest static void sendCouponCodeEmailToGeneratedLeadsTest(){
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='411001'];
        ZipCode__c zipcode1=[Select Id from ZipCode__c Where Name='110008'];//Added by Srini on 24th April 2023
        Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD Customer Experience Head User'];
        User interioUser = new TestUserBuilder().setProfileId(interioProfile.Id)
            .setBusinessUnit('W').getSavedTestRecord();
        Map<Id,Lead> mapLead = new Map<Id,Lead>();
        
        Group grp=[Select Id from Group where Type='Queue' and DeveloperName='Default_Queue' limit : 1];//Added by Srini on 24th April 2023       
        GroupMember grpMember=new GroupMember(); //Added by Srini on 24th April 2023
        grpMember.GroupId=grp.Id; //Added by Srini on 24th April 2023
        grpMember.UserOrGroupId=interioUser.Id;//Added by Srini on 24th April 2023
        insert grpMember; //Added by Srini on 24th April 2023
        
        System.runAs(interioUser) {
            Test.startTest();
            
            Coupon_Code__c cc = new Coupon_Code__c(CouponCodeValue__c='INT123',Start_Date__c=System.today()-1,End_Date__c=System.today()+1,IsCheckCouponCodeSent__c=false);
            
            insert cc;
            
            //Existing lead data
            Lead ldExisting = new Lead();
            ldExisting.LastName='Test SIEPB 70 Existing ';
            ldExisting.Age__c='21-30';
            ldExisting.Phone= '9561378410';
            ldExisting.MobilePhone= '9561378480';
            ldExisting.Email = 'shreela234@godrej.com';
            ldExisting.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            ldExisting.Source_of_Awareness__c='Exhibitions';
            ldExisting.LeadSource='Facebook/ Instagram';
            ldExisting.Business_Unit__c= 'W';
            ldExisting.Status='New';
            ldExisting.Company__c = 'XYZ';
            ldExisting.sub_division__C = 'B2C';
            ldExisting.Interio_sub_division__C = 'VFD';
            ldExisting.ZipCode__c=zipcode1.Id;
            ldExisting.IsEmailSentOnceWithCouponCode__c = true;
ldExisting.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Lead').getRecordTypeId();
            ldExisting.Applicable_For_Pincode_Based_Assignment__c = true;
            insert ldExisting;
            
            Lead ld = new Lead();
            ld.LastName='Test SIEPB 70 ';
            ld.Age__c='21-30';
            ld.Phone= '9561378409';
            ld.MobilePhone= '9561378478';
            ld.Email = 'shreela123@godrej.com';
            ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
            ld.Source_of_Awareness__c='Exhibitions';
            ld.LeadSource='Facebook/ Instagram';
            ld.Business_Unit__c= 'W';
            ld.Status='New';
            ld.Company__c = 'ABC';
            ld.sub_division__C = 'B2C';
            ld.ZipCode__c=zipcode.Id; //Added by Srini on 24th April 2023
            ld.IsEmailSentOnceWithCouponCode__c = false;
ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Lead').getRecordTypeId();
            ld.Applicable_For_Pincode_Based_Assignment__c = true;
            ld.Interio_sub_division__C = 'VFD';
            insert ld;

            
            ld.Status = 'Unqualified';//Added by Srini on 24th April 2023
            ld.Reason_for_Lost__c = 'Cannot contact';
            ld.Lost_Reasons_at_Call_Center__c = 'INVALID INQUIRY';
            ld.OwnerId=interioUser.Id;
ldExisting.Interio_sub_division__C = 'VFD';
            update ld; //Added by Srini on 24th April 2023
            mapLead.put(ld.Id,ld);
            
            LeadFieldPopulator lf = new LeadFieldPopulator();
            lf.sendCouponCodeEmailToGeneratedLeads(mapLead);
            Test.stopTest();
            }
    } 
    
        //Added populateNameForPESTest() by Shreela on 20th April 2023
    @isTest static void populateNameForPESTest(){
        List<Lead> leadList = new List<Lead>();
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='411001'];
        Profile pesProfile = [SELECT Id FROM Profile WHERE Name = 'PES Sales And Marketing User'];
        User pesUser = new TestUserBuilder().setProfileId(pesProfile.Id)
            .setBusinessUnit('W').getSavedTestRecord();
        Map<Id,Lead> mapLead = new Map<Id,Lead>();
        System.runAs(pesUser) {
            Test.startTest();
            //Lead Data with Name as NA
            Lead ld1 = new Lead();
            ld1.LastName='NA ';
            ld1.Title='Shreela Test';
            ld1.Business_Unit__c= 'Q';
            ld1.Status='New';
            ld1.Company__c = 'XYZ';
            ld1.ZipCode__c=zipcode.Id;
            insert ld1;
            
            //Lead Data with Name field having value
            Lead ld2 = new Lead();
            ld2.LastName='Shreela  ';
            ld2.Title='Shreela Test';
            ld2.Business_Unit__c= 'Q';
            ld2.Status='New';
            ld2.Company__c = 'XYZ';
            ld2.ZipCode__c=zipcode.Id;
            insert ld2;
            
            leadList.add(ld1);
            leadList.add(ld2);
            
            LeadFieldPopulator lf = new LeadFieldPopulator();
            lf.populateNameForPES(leadList);

            
            Test.stopTest();
            }
        
    }
    
    //Added by rohit on 2nd Feb 2024
    @isTest static void interioB2CUpdateSyncWithSFMCFieldOnOwnerChangeTest(){
        ZipCode__c zipcode=[Select Id from ZipCode__c Where Name='411001'];
        ZipCode__c zipcode1=[Select Id from ZipCode__c Where Name='110008'];
        Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD Customer Experience Head User'];
        User interioUser = new TestUserBuilder().setProfileId(interioProfile.Id)
            .setBusinessUnit('W').getSavedTestRecord();
        Map<Id,Lead> mapLead = new Map<Id,Lead>();
        
        Group grp=[Select Id from Group where Type='Queue' and DeveloperName='Default_Queue' limit : 1];       
        GroupMember grpMember=new GroupMember();
        grpMember.GroupId=grp.Id;
        grpMember.UserOrGroupId=interioUser.Id;
        insert grpMember;
        
        System.runAs(interioUser) {
            Test.startTest();
            
            //Existing lead data
            Lead leadRecord = new Lead();
            leadRecord.OwnerId=grp.Id;
            leadRecord.Status=GlobalConstants.NEW_CONSTANT;
            leadRecord.LastName='Test Lead ';
            leadRecord.Phone= '9561378410';
            leadRecord.MobilePhone= '9561378480';
            leadRecord.Email = 'test@godrej.com';
            leadRecord.Source_of_Awareness__c='Exhibitions';
            leadRecord.LeadSource='Facebook/ Instagram';
            leadRecord.Business_Unit__c= GlobalConstants.INTERIO_BUSINESS_UNIT;
            leadRecord.Company__c = 'XYZ';
            leadRecord.sub_division__C = GlobalConstants.B2C_SUBDIVISION;
            leadRecord.Interio_sub_division__C = GlobalConstants.INTERIO_VFD;
            leadRecord.ZipCode__c=zipcode1.Id;
			leadRecord.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Lead').getRecordTypeId();
            
            insert leadRecord;
            
            leadRecord.OwnerId=interioUser.Id;
            update leadRecord;
            
            Test.stopTest();
            }
    } 
}