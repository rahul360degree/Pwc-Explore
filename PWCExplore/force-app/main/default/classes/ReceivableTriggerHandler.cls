/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Handler class for Receivable Trigger
               Object Name - Line Item (Receivable__c)
Test Class:    
---------------------------------------------------------------------------
History
01-12-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ReceivableTriggerHandler extends VTriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ReceivableTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

   /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle Before Insert  event context of 'Receivable' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    01-12-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        ReceivableTriggerHelper helper = new ReceivableTriggerHelper();
        helper.populateDefaultsOnReceivable((List<Receivable__c>) newItems);
        helper.populateSalesRepresentative((List<Receivable__c>) newItems);
        SharingUtility.setParentContacts(newItems, null, false, false);
    }

    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle Before update  event context of 'Receivable' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    01-12-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, false);
        ReceivableTriggerHelper helper = new ReceivableTriggerHelper();
        helper.updateSalesRepresentative(newItems,oldItems);
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle After Insert event context of 'Receivable' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    01-12-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        ReceivableTriggerHelper helper = new ReceivableTriggerHelper();
        helper.createCommissionsRecordForInvoiceTypeRecords((Map<Id, Receivable__c>) newItems);
    }
}