trigger ContentVersionTrigger on ContentVersion (after insert) {
    TriggerDispatcher.Run(new ContentVersionTriggerHandler());
}