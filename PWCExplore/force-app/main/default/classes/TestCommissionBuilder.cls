/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Commissions
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 03-01-2021      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestCommissionBuilder {
    Commission__c commissionInstance;

    public TestCommissionBuilder() {
        commissionInstance = new Commission__c();
    }

    public TestCommissionBuilder setApprovalStatus(String approvalStatus) {
        commissionInstance.Approval_Status__c = approvalStatus;
        return this;
    }

    public TestCommissionBuilder setType(String type) {
        commissionInstance.Type__c = type;
        return this;
    }

    public TestCommissionBuilder setInvoiceNumber(String invoiceNumber) {
        commissionInstance.Invoice_Number__c = invoiceNumber;
        return this;
    }

    public Commission__c getTestRecord() {
        return commissionInstance;
    }

    public Commission__c getSavedTestRecord() {
        insert commissionInstance;
        return commissionInstance;
    }
}