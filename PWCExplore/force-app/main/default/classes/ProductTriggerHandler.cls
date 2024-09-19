/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for 'Product' Trigger
Inputs:        NA
Test Class:    
History
23-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ProductTriggerHandler extends VTriggerHandler {
	
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ProductTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Nupoor Sharma
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Product Trigger
    Inputs:        list of inserted records
    Test Class:   
    
    History
    10-08-2020      Nupoor Sharma     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
		ProductRecordProcessor processor = new ProductRecordProcessor();
        //DE1093 - UAT 
        processor.deactivateblockedsignalItems(newItems);
    }

    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Product Trigger
    Inputs:        map of created records
    Test Class:   

    History
    23-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
		ProductRecordProcessor processor = new ProductRecordProcessor();
        processor.createStandardPriceBookEntry((map<Id, Product2>) newItems);
    }
    
    
    public override void BeforeUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
		ProductRecordProcessor processor = new ProductRecordProcessor();
     	
        List<Product2> productToUpdate = new List<Product2>();
        
        for(Id idItr : newItems.keySet()){
            if(((Product2)newItems.get(idItr)).Item_Signal__c != ((Product2)oldItems.get(idItr)).Item_Signal__c){
                productToUpdate.add((Product2)newItems.get(idItr));
            }    
        }
        //DE1093 - UAT 
        processor.deactivateblockedsignalItems(productToUpdate);
    }
}