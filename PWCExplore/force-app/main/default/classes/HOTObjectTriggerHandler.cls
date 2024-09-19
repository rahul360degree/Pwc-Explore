/*------------------------------------------------------------------------
Author:        Saurabh Mehta, Jayasurya G
File Name:     HOTObjectTriggerHandler.cls
Company:       Stetig, Stetig
Description:   Class on Head of Terms for creating record in premise traction with different event type base on HOT dates, Updating end date of Licence & Licence Abstarction
Inputs:        NA
Last Modified: 01/02/2022
Test Class:    
----------------------------------------------------------------------------*/
public class HOTObjectTriggerHandler{
    
    // creating record for premise traction when LOI date updates
    public static void createPTonLOI(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        Set<Id> setLOIupdatedHotRec = new Set<Id>();
        
        for(HEAD_OF_TERMS__c hotobj : newHOTList) {
            
            if(hotobj.LOI_L_L_Execution_Date__c !=null && hotobj.LOI_L_L_Execution_Date__c != oldHotMap.get(hotobj.Id).LOI_L_L_Execution_Date__c) {
                setLOIupdatedHotRec.add(hotobj.Id);
            }
        }
        List<Premise_Tracking__c> newPrimeTractionlist = new List<Premise_Tracking__c>();
        
        if(!setLOIupdatedHotRec.isEmpty()) {
            
            List<Junction_Unit__c> lstRentalUnit = [Select HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.LOI_L_L_Execution_Date__c,Floor__c From Junction_Unit__c WHERE HEAD_OF_TERMS__c IN :setLOIupdatedHotRec LIMIT 20000];
            
            for(Junction_Unit__c ru : lstRentalUnit) {
                
                //Premise Traction record creation with event = LOI
                Premise_Tracking__c pt = new Premise_Tracking__c();
                pt.Leasable_Unit__c = ru.Floor__c;
                pt.Tracking_Date__c = ru.HEAD_OF_TERMS__r.LOI_L_L_Execution_Date__c;
                pt.Event__c = Label.LOI_Event;
                newPrimeTractionlist.add(pt);
            }
        }
        if(!newPrimeTractionlist.isEmpty()) {
            try{
                insert newPrimeTractionlist;
            }catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }  
        }       
    }
    
    // creating record for premise traction when LNL date updates
    public static void createPTonLNL(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        
        Set<Id> setLOIupdatedHotRecs = new Set<Id>();
        
        for(HEAD_OF_TERMS__c hotobjs : newHOTList) {
            
            if(hotobjs.L_L_Signing_Date__c !=null && hotobjs.L_L_Signing_Date__c != oldHotMap.get(hotobjs.Id).L_L_Signing_Date__c) {
                setLOIupdatedHotRecs.add(hotobjs.Id);
                
            }
        }
        List<Premise_Tracking__c> newPrimesTractionlist = new List<Premise_Tracking__c>();
        
        if(!setLOIupdatedHotRecs.isEmpty()) {
            
            List<Junction_Unit__c> lstRentalUnits = [Select HEAD_OF_TERMS__c,HEAD_OF_TERMS__r.L_L_Signing_Date__c,Floor__c From Junction_Unit__c WHERE HEAD_OF_TERMS__c IN :setLOIupdatedHotRecs LIMIT 20000];
            
            for(Junction_Unit__c rus : lstRentalUnits) {
                
                // creating premise traction record for event = Occupied
                Premise_Tracking__c pto = new Premise_Tracking__c();
                pto.Leasable_Unit__c = rus.Floor__c;
                pto.Tracking_Date__c = rus.HEAD_OF_TERMS__r.L_L_Signing_Date__c;
                pto.Event__c = Label.Set_Occupied;
                newPrimesTractionlist.add(pto);
                
                // creating premise traction record for event = Agreement
                Premise_Tracking__c pta = new Premise_Tracking__c();
                pta.Leasable_Unit__c = rus.Floor__c;
                pta.Tracking_Date__c = rus.HEAD_OF_TERMS__r.L_L_Signing_Date__c;
                pta.Event__c = Label.Set_Agreement;
                newPrimesTractionlist.add(pta);
                
                // updating rental unit status to leased 
                rus.Status__c = Label.Set_Leased;
            }
            if(!lstRentalUnits.isEmpty()){
                try{
                    update lstRentalUnits;
                }catch(DmlException e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }  
            }
        }
        
        if(!newPrimesTractionlist.isEmpty()) {
            try{
                insert newPrimesTractionlist;
            }catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }  
        }
    }
    
    // updating end date of Lience in HOT
    public static void updateLienceEndDateOnRentalUnit(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        Set<Id> setHotObjId = new Set<Id>();
        
        List<Premise_Tracking__c> newPrimesTractionlist = new List<Premise_Tracking__c>();
        
        for(HEAD_OF_TERMS__c hotobj : newHOTList) {
            
            if(hotobj.Licence_End_Date__c != null && hotobj.Licence_End_Date__c != oldHotMap.get(hotobj.Id).Licence_End_Date__c) {
                setHotObjId.add(hotobj.Id);
            }
        }   
        if(!setHotObjId.isEmpty()) {
            
            List<Junction_Unit__c> lstRentalUnit = [Select id, name, floor__c, End_Date__c, Start_Date__c, HEAD_OF_TERMS__r.Licence_commencement_date__c, HEAD_OF_TERMS__r.Licence_End_Date__c, Leasing_Status__c, HEAD_OF_TERMS__c From Junction_Unit__c WHERE HEAD_OF_TERMS__c IN :setHotObjId LIMIT 20000];
            
            for(Junction_Unit__c ru : lstRentalUnit){
                ru.End_Date__c = ru.HEAD_OF_TERMS__r.Licence_End_Date__c;
                ru.Start_Date__c = ru.HEAD_OF_TERMS__r.Licence_commencement_date__c;	
                
                // create premise traction record for event Vacant
                Premise_Tracking__c pto = new Premise_Tracking__c();
                pto.Leasable_Unit__c = ru.Floor__c;
                pto.Tracking_Date__c = Date.TODAY();
                pto.Event__c = Label.Set_Vacant;
                newPrimesTractionlist.add(pto);
            }			
            try{
                update lstRentalUnit;
                insert newPrimesTractionlist;
            }catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }  
        }
    }
    
    // Method Is Used TO Update the Licence abstction in HOT
    public static void updateLicenseAbstract(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        Set<Id> setHotObjId = new Set<Id>();
        
        for(HEAD_OF_TERMS__c hotobj : newHOTList) { 
            if(hotobj.Lease_Abstract__c != oldHotMap.get(hotobj.Id).Lease_Abstract__c) {
                setHotObjId.add(hotobj.Id);
            }
        }   
        if(!setHotObjId.isEmpty()) {
            List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Licence_commencement_date__c, License_fees_Commencement_date__c, Licence_End_Date__c, 
                                              LOI_L_L_Execution_Date__c, L_L_Signing_Date__c
                                              From HEAD_OF_TERMS__c 
                                              Where Id IN: setHotObjId LIMIT 20000];
            
            if(!hotList.isEmpty()){
                for(HEAD_OF_TERMS__c hot: hotList){
                    if(hot.Licence_commencement_date__c == NULL ){
                        hot.addError(Label.enter_licecnse_comencement_date_over_head_of_terms);
                    }
                    else if(hot.License_fees_Commencement_date__c == NULL ){
                        hot.addError(Label.enter_licecnse_fee_commencement_date_over_head_of_terms);
                    }
                    else if(hot.Licence_End_Date__c == NULL ){
                        hot.addError(Label.enter_license_end_date);
                    }
                    //else if(hot.LOI_L_L_Execution_Date__c == NULL ){
                        //hot.addError(Label.Enter_LOI_Execution_Date);
                    //}
                    else if(hot.L_L_Signing_Date__c == NULL ){
                        hot.addError(Label.Enter_LL_Signing_Date);
                    }
                }
            }
            
        }
    }
    
    public static map < String, Id > fetchRecordTypes(String ObjApiName) {
        map < String, Id > rtMap = new map < String, Id > ();
        
        for (RecordType rt: [select Id, Name, DeveloperName from RecordType
                             where sObjectType =: ObjApiName
                            ]) {
                                
                                rtMap.put(rt.DeveloperName, rt.Id);
                            }
        
        return rtMap;
    }  
    
    // Method is to check if the unit is not under lease
    public static void unitUnderLeaseCheck(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        Set<Id> setHotObjId = new Set<Id>();
        Map<Id, List<Junction_Unit__c>> hotPremiseMap = new Map<Id, List<Junction_Unit__c>>();
        Integer churnArea;
        Integer vacantArea;
        
        for(HEAD_OF_TERMS__c hotobj : newHOTList) { 
            if(hotobj.Lease_Abstract__c != oldHotMap.get(hotobj.Id).Lease_Abstract__c && hotobj.Lease_Abstract__c != true) {
                setHotObjId.add(hotobj.Id);
            }
        }   
        if(!setHotObjId.isEmpty()) {            
            List<Junction_Unit__c> premiseList = [Select Id, Name, HEAD_OF_TERMS__c, Floor__c, Floor__r.Expected_Churn_Sq_ft__c, Floor__r.Vacant_Area_Sq_ft__c
                                                  From Junction_Unit__c 
                                                  Where HEAD_OF_TERMS__c IN: setHotObjId LIMIT 1000];
            
            if(!newHOTList.isEmpty() && !premiseList.isEmpty()){
                for(HEAD_OF_TERMS__c hot: newHOTList){
                    churnArea = 0;
                    vacantArea = 0;
                    for(Junction_Unit__c premise: premiseList){
                        if(hot.Id == premise.HEAD_OF_TERMS__c){
                            churnArea = churnArea + Integer.ValueOf(premise.Floor__r.Expected_Churn_Sq_ft__c);
                            vacantArea = vacantArea + Integer.ValueOf(premise.Floor__r.Vacant_Area_Sq_ft__c);
                        }
                    }
                    
                    if(hot.Net_usable_area_Area_Sq_ft__c > vacantArea){
                        hot.addError('Area not available for Lease. Please check again later.');             
                    }
                }
            }
            
        }
    }
    
    //hides the premise tagging button over opportunity record after head of term is marked as final
    public static void hidePremiseAction(List<HEAD_OF_TERMS__c> newHOTList, Map<id,HEAD_OF_TERMS__c> oldHotMap){
        Set<Id> setHotObjId = new Set<Id>();
        Set<Id> setTrueOppObjId = new Set<Id>();
        Set<Id> setFalseOppObjId = new Set<Id>();
        
        Map < String, Id > recordTypes = new Map < String, Id > ();
        
        recordTypes = fetchRecordTypes(ElbConstantsClass.OPPORTUNITY_API);
        
        for(HEAD_OF_TERMS__c hotobj : newHOTList) { 
            if(hotobj.Mark_as_final__c != oldHotMap.get(hotobj.Id).Mark_as_final__c) {
                setHotObjId.add(hotobj.Id);
            }
        }   
        if(!setHotObjId.isEmpty()) {
            List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Mark_as_final__c, Opportunity__r.RecordTypeId
                                              From HEAD_OF_TERMS__c 
                                              Where Id IN: setHotObjId LIMIT 100];
            
            if(!hotList.isEmpty()){
                for(HEAD_OF_TERMS__c hot: hotList){
                    if(hot.Mark_as_final__c == true){
                        setTrueOppObjId.add(hot.Opportunity__c);
                    }
                    else if(hot.Mark_as_final__c == false){
                        setFalseOppObjId.add(hot.Opportunity__c);
                    } 
                }
            }
            
            if(!setTrueOppObjId.isEmpty()){
                List<Opportunity> oppObject = new List<Opportunity>();
                
                List<Opportunity> oppList = [Select Id, Name, RecordTypeId
                                             From Opportunity 
                                             Where Id IN: setTrueOppObjId LIMIT 100];
                
                if(!oppList.isEmpty()){
                    for(Opportunity opp: oppList){
                        opp.RecordTypeId = recordTypes.get(ElbConstantsClass.OPPORTUNITY_RECORD_TYPE_FINAL_LEASING);
                        oppObject.add(opp);
                    }
                    try {
                        update oppObject;
                    } catch(DmlException e) {
                        System.debug('The following exception has occurred while updating oppObject: ' + e.getMessage());
                    }
                    
                }
            }
            
            if(!setFalseOppObjId.isEmpty()){
                List<Opportunity> oppObject = new List<Opportunity>();
                
                List<Opportunity> oppList = [Select Id, Name, RecordTypeId
                                             From Opportunity 
                                             Where Id IN: setFalseOppObjId LIMIT 100];
                
                if(!oppList.isEmpty()){
                    for(Opportunity opp: oppList){
                        opp.RecordTypeId = recordTypes.get(ElbConstantsClass.OPPORTUNITY_RECORD_TYPE_LEASING); 
                        oppObject.add(opp);
                    }
                    
                    try {
                        update oppObject;
                    } catch(DmlException e) {
                        System.debug('The following exception has occurred while updating oppObject: ' + e.getMessage());
                    }
                }
            }
        }
    }
}