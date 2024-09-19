/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Competitor Visit
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 19-10-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestCompetitorVisitBuilder {
    Competitor_Visit__c competitorVisitInstance;

    public TestCompetitorVisitBuilder() {
        competitorVisitInstance = new Competitor_Visit__c();
    }

    public TestCompetitorVisitBuilder setBrand(String brand) {
        competitorVisitInstance.Brand__c = brand;
        return this;
    }

    public TestCompetitorVisitBuilder setRecordTypeId(Id recordTypeId) {
        competitorVisitInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public TestCompetitorVisitBuilder setContinue(Boolean continueWithSave) {
        competitorVisitInstance.Continue__c = continueWithSave;
        return this;
    }

    public Competitor_Visit__c getTestRecord() {
        return competitorVisitInstance;
    }

    public Competitor_Visit__c getSavedTestRecord() {
        insert competitorVisitInstance;
        return competitorVisitInstance;
    }
}