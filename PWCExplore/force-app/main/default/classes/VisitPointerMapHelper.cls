public with sharing class VisitPointerMapHelper {
    
    @AuraEnabled(cacheable = true)
    public static List<Visit__c> getRelatedVisit(Id pjpId){
        System.debug('visit Record-->'+ pjpId);
        List<Visit__c> visitList = [SELECT Id,Name, Geolocation__Latitude__s, Geolocation__Longitude__s,Account__r.Name,
                                    Account__r.Primary_Add_City__c,Account__r.Primary_Add_State__c,Account__r.Primary_Address_Code__c,
                                    Account__r.Primary_Address__r.Street__c,Account__r.Primary_Address__r.Country__c,Visit_Start_Date__c,Visit_Planned_Date__c
                                    FROM Visit__c
                                    Where PJP__c=: pjpId];
        System.debug('Records--->'+ visitList);
        
        return visitList;
    }
    
    
}