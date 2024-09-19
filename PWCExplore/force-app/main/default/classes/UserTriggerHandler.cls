public with sharing class UserTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction.
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code.
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.UserTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*--------------------------------------------------------------------------------------
     Author:       Shailja
     Company:      Salesforce
     Description:  Method is responsible for handling before insert operations
     Inputs:       List<SObject>
    ----------------------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        UserRecordProcessor.populateAssociatedAccountName((List<User>)newItems);
        UserRecordProcessor.populateAccountDetailsBasedOnBPCode((List<User>)newItems);
        UserRecordProcessor.validateSalesOffice((List<User>)newItems);
        UserRecordProcessor.validateWarehouses((List<User>)newItems);
    }
    
    /*--------------------------------------------------------------------------------------
     Author:       Shailja
     Company:      Salesforce
     Description:  Method is responsible for handling before update operations
     Inputs:       Map<Id, SObject>, Map<Id, SObject>
    ----------------------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        UserRecordProcessor.populateAssociatedAccountName((List<User>)newItems.values(), (Map<Id, User>)oldItems);
        UserRecordProcessor.populateAccountDetailsBasedOnBPCode((List<User>)newItems.values(), (Map<Id, User>)oldItems);
        UserRecordProcessor.validateSalesOffice((List<User>)newItems.values(), (Map<Id, User>)oldItems);
        UserRecordProcessor.validateWarehouses((List<User>)newItems.values());
        
    }
}