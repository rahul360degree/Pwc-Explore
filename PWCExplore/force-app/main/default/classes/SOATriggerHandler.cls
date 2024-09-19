/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-28-2023
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class SOATriggerHandler extends VTriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    public override void BeforeInsert(list<SObject> newItems){
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){ 
    }

    public override void AfterInsert(map<Id, sObject> newItems){
    }

    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        SOATriggerHelper.executeBatchToSendEmail((map<Id, Statement_of_Account__c>)newItems,(map<Id, Statement_of_Account__c>)oldItems);
    }
}