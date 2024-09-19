/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for DeactivateDiscountMatrixBatchSchedular 
                            and DeactivateDiscountMatrixBatch
Inputs:        NA
Test Class:     
History
13-08-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
@isTest
private class DeactivateDiscountMatrixSchedulerTest {
    
    @TestSetup static void createData(){
        //Insert Custom setting record
        Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'DeactivateDiscountMatrixBatchSchedular', 
                                                                            Batch_Size__c = 10);
        insert abc;
        
        Runtime_Execution__c runtimeExecution = new Runtime_Execution__c(FireDiscountMatrixValidationRules__c = false);
        insert runtimeExecution;
        
        //get standart price book
       Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,PriceList_Code__c='123',LN_PriceList_Code__c='456');
       Update standardPricebook;
       
       //insert product
       Product2 product = new Product2(Name = 'test product', Family = 'Mobile',Item__c='mob123',Is_Generic_Product__c=true);
       Insert product;
        
        //Create Running User
       // User runningUser = createUserRecord(); //added by mrunali at 18 JAN 2024 HOT FIX
       Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
       User runningUser = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.userDDMST@godrej.com', username = 'test.userDDMST@godrej.com');
        
        //Set Running user
        System.runAs(runningUser) {
            //Create Discount Matrix record
            Discount_Matrix__c matrix = createDiscountMatrixRecord();
            insert matrix;
        }
    }
    
    //Method to test Batch & Scheduler
    @isTest
    static void testSchedularAndBatch() {
        User runAsUser = [Select Id From User WHERE username = 'test.userDDMST@godrej.com' Limit 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(runAsUser){
            Test.StartTest();
            DeactivateDiscountMatrixBatchSchedular schedular = new DeactivateDiscountMatrixBatchSchedular();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Deactivate Discount Matrix Batch', sch, schedular); 
            Test.stopTest();
        }
   }
    
    
    //Method to create Discount Matrix records
    private static Discount_Matrix__c createDiscountMatrixRecord(){
        
        Discount_Matrix__c matrix = new Discount_Matrix__c();
        matrix.Name = 'Test Appliance Matrix';
        matrix.Discount_Code__c = 'HA9';
        matrix.Discount_Percent__c = 8;
        matrix.Level__c = '2';
        matrix.Start_Date__c = (System.today()).addDays(-10);
        matrix.End_Date__c = (System.today()).addDays(-5);
        matrix.Stage__c = 'Active';
        matrix.Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        matrix.Matrix_Source__c = 'Salesforce';
        matrix.Type__c = 'Discount';
        matrix.Gross_Net__c = '1';
        matrix.code__c = 'W56';
        matrix.Area__c ='EA2';
        matrix.price_list__c = Test.getStandardPricebookId();
        matrix.order_Currency__C = 'INR';
        
        return matrix;         
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
        userRec.username = 'test.user19@godrej.com';
        userRec.Business_Unit__c = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        userRec.IsActive = true;
        
        insert userRec;
        
        return userRec;
    }
}