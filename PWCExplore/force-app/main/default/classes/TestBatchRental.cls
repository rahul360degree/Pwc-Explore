/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        test method for rental Updates
* History
* --------
* 28-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestBatchRental {
    static testmethod void testBatchRental() {
        test.startTest();
        Id accoundId = LeaseTestDataFactory.createAccount();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        System.runAs(u){  
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId);
            List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accoundId];

            Id hotId = LeaseTestDataFactory.createHOT(oppId);
            hotId = LeaseTestDataFactory.tagPremise(hotId, oppId);
            
            Head_Of_Terms__c hot = new Head_Of_Terms__c();
            hot.Id = hotId;
            hot.LOI_L_L_Execution_Date__c = system.today();
            hot.L_L_Signing_Date__c = system.today();
            hot.Licence_commencement_date__c = system.today();
            hot.License_fees_Commencement_date__c = system.today();
            hot.Licence_End_Date__c = system.today();
            hot.Mark_as_final__c = true;
            hot.Number_of_chargeable_carparks__c = 40;
            hot.Per_carpark_charge__c = 2000;
            hot.Leasing_Term__c = 87;
            update hot;

            ScheduleRentalJob bpt = new ScheduleRentalJob();
            String sch = '0 0 23 * * ?';
            system.schedule('Test status Check', sch, bpt );
        }
        
        test.stopTest();
    }
}