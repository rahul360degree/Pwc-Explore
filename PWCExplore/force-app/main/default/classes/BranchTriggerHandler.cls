/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for 'Branch__C' Trigger
Inputs:        NA
Test Class:    
History
15-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class BranchTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.BranchTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Branch Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    15-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        BranchRecordHandler recordHandler = new BranchRecordHandler();
        recordHandler.populateDefaultsOnBranch((list<Branch__c>)newItems);
        recordHandler.updateAddressesOnBranch((list<Branch__c>)newItems);
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if(setting.Fire_Tax_Validation_on_Address_By_BP__c)
              recordHandler.validateTaxNumberForSelectedAddress((list<Branch__c>)newItems); 
     }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Branch Trigger
    Inputs:        map of created records
    Test Class:   

    History
    15-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        BranchRecordHandler recordHandler = new BranchRecordHandler();
        recordHandler.createAddressByBPRecords((list<Branch__c>)newItems.values());
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Update event context of Branch Trigger
    Inputs:        map of created records
    Test Class:   

    History
    26-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        BranchRecordHandler recordHandler = new BranchRecordHandler();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if(setting.Fire_Tax_Validation_on_Address_By_BP__c)
            recordHandler.validateTaxNumberForSelectedAddress((list<Branch__c>)newItems.values());
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Branch Trigger
    Inputs:        map of created records
    Test Class:   

    History
    15-05-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        BranchRecordHandler recordHandler = new BranchRecordHandler();
        recordHandler.CheckAndCreateAddressByBPRecords((map<Id, Branch__c>) newItems, (map<Id, Branch__c>) oldItems);
        
    }
}