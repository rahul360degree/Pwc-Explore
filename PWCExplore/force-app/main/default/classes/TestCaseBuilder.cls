/*------------------------------------------------------------------------------------
 * Author        :        Nupoor
 * Company       :        Salesforce
 * Description   :        Test Builder for Case
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 17-12-2020      Nupoor Sharma     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestCaseBuilder {
    Case caseInstance;

    public TestCaseBuilder() {
        caseInstance = new Case();
        // Set defaults for required fields here
        caseInstance.Subject = 'Case for test class';
    }

    public TestCaseBuilder setSubject(String subject) {
        caseInstance.Subject = subject;
        return this;
    }

    public TestCaseBuilder setAccountId(Id AccountId) {
        caseInstance.AccountId = AccountId;
        return this;
    }
    
    public TestCaseBuilder setBranch(String branch) {
        caseInstance.Branch__c = branch;
        return this;
    }
    
    public TestCaseBuilder setRecordTypeId(Id recordTypeId) {
        caseInstance.RecordTypeId = recordTypeId;
        return this;
    }
    
    public TestCaseBuilder setMHEDivision(String mheDivision) {
        caseInstance.MHE_Division__c = mheDivision;
        return this;
    }
    
    public TestCaseBuilder setAsset(Id AssetId) {
        caseInstance.AssetId = AssetId;
        return this;
    }

    public TestCaseBuilder setAlternateMobile(String alternateMobile) {
        caseInstance.Mobile__c = alternateMobile;
        return this;
    }

    public TestCaseBuilder setAlternateEmail(String alternateEmail) {
        caseInstance.Email__c = alternateEmail;
        return this;
    }

    public Case getTestRecord() {
        return caseInstance;
    }

    public Case getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(caseInstance.Subject)) {
            throw new TestDataException('Case Subject is Empty');
        }
        if (String.isBlank(caseInstance.AccountId)) {
            throw new TestDataException('Account is blank');
        }
        insert caseInstance;
        return caseInstance;
    }
}