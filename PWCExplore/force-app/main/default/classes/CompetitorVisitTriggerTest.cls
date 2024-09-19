@isTest
public with sharing class CompetitorVisitTriggerTest {
    static final Id INTERIO_RECORDTYPEID = Schema.SObjectType.Competitor_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
    @TestSetup
    public static void setupData(){
        Competitor_Visit__c visitRec = new TestCompetitorVisitBuilder().setBrand('PepperFry').setRecordTypeId(INTERIO_RECORDTYPEID).getSavedTestRecord();
    }

    @isTest
    public static void creatingCompetitorVisitForSameBrandShouldReturnWarning() {
        String errorMessage = '';
        try {
            Test.startTest();
            Competitor_Visit__c visitRec = new TestCompetitorVisitBuilder().setBrand('PepperFry').setRecordTypeId(INTERIO_RECORDTYPEID).getSavedTestRecord();
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(true, errorMessage.contains(Label.Competitor_visit_duplicate_warning), 'Duplicate visit did not return warning message');
    }

    @isTest
    public static void creatingCompetitorVisitForSameBrandWithContinueShouldSetDuplicate() {
        Competitor_Visit__c existingRec = [SELECT Id FROM Competitor_Visit__c];
        Test.startTest();
        Competitor_Visit__c visitRec = new TestCompetitorVisitBuilder().setBrand('PepperFry').setContinue(true).setRecordTypeId(INTERIO_RECORDTYPEID)
            .getSavedTestRecord();
        Test.stopTest();
        visitRec = [SELECT Duplicate__c FROM Competitor_Visit__c WHERE Id = :visitRec.Id];
        System.assertEquals(existingRec.Id, visitRec.Duplicate__c, 'Duplicate visit Id not set on new visit');
    }

    @isTest
    public static void settingContinueOnNewVisitShouldReturnError() {
        String errorMessage = '';
        try {
            Test.startTest();
            Competitor_Visit__c visitRec = new TestCompetitorVisitBuilder().setBrand('Royal Oak').setContinue(true).setRecordTypeId(INTERIO_RECORDTYPEID)
                .getSavedTestRecord();
            Test.stopTest();
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        System.assertEquals(true, errorMessage.contains(Label.Competitor_Visit_Continue_value_validation), 'New visit with continue did not return any error');
    }
}