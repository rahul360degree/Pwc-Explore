public class RevenuePlanning {
    Public List < Revenue_Plan__c > rpList {
        get;
        set;
    }
    Public String PlanId {
        get;
        set;
    }
    Public Integer numOfyears {
        get;
        set;
    }
    Public Map < Integer, List < Date >> yearMonthMap {
        get;
        set;
    }
    Public Boolean error {
        get;
        set;
    }
    Public String planStart {
        get;
        set;
    }
    Public String planEnd {
        get;
        set;
    }
    Public List < Integer > yearList {
        get;
        set;
    }
    Public List < String > typeList {
        get;
        set;
    }
    Public List < Floor__c > assetList {
        get;
        set;
    }
    
    public Boolean licenseFeeGenerated {get;set;}
    List < Floor__c > leasedAssetList = new List < Floor__c > ();
    List < Junction_Unit__c > leasingDetailsList = new List < Junction_Unit__c > ();
    public Map < Id, List < Junction_Unit__c >> assetLeasingMap = new Map < Id, List < Junction_Unit__c >> ();
    Map < Id, Map < Date, GenerateRevenueProjection.billResponseWrapper >> hotpMap = new Map < Id, Map < Date, GenerateRevenueProjection.billResponseWrapper >> ();
    Set < Id > oppIdSet = new Set < Id > ();
    /** 

* will allow the user to do the revenue planning 
* by simulating the projections for the upcoming years
* based on the current licensed tenants and the potential 
* revenue based on the assumptions entered by the user.
* take the number of years defined in the revenue plan and generate the license fee
* CAM and car park projections for those
*/
    public RevenuePlanning() {
        System.debug('test rp 1');
        rpList = new List < Revenue_Plan__c > ();
        yearMonthMap = new Map < Integer, List < Date >> ();
        yearList = new List < Integer > ();
        typeList = new List < String > ();
        assetList = new List < Floor__c > ();
        numOfyears = 0;
        error = false;
        licenseFeeGenerated = false;
        
        System.debug('ApexPages.currentPage().getParameters() :'+ApexPages.currentPage().getParameters());
        if (ApexPages.currentPage().getParameters().get('planId') != null && ApexPages.currentPage().getParameters().get('planId') != '') {
            
            System.debug('test rp 2');
            planId = apexPages.currentPage().getParameters().get('planId');
            
            if (planId != null) {
                System.debug('test rp 3');
                rpList = [Select Id, Name, Number_Of_years__C, Start_Date__C, End_Date__c, Description__c, Status__c, Type__c, Final__c from Revenue_Plan__c where id =: PlanId];
                if (rpList != null && rpList.size() == 1) {
                    System.debug('test rp 4');
                    if(rpList[0].status__c.equalsIgnoreCase('Not Generated')){
                        System.debug('test rp 5');
                        licenseFeeGenerated = false; 
                    }
                         
                    else {
                        System.debug('test rp 6');
                        licenseFeeGenerated = true;  
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',Projections have been already generated, please use the view modify button for making changes to the existing projections'));    
                    }
                    System.debug('test rp 7');
                    // the number of years the revenue plan is defined for. generally 3, ABP, SBP1, SBP2
                    numOfyears = Integer.valueOf(rpList[0].Number_Of_years__c);
                    
                    // get the financial year start month, Apr -1 st for ex:
                    Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
                    
                    // take that plan start and plan end from the  plan header
                    planStart = rpList[0].Start_Date__c.format();
                    planEnd = rpList[0].End_Date__c.format();
                    
                    // plan start date 1st April 2022 for ex: plan year + 1st day of the org fiscal month
                    Date startOfYearMonth = Date.newinstance(rpList[0].start_date__c.year(), orgFiscalMonth, 1);
                    
                    // type of plan, pessimistic, optimistic, full throttle etc
                    typeList.add(rpList[0].Type__c);
                    for (Integer i = 1; i <= numOfyears; i++) {
                        System.debug('test rp 8');
                        List < Date > tempDates = new List < Date > ();
                        // for the number of years in the plan, start from 1st april and generate the list of 12 months 
                        // till end of the year , 31st March
                        tempDates.add(startOfYearMonth);
                        //this is the year wise list.
                        yearMonthMap.put(startOfYearMonth.year(), tempDates);
                        yearList.add(startOfYearMonth.year());
                        
                        for (integer j = 2; j <= 12; j++) {
                            System.debug('test rp 9');
                            Date nextMonth = Date.newinstance(
                                startOfYearMonth.year(), 
                                startOfYearMonth.Month() + j - 1, 
                                1
                            );
                            System.debug('nextMonth to test :'+nextMonth);
                            yearMonthMap.get(startOfYearMonth.year()).add(nextMonth);
                        }
                        System.debug('test rp 10');
                        System.debug('yearMonthMap :'+yearMonthMap);
                        startOfYearMonth = startOfYearMonth.addMonths(12);
                    }
                    // fetch all assets , Building__r.Use_Of_Premises__c
                    assetList = [Select Id, Name, Building__r.Name,Building__r.Use_Of_Premises__c, Asset_Code__c, Total_Carpet_Area_Sq_ft__c, Vacant_Area_Sq_ft__c, Status__c 
                                 from Floor__C 
                                 order by Building__c, Floor_Number__c  LIMIT 200];
                    
                    // check which ones are under an active lease
                    for (Floor__c f: assetList) {
                        System.debug('test rp 11');
                        if (String.isNotBlank(f.Status__c) && (f.status__c.equalsIgnoreCase('Leased Out') || f.status__c.equalsIgnoreCase('Partly Vacant') || f.status__c.equalsIgnoreCase('Churn Expected'))) {
                            System.debug('test rp 12');
                            leasedAssetList.add(f);
                        }
                    }
                    system.debug('leasedAssetList'+leasedAssetList);
                    
                    // get the rental objects for those assets, which has the opportunity and HOT tagging
                    // along with start and end lease dates
                    if (!leasedAssetList.isEmpty()) {
                        System.debug('test rp 13');
                        leasingDetailsList = [Select Id, Name, floor__c, Start_Date__c, End_Date__c, 
                                              Lease_Status__c,Leasing_Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Account.Name, Head_Of_Terms__c,Head_Of_Terms__r.Id, Head_Of_Terms__r.Name, Head_Of_Terms__r.Licence_commencement_Date__c,
                                              Head_Of_Terms__r.Licence_End_Date__c, Head_Of_Terms__r.Net_usable_area_Area_Sq_ft__c, Carpet_Area_in_Sq_Ft__c,
                                    	          Floor__r.Building__r.Name,
                                              Floor__r.Asset_Code__c,Floor__r.Building__r.Use_Of_Premises__c
                                              from Junction_Unit__c where Floor__c =: leasedAssetList
                                              and (lease_status__c = 'Active Lease' or lease_status__c = 'Coming up for renewal') and Head_Of_Terms__c != null and 
                                              Opportunity__c != null
                                             ];
                           system.debug('leasingDetailsList:---'+leasingDetailsList);
                        system.debug('leasingDetailsList.size():---'+leasingDetailsList.size());
                        
                        // make a map of Floor, rental units = assetLeasingMap
                        if (leasingDetailsList.IsEmpty()){ System.debug('emtyo junction ');}
                        if (!leasingDetailsList.IsEmpty()) {
                            System.debug('test rp 14');
                            for (Junction_Unit__C j: leasingDetailsList) {
                                System.debug('test rp 15');
                                if (assetLeasingMap.containsKey(j.Head_Of_Terms__c)) {
                                    System.debug('test rp 16');
                                    assetLeasingMap.get(j.Head_Of_Terms__c).add(j);
                                } else {
                                    System.debug('test rp 17');
                                    List < Junction_Unit__c > jList = new List < Junction_Unit__c > ();
                                    jList.add(j);
                                    oppIdSet.add(j.Opportunity__r.Id);
                                    assetLeasingMap.put(j.Head_Of_Terms__c, jList);
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    public void generateProjection(){
        System.debug('test rp 18');
        generateProjectionForChargeType(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE);
        generateProjectionForChargeType(ElbConstantsClass.CHARGE_TYPE_CAR_PARK);
        generateProjectionForChargeType(ElbConstantsClass.CHARGE_TYPE_CAM1);
    }
    public void generateProjectionForChargeType(String cType) {
        System.debug('test rp 18.1');
        System.debug('cType :'+cType);
        Boolean leased = false;
        List < Junction_Unit__c > jl = new List < Junction_Unit__c > ();
        String licenceStart = '';
        String licenceEnd = '';
        String leaseStatus ='';
        String oppName = '';
        Decimal nua;
        List<Plan_Line_Items__c> pItemsList = new List<Plan_Line_Items__c>();
        hotpMap = new Map < Id, Map < Date, GenerateRevenueProjection.billResponseWrapper >> ();
        // generate projections for the monthly license fee as per the billing schedule
        // HOTId, <Month,Amount> till the lease expires
        system.debug('oppIdSet.keySet():--'+oppIdSet);
       // system.debug('oppIdSet.values():--'+oppIdSet.values());
        System.debug('yearList:--'+yearList);
        System.debug('yearMonthMap:--'+yearMonthMap);
        if(string.isNotBlank(cType) && cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE)){
            System.debug('test rp 19');
            hotpMap = GenerateRevenueProjection.generateLicenceFeeProjection(oppIdSet,yearList,yearMonthMap);
        }
            
        else if(string.isNotBlank(cType) && cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAR_PARK)){
            System.debug('test rp 20');
            hotpMap = GenerateRevenueProjection.generateMonthlyCarParkBill(oppIdSet,yearList,yearMonthMap);
        }
            
        else if(string.isNotBlank(cType) && cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAM1)){
            System.debug('test rp 21');
            hotpMap = GenerateRevenueProjection.generateCAMProjection(oppIdSet,yearList,yearMonthMap);
        }
            
        
        
        try {
            System.debug('test rp 22');
            // for each year in the  projection plan
            // for each leased asset
            // there can be more than one per floor
            // each HOT represents one leased unit
            system.debug('assetLeasingMap.keySet():--'+assetLeasingMap.keySet());
            system.debug('assetLeasingMap.values():--'+assetLeasingMap.values());
            system.debug('hotpMap.keySet():--'+hotpMap.keySet());
            system.debug('hotpMap.values():--'+hotpMap.values());
            for (Id h: assetLeasingMap.keySet()) {
                System.debug('test rp 23');
                 system.debug('yearList:--'+yearList);
                for (Integer i: yearList) {
                    System.debug('test rp 24');
                    //for every premises tagged on an HOT
                        Integer count = 0;
                        // for each month
                        
                        Junction_Unit__c ju = assetLeasingMap.get(h)[0];
                        for (Date d: yearMonthMap.get(i)) {
                            System.debug('test rp 25');
                            count++;
                            Plan_Line_Items__c p = new Plan_Line_Items__c();
                            // if its a leased asset, get the projected bill for that month and populate the value
                            if (hotpMap.containsKey(h)) {
                                System.debug('test rp 26');
                                GenerateRevenueProjection.billResponseWrapper b = new GenerateRevenueProjection.billResponseWrapper();
                                b = hotpMap.get(h).get(d);
                                if(b != null) {
                                    System.debug('test rp 27');
                                    p.put('Month_' + count + '_Amount__c', b.billAmount);
                                    if(b.termEnd) {
                                        System.debug('test rp 28');
                                        // termEnd is red
                                        p.put('Month_' + count + '_Color__c','red');
                                    }
                                    else if(b.leaseExpired){
                                        System.debug('test rp 29');
                                        // expired lease is blue
                                        p.put('Month_' + count + '_Color__c','#ABDEE6'); 
                                    }
                                    else if(b.escalation){
                                        System.debug('test rp 30');
                                        // expired lease is blue
                                        p.put('Month_' + count + '_Color__c','#db7093'); 
                                    }
                                    else{
                                        System.debug('test rp 31');
                                        // active lease is pale red
                                        p.put('Month_' + count + '_Color__c','pink'); 
                                    }
                                    
                                    System.debug('test rp 32');
                                    p.Asset_Type__c = 'Leasable Unit';
                                    p.Assumption__c = '';
                                    p.Leasable_Unit__c = ju.Floor__C;
                                    p.Name = ju.Name;
                                    p.Asset_Name__c = ju.Floor__r.Asset_Code__c;
                                    if(String.isNotBlank(ju.Floor__r.Building__r.Use_Of_Premises__c) && 
                                       (ju.Floor__r.Building__r.Use_Of_Premises__c.contains('Office Space') || 
                                        ju.Floor__r.Building__r.Use_Of_Premises__c.contains('ATM') || 
                                        ju.Floor__r.Building__r.Use_Of_Premises__c.contains('Land Area') ||
                                        ju.Floor__r.Building__r.Use_Of_Premises__c.contains('Others') ||
                                        ju.Floor__r.Building__r.Use_Of_Premises__c.contains('Industrial'))
                                       && cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE)){
                                          System.debug('test rp 33');
                                          p.Charge_Type__c = ElbConstantsClass.CATEGORY_COMMERCIAL;
                                      }
                                        
                                    else if(cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAR_PARK)){
                                        System.debug('test rp 34');
                                        p.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAR_PARK;
                                    }
                                        
                                    else if (cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAM1)){
                                        System.debug('test rp 35');
                                        p.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAM1;
                                    }
                                    else{
                                        System.debug('test rp 36');
                                        p.Charge_Type__c = ju.Floor__r.Building__r.Use_Of_Premises__c;
                                       /* List<String> chargeTypes = new List<String>();
                                        chargeTypes.add(ju.Floor__r.Building__r.Use_Of_Premises__c);
                                        p.Charge_Type__c = String.join(chargeTypes, ';');*/
                                    }
                                    
                                    System.debug('test rp 37');
                                    p.Building_Name__c = ju.Floor__r.Building__r.Name;
                                    p.Start_Date__c = d;
                                    p.Revenue_Plan__c = planId;
                                    p.extId__c = PlanId +ju.Floor__r.Asset_Code__c + h +d.year() + '-' + d.month() + '-' + d.day() +p.Charge_Type__c+p.Customer_Name__c;
                                    p.Head_Of_Terms__c = h;
                                    
                                    
                                    if (ju.Head_Of_Terms__r.Licence_commencement_Date__c != null) {
                                        System.debug('test rp 38');
                                        licenceStart = ju.Head_Of_Terms__r.Licence_commencement_Date__c.format();
                                        p.start_of_licence__c = ju.Head_Of_Terms__r.Licence_commencement_Date__c;
                                    }
                                    if (ju.Head_Of_Terms__r.Licence_End_Date__c != null) {
                                        System.debug('test rp 39');
                                        licenceEnd = ju.Head_Of_Terms__r.Licence_End_Date__c.format();
                                        p.End_Of_Licence__c = ju.Head_Of_Terms__r.Licence_End_Date__c;
                                    }
                                    System.debug('test rp 40');
                                    leaseStatus = ju.Lease_Status__c;
                                    oppName = ju.Opportunity__r.Account.Name;
                                    nua =ju.Head_Of_Terms__r.Net_usable_area_Area_Sq_ft__c;
                                    p.nua__c = nua;
                                    p.Customer_Name__c = oppName;
                                    
                                    pItemsList.add(p);
                                } else {
                                    System.debug('test rp 41');
                                    // leased but no billing schedule
                                    p.put('Month_' + count + '_Color__c','black'); 
                                    p.put('Month_' + count + '_Amount__c', 0);
                                }
                                
                            } else {
                                System.debug('test rp 42');
                                //else populate as zero
                                p.put('Month_' + count + '_Amount__c', 0);
                                p.put('Month_' + count + '_Color__c', '#CCE2CB');
                            }
                        } // month loop 
                } // year loop
            } // leased asset loop
            // for non leased spaces
            // create them as  new licenses
            // with whatever area is vacant in them
            for(Floor__C f : assetList){
                System.debug('test rp 43');
                if (String.isNotBlank(f.Status__c) && (f.status__c.equalsIgnoreCase('Fully Vacant') || f.status__c.equalsIgnoreCase('Partly Vacant'))) {
                    System.debug('test rp 44');
                    for (Integer i: yearList) {
                        System.debug('test rp 45');
                        Integer count = 0;
                        // for each month
                        for (Date d: yearMonthMap.get(i)) {
                            System.debug('test rp 46');
                            count++;
                            Plan_Line_Items__c p = new Plan_Line_Items__c();
                            p.Asset_Type__c = 'Leasable Unit';
                            p.Assumption__c = '';
                            p.Leasable_Unit__c = f.Id;
                            p.Name = f.Name;
                            p.Asset_Name__c = f.Asset_Code__c;
                            if(String.isNotBlank(f.Building__r.Use_Of_Premises__c) && 
                               (f.Building__r.Use_Of_Premises__c.contains('Office Space') || 
                                f.Building__r.Use_Of_Premises__c.contains('ATM') || 
                                f.Building__r.Use_Of_Premises__c.contains('Land Area') ||
                                f.Building__r.Use_Of_Premises__c.contains('Others') ||
                                f.Building__r.Use_Of_Premises__c.contains('Industrial'))
                               && cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE)){
                                  System.debug('test rp 47');
                                  p.Charge_Type__c = ElbConstantsClass.CATEGORY_COMMERCIAL;
                              }
                                
                            else if(cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAR_PARK)){
                                System.debug('test rp 48');
                                p.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAR_PARK;
                            }
                               
                            else if (cType.equalsIgnoreCase(ElbConstantsClass.CHARGE_TYPE_CAM1)){
                                System.debug('test rp 49');
                                p.Charge_Type__c = ElbConstantsClass.CHARGE_TYPE_CAM1;                               
                            }                               
                            else{
                                 System.debug('test rp 50');
                                 p.Charge_Type__c = f.Building__r.Use_Of_Premises__c;
                            }
                            System.debug('test rp 51');    
                            p.Building_Name__c = f.Building__r.Name;
                            p.Start_Date__c = d;
                            p.Revenue_Plan__c = planId;
                            p.extId__c = PlanId + f.Asset_Code__c +d.year() + '-' + d.month() + '-' + d.day() +p.Charge_Type__c+p.Customer_Name__c;
                            p.put('Month_' + count + '_Amount__c', 0);
                            p.put('Month_' + count + '_Color__c', '#CCE2CB');
                            leaseStatus = 'Vacant';
                            p.nua__c = f.Vacant_Area_Sq_ft__c;
                            p.Customer_Name__c = 'New Customer';
                            pItemsList.add(p);
                        } // month loop
                    } // year loop
                }
            }
            System.debug('test rp 52');
            Database.insert(pItemsList);
            licenseFeeGenerated = true;
            rpList[0].status__c = 'Generated';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',Projections have been generated'));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'please use the view edit projections button on the page to make modifications'));
        }
        catch (Exception e){
            System.debug('test rp 53');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Hi ' + UserInfo.getName() + ',There was an error in generating the revenue projections, Please contact your system adminstrator' + e.getMessage()));
            system.debug('Exception:' + e.getMessage());
            rpList[0].status__c = 'Error in generation';
        } finally {
            System.debug('test rp 54');
            update rpList;
        }
    }
}