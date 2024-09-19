public without sharing class DeactivateButtonHandler {
    @AuraEnabled
    public static Account getAccountRecord(Id recordId){
        try {
            Account a = [SELECT Id,Status__c,Number_of_Warning_Letters__c FROM Account WHERE Id =: recordId];
            return a;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean isWorkOrderExistOnAccount(Id recordId){
        try {       
            Boolean isExist = false;
            Integer workOrderCount = [SELECT COUNT() FROM WorkOrder Where AccountID =: recordId];
            if(workOrderCount > 0) {
                isExist =  true;
            } 
            return isExist;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Account updateAccountStatus(Id recordId){
        try {
            Account a = [SELECT Id,Status__c,Number_of_Warning_Letters__c FROM Account WHERE Id =: recordId];
            a.Status__c = 'BG Processed';
            update a;
            return a;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}