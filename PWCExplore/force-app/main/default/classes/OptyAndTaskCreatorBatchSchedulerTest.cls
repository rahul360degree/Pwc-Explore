/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for OpportunityAndTaskCreatorBatchScheduler 
                            and OpportunityAndTaskCreatorBatchForCP
Inputs:        NA
Test Class:     
History
13-08-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
@isTest
private class OptyAndTaskCreatorBatchSchedulerTest {
    
    @TestSetup static void createData(){
        //Inserting reserved chars from custom setting
        Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
        rChar.B2C_character__c = 'A';
        rChar.B2B_Account_Series_Char__c = 'X';
        rChar.B2B_character__c = 'AA';
        
        insert rChar;
        
        //Create Zip Code Data
        ZipCode__c zipCode = createZipCodeRecord();
        insert zipCode;
        
        //Create Address records
        Address__c address = createAddressRecord(zipCode);
        insert address;
        
        //Insert Custom setting record
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'OpportunityAndTaskCreatorBatch', 
                                                                            Batch_Size__c = 10);
        insert abc;
        
        //Create Running User
         // User runningUser = createUserRecord(); //added by Mrunali Chaudhari at 18 JAN 2024 HOT FIX
         // Created profile and User record by Mrunali Chaudhari at 18 JAN 2024 HOT FIX
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        
        User runningUser = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userOATCBST@godrej.com', username = 'test.userOATCBST@godrej.com');
            
        //Set Running user
        System.runAs(runningUser) {
            //Create Account
            Account accountRec = createAccountRecord(address.Id);
            insert accountRec;
            
            //create Competitor Products
            list<Competitor_Product__c> competitorProducts = createCompetitorProductsRecord(accountRec.Id);
            insert competitorProducts;
        }
    }
    
    //Method to test Batch & Scheduler
    @isTest
    static void testSchedularAndBatch() {
        User runAsUser = [Select Id From User WHERE username = 'test.userOATCBST@godrej.com' Limit 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(runAsUser){
            Test.StartTest();
            OpportunityAndTaskCreatorBatchScheduler schedular = new OpportunityAndTaskCreatorBatchScheduler();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Opty and Task Creator batch', sch, schedular); 
            Test.stopTest();
        }
   }
    
    //Method to Create Zipcode record
    private static ZipCode__c createZipCodeRecord() {
        ZipCode__c zipCode = new ZipCode__c();
        zipCode.Name = '410002';
        zipCode.CityCode__c = 'PUNE';
        zipCode.City_Name__c = 'PUNE';
        zipCode.StateCode__c = 'MH';
        zipCode.StateName__c = 'Maharashtra';
        zipCode.CountryCode__c = 'IN';   
        zipCode.CountryName__c = 'INDIA';   
        zipCode.ZipCodeExternalId__c = 'IN_410002';
        
        return zipCode;
    }
    
    //Method to Create Address record
    private static Address__c createAddressRecord(ZipCode__c zipCode) {
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        //address.Name__c = 'Nuvoco Plant Pune';
        address.Name__c = 'MHE1-Competitor Product Account';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.ZipCode__c = zipCode.Id;
        
        return address;
    }    
    
    //Method to Create Account record
    private static Account createAccountRecord(Id addressId) {
        
        Account acc = new Account();
        //acc.Name = 'MHE1-Competitor Product Account -' +system.now();
        acc.Name = 'MHE1-Competitor Product Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
        acc.PAN__c = 'ASDFG0916Z';
        acc.Type = 'D';//Dealer Type
        acc.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
        acc.Primary_Address__c = addressId;
        acc.Business_Partner_Status__c = 'Open';
        acc.One_Time_Business_Partner__c = 'No';
            
        return acc;
    }
    
    //Method to Create Competitor Products record
    private static list<Competitor_Product__c> createCompetitorProductsRecord(Id accountId) {
        list<Competitor_Product__c> competitorProducts = new list<Competitor_Product__c>();
        
        for(Integer i=0; i<2; i++){
            Competitor_Product__c cp = new Competitor_Product__c();
            cp.Name = 'MHE'+i+'-Competitor Product -' +system.now();
            cp.Quantity__c = 1;
            cp.Customer_Name__c = accountId;
            if(i == 0){ //For Opportunity
                cp.Manufacturing_Date__c = system.today().addYears(-5);
                cp.Product_Category__c = 'Class 4&5';
            }else { //For Task
                cp.Manufacturing_Date__c = system.today().addYears(-2);
                cp.Product_Category__c = 'Class 1';
            }
            competitorProducts.add(cp);
        }
          
        return competitorProducts;
    }
    
    //Method to insert & return User record
    private static user createUserRecord(){
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.user7@godrej.com');
        
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.username = 'test.user18@godrej.com';
        userRec.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
        userRec.IsActive = true;
        
        insert userRec;
        
        return userRec;
    }
}