/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Receivables
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 19-10-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestReceivableBuilder {
    Receivable__c receivableInstance;

    public TestReceivableBuilder() {
        receivableInstance = new Receivable__c(Document__c = '12345', Due_Date__c = Date.today(), Document_Date__c = Date.today(),
            Balance_in_Home_Currency__c = 1000);
    }

    public TestReceivableBuilder setInvoiceToBP(Id invoiceToBP) {
        receivableInstance.Invoice_To_BP__c = invoiceToBP;
        return this;
    }

    public TestReceivableBuilder setDueDate(Date dueDate) {
        receivableInstance.Due_Date__c = dueDate;
        return this;
    }

    public TestReceivableBuilder setOwnerId(Id ownerId) {
        receivableInstance.OwnerId = ownerId;
        return this;
    }

    public TestReceivableBuilder setBusinessUnit(String businessUnit) {
        receivableInstance.Business_Unit__c = businessUnit;
        return this;
    }

    public TestReceivableBuilder setInvoice(Id invoiceId) {
        receivableInstance.Invoice__c = invoiceId;
        return this;
    }

    public TestReceivableBuilder setBCCode(String bcCode) {
        receivableInstance.BC_Code__c = bcCode;
        return this;
    }

    public TestReceivableBuilder setNetBilledSales(Decimal netBilledSales) {
        receivableInstance.Net_Billed_Sales__c = netBilledSales;
        return this;
    }

    public TestReceivableBuilder setRecordType(String recordType) {
        receivableInstance.Record_Type__c = recordType;
        return this;
    }

    public TestReceivableBuilder setRecordTypeId(Id recordTypeId) {
        receivableInstance.RecordTypeId = recordTypeId;
        return this;
    }

    public TestReceivableBuilder setOrder(String orderNumber) {
        receivableInstance.Order__c = orderNumber;
        return this;
    }

    public TestReceivableBuilder setSalesRepresentative(Id salesRepId) {
        receivableInstance.Sales_Representative__c = salesRepId;
        return this;
    }
    
    public TestReceivableBuilder setStartDate(Date startDate) {
        receivableInstance.Start_Date__c = startDate;
        return this;
    }
    
    public TestReceivableBuilder setType(String itemtype) {
        receivableInstance.Type__c = itemtype;
        return this;
    }
    
    public TestReceivableBuilder setEndDate(Date endDate) {
        receivableInstance.End_Date__c = endDate;
        return this;
    }
    
    public TestReceivableBuilder setOutstandingAmount(double outstandingAmt) {
        receivableInstance.Balance_in_Home_Currency__c = outstandingAmt;
        return this;
    }
    
    public TestReceivableBuilder setDocumentDate(Date documentDate) {
        receivableInstance.Document_Date__c = documentDate;
        return this;
    }
    
    //added by Shreela on 25th October 2021 for test class issue
        public TestReceivableBuilder setBranch(String branch) {
        receivableInstance.Branch__c = branch;
        return this;
    }
    //ended by Shreela on 25th October 2021 for test class issue

    public Receivable__c getTestRecord() {
        return receivableInstance;
    }
    
    public Receivable__c getSavedTestRecord() {
        insert receivableInstance;
        return receivableInstance;
    }
}