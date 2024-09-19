@isTest
private class ZipCodeRuleTriggerHandlerTest {

    
    @isTest
    private static void test_LeadAssignmentProcessor(){
    
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
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
        
       
        Id leadB2BRecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Interio_MHE_SSG_B2B').getRecordTypeId();
        Lead Ld = new Lead();
        ld.RecordTypeId=leadB2BRecordTypeId;
        Ld.LastName='Rao';
        Ld.Age__c='21-30';
        Ld.MobilePhone= '9561378400';
        Ld.How_did_the_customer_find_the_store_loca__c= 'Just Dial';
        Ld.Source_of_Awareness__c='Exhibitions';
        Ld.LeadSource='Email';
        Ld.Business_Unit__c= 'W';
        Ld.Status='New';
        //Ld.Interio_Sub_Division__c='B2B';
        ld.Company__c = 'ABCD';
        ld.Zip_Code_Rule__c = z.id;
        //ld.segment__C = 'NA';
        ld.sub_division__C = 'B2B';
        //ld.Business_Unit__c 
        insert Ld; 
        
        z.Run_Round_Robin_on_Queue1__c = false;
        z.Queue_2__c = 'Cross_BU_Lead_queue_Appliances';
        z.Queue_1__c = 'Cross_BU_Lead_queue_Interio_B2B';
        update z;
        
        try {
            z.name = 'BadData';
            update z;
        }
        catch(Exception e){
        }
        
        }       
    }    
    
}