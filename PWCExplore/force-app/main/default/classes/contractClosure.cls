/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for early closure of head of terms
Related:       NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class contractClosure {
    public contractClosure() {

    }

    //fetch head of term details 
    @AuraEnabled(cacheable=true)
    public static List<HEAD_OF_TERMS__c> getHotData(String hotId){
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();

        hotList = [select Id, Name, Licence_End_Date__c
                        from HEAD_OF_TERMS__c 
                        where Id =: hotId LIMIT 100];
        return hotList;        
    }

    //Updating head of term details with reason for early closure 
    @AuraEnabled
    public static List<HEAD_OF_TERMS__c> updateHotFields(string hotId, Date hotEndDate, string reasonForChange, Date hotEndDateOld) { 
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();
        List<HEAD_OF_TERMS__c> hotObject = new List<HEAD_OF_TERMS__c>();

        Datetime now  = system.now();

        hotList = [select Id, Name, Licence_End_Date__c
                        from HEAD_OF_TERMS__c 
                        where Id =: hotId LIMIT 100];

        if(!hotList.isEmpty()){
            for(HEAD_OF_TERMS__c hot: hotList){
                if(hotEndDate < hotEndDateOld){
                    hot.Licence_End_Date__c = hotEndDate;
                    hot.Reason_for_change_in_contract_date__c = reasonForChange;
                    hot.Contract_Closure_Date__c = now;
                    hotObject.add(hot);
                }
            }

            try{
                update hotObject; 
            } catch(DmlException e) {
                System.debug('The following exception has occurred while Updating hotObject: ' + e.getMessage());
            }
            
        }

        return hotObject;
    }
}