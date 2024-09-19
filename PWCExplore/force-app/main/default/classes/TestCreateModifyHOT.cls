/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test methods for controller that create and modify the HOT
 * History
 * --------
 * 02-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestCreateModifyHOT {
    static testmethod void testCreateModifyHOT() {
       
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        String accId = LeaseTestDataFactory.createAccount();

        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            String conId = LeaseTestDataFactory.createContact(accId);
            String oppId = LeaseTestDataFactory.createOpportunity(accId);
            String hotId = LeaseTestDataFactory.createHOT(oppId);
            String hotId1 = LeaseTestDataFactory.createHOT(oppId);
            LeaseTestDataFactory.createStandardTermClauses();
            LeaseTestDataFactory.tagPremise(hotId,oppId);
            List<Junction_Unit__c> juList = [Select Id from Junction_Unit__c where Opportunity__c = :oppId and Head_Of_Terms__c =:hotId];
            system.assertEquals(2, juList.size());
            PageReference pageRef = Page.createHOT;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('HoTID',hotId); 
            CreateHoT cht=new CreateHot(); 
            cht.HOT.Notice_Period_For_Termination_Licensor__c = 60;
            cht.HOT.Notice_Period_For_Termination_Licensee__c = 60;
            cht.HOT.Leasing_Term__C = 87;
            cht.HOT.Carpark_Ratio__c = 1000;
            cht.HOT.Rent_escalation_structure__c = '';
            cht.HOT.Lock_in_period_in_months__c = 60;
            cht.HOT.Rent_per_sq_ft_monthly__c = 120;
            cht.HOT.Security_Deposit_Calculation_Type__c ='Simple';
            cht.HOT.Security_Deposit_Number_of_months__c = 9;
            cht.HOT.Security_Deposit__c = 20000;
            cht.HOT.Renewal_Terms__c = 48;
            cht.HOT.Terms_of_payment_CAM_fee__c = '7th of every month';
            cht.HOT.Terms_of_payment_license_fee__c = '1st of every month';
            cht.HOT.Compensation_free_period__c = 3;
            cht.HOT.Chareable_Carpark__c = 50;
            cht.HOT.Per_carpark_charge__c = 4000;
            cht.HOT.Validity_in_Days__c = 15;
            cht.generate();
            cht.updateData();
            cht.createHOT();
            List<Head_Of_Terms__c> htList = [select Id, Licence_commencement_date__c,Leasing_Term__C,Bill_Leasing_Term__c from Head_Of_Terms__c where Opportunity__r.Id = :OppId];
            system.assertEquals(htList.size(), 4);
            PageReference pageRef1 = Page.ModifyHOT;
            Test.setCurrentPage(pageRef1);
            ApexPages.currentPage().getParameters().put('HoTID',htList[1].Id); 
            ModifyHOT mht = new ModifyHOT();
            mht.updateData();
            mht.modifyHOT();
            htList[1].LOI_L_L_Execution_Date__c = system.today().addDays(1);
            update htList[1];
            List<Premise_Tracking__c> ptList = [Select id from Premise_Tracking__c where Event__c = :Label.LOI_Event];
            system.assertEquals(ptList.size(), 0);
            htList[1].L_L_Signing_Date__c = system.today().addDays(10);
            update htList[1];
            List<Premise_Tracking__c> ptList1 = [Select id from Premise_Tracking__c where Event__c = :Label.Set_Occupied];
            system.assertEquals(ptList.size(), 0);
            htList[1].Licence_commencement_date__c = system.today();
            
            LeaseTestDataFactory.createBillingSchedule(htList[1]);
            List<Billing_Schedule__c> bschList = [Select Id from Billing_Schedule__c where Head_Of_Terms__r.Id =: htList[1].Id];
            
            htList = [select Id, Licence_commencement_date__c,Leasing_Term__C,Bill_Leasing_Term__c,Lease_Abstract__c from Head_Of_Terms__c where Opportunity__r.Id = :OppId];
            List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accId];
            List<Opportunity> oppList = [Select Id from Opportunity where AccountId = :accId];
            oppList[0].Billing_Address__c = abList[0].Id;
            update oppList;

            htList[1].Lease_Abstract__c = true;
            htList[1].Mark_as_final__c = true;
            htList[1].Licence_commencement_date__c = system.today();
            htList[1].License_fees_Commencement_date__c = system.today();
            htList[1].Licence_End_Date__c = system.today().addMonths(Integer.ValueOf(htList[1].Leasing_Term__C));
            htList[1].Leasing_Term__C = htList[1].Bill_Leasing_Term__c;
            system.assertEquals(htList[1].Leasing_Term__C,htList[1].Bill_Leasing_Term__c);
            update htList;
            system.assertEquals(htList[1].Lease_Abstract__c, true);
            htList[1].Mark_as_final__c = false;
            update htList;
            system.assertEquals(htList[1].Mark_as_final__c, false);
        }
        test.stopTest();

    }

    static testmethod void testCreateModifyHOT1() {
       
        test.StartTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        String accId = LeaseTestDataFactory.createAccount();

        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            String conId = LeaseTestDataFactory.createContact(accId);
            String oppId = LeaseTestDataFactory.createOpportunity(accId);
            String hotId = LeaseTestDataFactory.createHOT(oppId);
            String hotId1 = LeaseTestDataFactory.createHOT(oppId);
            LeaseTestDataFactory.createStandardTermClauses();
            LeaseTestDataFactory.tagMultiPremise(hotId,oppId);
            List<Junction_Unit__c> juList = [Select Id from Junction_Unit__c where Opportunity__c = :oppId and Head_Of_Terms__c =:hotId];
            system.assertEquals(3, juList.size());
            PageReference pageRef = Page.createHOT;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('HoTID',hotId); 
            CreateHoT cht=new CreateHot(); 
            cht.HOT.Notice_Period_For_Termination_Licensor__c = 60;
            cht.HOT.Notice_Period_For_Termination_Licensee__c = 60;
            cht.HOT.Leasing_Term__C = 84;
            cht.HOT.Carpark_Ratio__c = 1000;
            cht.HOT.Rent_escalation_structure__c = '';
            cht.HOT.Lock_in_period_in_months__c = 60;
            cht.HOT.Rent_per_sq_ft_monthly__c = 120;
            cht.HOT.Security_Deposit_Calculation_Type__c ='Simple';
            cht.HOT.Security_Deposit_Number_of_months__c = 9;
            cht.HOT.Security_Deposit__c = 20000;
            cht.HOT.Renewal_Terms__c = 48;
            cht.HOT.Terms_of_payment_CAM_fee__c = '7th of every month';
            cht.HOT.Terms_of_payment_license_fee__c = '1st of every month';
            cht.HOT.Compensation_free_period__c = 3;
            cht.HOT.Chareable_Carpark__c = 50;
            cht.HOT.Per_carpark_charge__c = 4000;
            cht.HOT.Validity_in_Days__c = 15;
            cht.generate();
            cht.updateData();
            cht.createHOT();
            List<Head_Of_Terms__c> htList = [select Id, Licence_commencement_date__c,Leasing_Term__C,Bill_Leasing_Term__c from Head_Of_Terms__c where Opportunity__r.Id = :OppId];
            system.assertEquals(htList.size(), 4);
            PageReference pageRef1 = Page.ModifyHOT;
            Test.setCurrentPage(pageRef1);
            ApexPages.currentPage().getParameters().put('HoTID',htList[0].Id); 
            ModifyHOT mht = new ModifyHOT();
            mht.updateData();
            mht.modifyHOT();
            ApexPages.currentPage().getParameters().put('HoTID',htList[1].Id); 
            ModifyHOT mht1 = new ModifyHOT();
            mht1.updateData();
            mht1.modifyHOT();
            ApexPages.currentPage().getParameters().put('HoTID',htList[2].Id); 
            ModifyHOT mht2 = new ModifyHOT();
            mht2.updateData();
            mht2.modifyHOT();
            
        }
        test.stopTest();

    }
}