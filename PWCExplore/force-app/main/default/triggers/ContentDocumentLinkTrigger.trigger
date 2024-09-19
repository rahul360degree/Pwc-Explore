trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,before update,after insert) {//added after insert by Shreela on 16th March 2023
    
    TriggerDispatcher.Run(new ContentDocumentLinkTriggerHandler());
       
}