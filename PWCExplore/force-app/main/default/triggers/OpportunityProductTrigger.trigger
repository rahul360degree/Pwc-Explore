trigger OpportunityProductTrigger on OpportunityLineItem (before insert, before update, After delete) {
    TriggerDispatcher.Run(new OppProductTriggerHandler());
}