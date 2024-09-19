/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   class to assign Sobjects in Round Robin fashion based on Zip Code 
Inputs:        
Test Class:   

History
09-05-2020      Manasi Londhe     Initial Release
16-10-2020	    Kishor Kumar	  Updated to make it Generic
----------------------------------------------------------------------------*/
public without sharing class ZipCodeBasedAssignmentProcessor {

    public Map<Id,SObject> rulesAndSobjectRecordsToUpdate = new Map<Id,SObject>();
    public Map<String,Id> queueNameVsId = new Map<String,Id>();
    map<String, Object> businessUnitsVsLimit = new map<String, Object>();
    Map<Id,Integer> memberVsSobjectRecordsAssigned = new Map<Id,Integer>(); 
    String sObjectName;
    String sObjectLabel;
    string objectLabelTrimmed;
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to process Sobject assignment
    Inputs:        Sobjects list
    outputs:       
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
	16-10-2020	    Kishor Kumar	  Updated to make it Generic
    ----------------------------------------------------------------------------*/
    public void processAssignment(List<SObject> sobjectRecords) {
        Map<Id,List<SObject>> zipRuleIdVsSobjectRecords = new Map<Id, List<SObject>>();
        
        //Fetch Sobject details  
        if(sobjectRecords.size() >= 0){
            sObjectName = ((Id)sobjectRecords[0].get('Id')).getSObjectType().getDescribe().getName();
            sObjectLabel = ((Id)sobjectRecords[0].get('Id')).getSObjectType().getDescribe().getLabel();
            objectLabelTrimmed = sObjectLabel.replaceAll( '\\s+', '');
        } 
        
        //Fetch Assignment limit for Business Unit from Custom label
        String assignmentLimitJSON = System.label.Zip_Code_based_assignment_limit;
        Map<String, Object> assignmentLimitMap = (Map<String, Object>)JSON.deserializeUntyped(assignmentLimitJSON);
        Map<String, Object> objectVsLimitJson = (Map<String, Object>)assignmentLimitMap.get('AssignmentLimit');
        if(objectVsLimitJson.containsKey(objectLabelTrimmed)){
            businessUnitsVsLimit = (Map<String, Object>)objectVsLimitJson.get(objectLabelTrimmed);
        }
        
        for(SObject sobjeRec : sobjectRecords){
            Id zipCodeRuleId = (Id)sobjeRec.get('Zip_Code_Rule__c');
            if(zipCodeRuleId != null){
                if(!zipRuleIdVsSobjectRecords.containsKey(zipCodeRuleId))
                    zipRuleIdVsSobjectRecords.put(zipCodeRuleId, new List<SObject>{sobjeRec});
                else 
                    zipRuleIdVsSobjectRecords.get(zipCodeRuleId).add(sobjeRec);
            }
        }

        //Logic to assign records to Queue
        Map<Id,Map<String,List<SObject>>> ruleVsQueueVsSobjectRecords = assignSObjectToQueue(zipRuleIdVsSobjectRecords);
        Set<String> queues = new Set<String>();
        
        for(Id rule : ruleVsQueueVsSobjectRecords.keySet()){
            queues.addAll(ruleVsQueueVsSobjectRecords.get(rule).keySet());
        }
        
        //Method to fetch Queue members for Queues
        Map<String,List<Id>> queueVsMemberIds = Utility.getQueueMembers(queues);
        
        Set<Id> allMembers = new Set<Id>(); 
        
        for(String q : queueVsMemberIds.keySet()){
            allMembers.addAll(queueVsMemberIds.get(q));
        }
        Set<Id> outOfOfficeAndInactiveMembers = new Set<Id>();
        //Logic to find Inactive/ Out of Office / Already Limit exceeded users from Queue members
        if(UserInfo.getUserType() <> 'PowerPartner'){
        outOfOfficeAndInactiveMembers = Utility.getOutOfOfficeAndInactiveUsers(allMembers);
        outOfOfficeAndInactiveMembers.addAll(removeUsersWhoExceededLimit(allMembers));

        }

        for(Id rule : ruleVsQueueVsSobjectRecords.keySet()){            
            SObject sRecord;
            
            for(String q : ruleVsQueueVsSobjectRecords.get(rule).keySet()){
                sRecord = ruleVsQueueVsSobjectRecords.get(rule).get(q)[0];
            }
            
            if(sRecord != null && sRecord.getSobject('Zip_Code_Rule__r').get('Queues_And_LastAssignedId__c') != null){
                //Logic to find the last assigned member for queues
                Map<String,Object> queueVsLastAssigned = (Map<String,Object>)JSON.deserializeUntyped((String)sRecord.getSobject('Zip_Code_Rule__r').get('Queues_And_LastAssignedId__c'));
                
                for(String q : ruleVsQueueVsSobjectRecords.get(rule).keySet()){
                    Map<String, Object> filteredMembersAndIndex = getFilteredMembers(queueVsMemberIds.containsKey(q) ? queueVsMemberIds.get(q): null, outOfOfficeAndInactiveMembers,
                                                                          queueVsLastAssigned.containsKey(q) ? (String)queueVsLastAssigned.get(q) : null);
                    
                    List<Id> userIds = (List<Id>)filteredMembersAndIndex.get('finalApplicableUserIds');
                    Integer indexToStart = (Integer) filteredMembersAndIndex.get('indexToStartFrom');
                    
                    if(userIds.size() > 0 && indexToStart != null && indexToStart >= 0){
                        //Logic to assign Records among Queue members for a Queue  
                        for(Sobject record : assignsObjectRecordsToQueueMembers(ruleVsQueueVsSobjectRecords.get(rule).get(q), (List<Id>)filteredMembersAndIndex.get('finalApplicableUserIds'), 
                                                (Integer) filteredMembersAndIndex.get('indexToStartFrom'), queueVsLastAssigned)){
                                                    
                            if(!rulesAndSobjectRecordsToUpdate.containsKey(record.Id))
                                rulesAndSobjectRecordsToUpdate.put(record.Id,record);
                            else {
                                if(record.getsObjectType() == Zip_Code_Rule__c.sObjectType){ 
                                        Zip_Code_Rule__c zipRule = (Zip_Code_Rule__c)rulesAndSobjectRecordsToUpdate.get(record.Id);
                                        zipRule.Queues_And_LastAssignedId__c = (String)record.get('Queues_And_LastAssignedId__c');
                                        rulesAndSobjectRecordsToUpdate.put(record.Id, zipRule);
                                } else {
                                    	SObject objRec = (SObject)(Type.forName('Schema.'+ sObjectName).newInstance());
                                    	objRec = rulesAndSobjectRecordsToUpdate.get(record.Id);
                                        objRec.put('OwnerId', (Id)record.get('OwnerId'));
                                        rulesAndSobjectRecordsToUpdate.put(record.Id, objRec);
                                }
                            }
                        }
                        
                    }     
                }
            }
        }
        
        List<Sobject> sobjectsToUpdate = new List<Sobject>();
        List<Sobject> tempListOfSobject = new List<Sobject>();
        
        for(Sobject sobj : rulesAndSobjectRecordsToUpdate.values()){
            if(sobj.getsObjectType() == Zip_Code_Rule__c.sObjectType)
                sobjectsToUpdate.add(sobj);
            else
                tempListOfSobject.add(sobj);
        }
        sobjectsToUpdate.addAll(tempListOfSobject);
        
        try{
            //Update all the records with assignment details
            if(sobjectsToUpdate.size() > 0){
                String validationRuleString = 'Fire'+ objectLabelTrimmed + 'ValidationRules__c';
                
                if(objectLabelTrimmed == 'ServiceRequest'){
                    validationRuleString = 'FireCaseValidationRules__c';
                }
                
                list<Runtime_Execution__c> runtimeExecutions = Database.query(
                							'SELECT Id, '+ validationRuleString + 
                    						' FROM Runtime_Execution__c LIMIT 1'
                							);
                
                runtimeExecutions[0].put(validationRuleString, false);
                update runtimeExecutions[0];
                Update sobjectsToUpdate;
                runtimeExecutions[0].put(validationRuleString, true);
                update runtimeExecutions[0];
            }
        }
        catch(exception ex){
            Logger.logError('ZipCodeBasedAssignmentProcessor', '', '', ex);
        }
    }
	
    //Method to check if any Queue memeber has already reched assignment limit for the day
    public Set<Id> removeUsersWhoExceededLimit(Set<Id> allMembers){
        Set<Id> usersPastLimit = new Set<Id>(); 
        
        if(!businessUnitsVsLimit.isEmpty()){
            set<String> businessUnits = businessUnitsVsLimit.keySet();
            
            List<AggregateResult> aggregateResults = Database.query(
                    'SELECT Count(Id)totalRecordsAssigned, OwnerId, Business_Unit__c FROM ' + sObjectName + 
                    ' WHERE OwnerId IN : allMembers' +  
                    ' AND Zip_Code_Rule__c != null' + 
                    ' AND Business_Unit__c IN: businessUnits ' + 
                    ' AND CreatedDate = TODAY' +  
                    ' Group By OwnerId, Business_Unit__c'
                );
           
            for(AggregateResult ar  : aggregateResults){
                if(((Integer)ar.get('totalRecordsAssigned')) >= Integer.valueOf(businessUnitsVsLimit.get((String)ar.get('Business_Unit__c'))))
                 	usersPastLimit.add((Id)ar.get('OwnerId'));
            }
        }
        return usersPastLimit;
    }
    
    

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to assign SObject Records in Round Robin fashion to queues
    Inputs:        map of ruleId and list of its matching sobject records
    outputs:       It provides a map of ruleVsQueuesVsSobjectRecords (only returns the queues where round robin on members is allowed further)
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
	16-10-2020	    Kishor Kumar	  Updated to make it Generic
    ----------------------------------------------------------------------------*/
    public Map<Id, Map<String, List<SObject>>> assignSObjectToQueue(Map<Id, List<SObject>> zipRuleIdVsSobjectRecords){
        Map<Id,Integer> ruleVsNumberOfQueues = new Map<Id,Integer>(); 
        Set<String> queueNames = new Set<String>();
        
        for(Id ruleId : zipRuleIdVsSobjectRecords.keySet()){
            Integer numberOfQueues = 0;

            for(Integer i=1; i<=7; i++){
                if(!String.isBlank((String)zipRuleIdVsSobjectRecords.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Queue_'+i+'__c'))){
                    queueNames.add((String)zipRuleIdVsSobjectRecords.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Queue_'+i+'__c'));
                    numberOfQueues++;
                }
            }
            ruleVsNumberOfQueues.put(ruleId,numberOfQueues);
        }
        
        queueNameVsId = Utility.getQueueNameVsIds(queueNames);
        
        Map<Id, Map<String, List<SObject>>> ruleVsQueueVsSobjectRecords = new Map<Id, Map<String, List<SObject>>>();
        
        for(Id ruleId : zipRuleIdVsSobjectRecords.keySet()){
            Integer sequence = zipRuleIdVsSobjectRecords.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Sequence__c') != null ? Integer.valueOf(zipRuleIdVsSobjectRecords.get(ruleId)[0].getSobject('Zip_Code_Rule__r').get('Sequence__c')) : 1;
            
            Map<String, List<SObject>> tempQueueVsSobjectRecords = new Map<String, List<SObject>>();
            
            for(SObject sobjRec : zipRuleIdVsSobjectRecords.get(ruleId)){

                if(ruleVsNumberOfQueues.get(ruleId) > 0){
                    Integer mod = math.mod(sequence,ruleVsNumberOfQueues.get(ruleId));
                    mod= mod== 0 ? ruleVsNumberOfQueues.get(ruleId): mod;
                    String queueDevName = (String)sobjRec.getSobject('Zip_Code_Rule__r').get('Queue_'+mod+'__c');
                    String queueId = queueNameVsId.containsKey(queueDevName) ? queueNameVsId.get(queueDevName) : null;
                    Boolean performRROnQueue = (Boolean)sobjRec.getSobject('Zip_Code_Rule__r').get('Run_Round_Robin_on_Queue'+mod+'__c');
                    
                    if(queueId != null){
                        sobjRec.put('ownerId', queueId);

                        if(performRROnQueue){
                            if(!tempQueueVsSobjectRecords.containsKey(queueDevName))
                             	tempQueueVsSobjectRecords.put(queueDevName, new List<SObject>{sobjRec});
                            else
                             	tempQueueVsSobjectRecords.get(queueDevName).add(sobjRec);
                        }

                        rulesAndSobjectRecordsToUpdate.put(sobjRec.Id, sobjRec);
                        sequence++;
                    }
                }   
            }

            ruleVsQueueVsSobjectRecords.put(ruleId, tempQueueVsSobjectRecords);
            rulesAndSobjectRecordsToUpdate.put(ruleId, new Zip_Code_Rule__c(Id = ruleId, Sequence__c = sequence)); 
        }

        return ruleVsQueueVsSobjectRecords;
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
	16-10-2020	    Kishor Kumar	  Updated to make it Generic
    ----------------------------------------------------------------------------*/
    public Map<String,Object> getFilteredMembers(List<Id> allUserIds, Set<Id> userIdsToRemove, String lastAssignedId){
        List<Id> filteredMembers = new List<Id>(); 
        Integer index = 0;
        
        if(allUserIds != null){
            for(Id userId : allUserIds){
                if(!userIdsToRemove.contains(userId))
                filteredMembers.add(userId);
            }
        }
        
        filteredMembers.sort();
        
        if(!String.isBlank(lastAssignedId)){
            Boolean removeLastAssignedId =! filteredMembers.contains(lastAssignedId) ? true : false;
            if(removeLastAssignedId){
                filteredMembers.add(lastAssignedId);
                filteredMembers.sort();
            }
            
            index = filteredMembers.indexOf(lastAssignedId)+1 > filteredMembers.size()-1 ? 0 : filteredMembers.indexOf(lastAssignedId)+1;
            Id nextValidId = filteredMembers[index];
            
            if(removeLastAssignedId){
                Integer tempIndex = filteredMembers.indexOf(lastAssignedId);
                if(tempIndex != -1)
                filteredMembers.remove(tempIndex);
                filteredMembers.sort(); 
                index = filteredMembers.indexOf(nextValidId); 
            } 
        }
        
        return new Map<String,Object>{'finalApplicableUserIds' => filteredMembers,
                                      'indexToStartFrom' => index};  
    }

    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   method to assign Sobject Records to queue members in ROUND ROBIN  
    Inputs:        
    outputs:       
    Test Class:   

    History
    09-05-2020      Manasi Londhe     Initial Release
	16-10-2020	    Kishor Kumar	  Updated to make it Generic
    ----------------------------------------------------------------------------*/
    public List<SObject> assignsObjectRecordsToQueueMembers(List<SObject> sObjectRecords, List<Id> userIds, Integer indexToStartFrom, 
                                                   				Map<String,Object> queueVsLastAssigned){
                                                                    
        List<SObject> rulesAndSobjectRecords = new List<SObject>(); 
        Id lastAssignedId;
        String queueName;
        
        Id queueId = (Id)sObjectRecords[0].get('ownerId');
        
        for(String name : queueNameVsId.keySet()){
            if(queueNameVsId.get(name) == queueId)
            queueName = name;
        }

        //Check if BU has any User assignment limit
        Boolean considerAssignmentLimitForMembers = (sObjectRecords.Size() > 0 && businessUnitsVsLimit.containsKey((String)sObjectRecords[0].get('Business_Unit__c'))) ? true : false;
        //Fetch daily Limit for Business Units if any
        Integer userLimitToAssign = Integer.valueof(businessUnitsVsLimit.get((String)sObjectRecords[0].get('Business_Unit__c')));
                                                                   
        if(queueName != null){
            if(sObjectRecords.Size() > 0 && considerAssignmentLimitForMembers){
                for(SObject sobj : sObjectRecords){
                    if(userIds.Size() > 0 && memberVsSobjectRecordsAssigned.containsKey(userIds[indexToStartFrom]) 
                       					   && memberVsSobjectRecordsAssigned.get(userIds[indexToStartFrom]) < userLimitToAssign){
                        sobj.put('ownerId', userIds[indexToStartFrom]);
                        lastAssignedId = userIds[indexToStartFrom];
                        Integer recordAssignedCount = (memberVsSobjectRecordsAssigned.get(userIds[indexToStartFrom])) + 1;
                        memberVsSobjectRecordsAssigned.put(userIds[indexToStartFrom], recordAssignedCount);
                                               
                        if(recordAssignedCount >= userLimitToAssign){
                            userIds.remove(indexToStartFrom);
                            if(indexToStartFrom > userIds.size()-1 && userIds.size() >= 1)
                              indexToStartFrom = 0;
                        } else {
                            indexToStartFrom+=1;
                            if(indexToStartFrom>userIds.size()-1)
                              indexToStartFrom = 0;
                        }
                    } else if(userIds.Size() > 0 && !memberVsSobjectRecordsAssigned.containsKey(userIds[indexToStartFrom])){
                        sobj.put('ownerId', userIds[indexToStartFrom]);
                        lastAssignedId = userIds[indexToStartFrom];
                        memberVsSobjectRecordsAssigned.put(userIds[indexToStartFrom],1);
                        indexToStartFrom+=1;
                        if(indexToStartFrom > userIds.size()-1)
                        indexToStartFrom = 0;
                    }  
                    
                    rulesAndSobjectRecords.add(sobj);  
                }
            } else {
                for(SObject sobj : sObjectRecords){
                    sobj.put('ownerId', userIds[indexToStartFrom]);
                    lastAssignedId = userIds[indexToStartFrom];
                    indexToStartFrom+=1;
                    if(indexToStartFrom > userIds.size()-1)
                        indexToStartFrom = 0;
                    
                    rulesAndSobjectRecords.add(sobj);    
                }
            }
            
            queueVsLastAssigned.put(queueName, lastAssignedId);
            
            if(rulesAndSobjectRecordsToUpdate.containsKey((Id)sObjectRecords[0].get('Zip_Code_Rule__c'))){
                Zip_Code_Rule__c zipRule = (Zip_Code_Rule__c)rulesAndSobjectRecordsToUpdate.get((Id)sObjectRecords[0].get('Zip_Code_Rule__c'));
                zipRule.Queues_And_LastAssignedId__c = JSON.Serialize(queueVsLastAssigned);
                rulesAndSobjectRecordsToUpdate.put((Id)sObjectRecords[0].get('Zip_Code_Rule__c'), zipRule);
            }
            
            rulesAndSobjectRecords.add(new Zip_Code_Rule__c(id = (Id)sObjectRecords[0].get('Zip_Code_Rule__c'), 
                                                            	Queues_And_LastAssignedId__c = JSON.Serialize(queueVsLastAssigned))) ;
        }
        return rulesAndSobjectRecords;
    }


}