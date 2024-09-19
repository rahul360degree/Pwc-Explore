@isTest
private class SignatureHelperTest {
    @isTest private static void saveSignTest(){
        Test.startTest();
        Account acc = new Account(Name = 'ABCDE1234', 
                                  Account_code__c = 'W13456',
                                  Industry = 'Apparel',
                                  PAN__c = 'ABCDE1234S');
        acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert acc;
        //Create Case record
        Case caseRecord = new Case();
        caseRecord.Origin = 'Manual';
        caseRecord.Status = 'New';
        caseRecord.Priority = 'Medium';
        caseRecord.Case_Category__c = 'Customer Complaint';
        caseRecord.Email__c = 'abc@invalid.com';
        caseRecord.Mobile__c = '9890908989';
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        caseRecord.Asset_Location__c = 'Pune';
        caseRecord.AccountId = acc.Id;
        insert caseRecord;
        
        String imageData = 'test image data';
        Service_Form__c newServiceForm = new Service_Form__c();
        newServiceForm.Case__c = caseRecord.Id;
        newServiceForm.RecordTypeId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get('Job_Card').getRecordTypeId();
        insert newServiceForm;

        SignatureHelper.saveSign(imageData,newServiceForm.Id);
        Test.stopTest();
    }
}