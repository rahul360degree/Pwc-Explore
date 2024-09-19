@isTest
public class AssignLeadSchedularTest {
    
    @testSetup
    static void createData(){
       Id defaultQueueId=[select Id From Group Where Type = 'Queue' AND DeveloperName = :GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE].Id;
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
        z.Queues_And_LastAssignedId__c  = z.Queues_And_LastAssignedId__c.replace('0052h000000prLaAAI',UserInfo.getUserId());
        insert z;

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
        r.Persona__c='Sales Person'; // Added by Rohit Jadhav as Persona is Mandatory for Interio_B2B
        insert r;
        
        system.runAs(r){
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
            //ld.segment__C = 'NA';
            ld.sub_division__C = 'B2B';
            ld.Company__c = 'ABCj';
            //ld.Business_Unit__c 
            ld.OwnerId=defaultQueueId;
            insert Ld; 
        }
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'AssignLeadsSchedular', 
                                                                            Batch_Size__c = 10);
        insert abc;
    }
    
    @isTest
    static void testSchedularAndBatch() {
        Test.StartTest();
        AssignLeadsSchedular schedular = new AssignLeadsSchedular();
        String sch = '0 0 23 * * ?'; 
        system.schedule('lead assignment batch', sch, schedular); 
        Test.stopTest();
   }
}