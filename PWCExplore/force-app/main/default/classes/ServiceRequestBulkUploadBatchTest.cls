@isTest
public class ServiceRequestBulkUploadBatchTest {
    @isTest static void testData(){
    
    }
    static testMethod void testmethods(){
        List<Case> newCaseCreation = new List<Case>();
        List<Case> insertCaseRecord = new List<Case>();
        List<Account> insertAccount = new List<Account>();
        List<ContactPointEmail> insertContactPointEmail = new List<ContactPointEmail>();
        Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Appliance Service Request').getRecordTypeId();
        newCaseCreation.add(new Case(
            Mobile__c='9988004567',
          	Primary_Contact_Email__c='test@gmail.com',
            Case_Owner_Name__c='test1',
            Bulk_Upload__c=true,
            Address1__c='test1',
            Address2__c='test1',
            Address3__c='test1',
            Address4__c='test1',
            State__c='Andhra Pradesh',
            City__c='kkd',
            Country__c='india',
            Pincode__c='533240',
            Recordtypeid=devRecordTypeId
        ));
        newCaseCreation.add(new Case(
            Mobile__c='9988004565',
          	Primary_Contact_Email__c='test@gmail12.com',
            Case_Owner_Name__c='test1',
            Bulk_Upload__c=true,
            Address1__c='test1',
            Address2__c='test1',
            Address3__c='test1',
            Address4__c='test1',
            State__c='Andhra Pradesh',
            City__c='kkd',
            Country__c='india',
            Pincode__c='533240',
            Recordtypeid=devRecordTypeId
        ));
        newCaseCreation.add(new Case(
            Mobile__c='9988004566',
          	Primary_Contact_Email__c='test@gmail1.com',
            Case_Owner_Name__c='test1',
            Bulk_Upload__c=true,
            Address1__c='test1',
            Address2__c='test1',
            Address3__c='test1',
            Address4__c='test1',
            State__c='Andhra Pradesh',
            City__c='kkd',
            Country__c='india',
            Pincode__c='533240',
            Recordtypeid=devRecordTypeId
        ));
        insert newCaseCreation;
        insertAccount.add(new Account(
            LastName=newCaseCreation[0].Case_Owner_Name__c,
            PersonMobilePhone='1234567890',
            PersonEmail=newCaseCreation[0].Primary_Contact_Email__c,
            BillingStreet = newCaseCreation[0].Address1__c+'-'+newCaseCreation[0].Address2__c+'-'+newCaseCreation[0].Address3__c+'-'+newCaseCreation[0].Address4__c,
            BillingState=newCaseCreation[0].State__c,
            BillingCountry=newCaseCreation[0].Country__c,
            BillingCity=newCaseCreation[0].City__c,
            BillingPostalCode=newCaseCreation[0].Pincode__c
        ));
        insert insertAccount;
        insertContactPointEmail.add(new ContactPointEmail(
            EmailAddress=insertAccount[0].PersonEmail,
            ParentId=insertAccount[0].Id
        ));
        insert insertContactPointEmail;
        Test.startTest();
        ServiceRequestBulkUploadBatch batch = new ServiceRequestBulkUploadBatch();
		Database.executeBatch(batch,5);
        Test.stopTest();
    }
        
    
}