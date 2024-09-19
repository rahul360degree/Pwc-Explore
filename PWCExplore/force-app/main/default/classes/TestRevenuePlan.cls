/*------------------------------------------------------------------------------------
* Author        :        Stetig Consulting
* Description   :        test method for generating revenue plans
* History
* --------
* 20-12-2021     :    Initial Release
* ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestRevenuePlan {
    static testmethod void testGenerateRevenueProjection() {
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
            String buildId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            Project_Unit__c b = new Project_Unit__c();
            b.Id = buildId;
            b.Name = '02GBDTEST';
            update b;
            Id hotId = LeaseTestDataFactory.createHOT(oppId);
            hotId = LeaseTestDataFactory.tagPremise(hotId, oppId);
            Head_Of_Terms__c hot = new Head_Of_Terms__c();
            hot.Id = hotId;
            hot.LOI_L_L_Execution_Date__c = Date.newInstance(2021, 04, 01);
            hot.L_L_Signing_Date__c = Date.newInstance(2021, 04, 01);
            hot.Licence_commencement_date__c = Date.newInstance(2021, 04, 01);
            hot.License_fees_Commencement_date__c = Date.newInstance(2021, 04, 01);
            hot.Licence_End_Date__c = Date.newInstance(2022, 03, 31);
            hot.Mark_as_final__c = true;
            hot.Number_of_chargeable_carparks__c = 40;
            hot.Per_carpark_charge__c = 2000;
            hot.Leasing_Term__c = 138;//87
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
            
            List<Head_Of_Terms__c> hotList = [Select Id, Name, Licence_End_Date__c from Head_Of_Terms__c where Id = :hotId]; 
            
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
            
            Charges_Type__c carpark = new Charges_Type__c();
            carpark.Name = 'Car Park';
            carpark.Billing_Cycle__c= '1st and 2nd of every month';
            carpark.Category__c = 'revenue generating';
            carpark.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAR_PARK;
            carpark.Tax_applicable__c =true;
            carpark.Tax_Percentage__C = 10;
            carpark.Type_Of_Billing__c = 'Monthly fixed';
            carpark.Charge_CCode__c = allProducts[2].Id;
            insert carpark;
            
            Charges_Type__c cam = new Charges_Type__c();
            cam.Name = 'CAM Charges';
            cam.Billing_Cycle__c= '1st and 2nd of every month';
            cam.Category__c = 'revenue generating';
            cam.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAM1;
            cam.Tax_applicable__c =true;
            cam.Tax_Percentage__C = 10;
            cam.Type_Of_Billing__c = 'Monthly variable';
            cam.Charge_CCode__c = allProducts[2].Id;
            insert cam;
            
            Revenue_Plan__c revPlan = new Revenue_Plan__c();
            revPlan.Status__c = 'Not Generated';
            revPlan.Type__c = 'Optimistic';
            revPlan.Number_of_years__c = 1;
            revPlan.Start_Date__c = Date.newInstance(2021, 04, 01);
            revPlan.End_Date__c = Date.newInstance(2022, 03, 31);
            insert revPlan;
            
            List<Junction_Unit__c> juList = [Select Id, Head_Of_Terms__c, Floor__r.Building__r.Use_Of_Premises__c  
                                             from Junction_Unit__c 
                                             where Opportunity__c = :oppId and Head_Of_Terms__c =:hotId];
            system.assertEquals(2, juList.size());
            
            String planId = revPlan.Id;
            Map < Integer, List < Date >> yearMonthMap = new Map < Integer, List < Date >> ();
            List < Integer > yearList = new List < Integer > ();
            List < String > typeList = new List < String > ();
            List < Floor__c > assetList = new List < Floor__c > ();
            Integer numOfyears = 0;
            Boolean error = false;
            Boolean licenseFeeGenerated = false;
            
            List <Revenue_Plan__c> rpList = [Select Id, Name, Number_Of_years__C, Start_Date__C, End_Date__c, Description__c, Status__c, Type__c, Final__c 
                                             from Revenue_Plan__c 
                                             where id =: revPlan.Id];
            
            if(rpList[0].status__c.equalsIgnoreCase('Not Generated'))
                licenseFeeGenerated = false;  
            else {
                licenseFeeGenerated = true;  
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',Projections have been already generated, please use the view modify button for making changes to the existing projections'));    
            }
            // the number of years the revenue plan is defined for. generally 3, ABP, SBP1, SBP2
            numOfyears = Integer.valueOf(rpList[0].Number_Of_years__c);
            
            // get the financial year start month, Apr -1 st for ex:
            Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
            
            // take that plan start and plan end from the  plan header
            String planStart = rpList[0].Start_Date__c.format();
            String planEnd = rpList[0].End_Date__c.format();
            
            // plan start date 1st April 2022 for ex: plan year + 1st day of the org fiscal month
            Date startOfYearMonth = Date.newinstance(rpList[0].start_date__c.year(), orgFiscalMonth, 1);
            
            // type of plan, pessimistic, optimistic, full throttle etc
            typeList.add(rpList[0].Type__c);
            for (Integer i = 1; i <= numOfyears; i++) {
                List < Date > tempDates = new List < Date > ();
                // for the number of years in the plan, start from 1st april and generate the list of 12 months 
                // till end of the year , 31st March
                tempDates.add(startOfYearMonth);
                //this is the year wise list.
                yearMonthMap.put(startOfYearMonth.year(), tempDates);
                yearList.add(startOfYearMonth.year());
                
                for (integer j = 2; j <= 12; j++) {
                    Date nextMonth = Date.newinstance(
                        startOfYearMonth.year(), 
                        startOfYearMonth.Month() + j - 1, 
                        1
                    );
                    yearMonthMap.get(startOfYearMonth.year()).add(nextMonth);
                }
                startOfYearMonth = startOfYearMonth.addMonths(12);
            }
            
            List < Floor__c > leasedAssetList = new List < Floor__c > ();
            List < Junction_Unit__c > leasingDetailsList = new List < Junction_Unit__c > ();
            Map < Id, List < Junction_Unit__c >> assetLeasingMap = new Map < Id, List < Junction_Unit__c >> ();
            
            String assetVId = LeaseTestDataFactory.createVacantUnits(buildId);
            
            List<Floor__c> assetVacantList = [Select Id, Name, Building__r.Name,Building__r.Use_Of_Premises__c, 
                                              Asset_Code__c, Total_Carpet_Area_Sq_ft__c,
                                              Vacant_Area_Sq_ft__c, Status__c
                                              from Floor__c
                                              where Id=: assetVId];
            
            List<String> assetString = new List<String>();
            assetString.add(assetVacantList[0].Name);
            
            List<Junction_Unit__c> LeasedUnitList = new List<Junction_Unit__c>();
            LeasedUnitList.add(juList[0]);
            
            if (!LeasedUnitList.IsEmpty()) {
                for (Junction_Unit__C j: LeasedUnitList) {
                    if (assetLeasingMap.containsKey(j.Head_Of_Terms__c)) {
                        assetLeasingMap.get(j.Head_Of_Terms__c).add(j);
                    } else {
                        List < Junction_Unit__c > jList = new List < Junction_Unit__c > ();
                        jList.add(j);
                        //oppIdSet.add(j.Opportunity__r.Id);
                        assetLeasingMap.put(j.Head_Of_Terms__c, jList);
                    }
                }
            }
            
            ApexPages.currentPage().getParameters().put('planId', revPlan.Id); 
            RevenuePlanning rp = new RevenuePlanning(); 
            rp.rpList = rpList;
            rp.assetList = assetVacantList;
            //rp.oppIdSet = optySet;
            //rp.assetLeasingMap = assetLeasingMap;
            rp.yearList = yearList;
            rp.yearMonthMap = yearMonthMap;
            rp.generateProjection();
            
            GenerateRevenueProjection.generateLicenceFeeProjection(optySet, yearList, yearMonthMap);
            GenerateRevenueProjection.generateMonthlyCarParkBill(optySet, yearList, yearMonthMap);
            GenerateRevenueProjection.generateCAMProjection(optySet, yearList, yearMonthMap); 
            
            Set<String> assetCodeSet = new Set<String>();
            assetCodeSet.add(assetVacantList[0].Name+hot);
            
            List<SelectOption> finYearList = new List<SelectOption>();
            finYearList.add(new SelectOption('', '2021'));
            
            ViewEditProjection vep = new ViewEditProjection();
            vep.PlanId = revPlan.Id;
            vep.selectedFinancialYear = '2021';
            
            Integer selectedFinYear = Integer.valueOf(vep.selectedFinancialYear);
            
            Plan_Line_Items__c pli = new Plan_Line_Items__c();
            pli.Revenue_Plan__c = revPlan.Id;
            pli.Asset_Type__c= 'Leasable Unit';
            pli.Start_Date__c = Date.newInstance(2021, 04, 01);
            pli.Leasable_Unit__c = assetVId;
            pli.HEAD_OF_TERMS__c = hotId;
            pli.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAM1;
            pli.Asset_Name__c = '02 GBDOFFA4';
            insert pli;
            
            List<Plan_Line_Items__c> pItemsList = [Select Id, Charge_Type__c, Start_Date__c, Revenue_Plan__c,
                                                   Asset_Name__c, Building_Name__c, start_of_licence__c, End_Of_Licence__c,
                                                   Customer_Name__c, NUA__C,
                                                   Month_1_Amount__c,
                                                   Month_2_Amount__c,
                                                   Month_3_Amount__c,
                                                   Month_4_Amount__c,
                                                   Month_5_Amount__c,
                                                   Month_6_Amount__c,
                                                   Month_7_Amount__c,
                                                   Month_8_Amount__c,
                                                   Month_9_Amount__c,
                                                   Month_10_Amount__c,
                                                   Month_11_Amount__c,
                                                   Month_12_Amount__c,
                                                   Month_1_Color__c,
                                                   Month_2_Color__c,
                                                   Month_3_Color__c,
                                                   Month_4_Color__c,
                                                   Month_5_Color__c,
                                                   Month_6_Color__c,
                                                   Month_7_Color__c,
                                                   Month_8_Color__c,
                                                   Month_9_Color__c,
                                                   Month_10_Color__c,
                                                   Month_11_Color__c,
                                                   Month_12_Color__c,
                                                   Assumption__c,
                                                   HEAD_OF_TERMS__c,
                                                   ExtId__C, Asset_Type__c, Leasable_Unit__c, Name
                                                   FROM Plan_Line_Items__c Where Id =: pli.Id];
            
            Map < String, List < Plan_Line_Items__c >> assetPlanMap = new Map < String, List < Plan_Line_Items__c >> ();
            
            for (Plan_Line_Items__c p: pItemsList) {
                assetCodeSet.add(p.Asset_Name__c+p.Head_Of_Terms__c);
                if (assetPlanMap.containsKey(p.Asset_Name__c+p.Head_Of_Terms__c)) {
                    assetPlanMap.get(p.Asset_Name__c+p.Head_Of_Terms__c).add(p);
                } else {
                    List < Plan_Line_Items__c > tempList = new List < Plan_Line_Items__c > ();
                    tempList.add(p);
                    assetPlanMap.put(p.Asset_Name__c+p.Head_Of_Terms__c, tempList);
                }
            }
                  
            GenerateRevenueProjection.planItemWrapper wrap = new GenerateRevenueProjection.planItemWrapper(pItemsList[0], assetVacantList[0], true, 'NIX', 'NIX', 'NIX', 'NIX', 23141);
                
            vep.selectedChargeType = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
            
            vep.assetList = assetString;
            vep.planlineitem = pItemsList;
            vep.getFinancialYear = finYearList;
            vep.rpList = rpList;
            vep.submit();
            vep.save();
        }
        
        test.stopTest();
    }  
    
    static testmethod void testRevenuePlanning() {
        test.startTest();
        
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            
            String buildId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            String buildId2 = LeaseTestDataFactory.createOfficeSpaceBuilding();
            
            Floor__c f3 = new Floor__c();
            f3.Name = '02 GBDOFFA4';
            f3.Asset_Code__c = buildId;  
            f3.Total_Carpet_Area_Sq_ft__c = 40422;
            f3.Building__c = buildId;
            f3.Type_of_Premise__c = 'Warm Shell';
            insert f3;
            
            Junction_Unit__c ju2 = new Junction_Unit__c();
            ju2.Status__c = 'Leased';
            ju2.Carpet_Area_in_Sq_Ft__c = 40422;
            ju2.start_date__c = system.today();
            ju2.end_date__c = system.today().addMOnths(60);
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId);
            Id hotId = LeaseTestDataFactory.createHot(oppId);
            ju2.Opportunity__c = oppId;
            ju2.HEAD_OF_TERMS__c = hotId;
            ju2.Leasing_Status__c = 'Active Lease';
            ju2.Floor__c = f3.Id;
            insert ju2;
            
            Floor__c f4 = new Floor__c();
            f4.Name = '02 GBDOFFA3';
            f4.Asset_Code__c = buildId2;  
            f4.Total_Carpet_Area_Sq_ft__c = 40422;
            f4.Building__c = buildId2;
            f4.Type_of_Premise__c = 'Warm Shell';
            insert f4;
            
            Junction_Unit__c ju3 = new Junction_Unit__c();
            ju3.Status__c = 'Leased';
            ju3.Carpet_Area_in_Sq_Ft__c = 30000;
            ju3.start_date__c = system.today();
            ju3.end_date__c = system.today().addMOnths(60);
            Id oppId2 = LeaseTestDataFactory.createOpportunity(accoundId);
            Id hotId2 = LeaseTestDataFactory.createHot(oppId2);
            ju3.Opportunity__c = oppId2;
            ju3.HEAD_OF_TERMS__c = hotId2;
            ju3.Leasing_Status__c = 'Active Lease';
            ju3.Floor__c = f4.Id;
            insert ju3;
            
            List<Floor__c> assetList = [Select Id, Name, Building__r.Name,Building__r.Use_Of_Premises__c, 
                                        Asset_Code__c, Total_Carpet_Area_Sq_ft__c,
                                        Vacant_Area_Sq_ft__c, Status__c
                                        from Floor__c
                                        where Id=: f3.Id or Id=: f4.Id];
            
            List<Junction_Unit__c> juList = [Select Id, Name, floor__c, Start_Date__c, End_Date__c, 
                                             Lease_Status__c,Leasing_Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Account.Name, Head_Of_Terms__c,Head_Of_Terms__r.Id, Head_Of_Terms__r.Name, Head_Of_Terms__r.Licence_commencement_Date__c,
                                             Head_Of_Terms__r.Licence_End_Date__c, Head_Of_Terms__r.Net_usable_area_Area_Sq_ft__c, Carpet_Area_in_Sq_Ft__c,
                                             Floor__r.Building__r.Name,
                                             Floor__r.Asset_Code__c,Floor__r.Building__r.Use_Of_Premises__c 
                                             from Junction_Unit__c 
                                             where (Floor__c =: assetList[0].Id or Floor__c =: assetList[1].Id ) and 
                                             (lease_status__c = 'Active Lease' ) and 
                                             (Opportunity__c = :oppId or Opportunity__c = :oppId2 ) and 
                                             (Head_Of_Terms__c =:hotId or Head_Of_Terms__c =:hotId2) ];
            system.assertEquals(2, juList.size());
            
            Map < Id, List < Junction_Unit__c >> assetLeasingMap = new Map < Id, List < Junction_Unit__c >> ();
            Set < Id > oppIdSet = new Set < Id > ();
            
            if (!juList.IsEmpty()) {
                for (Junction_Unit__C j: juList) {
                    if (assetLeasingMap.containsKey(j.Head_Of_Terms__c)) {
                        assetLeasingMap.get(j.Head_Of_Terms__c).add(j);
                    } else {
                        List < Junction_Unit__c > jList = new List < Junction_Unit__c > ();
                        jList.add(j);
                        oppIdSet.add(j.Opportunity__r.Id);
                        assetLeasingMap.put(j.Head_Of_Terms__c, jList);
                    }
                }
            }
            
            Revenue_Plan__c revPlan = new Revenue_Plan__c();
            revPlan.Status__c = 'Not Generated';
            revPlan.Type__c = 'Optimistic';
            revPlan.Number_of_years__c = 1;
            revPlan.Start_Date__c = Date.newInstance(2021, 04, 01);
            revPlan.End_Date__c = Date.newInstance(2022, 03, 31);
            insert revPlan;
            
            Map < Integer, List < Date >> yearMonthMap = new Map < Integer, List < Date >> ();
            List < Integer > yearList = new List < Integer > ();
            List < String > typeList = new List < String > ();
            Integer numOfyears = 0;
            Boolean error = false;
            Boolean licenseFeeGenerated = false;
            
            
            List <Revenue_Plan__c> rpList = [Select Id, Name, Number_Of_years__C, Start_Date__C, End_Date__c, Description__c, Status__c, Type__c, Final__c 
                                             from Revenue_Plan__c 
                                             where id =: revPlan.Id];
            
            if(rpList[0].status__c.equalsIgnoreCase('Not Generated'))
                licenseFeeGenerated = false;  
            else {
                licenseFeeGenerated = true;  
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',Projections have been already generated, please use the view modify button for making changes to the existing projections'));    
            }
            // the number of years the revenue plan is defined for. generally 3, ABP, SBP1, SBP2
            numOfyears = Integer.valueOf(rpList[0].Number_Of_years__c);
            
            // get the financial year start month, Apr -1 st for ex:
            Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
            
            // take that plan start and plan end from the  plan header
            String planStart = rpList[0].Start_Date__c.format();
            String planEnd = rpList[0].End_Date__c.format();
            
            // plan start date 1st April 2022 for ex: plan year + 1st day of the org fiscal month
            Date startOfYearMonth = Date.newinstance(rpList[0].start_date__c.year(), orgFiscalMonth, 1);
            
            // type of plan, pessimistic, optimistic, full throttle etc
            typeList.add(rpList[0].Type__c);
            for (Integer i = 1; i <= numOfyears; i++) {
                List < Date > tempDates = new List < Date > ();
                // for the number of years in the plan, start from 1st april and generate the list of 12 months 
                // till end of the year , 31st March
                tempDates.add(startOfYearMonth);
                //this is the year wise list.
                yearMonthMap.put(startOfYearMonth.year(), tempDates);
                yearList.add(startOfYearMonth.year());
                
                for (integer j = 2; j <= 12; j++) {
                    Date nextMonth = Date.newinstance(
                        startOfYearMonth.year(), 
                        startOfYearMonth.Month() + j - 1, 
                        1
                    );
                    yearMonthMap.get(startOfYearMonth.year()).add(nextMonth);
                }
                startOfYearMonth = startOfYearMonth.addMonths(12);
            }
            
            RevenuePlanning rPlan = new RevenuePlanning();
            rPlan.rpList = rpList;
            rPlan.assetList = assetList;
            rPlan.assetLeasingMap = assetLeasingMap;
            rPlan.yearList = yearList;
            rPlan.yearMonthMap = yearMonthMap;
            rPlan.generateProjection();
        }
        test.stopTest();
    } 
    
    static testmethod void testViewEditProjection() {
        test.startTest();
        
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        Id accoundId = LeaseTestDataFactory.createAccount();
        
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            
            String buildId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            String buildId2 = LeaseTestDataFactory.createOfficeSpaceBuilding();
            
            Project_Unit__c building = [Select Id, Name from Project_Unit__c where Id =: buildId];
            
            Floor__c f3 = new Floor__c();
            f3.Name = '02 GBDOFFA4';
            f3.Asset_Code__c = buildId;  
            f3.Total_Carpet_Area_Sq_ft__c = 40422;
            f3.Building__c = buildId;
            f3.Type_of_Premise__c = 'Warm Shell';
            insert f3;
            
            Junction_Unit__c ju2 = new Junction_Unit__c();
            ju2.Status__c = 'Leased';
            ju2.Carpet_Area_in_Sq_Ft__c = 40422;
            ju2.start_date__c = Date.newInstance(2021, 04, 01);
            ju2.end_date__c = Date.newInstance(2022, 03, 31);
            Id oppId = LeaseTestDataFactory.createOpportunity(accoundId);
            Id hotId = LeaseTestDataFactory.createHot(oppId);
            ju2.Opportunity__c = oppId;
            ju2.HEAD_OF_TERMS__c = hotId;
            ju2.Leasing_Status__c = 'Active Lease';
            ju2.Floor__c = f3.Id;
            insert ju2;
            
            Floor__c f4 = new Floor__c();
            f4.Name = '02 GBDOFFA3';
            f4.Asset_Code__c = buildId2;  
            f4.Total_Carpet_Area_Sq_ft__c = 40422;
            f4.Building__c = buildId2;
            f4.Type_of_Premise__c = 'Warm Shell';
            insert f4;
            
            Junction_Unit__c ju3 = new Junction_Unit__c();
            ju3.Status__c = 'Leased';
            ju3.Carpet_Area_in_Sq_Ft__c = 30000;
            ju3.start_date__c = system.today();
            ju3.end_date__c = system.today().addMOnths(60);
            Id oppId2 = LeaseTestDataFactory.createOpportunity(accoundId);
            Id hotId2 = LeaseTestDataFactory.createHot(oppId2);
            ju3.Opportunity__c = oppId2;
            ju3.HEAD_OF_TERMS__c = hotId2;
            ju3.Leasing_Status__c = 'Active Lease';
            ju3.Floor__c = f4.Id;
            insert ju3;
            
            Opportunity opp = [Select Id, Name from Opportunity where Id =: oppId];
            
            List<Floor__c> assetList = [Select Id, Name, Building__r.Name, Asset_Code__c, Total_Carpet_Area_Sq_ft__c,Building__r.Use_Of_Premises__c,
                                        Vacant_Area_Sq_ft__c, Status__c
                                        from Floor__c
                                        where Id=: f3.Id or Id=: f4.Id];
            
            List<Junction_Unit__c> juList = [Select Id, Name, floor__c, Start_Date__c, End_Date__c, 
                                             Lease_Status__c,Leasing_Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Account.Name, Head_Of_Terms__c,Head_Of_Terms__r.Id, Head_Of_Terms__r.Name, Head_Of_Terms__r.Licence_commencement_Date__c,
                                             Head_Of_Terms__r.Licence_End_Date__c, Head_Of_Terms__r.Net_usable_area_Area_Sq_ft__c, Carpet_Area_in_Sq_Ft__c,
                                             Floor__r.Building__r.Name,
                                             Floor__r.Asset_Code__c,Floor__r.Building__r.Use_Of_Premises__c 
                                             from Junction_Unit__c 
                                             where (Floor__c =: assetList[0].Id or Floor__c =: assetList[1].Id ) and 
                                             (lease_status__c = 'Active Lease' ) and 
                                             (Opportunity__c = :oppId or Opportunity__c = :oppId2 ) and 
                                             (Head_Of_Terms__c =:hotId or Head_Of_Terms__c =:hotId2) ];
            system.assertEquals(1, juList.size());
            
            Map < Id, List < Junction_Unit__c >> assetLeasingMap = new Map < Id, List < Junction_Unit__c >> ();
            Set < Id > oppIdSet = new Set < Id > ();
            
            if (!juList.IsEmpty()) {
                for (Junction_Unit__C j: juList) {
                    if (assetLeasingMap.containsKey(j.Head_Of_Terms__c)) {
                        assetLeasingMap.get(j.Head_Of_Terms__c).add(j);
                    } else {
                        List < Junction_Unit__c > jList = new List < Junction_Unit__c > ();
                        jList.add(j);
                        oppIdSet.add(j.Opportunity__r.Id);
                        assetLeasingMap.put(j.Head_Of_Terms__c, jList);
                    }
                }
            }
            
            Revenue_Plan__c revPlan = new Revenue_Plan__c();
            revPlan.Status__c = 'Not Generated';
            revPlan.Type__c = 'Optimistic';
            revPlan.Number_of_years__c = 1;
            revPlan.Start_Date__c = Date.newInstance(2021, 04, 01);
            revPlan.End_Date__c = Date.newInstance(2022, 03, 31);
            insert revPlan;
            
            Map < Integer, List < Date >> yearMonthMap = new Map < Integer, List < Date >> ();
            List < Integer > yearList = new List < Integer > ();
            List < String > typeList = new List < String > ();
            Integer numOfyears = 0;
            Boolean error = false;
            Boolean licenseFeeGenerated = false;
            
            
            List <Revenue_Plan__c> rpList = [Select Id, Name, Number_Of_years__C, Start_Date__C, End_Date__c, Description__c, Status__c, Type__c, Final__c 
                                             from Revenue_Plan__c 
                                             where id =: revPlan.Id];
            
            if(rpList[0].status__c.equalsIgnoreCase('Not Generated'))
                licenseFeeGenerated = false;  
            else {
                licenseFeeGenerated = true;  
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',Projections have been already generated, please use the view modify button for making changes to the existing projections'));    
            }
            // the number of years the revenue plan is defined for. generally 3, ABP, SBP1, SBP2
            numOfyears = Integer.valueOf(rpList[0].Number_Of_years__c);
            
            // get the financial year start month, Apr -1 st for ex:
            Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
            
            // take that plan start and plan end from the  plan header
            String planStart = rpList[0].Start_Date__c.format();
            String planEnd = rpList[0].End_Date__c.format();
            
            // plan start date 1st April 2022 for ex: plan year + 1st day of the org fiscal month
            Date startOfYearMonth = Date.newinstance(rpList[0].start_date__c.year(), orgFiscalMonth, 1);
            
            // type of plan, pessimistic, optimistic, full throttle etc
            typeList.add(rpList[0].Type__c);
            for (Integer i = 1; i <= numOfyears; i++) {
                List < Date > tempDates = new List < Date > ();
                // for the number of years in the plan, start from 1st april and generate the list of 12 months 
                // till end of the year , 31st March
                tempDates.add(startOfYearMonth);
                //this is the year wise list.
                yearMonthMap.put(startOfYearMonth.year(), tempDates);
                yearList.add(startOfYearMonth.year());
                
                for (integer j = 2; j <= 12; j++) {
                    Date nextMonth = Date.newinstance(
                        startOfYearMonth.year(), 
                        startOfYearMonth.Month() + j - 1, 
                        1
                    );
                    yearMonthMap.get(startOfYearMonth.year()).add(nextMonth);
                }
                startOfYearMonth = startOfYearMonth.addMonths(12);
            }
            
            List<SelectOption> finYearList = new List<SelectOption>();
            finYearList.add(new SelectOption(' ', '2021'));
            
            List<SelectOption> chargeType = new List<SelectOption>();
            chargeType.add(new SelectOption(' ', ElbConstantsClass.CHARGE_TYPE_CAM1));
            
            Plan_Line_Items__c pli = new Plan_Line_Items__c();
            pli.Revenue_Plan__c = revPlan.Id;
            pli.Asset_Type__c= 'Leasable Unit';
            pli.Start_Date__c = Date.newInstance(2021, 04, 01);
            pli.Leasable_Unit__c = f3.Id;
            pli.HEAD_OF_TERMS__c = hotId;
            pli.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAM1;
            pli.Asset_Name__c = f3.Name;
            pli.building_name__c = '02GBD';
            insert pli;
            
            List<Plan_Line_Items__c> pItemsList = [Select Id, Charge_Type__c, Start_Date__c, Revenue_Plan__c,
                                                   Asset_Name__c, Building_Name__c, start_of_licence__c, End_Of_Licence__c,
                                                   Customer_Name__c, NUA__C,
                                                   Month_1_Amount__c,
                                                   Month_2_Amount__c,
                                                   Month_3_Amount__c,
                                                   Month_4_Amount__c,
                                                   Month_5_Amount__c,
                                                   Month_6_Amount__c,
                                                   Month_7_Amount__c,
                                                   Month_8_Amount__c,
                                                   Month_9_Amount__c,
                                                   Month_10_Amount__c,
                                                   Month_11_Amount__c,
                                                   Month_12_Amount__c,
                                                   Month_1_Color__c,
                                                   Month_2_Color__c,
                                                   Month_3_Color__c,
                                                   Month_4_Color__c,
                                                   Month_5_Color__c,
                                                   Month_6_Color__c,
                                                   Month_7_Color__c,
                                                   Month_8_Color__c,
                                                   Month_9_Color__c,
                                                   Month_10_Color__c,
                                                   Month_11_Color__c,
                                                   Month_12_Color__c,
                                                   Assumption__c,
                                                   HEAD_OF_TERMS__c,
                                                   ExtId__C, Asset_Type__c, Leasable_Unit__c, Name
                                                   FROM Plan_Line_Items__c Where Id =: pli.Id];
            
            Map < String, Plan_Line_Items__c > assetPlanMap = new Map < String, Plan_Line_Items__c > ();
            
            List<Head_Of_Terms__c> hotList = [Select Id, Name, Licence_End_Date__c from Head_Of_Terms__c where Id = :hotId]; 
            
            Set<String> assetCodeSet = new Set<String>();
            assetCodeSet.add(f3.Name + hotList[0].Name);
            
            List<String> assetString = new List<String>();
            assetString.add(f3.Name);
            
            for (Plan_Line_Items__c p: pItemsList) {
                if (assetPlanMap.containsKey(' ')) {
                    assetPlanMap.get(' ');
                } else {
                    Plan_Line_Items__c tempList = new Plan_Line_Items__c();
                    assetPlanMap.put(' ', tempList);
                }
            }
            
            PageReference pageRef = Page.ViewEditProjection;
            Test.setCurrentPage(pageRef);
            
            List<ViewEditProjection.planItemWrapper> wrapList = new List<ViewEditProjection.planItemWrapper>();
            wrapList.add(new ViewEditProjection.planItemWrapper(assetPlanMap, f3.Name, building.Name, false, 'Leased', opp.Name, '', '', 6788, '#00FF7F', ' '));
            
            ApexPages.currentPage().getParameters().put('planId', revPlan.Id); 
            ViewEditProjection vep = new ViewEditProjection();
            vep.PlanId = revPlan.Id;
            vep.selectedFinancialYear = '2021';
			Integer selectedFinYear = Integer.valueOf(vep.selectedFinancialYear);
            vep.selectedChargeType = ElbConstantsClass.CHARGE_TYPE_CAM1;
            vep.assetList = assetString;
            vep.planlineitem = pItemsList;
            vep.getFinancialYear = finYearList;
            vep.getchargetype = chargeType;
            vep.pWrapper = wrapList;
            vep.rpList = rpList;
            vep.submit();
            vep.save();
        }
        test.stopTest();
    } 
}