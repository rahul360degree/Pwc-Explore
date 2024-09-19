/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Handler class for 'Tax Number' Trigger
Inputs:        NA
Test Class:    
History
10-06-2020      Kartik Shetty     Initial Release.
----------------------------------------------------------------------------*/
public with sharing class TaxNumberTriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.TaxNumberTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle before Insert event context of 'Tax Number' Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    10-06-2020      Kartik Shetty     Initial Release.
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems) {
        TaxNumberRecordProcessor recordProcessor = new TaxNumberRecordProcessor();
        recordProcessor.populateDefaults((List<Tax_Number__c>) newItems);
        recordProcessor.performTaxNumberValidations((List<Tax_Number__c>) newItems);
    }

   /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 'Tax Number' Trigger
    Inputs:        map of created records
    Test Class:   

    History
    10-06-2020      Kartik Shetty     Initial Release.
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems) {
        TaxNumberRecordProcessor recordProcessor = new TaxNumberRecordProcessor();
        recordProcessor.performTaxNumberValidations((List<Tax_Number__c>) newItems.values());
        
        
        
        
        
        
        
        
    }
}