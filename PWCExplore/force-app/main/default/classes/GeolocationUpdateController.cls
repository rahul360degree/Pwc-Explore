public with sharing class GeolocationUpdateController {
    
    @AuraEnabled
    public static Boolean updateGeolocation(String recordId, decimal latitude, decimal longitude){
        Date today = Date.today();
    	Integer year = today.year();
    	Integer month = today.month();
    	String formattedMonth = (month < 10) ? '0'+String.valueOf(month) : String.valueOf(month);
		DateTime firstdayofmonthstring = DateTime.valueOf(String.valueOf(year)+'-'+formattedMonth+'-'+'01 9:00:00.00');
        System.debug('RecordId--->' + recordId);
        System.debug('Lat' + latitude);
        Id userId = UserInfo.getUserId();
        List<Visit__c> inProgressVisits = [Select Id,Status__c from Visit__c where OwnerId =: userId and Status__c ='In Progress' and PJP__r.Start_Date__c=:firstdayofmonthstring];
        system.debug('inProgressVisits'+inProgressVisits);
        try{
            if(inProgressVisits.isEmpty()){
                Visit__c visitRecord = [SELECT Id,Geolocation__Latitude__s,Geolocation__Longitude__s,Visit_Start_Date__c,Status__c FROM Visit__c WHERE Id=:recordId];
                visitRecord.Visit_Start_Date__c=System.now();
                visitRecord.Status__c='In Progress';
                visitRecord.Geolocation__Latitude__s = latitude;
                visitRecord.Geolocation__Longitude__s = longitude;
                system.debug('done');
                update visitRecord;
                return true;
                
            }
            else{
                system.debug('failed');
                return false;
            }
        }
        catch (Exception exc){
            System.debug('Error-=-->'+ exc);
            return false;
        }
    }

}