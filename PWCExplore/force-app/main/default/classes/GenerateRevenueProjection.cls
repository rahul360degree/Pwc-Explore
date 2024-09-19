public with sharing class GenerateRevenueProjection {
    public static Map < Id, List < Opportunity >> optyMap {get;set;}
    public static List < Charges_Type__c > chargesTypeList {get;set;}
    public static Map < Id, List < HEAD_OF_TERMS__c >> optyHotMap {get;set;}
    
    //Fetch Record Types Method
    public static map < String, Id > fetchRecordTypes(String ObjApiName) {
        map < String, Id > rtMap = new map < String, Id > ();
        
        for (RecordType rt: [select Id, Name, DeveloperName from RecordType where sObjectType =: ObjApiName]) {
            rtMap.put(rt.Name, rt.Id);
        }
        return rtMap;
    }    

    
    //Generate License Feee Projections
    public static Map<Id,Map<date,billResponseWrapper>> generateLicenceFeeProjection(Set<Id> optyIdSetBatch, List<Integer> yearList, Map < Integer, List < Date >> yearMonthMap){
        optyMap = new Map < Id, List < Opportunity >> ();
        List<HEAD_OF_TERMS__c> hotList = new List < HEAD_OF_TERMS__c > ();
        set<Id> hotIdSet = new set< Id > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        List<Billing_Schedule__c> billSchList = new List < Billing_Schedule__c > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > (); 
        SurveyWrapper countLog = new SurveyWrapper();        
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        Map<Id, Map<Date,billResponseWrapper>> hotpMap = new Map<Id, Map<Date,billResponseWrapper>>();
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        // select all the assets
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Licence_commencement_date__c, License_fees_Commencement_date__c,
                   Licence_End_Date__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Licence_End_Date__c!= null];
        
        //Fetch Query for Charge Types
        chargesTypeList = [Select Id, Name, Charge_Type__c, Type_of_billing__c
                           From Charges_Type__c
                           Where Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE];
        
        try{
            if (!hotList.isEmpty()) {
                for (HEAD_OF_TERMS__c hot: hotList) {
                    //valid Leasing check OR Rent Free Period check
                    if (hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_ACTIVE || 
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_FREE ||
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_NA) {
                            hotIdSet.add(hot.Id);
                        }
                }
                //Check if Billing Schedule for charge type as Licsense Fee is Present
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.id,HEAD_OF_TERMS__r.Name, Charges_Type__c, 
                               Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE and (Start_Date__c != null  AND End_Date__c != null)
                              ];
                Map<Id, List<Billing_Schedule__c> > hotBillSchList = new Map<Id, List<Billing_Schedule__c>>();
                for(Billing_Schedule__c b : billSchList){
                    if(hotBillSchList.containsKey(b.HEAD_OF_TERMS__r.Id)) {
                        hotBillSchList.get(b.HEAD_OF_TERMS__r.Id).add(b);
                    } else {
                        List<Billing_Schedule__c> tempList = new List<Billing_Schedule__c>();
                        tempList.add(b);
                        hotBillSchList.put(b.HEAD_OF_TERMS__r.Id, tempList);
                        
                    }
                }
                
                Boolean termEndMonth = false;
                Boolean leaseExpired = false;
                Boolean escalation = false;
                Decimal lastMonthRent = 0;
                Decimal lastButOneMonthRent = 0;
                Boolean lastButOneMonth = false;
                Decimal prevAmt = Decimal.valueOf(System.Label.Leasing_Escalation_Check_Amount);
                
                for (HEAD_OF_TERMS__c hot: hotList) {
                    Map<Date,billResponseWrapper> pMap = new Map<Date,billResponseWrapper>();
                    billSchList = new List<Billing_Schedule__c>();
                    lastButOneMonthRent = 0;
                    lastButOneMonth = false;
                    leaseExpired = false;
                    termEndMonth = false;
                    escalation  = false;
                    lastMonthRent  =0;
                    if(hotBillSchList.containsKey(hot.Id)){
                        billSchList = hotBillSchList.get(hot.Id);
                    }
                    for(Integer y: yearList) {
                        
                        for(Date d : yearMonthMap.get(y)){
                            termEndMonth = false;
                            leaseExpired = false;
                            escalation = false;
                            lastButOneMonth = false;
                            Date batchRunDate =  d;
                            
                            Date nextDate = batchRunDate;
                            Integer nextMonth = nextDate.Month();
                            Integer nextYear = nextDate.Year();
                            
                            Date startOfNextMonth = nextDate.toStartOfMonth();
                            Integer numberDays = date.daysInMonth(startOfNextMonth.year(), startOfNextMonth.month());
                            
                            Date endOfMonth = startOfNextMonth.addDays(numberDays - 1);
                            Date billStart = startOfNextMonth;
                            Date billEnd = endOfMonth;                           
                            
                            // generally the billable days are till end of the month
                            // On the last month of licensing if the client is moving out
                            // during the middle of the month, then the bill end date should be
                            // set as that date
                            Date lastDate = hot.Licence_End_Date__c; 
                            if(d.month() == lastDate.month() && d.year()==lastDate.year()) {
                                termEndMonth = true;
                            }
                            if(d.month() == lastDate.addMonths(-1).month() && d.year()==lastDate.year()) {
                                lastButOneMonth = true;
                            }
                            
                            if(d > lastDate) {
                                leaseExpired = true;
                            }
                            if (lastDate < billEnd) {
                                billEnd = lastDate;
                            }
                            
                            //  num of days int he billable month
                            // numberDays = billStart.Daysbetween(billEnd) + 1;
                            
                            Boolean overLapFlag = false;
                            
                            //ESCALATION LOGIC
                            // compare the escalation windows to the billing window
                            // for ex: 01st Aug - 31st Aug is the billable dates
                            // escalations are - 01-15th Aug - 0 Rent [Rent Free]
                            // 16th Aug - 20th Aug - 100 Rs/Sq.ft
                            // 21-31st Aug - 110 Rs /Sq.Ft 
                            // which makes the rent - 0*15 + 5*100 + 11*110
                            // arrive at the final rent by iterating the billing schedule against the 
                            // bill start and end dates
                            Decimal RentAmount = 0;
                            Decimal FinalRent = 0;
                            Date rentFreestartDate;
                            Date rentFreeEndDate;
                            
                            String chargeType = '';
                            String RecordIdType = '';
                            
                            String calulationMsg = 'Calculated as:';
                            
                            // if billing schedule is empty log an error
                            if (billSchList != null && billSchList.size() > 0) {
                                
                                for (Billing_schedule__C billSch: billSchList) {
                                    chargeType = billSch.Charges_Type__c;
                                    RecordIdType = '';
                                    
                                    List < Date > startDates = new List < Date > ();
                                    startDates.add(billSch.Start_Date__c);
                                    startDates.add(billStart);
                                    startDates.sort();
                                    Date MaxStartDate = startDates[(startDates.size() - 1)];
                                    
                                    List < Date > endDates = new List < Date > ();
                                    endDates.add(billSch.End_Date__C);
                                    endDates.add(billEnd);
                                    endDates.sort();
                                    Date MinEndDate = endDates[0];
                                    
                                    Integer overlapDays = MaxStartDate.daysBetween(MinEndDate) + 1;
                                    
                                    if (overlapDays > 0) {
                                        overLapFlag = true;
                                        rentAmount += billSch.Amount__c * overlapDays;
                                        calulationMsg += '(' + billSch.Amount__c + '*' + overlapDays + ')';
                                        
                                    }
                                    if (billSch.Amount__c == 0) {
                                        // its a rent free duration range
                                        rentFreestartDate = billSch.Start_Date__c;
                                        rentFreeEndDate = billSch.End_Date__C;
                                    }
                                }
                                
                                
                            } 
                            if (rentAmount > 0) {
                                FinalRent = rentAmount / numberDays;
                                calulationMsg += '/'  + numberDays;
                            }      
                            if(termEndMonth)
                                lastMonthRent = FinalRent;     
                            if(lastButOneMonth){
                                lastButOneMonthRent = FinalRent;   
                            }
                            if(FinalRent > prevAmt) {
                                escalation = true;
                            }
                            prevAmt = FinalRent;
                            // if lease has expired, continue at previous rate
                            // using the lastFullMonth rent value for projections beyond term end
                            if(leaseExpired)
                                pMap.put(d,new billResponseWrapper(lastButOneMonthRent,termEndMonth,leaseExpired, escalation));
                            else
                                pMap.put(d,new billResponseWrapper(FinalRent, termEndMonth, leaseExpired, escalation));
                        }
                    }
                    hotpMap.put(hot.Id,pMap);
                }
            }
        } catch (Exception e) {
            appLogObject.add(BillingServices.createLog(BillingServices.getClassName(),
                                                        BillingServices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            system.debug('exception message:' + e.getMessage());
        } finally {
            if (!appLogObject.isEmpty()) {
                try{
                    insert appLogObject;
                }catch (Exception e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                } 
            }
        }
        return hotpMap;
    }        
    
    //method to generate monthly car park bill(fixed bill) 
    public static Map < Id, Map < date, billResponseWrapper >> generateMonthlyCarParkBill(Set < Id > optyIdSetBatch, List < Integer > yearList, Map < Integer, List < Date >> yearMonthMap) {
        //Intialize variables
        optyMap = new Map < Id, List < Opportunity >> ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > ();
        Set<Id> hotIdSet = new set < Id > ();
        List<HEAD_OF_TERMS__c> hotList = new List < HEAD_OF_TERMS__c > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        List<Billing_Schedule__c> billSchList = new List < Billing_Schedule__c > ();
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        Map < Id, Map < Date, billResponseWrapper >> hotpMap = new Map < Id, Map < Date, billResponseWrapper >> ();
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c,             Per_carpark_charge__c,
                   Number_of_chargeable_carparks__c, Building__c, Building__r.Name, Licence_End_Date__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true
                   and Licence_End_Date__c!= null
                  ];
        
        //Fetch Query for Charge Types
        chargesTypeList = [Select Id, Name, Charge_Type__c, Type_of_billing__c
                           From Charges_Type__c
                           Where Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED and Name =: ElbConstantsClass.CHARGE_TYPES_CAR_PARK
                          ];
        
        try {
            if (!hotList.isEmpty()) {
                for (HEAD_OF_TERMS__c hot: hotList) {
                    //valid Leasing check OR Rent Free Period check
                    if (hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_ACTIVE ||
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_FREE ||
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_NA) {
                            
                            hotIdSet.add(hot.Id);
                        }
                }
                Decimal monthlyComp = 0;
                
                //Check if Billing Schedule for charge type as Car Park is Present
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.Name, Charges_Type__c, Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPE_CAR_PARK
                              ];
                Map < Id, List < Billing_Schedule__c > > hotBillSchList = new Map < Id, List < Billing_Schedule__c >> ();
                for (Billing_Schedule__c b: billSchList) {
                    if (hotBillSchList.containsKey(b.HEAD_OF_TERMS__r.Id)) {
                        hotBillSchList.get(b.HEAD_OF_TERMS__r.Id).add(b);
                    } else {
                        List < Billing_Schedule__c > tempList = new List < Billing_Schedule__c > ();
                        tempList.add(b);
                        hotBillSchList.put(b.HEAD_OF_TERMS__r.Id, tempList);
                    }
                }
                Boolean termEndMonth = false;
                Boolean leaseExpired = false;
                Boolean escalation = false;
                Decimal lastMonthRent = 0;
                Decimal lastButOneMonthRent = 0;
                Boolean lastButOneMonth = false;
                
                for (HEAD_OF_TERMS__c hot: hotList) {
                    Map < Date, billResponseWrapper > pMap = new Map < Date, billResponseWrapper > ();
                    billSchList = new List < Billing_Schedule__c > ();
                    lastButOneMonthRent = 0;
                    lastButOneMonth = false;
                    leaseExpired = false;
                    termEndMonth = false;
                    escalation = false;
                    lastMonthRent = 0;
                    if (hotBillSchList.containsKey(hot.Id)) {
                        billSchList = hotBillSchList.get(hot.Id);
                    }
                    if(billSchList != null && !billSchList.isEmpty()) {
                        for (Integer y: yearList) {
                            
                            for (Date d: yearMonthMap.get(y)) {
                                termEndMonth = false;
                                leaseExpired = false;
                                escalation = false;
                                lastButOneMonth = false;
                                Date batchRunDate = d;
                                
                                Date nextDate = batchRunDate;
                                Integer nextMonth = nextDate.Month();
                                Integer nextYear = nextDate.Year();
                                
                                Date licenseEndDate = hot.Licence_End_Date__c;
                                
                                Date startOfNextMonth = nextDate.toStartOfMonth();
                                // total days in that month
                                Integer numberDays = date.daysInMonth(nextYear, nextMonth);
                                
                                Date endOfMonth = startOfNextMonth.addDays(numberDays - 1);
                                
                                Date billStart = startOfNextMonth;
                                Date billEnd = endOfMonth;
                                Date lastDate = hot.Licence_End_Date__c; 
                                if(d.month() == lastDate.month() && d.year()==lastDate.year()) {
                                    termEndMonth = true;
                                }
                                if(d.month() == lastDate.addMonths(-1).month() && d.year()==lastDate.year()) {
                                    lastButOneMonth = true;
                                }
                                
                                if(d > lastDate) {
                                    leaseExpired = true;
                                }
                                if (lastDate < billEnd) {
                                    billEnd = lastDate;
                                }
                                if (licenseEndDate <= billEnd && !leaseExpired) {
                                    Integer totalBillableDays = Math.abs(licenseEndDate.daysBetween(startOfNextMonth)) + 1;
                                    billEnd = licenseEndDate;
                                    // per day car park charge * total chargeable car parks * total billable days in that month
                                    monthlyComp = (hot.Per_carpark_charge__c / numberDays) * hot.Number_of_chargeable_carparks__c * totalBillableDays;
                                } else {
                                    monthlyComp = hot.Per_carpark_charge__c * hot.Number_of_chargeable_carparks__c;
                                }
                                pMap.put(d,new billResponseWrapper(monthlyComp,termEndMonth,leaseExpired, escalation));
                            }// month loop
                        } // year loop
                    } // bill sched exists for carpark check
                    hotpMap.put(hot.Id,pMap);
                } // hot loop
                
            } // if condition
        } // try closure
        catch (Exception e) {
            appLogObject.add(BillingServices.createLog(BillingServices.getClassName(),
                                                        BillingServices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            
        } finally {
            if (!appLogObject.isEmpty()) {
                insert appLogObject;
            }
        }
        return hotpMap;
    }
    
    //Generate CAM Projections
    public static Map<Id,Map<date,billResponseWrapper>> generateCAMProjection(Set<Id> optyIdSetBatch, List<Integer> yearList,Map < Integer, List < Date >> yearMonthMap) {
        optyMap = new Map < Id, List < Opportunity >> ();
        List<HEAD_OF_TERMS__c> hotList = new List < HEAD_OF_TERMS__c > ();
        set<Id> hotIdSet = new set< Id > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        List<Billing_Schedule__c> billSchList = new List < Billing_Schedule__c > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > (); 
        SurveyWrapper countLog = new SurveyWrapper();        
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        Map<Id, Map<Date,billResponseWrapper>> hotpMap = new Map<Id, Map<Date,billResponseWrapper>>();
        Map < String, Map < Integer, List<Plan_Line_Items_CAM__mdt>>> camMetaDataMap = new Map < String, Map < Integer, List<Plan_Line_Items_CAM__mdt>>> ();                                                                         
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        // select all the assets
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Licence_commencement_date__c, License_fees_Commencement_date__c,
                   Licence_End_Date__c, Net_usable_area_Area_Sq_ft__c, Building__r.Building_Code__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Licence_End_Date__c!= null];
        
        try{
            if (!hotList.isEmpty()) {
                for (HEAD_OF_TERMS__c hot: hotList) {
                    //valid Leasing check OR Rent Free Period check
                    if (hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_ACTIVE || 
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_FREE ||
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_NA) {
                            hotIdSet.add(hot.Id);
                        }
                }
                //Check if Billing Schedule for charge type as CAM Charge is Present
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.id,HEAD_OF_TERMS__r.Name, Charges_Type__c, 
                               Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPE_CAM1
                              ];
                Map<Id, List<Billing_Schedule__c> > hotBillSchList = new Map<Id, List<Billing_Schedule__c>>();
                for(Billing_Schedule__c b : billSchList){
                    if(hotBillSchList.containsKey(b.HEAD_OF_TERMS__r.Id)) {
                        hotBillSchList.get(b.HEAD_OF_TERMS__r.Id).add(b);
                    } else {
                        List<Billing_Schedule__c> tempList = new List<Billing_Schedule__c>();
                        tempList.add(b);
                        hotBillSchList.put(b.HEAD_OF_TERMS__r.Id, tempList);
                        
                    }
                }
                
                String checkStr = '';
                
                List<Plan_Line_Items_CAM__mdt> camMetaDataList = Plan_Line_Items_CAM__mdt.getall().values();
                
                if (camMetaDataList != null && !camMetaDataList.isEmpty()) {
                    for (Plan_Line_Items_CAM__mdt camMD: camMetaDataList) {
                        Integer year = camMD.Charge_Date__c.Year();
                        Integer month = camMD.Charge_Date__c.Month();
                        
                        String yearStr = String.valueOf(year);
                        checkStr = yearStr + '-' + camMD.Building__c;
                        
                        if(!camMetaDataMap.containsKey(checkStr)){
                            List<Plan_Line_Items_CAM__mdt> newList = new List<Plan_Line_Items_CAM__mdt>();
                            newList.add(camMD);
                            Map<Integer,List<Plan_Line_Items_CAM__mdt>> newMap= new Map<Integer,List<Plan_Line_Items_CAM__mdt>>();
                            newMap.put(month, newList);
                            camMetaDataMap.put(checkStr, newMap);
                        } else {
                            Map<Integer,List<Plan_Line_Items_CAM__mdt>> getNewMap = new Map<Integer,List<Plan_Line_Items_CAM__mdt>>();
                            getNewMap = camMetaDataMap.get(checkStr);
                            if(!getNewMap.containsKey(month)) {
                                List<Plan_Line_Items_CAM__mdt> newList = new List<Plan_Line_Items_CAM__mdt>();
                                newList.add(camMD);
                                getNewMap.put(month, newList);
                            } else {
                                getNewMap.get(month).add(camMD);
                            }
                            camMetaDataMap.get(checkStr).putAll(getNewMap);
                        }
                    }
                }
                
                system.debug('Metadat Map: ' + camMetaDataMap);
                
                Boolean termEndMonth = false;
                Boolean leaseExpired = false;
                Boolean escalation = false;
                Decimal prevAmt = Decimal.valueOf(System.Label.Leasing_Escalation_Check_Amount);
                
                for (HEAD_OF_TERMS__c hot: hotList) {
                    Map<Date,billResponseWrapper> pMap = new Map<Date,billResponseWrapper>();
                    billSchList = new List<Billing_Schedule__c>();
                    leaseExpired = false;
                    termEndMonth = false;
                    escalation  = false;
                    Integer Rent = 0;
                    
                    if(hotBillSchList.containsKey(hot.Id)){
                        billSchList = hotBillSchList.get(hot.Id);
                    }
                    
                    if(billSchList != null && !billSchList.isEmpty()){
                        for(Integer y: yearList) {
                            
                            for(Date d : yearMonthMap.get(y)){
                                
                                termEndMonth = false;
                                leaseExpired = false;
                                escalation = false;
                                Date batchRunDate = d;
                                
                                Date nextDate = batchRunDate;
                                Integer nextMonth = nextDate.Month();
                                Integer nextYear = nextDate.Year();
                                
                                String yearStr = String.valueOf(nextYear);
                                checkStr = yearStr + '-' + hot.Building__r.Building_Code__c;
                                
                                Date licenseEndDate = hot.Licence_End_Date__c;
                                
                                Date startOfNextMonth = nextDate.toStartOfMonth();
                                // total days in that month
                                Integer numberDays = date.daysInMonth(nextYear, nextMonth);
                                
                                Date endOfMonth = startOfNextMonth.addDays(numberDays - 1);
                                
                                Date billStart = startOfNextMonth;
                                Date billEnd = endOfMonth;
                                Date lastDate = hot.Licence_End_Date__c; 
                                if(d.month() == lastDate.month() && d.year()==lastDate.year()) {
                                    termEndMonth = true;
                                }
                                
                                if(d > lastDate) {
                                    leaseExpired = true;
                                }
                                
                                // licenseEndDate <= billEnd && 
                                if (!leaseExpired) {
                                    if(camMetaDataMap != null && !camMetaDataMap.isEmpty()){
                                        
                                        
                                        if(camMetaDataMap.get(checkStr).get(nextMonth) != null){
                                            for(Plan_Line_Items_CAM__mdt camData : camMetaDataMap.get(checkStr).get(nextMonth)){
                                                if(batchRunDate == camData.Charge_Date__c) {
                                                    Rent = Integer.valueOf(hot.Net_usable_area_Area_Sq_ft__c * camData.Amount__c);
                                                    if(Rent > prevAmt) {
                                                        escalation = true;
                                                    }
                                                    prevAmt = Rent;
                                                    pMap.put(d,new billResponseWrapper(Rent, termEndMonth, leaseExpired, escalation));
                                                }
                                            }
                                        }
                                        else{
                                            pMap.put(d,new billResponseWrapper(0 ,termEndMonth,leaseExpired, escalation));
                                        }
                                    }
                                } else {
                                    leaseExpired = true;
                                    pMap.put(d,new billResponseWrapper(0 ,termEndMonth,leaseExpired, escalation));
                                } 
                            }// month loop end
                        } // year loop end
                    }
                    hotpMap.put(hot.Id,pMap);
                }
            }
        } catch (Exception e) {
            appLogObject.add(BillingServices.createLog(BillingServices.getClassName(),
                                                        BillingServices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            system.debug('exception message:' + e.getMessage());
        } finally {
            if (!appLogObject.isEmpty()) {
                try{
                    insert appLogObject;
                }catch (Exception e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                } 
            }
        }
        return hotpMap;
    }
    
    public Class planItemWrapper {
        Public Plan_Line_Items__c pl{get; set;}
        public Floor__c asset {get;set;}
        
        Public Boolean leased {get;set;}
        Public String status {get;set;}
        Public String tenant {get;set;}
        public String licenceStart {get;set;}
        public String licenceEnd {get;set;}
        public Decimal NUA {get;set;}
        
        Public PlanItemWrapper(Plan_Line_Items__c pi, Floor__c asset, Boolean status, String s, String t, String ls, String ld, Decimal NUA){
            pl=new Plan_Line_Items__c ();
            leased = false;
            this.pl= pi;
            this.leased = status;
            this.status = s;
            this.tenant = t;
            this.licenceStart = ls;
            this.licenceEnd  = ld;
            this.asset = asset;
            this.NUA = NUA;
            
        }
    }
    public class SurveyWrapper{ 
        public Application_Log__c surveyBilling {get;set;}
        public SurveyWrapper surveyWrapperItem {get;set;}
        public List<SurveyWrapper> surveyWrapperList {get;set;}
        public Set<Id> hotIdSet {get;set;}
        public integer responseCount {get;set;}
        public Integer responsePositiveCount{get;set;}
        public Integer responseNegativeCount{get;set;}
        
        public SurveyWrapper(){
            surveyBilling = new Application_Log__c();
            responseCount = 0;
            responsePositiveCount = 0;
            responseNegativeCount = 0;
        }
        
        public SurveyWrapper(SurveyWrapper surveyWrapperItem){
            this.surveyWrapperItem = surveyWrapperItem;
        }
    }
    public  class billResponseWrapper {
        public Decimal billAmount {get;set;}
        public boolean termEnd {get;set;}
        public boolean leaseExpired {get;set;}
        public boolean escalation {get;set;}
        public billResponseWrapper(){
            
        }
        public billResponseWrapper(Decimal amt, boolean tEnd, boolean lexp, boolean esc){
            this.billAmount = amt;
            this.termEnd = tEnd;
            this.leaseExpired= lExp;
            this.escalation = esc;
        }
    }
}