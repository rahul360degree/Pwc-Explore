/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Quotes
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestQuoteBuilder {
    Quote quoteInstance;

    public TestQuoteBuilder() {
        quoteInstance = new Quote();
        // Set defaults for required fields here
        quoteInstance.Name = 'Quote for test class';
    }

    public TestQuoteBuilder setName(String name) {
        quoteInstance.Name = name;
        return this;
    }

    public TestQuoteBuilder setOpportunityId(Id opportunityId) {
        quoteInstance.OpportunityId = opportunityId;
        return this;
    }

    public TestQuoteBuilder setRecordTypeId(Id recordTypeId) {
        quoteInstance.RecordTypeId = recordTypeId;
        return this;
    }    
    
    public Quote getTestRecord() {
        return quoteInstance;
    }
    
   //Added by Namrata and Shreela on 1st September 2022
    public TestQuoteBuilder setPricebook2Id(Id Pricebook2Id) {
        quoteInstance.Pricebook2Id = Pricebook2Id ;
        return this;
    }
    //Ended by Namrata and Shreela on 1st September 2022

    public Quote getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(quoteInstance.Name)) {
            throw new TestDataException('Quote Name is Empty');
        }
        if (String.isBlank(quoteInstance.OpportunityId)) {
            throw new TestDataException('Opportunity is blank');
        }
        insert quoteInstance;
        return quoteInstance;
    }
    
      // Added new methods by rohit jadhav on 15th Sep 2023
    public TestQuoteBuilder setExpectedDateOfDelivery(Date expectedDateOfDelivery) {
        quoteInstance.Expected_Date_of_Delivery__c = expectedDateOfDelivery;
        return this;
    }
    
    public TestQuoteBuilder setExpirationDate(Date expirationDate) {
        quoteInstance.ExpirationDate = expirationDate;
        return this;
    }
    
    public TestQuoteBuilder setTechnicalOfferDesignCodes(String technicalOfferDesignCodes) {
        quoteInstance.Technical_Offer_Design_Codes__c = technicalOfferDesignCodes;
        return this;
    }
    
    public TestQuoteBuilder setTechnicalOfferExclusions(String technicalOfferExclusions) {
        quoteInstance.Technical_Offer_Exclusions__c = technicalOfferExclusions;
        return this;
    }
}