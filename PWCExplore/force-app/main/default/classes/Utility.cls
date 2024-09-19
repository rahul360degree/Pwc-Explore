/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Utility class 
Inputs:        NA
Test Class:    
History
20-03-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class Utility {
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to check if record is lock for Apporval 
    Inputs:        record ids
    Test Class:    
    History
    10-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public static map<Id,boolean> recordLockCheck(list<Id> recordIds){
        List<ProcessInstanceWorkitem> lstPendningApproval=new List<ProcessInstanceWorkitem>();
        Set<Id> setUserId=new Set<Id>();
        Set<Id> setQueue=new Set<Id>();
        set<Id> setGroupIdRetrieved=new Set<Id>();
        Map<Id,boolean> mapPR=new Map<Id,boolean>();
        
        List<GroupMember> lstGroupMember=new List<GroupMember> ();
        Id loggedInUserId=UserInfo.getUserId();
        lstPendningApproval=[SELECT Id,ActorId,OriginalActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :recordIds];
        boolean bIsByPassLogic=Runtime_Execution__c.getInstance().Allow_Edit_For_Locked_Record__c;
        
        for(ProcessInstanceWorkitem prVar: lstPendningApproval){
            mapPR.put(prVar.ProcessInstance.TargetObjectId,false);
            if((String.valueOf(prvar.ActorId)).contains('005') && prvar.ActorId==loggedInUserId){
                mapPR.put(prVar.ProcessInstance.TargetObjectId,true); // Allow record edit
            }  
            else if(!((String.valueOf(prvar.ActorId)).contains('005'))  ){
                setQueue.add(prvar.ActorId);  
                
            } 
            if(bIsByPassLogic)
                mapPR.put(prVar.ProcessInstance.TargetObjectId,true); // Allow record edit
            
        }
        if(setQueue.size()>0){
            lstGroupMember=[select GroupId from GroupMember where UserOrGroupId=:loggedInUserId and groupId IN :setQueue];
        }
        for(GroupMember grpMember: lstGroupMember)
            setGroupIdRetrieved.add(grpMember.GroupId);
        
        for(ProcessInstanceWorkitem prVar: lstPendningApproval){
            if(!((String.valueOf(prvar.ActorId)).contains('005'))  && setGroupIdRetrieved.contains(prvar.ActorId))
                mapPR.put(prVar.ProcessInstance.TargetObjectId,true); // Allow record edit if user part of Queue
        }
        return mapPR;   
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to fetch Record Type details 
    Inputs:        Object's Api Name
    Test Class:    
    History
    20-03-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public map<String, Id> fetchRecordTypes(String ObjApiName){
        map<String, Id> rtMap = new map<String, Id>();
        
        for(RecordType rt : [select Id, Name, DeveloperName from RecordType 
                                            where sObjectType=: ObjApiName]){
            
            rtMap.put(rt.DeveloperName, rt.Id);                                    
        }
        
        return rtMap;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to fetch Record Type Record Type Id using developer Name 
    Inputs:        Object's Api Name and Record Type Developer Name
    Test Class:    
    History
    20-03-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public Id fetchRecordTypeId(String ObjApiName, String rtDevName){
        
        RecordType rt = [select Id from RecordType 
                                   where sObjectType=: ObjApiName 
                                   AND DeveloperName =: rtDevName LIMIT 1];
                   
        
        return rt.Id;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to fetch Standard PriceBook details 
    Inputs:        
    Test Class:    
    History
    24-03-2020      Kishor Kumar     Initial Release
    08-06-2020      Kartik Shetty   Modified function return type to list of pricebook.

    ----------------------------------------------------------------------------*/
    public List<Pricebook2> fetchStandardPriceBookDetail(){
        
        return [SELECT Id FROM Pricebook2
                         WHERE isStandard = true
                         LIMIT 1];
    }

     /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to get picklist values  
    Inputs:        Object API Name and Field API Name
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static set<String> getPicklistValues(String objectAPIName,String fieldAPIName){
        Set<String> picklistValues=new Set<String>(); 
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectAPIName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : values){
            picklistValues.add(pickListVal.getValue());
        } 
        return picklistValues; 
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to get picklist values  
    Inputs:        Object API Name and Field API Name
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Map<String,String> getPicklistLabels(String objectAPIName,String fieldAPIName){
        Map<String,String> picklistValueVsLabels=new Map<String,String>(); 
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectAPIName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : values){
            picklistValueVsLabels.put(pickListVal.getValue(),pickListVal.getLabel());
        } 
        return picklistValueVsLabels; 
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to get map of queueNameVsQueueId  
    Inputs:        set of queue names
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Map<String,Id> getQueueNameVsIds(set<String> queueNames){
        Map<String,Id> queueNameVsId=new Map<String,Id>(); 
        for(Group g:[Select Id,DeveloperName From Group where Type='Queue' And DeveloperName in :queueNames]){
            queueNameVsId.put(g.DeveloperName,g.Id);
        }
        return queueNameVsId;
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   this method returns queueNameVsQueueMembers   
    Inputs:        Set of queue developer names
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Map<String,List<Id>> getQueueMembers(Set<String> queueNames){
        Map<String,List<Id>> queueVsQueueMemberIds=new Map<String,List<Id>>();
        for(Groupmember groupMember:[SELECT userOrGroupId,group.DeveloperName 
                                     FROM Groupmember 
                                     WHERE group.DeveloperName  In :queueNames 
                                     Order By userOrGroupId]){
            if(!queueVsQueueMemberIds.containsKey(groupMember.group.DeveloperName))
                queueVsQueueMemberIds.put(groupMember.group.DeveloperName,new List<Id>{groupMember.userOrGroupId});
            else
                queueVsQueueMemberIds.get(groupMember.group.DeveloperName).add(groupMember.userOrGroupId);
        }
        for(String queue:queueNames){
            if(!queueVsQueueMemberIds.containsKey(queue))
            queueVsQueueMemberIds.put(queue,new List<Id>());  
        }
        return queueVsQueueMemberIds;
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   this method returns outOfOffice and inactive users   
    Inputs:        
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Set<Id> getOutOfOfficeAndInactiveUsers(Set<Id> allMembers){
        Set<Id> invalidUsers=new Set<Id>();
        for(OutOfOffice outOfOfficeRecord:[Select UserId,StartDate,EndDate 
                                           From OutOfOffice 
                                           where UserId in :allMembers And StartDate<=TODAY And EndDate>=TODAY]){
            invalidUsers.add(outOfOfficeRecord.UserId);
        }
        for(User u:[Select Id,IsActive From User where Id in : allMembers And IsActive=false]){
            invalidUsers.add(u.Id);
        }
        return invalidUsers;
    }

    public static List<Schema.FieldSetMember> getFieldSetInfo(String fieldSetName, String objectName) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields(); 
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   this method returns number of months between two dated  
    Inputs:        two date variables
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Integer getMonthsBetween(Date date1,Date date2){
        if (date1 == null || date2 == null) return 0;
        return date1.monthsBetween(date2); 
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   this method returns queueNameVsDeveloperName  
    Inputs:        two date variables
    Test Class:    
    History
    9-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public static Map<String,String> getQueueNameVsDeveloperName(Set<String> queueNames){
        Map<String,String> nameVsDevName=new Map<String,String>();
        for(Group grp:[SELECT Name,DeveloperName 
                       FROM Group 
                       WHERE Name  In :queueNames ]){
                            nameVsDevName.put(grp.Name,grp.DeveloperName);
                       }
        return nameVsDevName;
    }
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   This method returns Email Template 
    Inputs:        String variable
    Test Class:    
    History
    09-02-2024    Initial release     Shreela Nair
    ----------------------------------------------------------------------------*/    
     public static EmailTemplate getEmailTemplate(String emailTemplateName){
         
         EmailTemplate et = [SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body 
                             FROM EmailTemplate 
                             WHERE DeveloperName =:emailTemplateName limit 1];
         
         return et;
     }
    
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   This method returns OrgWideEmailAddress
    Inputs:        String Variable
    Test Class:    
    History
    09-02-2024    Initial release     Shreela Nair
    ----------------------------------------------------------------------------*/    
     public static OrgWideEmailAddress getOrgWideEmailAddress(String orgEmailAddress){
         
         OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE 
                                         DisplayName=:orgEmailAddress limit 1];
         
         return owea;
     }
}