/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        test method for generating bills
* History
* --------
* 28-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestBillingServicesBatch {
    static testmethod void testBillingServicesSchedule() {
        test.startTest();
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        
        System.runAs(u) {
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
            hot.Leasing_Term__c = 138;
            update hot;
            
            ScheduleBillingJob sbj = new ScheduleBillingJob();
            String sch = '0 0 23 * * ?';
            system.schedule('Test status Check', sch, sbj );
            // system.assertEquals( 87, hot.Leasing_Term__c);//gcp22 EDITED by dhiren 04/04/2023
        }
        
        test.stopTest();
    }
    
    static testmethod void testBillingServicesBatch() {
        test.startTest();
        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('ELB ITPrk C LicenseFee Main').setDescription('ELB ITPrk C LicenseFee Main').setItemCode('80131801SD00041').getTestRecord(),
                new TestProductBuilder().setName('ELB ITPrk C CAM Chrgs KPMG').setItemCode('80131801SD00102').setDescription('ELB ITPrk C CAM Chrgs KPMG').getTestRecord(),
                new TestProductBuilder().setName('ELB ITPrk C Common Fac Fees').setItemCode('80131801SD00042').setDescription('ELB ITPrk C Common Fac Fees').getTestRecord(),
                new TestProductBuilder().setName('ELB ITPrk C AC Chrgs Main').setItemCode('80131801SD00048').setDescription('ELB ITPrk C AC Chrgs Main').getTestRecord()
                };
                    
                    Id accoundId = LeaseTestDataFactory.createAccount();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        System.runAs(u){
            List<Address_by_BP__c> abList = [Select Id, Address_Code__c from Address_by_BP__c where Account__c = :accoundId];
            
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
            hot.Leasing_Term__c = 120;
            update hot;
            
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.StageName = 'Converted';
            opp.Billing_Address__c = abList[0].Id;
            update opp;
            
            List<Head_Of_Terms__c> hotList = [Select Id, Name, Licence_End_Date__c, Licence_Commencement_Date__c, Leasing_Term__c, Bill_Leasing_Term__c 
                                              from Head_Of_Terms__c 
                                              where Id = :hotId];
            
            Charges_Type__c cLicence = new Charges_Type__c();
            cLicence.Name = 'License Fee Monthly';
            cLicence.Billing_Cycle__c= 'Every Month';
            cLicence.Category__c = 'revenue generating';
            cLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
            cLicence.Tax_applicable__c =true;
            cLicence.Tax_Percentage__C = 10;
            cLicence.Type_Of_Billing__c = 'Monthly fixed';
            cLicence.Charge_CCode__c = allProducts[0].Id;
            insert cLicence;
            
            List<Billing_Schedule__c> bschList = new List<Billing_Schedule__c>();
            Billing_Schedule__c bSch = new Billing_Schedule__c();
            bSch.Charges_Type__c = cLicence.Id;
            bSch.Head_Of_Terms__c = hotList[0].Id;
            bSch.start_date__c = hotList[0].Licence_Commencement_Date__c;
            bsch.End_date__c = hotList[0].Licence_Commencement_Date__c.addMonths(60);
            bsch.Rate__c = 100;
            bsch.Amount__c = 500000;
            bsch.Number_of_Months__c = 60;
            bschList.add(bsch);
            
            Charges_Type__c qLicence = new Charges_Type__c();
            qLicence.Name = 'License Fee Quarterly';
            qLicence.Billing_Cycle__c= 'Every Month';
            qLicence.Category__c = 'revenue generating';
            qLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
            qLicence.Tax_applicable__c =true;
            qLicence.Tax_Percentage__C = 10;
            qLicence.Type_Of_Billing__c = 'Quarterly Fixed';
            qLicence.Charge_CCode__c = allProducts[0].Id;
            insert qLicence;
            
            Charges_Type__c mhLicence = new Charges_Type__c();
            mhLicence.Name = 'Housing Billing';
            mhLicence.Billing_Cycle__c= '10th every month';
            //mhLicence.Category__c = 'revenue generating';
            mhLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_HOUSING;
            mhLicence.Tax_applicable__c =false;
            //mhLicence.Tax_Percentage__C = 10;
            mhLicence.Type_Of_Billing__c = 'Monthly Fixed';
            mhLicence.Charge_CCode__c = allProducts[0].Id;
            insert mhLicence;
            
            Billing_Schedule__c bSch1 = new Billing_Schedule__c();
            bSch1.Charges_Type__c = qLicence.Id;
            bSch1.Head_Of_Terms__c = hotList[0].Id;
            bSch1.start_date__c = hotList[0].Licence_Commencement_Date__c;
            bsch1.End_date__c = hotList[0].Licence_Commencement_Date__c.addMonths(60);
            bsch1.Rate__c = 100;
            bsch1.Amount__c = 500000;
            bsch1.Number_of_Months__c = 60;
            bschList.add(bsch1);
            
            Billing_Schedule__c bSch2 = new Billing_Schedule__c();
            bSch2.Charges_Type__c = mhLicence.Id;
            bSch2.Head_Of_Terms__c = hotList[0].Id;
            //bSch2.start_date__c = hotList[0].Licence_Commencement_Date__c;
            //bSch2.End_date__c = hotList[0].Licence_Commencement_Date__c.addMonths(60);
            //bSch2.Rate__c = 100;
            //bSch2.Amount__c = 500000;
            bSch2.Number_of_Months__c = 0;
            bschList.add(bSch2);
            insert bschList;
            
            system.debug('Leasing Term : ' + hotList[0].Leasing_Term__c);
            system.debug('Bill_Leasing_Term__c Term : ' + hotList[0].Bill_Leasing_Term__c);
            
            hot.Lease_Abstract__c = true;
            update hot;
            
            Set<Id> optySet = new Set<Id>();
            optySet.add(oppId);
            
            BillingServicesBatch bpt = new BillingServicesBatch();
            database.executebatch(bpt);
            
            BillingServices bs = new BillingServices();
            bs.generateBills(hotList);
            bs.generateMonthlyLicenseFeeBill(optySet);
            bs.generateQuarterlyLicenseFeeBill(optySet);
            bs.generateYearlyLicenseFeeBill(optySet);
            bs.generateMonthlyCarParkBill(optySet);
            bs.generateMonthlyVariableBill(optySet);
            bs.generateMonthlyHousingBill(optySet);
            //system.Assert.isInstanceOfType(bs, BillingServices.class);//gcp22 edited by dhiren 04/04/2023
        }
        
        test.stopTest();
    }
    
    static testmethod void testBillingServicesRentFree() {
       
        Id accoundId = LeaseTestDataFactory.createAccount();
        Account AccountRec = [select id,Business_Unit__c from Account where id =:accoundId ];
        AccountRec.Business_Unit__c = 'N';
        Update AccountRec;
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();        
        User u = [Select Id from User where Id =: leasingUserId];
        System.runAs(u){ 
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OpportunityTriggerDisabled__c =true ;
            insert setting;
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
            test.startTest(); 
            List<Head_Of_Terms__c> hotList = [Select Id, Name, Licence_End_Date__c from Head_Of_Terms__c where Id = :hotId];
            BillingServices bs = new BillingServices();
            bs.generateBills(hotList);
            bs.generateMonthlyLicenseFeeBill(optySet);
            bs.generateQuarterlyLicenseFeeBill(optySet);
            bs.generateYearlyLicenseFeeBill(optySet);
            bs.generateMonthlyCarParkBill(optySet);
            bs.generateMonthlyVariableBill(optySet);
            test.stopTest();
        }
        
       
    }
}