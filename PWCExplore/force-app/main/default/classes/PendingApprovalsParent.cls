/**
 * @description       : Created for https://gnbdigitalprojects.atlassian.net/browse/SMEPB-24
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 05-23-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing  abstract class PendingApprovalsParent {
    //prepare the query
    protected string processInstanceQuery(string fieldNames,string sObjectName, string whereClause){
        try{
            String query='SELECT Id, Actor.name, ProcessInstanceId, ProcessInstance.Status,ElapsedTimeInDays, '
                +'ProcessInstance.ProcessDefinition.DeveloperName, '
                +'ProcessInstance.ProcessDefinition.Type, '
                +'ProcessInstance.ProcessDefinition.TableEnumOrId, '
                +'ProcessInstance.TargetObjectId '
                //+fieldNames
                +' from ProcessInstanceWorkitem '
                +' where '
                +' ProcessInstance.TargetObject.Type  =: sObjectName ' 
                //whereClause
                + ' limit 30000'
                +' ';
            return query;
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    } 
    // get pending approvals
    protected List<sObject> getProcessInstanceWorkitemRecords(string query,String sObjectName){
        try{
            List<ProcessInstanceWorkitem> processItems= Database.query(query);
            return processItems;        
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
    //get parent Ids
    protected Set<Id> getTargetObjectIds(List<ProcessInstanceWorkitem> processItems){
        try{
            Set<Id> recId = new Set<Id>();
            for(ProcessInstanceWorkitem workItem:processItems){recId.add(workItem.ProcessInstance.TargetObjectId);}
            return recId;
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
    //  get parent records
    public virtual List<sObject> getTargetObjectRecords(String query, Set<Id> recId){
        try{
            return Database.query(query);
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
}