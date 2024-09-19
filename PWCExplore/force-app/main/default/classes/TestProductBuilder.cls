/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test Builder for Products
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 18-06-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestProductBuilder {
    Product2 productInstance;

    public TestProductBuilder() {
        productInstance = new Product2();
        // Set defaults for required fields here
        productInstance.Name = 'Product for test class';
        productInstance.IsActive = true;
    }

    public TestProductBuilder setName(String name) {
        productInstance.Name = name;
        return this;
    }

    public TestProductBuilder setIsActive(Boolean isActive) {
        productInstance.IsActive = isActive;
        return this;
    }
    
    public TestProductBuilder setIsGeneric(Boolean isGeneric) {
        productInstance.Is_Generic_Product__c = isGeneric;
        return this;
    }

    public TestProductBuilder setDescription(String description) {
        productInstance.Description = description;
        return this;
    }

    public TestProductBuilder setComponentType(String componentType) {
        productInstance.Component_Type__c = componentType;
        return this;
    }
    
    public TestProductBuilder setProductCode(String productCode) {
        productInstance.ProductCode = productCode;
        return this;
    }


    public TestProductBuilder setItemCode(String itemCode) {
        productInstance.Item__c = itemCode;
        return this;
    }
	public TestProductBuilder setCommodityCode(String commodityCode) {
        productInstance.Commodity_Set__c = commodityCode;
        return this;
    }
    public TestProductBuilder setProductLine(String productLine){
        productInstance.Product_Line__c = productLine;
        return this;
    }

    public Product2 getTestRecord() {
        return productInstance;
    }

    public Product2 getSavedTestRecord() {
        // Add errors for all required fields here
        if (String.isBlank(productInstance.Name)) {
            throw new TestDataException('Product Name is Empty');
        }
        if (String.isBlank(productInstance.Item__c)) {
            throw new TestDataException('Item code is Empty');
        }
        insert productInstance;
        return productInstance;
    }
}