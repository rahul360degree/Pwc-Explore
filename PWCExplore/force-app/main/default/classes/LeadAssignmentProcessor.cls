/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   class to assign Leads in Round Robin fashion
Inputs:        map of created records
Test Class:   

History
09-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class LeadAssignmentProcessor {

    public Map<Id,SObject> rulesAndLeadsToUpdate=new Map<Id,SObject>();
    public Map<String,Id> queueNameVsId=new Map<String,Id>();
    Set<String> businessUnitsToConsiderAssignedLeadsLimit=new Set<String>{GlobalConstants.APPLIANCE_BUSINESS_UNIT};
    Map<Id,Integer> memberVsLeadsAssigned=new Map<Id,Integer>(); 
    
        /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to process lead assignment
    Inputs:        leads
    outputs:       
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public void processAssignment(List<Lead> leads) {
        Map<Id,List<Lead>> zipRuleIdVsLeads=new Map<Id,List<Lead>>();
        for(Lead l:leads){
            if(l.Zip_Code_Rule__c!=null){
                if(!zipRuleIdVsLeads.containsKey(l.Zip_Code_Rule__c))
                    zipRuleIdVsLeads.put(l.Zip_Code_Rule__c,new List<Lead>{l});
                else 
                    zipRuleIdVsLeads.get(l.Zip_Code_Rule__c).add(l);
            }
        }
        Map<Id,Map<String,List<Lead>>> ruleVsQueueVsLeads=assignLeadsToQueue(zipRuleIdVsLeads);
        Set<String> queues=new Set<String>();
        for(Id rule:ruleVsQueueVsLeads.keySet()){
            queues.addAll(ruleVsQueueVsLeads.get(rule).keySet());
        }
        Map<String,List<Id>> queueVsMemberIds=Utility.getQueueMembers(queues);
        Set<Id> allMembers=new Set<Id>(); 
        for(String q:queueVsMemberIds.keySet()){
            allMembers.addAll(queueVsMemberIds.get(q));
        }
        Set<Id> outOfOfficeAndInactiveMembers=Utility.getOutOfOfficeAndInactiveUsers(allMembers);
        outOfOfficeAndInactiveMembers.addAll(removeUsersWhoExceededLimit(allMembers));
        for(Id rule:ruleVsQueueVsLeads.keySet()){
            Lead leadRec;
            for(String q:ruleVsQueueVsLeads.get(rule).keySet()){
                leadRec=ruleVsQueueVsLeads.get(rule).get(q)[0];
            }
            if(leadRec!=null && leadRec.Zip_Code_Rule__r.Queues_And_LastAssignedId__c!=null){
                Map<String,Object> queueVsLastAssigned=(Map<String,Object>)JSON.deserializeUntyped(leadRec.Zip_Code_Rule__r.Queues_And_LastAssignedId__c);
                for(String q:ruleVsQueueVsLeads.get(rule).keySet()){
                    Map<String,Object> filteredMembersAndIndex=getFilteredMembers(queueVsMemberIds.containsKey(q)?queueVsMemberIds.get(q):null,outOfOfficeAndInactiveMembers,
                                                                          queueVsLastAssigned.containsKey(q)?(String)queueVsLastAssigned.get(q):null);
                    List<Id> userIds=(List<Id>)filteredMembersAndIndex.get('finalApplicableUserIds');
                    Integer indexToStart=(Integer) filteredMembersAndIndex.get('indexToStartFrom');
                    if(userIds.size()>0 && indexToStart!=null && indexToStart>=0){
                        for(Sobject record : assignLeadsToQueueMembers(ruleVsQueueVsLeads.get(rule).get(q),(List<Id>)filteredMembersAndIndex.get('finalApplicableUserIds')
                                                ,(Integer) filteredMembersAndIndex.get('indexToStartFrom'),queueVsLastAssigned)){
                            if(!rulesAndLeadsToUpdate.containsKey(record.Id))
                                rulesAndLeadsToUpdate.put(record.Id,record);
                            else{
                                if(record.getsObjectType() == Zip_Code_Rule__c.sObjectType){ 
                                        Zip_Code_Rule__c zipRule= (Zip_Code_Rule__c)rulesAndLeadsToUpdate.get(record.Id);
                                        zipRule.Queues_And_LastAssignedId__c=(String)record.get('Queues_And_LastAssignedId__c');
                                        rulesAndLeadsToUpdate.put(record.Id,zipRule);
                                }
                                else{
                                        Lead ldRec=(Lead)rulesAndLeadsToUpdate.get(record.Id);
                                        ldRec.OwnerId=(Id)record.get('OwnerId');
                                        rulesAndLeadsToUpdate.put(record.Id,ldRec);
                                }
                            }
                        }
                        
                    }     
                }
            }
        }
        
        

        List<Sobject> sobjectsToUpdate=new List<Sobject>();
        List<Sobject> tempListOfLeads=new List<Sobject>();
        Id defaultQueueId=[select Id From Group Where Type = 'Queue' AND DeveloperName = :GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE].Id;
        for(Sobject sobj:rulesAndLeadsToUpdate.values()){
            if(sobj.getsObjectType() == Zip_Code_Rule__c.sObjectType)
                sobjectsToUpdate.add(sobj);
            else{
                /* SAF-73: Added criteria to for SAF-73*/
                Lead lead = (Lead) sObj;
                if(lead.Business_Unit__c =='H' &&  !(''+lead.OwnerId).startsWith('005') && lead.OwnerId !=defaultQueueId){
                    lead.OwnerId = defaultQueueId;
                }
                tempListOfLeads.add(sobj);
            }
                
        }
        sobjectsToUpdate.addAll(tempListOfLeads);
        try{
            if(sobjectsToUpdate.size()>0){
                Runtime_Execution__c runtimeExecution=[Select Id,FireLeadValidationRules__c From Runtime_Execution__c Limit 1];
                runtimeExecution.FireLeadValidationRules__c=false;
                Database.update(runtimeExecution,true);
                
                //logic added by SFDC team to resolve the multiple chunk issue
                //sobjectsToUpdate.sort();
                sobjectsToUpdate = sortChunks(sobjectsToUpdate);
                Database.update(sobjectsToUpdate,true);

                runtimeExecution.FireLeadValidationRules__c=true;
                Database.update(runtimeExecution,true);
            }
        }
        catch(exception ex){
            Logger.logError('LeadAssignmentProcessor', '', '', ex);
        }
    }

    public Set<Id> removeUsersWhoExceededLimit(Set<Id> allMembers){
        Integer leadLimit=Integer.ValueOf(System.Label.Appliance_D2D_Lead_limit_Per_Day);
        Set<Id> usersPastLimit=new Set<Id>(); 
        for(AggregateResult ar  : [Select Count(Id)totalLeadsAssigned,OwnerId From Lead 
                                   Where OwnerId In:allMembers 
                                   And Zip_Code_Rule__c!=null
                                   And Business_Unit__c=:GlobalConstants.APPLIANCE_BUSINESS_UNIT
                                   //Modofied by Praful - 01-Dec-2020 - OTRS-30257796
                                   //Modified by Dinesh G-16-Dec-2020 
                                   And (CreatedDate=Today OR Status='new') 
                                   Group By OwnerId]){
            if(((Integer)ar.get('totalLeadsAssigned'))>=leadLimit)
             usersPastLimit.add((Id)ar.get('OwnerId'));
        }
        return usersPastLimit;
    }

        /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to assign Leads in Round Robin fashion to queues
    Inputs:        map of ruleId and list of its matching leads
    outputs:       It provides a map of ruleVsQueuesVsLeads (only returns the queues where round robin on members is allowed further)
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public Map<Id,Map<String,List<Lead>>> assignLeadsToQueue(Map<Id,List<Lead>> zipRuleIdVsLeads){
        Map<Id,Integer> ruleVsNumberOfQueues=new Map<Id,Integer>(); 
        Set<String> queueNames=new Set<String>();
        for(Id ruleId:zipRuleIdVsLeads.keySet()){
            Integer numberOfQueues=0;
            for(Integer i=1;i<=7;i++){
                if(!String.isBlank((String)zipRuleIdVsLeads.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Queue_'+i+'__c'))){
                    queueNames.add((String)zipRuleIdVsLeads.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Queue_'+i+'__c'));
                    numberOfQueues++;
                }
            }
            ruleVsNumberOfQueues.put(ruleId,numberOfQueues);
        }
        queueNameVsId=Utility.getQueueNameVsIds(queueNames);
        Map<Id,Map<String,List<Lead>>> ruleVsQueueVsLeads=new Map<Id,Map<String,List<Lead>>>();
        for(Id ruleId:zipRuleIdVsLeads.keySet()){ 
            Integer sequence=zipRuleIdVsLeads.get(ruleId)[0].Zip_Code_Rule__r.Sequence__c!=null?(Integer)zipRuleIdVsLeads.get(ruleId)[0].Zip_Code_Rule__r.Sequence__c:1;
            Map<String,List<Lead>> tempQueueVsLeads=new Map<String,List<Lead>>();
            for(Lead l:zipRuleIdVsLeads.get(ruleId)){
                if(ruleVsNumberOfQueues.get(ruleId)>0){
                    Integer mod=math.mod(sequence,ruleVsNumberOfQueues.get(ruleId));
                    mod=mod==0?ruleVsNumberOfQueues.get(ruleId):mod;
                    String queueDevName=(String)l.getSobject('Zip_Code_Rule__r').get('Queue_'+mod+'__c');
                    String queueId=queueNameVsId.containsKey(queueDevName)?queueNameVsId.get(queueDevName):null;
                    Boolean performRROnQueue=(Boolean)l.getSobject('Zip_Code_Rule__r').get('Run_Round_Robin_on_Queue'+mod+'__c');
                    
                    if(queueId!=null){
                        l.ownerId=queueId;
                        if(performRROnQueue){
                            if(!tempQueueVsLeads.containsKey(queueDevName))
                            tempQueueVsLeads.put(queueDevName,new List<Lead>{l});
                            else
                            tempQueueVsLeads.get(queueDevName).add(l);
                        }
                        rulesAndLeadsToUpdate.put(l.Id,l);
                        sequence++;
                    }
                }   
            }
            ruleVsQueueVsLeads.put(ruleId,tempQueueVsLeads);
            rulesAndLeadsToUpdate.put(ruleId,new Zip_Code_Rule__c(Id=ruleId,Sequence__c=sequence)); 
        }
        return ruleVsQueueVsLeads;
    }

        /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to get final filtered valid queue member ids and index of  queue member ids list to start round robin assignment from
    Inputs:        allUserIds-> all queue member ids
                   userIdsToRemove-> invalid queue members ids(out of office and inactive users)
                   lastAssignedId-> last assigned queue member id for corresponding queue.
    outputs:       
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public Map<String,Object> getFilteredMembers(List<Id> allUserIds,Set<Id> userIdsToRemove,String lastAssignedId){
        List<Id> filteredMembers=new List<Id>(); 
        if(allUserIds!=null){
            for(Id userId:allUserIds){
                if(!userIdsToRemove.contains(userId))
                filteredMembers.add(userId);
            }
        }
        filteredMembers.sort();
        Integer index=0;
        if(!String.isBlank(lastAssignedId)){
            Boolean removeLastAssignedId=!filteredMembers.contains(lastAssignedId)?true:false;
            if(removeLastAssignedId){
                filteredMembers.add(lastAssignedId);
                filteredMembers.sort();
            }
            index=filteredMembers.indexOf(lastAssignedId)+1>filteredMembers.size()-1?0:filteredMembers.indexOf(lastAssignedId)+1;
            Id nextValidId=filteredMembers[index];
            if(removeLastAssignedId){
                Integer tempIndex=filteredMembers.indexOf(lastAssignedId);
                if(tempIndex!=-1)
                filteredMembers.remove(tempIndex);
                filteredMembers.sort(); 
                index=filteredMembers.indexOf(nextValidId); 
            } 
        }
        return new Map<String,Object>{'finalApplicableUserIds'=>filteredMembers,
                                      'indexToStartFrom'=>index};  
    }

    
       /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description: method to assign leads to queue members in ROUND ROBIN  
    Inputs:        
    outputs:       
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public List<SObject> assignLeadsToQueueMembers(List<Lead> leads,List<Id> userIds,Integer indexToStartFrom,Map<String,Object> queueVsLastAssigned){
        Integer leadLimit=Integer.ValueOf(System.label.Appliance_D2D_Lead_limit_Per_Day);
        List<SObject> rulesAndLeads=new List<SObject>(); 
        Id lastAssignedId;
        String queueName;
        Id queueId=leads[0].ownerId;
        for(String name:queueNameVsId.keySet()){
            if(queueNameVsId.get(name)==queueId)
            queueName=name;
        }
        Boolean considerLeadLimitForMembers=(leads.Size()>0 && businessUnitsToConsiderAssignedLeadsLimit.contains(leads[0].Business_Unit__c))?true:false;
        if(queueName!=null){
                                //Line 252-262 add by Dinesh G-16-Dec-2020 
             for(AggregateResult ar  : [Select Count(Id)totalLeadsAssigned,OwnerId From Lead 
                                   Where OwnerId In:userIds 
                                   And Zip_Code_Rule__c!=null
                                   And Business_Unit__c=:GlobalConstants.APPLIANCE_BUSINESS_UNIT
                                   And (CreatedDate=Today OR Status='new')
                                   Group By OwnerId]){
                                       if(((Integer)ar.get('totalLeadsAssigned'))!=null && ((Integer)ar.get('totalLeadsAssigned'))< leadLimit){
                                        memberVsLeadsAssigned.put((Id)ar.get('OwnerId'),(Integer)ar.get('totalLeadsAssigned'));
                                         
                                       }
                                   }
            if(leads.Size()>0 && considerLeadLimitForMembers){
                for(Lead l:leads){
                    if(userIds.Size()>0 && memberVsLeadsAssigned.containsKey(userIds[indexToStartFrom]) && memberVsLeadsAssigned.get(userIds[indexToStartFrom]) < leadLimit){
                        l.ownerId=userIds[indexToStartFrom];
                        lastAssignedId=userIds[indexToStartFrom];
                        Integer leadsAssigned=(memberVsLeadsAssigned.get(userIds[indexToStartFrom]))+1;
                        memberVsLeadsAssigned.put(userIds[indexToStartFrom],leadsAssigned);
                        if(leadsAssigned >= leadLimit){
                            userIds.remove(indexToStartFrom);
                            if(indexToStartFrom>userIds.size()-1 && userIds.size()>=1)
                              indexToStartFrom=0;
                        }
                        else{
                            indexToStartFrom+=1;
                            if(indexToStartFrom>userIds.size()-1)
                              indexToStartFrom=0;
                        }
                    }
                    else if(userIds.Size()>0 && !memberVsLeadsAssigned.containsKey(userIds[indexToStartFrom])){
                        l.ownerId=userIds[indexToStartFrom];
                        lastAssignedId=userIds[indexToStartFrom];
                        memberVsLeadsAssigned.put(userIds[indexToStartFrom],1);
                        indexToStartFrom+=1;
                        if(indexToStartFrom>userIds.size()-1)
                        indexToStartFrom=0;

                    }  
                    rulesAndLeads.add(l);  
                }
            } 
            else{
                for(Lead l:leads){
                    l.ownerId=userIds[indexToStartFrom];
                    lastAssignedId=userIds[indexToStartFrom];
                    indexToStartFrom+=1;
                    if(indexToStartFrom>userIds.size()-1)
                        indexToStartFrom=0;
                    rulesAndLeads.add(l);    
                }
            }
            queueVsLastAssigned.put(queueName,lastAssignedId);
            if(rulesAndLeadsToUpdate.containsKey(leads[0].Zip_Code_Rule__c)){
                Zip_Code_Rule__c zipRule=(Zip_Code_Rule__c)rulesAndLeadsToUpdate.get(leads[0].Zip_Code_Rule__c);
                zipRule.Queues_And_LastAssignedId__c=JSON.Serialize(queueVsLastAssigned);
                rulesAndLeadsToUpdate.put(leads[0].Zip_Code_Rule__c,zipRule);
            }
            rulesAndLeads.add(new Zip_Code_Rule__c(id=leads[0].Zip_Code_Rule__c,Queues_And_LastAssignedId__c=JSON.Serialize(queueVsLastAssigned))) ;
        }
        return rulesAndLeads;
    }
    
    public static List<SObject> sortChunks(List<SObject> scope) {
        Map<String, List<SObject>> sortMap = new Map<String, List<SObject>>();
        for ( SObject rec: scope ) {
            String keyPrefix = rec.getSObjectType().getDescribe().getName();
            if (!sortMap.containsKey(keyPrefix)) {
            	sortMap.put(keyPrefix, new List<SObject>());
            }
        	sortMap.get(keyPrefix).add( rec );
        }
        List<SObject> flattenedList = new List<SObject>();
        for ( String key: sortMap.keySet() ) {
        	flattenedList.addAll( sortMap.get( key ) );
        }
        return flattenedList;
    }
}