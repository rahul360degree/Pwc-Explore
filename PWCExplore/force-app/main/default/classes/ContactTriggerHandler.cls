public with sharing class ContactTriggerHandler extends VTriggerHandler {
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AccountTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){    
        ContactFieldPopulator populator = new ContactFieldPopulator();
        populator.checkMandatoryDocuments((map<Id, Contact>) newItems);
        
        

    }
    
}