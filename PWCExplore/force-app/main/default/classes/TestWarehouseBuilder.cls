/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   builder test class for Line items
Inputs:        
Test Class:    
History
08-01-2021      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/

@isTest
public with sharing class TestWarehouseBuilder {
    warehouse__c warehouse;
    
    public TestWarehouseBuilder() {
        warehouse = new warehouse__c();
    }
    
   public TestWarehouseBuilder setName(String name) {
        warehouse.Name = name;
        return this;
    }
    
   public TestWarehouseBuilder setWarehouseCode(String code) {
        warehouse.Warehouse__c = code;
        return this;
    }
    
   public warehouse__c getRecord() {
        return warehouse;
   }
    
   public warehouse__c getSavedRecord() {
        insert warehouse;
        return warehouse;
   }
    
}