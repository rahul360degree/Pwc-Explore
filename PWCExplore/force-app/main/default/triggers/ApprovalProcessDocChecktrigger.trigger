trigger ApprovalProcessDocChecktrigger on ProcessInstanceChangeEvent (after insert) {
List<ProcessInstanceChangeEvent> requestsToUpdate= new List<ProcessInstanceChangeEvent>();
    for(ProcessInstanceChangeEvent event: Trigger.new){
        requestsToUpdate.add(event);
    }

   Set<Id> checkRecs= new Set<Id>();
    for(ProcessInstanceChangeEvent event: Trigger.new){
        checkRecs.add(event.TargetObjectId);
    }
    
    Set<Id> conDocIdSet = new Set<Id>();
    Map<Id,List<Id>> recIdtoDocIdMap=new Map<Id,List<Id>>();
    for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:checkRecs]) {
			recIdtoDocIdMap.put(conDocLink.Id,new List<Id>{conDocLink.ContentDocumentId});                
        conDocIdSet.add(conDocLink.ContentDocumentId);
            }
    
    List<ContentVersion> docCheckList=new List<ContentVersion>([SELECT ContentDocumentId,Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN:conDocIdSet]); 
    List<UploadFilesCheckList__mdt> reqDocsMD=[SELECT RequiredDocuments__c FROM UploadFilesCheckList__mdt WHERE Label='TECH Termination Documents_Appliances'];
Map<Id,List<String>> rectoDocNameMap= new Map<Id,List<String>>();
    
    for(Id keyrec: recIdtoDocIdMap.keySet()){
        List<Id> docIds=recIdtoDocIdMap.get(keyrec);
        List<String> docNames= new List<String>();
        
        for(Id a:docIds){
            for(ContentVersion con:docCheckList){
                if(con.Id==a){
                    docNames.add(con.Document_Name__c);
                    break;
                }
            }
        }
       
        rectoDocNameMap.put(keyrec,docNames);
        
    }

}