/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Test class for SendEmailNotificationToCustomers
Inputs:        -
Date :         19-01-2024
----------------------------------------------------------------------------*/
@isTest
public class SendEmailNotificationToCustomerTest {
    @TestSetUp
    static void prepareData(){
         Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'MHE Godrej Branch Champion User', 
                                  Alias = 'tMheuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.mhegbcuser@godrej.com', 
                                  username = 'test.mhegbcuser@godrej.com', Business_Unit__c = GlobalConstants.MHE_BUSINESS_UNIT);
        
        insert userToRun;
        
        System.runAs(userToRun){
            
            Address__c addressRecord = new Address__c(Name__c  = 'Testing for MHE', Address_Type__c  = 'B2B');
            insert addressRecord;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit('K')
                .setName('Testing for MHE Account')
                .setPanNumber('ABDFR1234R')
                .setPrimaryAddress(addressRecord.Id)
                .getSavedTestRecord();
            
            Asset newAsset = new Asset();
            newAsset.Name= 'Asset Record 1';
            newAsset.AccountId = accountRecord.id;
            newAsset.Status = 'Active';
            newAsset.Equipment_Serial_No__c = '38303';
            newAsset.Address_Code__c = addressRecord.id;		
            newAsset.Type_of_Warranty__c = 'Not Applicable';
            newAsset.MHE_Division__c = 'Outright Sales';
            insert newAsset;
            
            Case cs = new Case();
            cs.Status = 'Resolved';
            cs.Origin = 'Manual';
            cs.Email__c = 'test123@godrej.com';
            cs.Alternate_Contact_s_Name__c ='Test Contact Record';
            cs.Mobile__c = '9999999999';
            cs.Subject = 'test case subject';
            cs.Description = 'test Case Description';
            cs.Type = 'BM';
            cs.Branch__c = '5010';
            cs.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'MHE_Service_Request');
            cs.AccountId = accountRecord.Id;
            insert cs;
            
            ContentVersion contentVersion = new ContentVersion( Title = 'Job Card 1', PathOnClient = 'JobCard.pdf',
                                                               VersionData = Blob.valueOf('Test Content'),
                                                               IsMajorVersion = true); 
            insert contentVersion;
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title = 'Job Card 1'];
            
            ContentDocumentLink cdl2 = New ContentDocumentLink();
            cdl2.LinkedEntityId = cs.Id;
            cdl2.ContentDocumentId = documents[0].Id;
            cdl2.shareType = 'V';
            insert cdl2; 
            
        }
     }
    @isTest 
    static void testsendEmailNotification(){
        User userToRun = [Select Id,FirstName,LastName,Name,Username FROM User Where username = 'test.mhegbcuser@godrej.com' AND Profile.Name = 'System Administrator' LIMIT 1];
        
        List<Case> cs =[Select Id,Status,Email__c,Account.Name,OwnerId,Owner.FirstName,Owner.LastName,ContactEmail,SuppliedEmail FROM Case WHERE Email__c = 'test123@godrej.com'];  
        System.runAs(userToRun) {
            cs[0].OwnerId = userToRun.Id; //Owner change from Queue to Created User
            update cs;
            List<Id> cId = new List<Id>();
            for(Case cse : cs){
                cId.add(cse.Id); 
            }
            SendEmailNotificationToCustomer.sendEmailNotifcationToCustomer(cId);
            
        }
    }

}