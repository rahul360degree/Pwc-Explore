public with sharing class ServiceAuditReportDatatableController {
    @AuraEnabled(cacheable=true)
    public static OADataWrapper getOAData(Id oaId) {
        OADataWrapper result = new OADataWrapper();

        // Query related SARLI records
        result.sarliRecords = [SELECT Id, Observation_Question__c, Maximum_Score__c, Achieved_Score__c, Recommendation__c FROM Service_Audit_Report_Line_Item__c WHERE Observation_Area__c = :oaId];
        return result;
    }

    @AuraEnabled
    public static void updateSARLIRecords(List<Service_Audit_Report_Line_Item__c> updatedRecords) {
        try {
            update updatedRecords;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }

    public class OADataWrapper {
        @AuraEnabled public List<Service_Audit_Report_Line_Item__c> sarliRecords;
    }
}