public class ContentDocumentLinkTriggerHandler extends VTriggerHandler{
	public override void BeforeInsert(list<SObject> newItems){
        ContentDocumentLinkTriggerHelper contentHelper = new ContentDocumentLinkTriggerHelper();
        contentHelper.statementOfAccountVisibility(newItems);
        
        
    }
    
    //Added by Shreela on 16th March 2023
    public override void AfterInsert(Map<Id, SObject> newItems){
        ContentDocumentLinkTriggerHelper contentHelper = new ContentDocumentLinkTriggerHelper();
        contentHelper.sendEmailonInsertionofAttachmentandNotes((Map<Id,ContentDocumentLink>)newItems); //Modified method name by Shreela on 29th May 2023
        
        contentHelper.setShareType(newItems.values()); //Added by Shreela & Varun on 3rd August 2023
         contentHelper.setVisibilityOfBSOFilesForExternalUsers(newItems.values()); //Added by Shreela for SMEPB - 119 on 14th September 2023
        
    }
}