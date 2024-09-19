public with sharing class CommissionTriggerHandler extends VTriggerHandler{
    public static Boolean tiggerDisabled = false;

    /*
     *   Checks to see if the trigger has been disabled either by custom setting or by running code
     */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.CommissionsTriggerDisabled__c)
            return true;
        else
            return tiggerDisabled;
    }

    public override void BeforeInsert(List<SObject> newItems){
        CommissionTriggerHandlerHelper helper = new CommissionTriggerHandlerHelper();
        helper.setDefaultsOnCreditShareRequest((List<Commission__c>) newItems);
    }

    public override void AfterInsert(Map<Id, SObject> newItems){
        CommissionTriggerHandlerHelper helper = new CommissionTriggerHandlerHelper();
        helper.shareCreditRequest((List<Commission__c>) newItems.values());
    }

    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        CommissionTriggerHandlerHelper helper = new CommissionTriggerHandlerHelper();
        helper.generateCommissionRecords((Map<Id,Commission__c>) newItems, (Map<Id,Commission__c>) oldItems);
    }
}