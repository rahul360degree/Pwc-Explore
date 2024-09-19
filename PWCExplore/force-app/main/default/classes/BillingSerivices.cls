/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for generation of different types of bill over head of terms
Inputs:        NA
Last Modified: 03/02/2022
Test Class:    
----------------------------------------------------------------------------*/

public class BillingSerivices {
    
    public Map < Id, List < Opportunity >> optyMap {get;set;}
    public List < Charges_Type__c > chargesTypeList {get;set;}
    //public Map < Id, List < Charges_Type__c >> chargeTypeMap {get;set;} 
    public Map < Id,  Charges_Type__c> chargeTypeMap {get;set;} 
    public List < HEAD_OF_TERMS__c > hotList {get;set;}
    public set < Id > hotIdSet {get;set;}
    public Map < Id, List < HEAD_OF_TERMS__c >> optyHotMap {get;set;}
    public List < Billing_Schedule__c > billSchList {get;set;}
    
    //fetch class name for Application log
    public static String getClassName(String line) {
        if (line.startsWith('Class.'))
            line = line.substringAfter('Class.');
        return line.substringBefore(':').substringBeforeLast('.');
    }
    
    //fetch method name for Application log
    public static String getMethod(String line) {
        return line.substringBefore(':').substringAfterLast('.');
    }
    
    //fetch class name for Application log
    public static String getClassName() {
        return getClassName(new DmlException().getStackTraceString().substringAfter('\n'));
    }
    
    //fetch method name for Application log
    public static String getMethod() {
        return getMethod(new DmlException().getStackTraceString().substringAfter('\n'));
    }
    
    //Create Application log Record
    public static Application_Log__c createLog(String sourceClassName, String sourceMethodName, String referenceId, String errorMessage) {
        Application_Log__c logRecord = new Application_Log__c();
        
        if (errorMessage.substring(0, 1) == ElbConstantsClass.LOG_SUCCESS_MESSAGE_SHORT) {
            logRecord.Type__c = ElbConstantsClass.LOG_SUCCESS_MESSAGE;
        } else {
            logRecord.Type__c = GlobalConstants.LOG_TYPE.ERROR.name();
        }
        logRecord.Category__c = ElbConstantsClass.LOG_CATEGORY;
        logRecord.Source_Apex_Class__c = sourceClassName;
        logRecord.Source_Function__c = sourceMethodName;
        logRecord.Message__c = errorMessage;
        logRecord.Record_ID__c = referenceId;
        logRecord.User__c = UserInfo.getUserId();
        
        return logRecord;
    }
    
    //Fetch Record Types Method
    public map < String, Id > fetchRecordTypes(String ObjApiName) {
        map < String, Id > rtMap = new map < String, Id > ();
        
        for (RecordType rt: [select Id, Name, DeveloperName from RecordType where sObjectType =: ObjApiName]) {
            rtMap.put(rt.Name, rt.Id);
        }
        return rtMap;
    }
    
    //Calculation for Error or Success log for Application Log Record
    public static SurveyWrapper getListOfSuccessAndErrors ( List<Application_Log__c> surveyList , Set<Id> hotIdSet){
        Integer postiveResponse = 0;
        Integer negativeResponse = 0;
        
        for(Application_Log__c e: surveyList) {
            list<Application_Log__c> lstSurveyData = new list<Application_Log__c>();
            string key = e.Type__c ;
            if(key == ElbConstantsClass.LOG_TYPE){
                postiveResponse += 1;
            }
            if (key == ElbConstantsClass.LOG_ERROR_MESSAGE) {
                negativeResponse += 1;
            }			
        }
        
        //create a new wrapper object and addiing the values to the wrapper class
        SurveyWrapper wrapperObj = new SurveyWrapper();
        wrapperObj.hotIdSet = hotIdSet;
        wrapperObj.responseCount = surveyList.size();
        wrapperObj.responsePositiveCount = postiveResponse;
        wrapperObj.responseNegativeCount =  negativeResponse;
        return wrapperObj;
    }
    
    //Generate Bills according to the specific requirememnts
    public List<SurveyWrapper> generateBills(List<HEAD_OF_TERMS__c> hotList) {
        Set<Id> hotIdSet = new Set<Id>();
        Set<Id> oppBillMonthlyFixedIdSet = new Set<Id>();
        Set<Id> oppBillMonthlyHousingFixedIdSet = new Set<Id>();
        Set<Id> oppBillMonthlyCarParkIdSet = new Set<Id>();
        Set<Id> oppBillMonthlyVariableIdSet = new Set<Id>();
        Set<Id> oppBillQuarterlyIdSet = new Set<Id>();
        Set<Id> oppBillYearlyIdSet = new Set<Id>();
        List<Billing_Schedule__c> billSchMonthlyFixedList = new List<Billing_Schedule__c>();
        List<Billing_Schedule__c> billSchMonthlyHousingFixedList = new List<Billing_Schedule__c>();
        List<Billing_Schedule__c> billSchMonthlyCarParkList = new List<Billing_Schedule__c>();
        List<Billing_Schedule__c> billSchMonthlyVariableList = new List<Billing_Schedule__c>();
        List<Billing_Schedule__c> billSchQuaterlyList = new List<Billing_Schedule__c>();
        List<Billing_Schedule__c> billSchYearlyList = new List<Billing_Schedule__c>(); 
        Map<Id, Billing_Schedule__c> billSchQuaterlyMap = new Map<Id, Billing_Schedule__c>();
        Map<Id, Billing_Schedule__c> billSchYearlyMap = new Map<Id, Billing_Schedule__c>();
        Date lastBillingQuaterDate;
        Date lastBillingYearDate;       
        Date todayDate = system.today(); //Date.newInstance(2021, 12, 14); //system.today(); //Date.newInstance(2019, 11, 12);
        Integer todayDay = todayDate.day();
        Integer todayMonth = todayDate.Month();
        Integer todayYear = todayDate.Year();
        
        List<SurveyWrapper> wrapObject = new List<SurveyWrapper>();
        
        for(HEAD_OF_TERMS__c hot: hotList){
            hotIdSet.add(hot.Id);
        }
        
        billSchMonthlyFixedList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, 
                                   To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                                   from Billing_Schedule__c 
                                   where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE and
                                   Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED];
        
        billSchMonthlyHousingFixedList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, 
                                          To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                                          from Billing_Schedule__c 
                                          where HEAD_OF_TERMS__c IN: hotIdSet /*and (Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_HOUSING or
                                                                                   Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL) */
                                          and Charges_Type__r.Charge_Type__c IN (:ElbConstantsClass.CHARGE_TYPES_HOUSING, :ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL) //Added for Residential
                                          and Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED];
        
        
        billSchMonthlyCarParkList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, 
                                     To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                                     from Billing_Schedule__c 
                                     where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPE_CAR_PARK and
                                     Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED];
        
        billSchMonthlyVariableList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, 
                                      To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                                      from Billing_Schedule__c 
                                      where HEAD_OF_TERMS__c IN: hotIdSet and
                                      Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_VARIABLE];
        
        billSchQuaterlyList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, Start_Date__c,
                               End_Date__c, To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                               from Billing_Schedule__c 
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE and
                               Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_QUARTERLY_FIXED];
        
        billSchYearlyList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Charge_Type__c, Charges_Type__r.Type_of_billing__c, Start_Date__c,
                             End_Date__c, To_be_billed_on__c, HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                             from Billing_Schedule__c 
                             where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE and
                             Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_YEARLY_FIXED];
        
        //generate monthly bills for Monthly Fixed License Fee on specific date
        if(!billSchMonthlyFixedList.isEmpty()){
            for(Billing_Schedule__c billSchM: billSchMonthlyFixedList){
                if(todayDate.addMonths(1) < billSchM.HEAD_OF_TERMS__r.Licence_End_Date__c){
                    oppBillMonthlyFixedIdSet.add(billSchM.HEAD_OF_TERMS__r.Opportunity__c);
                }
            }
            
            if(todayDay == Integer.valueOf(System.Label.Billing_Date)){
                wrapObject.add(genreateMonthlyLicenseFeeBill(oppBillMonthlyFixedIdSet));
            }
        }
        
        //generate monthly bills for Monthly Housing bill on specific date
        if(!billSchMonthlyHousingFixedList.isEmpty()){
            for(Billing_Schedule__c billSchMH: billSchMonthlyHousingFixedList){
                if(todayDate.addMonths(1) < billSchMH.HEAD_OF_TERMS__r.Licence_End_Date__c){
                    oppBillMonthlyHousingFixedIdSet.add(billSchMH.HEAD_OF_TERMS__r.Opportunity__c);
                }
            }
            
            if(todayDay == Integer.valueOf(System.Label.Billing_Housing_Date)){
                wrapObject.add(generateMonthlyHousingBill(oppBillMonthlyHousingFixedIdSet));
            }
        }
        
        //generate monthly bills for Monthly Fixed Car Park on specific date
        if(!billSchMonthlyCarParkList.isEmpty()){
            for(Billing_Schedule__c billSchMCP: billSchMonthlyCarParkList){
                if(todayDate.addMonths(1) < billSchMCP.HEAD_OF_TERMS__r.Licence_End_Date__c){
                    oppBillMonthlyCarParkIdSet.add(billSchMCP.HEAD_OF_TERMS__r.Opportunity__c);
                }
            }
            
            if(todayDay == Integer.valueOf(System.Label.Billing_Date)){
                wrapObject.add(genreateMonthlyCarParkBill(oppBillMonthlyCarParkIdSet));
            }
        }
        
        //generate monthly wrapper bills for Monthly Variable on specific date
        if(!billSchMonthlyVariableList.isEmpty()){
            for(Billing_Schedule__c billSchMV: billSchMonthlyVariableList){
                oppBillMonthlyVariableIdSet.add(billSchMV.HEAD_OF_TERMS__r.Opportunity__c);
            }
            
            if(todayDay == Integer.valueOf(System.Label.Billing_Date)){
                wrapObject.add(generateMonthlyVariableBill(oppBillMonthlyVariableIdSet));
            }
        }
        
        //generate quaterly Fixed bills
        if(!billSchQuaterlyList.isEmpty()){
            for(Billing_Schedule__c billSchQ: billSchQuaterlyList){
                
                if (billSchQuaterlyMap.containsKey(billSchQ.Id)) {
                    Billing_Schedule__c newRecord = billSchQuaterlyMap.get(billSchQ.Id);
                    billSchQuaterlyMap.put(billSchQ.Id, newRecord);
                } else {
                    Billing_Schedule__c tempRecord = new Billing_Schedule__c ();
                    billSchQuaterlyMap.put(billSchQ.Id, tempRecord);
                }
                
                if(billSchQ.To_be_billed_on__c == null){
                    lastBillingQuaterDate = billSchQ.Start_Date__c;                   
                } else {
                    lastBillingQuaterDate = billSchQ.To_be_billed_on__c;
                    //lastBillingQuaterDate = lastBillingQuaterDate.addDays(1);
                }
                
                Date biliingQuarterDate;
                    
                if(lastBillingQuaterDate.day() == 31) {
                    biliingQuarterDate = lastBillingQuaterDate.addDays(-21);
                } else if(lastBillingQuaterDate.day() == 30) {
                    biliingQuarterDate = lastBillingQuaterDate.addDays(-20);
                } else if(lastBillingQuaterDate.day() == 29) {
                    biliingQuarterDate = lastBillingQuaterDate.addDays(-19);
                } else if(lastBillingQuaterDate.day() == 28) {
                    biliingQuarterDate = lastBillingQuaterDate.addDays(-18);
                }
                
                if(todayDate == biliingQuarterDate){
                    oppBillQuarterlyIdSet.add(billSchQ.HEAD_OF_TERMS__r.Opportunity__c);  
                }
            }
            wrapObject.add(genreateQuarterlyLicenseFeeBill(oppBillQuarterlyIdSet));
        }
        
        //generate yearly Fixed bills
        if(!billSchYearlyList.isEmpty()){
            for(Billing_Schedule__c billSchY: billSchYearlyList){                
                if (billSchYearlyMap.containsKey(billSchY.Id)) {
                    Billing_Schedule__c newRecord = billSchYearlyMap.get(billSchY.Id);
                    billSchYearlyMap.put(billSchY.Id, newRecord);
                } else {
                    Billing_Schedule__c tempRecord = new Billing_Schedule__c ();
                    billSchYearlyMap.put(billSchY.Id, tempRecord);
                }
                
                if(billSchY.To_be_billed_on__c == null){
                    lastBillingYearDate = billSchY.Start_Date__c;                   
                } else {
                    lastBillingYearDate = billSchY.To_be_billed_on__c;
                    //lastBillingYearDate = lastBillingYearDate.addDays(1);
                }
                
                Date biliingYearDate;
                    
                if(lastBillingYearDate.day() == 31) {
                    biliingYearDate = lastBillingYearDate.addDays(-21);
                } else if(lastBillingYearDate.day() == 30) {
                    biliingYearDate = lastBillingYearDate.addDays(-20);
                } else if(lastBillingYearDate.day() == 29) {
                    biliingYearDate = lastBillingYearDate.addDays(-19);
                } else if(lastBillingYearDate.day() == 28) {
                    biliingYearDate = lastBillingYearDate.addDays(-18);
                }
                
                if(todayDate == biliingYearDate){
                    oppBillYearlyIdSet.add(billSchY.HEAD_OF_TERMS__r.Opportunity__c);  
                }
            }
            wrapObject.add(genreateYearlyLicenseFeeBill(oppBillYearlyIdSet));
        }
        
        return wrapObject;
    }
    
    //Method to generate monthly license fee bill
    public SurveyWrapper genreateMonthlyLicenseFeeBill(Set<Id> optyIdSetBatch) {
        optyMap = new Map < Id, List < Opportunity >> ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        hotIdSet = new set< Id > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > (); 
        SurveyWrapper countLog = new SurveyWrapper();        
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Licence_commencement_date__c, License_fees_Commencement_date__c,
                   Licence_End_Date__c, Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true];
        
        //Fetch Query for Charge Types
        chargesTypeList = [Select Id, Name, Charge_Type__c, Type_of_billing__c
                           From Charges_Type__c
                           Where Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED and Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE];
        
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
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Name =: ElbConstantsClass.CHARGE_TYPE_LICENSE_FEE_MONTHLY
                              ];
                
                for (HEAD_OF_TERMS__c hot: hotList) {
                    
                    List < Billing__c > fixedBillingObject = new List < Billing__c > ();
                    Billing__c fixedBillingLineItem = new Billing__c();
                    // the batch runs on 25th of every month to 
                    // generate bills for the upcoming month
                    // 25th July generates bills for 01 Aug - 31st Aug
                    Date batchRunDate = system.today();
                    Date nextDate = batchRunDate.addMonths(1);
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
                    if (lastDate < billEnd) {
                        billEnd = lastDate;
                    }
                    
                    //  num of days in the billable month
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
                    Decimal rentAmount = 0;
                    Decimal FinalRent = 0;
                    Date rentFreestartDate;
                    Date rentFreeEndDate;
                    
                    String chargeType = '';
                    String RecordIdType = '';
                    
                    String calulationMsg = 'Calculated as:';
                    
                    //Map<Id, Decimal> rentMap = new Map<Id, Decimal>(); 
                                
                    // if billing schedule is empty log an error
                    if (billSchList != null && billSchList.size() > 0) {
                        
                        for (Billing_schedule__C billSch: billSchList) {
                            if(hot.Id == billSch.HEAD_OF_TERMS__c){
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
                                
                                //rentMap.put(hot.Id, rentAmount);                                
                            } 
                        }
                            FinalRent = rentAmount / numberDays;
                            calulationMsg += '/'  + numberDays;                     
                    }
                    // get the rent free dates, for logging the chargeable and free period for reference
                    List < Date > startDates = new List < Date > ();
                    startDates.add(rentFreestartDate);
                    startDates.add(billStart);
                    startDates.sort();
                    Date MaxStartDate;
                    if (!startDates.isEmpty()) {
                        MaxStartDate = startDates[(startDates.size() - 1)];
                    }
                    
                    
                    List < Date > endDates = new List < Date > ();
                    endDates.add(rentFreeEndDate);
                    endDates.add(billEnd);
                    endDates.sort();
                    Date MinEndDate;
                    if (!endDates.isEmpty()) {
                        MinEndDate = endDates[0];
                    }
                    Integer RentFreePeriod = 0;
                    Boolean twoRanges = false;
                    if(MinEndDate != null){
                        RentFreePeriod = MaxStartDate.daysBetween(MinEndDate) + 1;
                    }
                    
                    Integer ChargeableDays = 0;
                    // Now get the window of rent free dates.
                    // For the message for narration
                    String rentFreeChargeableMsg = '';
                    String message = 'This is being generated on ' + batchRunDate.format() + ' for ' + billStart.format() + ' - ' + billEnd.format() + '.'; 
                    if (RentFreePeriod <= 0) {
                        ChargeableDays = billStart.daysBetween(billEnd) + 1;
                        rentFreeChargeableMsg = 'No rent free duration during this billable period.\n\n' + ChargeableDays + ' days are chargeable';
                    } else {
                        ChargeableDays = billStart.daysBetween(billEnd) + 1 - rentFreePeriod;
                        if (billStart.Daysbetween(rentFreestartDate) > 0) {
                            Date Range1Start = billStart;
                            Date Range1End = rentFreeStartDate.addDays(-1);
                            rentFreeChargeableMsg = 'Rent free period 1:' + Range1Start.format() + '-' + Range1End.format() + ':';
                        }
                        
                        if (rentFreeEndDate.Daysbetween(billEnd) > 0) {
                            Date Range2Start = rentFreeEndDate.addDays(1);
                            Date Range2End = billEnd;
                            rentFreeChargeableMsg += 'Rent free period 2:' + Range2Start.format() + '-' + Range2End.format();
                        }
                        rentFreeChargeableMsg += '. \n \n' + ChargeableDays + ' days are chargeable';
                    }
                    //Id LicenseFeeRecordTypeId = Schema.SObjectType.Billing__C.getRecordTypeInfosByName().get(ElbConstantsClass.CHARGE_TYPE_LICENSE_FEE).getRecordTypeId();
                    
                    fixedBillingLineItem.Opportunity__c = hot.Opportunity__c;
                    fixedBillingLineItem.Billing_Start_Date__c = billStart;
                    fixedBillingLineItem.Billing_End_Date__c = billEnd;
                    fixedBillingLineItem.Generation_Date__c = batchRunDate;
                    fixedBillingLineItem.Type_of_billing__c = ElbConstantsClass.TYPE_BILLING_FIXED;
                    fixedBillingLineItem.Amount__c = FinalRent;
                    fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;
                    fixedBillingLineItem.HEAD_OF_TERMS__c = hot.Id;
                    fixedBillingLineItem.Remarks__c = message + '\n \n' + rentFreeChargeableMsg +'\n \n'+ calulationMsg;
                    fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                    fixedBillingLineItem.Charge__c = chargesTypeList[0].Id; 
                    fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.CHARGE_TYPE_LICENSE_FEE);
                    
                    fixedBillingObject.add(fixedBillingLineItem);
                    
                    if (!fixedBillingObject.isEmpty()) {
                        try{
                            insert fixedBillingObject;
                            for(Billing__c bill: fixedBillingObject){
                                appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                            BillingSerivices.getMethod(),
                                                                            bill.Id,
                                                                            ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                            }
                        } catch (Exception e) {
                            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                        BillingSerivices.getMethod(),
                                                                        hot.Opportunity__c,
                                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
                        }
                    } 
                }                
            }
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            
        } finally {
            if (!appLogObject.isEmpty()) {
                try{
                    insert appLogObject;
                } catch(Exception e){
                    system.debug('Error during inserting appLogObject: ' + e.getMessage());
                }
            }
        }
        return getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    //Method to generate quarterly license fee bill
    public SurveyWrapper genreateQuarterlyLicenseFeeBill(Set<Id> optyIdSetBatch) {
        //Intialize variables
        optyMap = new Map < Id, List < Opportunity >> ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        hotIdSet = new set< Id > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > (); 
        SurveyWrapper countLog = new SurveyWrapper();
        
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes('Billing__c');
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Licence_commencement_date__c, License_fees_Commencement_date__c,
                   Licence_End_Date__c , Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where  Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true];
        
        try{
            List < Billing__c > fixedBillingObject = new List < Billing__c > ();//added here
            List<Billing_schedule__c> billSchObject = new List<Billing_schedule__c>();//added here
            if (!hotList.isEmpty()) { 
                for (HEAD_OF_TERMS__c hot: hotList) {
                    //valid Leasing check OR Rent Free Period check
                    if (hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_ACTIVE || 
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_FREE ||
                        hot.Lease_Status__c == ElbConstantsClass.LEASE_STATUS_NA) {   
                            hotIdSet.add(hot.Id);
                        }
                }
                
                //Check if Billing Schedule for charge type as Licsense Fee Quarterly is Present
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Name, Charges_Type__r.Type_of_billing__c,
                               Charges_Type__r.Charge_Type__c ,Start_Date__c, End_Date__c, HEAD_OF_TERMS__r.Opportunity__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c, To_be_billed_on__c, HEAD_OF_TERMS__r.Licence_End_Date__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE 
                               and Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_QUARTERLY_FIXED
                              ];
                
                /*List < Billing__c > fixedBillingObject = new List < Billing__c > ();removed from here and added above*/
                for (HEAD_OF_TERMS__c hot: hotList) {
                    
                    Billing__c fixedBillingLineItem = new Billing__c();
                    // generate bills for the upcoming Quarter
                    Boolean overLapFlag = false;
                    Date batchRunDate;
                    Date billStart;
                    Date billEnd;
                    Date lastDate;
                    Integer numberDays;
                    
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
                    /*List<Billing_schedule__c> billSchObject = new List<Billing_schedule__c>();removed from here and added above*/
                    //Map<Id, Decimal> rentMap = new Map<Id, Decimal>(); 
                    
                    // if billing schedule is empty log an error
                    if (billSchList != null && billSchList.size() > 0) {
                        for (Billing_schedule__c bSch: billSchList) {
                            if(hot.Id == bSch.HEAD_OF_TERMS__c){
                                
                                Billing_schedule__c billScheLineItem = new Billing_schedule__c();
                                batchRunDate = system.today(); //Date.newInstance(2021, 06, 15);
                                if(bSch.To_be_billed_on__c == null){
                                    billStart = bSch.Start_Date__c;
                                }
                                else{
                                    billStart = bSch.To_be_billed_on__c.addDays(1);
                                    //billStart = billStart.addDays(1);//redundant
                                }
                                billEnd = billStart.addMonths(3).addDays(-1);
                                numberDays = (billStart.daysBetween(billEnd))+1;
                                
                                lastDate = bSch.HEAD_OF_TERMS__r.Licence_End_Date__c;
                                
                                if (lastDate < billEnd) {
                                    billEnd = lastDate;
                                }
                                chargeType = bSch.Charges_Type__c;
                                RecordIdType = '';
                                
                                List < Date > startDates = new List < Date > ();
                                startDates.add(bSch.Start_Date__c);
                                startDates.add(billStart);
                                startDates.sort();
                                Date MaxStartDate = startDates[(startDates.size() - 1)];
                                
                                List < Date > endDates = new List < Date > ();
                                endDates.add(bSch.End_Date__C);
                                endDates.add(billEnd);
                                endDates.sort();
                                Date MinEndDate = endDates[0];
                                
                                if(MinEndDate>MaxStartDate){
                                    Integer overlapDays = MaxStartDate.daysBetween(MinEndDate) + 1;
                                    if (overlapDays > 0) {
                                        overLapFlag = true;
                                        rentAmount += bSch.Amount__c * overlapDays;
                                        calulationMsg += '(' + bSch.Amount__c + '*' + overlapDays + ')';
                                    }
                                }
                                if (bSch.Amount__c == 0) {
                                    // its a rent free duration range
                                    rentFreestartDate = bSch.Start_Date__c;
                                    rentFreeEndDate = bSch.End_Date__C;
                                }
                                
                                billScheLineItem.Id = bSch.Id;
                                billScheLineItem.To_be_billed_on__c = billEnd;
                                billSchObject.add(billScheLineItem);
                                
                                //rentMap.put(hot.Id, rentAmount);     
                            }
                        }
                        
                            FinalRent = rentAmount / numberDays;
                            calulationMsg += '/'  + numberDays;
                    }
                    
                    // get the rent free dates, for logging the chargeable and free period for reference
                    Integer RentFreePeriod=0;
                    Integer ChargeableDays = 0;
                    Date MaxStartDate;
                    Date MinEndDate;
                    // get the rent free dates, for logging the chargeable and free period for reference
                    if(rentFreestartDate !=null && rentFreeEndDate !=null){
                        List < Date > startDates = new List < Date > ();
                        startDates.add(rentFreestartDate);
                        startDates.add(billStart);
                        startDates.sort();
                        
                        if (!startDates.isEmpty()) {
                            MaxStartDate = startDates[(startDates.size() - 1)];
                        }
                        
                        
                        List < Date > endDates = new List < Date > ();
                        endDates.add(rentFreeEndDate);
                        endDates.add(billEnd);
                        endDates.sort();
                        
                        if (!endDates.isEmpty()) {
                            MinEndDate = endDates[0];
                        }
                        
                        Boolean twoRanges = false;
                        
                        RentFreePeriod = MaxStartDate.daysBetween(MinEndDate) + 1;
                        ChargeableDays = 0;
                    }
                    // Now get the window of rent free dates.
                    // For the message for narration
                    String rentFreeChargeableMsg = '';
                    String message = 'This is being generated on ' + batchRunDate.format() + ' for ' + billStart.format() + ' - ' + billEnd.format() + '.'; 
                    if (RentFreePeriod <= 0) {
                        ChargeableDays = billStart.daysBetween(billEnd) + 1;
                        rentFreeChargeableMsg = 'No rent free duration during this billable period.\n\n' + ChargeableDays + ' days are chargeable';
                    } else {
                        rentFreeChargeableMsg=rentFreePeriod + ' - days are rent free:' + MaxStartDate.format() + '-to-' + MinEndDate.format();
                        ChargeableDays = billStart.daysBetween(billEnd) + 1 - rentFreePeriod;
                        if (billStart.Daysbetween(rentFreestartDate) > 0) {
                            Date Range1Start = billStart;
                            Date Range1End = rentFreeStartDate.addDays(-1);
                            rentFreeChargeableMsg += 'chargeable  period 1:' + Range1Start.format() + '-' + Range1End.format() + ':';
                        }
                        
                        if (rentFreeEndDate.Daysbetween(billEnd) > 0) {
                            Date Range2Start = rentFreeEndDate.addDays(1);
                            Date Range2End = billEnd;
                            rentFreeChargeableMsg += 'chargeable  period 2:' + Range2Start.format() + '-' + Range2End.format();
                        }
                        rentFreeChargeableMsg += '. \n \n' + ChargeableDays + ' days are chargeable';
                    }
                    
                    fixedBillingLineItem.Opportunity__c = hot.Opportunity__c;
                    fixedBillingLineItem.Billing_Start_Date__c = billStart;
                    fixedBillingLineItem.Billing_End_Date__c = billEnd;
                    fixedBillingLineItem.Generation_Date__c = batchRunDate;
                    fixedBillingLineItem.Type_of_billing__c = ElbConstantsClass.TYPE_BILLING_QUARTERLY_FIXED;
                    fixedBillingLineItem.Amount__c = FinalRent;
                    fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;
                    fixedBillingLineItem.HEAD_OF_TERMS__c = hot.Id;
                    fixedBillingLineItem.Remarks__c = message + '\n \n' + rentFreeChargeableMsg +'\n \n'+ calulationMsg;
                    fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                    fixedBillingLineItem.Charge__c = chargeType;
                    fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.CHARGE_TYPE_LICENSE_FEE);
                    
                    fixedBillingObject.add(fixedBillingLineItem);
                    
                    /*if (!billSchObject.isEmpty()) {
                        try{
                            update billSchObject;
                        } catch (Exception e) {
                            System.debug('The following exception has occurred: ' + e.getMessage());
                        }
                    }
                    
                    if (!fixedBillingObject.isEmpty()) {
                        try{
                            insert fixedBillingObject; 
                            for(Billing__c bill: fixedBillingObject){
                                appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                            BillingSerivices.getMethod(),
                                                                            bill.Id,
                                                                            ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                            }
                        } catch (Exception e) {
                            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                        BillingSerivices.getMethod(),
                                                                        hot.Opportunity__c,
                                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
                        }
                    }*/
                }
            }
           if (!billSchObject.isEmpty()) {
                        try{
                            update billSchObject;
                        } catch (Exception e) {
                            System.debug('The following exception has occurred: ' + e.getMessage());
                        }
                    }
                    
                    if (!fixedBillingObject.isEmpty()) {
                        try{
                            insert fixedBillingObject; 
                            for(Billing__c bill: fixedBillingObject){
                                appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                            BillingSerivices.getMethod(),
                                                                            bill.Id,
                                                                            ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                            }
                        } catch (Exception e) {
                            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                        BillingSerivices.getMethod(),
                                                                        null,//hot.Opportunity__c,
                                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
                        }
                    } 
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            
        } finally {
            if (!appLogObject.isEmpty()) {
                try{
                    insert appLogObject;
                }catch (Exception e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }   
            }
        }
        return BillingSerivices.getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    //Method to generate yearly license fee bill
    public  SurveyWrapper genreateYearlyLicenseFeeBill(Set<Id> optyIdSetBatch) {
        //Intialize variables
        optyMap = new Map < Id, List < Opportunity >> ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        hotIdSet = new set< Id > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > (); 
        SurveyWrapper countLog = new SurveyWrapper();
        
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes('Billing__c');
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Licence_commencement_date__c, License_fees_Commencement_date__c,
                   Licence_End_Date__c, Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where  Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true];
        
        
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
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Name, Charges_Type__r.Type_of_billing__c ,
                               Charges_Type__r.Charge_Type__c ,Start_Date__c, End_Date__c, HEAD_OF_TERMS__r.Opportunity__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c, HEAD_OF_TERMS__r.Licence_End_Date__c, To_be_billed_on__c                              
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE and 
                               Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_YEARLY_FIXED
                              ];
                
                List < Billing__c > fixedBillingObject = new List < Billing__c > ();
                
                for (HEAD_OF_TERMS__c hot: hotList) {     
                    
                    Billing__c fixedBillingLineItem = new Billing__c();
                    Date batchRunDate;
                    Date billStart;
                    Date billEnd;
                    Date lastDate;
                    Integer numberDays;
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
                    
                    List<Billing_schedule__c> billSchObject = new List<Billing_schedule__c>();
                    //Map<Id, Decimal> rentMap = new Map<Id, Decimal>(); 
                    
                    // if billing schedule is empty log an error
                    if (billSchList != null && billSchList.size() > 0) {
                        for (Billing_schedule__C bSch: billSchList) {
                            
                            if(hot.Id == bSch.HEAD_OF_TERMS__c){
                                Billing_schedule__c billScheLineItem = new Billing_schedule__c();
                                batchRunDate = system.today(); //Date.newInstance(2019, 11, 12);
                                if(bSch.To_be_billed_on__c == null){
                                    billStart = bSch.Start_Date__c;
                                }
                                else{
                                    billStart = bSch.To_be_billed_on__c;
                                    billStart = billStart.addDays(1);
                                }
                                billEnd = billStart.addYears(1).addDays(-1);
                                numberDays = (billStart.daysBetween(billEnd))+1;
                                
                                lastDate = bSch.HEAD_OF_TERMS__r.Licence_End_Date__c;
                                
                                if (lastDate < billEnd) {
                                    billEnd = lastDate;
                                }
                                
                                chargeType = bSch.Charges_Type__c;
                                RecordIdType = '';
                                
                                List < Date > startDates = new List < Date > ();
                                startDates.add(bSch.Start_Date__c);
                                startDates.add(billStart);
                                startDates.sort();
                                Date MaxStartDate = startDates[(startDates.size() - 1)];
                                
                                List < Date > endDates = new List < Date > ();
                                endDates.add(bSch.End_Date__C);
                                endDates.add(billEnd);
                                endDates.sort();
                                Date MinEndDate = endDates[0];
                                
                                if(MinEndDate>MaxStartDate){
                                    Integer overlapDays = MaxStartDate.daysBetween(MinEndDate) + 1;
                                    if (overlapDays > 0) {
                                        overLapFlag = true;
                                        rentAmount += bSch.Amount__c * overlapDays;
                                        calulationMsg += '(' + bSch.Amount__c + '*' + overlapDays + ')';
                                    }
                                }
                                if (bSch.Amount__c == 0) {
                                    // its a rent free duration range
                                    rentFreestartDate = bSch.Start_Date__c;
                                    rentFreeEndDate = bSch.End_Date__C;
                                }
                                
                                billScheLineItem.Id = bSch.Id;
                                billScheLineItem.To_be_billed_on__c = billEnd;
                                billSchObject.add(billScheLineItem);
                                
                                //rentMap.put(hot.Id, rentAmount);                                
                            } 
                        }
                        
                            FinalRent = rentAmount / numberDays;
                            calulationMsg += '/'  + numberDays;                       
                    }
                    
                    Integer RentFreePeriod=0;
                    Integer ChargeableDays = 0;
                    Date MaxStartDate;
                    Date MinEndDate;
                    // get the rent free dates, for logging the chargeable and free period for reference
                    if(rentFreestartDate !=null && rentFreeEndDate !=null){
                        List < Date > startDates = new List < Date > ();
                        startDates.add(rentFreestartDate);
                        startDates.add(billStart);
                        startDates.sort();
                        
                        if (!startDates.isEmpty()) {
                            MaxStartDate = startDates[(startDates.size() - 1)];
                        }
                        
                        
                        List < Date > endDates = new List < Date > ();
                        endDates.add(rentFreeEndDate);
                        endDates.add(billEnd);
                        endDates.sort();
                        
                        if (!endDates.isEmpty()) {
                            MinEndDate = endDates[0];
                        }
                        
                        Boolean twoRanges = false;
                        
                        RentFreePeriod = MaxStartDate.daysBetween(MinEndDate) + 1;
                        ChargeableDays = 0;
                    }
                    // Now get the window of rent free dates.
                    // For the message for narration
                    String rentFreeChargeableMsg = '';
                    String message = 'This is being generated on ' + batchRunDate.format() + ' for ' + billStart.format() + ' - ' + billEnd.format() + '.'; 
                    if (RentFreePeriod <= 0) {
                        ChargeableDays = billStart.daysBetween(billEnd) + 1;
                        rentFreeChargeableMsg = 'No rent free duration during this billable period.\n\n' + ChargeableDays + ' days are chargeable';
                    } else {
                        rentFreeChargeableMsg=rentFreePeriod + ' - days are rent free:' + MaxStartDate.format() + '-to-' + MinEndDate.format();
                        ChargeableDays = billStart.daysBetween(billEnd) + 1 - rentFreePeriod;
                        if (billStart.Daysbetween(rentFreestartDate) > 0) {
                            Date Range1Start = billStart;
                            Date Range1End = rentFreeStartDate.addDays(-1);
                            rentFreeChargeableMsg += 'chargeable  period 1:' + Range1Start.format() + '-' + Range1End.format() + ':';
                        }
                        
                        if (rentFreeEndDate.Daysbetween(billEnd) > 0) {
                            Date Range2Start = rentFreeEndDate.addDays(1);
                            Date Range2End = billEnd;
                            rentFreeChargeableMsg += 'chargeable  period 2:' + Range2Start.format() + '-' + Range2End.format();
                        }
                        rentFreeChargeableMsg += '. \n \n' + ChargeableDays + ' days are chargeable';
                    }
                    
                    
                    fixedBillingLineItem.Opportunity__c = hot.Opportunity__c;
                    fixedBillingLineItem.Billing_Start_Date__c = billStart;
                    fixedBillingLineItem.Billing_End_Date__c = billEnd;
                    fixedBillingLineItem.Generation_Date__c = batchRunDate;
                    fixedBillingLineItem.Type_of_billing__c = ElbConstantsClass.TYPE_BILLING_YEARLY_FIXED;
                    fixedBillingLineItem.Amount__c = FinalRent;
                    fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;
                    fixedBillingLineItem.HEAD_OF_TERMS__c = hot.Id;
                    fixedBillingLineItem.Remarks__c = message + '\n \n' + rentFreeChargeableMsg +'\n \n'+ calulationMsg;
                    fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                    fixedBillingLineItem.Charge__c = chargeType;
                    fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.CHARGE_TYPE_LICENSE_FEE);
                    
                    fixedBillingObject.add(fixedBillingLineItem);
                    
                    
                    if (!billSchObject.isEmpty()) {
                        try{
                            update billSchObject;
                        } catch (Exception e) {
                            System.debug('The following exception has occurred: ' + e.getMessage());
                        }
                    }
                    
                    if (!fixedBillingObject.isEmpty()) {
                        try{
                            insert fixedBillingObject; 
                            for(Billing__c bill: fixedBillingObject){
                                appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                            BillingSerivices.getMethod(),
                                                                            bill.Id,
                                                                            ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                            }
                        } catch (Exception e) {
                            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                        BillingSerivices.getMethod(),
                                                                        hot.Opportunity__c,
                                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
                        }
                    }
                } 
            } 
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            
        } finally {
            if (!appLogObject.isEmpty()) {
                try{
                    insert appLogObject;
                }catch (Exception e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                } 
            }
        }
        return BillingSerivices.getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    //method to generate monthly car park bill(fixed bill) 
    public SurveyWrapper genreateMonthlyCarParkBill(Set<Id> optyIdSetBatch) {
        //Intialize variables
        optyMap = new Map < Id, List < Opportunity >> ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > ();
        hotIdSet = new set< Id > ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        chargesTypeList = new List < Charges_Type__c > ();
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Per_carpark_charge__c,
                   Number_of_chargeable_carparks__c, Building__c, Building__r.Name, Licence_End_Date__c, Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true
                  ];
        
        //Fetch Query for Charge Types
        chargesTypeList = [Select Id, Name, Charge_Type__c, Type_of_billing__c
                           From Charges_Type__c
                           Where Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED and Charge_Type__c =: ElbConstantsClass.CHARGE_TYPE_CAR_PARK];
        
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
                
                //Check if Billing Schedule for charge type as Car Park is Present
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c, Charges_Type__r.Charge_Type__c, HEAD_OF_TERMS__r.Licence_End_Date__c,
                               HEAD_OF_TERMS__r.Per_carpark_charge__c, HEAD_OF_TERMS__r.Number_of_chargeable_carparks__c, HEAD_OF_TERMS__r.Opportunity__c,
                               HEAD_OF_TERMS__r.Building__r.Name
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet and Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPE_CAR_PARK
                              ];
                
                List < Billing__c > fixedBillingObject = new List < Billing__c > ();
                
                // if billing schedule is empty log an error
                if (billSchList != null && billSchList.size() > 0) {
                    for (Billing_schedule__C bill: billSchList) {
                        
                        Decimal monthlyComp = 0;
                        String chargeType = '';
                        chargeType = bill.Charges_Type__c;
                        
                        Date targetDate = system.today();
                        Integer targetMonth = targetDate.Month();
                        Integer targetYear = targetDate.Year();
                        
                        Date nextDate = targetDate.addMonths(1);
                        Integer nextMonth = nextDate.Month();
                        Integer nextYear = nextDate.Year();
                        
                        Date licenseEndDate = bill.HEAD_OF_TERMS__r.Licence_End_Date__c;
                        
                        Date startOfNextMonth = nextDate.toStartOfMonth();
                        // total days in that month
                        Integer numberDays = date.daysInMonth(nextYear, nextMonth);
                        
                        Date endOfMonth = startOfNextMonth.addDays(numberDays - 1);
                        
                        Date billStart = startOfNextMonth;
                        Date billEnd = endOfMonth;
                        
                        if (licenseEndDate <= billEnd) {
                            Integer totalBillableDays = Math.abs(licenseEndDate.daysBetween(startOfNextMonth)) + 1;                                
                            billEnd = licenseEndDate;
                            // per day car park charge * total chargeable car parks * total billable days in that month
                            monthlyComp = (bill.HEAD_OF_TERMS__r.Per_carpark_charge__c / numberDays) * bill.HEAD_OF_TERMS__r.Number_of_chargeable_carparks__c * totalBillableDays;
                        } else {
                            monthlyComp = bill.HEAD_OF_TERMS__r.Per_carpark_charge__c * bill.HEAD_OF_TERMS__r.Number_of_chargeable_carparks__c;
                        }
                        
                        Billing__c fixedBillingLineItem = new Billing__c();
                        
                        fixedBillingLineItem.Opportunity__c = bill.HEAD_OF_TERMS__r.Opportunity__c;
                        fixedBillingLineItem.Billing_Start_Date__c = billStart;
                        fixedBillingLineItem.Billing_End_Date__c = billEnd;
                        fixedBillingLineItem.Generation_Date__c = targetDate;
                        fixedBillingLineItem.Type_of_billing__c = ElbConstantsClass.TYPE_BILLING_FIXED;
                        fixedBillingLineItem.Amount__c = monthlyComp;
                        fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;
                        fixedBillingLineItem.HEAD_OF_TERMS__c = bill.HEAD_OF_TERMS__c;
                        fixedBillingLineItem.Remarks__c = 'Charges for ' + bill.HEAD_OF_TERMS__r.Number_of_chargeable_carparks__c + ' billable Car Parks at ' + bill.HEAD_OF_TERMS__r.Per_carpark_charge__c;
                        fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                        fixedBillingLineItem.Charge__c = chargesTypeList[0].Id; 
                        fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.CHARGE_TYPES_CAR_PARK);
                        
                        fixedBillingObject.add(fixedBillingLineItem);
                        
                    }
                }
                if (!fixedBillingObject.isEmpty()) {
                    insert fixedBillingObject;
                    for(Billing__c bill: fixedBillingObject){
                        appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                    BillingSerivices.getMethod(),
                                                                    bill.Id,
                                                                    ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                    }
                }                
            }
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
            
        } finally {
            if (!appLogObject.isEmpty()) {
                insert appLogObject;
            }
        }
        return BillingSerivices.getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    //generation for monthly Housing bills
    public SurveyWrapper generateMonthlyHousingBill(Set<Id> optyIdSetBatch) {
        //Intialize variables      
        hotIdSet = new set< Id > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        //optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        
        // Checking if the selected Head of terms are marked as final in checkbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Per_carpark_charge__c,
                   Number_of_chargeable_carparks__c, Building__c, Building__r.Name, Licence_End_Date__c, License_fees_Commencement_date__c, Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true
                  ];
        
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        
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
                
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.Opportunity__c, HEAD_OF_TERMS__r.License_fees_Commencement_date__c,
                               HEAD_OF_TERMS__r.Licence_End_Date__c,Charges_Type__c, Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c, Charges_Type__r.Type_of_billing__c, Charges_Type__r.Charge_Type__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet AND (Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_HOUSING or 
                               Charges_Type__r.Charge_Type__c =: ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL) and
                               Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_FIXED]; //Added for Residential
                
                List < Billing__c > fixedBillingObject = new List < Billing__c > ();
                
                for(Billing_Schedule__c billSch: billSchList){
                    
                    Date targetDate = system.today().addmonths(1);
                    Integer targetMonth = targetDate.Month();
                    Integer targetYear = targetDate.Year();
                    // Housing is generated for the current month
                    Date minBillStartDate = billSch.HEAD_OF_TERMS__r.License_fees_Commencement_date__c;
                    Integer minBillMonth = minBillStartDate.Month();
                    
                    Date licenseEndDate = billSch.HEAD_OF_TERMS__r.Licence_End_Date__c;
                    
                    Date startOfCurrentMonth = targetDate.toStartOfMonth();
                    // num of days in that month
                    Integer numberDays = date.daysInMonth(targetYear, targetMonth);                                
                    Date endOfMonth = startOfCurrentMonth.addDays(numberDays - 1);
                    
                    Date billStart;
                    Date billEnd;
                    
                    billStart = startOfCurrentMonth;
                    billEnd = endOfMonth;
                    
                    if (minBillStartDate >= billStart) {
                        billStart = minBillStartDate;
                    }
                    
                    if (licenseEndDate <= billEnd) {
                        billEnd = licenseEndDate;
                    }
                    
                    Billing__c fixedBillingLineItem = new Billing__c();
                    
                    fixedBillingLineItem.Opportunity__c = billSch.HEAD_OF_TERMS__r.Opportunity__c;
                    fixedBillingLineItem.Billing_Start_Date__c = billStart;
                    fixedBillingLineItem.Billing_End_Date__c = billEnd;
                    fixedBillingLineItem.Generation_Date__c = system.today();
                    fixedBillingLineItem.Type_of_billing__c = billSch.Charges_Type__r.Type_of_billing__c;
                    fixedBillingLineItem.Amount__c = billSch.amount__c;//0;changed amount from 0 to billschedule's monthly compensation value
                    //fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;//ElbConstantsClass.BILLING_APPROVA_CONSUMPTION_NOT_ENTER;
                    fixedBillingLineItem.HEAD_OF_TERMS__c = billSch.HEAD_OF_TERMS__c;
                    fixedBillingLineItem.Remarks__c = 'This Bill is generated on ' + targetDate.format() + ' for ' + billStart.format() + ' - ' + billEnd.format() + '.';
                    fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                    fixedBillingLineItem.Charge__c = billSch.Charges_Type__r.id;//chargesTypeList[0].Id;
                    
                    if (billSch.Charges_Type__r.Charge_Type__c == ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL){      
                        fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.RECORD_TYPE_RESIDENTIAL);
                        fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVAL_NOT_SUBMIT;
                    } else if (billSch.Charges_Type__r.Charge_Type__c == ElbConstantsClass.CHARGE_TYPES_HOUSING){
                        fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.RECORD_TYPE_HOUSING);
                        fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVA_CONSUMPTION_NOT_ENTER;
                    }
                        
                    
                  	//recordTypes.get(ElbConstantsClass.RECORD_TYPE_HOUSING);
                    
                    fixedBillingObject.add(fixedBillingLineItem);
                    
                }
                
                if (!fixedBillingObject.isEmpty()) {
                    insert fixedBillingObject;
                    for(Billing__c bill: fixedBillingObject){
                        appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                    BillingSerivices.getMethod(),
                                                                    bill.Id,
                                                                    ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                    }
                } 
                
                
                
            }
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
        } finally {
            if (!appLogObject.isEmpty()) {               
                try {
                    insert appLogObject;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while inserting appLogObject: ' + e.getMessage());
                }
            }
        }
        
        return getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    //generation for monthly variable bills
    public SurveyWrapper generateMonthlyVariableBill(Set<Id> optyIdSetBatch) {
        //Intialize variables      
        chargesTypeList = new List < Charges_Type__c > ();
        //chargeTypeMap = new Map < Id, List < Charges_Type__c >> ();
        chargeTypeMap = new Map < Id, Charges_Type__c> ();
        optyMap = new Map < Id, List < Opportunity >> ();
        hotIdSet = new set< Id > ();
        List < Application_Log__c > appLogObject = new List < Application_Log__c > ();
        hotList = new List < HEAD_OF_TERMS__c > ();
        optyHotMap = new Map < Id, List < HEAD_OF_TERMS__c >> ();
        billSchList = new List < Billing_Schedule__c > ();
        
        //Fetch Query for Charge Types
        chargesTypeList = [Select Id, Name, Charge_Type__c, Type_of_billing__c
                           From Charges_Type__c
                           Where Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_VARIABLE];
        
        try {
            if (!chargesTypeList.isEmpty()) {
                for (Charges_Type__c cty: chargesTypeList) {
                    if (!chargeTypeMap.containsKey(cty.Id)) //{redundant
                        chargeTypeMap.put(cty.Id, cty);
                        /*List < Charges_Type__c > newList = new List < Charges_Type__c > ();
                        newList.add(cty);
                        chargeTypeMap.put(cty.Id, newList);
                    } else {
                        chargeTypeMap.get(cty.Id).add(cty);
                    }*/
                }
            }
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
        } finally {
            if (!appLogObject.isEmpty()) {
                try {
                    insert appLogObject;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while inserting appLogObject: ' + e.getMessage());
                }
            }
        }
        
        // Checking if the selected Head of terms are marked as final in checbox field
        hotList = [Select Id, Name, Opportunity__c, Opportunity__r.Name, Mark_as_final__c, Lease_Status__c, Per_carpark_charge__c,
                   Number_of_chargeable_carparks__c, Building__c, Building__r.Name, Licence_End_Date__c, License_fees_Commencement_date__c, Lease_Abstract__c
                   from HEAD_OF_TERMS__c
                   Where Opportunity__c IN: optyIdSetBatch and Mark_as_final__c =: true and Lease_Abstract__c =: true
                  ];
        
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes(ElbConstantsClass.BILLING_API);
        List<Leasing_Monthly_Variable_Bill_Start_Date__mdt> lstVariableBillStartDates = Leasing_Monthly_Variable_Bill_Start_Date__mdt.getall().values();
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
                
                billSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Charges_Type__r.Name, Start_Date__c, End_Date__c,
                               Rate__c, Net_usable_area_Area_Sq_ft__c, Amount__c, Charges_Type__r.Type_of_billing__c, Charges_Type__r.Charge_Type__c,
                               HEAD_OF_TERMS__r.License_fees_Commencement_date__c, HEAD_OF_TERMS__r.Licence_End_Date__c, HEAD_OF_TERMS__r.Opportunity__c
                               from Billing_Schedule__c
                               where HEAD_OF_TERMS__c IN: hotIdSet AND Charges_Type__r.Type_of_billing__c =: ElbConstantsClass.TYPE_BILLING_VARIABLE
                              ];
                
                List < Billing__c > fixedBillingObject = new List < Billing__c > ();
                if (!chargeTypeMap.isEmpty()) {
                    for (Id ctId: chargeTypeMap.keySet()) {
                        
                        for (Billing_Schedule__c billSch: billSchList) {
                            
                            Date targetDate = system.today();
                            Integer targetMonth = targetDate.Month();
                            Integer targetYear = targetDate.Year();
                            // cam is generated for the previous month
                            /*Date minBillStartDate = bill.HEAD_OF_TERMS__r.License_fees_Commencement_date__c;
                            Integer minBillMonth = minBillStartDate.Month();*/ //redundant
                            
                            Date previousDate = targetDate.addMonths(-1);
                            Integer previousMonth = previousDate.Month();
                            Integer previousYear = previousDate.Year();
                            
                            Date licenseEndDate = billSch.HEAD_OF_TERMS__r.Licence_End_Date__c;
                            
                            Date startOfPreviousMonth = previousDate.toStartOfMonth();
                            // num of days in that month
                            Integer numberDays = date.daysInMonth(previousYear, previousMonth);                                
                            Date endOfMonth = startOfPreviousMonth.addDays(numberDays - 1);
                            
                            Date billStart;
                            Date billEnd;
                            
                            billStart = startOfPreviousMonth;
                            billEnd = endOfMonth;
                            //Added to accomodate CAM , AHU , HVAC , Revenue Share and Water consumption bill start and bill end dates
                            for(Leasing_Monthly_Variable_Bill_Start_Date__mdt mdt : lstVariableBillStartDates){
                                system.debug('billSch.Charges_Type__r.Charge_Type__c :'+billSch.Charges_Type__r.Charge_Type__c);
                                system.debug('ElbConstantsClass.CHARGE_TYPE_CAM1 :'+ElbConstantsClass.CHARGE_TYPE_CAM1);
                                system.debug('mdt.MasterLabel :'+mdt.MasterLabel);
                                if(billSch.Charges_Type__r.Charge_Type__c==ElbConstantsClass.CHARGE_TYPE_CAM1 && billSch.Charges_Type__r.Charge_Type__c==mdt.MasterLabel){
                                    system.debug('Inside if billSch.Charges_Type__r.Charge_Type__c:'+billSch.Charges_Type__r.Charge_Type__c+'ElbConstantsClass.CHARGE_TYPE_CAM1 :'+ElbConstantsClass.CHARGE_TYPE_CAM1+'mdt.MasterLabel :'+mdt.MasterLabel);
                                    billStart=Date.newInstance(targetYear, targetMonth , Integer.valueOf(mdt.Bill_Start_Date__c));                                  
                                }
                                else if (billSch.Charges_Type__r.Charge_Type__c==mdt.MasterLabel){
                                    system.debug('Inside else :'+billSch.Charges_Type__r.Charge_Type__c+'ElbConstantsClass.CHARGE_TYPE_CAM1 :'+ElbConstantsClass.CHARGE_TYPE_CAM1+'mdt.MasterLabel :'+mdt.MasterLabel);
                                    billStart=Date.newInstance(previousYear, previousMonth, Integer.valueOf(mdt.Bill_Start_Date__c));
                                }                             
                            }
                            
                            if (licenseEndDate <= billEnd) 
                                billEnd = licenseEndDate;
                            else
                            	billEnd=billStart.addMonths(1).addDays(-1);    
                            
                            if (ctId == billSch.Charges_Type__c) {
                                Billing__c fixedBillingLineItem = new Billing__c();
                                
                                fixedBillingLineItem.Opportunity__c = billSch.HEAD_OF_TERMS__r.Opportunity__c;
                                fixedBillingLineItem.Billing_Start_Date__c = billStart;
                                fixedBillingLineItem.Billing_End_Date__c = billEnd;
                                fixedBillingLineItem.Generation_Date__c = targetDate;
                                fixedBillingLineItem.Type_of_billing__c = ElbConstantsClass.TYPE_BILLING_VARIABLE;
                                fixedBillingLineItem.Amount__c = 0;
                                fixedBillingLineItem.Approval_Status__c = ElbConstantsClass.BILLING_APPROVA_CONSUMPTION_NOT_ENTER;
                                fixedBillingLineItem.HEAD_OF_TERMS__c = billSch.HEAD_OF_TERMS__c;
                                fixedBillingLineItem.Remarks__c = 'This Bill is generated on ' + targetDate.format() + ' for ' + billStart.format() + ' - ' + billEnd.format() + '.';
                                fixedBillingLineItem.Posting_Status__c = ElbConstantsClass.BILLING_SYNC_STATUS_NOT_POST;
                                fixedBillingLineItem.Charge__c = billSch.Charges_Type__c;
                                if(billSch.Charges_Type__r.Charge_Type__c == ElbConstantsClass.CHARGE_TYPE_CAM1){
                                    fixedBillingLineItem.RecordTypeId = recordTypes.get(ElbConstantsClass.CHARGE_TYPE_CAM1);
                                } else {
                                    fixedBillingLineItem.RecordTypeId = recordTypes.get(billSch.Charges_Type__r.Name);
                                }
                                fixedBillingObject.add(fixedBillingLineItem);
                            }
                        } 
                    }
                }
                
                if (!fixedBillingObject.isEmpty()) {
                    insert fixedBillingObject;
                    for(Billing__c bill: fixedBillingObject){
                        appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                                    BillingSerivices.getMethod(),
                                                                    bill.Id,
                                                                    ElbConstantsClass.LOG_SUCCESS_MESSAGE_LONG));
                    }
                } 
                
                
                
            }
        } catch (Exception e) {
            appLogObject.add(BillingSerivices.createLog(BillingSerivices.getClassName(),
                                                        BillingSerivices.getMethod(),
                                                        NULL,
                                                        'ERROR: ' + e + ' at line ' + e.getLineNumber()));
        } finally {
            if (!appLogObject.isEmpty()) {               
                try {
                    insert appLogObject;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while inserting appLogObject: ' + e.getMessage());
                }
            }
        }
        
        return BillingSerivices.getListOfSuccessAndErrors(appLogObject, hotIdSet);
    }
    
    public class SurveyWrapper { 
        public Application_Log__c surveyBilling {get;set;}
        public SurveyWrapper surveyWrapperItem {get;set;}
        public List<SurveyWrapper> surveyWrapperList {get;set;}
        public Set<Id> hotIdSet {get;set;}
        public integer responseCount {get;set;}
        public Integer responsePositiveCount{get;set;}
        public Integer responseNegativeCount{get;set;}
        
        public SurveyWrapper() {
            surveyBilling = new Application_Log__c();
            responseCount = 0;
            responsePositiveCount = 0;
            responseNegativeCount = 0;
        }
        
        public SurveyWrapper(SurveyWrapper surveyWrapperItem) {
            this.surveyWrapperItem = surveyWrapperItem;
        }
    }
}