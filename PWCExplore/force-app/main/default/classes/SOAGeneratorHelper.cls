/**
* @description       : It is a jhelper class for the SOAGeneratorBatch
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 01-31-2023
* @last modified by  : vrajpoot@godrej.com
* @Test Class		 : StatementofAccountTest
**/
public class SOAGeneratorHelper {
    //return Map as {Key=> Salary Code, Value=> User Id}
    public  Map<String, Id> userMapWithSalaryCode(){
        Map<String, Id> mapUserIDSalaryCode = new Map<String, Id>();
        for(User u: [Select Id, salary_code__c FROM User where isactive = TRUE and profile.userlicense.name = 'Salesforce']){
            mapUserIDSalaryCode.put(u.salary_code__c, u.Id);
        }
        return mapUserIDSalaryCode;
    }
    
    //return Map {key=>Label,value=>user Id}
    public Map<String, Id> getBrandedAccounttantCity(Map<String, Id> mapUserIDSalaryCode,List<String> lstCityCodes){        
        Map<String, Id> mapCityCodeBA = new Map<String, Id>();
        for(Branch_Accountant_City_Mapping__mdt baCityMapping: [Select Id, Label,Branch_Accountant_Salary_Code__c
                                                                FROM Branch_Accountant_City_Mapping__mdt WHERE label in :lstCityCodes ]
           ){
               mapCityCodeBA.put(baCityMapping.label, mapUserIDSalaryCode.get(baCityMapping.Branch_Accountant_Salary_Code__c));
           }
        return mapCityCodeBA;
    }
    
    //Return Date
    public Date dtDate(){
        //Date dtToday = Date.newInstance(2022, 2, 1).addMonths(-1);
        Date dtToday = Date.Today().addMonths(-1);
        return dtToday;
    }
    
    //Create SOA
    public Statement_Of_Account__c initializeSOA(Account acn, Date dtToday, Map<String, Id> mapCityCodeBA,Map<String,Branch_Accountant_Area_Code_Mappings__mdt> branchAccountantAreaCodeMAP,Map<String,Id> salaryCodeWithUserId){
        integer intCalendarYear = dtToday.Year();
        integer intCalendarMonth = dtToday.Month();
        integer intPeriodYear = intCalendarMonth >= 4 ? (intCalendarYear+1) : intCalendarYear;
        integer intPeriodMonth = intCalendarMonth >=4 ? (intCalendarMonth - 3) : (9 + intCalendarMonth);
            //string strCalendarMonth = (DateTime.NewInstance(2022,2,1,0,0,0).addMonths(-1) ).Format('MMMM'); 
            string strCalendarMonth = (System.now().addMonths(-1) ).Format('MMMM');
        Statement_Of_Account__c soa = new Statement_Of_Account__c();
        soa.Account__c = acn.Id;                    
        soa.Name = 'DSA for ' + acn.Name + ' for ' + strCalendarMonth + ' ' + intCalendarYear ;
        //soa.OwnerId = acn.DSA_Contact_User__c;
        soa.OwnerId = acn.OwnerId;
        soa.Calendar_Month__c = strCalendarMonth;
        soa.Calendar_Year__c = intCalendarYear;
        soa.Period_Month__c = intPeriodMonth;
        soa.Period_Year__c = intPeriodYear;
        soa.DSA_External_Key__c = acn.Account_Code__c + '_' + intPeriodYear + '_' + (intPeriodMonth<10 ? '0' + String.valueOf(intPeriodMonth) : String.valueOf(intPeriodMonth));
        soa.Business_Unit__c = (acn.Account_Code__c).substring(0,1);
        //soa.Branch_Accountant__c = mapCityCodeBA.get(acn.Primary_Address__r.ZipCode__r.CityCode__c);
        soa.Area_Sales_Manager__c = acn.OwnerId;
        if(acn.Owner.ManagerId <> null)
        	soa.ASM_Manager__c = acn.Owner.ManagerId;//ASM L+1        
        if(acn.Owner.ManagerId <> null && acn.Owner.Manager.ManagerId <>null)
        	soa.ASM_s_L_2__c = acn.Owner.Manager.ManagerId; //ASM L+2

        if(branchAccountantAreaCodeMAP.containsKey(acn.Area_Code_of_Owner__c)){
            String salaryCode = branchAccountantAreaCodeMAP.get(acn.Area_Code_of_Owner__c).Branch_Accountant_Salary_Code__c;
            if(salaryCodeWithUserId.containsKey(salaryCode)){
                soa.Branch_Accountant__c = salaryCodeWithUserId.get(salaryCode);
                soa.Branch_Accountant_Salary_Code__c = salaryCode;
            }
        }
        
        return soa;
    }
    //create soa records
    public void createSOARecords(List<Statement_Of_Account__c> lstSOA){
        Database.SaveResult[] srList =  Database.insert(lstSOA,false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted Invoice. Invoice ID: ' + sr.getId());               
            } else {
                for(Database.Error objErr : sr.getErrors()) {
                    System.debug('Error: '+objErr.getStatusCode() + ': ' + objErr.getMessage());
                    //Error framework
                }
            }
        }
    }
    
}