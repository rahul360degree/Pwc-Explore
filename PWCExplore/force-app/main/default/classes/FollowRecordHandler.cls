/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   class to handle case along with related milestones record Follow 

Test Class:   

History
11-12-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class FollowRecordHandler{
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle record Follow logic 
    
    Test Class:   FollowRecordHandlerTest
    
    History
    11-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static void followRecord(Id caseId){
        List<EntitySubscription> entitySubToInsert = new List<EntitySubscription>();
        map<Id, EntitySubscription> parentIdVsExistingSubMap = new map<Id, EntitySubscription>();
        
        //Fetch Existing subscriber records
        parentIdVsExistingSubMap = retrieveExistingSubsRecord(caseId);
       
        //Follow Case logic
        for(Case caseRec : [SELECT Id, (SELECT Id FROM Project_Milestones__r), OwnerId 
                            FROM Case 
                            WHERE Id =: caseId]){
             
            //check if record is already followed     
            if(!parentIdVsExistingSubMap.containsKey(caseRec.id)){
                EntitySubscription follow = new EntitySubscription(parentId = caseRec.id, subscriberid = userInfo.getUserId());
            	entitySubToInsert.add(follow);                    
            }              
            
                                
            //Follow related milestones                    
            if(caseRec.Project_Milestones__r.size() > 0){
                 for(Project_Milestone__c pmToFollow : caseRec.Project_Milestones__r){
                     //check if record is already followed     
            		 if(!parentIdVsExistingSubMap.containsKey(pmToFollow.id)){
                     	EntitySubscription followPM = new EntitySubscription(parentId = pmToFollow.id, subscriberid = userInfo.getUserId());
                     	entitySubToInsert.add(followPM);
                     }
                }                    
            }            
        }
           
        try{ 
            insert entitySubToInsert;
        } catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }       
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to retrieve existing subscription records 
    
    Test Class:   
    
    History
    16-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static map<Id, EntitySubscription> retrieveExistingSubsRecord(Id caseId){
        set<Id> recIds = new set<Id>();
        map<Id, EntitySubscription> parentIdVsExistingSubMap = new map<Id, EntitySubscription>();
        
        for(Case caseRec : [SELECT Id, (SELECT Id FROM Project_Milestones__r), OwnerId 
                            FROM Case 
                            WHERE Id =: caseId]){
			recIds.add(caseRec.id);   
                                
            //get related milestones                    
            if(caseRec.Project_Milestones__r.size() > 0){
                 for(Project_Milestone__c pmToFollow : caseRec.Project_Milestones__r){
                    recIds.add(pmToFollow.id);                     
                }                    
            }            
        }
        
        //Fetch existing Entity Subscription records
		for(EntitySubscription ExistingSub : [SELECT Id, parentId FROM EntitySubscription 
                                                 		WHERE parentId IN : recIds 
                                              			AND subscriberid =: userInfo.getUserId()]){
            parentIdVsExistingSubMap.put(ExistingSub.parentId, ExistingSub);                                      
        }
        
        return parentIdVsExistingSubMap;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle record Unfollow logic 
    
    Test Class:   
    
    History
    11-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    @AuraEnabled
    public static void unfollowRecord(Id caseId){        
        map<Id, EntitySubscription> parentIdVsExistingSubMap = new map<Id, EntitySubscription>();
        
        //Fetch Existing subscriber records
        parentIdVsExistingSubMap = retrieveExistingSubsRecord(caseId);
        
        try{
            delete parentIdVsExistingSubMap.values();
        } catch(Exception ex){
            Logger.logError('FollowRecordHandler', 'unfollowRecord', '', ex);
        }  
    }
}