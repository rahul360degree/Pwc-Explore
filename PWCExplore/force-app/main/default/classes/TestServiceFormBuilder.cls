/*------------------------------------------------------------------------------------
 * Author        :        Nupoor
 * Company       :        Salesforce
 * Description   :        Test Builder for Service Forms
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 17-12-2020      Nupoor Sharma     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestServiceFormBuilder {
    Service_Form__c serviceFormInstance;

    public TestServiceFormBuilder() {
        serviceFormInstance = new Service_Form__c();
        // Set defaults for required fields here
    }


    public TestServiceFormBuilder setCaseId(Id CaseId) {
        serviceFormInstance.Case__c = CaseId;
        return this;
    }

    public TestServiceFormBuilder setRecordTypeId(Id recordTypeId) {
        serviceFormInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public Service_Form__c getTestRecord() {
        return serviceFormInstance;
    }

    public Service_Form__c getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(serviceFormInstance.RecordTypeId)) {
            throw new TestDataException('Service_Form__c Recordtype is Empty');
        }
        if (String.isBlank(serviceFormInstance.Case__c)) {
            throw new TestDataException('Case__c is blank');
        }
        insert serviceFormInstance;
        return serviceFormInstance;
    }
}