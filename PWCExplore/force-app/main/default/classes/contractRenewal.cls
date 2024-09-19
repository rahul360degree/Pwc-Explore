/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for renewal of contract/head of terms 
Related:       NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class contractRenewal {
    public contractRenewal() {

    }

    //fetch contract/ head of terms details
    @AuraEnabled(cacheable=true)
    public static List<HEAD_OF_TERMS__c> getHotData(String hotId){
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();

        hotList = [select Id, Name, Licence_End_Date__c
                        from HEAD_OF_TERMS__c 
                        where Id =: hotId 
                   LIMIT 100];

        return hotList;        
    }

    //updating details over hot with reason for extension and premise traction for changing the units status
    @AuraEnabled
    public static List<HEAD_OF_TERMS__c> updateHotFields(string hotId, Date hotEndDate, string reasonForChange, Date hotEndDateOld) { 
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();
        Set<Id> premiseIdSet = new Set<Id>();
        List<HEAD_OF_TERMS__c> hotObject = new List<HEAD_OF_TERMS__c>();

        List<Junction_Unit__c> premiseList = new List<Junction_Unit__c>();

        List<Floor__c> leasableList = new List<Floor__c>();

        List<Premise_Tracking__c> premiseTracObject = new List<Premise_Tracking__c>();
        List<Junction_Unit__c> premObject = new List<Junction_Unit__c>();

        Datetime now  = system.now();
        Date today  = system.today();

        hotList = [select Id, Name, Licence_End_Date__c
                        from HEAD_OF_TERMS__c 
                        where Id =: hotId LIMIT 100];

        premiseList = [select Id, Name, HEAD_OF_TERMS__c, End_Date__c, Floor__c
                        from Junction_Unit__c 
                        where HEAD_OF_TERMS__c =: hotId LIMIT 1000];

        if(!hotList.isEmpty()){
            for(HEAD_OF_TERMS__c hot: hotList){
                if(hotEndDate > hotEndDateOld){
                    hot.Reason_for_Contract_Renewal__c = reasonForChange;
                    hot.Blocked_Till_Date__c = hotEndDate;
                    hot.Licence_End_Date__c = hotEndDate;
                    hot.Contract_Renewal_Date__c = now;
                    hotObject.add(hot);
                    
                    for(Junction_Unit__c prem: premiseList){
                        if(prem.HEAD_OF_TERMS__c == hot.Id){
                            Junction_Unit__c premLineItem = new Junction_Unit__c();
                            premiseIdSet.add(prem.Floor__c);
                            premLineItem.Id = prem.Id;
                            premLineItem.Block_Till_Date__c = hotEndDate;
                            premLineItem.Reason_for_Blocking__c = reasonForChange;
                            //premLineItem.Status__c = ElbConstantsClass.EVENT_BLOCKED;
                            premObject.add(premLineItem);
                        }
                    }
                }    
            }

            try{
                update premObject;
            } catch(DmlException e) {
                System.debug('The following exception has occurred while Updating premObject: ' + e.getMessage());
            }

            
            try{
                update hotObject;
            } catch(DmlException e) {
                System.debug('The following exception has occurred while Updating hotObject: ' + e.getMessage());
            }
            

            leasableList = [Select Id, Name, Building__c
                            from Floor__c
                            Where Id IN: premiseIdSet LIMIT 1000];

            if(!leasableList.isEmpty()){
                for(Floor__c lu: leasableList){
                    Premise_Tracking__c premiseTracItem = new Premise_Tracking__c();
                    premiseTracItem.Leasable_Unit__c = lu.Id;
                    premiseTracItem.Event__c = ElbConstantsClass.EVENT_BLOCKED;
                    premiseTracItem.Tracking_Date__c = today;
                    premiseTracObject.add(premiseTracItem);
                }
            }

            try{
                insert premiseTracObject;
            } catch(DmlException e) {
                System.debug('The following exception has occurred while inserting premiseTracObject: ' + e.getMessage());
            }
            
        }

        return hotObject;
    }
}