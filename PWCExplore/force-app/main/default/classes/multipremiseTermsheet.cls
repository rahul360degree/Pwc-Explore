/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for displaying multiple premise tagged over one visualforce page in an opportunity.
Inputs:        multipremiseTermsheet.vfp, GenerateMultipleTermSheet.vfp
Last Modified: 01/11/2021
Test Class:    
----------------------------------------------------------------------------*/

public class multipremiseTermsheet {
    
    public Boolean isRunError {get;set;}
    public Boolean isApproved {get;set;}
    public Boolean isIpcContact {get;set;}
    
    public string preparedFor {get;set;}
    public string preparedBy{get;set;}
    
    public NumberToWord formatClass {get;set;}
    
    public string amountCompensation{get;set;}
    public string amountSecurityDep{get;set;}
    
    public string wordCompensation{get;set;}
    public string wordSecurityDep{get;set;}
    
    public Boolean printCAMDetails {get;set;}
    public Set<Id> hotWrapperIdSet {get;set;}
    
    
    public List<HEAD_OF_TERMS__c> HOT {get;set;}
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
    public Map<String,List<Billing_Schedule__c>> premiseGroupBillingMap {get;set;}
    public Map<String,Map<String, List<Term_Item__c>>> hotHeaderPremiseTermMap {get;set;}
    
    public List<termWrapper> termWrapperList {get; set;}
    
    public List<Billing_Schedule__c> billingSchList {get;set;}
    public List<BillingWrapper> billingWrapperList {get; set;}
    
    public string hotId;
    public Junction_Unit__c rentalUnit {get;set;}
    public List<HEAD_OF_TERMS__c> headOfTermsList {get;set;}
    public List<Junction_Unit__c> rentalUnitList {get;set;}
    public List<Term_Item__c> termList {get;set;}
    
    public Map<id, Term_Item__c> termMap {get;set;}
    
    public List<HEAD_OF_TERMS__c> hotList{
        get;
        set;
    }
    public List<HOTWrapper> HOTWrapperList{
        get;
        set;
    }
    
    public multipremiseTermsheet(){
        HOTWrapperList = new List<HOTWrapper>();
        optyID = apexPages.currentPage().getParameters().get('id');
        
        
        if (optyID != null) {
            hotList=[select Id,Name,Building__r.Name,Approval_Status__c,Premise_Group__c,
                     CreatedBy.Name, CreatedDate, Termsheet_name__c,Net_usable_area_Area_Sq_ft__c, Master_Record__c
                     From HEAD_OF_TERMS__c where Opportunity__c =:optyID ];
            for(HEAD_OF_TERMS__c  h : hotList){
                HOTWrapper hw = new HOTWrapper();
                hw.hot = h;
                HOTWrapperList.add(hw);           
            }
            List<Junction_Unit__c> unitList = new List<Junction_Unit__c>();
            Map<Id,List<Junction_Unit__c>> UnitHOTMap = new Map<Id,List<Junction_Unit__c>>();
            unitList = [select Name,  Floor__c, Floor__r.Name, Status__c, Opportunity__c, Chargeable_area__c, Area__c, Floor__r.Building__c, Floor__r.Building__r.Name,
                        Floor__r.Building__r.Building_Type__c, Floor__r.Building__r.Building_Configuration__c, Floor__r.Building__r.Project__c,Floor__r.Building__r.Use_of_premises__c,
                        Floor__r.Building__r.Bldg_Status__c, Carpet_Area_in_Sq_Ft__c,  HEAD_OF_TERMS__c,Premise_Group__c, Floor__r.Block__c,Floor__r.Floor_Number__c,
                        Floor__r.Terrace_Floor__c, Floor__r.Building__r.Agreement_Type__c, Floor__r.Building__r.Display_Name__c, 
                        Floor__r.Building__r.Building_View__c, Floor__r.Building__r.Typical__c, Floor__r.Building__r.Title_of_the_HOT__c,Building__c,Building__r.Name,
                        Floor__r.Type_of_premise__c
                        from Junction_Unit__c where Opportunity__c =: OptyID];
            for(Junction_Unit__c u : unitList){
                if(UnitHOTMap.containsKey(u.HEAD_OF_TERMS__c)) {
                    UnitHOTMap.get(u.HEAD_OF_TERMS__c).add(u);
                } else{
                    List<Junction_Unit__c> tempList = new List<Junction_Unit__c>();
                    tempList.add(u);
                    UnitHOTMap.put(u.HEAD_OF_TERMS__c, tempList);
                }
            }
            String premDesc ='';
            
            for(HOTWrapper hw: HOTWrapperList){       
                for(Junction_Unit__c unit : UnitHOTMap.get(hw.hot.Id)){
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
                    if(String.isNotBlank(unit.Floor__r.Block__c) && !(unit.Floor__r.Block__c.equalsIgnoreCase('NA'))) {
                        premDesc += unit.Floor__r.Building__r.Display_Name__c + ',' + unit.Floor__r.Block__c + ',' + suffix + ',';
                    } else {
                        premDesc += unit.Floor__r.Building__r.Display_Name__c +  ',' + suffix +',';
                    }
                }
                hw.premiseDescription = premDesc;
                premDesc ='';
            }
            
        }
    }
    
    public PageReference generateTerms() {
        isRunError = false;
		isIpcContact = false;       
        headOfTermsList = new List<HEAD_OF_TERMS__c>();
        rentalUnitList = new List<Junction_Unit__c>();
        termList = new List<Term_Item__c>();
        termMap = new Map<id, Term_Item__c>();
        termWrapperList = new List<termWrapper>();
        
        hotWrapperIdSet = new Set<Id>();
        
        mergeFieldsMap = new Map < String, List < String >>();
        HoTFieldMap = new  Map < String, HEAD_OF_TERMS__c >();
        colspanMap = new  Map < String, Integer >();
        premiseGroupTermMap = new Map<String,List<Term_Item__C>>();
        premiseGroupBillingMap = new Map<String,List<Billing_Schedule__c>>();
        hotHeaderPremiseTermMap = new Map<String,Map<String, List<Term_Item__c>>>();
        
        unitList = new List < Junction_Unit__c > ();
        premiseGroupMap = new Map<String,List<Junction_Unit__c>>();
        premiseOptionsList = new List<String>();
        premiseOfficeSpaceMap = new Map<String,String>();
        
        billingSchList = new List<Billing_Schedule__c>();
        billingWrapperList = new List<BillingWrapper>();
        
        //HOTWrapper hw = new HOTWrapper();
        
        formatClass = new NumberToWord();
        
        amountCompensation = '';
        amountSecurityDep='';
        
        wordCompensation = '';
        wordSecurityDep = '';
        
        printCAMDetails = false;
        
        for (HOTWrapper wrapper : this.HOTWrapperList) {
            if(wrapper.isSelected == true && wrapper.hot.Master_Record__c == true){
                List<HEAD_OF_TERMS__c> headOfTermsObject = new List<HEAD_OF_TERMS__c>();
                HEAD_OF_TERMS__c headOfTermsLineItem = new HEAD_OF_TERMS__c();
                headOfTermsLineItem.Id = wrapper.hot.Id;
                headOfTermsLineItem.Master_Record__c = true;
                
                headOfTermsObject.add(headOfTermsLineItem);
                
                update headOfTermsObject;
            }
        }
        
        
        for (HOTWrapper wrapper : this.HOTWrapperList) {
            if(wrapper.isSelected == true){
                if (wrapper.hot.Id != null) {
                    hotWrapperIdSet.add(wrapper.hot.Id);
                }
            }
        } 
        HOT = [Select Id, Opportunity__r.Id,Rent_per_sq_ft_monthly__c,Carpark_Ratio__c,
               Rent_escalation_structure__c,Security_Deposit_Number_of_months__c,
               Security_Deposit_Calculation_Type__c, Leasing_Term__C, 
               Lock_in_period_in_months__c, Terms_of_payment_CAM_fee__c, 
               Terms_of_payment_license_fee__c  , Renewal_Terms__c,
               Compensation_free_period__c,Chareable_Carpark__c, Total_Number_of_carparks__c,
               Number_of_carparks_included_in_the__c,Number_of_chargeable_carparks__c,Per_carpark_charge__c,Validity_in_Days__c,
               Premise_Group__c, Approval_Status__c, Proposed_Licensee__c, Net_usable_area_Area_Sq_ft__c, Building__c,
               Building__r.Building_View__c, Building__r.Project__c, Building__r.City__c, Building__r.Location__c,
               Building__r.Display_Name__c, Opportunity__r.Auto_Number__c,
               Opportunity__r.Primary_contact__r.Name, Opportunity__r.IPC_Contact__c, Opportunity__r.IPC_Contact__r.Name,
               Opportunity__r.Original_Account__r.Name, Opportunity__r.Primary_contact__c, Opportunity__r.Primary_contact__r.Salutation,
               Billing_Mismatch__c, Opportunity__r.Company__c, Licensor__c, Opportunity__r.Primary_contact__r.FirstName,
               Opportunity__r.IPC_Contact__r.FirstName
               from HEAD_OF_TERMS__c where Id IN: hotWrapperIdSet];
        OptyID = HoT[0].Opportunity__r.Id;
        optyList = [select id, Name,AccountId,Account.Name,IPC__c,IPC__r.Name, Auto_Number__c,IPC_Contact__r.Name, Primary_contact__r.Name, Company__c
                    from Opportunity where id =: OptyID];
        
        if(!optyList.isEmpty() && optyList[0].IPC_Contact__c != null && optyList[0].Primary_contact__c == null){
               isIpcContact = true;
           }
        
        if(!HOT.isEmpty()){   
            for(HEAD_OF_TERMS__c hot: HOT){
                if(hot.Approval_Status__c == ElbConstantsClass.APPROVED){
                    isApproved = true;
                }
            }
        }
        
        List<Term_Item__C> tList = new List<Term_Item__C>();
        List<Term_Item__C> tListNew = new List<Term_Item__C>();
        
        tList = [Select id, Name, Sequence__C, Header__C, term_text_editable__c, Include_Term__c, Value__C, Merge_Field_1__c, Merge_Field_2__c, Merge_Field_3__c,
                 HEAD_OF_TERMS__c, Merged_Term_Value__c, HEAD_OF_TERMS__r.handover_condition__c
                 from Term_Item__c 
                 where HEAD_OF_TERMS__c IN: hotWrapperIdSet 
                 order by Sequence__c];
        
        
        for(Term_Item__C term1 : tList){
            for(HEAD_OF_TERMS__c hot: HOT){
                if(term1.HEAD_OF_TERMS__c == hot.Id){
                    tListNew.add(term1);
                    if(!hotHeaderPremiseTermMap.containsKey(term1.Header__c)){
                        List<Term_Item__C> newList = new List<Term_Item__C>();
                        newList.add(term1);
                        Map<String,List<Term_Item__C>> newMap= new Map<String,List<Term_Item__C>>();
                        newMap.put(hot.Premise_Group__c, newList);
                        hotHeaderPremiseTermMap.put(term1.Header__c, newMap);
                    } else {
                        Map<String,List<Term_Item__C>> getNewMap = new Map<String,List<Term_Item__C>>();
                        getNewMap = hotHeaderPremiseTermMap.get(term1.Header__c);
                        if(!getNewMap.containsKey(hot.Premise_Group__c)) {
                            List<Term_Item__C> newList = new List<Term_Item__C>();
                            newList.add(term1);
                            getNewMap.put(hot.Premise_Group__c, newList);
                        } else {
                            getNewMap.get(hot.Premise_Group__c).add(term1);
                        }
                        hotHeaderPremiseTermMap.get(term1.Header__c).putAll(getNewMap);
                    }
                }
            }
        }
        
        termList = [Select Id, Name, HEAD_OF_TERMS__c, Header__c, Merged_Term_Value__c, Value__c, Merge_Field_1__c, Deviation__c,
                    HEAD_OF_TERMS__r.Master_Record__c, Reason_for_deviation__c, Negotiation_Details__c, Negotiation_Log__c
                    from Term_Item__c
                    where HEAD_OF_TERMS__c IN: hotWrapperIdSet and HEAD_OF_TERMS__r.Master_Record__c =: true
                    order by sequence__c ];
        
        if(termList.isEmpty()){
            isRunError = true;
        }
        else{
            Integer i = 1;
            for(Term_Item__c term: termList){  
                List<Term_Item__c> teList = new List<Term_Item__c>();
                teList.add(term);
                if(term.Header__c == ElbConstantsClass.CAM_CHARGES){
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, false, premiseGroupTermMap, premiseGroupBillingMap, hotHeaderPremiseTermMap));
                    printCAMDetails = true;
                }
                else if(term.Header__c == ElbConstantsClass.OFFERED_FLOOR_AREA){
                    termWrapperList.add(new termWrapper(i, teList, false, true, false, false, premiseGroupTermMap, premiseGroupBillingMap, hotHeaderPremiseTermMap));
                    //printOfficeSpaceDetails = true;
                }
                else if(term.Header__c == ElbConstantsClass.MONTHLY_COMP_FEE){
                    termWrapperList.add(new termWrapper(i, teList, false, false, true, false, premiseGroupTermMap, premiseGroupBillingMap, hotHeaderPremiseTermMap));
                }
                else if(term.Header__c == ElbConstantsClass.SECURITY_DEPOSIT){
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, true, premiseGroupTermMap, premiseGroupBillingMap, hotHeaderPremiseTermMap));
                }
                else{
                    termWrapperList.add(new termWrapper(i, teList, false, false, false, false, premiseGroupTermMap, premiseGroupBillingMap, hotHeaderPremiseTermMap));
                }
                i += 1;
            }
        }
        
        //system.debug('print hotheaderterm map'+((hotHeaderPremiseTermMap.get('Car parking')).get('A')).size());
        PageReference np = new PageReference('/apex/GenerateMultipleTermSheet');
        np.setRedirect(false);
        return np; 
    }
    
    public class HOTWrapper {
        public Boolean isSelected {get; set;}
        public Head_Of_Terms__c hot {get; set;}
        public String premiseDescription {get;set;}
        public Boolean isRadioSelected {get; set;}
        
        public HOTWrapper(){
            this.isSelected = false;
            this.hot  = new HEAD_OF_TERMS__c();
        }
    }
    
    public class termWrapper{
        public Integer termSequence {get;set;}
        public Boolean termItemBool {get;set;}
        public Set<String> keySet {get;set;}
        public Boolean printOfficeSpaceDetails {get;set;}
        public Boolean printMonCompDetails {get;set;}
        public Boolean printSecurityDeopsitDetails {get;set;}
        public List<Term_Item__c> termItemObject {get;set;}
        public Map<String,List<Term_Item__C>> premiseGroupTermMap = new Map<String,List<Term_Item__C>>();
        public Map<String,List<Billing_Schedule__c>> premiseGroupBillingMap = new Map<String,List<Billing_Schedule__c>>();
        public Map<String,Map<String, List<Term_Item__c>>> hotHeaderPremiseTermMap = new Map<String,Map<String, List<Term_Item__c>>>();
        
        public termWrapper(Integer termSequence, List<Term_Item__c> termItemObject, Boolean termItemBool, Boolean printOfficeSpaceDetails,
                           Boolean printMonCompDetails, Boolean printSecurityDeopsitDetails, Map<String,List<Term_Item__C>> premiseGroupTermMap,
                           Map<String,List<Billing_Schedule__c>> premiseGroupBillingMap, Map<String,Map<String, List<Term_Item__c>>> hotHeaderPremiseTermMap){
                               this.termSequence = termSequence;
                               this.termItemObject = termItemObject;  
                               this.termItemBool = termItemBool;
                               this.printOfficeSpaceDetails = printOfficeSpaceDetails;
                               this.printMonCompDetails = printMonCompDetails;
                               this.printSecurityDeopsitDetails = printSecurityDeopsitDetails;
                               this.keySet = premiseGroupTermMap.keySet();
                               this.premiseGroupTermMap = premiseGroupTermMap;
                               this.premiseGroupBillingMap = premiseGroupBillingMap;
                               this.hotHeaderPremiseTermMap = hotHeaderPremiseTermMap;
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