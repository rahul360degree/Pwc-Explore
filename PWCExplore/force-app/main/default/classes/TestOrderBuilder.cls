/*------------------------------------------------------------------------------------
 * Author        :        Sumit
 * Company       :        Salesforce
 * Description   :        Test Builder for Orders
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 10-07-2020      Sumit Swami     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestOrderBuilder {
    Order orderInstance;

    public TestOrderBuilder() {
        orderInstance = new Order();
        // Set defaults for required fields here
        orderInstance.Name = 'Order for test class';
    }

    public TestOrderBuilder setName(String name) {
        orderInstance.Name = name;
        return this;
    }

    public TestOrderBuilder setOpportunityId(Id opportunityId) {
        orderInstance.OpportunityId = opportunityId;
        return this;
    }
    
    public TestOrderBuilder setAccountId(Id accountId) {
        orderInstance.AccountId = accountId;
        return this;
    }
    
    public TestOrderBuilder setQuoteId(Id quoteId) {
        orderInstance.QuoteId = quoteId;
        return this;
    }
    
     public TestOrderBuilder setInstallationScope(String InstallationScope) {
        orderInstance.Installation_Scope__c = InstallationScope;
        return this;
    }
    
    public TestOrderBuilder setAmount(Decimal orderAmount) {
        orderInstance.Order_Amount__c = orderAmount;
        return this;
    }
    
    public TestOrderBuilder setStatus(String orderStatus) {
        orderInstance.Status = orderStatus;
        return this;
    }
    
    public TestOrderBuilder setIntegrationStatus(String intgStatus) {
        orderInstance.Integration_Status__c = intgStatus;
        return this;
    }
    
    public TestOrderBuilder setEffectiveDate(Date effectiveDate) {
        orderInstance.EffectiveDate = effectiveDate;
        return this;
    }
    
    public TestOrderBuilder setShipToAddress(Id shipToAddress) {
        orderInstance.Ship_To_Address__c = shipToAddress;
        return this;
    }
    
    public TestOrderBuilder setSoldToAddress(Id soldToAddress) {
        orderInstance.Sold_To_Address__c = soldToAddress;
        return this;
    }
    
    public TestOrderBuilder setBusinessUnit(String businessUnit) {
        orderInstance.Business_Unit__c = businessUnit;
        return this;
    }
    
    public TestOrderBuilder setPriceBook2Id(Id priceBookId) {
        orderInstance.Pricebook2Id = priceBookId;
        return this;
    }
    
    public TestOrderBuilder setRecordTypeId(Id recordTypeId) {
        orderInstance.RecordTypeId = recordTypeId;
        return this;
    }
    
    public TestOrderBuilder setMHEDivision(String mheDivision) {
        orderInstance.MHE_Division__c = mheDivision;
        return this;
    }

    public TestOrderBuilder setOrderReferenceNumberExt(String orderRefNumber) {
        orderInstance.Order_Reference_Number_Ext__c = orderRefNumber;
        return this;
    }

    public TestOrderBuilder setOrderReferenceNumber(String orderRefNumber) {
        orderInstance.OrderReferenceNumber = orderRefNumber;
        return this;
    }
    
    public Order getTestRecord() {
        return orderInstance;
    }

    public Order getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(orderInstance.Name)) {
            throw new TestDataException('Order Name is Empty');
        }
        if (String.isBlank(orderInstance.AccountId)) {
            throw new TestDataException('Account is blank');
        }
        insert orderInstance;
        return orderInstance;
    }
}