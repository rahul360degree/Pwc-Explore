/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Price Book Entry
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestPriceBookEntryBuilder {
    PriceBookEntry priceBookEntryInstance;

    public TestPriceBookEntryBuilder() {
        priceBookEntryInstance = new PriceBookEntry();
        // Set defaults for required fields here
        priceBookEntryInstance.UseStandardPrice = false;
        priceBookEntryInstance.UnitPrice = 100;
        priceBookEntryInstance.IsActive = true;
    }

    public PriceBookEntry getTestRecord() {
        return priceBookEntryInstance;
    }

    public TestPriceBookEntryBuilder setProduct2Id(Id product2Id) {
        priceBookEntryInstance.Product2Id = product2Id;
        return this;
    }

    public TestPriceBookEntryBuilder setPricebook2Id(Id pricebook2Id) {
        priceBookEntryInstance.Pricebook2Id = pricebook2Id;
        return this;
    }

    public TestPriceBookEntryBuilder setUnitPrice(Decimal unitPrice) {
        priceBookEntryInstance.UnitPrice = unitPrice;
        return this;
    }

    public TestPriceBookEntryBuilder setIsActive(Boolean isActive) {
        priceBookEntryInstance.IsActive = isActive;
        return this;
    }

    public TestPriceBookEntryBuilder setUseStandardPrice(Boolean useStandardPrice) {
        priceBookEntryInstance.UseStandardPrice = useStandardPrice;
        return this;
    }

    public PriceBookEntry getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(priceBookEntryInstance.Product2Id)) {
            throw new TestDataException('Product is Empty');
        }
        if (String.isBlank(priceBookEntryInstance.Pricebook2Id)) {
            throw new TestDataException('Price Book is Empty');
        }
        if (!priceBookEntryInstance.UseStandardPrice && priceBookEntryInstance.UnitPrice == null) {
            throw new TestDataException('UnitPrice is not set');
        }
        insert priceBookEntryInstance;
        return priceBookEntryInstance;
    }
}