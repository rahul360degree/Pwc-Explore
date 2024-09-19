/*------------------------------------------------------------------------
Author:        Mahith Madwesh
Company:       Salesforce
Description:   Helper class for pinCodeDealerMapping TriggerHandler
Inputs:        NA
Test Class:    
History
15-12-2020      Mahith Madwesh     Initial Release
----------------------------------------------------------------------------*/
public with sharing class PincodeDealerTriggerHelper {

    public void getPincodeDealerUpdates(list<Pin_Code_Dealer_Mapping__c> newRecords, string executionContext){

        list<logger__c> existingStagingTableRecords = [SELECT Id,Type__c FROM Logger__c where Type__c='Metadata change - P1' 
                                                                                AND Pin_Code_Dealer_Mapping__c IN:newRecords];
        list<Logger__c> loggerList = new list<Logger__c>();
        
        if(executionContext == 'insert'){
            for(Pin_Code_Dealer_Mapping__c pc:newRecords){
                 logger__c newLog = new logger__c();
                    newLog.Account__c = pc.Service_Dealer__c;
                    newLog.Type__c = 'Pincode mapping - P2';
                    newLog.SubType__c='New/Dealer Change';
                    newLog.Pin_Code_Dealer_Mapping__c = pc.Id;
                    if(existingStagingTableRecords.size()>0){
                         newLog.Status__c = 'Rejected';
                    }else{
                         newLog.Status__c = 'Pending';
                    }
                    loggerList.add(newLog);
            }
        }else if(executionContext == 'delete'){
            for(Pin_Code_Dealer_Mapping__c pc:newRecords){
                 logger__c newLog = new logger__c();
                    newLog.Account__c = pc.Service_Dealer__c;
                    newLog.Type__c = 'Pincode mapping - P2';
                    newLog.SubType__c='Deleted';
                    newLog.Status__c = 'Pending';
                    newLog.Pin_Code_Dealer_Mapping__c = pc.Id;
                    newLog.Deleted_PinCode__c = pc.Name;
                    loggerList.add(newLog);
            }
        }
         insert loggerList;
    }



}