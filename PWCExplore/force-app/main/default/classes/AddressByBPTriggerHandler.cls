/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Address_by_BP__c Trigger
Inputs:        NA
Test Class:    
History
26-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AddressByBPTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AddressByBPTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Address_by_BP__c Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    26-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        AddressByBPTriggerHelper helper = new AddressByBPTriggerHelper();
        helper.populateDefaults((list<Address_by_BP__c>) newItems); //To get the Account and Branch details from the Address By BP details in SOAP Request and associate it either with existing account and branch or dummy account
        helper.updateAddressByBPRecordTypeAndAccount((list<Address_by_BP__c>) newItems);
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        
        if(setting.Fire_Tax_Validation_on_Address_By_BP__c)
            helper.validateTaxNumberForSelectedAddress((list<Address_by_BP__c>) newItems);
        
        helper.updateAccountNameOnAddressByBP((list<Address_by_BP__c>) newItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Update event context of Address_by_BP__c Trigger
    Inputs:        map of created records
    Test Class:   

    History
    26-05-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        AddressByBPTriggerHelper helper = new AddressByBPTriggerHelper();
        
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if(setting.Fire_Tax_Validation_on_Address_By_BP__c)
            helper.validateTaxNumberForSelectedAddress((list<Address_by_BP__c>) newItems.values());
    }
}