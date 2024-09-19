public with sharing class ContentVersionTriggerHandler extends VTriggerHandler {

    // Allows unit tests (or other code) to disable this trigger for the transaction.
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code.
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ContentVersionDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

    public override void AfterInsert(map<Id, sObject> newItems) {
        //Get all ContentDocument
        Set<String> contentDocumentIds = new Set<String>();
        Set<String> orderIds = new Set<String>();
        for(ContentVersion cv : (List<ContentVersion>)newItems.values()){
            contentDocumentIds.add(cv.ContentDocumentId);
        }

        List<ContentDocumentLink> cdLinks = [SELECT ContentDocument.title,LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN: contentDocumentIds];

        if( cdLinks != null && cdLinks.size() > 0){
            for(ContentDocumentLink cdLink : cdLinks){
                if(cdLink.LinkedEntityId != null && String.valueOf(cdLink.LinkedEntityId).startsWith('801')){
                    orderIds.add(cdLink.LinkedEntityId);
                }
            }
        }

        List<Order> orderList = new List<Order>();
        for(String orderId : orderIds){
            Order orderToBeUpdated = new Order();
            orderToBeUpdated.Id = orderId;
            orderToBeUpdated.Has_Attachment__c = true;
            orderList.add(orderToBeUpdated);
        }

        if(orderList.size() > 0){
            try{
                update orderList;
            }catch(Exception ex){
               Logger.logError('ContentVersionTriggerHandler', 'AfterInsert', '', ex);
            }
        }
    }   
}