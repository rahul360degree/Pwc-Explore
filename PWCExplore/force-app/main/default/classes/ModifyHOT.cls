/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for modifying head of terms for deviation or changes in amount
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class ModifyHOT {
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
    
    //method to modify head of terms
    public ModifyHOT() {
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
        generated = true;
        carparktable = true;
        
        if (ApexPages.currentPage().getParameters().get('HoTID') != null && ApexPages.currentPage().getParameters().get('HoTID') != '') {
            HoTID = apexPages.currentPage().getParameters().get('HoTID');
            
            if (HoTID != null) {
                HOT = [Select Id, Opportunity__r.Id,Rent_per_sq_ft_monthly__c,Carpark_Ratio__c,
                       Rent_escalation_structure__c,Security_Deposit_Number_of_months__c,
                       Security_Deposit_Calculation_Type__c, Leasing_Term__C, Handover_date_of_Premises__c,Handover_condition_custom__c,
                       Lock_in_period_in_months__c, Terms_of_payment_CAM_fee__c, Security_Deposit__c,Valid_Till_Date__c,
                       Terms_of_payment_license_fee__c	, Renewal_Terms__c,Handover_condition__c,Total_Number_of_carparks_1__c,
                       Compensation_free_period__c,Chareable_Carpark__c, Total_Number_of_carparks__c,Monthly_Compensation_Fee_Clause__c,
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
                                premiseGroupMap.put(unit.Premise_Group__C,tempList);
                                premiseOptionsList.add(unit.Premise_Group__C);
                                premiseOfficeSpaceMap.put(unit.Premise_Group__C, premDesc);
                            }
                        }
                    }
                    String type = ElbConstantsClass.HEAD_OF_TERMS_API;
                    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                    Schema.SObjectType HoTschema = schemaMap.get(type);
                    Map<String, Schema.SObjectField> fieldMap = HoTschema.getDescribe().fields.getMap();
                    
                    for (String fieldName: fieldMap.keySet()) {
                        //   System.debug('##Field API Name='+fieldName);
                        fieldLabelMap.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
                    }
                    
                    // merge field value under each term
                    mergeFieldsMap = new Map < String, List < String >> ();
                    // term Id to Term Record Mapping
                    HoTFieldMap = new Map < String, HEAD_OF_TERMS__c > ();
                    List<Term_Item__C> tList = new List<Term_Item__C>();
                    
                    colspanMap = new Map<String,Integer>();
                    tList = [Select id, Name, Sequence__C, Header__C, term_text_editable__c, Merged_Term_Value__c,
                             Include_Term__c, Value__C, Merge_Field_1__c, Merge_Field_2__c, Merge_Field_3__c, 
                             customised_term__c,Deviation__c,Reason_for_deviation__c,key__c
                             from Term_Item__C where Head_Of_Terms__c =:HoTID order by Sequence__C];
                    Map<String,Id> recordTypes = new Map<String,Id>();
                    Utility u = new Utility();
                    recordTypes = u.fetchRecordTypes(ElbConstantsClass.HEAD_OF_TERMS_API);
                    for(String option: premiseGroupMap.keySet()) {
                        
                        premiseGroupTermMap.put(option,tList);
                        premiseGroupHTMap.put(option,HOT);
                        
                        if (tList.size() > 0) {
                            for (Term_Item__c term: tList) {
                                term.key__c = term.Id + option;
                                
                                HoTFieldMap.put(term.key__c, HOT);
                                List < String > tempList = new List < String > ();
                                mergeFieldsMap.put(term.key__c, tempList);
                                HoTFieldMap.put(term.key__c, HOT);
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
    public string findAndReplaceMergeFields(String fieldValue, Term_Item__C ti, Head_Of_Terms__c ht1) {
        Pattern p = Pattern.compile(ElbConstantsClass.PATTERN);
        formatClass = new NumberToWord();
        matcher myMatcher = p.matcher(ti.Value__c);
        String replacementString = ti.Value__c;
        String replacableString = '';
        while (myMatcher.find()) {
            
            String mergeFieldName = myMatcher.group();
            
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M1)) {
                replacableString = ti.Merge_Field_1__c;
                mergeFieldName = replacableString;
                
                replacableString = String.ValueOf(ht1.get(replacableString));
                
            }
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M2)) {
                replacableString = ti.Merge_Field_2__c;
                mergeFieldName = replacableString;
                replacableString = String.ValueOf(ht1.get(replacableString));
            }
            if (myMatcher.group().equalsIgnoreCase(ElbConstantsClass.PATTERN_M3)) {
                replacableString = ti.Merge_Field_3__c;
                mergeFieldName = replacableString;
                replacableString = String.ValueOf(ht1.get(replacableString));
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
                           replacableString ='There will be an escalation in Security Deposit for the ' + ht1.Leasing_Term__c/12 + ' year term with an escalation percentage of '; // + hoTerm.Escalation_Percentage__c;
                       } else if(replacableString.equalsIgnoreCase(ElbConstantsClass.AVG)){
                           replacableString = 'There will not be any escalation in Security Deposit for the ' + ht1.Leasing_Term__c/12 + ' year term. Calculated as average of 1st & last year monthly compensation ';
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
    
    public pageReference updateData() {
        
        for(String s: premiseGroupMap.keySet()){
            List<Term_Item__C> tList = premiseGroupTermMap.get(s);
            
            if (tList.size() > 0) {
                for (Term_Item__c term: tList) {
                    if(String.isBlank(term.customised_term__c))
                        term.Merged_Term_Value__c = findAndReplaceMergeFields(term.Value__c, term, HOT);
                    else
                        term.Merged_Term_Value__c = term.customised_term__c;
                    if(term.Header__C.equalsIgnoreCase(ElbConstantsClass.HANDOVER_CONDITION)) {
                        if(String.isNotBlank(HOT.handover_condition_custom__c)){
                            term.Merged_Term_Value__c = HOT.handover_condition_custom__c;
                        }
                    }
                }
            }
        }
        return null;
        
    }
    public PageReference modifyHOT(){
        PageReference retPage;
        try {
            update HOT;
            List<Term_Item__C> tList = new List<Term_Item__C>();
            List<Term_Item__C> tListUpdate = new List<Term_Item__C>();
            List<Term_Item__C> tListDelete = new List<Term_Item__C>();
            
            for(String s: premiseGroupMap.keySet()){
                tList = premiseGroupTermMap.get(s);
            }
            for(Term_Item__C t: tList){
                if(t.include_term__c){
                    tListupdate.add(t);
                } else {
                    tListdelete.add(t);
                }
            }
            update tListupdate;
            if (Schema.sObjectType.Term_Item__C.isDeletable()){		//GCP-22
                delete tListdelete;
            }
            
            String sServerName = ApexPages.currentPage().getHeaders().get(ElbConstantsClass.HOST);
            String optyPage = 'https://'+sServerName+'/'+HOTID;
            retPage  = new PageReference(optyPage); 
            retPage.setRedirect(true);
            
        } catch(Exception ex){
            Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'An exception occurred while creating the term sheet:' + ex.getMessage()));
        }
        return retPage;
    }
}