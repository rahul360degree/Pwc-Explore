/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        test method for generating bills
* History
* --------
* 10-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestBillingServices {
    static testmethod void testBillingServicesNormal() {
        test.startTest();
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        System.runAs(u){  
            List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accoundId];
            
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId);
            List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accoundId];

            String buildId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            Project_Unit__c b = new Project_Unit__c();
            b.Id = buildId;
            b.Name = '02GBDTEST';
            update b;
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
            hot.Leasing_Term__c = 138;
            system.debug(' hot.Leasing_Term__c:'+ hot.Leasing_Term__c);
         //   system.debug(' hot.Bill_Leasing_Term:'+ hot.Bill_Leasing_Term);
            system.debug(' hot.Billing_Mismatch__c:'+ hot.Billing_Mismatch__c);
            
            update hot;
            
            oppList[0].Id = oppId;
            oppList[0].StageName = 'Converted';
            oppList[0].Billing_Address__c = abList[0].Id;
            update oppList;
            
            LeaseTestDataFactory.createBillingSchedule(hot);
            hot.Lease_Abstract__c = true;
            update hot;
            Set<Id> optySet = new Set<Id>();
            optySet.add(oppId);
            system.assertEquals(optySet.size(), 1);

            BillingServices bs = new BillingServices();
            
            bs.generateMonthlyLicenseFeeBill(optySet);
            bs.generateQuarterlyLicenseFeeBill(optySet);
            bs.generateYearlyLicenseFeeBill(optySet);
            bs.generateMonthlyCarParkBill(optySet);
            bs.generateMonthlyVariableBill(optySet);
            bs.generateMonthlyHousingBill(optySet);
        }
        
        test.stopTest();
    }
    
    static testmethod void testBillingServicesRentFree() {
        test.startTest();
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        System.runAs(u){  
            List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accoundId];
            
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId);
            List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accoundId];

            String buildId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            Project_Unit__c b = new Project_Unit__c();
            b.Id = buildId;
            b.Name = '02GBDTEST';
            update b;
            Id hotId = LeaseTestDataFactory.createHOT(oppId);
            hotId = LeaseTestDataFactory.tagPremise(hotId, oppId);
            Head_Of_Terms__c hot = new Head_Of_Terms__c();
            hot.Id = hotId;
            hot.LOI_L_L_Execution_Date__c = system.today();
            hot.L_L_Signing_Date__c = system.today();
            hot.Licence_commencement_date__c = system.today();
            hot.License_fees_Commencement_date__c = Date.newInstance(2021, 12, 15);
            hot.Licence_End_Date__c = Date.newInstance(2028, 12, 31);
            hot.Mark_as_final__c = true;
            hot.Number_of_chargeable_carparks__c = 40;
            hot.Per_carpark_charge__c = 2000;
            hot.Leasing_Term__c = 138;
            update hot;
            
            oppList[0].Id = oppId;
            oppList[0].StageName = 'Converted';
            oppList[0].Billing_Address__c = abList[0].Id;
            update oppList;
            
            LeaseTestDataFactory.createBillingSchedule(hot);
            hot.Lease_Abstract__c = true;
            update hot;
            Set<Id> optySet = new Set<Id>();
            optySet.add(oppId);
            system.assertEquals(optySet.size(), 1);

            BillingServices bs = new BillingServices();
            
            bs.generateMonthlyLicenseFeeBill(optySet);
            bs.generateQuarterlyLicenseFeeBill(optySet);
            bs.generateYearlyLicenseFeeBill(optySet);
            bs.generateMonthlyCarParkBill(optySet);
            bs.generateMonthlyVariableBill(optySet);
            bs.generateMonthlyHousingBill(optySet);
        }
        
        test.stopTest();
    }
}