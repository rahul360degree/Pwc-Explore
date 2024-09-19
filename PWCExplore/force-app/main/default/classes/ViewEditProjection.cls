public without sharing class ViewEditProjection {
    Public String PlanId {
        get;
        set;
    }
    Public List < Revenue_Plan__c > rpList {
        get;
        set;
    }
    Public String selectedFinancialYear {
        get;
        set;
    }
    Public String selectedChargeType {
        get;
        set;
    }
    Public List < Plan_Line_Items__c > planlineitem {
        get;
        set;
    }
  
    Public List < planItemWrapper > pWrapper {
        get;
        set;
    }
    Public List < String > typeList {
        get;
        set;
    }
    Public Map < String, List < String >> allyearMonthStringMap {
        get;
        set;
    }
    Public Boolean error {
        get;
        set;
    }
    public List<String> assetList {
        get;
        set;
    }
    Map < String, List < Plan_Line_Items__c >> assetPlanMap {
        get;
        set;
    }
    public ViewEditProjection() {
        typeList = new List < String > ();
        pWrapper = new List < planItemWrapper > ();
        allyearMonthStringMap = new Map < String, List < String >> ();

        assetList = new List<String>();
        planId = ApexPages.currentPage().getParameters().get('planId');
    }
    public List < SelectOption > getFinancialYear {
        get {
            List < SelectOption > optns = new List < Selectoption > ();
            optns.add(new SelectOption('', 'Select Financial Year'));
            if (planId != null && planId != '') {
                Integer StartYear = 0;
                Integer EndYear = 0;

                rpList = [Select Id, Name, Number_Of_years__C, Start_Date__C, End_Date__c, Description__c, Status__c, Type__c, Final__c from Revenue_Plan__c where id =: PlanId];

                if (rpList != null && rpList.size() == 1) {

                    StartYear = rpList[0].Start_Date__C.year();
                    EndYear = rpList[0].End_Date__c.year();

                    while (StartYear < EndYear) {
                        String Durationoneyear = String.valueOf(StartYear) + ' - ' + String.valueOf(StartYear + 1);
                        StartYear = StartYear + 1;
                        optns.add(new SelectOption(String.valueOf(StartYear), Durationoneyear));
                        //StartYear = StartYear + 1;//moving it above to get the correct years as per the fiscal year set in org
                    }

                }

            }
            return optns;
        }
        set;
    }
    public List < SelectOption > getchargetype {
        get {
            List < SelectOption > optns = new List < Selectoption > ();
            optns.add(new SelectOption('', 'Select Charge Type'));
            if (planId != null && planId != '') {
                Schema.DescribeFieldResult fieldResult = Plan_Line_Items__c.Charge_Type__c.getDescribe();
                List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry pickListVal: ple) {
                    optns.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
                }
            }
            return optns;
        }
        set;
    }
    public void submit() {
        typeList = new List < String > ();
        pWrapper = new List < planItemWrapper > ();
        allyearMonthStringMap = new Map < String, List < String >> ();
        List < Plan_Line_Items__c > pItemsList = new List < Plan_Line_Items__c > ();
        List < Plan_Line_Items__c > Selectedyearplanlineitem = new List < Plan_Line_Items__c > ();
        Map < String, Plan_Line_Items__c > pYearMap = new Map < String, Plan_Line_Items__c > ();
        Set < String > assetCodeSet = new Set < String > ();
        assetPlanMap = new Map < String, List < Plan_Line_Items__c >> ();
        Integer selectedFinYear = Integer.valueOf(selectedFinancialYear);
        //Integer selectedFinYearEnd  = Integer.valueOf(selectedFinancialYear)+1;// not needed as per the "ending month" set in fiscal year in org
        Integer selectedFinYearStart  = Integer.valueOf(selectedFinancialYear)-1;
        
        if(selectedChargeType == ElbConstantsClass.CHARGE_TYPE_CAM){
            selectedChargeType = ElbConstantsClass.CHARGE_TYPE_CAM1;
        }
        else{
            selectedChargeType = selectedChargeType;
        }
        
        pItemsList = [Select Id, Charge_Type__c, Start_Date__c, Revenue_Plan__c,
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
            ExtId__C
            FROM Plan_Line_Items__c Where Charge_Type__c =: selectedChargeType AND Revenue_Plan__c =: planId AND FISCAL_YEAR(Start_Date__C) =: selectedFinYear  order by building_name__c ASC, asset_name__c ASC, Start_Date__C ASC
        ];
        typeList.add(rpList[0].Type__c);
        List < String > tempL = new List < String > ();
        allyearMonthStringMap.put(rpList[0].Type__c, tempL);

        // get the financial year start month, Apr -1 st for ex:
        Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;

        // plan start date 1st April 2022 for ex: plan year + 1st day of the org fiscal month
        Date startOfYearMonth = Date.newinstance(Integer.valueOf(selectedFinYearStart), orgFiscalMonth, 1);
        Integer numOfyears = 1;
        for (Integer i = 1; i <= numOfyears; i++) {
            List < Date > tempDates = new List < Date > ();
            // for the number of years in the plan, start from 1st april and generate the list of 12 months 
            // till end of the year , 1st april
            tempDates.add(startOfYearMonth);

            List < String > tempStringDates = new List < String > ();
            tempStringDates.add(
                DateTime.newInstance(
                    startOfYearMonth.year(),
                    startOfYearMonth.month(),
                    startOfYearMonth.day()
                ).format('MMMMM-YY')
            );

            //this is a single list of all months across all years of the revenue plan
            allyearMonthStringMap.get(rpList[0].Type__C).add(
                DateTime.newInstance(
                    startOfYearMonth.year(),
                    startOfYearMonth.month(),
                    startOfYearMonth.day()
                ).format('MMMMM-YY')
            );

            for (integer j = 2; j <= 12; j++) {
                Date nextMonth = Date.newinstance(
                    startOfYearMonth.year(),
                    startOfYearMonth.Month() + j - 1,
                    1
                );
                allyearMonthStringMap.get(rpList[0].Type__c).add(
                    DateTime.newInstance(
                        nextMonth.year(),
                        nextMonth.month(),
                        nextMonth.day()
                    ).format('MMMMM-YY')
                );
            }
            startOfYearMonth = startOfYearMonth.addMonths(12);
        }
        // organise the data asset code wise
        // we are printing one projection per asset per year per charge type
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
        Boolean leased = false;
        List < Junction_Unit__c > jl = new List < Junction_Unit__c > ();
        String licenceStart = '';
        String licenceEnd = '';
        String leaseStatus = '';
        String oppName = '';
        String buildingName = '';
        Decimal nua;
        String assetName = '';
        String extId = '';
        if (!assetCodeSet.isEmpty()) {
            for (String s: assetCodeSet) {
                // take any plan line item to decide if the asset is leased and get all the details of the asset.
                Plan_Line_Items__c pYear = new Plan_Line_Items__c();
                Integer count = 1;
                assetList.add(s);
                for (Plan_Line_Items__c p: assetPlanMap.get(s)) {
                    // take any one record and populate the common fields
                    if(p.start_of_licence__c != null)
                        licenceStart = p.start_of_licence__c.format();
                    if(p.End_Of_Licence__c != null)
                        licenceEnd = p.End_Of_Licence__c.format();
                    oppName = p.Customer_Name__c;
                    nua = p.nua__c;
                    extId = p.Asset_Name__c+p.Head_Of_Terms__c;
                    buildingName = p.Building_Name__c;
                    assetName = p.Asset_Name__c;
                    if (p.start_of_licence__c != null) {
                        leaseStatus = 'Leased';
                        leased = true;
                    }
                    // one asset for a single year and chargetype combo will have 12 records, each to represent one month projection
                    // need to  transpose into one record for that year to display it horizontally for editing as a single row
                    pYear.put('Month_' + count + '_Amount__c', p.get('Month_' + count + '_Amount__c'));
                    pYear.put('Month_' + count + '_Color__c',  p.get('Month_' + count + '_Color__c'));
                    if(count == 1)
                        if (Schema.sObjectType.Plan_Line_Items__c.fields.Assumption__c.isAccessible()){ 
                            pYear.Assumption__c = p.Assumption__c;
                          }
                    count++;
                } // for each plan for that asset
                pYearMap.put(extId,pYear);
                if (leased)
                    pWrapper.add(new PlanItemWrapper(pYearMap, assetName, buildingName, true, leaseStatus, oppName, licenceStart, licenceEnd, nua, '#FF6666', extId));
                else
                    pWrapper.add(new PlanItemWrapper(pYearMap,assetName, buildingName,false, 'Vacant', oppName, '', '', nua, '#00FF7F', extId));
                licenceStart = '';
                licenceEnd = '';
                leaseStatus = '';
                oppName = '';
                nua = 0;
                buildingName ='';
                leased = false;
            } // asset loop
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ', Below are the projections for :' + selectedFinYear + '-' + selectedFinYearEnd  + ' ' + selectedChargeType + ' Charges'));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ', Below are the projections for :' + selectedFinYearStart + '-' + selectedFinYear  + ' ' + selectedChargeType + ' Charges'));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Please make your edits and click on save to record the changes made'));
        }
    }
    public void save() {
        List<Plan_Line_Items__c> allPlanLineItems  = new List<Plan_Line_Items__c>();
        List<Plan_Line_Items__c> updatePlanList = new List<Plan_Line_Items__c>();
        for(planItemWrapper p : pWrapper){
            Integer count = 1;
            for (Plan_Line_Items__c pi: assetPlanMap.get(p.extId)){
                pi.put('Month_' + count + '_Amount__c', p.pl.get(p.extId).get('Month_' + count + '_Amount__c'));
                updatePlanList.add(pi);
                count++;
                pi.Assumption__c = p.pl.get(p.extId).Assumption__c;
            }
        } // each item in the wrapper represents one row for each asset
        try {
            update updatePlanList;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Plan updates have been saved!'));

        }catch (Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'There has been an error while saving your changes:' + e.getMessage()));
            system.debug('Exception:' + e.getMessage());
        } finally {

        }
    }

    public class planItemWrapper {
        Public Map < String, Plan_Line_Items__c > pl {
            get;
            set;
        }
        public string asset {
            get;
            set;
        }
        public string building {
            get;
            set;
        }
        Public Boolean leased {
            get;
            set;
        }
        Public String status {
            get;
            set;
        }
        Public String tenant {
            get;
            set;
        }
        public String licenceStart {
            get;
            set;
        }
        public String licenceEnd {
            get;
            set;
        }
        public Decimal NUA {
            get;
            set;
        }
        public String lColor {
            get;
            set;
        }
        public String extId {
            get;
            set;
        }

        Public PlanItemWrapper(Map < String, Plan_Line_Items__c > pi, String asset,String building, Boolean status, String s, String t, String ls, String ld, Decimal NUA, String leaseColor, String extId) {
            pl = new Map < String, Plan_Line_Items__c > ();
            leased = false;
            this.pl = pi;
            this.leased = status;
            this.status = s;
            this.tenant = t;
            this.licenceStart = ls;
            this.licenceEnd = ld;
            this.asset = asset;
            this.building = building;
            this.NUA = NUA;
            this.lColor = leaseColor;
            this.extId = extId;
        }

    }
}