trigger ContentDocumentTrigger on ContentDocument (before delete,after delete) {
    TriggerDispatcher.Run(new ContentDocumentTriggerHandler());
}