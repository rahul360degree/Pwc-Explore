@isTest
public with sharing class ChecklistDocControllerTest {
    @testsetup
    private static void createData() {
        Account acc = new Account(Name = 'ABCDE1234', 
                                      Account_code__c = 'W13456',
                                      Industry = 'Apparel',
                                      PAN__c = 'ABCDE1234S');
        acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert acc;
         
        Case caseRecord = new Case();
        caseRecord.AccountId = acc.Id;
        caseRecord.Origin = 'Email';
        caseRecord.Priority = 'Medium';
        insert caseRecord;

        Service_Form__c serviceForm = new Service_Form__c();
        serviceForm.Case__c = caseRecord.Id;
        serviceForm.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Service_Form__c', 'Job_Card');
        insert serviceForm;
        
        Service_Form__c serviceForm2 = new Service_Form__c();
        serviceForm2.Case__c = caseRecord.Id;
        serviceForm2.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Service_Form__c', 'Commissioning_Checklist');
        insert serviceForm2;
        
        MHE_Time_Entry__c timeE = new MHE_Time_Entry__c();
        timeE.Service_Form__c = serviceForm.ID;
        timeE.Technician_Name__c = 'Tanya Tyagi';
        timeE.Service_Report_and_Customer_Signature__c = System.now();
        insert timeE;

    }

    @IsTest
    static void generatePDFTest(){
        Test.startTest();
        List<Service_Form__c> serviceForms = [Select Id FROM Service_Form__c LIMIT 1];
        ChecklistDocController.disableSave(serviceForms[0].Id);
        ChecklistDocController.generatePDF(serviceForms[0].Id, false);
        Test.stopTest();
    }

    @isTest
    static void checkListControllerTest(){
        Test.startTest();
        List<Service_Form__c> serviceForms = [Select Id FROM Service_Form__c LIMIT 1];
        PageReference pageRef = Page.ChecklistDoc;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(serviceForms[0].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(serviceForms[0]);
        ChecklistDocController cntrl = new ChecklistDocController(sc);
        Test.stopTest();
    }
    
    @isTest
    static void serviceFormSubmitTest(){
        Boolean flag = false;
        Test.startTest();
        List<Service_Form__c> serviceForms = [Select Id FROM Service_Form__c LIMIT 1];
        serviceForms[0].Status__c = GlobalConstants.SERVICE_FORM_STATUS_SUBMITTED;
        try{
        update serviceForms;
        }
        catch(Exception ex){
            flag=true;
        }
        Test.stopTest();
        System.assertEquals(true, flag, 'flag should be true for the lack of customer signature');
    }

}