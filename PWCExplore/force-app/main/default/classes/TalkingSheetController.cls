/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for Comparison Sheet to understand if any deviation or changes to the proposal has been processed
Related:        TalkingSheet.vfp
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public class TalkingSheetController {
    public Boolean isRunError {get;set;}
    public string preparedFor {get;set;}
    public string preparedBy{get;set;}
    public NumberToWord formatClass {get;set;}
    public string amountCompensation{get;set;}
    public string amountSecurityDep{get;set;}
    public string wordCompensation{get;set;}
    public string wordSecurityDep{get;set;}
    public Boolean printCAMDetails {get;set;}
    public HEAD_OF_TERMS__c HOT {get;set;}
    public String OptyID {get;set;}
    public List < Opportunity > optyList {get;set;}
    public List < Junction_Unit__c > unitList {get;set;}
    public string optyName {get;set;}
    public Map<String,List<Junction_Unit__c>> premiseGroupMap {get;set;}
    public List<String> premiseOptionsList {get;set;}
    public Map<String,String> premiseOfficeSpaceMap {get;set;}
    public Map < String, List < String >> mergeFieldsMap {get;set;}
    public Map < String, HEAD_OF_TERMS__c > HoTFieldMap {get;set;}
    public Map < String, Integer > colspanMap {get;set;}
    public Map<String,List<Term_Item__C>> premiseGroupTermMap {get;set;}
    public List<termWrapper> termWrapperList {get; set;}
    public List<Billing_Schedule__c> billingSchList {get;set;}
    public List<BillingWrapper> billingWrapperList {get; set;}
    public string hotId;
    public Junction_Unit__c rentalUnit {get;set;}
    public List<HEAD_OF_TERMS__c> headOfTermsList {get;set;}
    public List<Junction_Unit__c> rentalUnitList {get;set;}
    public List<Term_Item__c> termList {get;set;}
    public Map<id, Term_Item__c> termMap {get;set;}
    public map < String, Id > fetchRecordTypes(String ObjApiName) {
        map < String, Id > rtMap = new map < String, Id > ();
        for (RecordType rt: [select Id, Name, DeveloperName from RecordType where sObjectType =: ObjApiName]) {
            rtMap.put(rt.Name, rt.Id);
        }
        return rtMap;
    }
    
    //fetch details regarding deviation or any changes made to the terms
    public void getDetails() {
        
        isRunError = false;
        headOfTermsList = new List<HEAD_OF_TERMS__c>();
        rentalUnitList = new List<Junction_Unit__c>();
        termList = new List<Term_Item__c>();
        termMap = new Map<id, Term_Item__c>();
        termWrapperList = new List<termWrapper>();
        mergeFieldsMap = new Map < String, List < String >>();
        HoTFieldMap = new  Map < String, HEAD_OF_TERMS__c >();
        colspanMap = new  Map < String, Integer >();
        premiseGroupTermMap = new Map<String,List<Term_Item__C>>();
        unitList = new List < Junction_Unit__c > ();
        premiseGroupMap = new Map<String,List<Junction_Unit__c>>();
        premiseOptionsList = new List<String>();
        premiseOfficeSpaceMap = new Map<String,String>(); 
        billingSchList = new List<Billing_Schedule__c>();
        billingWrapperList = new List<BillingWrapper>();
        formatClass = new NumberToWord();
        amountCompensation = '';
        amountSecurityDep='';
        wordCompensation = '';
        wordSecurityDep = '';
        printCAMDetails = false;
        //printOfficeSpaceDetails = false;
        hotId = ApexPages.currentPage().getParameters().get('hotId');
        
        headOfTermsList = [Select Id, Name, Licensor__c, Proposed_Licensee__c, Net_usable_area_Area_Sq_ft__c, Building__c, Building__r.Building_View__c, Building__r.Project__c,
                           Building__r.City__c, Building__r.Location__c, Building__r.Display_Name__c, Opportunity__r.Auto_Number__c, Billing_Mismatch__c                   
                           from HEAD_OF_TERMS__c
                           where id =: hotId];
        
        rentalUnitList = [Select Id, Name, HEAD_OF_TERMS__c, Floor__c, Floor__r.Block__c, Floor__r.Floor_Number__c
                          from Junction_Unit__c
                          where HEAD_OF_TERMS__c =: hotId];
        
        termList = [Select Id, Name, HEAD_OF_TERMS__c, Header__c, Merged_Term_Value__c, Value__c, Merge_Field_1__c, Deviation__c, Reason_for_deviation__c, Negotiation_Details__c, Negotiation_Log__c
                    from Term_Item__c
                    where HEAD_OF_TERMS__c =: hotId order by sequence__c];
        
        if (hotId != null) {
            HOT = [Select Id, Opportunity__r.Id,Rent_per_sq_ft_monthly__c,Carpark_Ratio__c,
                   Rent_escalation_structure__c,Security_Deposit_Number_of_months__c,
                   Security_Deposit_Calculation_Type__c, Leasing_Term__C, 
                   Lock_in_period_in_months__c, Terms_of_payment_CAM_fee__c, 
                   Terms_of_payment_license_fee__c	, Renewal_Terms__c,
                   Compensation_free_period__c,Chareable_Carpark__c, Total_Number_of_carparks__c,
                   Number_of_carparks_included_in_the__c,Number_of_chargeable_carparks__c,Per_carpark_charge__c,Validity_in_Days__c,
                   Bill_Leasing_Term__c
                   from HEAD_OF_TERMS__c where Id =: hotId];
            OptyID = HoT.Opportunity__r.Id;
            optyList = [select id, Name,AccountId,Account.Name,IPC__c,IPC__r.Name from Opportunity where id =: OptyID];
            
            if (optyList.size() > 0) {
                optyName = optyList[0].Account.Name;
                unitList = [select Name,  Floor__c, Floor__r.Name, Status__c, Opportunity__c, Chargeable_area__c, Area__c, Floor__r.Building__c, Floor__r.Building__r.Name,
                            Floor__r.Building__r.Building_Type__c, Floor__r.Building__r.Building_Configuration__c, Floor__r.Building__r.Project__c,Floor__r.Building__r.Use_of_premises__c,
                            Floor__r.Building__r.Bldg_Status__c, Carpet_Area_in_Sq_Ft__c,  HEAD_OF_TERMS__c,Premise_Group__c, Floor__r.Block__c,Floor__r.Floor_Number__c,
                            Floor__r.Terrace_Floor__c, Floor__r.Building__r.Agreement_Type__c, Floor__r.Building__r.Display_Name__c, 
                            Floor__r.Building__r.Building_View__c, Floor__r.Building__r.Typical__c, Floor__r.Building__r.Title_of_the_HOT__c,
                            Floor__r.Type_of_premise__c
                            from Junction_Unit__c where Opportunity__c =: OptyID and HEAD_OF_TERMS__c = :HoTID
                           ];
                
                if (unitList.size() > 0) {
                    for (Junction_Unit__c unit: unitList) {
                        if(premiseGroupMap.containsKey(unit.Premise_Group__c)){
                            premiseGroupMap.get(unit.Premise_Group__c).add(unit);
                            String premDesc1 = premiseOfficeSpaceMap.get(unit.Premise_Group__c);
                            String suffix1 ='';
                            if(unit.Floor__r.Floor_Number__c == '1'){
                                suffix1 = '1st floor';
                            } else if(unit.Floor__r.Floor_Number__c == '2') {
                                suffix1 = '2nd floor';
                            } else if(unit.Floor__r.Floor_Number__c == '3') {
                                suffix1 = '3rd floor';
                            } else {
                                suffix1 = unit.Floor__r.Floor_Number__c + 'th floor';
                            }
                            if(String.isNotBlank(unit.Floor__r.Block__c) && !(unit.Floor__r.Block__c.equalsIgnoreCase('NA'))) {
                                premDesc1 += ',' + unit.Floor__r.Block__c +',' + suffix1;
                            }
                            else {
                                premDesc1 += ',' + suffix1;
                            }
                            premiseOfficeSpaceMap.put(unit.Premise_Group__C,premDesc1);
                        } else {
                            List<Junction_Unit__c> tempList = new List<Junction_Unit__c>();
                            tempList.add(unit);
                            String suffix ='';
                            if(unit.Floor__r.Floor_Number__c == '1'){
                                suffix = '1st floor';
                            } else if(unit.Floor__r.Floor_Number__c == '2') {
                                suffix = '2nd floor';
                            } else if(unit.Floor__r.Floor_Number__c == '3') {
                                suffix = '3rd floor';
                            } else {
                                suffix = unit.Floor__r.Floor_Number__c + 'th floor';
                            }
                            String premDesc = '';
                            if(String.isNotBlank(unit.Floor__r.Block__c) && !(unit.Floor__r.Block__c.equalsIgnoreCase('NA'))) {
                                premDesc = unit.Floor__r.Building__r.Display_Name__c + ',' + unit.Floor__r.Block__c + ',' + suffix;
                            } else {
                                premDesc = unit.Floor__r.Building__r.Display_Name__c +  ',' + suffix;
                            }
                            premiseGroupMap.put(unit.Premise_Group__c,tempList);
                            premiseOptionsList.add(unit.Premise_Group__c);
                            premiseOfficeSpaceMap.put(unit.Premise_Group__c, premDesc);
                        }
                    }
                }
            }
        }
        // merge field value under each term
        mergeFieldsMap = new Map < String, List < String >> ();
        // term Id to Term Record Mapping
        HoTFieldMap = new Map < String, HEAD_OF_TERMS__c > ();
        List<Term_Item__C> tList = new List<Term_Item__C>();
        List<Term_Item__C> tListNew = new List<Term_Item__C>();
        
        colspanMap = new Map<String,Integer>();
        tList = [Select id, Name, Sequence__C, Header__C, term_text_editable__c, Include_Term__c, Value__C,
                 Merge_Field_1__c, Merge_Field_2__c, Merge_Field_3__c 
                 from Term_Item__C 
                 where RecordType.Name =: ElbConstantsClass.RECORD_TYPE_STANDARD_CLAUSES order by Sequence__C];
        
        Map<String,Id> recordTypes = new Map<String,Id>();
        Map<String,Id> recordTypesCharge = new Map<String,Id>();
        Utility u = new Utility();
        recordTypes = u.fetchRecordTypes(ElbConstantsClass.HEAD_OF_TERMS_API);
        recordTypesCharge = fetchRecordTypes(ElbConstantsClass.RECORD_TYPES_CHARGES_TYPE);
        for(String option: premiseGroupMap.keySet()) {
            Head_Of_Terms__c ht  = new Head_Of_Terms__c();
            ht.handover_condition__c = premiseGroupMap.get(option)[0].Floor__r.Type_of_premise__c;
            ht.premise_group__c = option;
            tListNew = new List<Term_Item__C>();
            for(Term_Item__C term : tList){
                Term_Item__c term1 = new Term_Item__c();
                term1.Value__c = term.Value__c;
                term1.Merge_Field_2__c = term.Merge_Field_2__c;
                term1.Merge_Field_3__c = term.Merge_Field_3__c;
                term1.Merge_Field_1__c = term.Merge_Field_1__c;
                term1.Header__C = term.Header__c;
                term1.term_text_editable__c = term.term_text_editable__c;
                term1.key__c = term.Id + option;
                term1.Deviation__c = ElbConstantsClass.NO;
                term1.Reason_for_deviation__c = '';
                term1.include_term__c = true;
                term1.Sequence__C = term.Sequence__C;
                term.RecordTypeId = recordTypes.get(ElbConstantsClass.RECORD_TYPE_PROPOSED_CLAUSES);
                tListNew.add(term1);
            }
            premiseGroupTermMap.put(option,tListNew);
        }
        
        billingSchList = [Select Id, Name, HEAD_OF_TERMS__c, Charges_Type__c, Net_usable_area_Area_Sq_ft__c, Start_Date__c, End_Date__c, From_Month__c, To_Month__c, 
                          Number_of_Months__c, Rate__c, Amount__c, Security_Deposit__c
                          from Billing_Schedule__c
                          where HEAD_OF_TERMS__c =: hotId
                          order by Name];
        
        if((HOT.Leasing_Term__c != HOT.Bill_Leasing_Term__c || billingSchList.isEmpty()) && headOfTermsList[0].Billing_Mismatch__c == true){
            isRunError = true;
            Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Please enter the details for Billing Schedule or check the details entered in the Billing Schedule, there is a mis-match of the license term.'));
        }
        else{
            Integer i1 = 1;
            for(Billing_Schedule__c bi: billingSchList){
                List<Billing_Schedule__c> biList = new List<Billing_Schedule__c>();
                biList.add(bi);
                amountCompensation = formatClass.INFormat(bi.Amount__c);
                amountSecurityDep = formatClass.INFormat(bi.Security_Deposit__c);
                wordCompensation = formatClass.getNumberToWordConvertion(bi.Amount__c);
                wordSecurityDep = formatClass.getNumberToWordConvertion(bi.Security_Deposit__c);
                if(bi.Start_Date__c == NULL || bi.End_Date__c == NULL){
                    billingWrapperList.add(new BillingWrapper(i1, biList, false, amountCompensation, amountSecurityDep, wordCompensation, wordSecurityDep));
                }
                else{
                    billingWrapperList.add(new BillingWrapper(i1, biList, true, amountCompensation, amountSecurityDep, wordCompensation, wordSecurityDep));
                }
                
                i1 += 1;
            }
        }
        
        if(termList.isEmpty()){
            isRunError = true;
        }
        else{
            Integer i = 1;
            for(Term_Item__c ti: termList){  
                List<Term_Item__c> teList = new List<Term_Item__c>();
                teList.add(ti);
                if(ti.Header__c == ElbConstantsClass.CAM_CHARGES){
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, false));
                    printCAMDetails = true;
                }
                else if(ti.Header__c == ElbConstantsClass.OFFERED_FLOOR_AREA){
                    termWrapperList.add(new termWrapper(i, teList, false, true, false, false));
                    //printOfficeSpaceDetails = true;
                }
                else if(ti.Header__c == ElbConstantsClass.MONTHLY_COMP_FEE){
                    termWrapperList.add(new termWrapper(i, teList, false, false, true, false));
                }
                else if(ti.Header__c == ElbConstantsClass.SECURITY_DEPOSIT){
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, true));
                }
                else{
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, false));
                }
                i += 1;
            }
        }
    }
    
    public class termWrapper{
        public Integer termSequence {get;set;}
        public Boolean termItemBool {get;set;}
        public Boolean printOfficeSpaceDetails {get;set;}
        public Boolean printMonCompDetails {get;set;}
        public Boolean printSecurityDeopsitDetails {get;set;}
        public List<Term_Item__c> termItemObject {get;set;}
        
        public termWrapper(Integer termSequence, List<Term_Item__c> termItemObject, Boolean termItemBool, Boolean printOfficeSpaceDetails, Boolean printMonCompDetails, Boolean printSecurityDeopsitDetails){
            this.termSequence = termSequence;
            this.termItemObject = termItemObject;  
            this.termItemBool = termItemBool;
            this.printOfficeSpaceDetails = printOfficeSpaceDetails;
            this.printMonCompDetails = printMonCompDetails;
            this.printSecurityDeopsitDetails = printSecurityDeopsitDetails;
        }
    }
    
    public class BillingWrapper{
        public Integer billingSequence {get;set;}
        public Boolean printDate {get;set;}
        public List<Billing_Schedule__c> billingItemObject {get;set;}
        public String moneyFormatCompensation {get;set;}
        public String moneyFormatSecurityDep {get;set;}
        
        public String wordFormatCompensation {get;set;}
        public String wordFormatSecurityDep {get;set;}
        
        public BillingWrapper(Integer billingSequence, List<Billing_Schedule__c> billingItemObject, Boolean printDate, String moneyFormatCompensation, String moneyFormatSecurityDep, String wordFormatCompensation, String wordFormatSecurityDep){
            this.billingSequence = billingSequence;
            this.billingItemObject = billingItemObject;
            this.printDate = printDate;
            this.moneyFormatCompensation = moneyFormatCompensation;
            this.moneyFormatSecurityDep = moneyFormatSecurityDep;
            this.wordFormatCompensation = wordFormatCompensation;
            this.wordFormatSecurityDep = wordFormatSecurityDep;
        }
    }
}