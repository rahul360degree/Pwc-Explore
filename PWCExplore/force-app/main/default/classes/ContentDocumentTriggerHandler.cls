public with sharing class ContentDocumentTriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction.
    public static Boolean TriggerDisabled = false;
    
    public static List<Order> ordersToBeUpdated = new List<Order>();
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code.
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ContentDocumentDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }

    public override void BeforeDelete(map<Id, sObject> oldItems) {
        Set<String> orderIds = new Set<String>();
        String attendancePrefix = Schema.getGlobalDescribe().get('Attendance__c'). getDescribe(). getKeyPrefix();

        List<ContentDocumentLink> cdLinks = [SELECT ContentDocument.title,LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN: oldItems.keySet()];
        if (cdLinks != null && cdLinks.size() > 0){
            for (ContentDocumentLink cdLink : cdLinks) {
                if (cdLink.LinkedEntityId != null) {
                    if (String.valueOf(cdLink.LinkedEntityId).startsWith('801')) {
                        orderIds.add(cdLink.LinkedEntityId);
                    }
                    if (String.valueOf(cdLink.LinkedEntityId).startsWith(attendancePrefix)) {
                        oldItems.get(cdLink.ContentDocumentId).addError(Label.Attendance_Attachment_Delete_Error);
                    }
                }
            }
        }

        for(String orderId : orderIds){
            Order orderToBeUpdated = new Order();
            orderToBeUpdated.Id = orderId;
            orderToBeUpdated.Has_Attachment__c = false;
            ordersToBeUpdated.add(orderToBeUpdated);
        }
    }

    public override void AfterDelete(map<Id, sObject> oldItems) {
        if(ordersToBeUpdated != null && ordersToBeUpdated.size() > 0) update ordersToBeUpdated;
    }

}