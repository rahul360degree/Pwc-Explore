/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for tagging premise over a opportunity.
Inputs:        leasingProperty.vfp
Last Modified: 19/10/2021
Test Class:    
----------------------------------------------------------------------------*/
public with sharing class SearchTagPremise {
    public Opportunity objectOpp {
        get;
        set;
    }
    public List < Floor__c > Floorlist {
        get;
        set;
    }
    public List < Floor__c > SelectedFloorlist {
        get;
        set;
    }
    public List < Opportunity > optyList {
        get;
        set;
    }
    public Id optyId {
        get;
        set;
    }
    public Boolean flag {
        get;
        set;
    }
    
    
    public Boolean error1 {
        get;
        set;
    }
    public Boolean error2 {
        get;
        set;
    }
    public Boolean error3 {
        get;
        set;
    }
    public Project_Unit__c objectPro {
        get;
        set;
    }
    public Boolean fullyVacant {
        get;
        set;
    }
    public Boolean partlyVacant {
        get;
        set;
    }
    public Boolean churnExpected {
        get;
        set;
    }
    public Boolean leasedOut {
        get;
        set;
    }
    public String selectedVal {
        get;
        set;
    }
    public Boolean fullFloor {
        get;
        set;
    }
    public Decimal FromRange {
        get;
        set;
    }
    public Decimal ToRange {
        get;
        set;
    }
    public string selectedAsset {get;set;}
    public string selectedLocation {get;set;}
    public string selectedProject{get;set;}
    public string selectedBuilding{get;set;}
    public string queryString {
        get;
        set;
    }
    public Junction_Unit__c dummyUnit {
        get;
        set;
    }
    
    public List < String > premiseOptionsList {
        get;
        set;
    }
    public List<wrapperClass> wrapList {get; set;}
    public List<wrapperClass> wrapListSelected {get; set;}
    public wrapperClass selectedWarpperNew {get; set;}
    public Map<String,  List<wrapperClass>> premiseOptions {get;set;}
    
    public List < SelectOption > getProjects {
        get {
            List < SelectOption > optns = new List < Selectoption > ();
            List <  Project_Unit__c > queryResult = new List <  Project_Unit__c > ();
            Map < String, List <  Project_Unit__c > > queryResultMap = new Map < String, List <  Project_Unit__c > > ();//Field__c includes (:variable)
            
            
            // queryResult = [Select Project__c, Use_of_premises__c, Location__c from Project_Unit__c where Use_of_premises__c INCLUDES(: objectPro.Use_of_premises__c) and Location__c =: objectPro.Location__c];
            String locationClause = '';
            String usesofpremisesClause = '';
            
            if (objectPro.Location__c != null && objectPro.Use_of_premises__c != null) {
                locationClause = ' WHERE Location__c = \'' + objectPro.Location__c + '\'';
                System.debug('locationClause: ' + locationClause);
                
                //String[] assetTypes = objectPro.Use_of_premises__c.split(';');
                List <String> assetTypes = objectPro.Use_of_premises__c.split(';');
                usesofpremisesClause = ' AND Use_of_premises__c INCLUDES (\'' + String.join(assetTypes, '\',\'') + '\')';
                System.debug('usesofpremisesClause: ' + usesofpremisesClause);
            }
            
            String stringqueryResult = 'SELECT Project__c, Use_of_premises__c, Location__c FROM Project_Unit__c ' + locationClause + usesofpremisesClause;
            queryResult = Database.query(stringqueryResult);
            
            System.debug('queryResult: ' + queryResult);
            
            
            
            
            optns.add(new SelectOption('','Select a Project'));
            for (Project_Unit__c obj: queryResult) {
                if(obj.Project__c != null){
                    if(!queryResultMap.containsKey(obj.Project__c)){
                        List<Project_Unit__c> newList = new List<Project_Unit__c>();
                        newList.add(obj);
                        queryResultMap.put(obj.Project__c, newList);
                        optns.add(new SelectOption(obj.Project__c,obj.Project__c));
                    }
                    else{
                        List<Project_Unit__c> newList = queryResultMap.get(obj.Project__c);
                        queryResultMap.put(obj.Project__c, newList);
                    }
                } 
            }
            return optns;
        }
        set;
    } 
    public List < SelectOption > getBuildings {
        get {
            List < SelectOption > optnsB = new List < Selectoption > ();
            List <  Project_Unit__c > querybuilding = new List <  Project_Unit__c > ();
           
           // querybuilding = [Select Name from Project_Unit__c where Project__c =:selectedProject AND Use_of_premises__c INCLUDES (: objectPro.Use_of_premises__c) and Location__c =: objectPro.Location__c];
           
            String locationClause = '';
            String usesofpremisesClause = '';
            String ProjectClause = '';

            if (objectPro.Location__c != null && objectPro.Use_of_premises__c != null && selectedProject !=null ) {
                locationClause = ' WHERE Location__c = \'' + objectPro.Location__c + '\'';
                System.debug('locationClause: ' + locationClause);
                
                 ProjectClause = 'AND  Project__c  = \'' + selectedProject + '\'';
                System.debug('ProjectClause: ' + ProjectClause);
                
                String[] assetTypes = objectPro.Use_of_premises__c.split(';');
                usesofpremisesClause = ' AND Use_of_premises__c INCLUDES (\'' + String.join(assetTypes, '\',\'') + '\')';
                System.debug('usesofpremisesClause: ' + usesofpremisesClause);
            }
            
            String stringquerybuilding = 'SELECT Name,Project__c, Use_of_premises__c, Location__c FROM Project_Unit__c ' + locationClause + usesofpremisesClause+ProjectClause;
            querybuilding = Database.query(stringquerybuilding);
             system.debug('querybuilding++--'+querybuilding);
            
            
            optnsB.add(new SelectOption('','Select a building'));
            for (Project_Unit__c obj: querybuilding) {
                //optns.add(new SelectOption(obj.Project__c));
                optnsB.add(new SelectOption(obj.Name,obj.Name));
            }
            return optnsB;
        }
        set;
    }
    
    public SearchTagPremise() {
        optyId = ApexPages.CurrentPage().getParameters().get('id');
        objectOpp = new Opportunity();
        objectPro = new Project_Unit__c();
        Floorlist = new List < Floor__c > ();
        SelectedFloorlist = new List < Floor__c > ();
        premiseOptions = new Map<String,  List<wrapperClass>>();
        
        premiseOptionsList = new List<String>();
        flag = false;
        error1 = false;
        error2 = false;
        FromRange = null;
        ToRange = null;
        fullyVacant = false;
        partlyVacant = false;
        churnExpected = false;
        leasedOut = false;
        dummyUnit = new Junction_Unit__c();
        
        if (ApexPages.currentPage().getParameters().get('optyId') != null && ApexPages.currentPage().getParameters().get('optyId') != '') {
            optyId = ApexPages.currentPage().getParameters().get('optyId');
        }
    }
    public void Search() {
        fullFloor = false;
        error1 = false;
        error2 = false;
        String Location = objectPro.Location__c;
        String AssetType =objectPro.Use_of_premises__c;
        system.debug('AssetType+__'+AssetType);
        Boolean isSelected = false;
        String neededArea = '';
        wrapList = new List<wrapperClass>();
        List<String> statusList = new List<String>();
        
        
        //   List<String> selectedOptions = AssetType.split(';'); 
        //   system.debug('selectedOptions++'+selectedOptions);
        List<String> selectedOptions = new List<String>();
        if (AssetType != null) {
            selectedOptions = AssetType.split(';');
            System.debug('selectedOptions++' + selectedOptions);
        } 
        
        Map<String, String> assetTypeMap = new Map<String, String>();
        assetTypeMap.put('Retail Space', 'RT');
        assetTypeMap.put('Office Space', 'OF');
        assetTypeMap.put('Land Area', 'LD');
        assetTypeMap.put('Residential', 'RS');
        assetTypeMap.put('Cell Site', 'CS');
        assetTypeMap.put('ATM', 'AT');
        assetTypeMap.put('Others', 'OT');
        assetTypeMap.put('Industrial', 'IN');
        assetTypeMap.put('Storage space', 'ST');
        
        
        List<String> selectedCodes = new List<String>();
        
        
        for (String option : selectedOptions) {
            if (assetTypeMap.containsKey(option)) {
                selectedCodes.add(assetTypeMap.get(option));
            }
        }
        System.debug('selectedCodes++'+selectedCodes);
        
        
        
        String likeNameCases = '';
        for (Integer i = 0; i < selectedCodes.size(); i++) {
            if (i != 0) {
                likeNameCases += 'OR ';
            }
            likeNameCases += '( Name LIKE \'' + selectedCodes[i] + '%\')';
        }
        System.debug('likeNameCases: ' + likeNameCases);
        
        queryString = 'Select Id, Name,Building__r.Name,Building__r.Project__c,Building__r.Use_of_premises__c,Vacant_Area_Sq_ft__c, Leased_Chargeable_Area__c,Blocked_Chargeable_Area__c, Total_Carpet_Area_Sq_ft__c,Status__c, Asset_Code__c, Expected_Churn_Sq_ft__c from Floor__c WHERE ( ' +likeNameCases  + ') AND  Building__r.Location__c LIKE \'' + Location + '%\'';
        system.debug('queryString:'+queryString);
        if(String.isNotBlank(objectPro.Location__c) && String.isNotBlank(AssetType)) {
            if(String.isNotBlank(selectedProject)){
                // add project filter to the query
                //String ProjectName = selectedProject;
                //queryString = queryString +  ' and Building__r.Project__c LIKE \'' + ProjectName + '%\'';
                String ProjectName = selectedProject;
                String searchString = ProjectName + '%';   //chenged by pankaj for GCP-22             
                queryString +=  ' and Building__r.Project__c LIKE \'' + searchString +'%\'';//chenged by pankaj for GCP-22
                if(String.isNotBlank(selectedBuilding)){
                    List<Project_Unit__c> buil  = [Select Name from Project_Unit__c where Name =: selectedBuilding];
                    String buildingName = buil[0].name;
                    // add building filter to the query
                    queryString +=  ' and Building__r.Name LIKE \''+ buildingName +'%\'';
                    if((FromRange != null && ToRange != null) && (FromRange >= 0 && ToRange != 0)) {
                        // if range is chosen
                        queryString +=  ' and Vacant_Area_Sq_ft__c >= ' + FromRange + ' and vacant_Area_Sq_ft__c <=' + ToRange;
                    }
                    if(fullyVacant) {
                        statusList.add(ElbConstantsClass.FLOOR_STATUS_FULL_VACANT);
                    }
                    if(partlyVacant) {
                        statusList.add(ElbConstantsClass.FLOOR_STATUS_PARTLY_VACANT);              
                    }
                    if(leasedOut) {
                        statusList.add(ElbConstantsClass.FLOOR_STATUS_LEASED_OUT);
                    }
                    if(churnExpected) {
                        statusList.add(ElbConstantsClass.FLOOR_STATUS_CHURN_EXPECTED);
                    }
                    String status = '';
                    String finalStatus = '';
                    
                    if(!statusList.isEmpty()){
                        for(string s: statusList) {
                            status += '\'' + s + '\',';
                        }
                        finalStatus = status.mid(0,status.length() -1);    
                        
                        queryString += ' and status__c IN (' + finalStatus +')' ;
                    }
                }
            }
            system.debug('queryString:--'+queryString);
            floorList = Database.query(queryString);
            system.debug('floorList.size():--'+floorList.size());
            system.debug('floorList:--'+floorList);
            for(Floor__c f :floorList){
                system.debug('isSelected:--'+isSelected);
                system.debug('neededArea:--'+neededArea);
                system.debug(' f.Name:--'+ f.Name);
                
                system.debug('f:--'+f);
                wrapList.add(new wrapperClass(f, isSelected,false,neededArea, f.Name ));
                system.debug('wrapList:--'+wrapList);
            }
        }
        else {
            Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Please Select Location & Asset Type'));
        }
    }
    public void Selected() {
        
        error1 = false;
        error2 = false;
        error3 = false;
        List<String> al = new List<String>();
        
        wrapListSelected = new List<wrapperClass>();
        
        for(wrapperClass selectedWarpper : wrapList) {
            if(selectedWarpper.isSelected == true) {
                al.add(selectedWarpper.f.Building__r.Name);
                Integer vacantA = Integer.ValueOf(selectedWarpper.f.Vacant_Area_Sq_ft__c);
                Integer churnA = Integer.ValueOf(selectedWarpper.f.Expected_Churn_Sq_ft__c);
                if((vacantA == null || vacantA == 0)&&( churnA == null || churnA == 0)) {
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Vacant/Churn Area is not available on the floor Please select different floor'));
                    error3 = true;
                }
                if(selectedWarpper.fullFloor == false) {
                    if(selectedWarpper.neededArea == null || selectedWarpper.neededArea == '') {
                        error1 = true;
                    } else {
                        error1 = false;
                        if(String.isNotBlank(selectedWarpper.neededArea)) {
                            Integer needed = Integer.ValueOf(selectedWarpper.neededArea);
                            Integer vacant = Integer.ValueOf(selectedWarpper.f.Vacant_Area_Sq_ft__c);
                            Integer churn = Integer.ValueOf(selectedWarpper.f.Expected_Churn_Sq_ft__c);
                            if(needed > vacant && (needed > churn)) {
                                error2 = true;
                            } else {
                                error2 = false;
                            }        
                        }
                    }
                    
                }
                if(error1 == false) {
                    if(error2 == false) {    
                        if(error3 == false) {
                            
                            //Add into Selected Wrapper List
                            if(selectedWarpper.fullFloor){
                                selectedWarpper.neededArea = string.valueOf(selectedWarpper.f.Total_Carpet_Area_Sq_ft__c);
                                wrapListSelected.add(selectedWarpper);
                            } else if(!selectedWarpper.fullFloor) { 
                                selectedWarpperNew = new wrapperClass( selectedWarpper.f, selectedWarpper.isSelected, false, selectedWarpper.neededArea, selectedWarpper.buildingName);
                                Integer needed = Integer.ValueOf(selectedWarpper.neededArea);
                                selectedWarpperNew.neededArea = string.valueOf(needed);
                                selectedWarpperNew.buildingName = string.valueOf(selectedWarpper.buildingName);
                                wrapListSelected.add(selectedWarpperNew);
                            }    
                        }
                    }
                }
                if (error1 == true) {
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Please Select Full Floor or Enter Area Neeeded'));
                }
                if (error2 == true) {
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Needed Area exceed limit of Vacant/Churn Area'));
                }
                if (error3 == true) {
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Vacant/Churn Area is not available on the floor Please select different floor'));
                }
            }
        }
        
        for(Integer i=0 ; i<al.size() ; i++){
            for(Integer j=i+1 ; j<al.size() ; j++){
                if(al.get(i) == al.get(j)){
                    //System.debug('Same');
                } else {
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Please select spaces from the same building'));
                }
            }
        }
        
        premiseOptions.put(dummyUnit.Premise_Group__c,wrapListSelected);
        premiseOptionsList.add(dummyUnit.Premise_Group__c);
    }
    public void DeSelected() {
        SelectedFloorlist = null;
        for(Floor__c floor: Floorlist) {
            floor.Selected__c = FALSE;
            floor.Full_Floor__c = FALSE;
            floor.Needed_Area_Sq_ft__c = null;
        }
        
        try {
            update Floorlist;
        } catch(DmlException e) {
            System.debug('The following exception has occurred while updating Floorlist: ' + e.getMessage());
        }
        
    }
    public PageReference Submit() {
        PageReference retPage;
        Head_Of_Terms__c HoT = new Head_Of_Terms__c();
        HoT.Opportunity__c = optyId;
        try {
            insert HoT;
        } catch(DmlException e) {
            System.debug('The following exception has occurred while inserting HoT: ' + e.getMessage());
        }
        
        for(String opt : premiseOptions.keySet()) {
            for(wrapperClass f: premiseOptions.get(opt)){
                Junction_Unit__c unit = new Junction_Unit__c();
                unit.Floor__c = f.f.Id;
                unit.Opportunity__c = optyId;
                unit.Status__c = ElbConstantsClass.UNIT_STATUS;
                Integer needed;
                if(String.isNotBlank(f.neededArea)) {
                    needed = Integer.valueof(f.neededArea);   
                    unit.Carpet_Area_in_Sq_Ft__c = needed;
                }
                if(f.fullFloor == true) {
                    unit.Carpet_Area_in_Sq_Ft__c = f.f.Total_Carpet_Area_Sq_ft__c;
                }
                unit.Head_Of_Terms__c = HoT.Id;
                unit.Premise_Group__c = opt;
                
                try {
                    insert unit;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred while inserting unit: ' + e.getMessage());
                }
            }
            
        }
        String sServerName = ApexPages.currentPage().getHeaders().get(ElbConstantsClass.HOST);
        String HotTermsPage = 'https://'+sServerName+'/apex/CreateHoT?id='+optyId+ '&HoTId=' + HoT.Id;
        // String optyPage = 'https://'+sServerName+'/'+optyId;
        retPage = new PageReference(HotTermsPage); 
        retPage.setRedirect(true);
        return retPage;
    }
    public class wrapperClass {
        public Floor__c f {get;set;}
        public Boolean isSelected {get;set;}
        public Boolean fullFloor {get;set;}
        public String neededArea {get;set;}
        public String buildingName {get;set;}
        
        public wrapperClass( Floor__c floor, Boolean isSelected, Boolean fullFloor, String neededArea, String buildingName) 
        {
            this.f = floor;
            this.isSelected = isSelected;
            this.fullFloor = fullFloor;
            if(this.fullFloor)
                this.neededArea = String.valueOf(this.f.Total_Carpet_Area_Sq_ft__c);
            else
                this.neededArea = '';
            this.buildingName = buildingName;
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}