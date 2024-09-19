/*
Written by  : Sreekanth Jujare
On		    : 27/06/2022
Description : Creates or Updates a Task record
*/

@isTest
public class setScheduledEndDateInTaskTest {
    @isTest 
    public static void endDateTriggerTest() {
        
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
        
        // Test data setup
        Task tsk = new Task();
        tsk.whoId = Ld.Id;
        tsk.Sub_Activity__c = 'Lead Generation';
        tsk.Subject = 'Hello World';
        tsk.Status = 'On hold';
        tsk.Priority = 'Normal';
        tsk.View_Status__c='Completed';
        tsk.Start_Date__c=DateTime.newInstance(2022, 6, 24, 12, 00, 00);
        tsk.CSG_Activity__c='Tender - Pre Qualification Doc';
        tsk.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        
        //Perform Test
        Test.startTest();
        insert tsk;
        Test.stopTest();

    }
}