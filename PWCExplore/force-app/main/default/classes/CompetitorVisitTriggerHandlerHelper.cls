/*------------------------------------------------------------------------
 Author:        Mahith Madwesh
 Company:       Salesforce
 Description:   Helper class for 'Competitor visit' Trigger
 Inputs:        NA
 Test Class:
 History
 17-11-2020     Mahith Madwesh     Initial Release
 ----------------------------------------------------------------------------*/
public with sharing class CompetitorVisitTriggerHandlerHelper {
    public void checkForDuplicate(list<Competitor_Visit__c> newItems){
        List <Competitor_Visit__c> duplicateCV = new list<Competitor_Visit__c>();
        List <Competitor_Visit__c> existingCV = new list<Competitor_Visit__c>();
        
        List<string> newBrandNames = new list<string>();
        for(Competitor_Visit__c cv2:newItems){
            newBrandNames.add(cv2.Brand__c);
        }
        
        Id interioB2CRecordType =Schema.SObjectType.Competitor_Visit__c.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();
        
        List<Competitor_Visit__c> existingCVList = [SELECT Id, Brand__c, Duplicate__c, Continue__c FROM Competitor_Visit__c
            WHERE CreatedDate = LAST_N_DAYS:30 and recordTypeId=:interioB2CRecordType and Brand__c IN :newBrandNames and CreatedById=:UserInfo.getUserId()];
        
        Map<String, Competitor_Visit__c> exisitingMap = new Map<String, Competitor_Visit__c>();
        
        for(Competitor_Visit__c cv0: existingCVList){
            exisitingMap.put(cv0.Brand__c,cv0);
        }
        
        for(Competitor_Visit__c cv: newItems){
            if(exisitingMap.containsKey(cv.Brand__c)) {
                if(cv.Continue__c==true && cv.RecordTypeId == interioB2CRecordType) {
                    cv.Duplicate__c = exisitingMap.get(cv.Brand__c).Id;
                    break;
                } else  if(cv.Continue__c==false && cv.RecordTypeId == interioB2CRecordType) {
                    cv.addError(System.Label.Competitor_visit_duplicate_warning);
                }
            } else {
                if(cv.Continue__c && cv.RecordTypeId == interioB2CRecordType) {
                    cv.addError(System.Label.Competitor_Visit_Continue_value_validation);
                }
                if(!cv.Continue__c && cv.recordTypeId==interioB2CRecordType) {
                    cv.Duplicate__c=null;
                }
            }
        }
    }
}