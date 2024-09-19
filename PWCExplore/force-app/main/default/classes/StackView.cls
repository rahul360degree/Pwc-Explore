public with sharing class StackView {
    public string sendJSON {get;set;}
    public string selectedAsset {get;set;}
    public string selectedLocation {get;set;}
    public string selectedProject{get;set;}
    public string selectedBuilding{get;set;}
    public string selectedTower{get;set;}
    public Project_Unit__c objectPro {get;set;}
    public StackView() {
        sendJSON='\'No Data\'';
        objectPro = new Project_Unit__c();
    }
    
    public List < SelectOption > getProjects {
        get {
            List < SelectOption > optns = new List < Selectoption > ();
            List <  Project_Unit__c > queryResult = new List <  Project_Unit__c > ();
            Map < String, List <  Project_Unit__c > > queryResultMap = new Map < String, List <  Project_Unit__c > > ();
            queryResult = [Select Project__c, Asset_Type__c, Location__c from Project_Unit__c where Asset_Type__c=: objectPro.Asset_Type__c and Location__c =: objectPro.Location__c];
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
            querybuilding = [Select Name from Project_Unit__c where Project__c =:selectedProject];
            optnsB.add(new SelectOption('','Select a building'));
            for (Project_Unit__c obj: querybuilding) {
                //optns.add(new SelectOption(obj.Project__c));
                optnsB.add(new SelectOption(obj.Name,obj.Name));
            }
            return optnsB;
        }
        set;
    }
    
    public void Search() {
        String Location = objectPro.Location__c;
        String AssetType = objectPro.Asset_Type__c;
        Boolean isSelected = false;
        String neededArea = '';
        
        if(String.isNotBlank(Location) && String.isNotBlank(AssetType)) {
            
            if(String.isNotBlank(selectedProject)) {
                
                String ProjectName = selectedProject;
                if(String.isNotBlank(selectedBuilding)){
                    
                    List<Project_Unit__c> buil  = [Select Name from Project_Unit__c where Name =: selectedBuilding];
                    //String ProjectName = objectPro.Project__c;
                    
                    String buildingName = buil[0].name;
                    
                    List < Floor__c > floorList = new List < Floor__c > ();
                    Map < String, Floor__c > floorMap = new Map < String, Floor__c > ();
                    Map < Decimal, List < Floor__c >> floorAssestMap = new Map < Decimal, List < Floor__c >> ();
                    Map < Id, Junction_Unit__c > assestRentalMap = new Map < Id, Junction_Unit__c > ();
                    Map<Decimal, Map<String, List<Junction_Unit__c>>> floorLeasableRentalMap = new Map<Decimal, Map<String, List<Junction_Unit__c>>>();
                    List < Floor__c > newWrapList;
                    
                    Set<String> floorCodeSet = new Set<String>();
                    /** 
floorList = [select id, name, Status__c, Floor_Number__c, 
Building__c, Block__c, Block_Sequence__c, Leasable_Unit__c, 
Asset_Code__c,  Total_Carpet_Area_Sq_ft__c,Leased_Chargeable_Area__c,Vacant_Area_Sq_ft__c
from Floor__c where Building__r.Name =: buildingName];

for (Floor__c ff: floorList) {
// {1,<Some Random unit from that floor>}
// one record per floor
// gives us the list of unique floors in that building
floorMap.put(ff.Floor_Number__c, ff);
} 
**/
                    
                    List < Floor__c > assStructList = [select id, name, Status__c, Floor_Number__c, 
                                                       Building__c, Block__c, Block_Sequence__c, Leasable_Unit__c,
                                                       Asset_Code__c,  Total_Carpet_Area_Sq_ft__c,Leased_Chargeable_Area__c,Vacant_Area_Sq_ft__c, Floor_No__c
                                                       from Floor__c
                                                       where Building__r.Name =: buildingName  
                                                       order by Floor_No__c DESC, Block_Sequence__c ASC
                                                      ];
                    if (assStructList != null && !assStructList.isEmpty()) {
                        for (Floor__c asr: assStructList) {
                            floorCodeSet.add(asr.id);
                            if (floorAssestMap.containsKey(asr.Floor_No__c)) {
                                List<Floor__c> asrList = floorAssestMap.get(asr.Floor_No__c);
                                asrList.add(asr);
                                floorAssestMap.put(asr.Floor_No__c, asrList);
                            } else {
                                List < Floor__c > tempList = new List < Floor__c > ();
                                tempList.add(asr);
                                floorAssestMap.put(asr.Floor_No__c, tempList);
                            }
                        }
                    }
                    
                    List <Junction_Unit__c> rentalUlist = [select Id, Name, Term_Period__c , Floor__c, Floor__r.Asset_Code__c, Building__c, Opportunity__c, Opportunity__r.name, 
                                                           Block_Till_Date__c,End_Date__c, Floor__r.Floor_No__c, Carpet_Area_in_Sq_Ft__c, Status__c, Floor__r.Name,
                                                           Lease_Status__c
                                                           from Junction_Unit__c
                                                           where Floor__c IN: floorCodeSet and  (Lease_Status__C = 'Active Lease' OR Lease_Status__C = 'Coming up for renewal')]; 
                    
                    if(rentalUlist != null && !rentalUlist.isEmpty() && assStructList != null && !assStructList.isEmpty()){
                        for(Junction_Unit__c ru : rentalUlist ){
                            if(!floorLeasableRentalMap.containsKey(ru.Floor__r.Floor_No__c)){
                                List<Junction_Unit__c> newList = new List<Junction_Unit__c>();
                                newList.add(ru);
                                Map<String,List<Junction_Unit__c>> newMap= new Map<String,List<Junction_Unit__c>>();
                                newMap.put(ru.Floor__r.Name, newList);
                                floorLeasableRentalMap.put(ru.Floor__r.Floor_No__c, newMap);
                            } else {
                                Map<String,List<Junction_Unit__c>> getNewMap = new Map<String,List<Junction_Unit__c>>();
                                getNewMap = floorLeasableRentalMap.get(ru.Floor__r.Floor_No__c);
                                if(!getNewMap.containsKey(ru.Floor__r.Name)) {
                                    List<Junction_Unit__c> newList = new List<Junction_Unit__c>();
                                    newList.add(ru);
                                    getNewMap.put(ru.Floor__r.Name, newList);
                                } else {
                                    getNewMap.get(ru.Floor__r.Name).add(ru);
                                }
                                floorLeasableRentalMap.get(ru.Floor__r.Floor_No__c).putAll(getNewMap);
                            } 
                        }
                    }
                    
                    
                    List<LeasedUnits> llist ;
                    List<floorJSONWrapper> fjwList = new List<floorJSONWrapper>();
                    Decimal netusablearea;
                    Decimal vacantArea;
                    Decimal leasedArea;
                    if(!floorAssestMap.isEmpty()) {
                        for(Decimal f: floorAssestMap.keySet()) {
                            llist = new List<LeasedUnits>();
                            netusablearea =0;
                            leasedArea= 0;
                            vacantArea = 0;
                            
                            for(floor__c unit : floorAssestMap.get(f)){
                                // for each leasable unit on the floor
                                netusablearea += unit.Total_Carpet_Area_Sq_ft__c;
                                leasedArea += unit.Leased_Chargeable_Area__c;
                                vacantArea += unit.Vacant_Area_Sq_ft__c;
                                
                                if(!floorLeasableRentalMap.isEmpty()){
                                    system.debug('floorLeasableRentalMap map'+ floorLeasableRentalMap);
                                    system.debug('floorLeasableRentalMap.get(f).get(unit) map'+ floorLeasableRentalMap.get(f).get(unit.Name));
                                    
                                    if(floorLeasableRentalMap.get(f).get(unit.Name) != null){
                                        for(Junction_Unit__c rental : floorLeasableRentalMap.get(f).get(unit.Name)){
                                            if(rental.Opportunity__c != null) {
                                                if(rental.End_Date__c != null){
                                                    llist.add(new LeasedUnits(unit.Name, rental.Opportunity__r.name, string.valueOf(rental.End_Date__c.format()), rental.Status__c,string.valueOf(rental.Carpet_Area_in_Sq_Ft__c),rental.term_period__c ));
                                                }
                                                else{
                                                    llist.add(new LeasedUnits(unit.Name, rental.Opportunity__r.name, '', rental.Status__c,string.valueOf(rental.Carpet_Area_in_Sq_Ft__c),'' ));                                     
                                                }    
                                            }
                                            else{
                                                LeasedUnits l = new LeasedUnits(unit.Name,'','', rental.Status__c, String.valueOf(rental.Carpet_Area_in_Sq_Ft__c),'' );
                                                llist.add(l);
                                            } 
                                        }
                                    }
                                }
                            }
                            floorJSONWrapper fw = new floorJSONWrapper(f,f, f,string.valueOf(netusablearea),string.valueOf(vacantArea),string.valueOf(leasedArea),llist);
                            fjwList.add(fw);
                        }
                    }
                    
                    
                    sendJSON= JSON.serialize(fjwList);
                    
                }
            }
        }
    }
    public class floorJSONWrapper {
        public Decimal FloorSequence {get;set;}
        public Decimal FloorName {get;set;} 
        public Decimal FloorNumber {get;set;} 
        public String TowerName {get;set;}
        public String TotalSqFt {get;set;} 
        public String VacantSqft {get;set;}
        public String LeasedSqft {get;set;} 
        public List<LeasedUnits> LeasableUnits = new List<LeasedUnits>();
        
        public floorJSONWrapper(Decimal FloorSequence, Decimal FloorName, Decimal FloorNumber, string TotalSqFt, string VacantSqft, String LeasedSqft, List<LeasedUnits> lUnits){   
            //   this.name = name;
            this.FloorSequence = FloorSequence;
            this.FloorName = FloorName;
            this.FloorNumber = FloorNumber;
            this.TotalSqFt = TotalSqFt;
            this.VacantSqft = VacantSqft;
            this.LeasedSqft = LeasedSqft;
            this.LeasableUnits = lUnits;
        }
        
    }
    
    public class LeasedUnits{
        public String Name {get;set;}
        
        public String OccupiedBy {get;set;} 
        public String Occupiedtill {get;set;}
        public String Status {get;set;} 
        public String Area {get;set;}
        public String termperiod {get;set;}
        public LeasedUnits(String Name, String OccupiedBy, string Occupiedtill, string Status, string Area,String termperiod){   
            //   this.name = name;
            this.Name = Name;
            this.OccupiedBy = OccupiedBy;
            this.Occupiedtill = Occupiedtill;
            this.Status = Status;
            this.Area = Area;
            this.termperiod=termperiod;
        }
    }
}