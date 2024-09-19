/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-28-2023
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class SOATriggerHelper {
    public static void executeBatchToSendEmail(map<Id, Statement_of_Account__c> newItems, map<Id, Statement_of_Account__c> oldItems){
        
        Set<Id> soaIds = new Set<Id>();
        for(Statement_of_Account__c st:newItems.values()){
            if(newItems.get(st.id).Status__c <> oldItems.get(st.id).Status__c && st.Status__c == GlobalConstants.statements_Attached){
                soaIds.add(st.id);
            }
        }

        if(!soaIds.isEmpty()){
            SOAEmailBatch soa = new SOAEmailBatch(soaIds); 
            Database.executeBatch(soa,10);
        }
        
    }
}