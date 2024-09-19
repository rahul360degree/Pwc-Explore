public with sharing class startVisithandler {
    @AuraEnabled(cacheable=true)
    public static Visit__c getaddress(Id recordId) {
        Visit__c add =  [SELECT Account__r.Primary_Add_City__c,Account__r.Primary_Add_State__c,Account__r.Primary_Address_Code__c,Account__r.Primary_Address__r.Street__c,Account__r.Primary_Address__r.Country__c FROM Visit__c Where Id =: recordId];
        return add;
    }
}