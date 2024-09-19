/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Class to contain business logic for Dealer Visit Trigger
Test Class:    DealerVisitTriggerTest
---------------------------------------------------------------------------
History
10-05-2020      Shailja      Initial Release
----------------------------------------------------------------------------*/
public without sharing class DealerVisitTriggerHelper {
    // Joshna 24/2/21 - added this new fix as part of hypercare to allow users to complete visits w/o geotag
    public static final String DEALER_VISIT_STATUS_COMPLETE_WO_GEOTAG = 'Completed without Geotag';
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to create Events after insertion of Dealer_Visit records
Inputs:        list of records
Test Class:   
----------------------------------------------------------------------------
History
10-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void createDealerVisitEvents(list<Dealer_Visit__c> newDealerVisits){
        Id counterShareRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Counter_Share').getRecordTypeId();
        Map<Id, PJP__c> pjpIdVsPJPRecord = getPjpIdVsPJPRecord(newDealerVisits);
        List<Event> eventList = new List<Event>();
        String interioB2CRecordTypeId_DealerVisit = 	Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        String interioB2CRecordTypeId_Task = 	Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        
        for(Dealer_Visit__c dealerVisit : newDealerVisits){
            if (dealerVisit.RecordTypeId != counterShareRecordTypeId) {
 
                Set<Id> userIdSet = new Set<Id>();
                userIdSet.add(dealerVisit.OwnerId);
                
                if (dealerVisit.ASM__c != null){
                    userIdSet.add(dealerVisit.ASM__c);
                }if (dealerVisit.ZM__c != null) {
                    userIdSet.add(dealerVisit.ZM__c );                    
                }
                eventList.addAll(createEvent(dealerVisit,userIdSet));
   
            }
        }
        try {
            if((!eventList.isEmpty()) && eventList.size() > 0){
                insert eventList;
            }
        } catch(Exception ex){
            Logger.logError('DealerVisitTriggerHelper', 'createDealerVisitEvents', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Poonam
Company:       Salesforce
Description:   Method to create Events after insertion Dealer_Visit records
Inputs:        list of records
Test Class:   
----------------------------------------------------------------------------*/
    
    public List<Event> createEvent(Dealer_Visit__c dealerVisit, Set<Id> ownerIdSet) {
        String interioB2CRecordTypeId_DealerVisit = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        List<Event> events = new List<Event>();
        for (Id ownerId : ownerIdSet) {
            events.add(new Event( 
                Type = 'Meeting',
                Description = dealerVisit.Dealer_Name__c,
                Subject = dealerVisit.Dealer_Name__c,
                DurationInMinutes = (dealerVisit.RecordTypeId == interioB2CRecordTypeId_DealerVisit) ? 5 : 120,
                ActivityDateTime = (dealerVisit.Visit_Due_Date__c != null) ? dealerVisit.Visit_Due_Date__c : Datetime.now(),
                Dealer_Visit_Status__c = dealerVisit.Dealer_Visit_Status__c,
                WhatId = dealerVisit.id,
                OwnerId = ownerId
                
            ));
           
        }
        
        return events;
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to get Map of PJP Id Vs PJP Record
Inputs:        list of records
Test Class:   
----------------------------------------------------------------------------
History
16-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public Map<Id, PJP__c> getPjpIdVsPJPRecord(List<Dealer_Visit__c> dealerVisits){
        Set<Id> pjpIds = new Set<Id>();
        for(Dealer_Visit__c dv : dealerVisits){
            pjpIds.add(dv.PJP__c);
        }
        return (new Map<Id, PJP__c>([Select Id, OwnerId From PJP__c Where Id IN: pjpIds]));
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to update Events on update of Dealer_Visit records
Inputs:        Map of records
Test Class:   
----------------------------------------------------------------------------
History
10-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void updateDealerVisitEvents(Map<Id, Dealer_Visit__c> newDealerVisits, Map<Id, Dealer_Visit__c> oldDealerVisits){
        List<Event> eventsToBeUpdated = new List<Event>();
        List<Id> dealerVisitIds = new List<Id>(); 
        Set<Id> cancelledVisit = new Set<Id> ();  
        String interioB2CRecordTypeId_DealerVisit = 	Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        
        
        for(Dealer_Visit__c dv : newDealerVisits.values()){
            if((dv.Visit_Due_Date__c != oldDealerVisits.get(dv.Id).Visit_Due_Date__c) || (dv.Dealer_Visit_Status__c != oldDealerVisits.get(dv.Id).Dealer_Visit_Status__c)){
                if(dv.Dealer_Visit_Status__c == 'Cancelled' && dv.RecordTypeId == interioB2CRecordTypeId_DealerVisit){
                    cancelledVisit.add(dv.Id);    
                }else{
                    dealerVisitIds.add(dv.Id);
                   
                }
                
            }
        }
  
        for(Event ev : [Select Id, Dealer_Visit_Status__c, ActivityDateTime, WhatId, DurationInMinutes From Event Where WhatId IN :dealerVisitIds]){
            
            eventsToBeUpdated.add(new Event(Id = ev.Id,
                                            Dealer_Visit_Status__c = newDealerVisits.get(ev.WhatId).Dealer_Visit_Status__c,
                                            ActivityDateTime = (newDealerVisits.get(ev.WhatId).Dealer_Visit_Status__c == GlobalConstants.DEALER_VISIT_STATUS_COMPLETE 
                                                                || newDealerVisits.get(ev.WhatId).Dealer_Visit_Status__c == DEALER_VISIT_STATUS_COMPLETE_WO_GEOTAG) ? Datetime.now() : newDealerVisits.get(ev.WhatId).Visit_Due_Date__c,
                                            DurationInMinutes = (newDealerVisits.get(ev.WhatId).Dealer_Visit_Status__c == GlobalConstants.DEALER_VISIT_STATUS_COMPLETE 
                                                                 || newDealerVisits.get(ev.WhatId).Dealer_Visit_Status__c == DEALER_VISIT_STATUS_COMPLETE_WO_GEOTAG) ? 0 : ev.DurationInMinutes
                                            
                                           
                                           ));

        } 
        if(!cancelledVisit.isEmpty()){
            delete [Select Id From Event Where WhatId IN :cancelledVisit];
        }
        
        try{
            if(eventsToBeUpdated != null && eventsToBeUpdated.size() > 0)
                update eventsToBeUpdated;
        }catch(Exception ex){
            Logger.logError('DealerVisitTriggerHelper', 'updateDealerVisitEvents', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to update intent
Inputs:        Map of records
Test Class:   
----------------------------------------------------------------------------
History
07-07-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void updateIntentOnUpdate(map<Id, Dealer_Visit__c> newDealerVisits, map<Id, Dealer_Visit__c> oldDealerVisits){
        for(Dealer_Visit__c dv : newDealerVisits.values()){
            if(String.isNotBlank(dv.Intent__c)){  
                dv.Intent__c = '';
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Joshna
Company:       Salesforce
Description:   Method to set account ID on counter share records
Inputs:        List of records
Test Class:   
----------------------------------------------------------------------------
History
06-11-2020      Joshna     Initial Release
----------------------------------------------------------------------------*/
    public void setAccountIdForCounterShare(List<Dealer_Visit__c> newDealerVisits){
        Id counterShareRecordTypeId = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Counter_Share').getRecordTypeId();
        Id loggedInUserAccountId;
        for (User each : [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()]) {
            loggedInUserAccountId = each.AccountId;
        }
        if (String.isNotBlank(loggedInUserAccountId)) {
            for (Dealer_Visit__c each : newDealerVisits) {
                if (each.RecordTypeId == counterShareRecordTypeId) {
                    each.Account_Information__c = loggedInUserAccountId;
                }
            }
        }
    }
    //PJP validation
    public void checkforSameTime(List<Dealer_Visit__c> newDealerVisits){
        Set<Id> ownerIdSet = new Set<Id>();
        Id interioB2C =  Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        for(Dealer_Visit__c dVisit: newDealerVisits){
            if(dVisit.RecordTypeId == interioB2C){
                ownerIdSet.add(dVisit.ownerId);
            }
        }
        List<Event> eventList  = [SELECT Id,OwnerId,What.type,StartDateTime,EndDateTime FROM Event where What.type = 'Dealer_Visit__c' and OwnerId IN :ownerIdSet limit 40000];
        Map<Id,List<Event>> ownerIdWithEventMap = new Map<Id,List<Event>> ();
        if(!eventList.isEmpty()){
            for(Event ev:eventList){
                if(!ownerIdWithEventMap.containsKey(ev.ownerId)){
                    ownerIdWithEventMap.put(ev.ownerId, new List<Event>());
                }
                ownerIdWithEventMap.get(ev.ownerId).add(ev);
            }
            
            
            for(Dealer_Visit__c dVisit: newDealerVisits){
                List<Event> eList = ownerIdWithEventMap.get(dVisit.OwnerId);
                if(!eList.isEmpty()){
                    for(Event e:eList){
                        if(dVisit.Visit_Due_Date__c >=e.StartDateTime &&  dVisit.Visit_Due_Date__c <=e.EndDateTime && dVisit.Id!=e.WhatId){
                            dVisit.addError('Already Existed');
                        }
                    }
                }
            }
        }
    }
    
    //Create the Questionnaire
    public void populateQuestionnaireFields(List<Dealer_Visit__c> newDealerVisits) {
        String interioB2CRecordTypeId = 	Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        List<Dealer_Visit__c> dealerVisitsToUpdate = new List<Dealer_Visit__c>();
        Set<String> taskTypeSet = new Set<String>();
        Map<String, List<Interio_Questionnaire__c>> taskTypeToQuestionnairesMap = new Map<String, List<Interio_Questionnaire__c>>();
        
        // Step 1: Find all task types for dealer visit code (Set)
        for (Dealer_Visit__c dealerVisit : newDealerVisits) {
            if(!String.isEmpty(dealerVisit.Task_Type__c) && dealerVisit.RecordTypeId == interioB2CRecordTypeId){  
                taskTypeSet.add(dealerVisit.Task_Type__c);
            }
        }
        
        String questionnaireRecordTypeId = 	Schema.SObjectType.Interio_Questionnaire__c.getRecordTypeInfosByDeveloperName().get('Interio_Questionnaire').getRecordTypeId();
        // Step 2: Create a Map with task type as key and related Interio Questionnaires as value    
        for (Interio_Questionnaire__c template : [SELECT Id,Task_Type__c,Question_1__c, Question_2__c, Question_3__c, Question_4__c, Question_5__c, Question_6__c,
                                                  Question_7__c, Question_8__c, Question_9__c, Question_10__c 
                                                  FROM Interio_Questionnaire__c                                                    
                                                  WHERE Status__c = 'Active' 
                                                  AND Task_Type__c IN: taskTypeSet
                                                  and RecordTypeId = :Schema.SObjectType.Interio_Questionnaire__c.getRecordTypeInfosByDeveloperName().get('Template').getRecordTypeId()]) {
                                                      if(!taskTypeToQuestionnairesMap.containsKey(template.Task_Type__c)){
                                                          taskTypeToQuestionnairesMap.put(template.Task_Type__c, new List<Interio_Questionnaire__c>());
                                                      }
                                                      taskTypeToQuestionnairesMap.get(template.Task_Type__c).add(template);
                                                  }
        
        List<Interio_Questionnaire__c> createQuestionnaire = new List<Interio_Questionnaire__c>();
        for (Dealer_Visit__c dealerVisit : newDealerVisits) {
            if(!String.isEmpty(dealerVisit.Task_Type__c) && taskTypeToQuestionnairesMap.containsKey(dealerVisit.Task_Type__c)){
                for( Interio_Questionnaire__c template : taskTypeToQuestionnairesMap.get(dealerVisit.Task_Type__c)){
                    createQuestionnaire.add( new Interio_Questionnaire__c(Template__c = template.Id,Task_Type__c = template.Task_Type__c,
                                                                          RecordTypeId = questionnaireRecordTypeId,
                                                                          Visit__c = dealerVisit.Id,
                                                                          Question_1__c = template.Question_1__c,
                                                                          Question_2__c = template.Question_2__c,
                                                                          Question_3__c = template.Question_3__c,
                                                                          Question_4__c = template.Question_4__c,
                                                                          Question_5__c = template.Question_5__c,
                                                                          Question_6__c = template.Question_6__c,
                                                                          Question_7__c = template.Question_7__c,
                                                                          Question_8__c = template.Question_8__c,
                                                                          Question_9__c = template.Question_9__c,
                                                                          Question_10__c = template.Question_10__c
                                                                          
                                                                          
                                                                         ));
                }
            }
        }
        
        if (!createQuestionnaire.isEmpty()) {
            Database.insert(createQuestionnaire,false);
        }
    }
    
}