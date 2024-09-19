/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Billed Sales & Outstandings
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 03-01-2021      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestBilledSalesOutstandingsBuilder {
    Billed_Sales_Outstandings__c bsoInstance;

    public TestBilledSalesOutstandingsBuilder() {
        bsoInstance = new Billed_Sales_Outstandings__c(Document_Number__c = '12345', Due_Date__c = Date.today(), Document_Date__c = Date.today());
    }

    public TestBilledSalesOutstandingsBuilder setAccount(Id accountId) {
        bsoInstance.Account__c = accountId;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setDueDate(Date dueDate) {
        bsoInstance.Due_Date__c = dueDate;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setOwnerId(Id ownerId) {
        bsoInstance.OwnerId = ownerId;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setStatus(String status) {
        bsoInstance.Status__c = status;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setBusinessUnit(String businessUnit) {
        bsoInstance.Business_Unit__c = businessUnit;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setPlannedCollectionDate1(Date plannedCollectionDate) {
        bsoInstance.Planned_Collection_Date_1__c = plannedCollectionDate;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setPlannedCollectionAmount1(Decimal plannedCollectionAmount) {
        bsoInstance.Planned_Collection_Amount_1__c = plannedCollectionAmount;
        return this;
    }

    public TestBilledSalesOutstandingsBuilder setSalesRepresentative(Id userId) {
        bsoInstance.Sales_Representative__c = userId;
        return this;
    }

    public Billed_Sales_Outstandings__c getTestRecord() {
        return bsoInstance;
    }

    public Billed_Sales_Outstandings__c getSavedTestRecord() {
        insert bsoInstance;
        return bsoInstance;
    }
}