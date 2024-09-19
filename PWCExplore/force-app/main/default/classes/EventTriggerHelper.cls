/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Class to contain business logic for Event Trigger
Test Class:    DealerVisitTriggerTest
---------------------------------------------------------------------------
History
19-05-2020      Shailja      Initial Release
11-11-2020      Mahith      Added Method to prevent delete of Attendence Remindes
----------------------------------------------------------------------------*/
public without sharing class EventTriggerHelper {
    // Joshna 24/2/21 - added this new fix as part of hypercare to allow users to complete visits w/o geotag
    public static final String DEALER_VISIT_STATUS_COMPLETED_WO_GEOTAG = 'Completed without Geotag';
/*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to update Dealer_Visit Records on update of Event records
    Inputs:        Map of records
    Test Class:   
    ----------------------------------------------------------------------------
    History
    10-05-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateEvents(Map<Id, Event> newEvents, Map<Id, Event> oldEvents){
        List<Dealer_Visit__c> dealerVisitsToUpdate = new List<Dealer_Visit__c>();
        List<Id> dealerVisitIds = new List<Id>();
        Map<Id, Event> dealerVisitIdVsEvent = new Map<Id, Event>();
        for(Event ev : newEvents.values()){
            if(ev.WhatId != null
               &&(ev.ActivityDateTime != oldEvents.get(ev.Id).ActivityDateTime
                  || ev.Dealer_Visit_Status__c != oldEvents.get(ev.Id).Dealer_Visit_Status__c)){
                      dealerVisitIds.add(ev.WhatId);
                      dealerVisitIdVsEvent.put(ev.WhatId, ev);
                  }
        }
        
        for(Dealer_Visit__c dv : [Select Id, Visit_Due_Date__c, Dealer_Visit_Status__c From Dealer_Visit__c Where Id IN: dealerVisitIds]){
            dealerVisitsToUpdate.add(new Dealer_Visit__c(
                Id = dv.Id,
                Visit_Due_Date__c = (dealerVisitIdVsEvent.get(dv.Id).Dealer_Visit_Status__c != GlobalConstants.DEALER_VISIT_STATUS_COMPLETE
                  && dealerVisitIdVsEvent.get(dv.Id).Dealer_Visit_Status__c != DEALER_VISIT_STATUS_COMPLETED_WO_GEOTAG) ? dealerVisitIdVsEvent.get(dv.Id).ActivityDateTime : dv.Visit_Due_Date__c,
                Dealer_Visit_Status__c = dealerVisitIdVsEvent.get(dv.Id).Dealer_Visit_Status__c
            ));
        }
        
        try{
            if(dealerVisitsToUpdate != null && dealerVisitsToUpdate.size() > 0){
                update dealerVisitsToUpdate;
            }
        }catch(Exception ex){
             Logger.logError('EventTriggerHelper', 'updateEvents', '', ex);
        }
    }

    /*------------------------------------------------------------------------
    Author:        Mahith
    Company:       Salesforce
    Description:   Method to create training records
    Inputs:        Map of records
    Test Class:   
    ----------------------------------------------------------------------------
    History
    11-11-2020      Mahith     Initial Release
    ----------------------------------------------------------------------------*/
    public void createTrainingRecord(List<Event> newEvents) {
        Id trainingRecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Training').getRecordTypeId();
        List<Training__c> trainingList = new List<Training__c>();
        for (Event each : newEvents) {
            if (each.RecordTypeId != trainingRecordTypeId) {
                continue;
            }
            trainingList.add(new Training__c(Attendee__c = UserInfo.getUserId()));
        }
        insert trainingList;
        Integer counter = 0;
        for (Event each : newEvents) {
            if (each.RecordTypeId != trainingRecordTypeId) {
                continue;
            }
            each.WhatId = trainingList[counter].Id;
            counter ++;
        }
    }

    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to update add validation error on event creation
    Inputs:        List of records
    ----------------------------------------------------------------------------
    History
    29-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateEvents(List<Event> newEvents){
        String campaignKeyPrefix = Campaign.SObjectType.getDescribe().getKeyPrefix();

        Set<String> campaigns = new Set<String>();
        for(Event event : newEvents){
            //For Campaign records
            if(event.WhatId != null 
                && String.valueOf(event.WhatId).startsWith(campaignKeyPrefix)
                && event.Event_Type__c == GlobalConstants.CALENDAR_EVENT_TYPE){
                campaigns.add(event.WhatId);
            }
        }

        Map<String,Campaign> campaignRecords = new Map<String,Campaign>([Select Id,OwnerId FROM Campaign WHERE Id IN :campaigns ]);
        for(Event event : newEvents){
            if(campaignRecords.containsKey(event.WhatId)
                && campaignRecords.get(event.WhatId).OwnerId != event.OwnerId
                && event.Event_Type__c == GlobalConstants.CALENDAR_EVENT_TYPE){
                event.addError(System.Label.NOT_ALLOWED_TO_CREATE_EVENT);
            }
        }
    }
}