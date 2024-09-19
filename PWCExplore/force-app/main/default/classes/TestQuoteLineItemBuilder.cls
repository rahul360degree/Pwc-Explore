/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Quote Line Item
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestQuoteLineItemBuilder {
    QuoteLineItem quoteLineItemInstance;

    public TestQuoteLineItemBuilder() {
        quoteLineItemInstance = new QuoteLineItem();
        quoteLineItemInstance.Quantity = 1;
    }

    public TestQuoteLineItemBuilder setQuoteId(Id quoteId) {
        quoteLineItemInstance.QuoteId = quoteId;
        return this;
    }

    public TestQuoteLineItemBuilder setPriceBookEntryId(Id priceBookEntryId) {
        quoteLineItemInstance.PriceBookEntryId = priceBookEntryId;
        return this;
    }

    public TestQuoteLineItemBuilder setSequenceNumber(Decimal sequenceNumber) {
        quoteLineItemInstance.Sequence_Number__c = sequenceNumber;
        return this;
    }
    
    public TestQuoteLineItemBuilder setProductLine(String productLine){
        quoteLineItemInstance.Product_Type__c=productLine;
        return this;
    }

    public TestQuoteLineItemBuilder setUnitPrice(Decimal unitPrice) {
        quoteLineItemInstance.UnitPrice = unitPrice;
        return this;
    }
    
    public TestQuoteLineItemBuilder setAssetId(Id assetId) {
        quoteLineItemInstance.Asset__c = assetId;
        return this;
    }

    public TestQuoteLineItemBuilder setContractPeriod(Integer contractPeriod) {
        quoteLineItemInstance.Contract_Period__c = contractPeriod;
        return this;
    }

    
    public TestQuoteLineItemBuilder setOpportunityLineItemId(Id oliId) {
        quoteLineItemInstance.OpportunityLineItemId = oliId;
        return this;
    }
    
    
    public QuoteLineItem getTestRecord() {
        return quoteLineItemInstance;
    }

    public QuoteLineItem getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(quoteLineItemInstance.QuoteId)) {
            throw new TestDataException('Quote Id is blank');
        }
        if (String.isBlank(quoteLineItemInstance.PricebookEntryId)) {
            throw new TestDataException('Price Book Entry Id is blank');
        }
        insert quoteLineItemInstance;
        return quoteLineItemInstance;
    }
}