/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Events
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 04-01-2021      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestEventBuilder {
    Event eventInstance;

    public TestEventBuilder() {
        eventInstance = new Event(Subject = 'Test Event', StartDateTime = System.now(), EndDateTime = System.now().addHours(1));
    }

    public TestEventBuilder setWhatId(Id whatId) {
        eventInstance.WhatId = whatId;
        return this;
    }

    public TestEventBuilder setRecordTypeId(Id recordTypeId) {
        eventInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public Event getTestRecord() {
        return eventInstance;
    }

    public Event getSavedTestRecord() {
        insert eventInstance;
        return eventInstance;
    }
}