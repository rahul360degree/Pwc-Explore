public with sharing class CustomCalendarController {
    
	@AuraEnabled(cacheable=true)
    public static List<Visit__c> getAllVisitsData(ID userId,ID pjprecId,String pageType) {      
       if(pageType=='Home'|| pageType=='TeamView'){
        List<Visit__c> visitsList = [SELECT Id,Name,OwnerId,Status__c,PJP__c,PJP__r.Status__c, Geolocation__Latitude__s, Geolocation__Longitude__s,Account__r.Id,Account__r.Name,
        Account__r.Primary_Add_City__c,Account__r.Primary_Add_State__c,Account__r.Primary_Address_Code__c,
        Account__r.Primary_Address__r.Street__c,Account__r.Primary_Address__r.Country__c,Visit_Start_Date__c,Visit_Planned_Date__c,Visit_Scheduled_Date__c,RecordTypeId
        FROM Visit__c WHERE OwnerId=:userId And PJP__r.Id=:pjprecId];
        
        return visitsList;

       }else if(pageType=='Details'){
        List<Visit__c> visitsList = [SELECT Id,Name,OwnerId,Status__c,PJP__c,PJP__r.Status__c, Geolocation__Latitude__s, Geolocation__Longitude__s,Account__r.Id,Account__r.Name,
        Account__r.Primary_Add_City__c,Account__r.Primary_Add_State__c,Account__r.Primary_Address_Code__c,
        Account__r.Primary_Address__r.Street__c,Account__r.Primary_Address__r.Country__c,Visit_Start_Date__c,Visit_Planned_Date__c,PJP__r.Start_Date__c,Visit_Scheduled_Date__c,RecordTypeId
        FROM Visit__c WHERE PJP__r.Id=:pjprecId];

        return visitsList;
       }
         
        return null;
        
    }
    @AuraEnabled
    public static void updateScheduledDate(ID Id,DateTime dt){
        Visit__c visitRecord=[SELECT ID, Visit_Planned_Date__c FROM Visit__c WHERE ID=:Id];
        visitRecord.Visit_Planned_Date__c=(Datetime)dt;
        
        update visitRecord;
        
    }

    @AuraEnabled(cacheable=true)
    public static List<User> fetchASMoptions(ID userId){
        List<User> asmList=[SELECT ID,Name FROM User WHERE ManagerId=:userId AND UserRole.Name LIKE '%ASM%']; //Username IN ('tarun.s.akkineni@pwc.com.pwcexplore','aditya.rohith.katta@pwc.com.pwcexplore','shubham.pant.tpr@pwc.com.pwcexplore')];//ManagerId=:userId AND UserRole.Name LIKE '%ASM%'
        
        return asmList;
        
    }


    @AuraEnabled(cacheable=true)
    public static Boolean checkUserRole(ID userId){
        User userDetails=[SELECT ID,Name,UserRole.Name FROM User WHERE ID=:userId];
        
            String role=userDetails.UserRole.Name;                  
        
        
        return (role.Contains('RBH'))? true:false;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<PJP__c> monthWiseRender(String forThisDate) {      
        DateTime dateAndMonth = DateTime.valueOf(String.valueOf(forThisDate)+' '+'9:00:00.00');
        Id test = UserInfo.getUserId(); 
        List<PJP__c> pjprecord = [Select Id, Status__c,OwnerId from PJP__c where Start_Date__c =:dateAndMonth and OwnerId=:test]; 
        return pjprecord;
    
}
@AuraEnabled(cacheable=true)
public static List<PJP__c> getPJPdata(ID recordId,String forThisDate){
    if(recordId != null){
        List<PJP__c> pjpData=[SELECT ID,Name,Start_Date__c,Status__c FROM PJP__c WHERE ID=:recordId];
        system.debug(pjpData);
        return pjpData;
    }
    else if(forThisDate != null){
        DateTime dateAndMonth = DateTime.valueOf(String.valueOf(forThisDate)+' '+'9:00:00.00');
        system.debug('hahs'+dateAndMonth);
        List<PJP__c> pjprecord = [Select Id, Status__c from PJP__c where Start_Date__c =:dateAndMonth];
        system.debug(pjprecord);
        return pjprecord;
    }
    return null;
    
}


}