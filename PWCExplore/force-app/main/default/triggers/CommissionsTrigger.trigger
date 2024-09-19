trigger CommissionsTrigger on Commission__c (before insert, after insert, after update, before update) {
    TriggerDispatcher.Run(new CommissionTriggerHandler());
}