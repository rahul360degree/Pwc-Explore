/*------------------------------------------------------------------------
Author:        Lalitha Bhat
Company:       Stetig
Description:   Class for generating a Head of term from premise tagging over opportunity
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public without sharing class CreateHoT {
    public NumberToWord formatClass {get;set;}
    public List < SelectOption > lstPaymentPlanList {get;set;}
    public string strPPId {get;set;}
    Public String OptyID {get;set;}
    Public String HoTID {get;set;}
    public List < Opportunity > optyList {get;set;}
    Public List < Junction_Unit__c > unitList {get;set;}
    public string optyName {get;set;}
    public string projectName {get;set;}
    public HEAD_OF_TERMS__c HOT {get;set;}
    public Decimal CarpetArea {get;set;}
    public Date HoTDate {get;set;}
    public Boolean validate{get;set;}
    public Boolean error{get;set;}
    public Map<String,List<Junction_Unit__c>> premiseGroupMap {get;set;}
    public List<String> premiseOptionsList {get;set;}
    public Map<String,String> premiseOfficeSpaceMap {get;set;}
    public Map<String,List<Term_Item__C>> premiseGroupTermMap {get;set;}
    public Map<String,Head_Of_Terms__c> premiseGroupHTMap {get;set;}
    public Map < String, List < String >> mergeFieldsMap {get;set;}
    public Map < String, HEAD_OF_TERMS__c > HoTFieldMap {get;set;}
    public Map<String,String> fieldLabelMap {get;set;}
    public Boolean generated {get;set;}
    public Boolean carparktable {get;set;}
    public Map < String, Integer > colspanMap {get;set;}
    
    //method to create a head of term record
    public CreateHoT() {
        optyName = '';
        CarpetArea = 0;
        validate = false;
        strPPId = '';
        unitList = new List < Junction_Unit__c > ();
        premiseGroupMap = new Map<String,List<Junction_Unit__c>>();
        premiseOptionsList = new List<String>();
        premiseOfficeSpaceMap = new Map<String,String>();
        error= false;
        premiseGroupTermMap = new Map<String,List<Term_Item__C>>();
        premiseGroupHTMap = new Map<string,Head_Of_Terms__c>();
        fieldLabelMap = new Map < String, String > ();
        generated = false;
        carparktable = false;
        
        if (ApexPages.currentPage().getParameters().get('HoTID') != null && ApexPages.currentPage().getParameters().get('HoTID') != '') {
            
            HoTID = apexPages.currentPage().getParameters().get('HoTID');
            
            if (HoTID != null) {
                HOT = [Select Id, Opportunity__r.Id,Rent_per_sq_ft_monthly__c,Carpark_Ratio__c,
                       Rent_escalation_structure__c,Security_Deposit_Number_of_months__c,
                       Security_Deposit_Calculation_Type__c, Leasing_Term__C, 
                       Lock_in_period_in_months__c, Terms_of_payment_CAM_fee__c, 
                       Terms_of_payment_license_fee__c	, Renewal_Terms__c,
                       Compensation_free_period__c,Chareable_Carpark__c, Total_Number_of_carparks__c,
                       Number_of_carparks_included_in_the__c,Number_of_chargeable_carparks__c,Per_carpark_charge__c,Validity_in_Days__c, Escalation_Percentage__c
                       from HEAD_OF_TERMS__c where Id=:HoTId];
                OptyID = HoT.Opportunity__r.Id;
                optyList = [select id, Name,AccountId,Account.Name,IPC__c,IPC__r.Name from Opportunity where id =: OptyID];
                
                if (optyList.size() > 0) {
                    optyName = optyList[0].Account.Name;
                    unitList = [select Name,  Floor__c, Floor__r.Name, Status__c, Opportunity__c, Chargeable_area__c, Area__c, Floor__r.Building__c, Floor__r.Building__r.Name,
                                Floor__r.Building__r.Building_Type__c, Floor__r.Building__r.Building_Configuration__c, Floor__r.Building__r.Project__c,Floor__r.Building__r.Use_of_premises__c,
                                Floor__r.Building__r.Bldg_Status__c, Carpet_Area_in_Sq_Ft__c,  HEAD_OF_TERMS__c,Premise_Group__c, Floor__r.Block__c,Floor__r.Floor_Number__c,
                                Floor__r.Terrace_Floor__c, Floor__r.Building__r.Agreement_Type__c, Floor__r.Building__r.Display_Name__c, 
                                Floor__r.Building__r.Building_View__c, Floor__r.Building__r.Typical__c, Floor__r.Building__r.Title_of_the_HOT__c,Building__c,Building__r.Name,
                                Floor__r.Type_of_premise__c
                                from Junction_Unit__c where Opportunity__c =: OptyID and HEAD_OF_TERMS__c = :HoTID
                               ];
                    
                    if (unitList.size() > 0) {
                        for (Junction_Unit__c unit: unitList) {
                            if(premiseGroupMap.containsKey(unit.Premise_Group__C)){
                                premiseGroupMap.get(unit.Premise_Group__C).add(unit);
                                String premDesc1 = premiseOfficeSpaceMap.get(unit.Premise_Group__C);
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
                            }
                            else {
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
                                premiseGroupMap.put(unit.Premise_Group__C,tempList);
                                premiseOptionsList.add(unit.Premise_Group__C);
                                premiseOfficeSpaceMap.put(unit.Premise_Group__C, premDesc);
                            }
                        }
                    }
                    String type='HEAD_OF_TERMS__c';
                    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                    Schema.SObjectType HoTschema = schemaMap.get(type);
                    Map<String, Schema.SObjectField> fieldMap = HoTschema.getDescribe().fields.getMap();
                    
                    for (String fieldName: fieldMap.keySet()) {
                        fieldLabelMap.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
                    }
                    
                    // merge field value under each term
                    mergeFieldsMap = new Map < String, List < String >> ();
                    // term Id to Term Record Mapping
                    HoTFieldMap = new Map < String, HEAD_OF_TERMS__c > ();
                    List<Term_Item__C> termList = new List<Term_Item__C>();
                    List<Term_Item__C> termListNew = new List<Term_Item__C>();
                    
                    colspanMap = new Map<String,Integer>();
                    termList = [Select id, Name, Sequence__C, Header__C, term_text_editable__c, Include_Term__c, Value__C, Merge_Field_1__c, Merge_Field_2__c, Merge_Field_3__c, customised_term__c from Term_Item__C where RecordType.Name = 'Standard Clauses' order by Sequence__C];
                    Map<String,Id> recordTypes = new Map<String,Id>();
                    Utility u = new Utility();
                    recordTypes = u.fetchRecordTypes(ElbConstantsClass.HEAD_OF_TERMS_API);
                    for(String option: premiseGroupMap.keySet()) {
                        Head_Of_Terms__c hoTerm  = new Head_Of_Terms__c();
                        hoTerm.handover_condition__c = premiseGroupMap.get(option)[0].Floor__r.Type_of_premise__c;
                        hoTerm.premise_group__c = option;
                        termListNew = new List<Term_Item__C>();
                        for(Term_Item__C term : termList){
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
                            term1.RecordTypeId = recordTypes.get(ElbConstantsClass.RECORD_TYPE_PROPOSED_CLAUSES);
                            termListNew.add(term1);
                        }
                        premiseGroupTermMap.put(option,termListNew);
                        premiseGroupHTMap.put(option,hoTerm);
                        
                        if (termListNew.size() > 0) {
                            for (Term_Item__c term: termListNew) {
                                term.Merged_Term_Value__c = findAndReplaceMergeFields(term.Value__c, term, hoTerm);
                                
                                HoTFieldMap.put(term.key__c, hoTerm);
                                
                                List < String > tempList = new List < String > ();
                                mergeFieldsMap.put(term.key__c, tempList);
                                HoTFieldMap.put(term.key__c, hoTerm);
                                if (String.isNotBlank(term.Merge_Field_1__c)) {
                                    if (mergeFieldsMap.containsKey(term.key__c)) {
                                        mergeFieldsMap.get(term.key__c).add(term.Merge_Field_1__c.toLowerCase());
                                    } else {
                                        List < String > tempList1 = new List < String > ();
                                        tempList1.add(term.Merge_Field_1__c.toLowerCase());
                                        mergeFieldsMap.put(term.key__c, tempList1);
                                    }
                                }
                                if (String.isNotBlank(term.Merge_Field_2__c)) {
                                    if (mergeFieldsMap.containsKey(term.key__c)) {
                                        mergeFieldsMap.get(term.key__c).add(term.Merge_Field_2__c.toLowerCase());
                                    } else {
                                        List < String > tempList1 = new List < String > ();
                                        tempList1.add(term.Merge_Field_2__c.toLowerCase());
                                        mergeFieldsMap.put(term.key__c, tempList1);
                                    }
                                }
                                if (String.isNotBlank(term.Merge_Field_3__c)) {
                                    if (mergeFieldsMap.containsKey(term.key__c)) {
                                        mergeFieldsMap.get(term.key__c).add(term.Merge_Field_3__c.toLowerCase());
                                    } else {
                                        List < String > tempList1 = new List < String > ();
                                        tempList1.add(term.Merge_Field_3__c.toLowerCase());
                                        mergeFieldsMap.put(term.key__c, tempList1);
                                    }
                                }   
                                if(mergeFieldsMap.get(term.key__c).size() > 0)
                                    colspanMap.put(term.key__c, 4 - (mergeFieldsMap.get(term.key__c).size()));
                                else 
                                    colspanMap.put(term.key__c, 4);
                            }
                        }
                    }
                }
                
            }      
        }
    }
    public string findAndReplaceMergeFields(String fieldValue, Term_Item__C tItem, Head_Of_Terms__c hoTerm) {
        Pattern pat = Pattern.compile(ElbConstantsClass.PATTERN);
        formatClass = new NumberToWord();
        matcher myMatcher = pat.matcher(tItem.Value__c);
        String replacementString = tItem.Value__c;
        String replacableString = '';
        while (myMatcher.find()) {
            
            String mergeFieldName = myMatcher.group();
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M1)) {
                replacableString = tItem.Merge_Field_1__c;
                mergeFieldName = replacableString;
                system.debug('Merge field:' + mergeFieldName);

                replacableString = String.ValueOf(hoTerm.get(replacableString));
            }
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M2)) {
                replacableString = tItem.Merge_Field_2__c;
                system.debug('Merge field:' + mergeFieldName);

                mergeFieldName = replacableString;
                replacableString = String.ValueOf(hoTerm.get(replacableString));
            }
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M3)) {
                replacableString = tItem.Merge_Field_3__c;
                system.debug('Merge field:' + mergeFieldName);

                mergeFieldName = replacableString;
                replacableString = String.ValueOf(hoTerm.get(replacableString));
            }
            if (String.isNotBlank(replacableString)) {
                // before replacing the merge fields with the value of the replacable string, check if there are special conditions.
                // for ex: we store the terms and lock period in months, but we want to print them as years
                // doing all those special processing below
                if(mergeFieldName.equalsIgnoreCase(ElbConstantsClass.LICENSOR_LOCKIN_PERIOD_MONTHS) || 
                   mergeFieldName.equalsIgnoreCase(ElbConstantsClass.LICENSEE_LOCKIN_PERIOD_MONTHS) || 
                   mergeFieldName.equalsIgnoreCase(ElbConstantsClass.LEASING_TERM_MONTHS) ){
                       
                       Integer numOfMonths = Integer.ValueOf(replacableString);
                       Integer months = Math.mod(numOfMonths,12);
                       if(months != 0){
                           if(numOfMonths/12 != 0)
                               replacableString = String.valueOf(numOfMonths/12 ) + ' years ' + String.ValueOf(months) + ' months';
                           else
                               replacableString = String.ValueOf(months) + ' months';
                       } else if(numOfMonths/12 != 0) {
                           replacableString = String.valueOf(numOfMonths/12 ) + ' years ';
                       } 
                   } else if (mergeFieldName.equalsIgnoreCase(ElbConstantsClass.SEC_DEPOSIT_CALCULATION_TYPE)){
                       
                       if(replacableString.equalsIgnoreCase(ElbConstantsClass.SIMPLE)){
                           replacableString ='There will be an escalation in Security Deposit for the ' + hoTerm.Leasing_Term__c/12 + ' year term with an escalation percentage of '; // + hoTerm.Escalation_Percentage__c;
                       } else if(replacableString.equalsIgnoreCase(ElbConstantsClass.AVG)){
                           replacableString = 'There will not be any escalation in Security Deposit for the ' + hoTerm.Leasing_Term__c/12 + ' year term. Calculated as average of 1st & last year monthly compensation ';
                       }
                       
                   } else if (mergeFieldName.equalsIgnoreCase(ElbConstantsClass.HANDOVER_DATE_PREMISE)){
                       
                       replacableString = (replacableString).substring(0, (replacableString).indexOf(' '));
                       
                   } else if (mergeFieldName.equalsIgnoreCase(ElbConstantsClass.SEC_DEPOSIT)){
                       
                       Decimal amount = Decimal.valueOf(replacableString);
                       replacableString = formatClass.INFormat(amount) + ' ( ' + formatClass.getNumberToWordConvertion(amount) + ' )';
                       
                   }
                replacementString = replacementString.replace(myMatcher.group(), replacableString);
            } else {
                replacementString = replacementString;
            }
            replacableString = '';
        }
        return replacementString;
    }
    public PageReference generate(){
        
        for(String pOption: premiseGroupHTMap.keySet()) {
            Head_Of_Terms__c hoTerm = premiseGroupHTMap.get(pOption);
            hoTerm.Leasing_Term__C = HOT.Leasing_Term__C;
            hoTerm.Carpark_Ratio__c = HOT.Carpark_Ratio__c;
            hoTerm.Rent_escalation_structure__c = HOT.Rent_escalation_structure__c;
            hoTerm.Lock_in_period_in_months__c = HOT.Lock_in_period_in_months__c;
            hoTerm.Rent_per_sq_ft_monthly__c = HOT.Rent_per_sq_ft_monthly__c;
            hoTerm.Security_Deposit_Calculation_Type__c = HOT.Security_Deposit_Calculation_Type__c;
            hoTerm.Security_Deposit_Number_of_months__c = HOT.Security_Deposit_Number_of_months__c;
            hoTerm.Renewal_Terms__c = HOT.Renewal_Terms__c;
            hoTerm.Terms_of_payment_CAM_fee__c = HOT.Terms_of_payment_CAM_fee__c;
            hoTerm.Terms_of_payment_license_fee__c = HOT.Terms_of_payment_license_fee__c;
            hoTerm.Compensation_free_period__c = HOT.Compensation_free_period__c;
            hoTerm.Chareable_Carpark__c = HOT.Chareable_Carpark__c;
            hoTerm.Per_carpark_charge__c = HOT.Per_carpark_charge__c;
            hoTerm.Validity_in_Days__c = HOT.Validity_in_Days__c;
            
        }
        for(String s: premiseGroupMap.keySet()){
            
            List<Term_Item__C> tiList = new List<Term_Item__C>();
            tiList = premiseGroupTermMap.get(s);
            Head_Of_Terms__c hoTerm = premiseGroupHTMap.get(S);
            Decimal totalArea = 0;
            for(Junction_Unit__c u : premiseGroupMap.get(S)) {
                totalArea += u.Carpet_Area_in_Sq_Ft__c;
            }
            if(hoTerm.Carpark_Ratio__c != null){
                Decimal totalCarparks = 0;
                totalCarparks =totalArea/hoTerm.Carpark_Ratio__c;
                totalCarparks = totalCarparks.round(System.RoundingMode.FLOOR);
                hoTerm.Number_of_chargeable_carparks__c = (totalCarparks*hoTerm.Chareable_Carpark__c/100).round(System.RoundingMode.FLOOR);
                hoTerm.Number_of_carparks_included_in_the__c = totalCarparks -hoTerm.Number_of_chargeable_carparks__c;
                hoTerm.Total_Number_of_carparks_1__c = hoTerm.Number_of_chargeable_carparks__c + hoTerm.Number_of_carparks_included_in_the__c;
                carparktable =true;
            }
            if (tiList.size() > 0) {
                for (Term_Item__c term: tiList) {
                    term.Merged_Term_Value__c = findAndReplaceMergeFields(term.Value__c, term, hoTerm);
                    if(term.Header__C.equalsIgnoreCase(ElbConstantsClass.HANDOVER_CONDITION)) {
                        if(String.isNotBlank(hoTerm.handover_condition_custom__c)){
                            term.Merged_Term_Value__c = hoTerm.handover_condition_custom__c;
                        }
                    }
                }
            }
        }
        generated = true;
        return null;
    }
    public pageReference updateData() {
        
        for(String s: premiseGroupMap.keySet()){
            List<Term_Item__C> tiList = new List<Term_Item__C>();
            tiList = premiseGroupTermMap.get(s);
            Head_Of_Terms__c hoTerm = premiseGroupHTMap.get(S);
            if (tiList.size() > 0) {
                for (Term_Item__c term: tiList) {
                    if(String.isBlank(term.customised_term__c))
                        term.Merged_Term_Value__c = findAndReplaceMergeFields(term.Value__c, term, hoTerm);
                    else
                        term.Merged_Term_Value__c = term.customised_term__c;
                    if(term.Header__C.equalsIgnoreCase(ElbConstantsClass.HANDOVER_CONDITION)) {
                        if(String.isNotBlank(hoTerm.handover_condition_custom__c)){
                            term.Merged_Term_Value__c = hoTerm.handover_condition_custom__c;
                        }
                    }
                }
            }
        }
        return null;
        
    }
    
    public PageReference createHOT(){
        List<Head_Of_Terms__c> htList = new List<Head_Of_Terms__c>();
        List<Head_Of_Terms__c> htListnew = new List<Head_Of_Terms__c>();
        Map<String,Id> htListInsertedMap = new Map<String,Id>();
        List<Term_Item__C> termListToInsert = new List<Term_Item__C>();
        List<Junction_Unit__c> uListtoUpdate = new List<Junction_Unit__c>();
        PageReference retPage;
        for(String option: premiseGroupHTMap.keySet()){
            Head_Of_Terms__c hoTerm  = premiseGroupHTMap.get(option);
            hoTerm.Opportunity__c = OptyID;
            hoTerm.Building__c = premiseGroupMap.get(option)[0].Floor__r.Building__c;
            hoTerm.proposed_licensee__c = optyName;
            hoTerm.Termsheet_name__c = premiseGroupMap.get(option)[0].Floor__r.Building__r.Display_Name__c + '-' + 'Premise Option ' + '-' +option;
            htList.add(hoTerm);
        }
        try {
            insert htList;
            htListnew = [select Id, Premise_Group__C from Head_Of_Terms__c where id in :htList];
            for(Head_Of_Terms__c h : htListNew){
                htListInsertedMap.put(h.Premise_Group__c, h.Id);
            }
            for(String s: premiseGroupHTMap.keySet()){
                // for each premise
                // tag the corresponding HOT to the term items
                // tag the HOT to the corresponding units of that premise
                for(Term_Item__C t: premiseGroupTermMap.get(s)) {
                    // creating a fresh copy of that record here 
                    // since we have id value in the existing record
                    // only the terms the user wants to include from the default terms need to be captured
                    if(t.include_term__c) {
                        
                        Term_Item__C t1 = new Term_Item__C();
                        t1.Merged_Term_Value__c = t.Merged_Term_Value__c;
                        t1.include_term__c = t.include_term__c;
                        t1.Header__C = t.Header__C;
                        t1.Reason_for_deviation__c = t.Reason_for_deviation__c;
                        t1.Deviation__c = t.Deviation__c;
                        t1.Value__C = t.Value__C;
                        t1.Sequence__C = t.Sequence__C;
                        t1.Merge_Field_1__c = t.Merge_Field_1__c;
                        t1.Merge_Field_2__c = t.Merge_Field_2__c;
                        t1.Merge_Field_3__c = t.Merge_Field_3__c;
                        t1.Head_Of_Terms__c = htListInsertedMap.get(s);
                        t1.term_text_editable__c = t.term_text_editable__c;
                        termListToInsert.add(t1);
                    }
                }
                for(Junction_Unit__c u : premiseGroupMap.get(s)){
                     u.Head_Of_Terms__c = htListInsertedMap.get(S);
                     uListtoUpdate.add(u);
                }
            }
            
            insert termListToInsert;
            update uListtoUpdate;
            if (Schema.sObjectType.Head_Of_Terms__c.isDeletable()){		//GCP-22
            	delete HOT;    
            }
            String sServerName = ApexPages.currentPage().getHeaders().get(ElbConstantsClass.HOST);
            String optyPage = 'https://'+sServerName+'/'+optyId;
            retPage  = new PageReference(optyPage); 
            retPage.setRedirect(true);
            
        } catch(Exception ex){
            Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'An exception occurred while creating the term sheet:' + ex.getMessage()));
        }
        return retPage;
    }
    
}