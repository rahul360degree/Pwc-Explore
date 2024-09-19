trigger PJPPlatfromEventTrigger on PJP__c (after Update) {
    list<PJPRecordStatusChangeEvent__e> eventlist = new List<PJPRecordStatusChangeEvent__e>();
    for(PJP__c obj : Trigger.new){
        if(Trigger.oldMap.get(obj.Id).Status__c != obj.Status__c){
            if(obj.Status__c == 'Submit for Approval' || obj.Status__c =='Rejected'){
                PJPRecordStatusChangeEvent__e event = new PJPRecordStatusChangeEvent__e(
                	recordId__c = obj.Id,
                    Status__c = obj.Status__c
                
                );
                eventlist.add(event);
            }
        }
    }
    if(!eventlist.isEmpty()){
        EventBus.publish(eventlist);
    }
}