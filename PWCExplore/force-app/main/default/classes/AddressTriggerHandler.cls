/*------------------------------------------------------------------------
Author:        Rohit Jadhav
Company:       Salesforce
Description:   Handler class for Address__c Trigger
Inputs:        NA
Test Class:    
History
26-05-2020      Rohit Jadhav     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AddressTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AddressTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    public override void BeforeInsert(list<SObject> newItems){
        AddressTriggerHelper helper = new AddressTriggerHelper();
        helper.validateQueueName((list<Address__c>) newItems,null);
    }
    
    public override void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        AddressTriggerHelper helper = new AddressTriggerHelper();
        helper.validateQueueName((list<Address__c>) newItems.values(),(Map<Id,Address__c>) oldItems);
    }
}