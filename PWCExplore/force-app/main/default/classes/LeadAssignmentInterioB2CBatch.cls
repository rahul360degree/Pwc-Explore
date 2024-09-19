/**
* @description       : Used for Interio Tele caller round robin qound robin 
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 12-29-2022
* @last modified by  : vrajpoot@godrej.com
**/
global class LeadAssignmentInterioB2CBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    //key=> Email, value = remained Leads to assign
    private Integer availableLeadsSize = 0;
    Integer maxRecordPerUser = Integer.valueof(System.Label.Interio_B2C_Lead_Assignment_TeleCaller_Limit);
    private Map<String,Integer> leadsLoadToAssign;
    //get user id
    private Set<Id> getUserIds(){
        List<String> assignedToUserNameList=Label.Interio_B2C_Lead_Assignment_User_Name.split(',');        
        Set<Id> userIdSet = new Set<Id>();
        for(User user:[Select Id from User where username IN:assignedToUserNameList and isActive=true]){
            userIdSet.add(user.Id);
        }
        return userIdSet;
    }
    //Get Map key=>user Id, value=>Available leads to assign
    private Map<String,Integer> getLeadsLoadToAssign(){
        Set<Id> userIdSet = getUserIds();
        
        Map<String,Integer> availableLeadLoadMap = new Map<String,Integer>();        
        for(AggregateResult ar:[Select OwnerId ownerId,Count(Id) leadCount from Lead Where OwnerId IN:userIdSet AND Status =:GlobalConstants.NEW_CONSTANT and Business_Unit__c =:GlobalConstants.INTERIO_BUSINESS_UNIT GROUP BY OwnerId ORDER BY Count(Id)])
        {
            Id userId = (Id)ar.get('ownerId');
            userIdSet.remove(userId);
            Integer remianingLoadSize = maxRecordPerUser - ((Integer)ar.get('leadCount'));
            if(remianingLoadSize>0){
                availableLeadLoadMap.put((Id)ar.get('ownerId'), remianingLoadSize);
                availableLeadsSize +=remianingLoadSize;
            }
        }
        if(!userIdSet.isEmpty()){
            for(Id userId:userIdSet){
                availableLeadsSize += maxRecordPerUser;
                availableLeadLoadMap.put(userId, maxRecordPerUser);
            }
        }
        return availableLeadLoadMap;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        leadsLoadToAssign = getLeadsLoadToAssign();
        System.debug(leadsLoadToAssign);
        Id defaultQueueId = [select Id From Group Where Type = 'Queue' 
                             AND DeveloperName = :GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE].Id;
        String query = 'Select Id,CreatedDate from Lead Where OwnerId=\''+defaultQueueId+'\''+
            ' AND Status =\''+GlobalConstants.NEW_CONSTANT+'\''+
            ' AND Business_Unit__c =\''+GlobalConstants.INTERIO_BUSINESS_UNIT+'\''+
            ' AND (Interio_Sub_Division__c = \''+GlobalConstants.INTERIO_KITCHEN +'\' OR  Interio_Sub_Division__c = \''+GlobalConstants.INTERIO_VFD+'\') ' +
            ' ORDER BY CreatedDate DESC limit '+availableLeadsSize;
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC,list<Lead> LeadList){ 
        List<String> userIdSet = new List<String>();
        userIdSet.addAll(leadsLoadToAssign.keySet());
        if(!userIdSet.isEmpty()){
            Integer userIndex = 0;
            for(Lead lead:LeadList){
                if(userIdSet.isEmpty()){
                    break;
                }
                Id userId = userIdSet[userIndex];
                lead.OwnerId = userId;
                Integer remainingleads = leadsLoadToAssign.get(userId)-1;
                if(remainingleads<=0){
                    userIdSet.remove(userIndex);
                    leadsLoadToAssign.remove(userId);
                }else{
                    leadsLoadToAssign.put(userId, remainingleads);
                    userIndex++;
                }
                if(userIndex >= userIdSet.size()){
                    userIndex = 0;
                }
            }
            try{
                Database.SaveResult[] leadUpdateResult = Database.update(LeadList, false);
                // Iterate through each returned result by the method
                for (Database.SaveResult sr : leadUpdateResult) {
                    if (!sr.isSuccess()) {
                        // This condition will be executed for failed records
                        for(Database.Error objErr : sr.getErrors()) {
                            System.debug('The following error has occurred.');
                            // Printing error message in Debug log
                            System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                            System.debug('Field which are affected by the error:' + objErr.getFields());
                        }
                    }
                }
            }catch(Exception ex){
                System.debug(ex.getStackTraceString());
            }
            
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
    global void execute(SchedulableContext sc) {
        LeadAssignmentInterioB2CBatch batch = new LeadAssignmentInterioB2CBatch(); 
        Database.executeBatch(batch,200);
    }
}