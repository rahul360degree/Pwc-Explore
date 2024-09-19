/**
 * @Description       : Used to execute in System context
 * @Author            : Varun Rajpoot
 * @last modified on  : 10-01-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   09-22-2023   Varun Rajpoot   Initial Version
**/
public without sharing class QuoteRecordProcessor_SystemContext {
    public static void updateQLIForLocksB2B(Set<Id> qIds){       
        List<QuotelineItem> qliRecordList = [Select Id,Quote.Approval_Status__c from QuotelineItem where QuoteId IN: qIds];
        for(QuotelineItem qli: qliRecordList){
            qli.Approval_Status__c = qli.Quote.Approval_Status__c;
        }
        if(!qliRecordList.isEmpty()){
            List<Database.SaveResult> saveResult = Database.update(qliRecordList,false);       
            for (Database.SaveResult sr : saveResult) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
}