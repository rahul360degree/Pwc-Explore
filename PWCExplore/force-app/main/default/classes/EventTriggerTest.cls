@isTest
public with sharing class EventTriggerTest {
    static final Id STANDARD_RECORDTYPE_ID = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Standard_Event').getRecordTypeId();
    @TestSetup
    public static void setupData(){
        Dealer_Visit__c dealerVisitRecord = new TestDealerVisitBuilder().getSavedTestRecord();
        Event eventRec = new TestEventBuilder().setWhatId(dealerVisitRecord.Id).setRecordTypeId(STANDARD_RECORDTYPE_ID).getSavedTestRecord();
    }

    @isTest
    public static void creatingNewTrainingEventShouldSetWhatId() {
        Id trainingRecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Training').getRecordTypeId();
        Test.startTest();
        Event trainingEvent = new TestEventBuilder().setRecordTypeId(trainingRecordTypeId).getSavedTestRecord();
        Test.stopTest();
        trainingEvent = [SELECT Id, WhatId FROM Event WHERE Id = :trainingEvent.Id];
        List<Training__c> trainingRecords = [SELECT Id FROM Training__c WHERE Id = :trainingEvent.WhatId];
        System.assertEquals(1, trainingRecords.size(), 'Training record was not created for a training event');
        System.assertEquals(trainingRecords[0].Id, trainingEvent.WhatId, 'Training record not tagged to Event');
    }

    @isTest
    public static void updatingDealerVisitEventShouldUpdateDealerVisit() {
        Event dealerVisitEvent = [SELECT Id, StartDateTime FROM Event WHERE RecordTypeId = :STANDARD_RECORDTYPE_ID LIMIT 1];
        dealerVisitEvent.StartDateTime = dealerVisitEvent.StartDateTime.addDays(1);
        Test.startTest();
        update dealerVisitEvent;
        Test.stopTest();
        Dealer_Visit__c dealerVisitRecord = [SELECT Visit_Due_Date__c FROM Dealer_Visit__c];
        System.assertEquals(dealerVisitEvent.StartDateTime, dealerVisitRecord.Visit_Due_Date__c, 'Dealer Visit Date was not reset after event change');
    }
}