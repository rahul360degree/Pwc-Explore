/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     TaskObjectTrigger.apxt
Company:       Stetig, Stetig
Description:   Trigger on Task object whenever sit visit status marked completed lead is getting convert into respective opportunity
Inputs:        NA
Last Modified: 11/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public class TaskObjectTriggerHandller {
	
    /*
	* @Description :validate lead status before conversion
	*/
	public static void validateLeadBeforeConversion (List<Task> newTaskList, Map<Id, Task> oldTaskMap, Boolean isInsert) {
    	Set<Id> leadIdSet = new Set<Id>();
        //Added by Ashwin Thale On 13-02-2024
        Utility objUtility = new Utility();
        ID recId = objUtility.fetchRecordTypeId(GlobalConstants.TASK_SOBJECT_TYPE,GlobalConstants.TASK_RECORDTYPE_Interio_B2C_LDM);
        
    	for(Task tsk : newTaskList) {
		   if(tsk.whoId != null && (String.valueOf(tsk.whoId).substring(0,3) == '00Q')
			   && tsk.View_Status__c == 'completed' && (isInsert || tsk.View_Status__c != oldTaskMap.get(tsk.Id).View_Status__c)) {
			   leadIdSet.add(tsk.whoId);
		   }
            /*------------------------------------------------------------------------
            Modified By:   Ashwin Thale On 13-02-2024
            Description:   Method updated to make the SFMC checkbox True when the Record Type is Interio_B2C_LDM and Record is in Insert Operation.
            ------------------------------------------------------------------------*/
            if(tsk.RecordTypeId == recId && isInsert){
                tsk.SFMC__c = TRUE;
            }
		}
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id,Description, Email, OwnerId, Status, MobilePhone, Name, Source_Contact__c, Account__c, Phone, RecordTypeId FROM Lead WHERE Id in: leadIdSet AND Status = 'Unqualified']);
		
		for(Task tsk : newTaskList) {
		   if(leadMap.containskey(tsk.whoId) &&  leadMap.get(tsk.whoId).status == 'Unqualified')
			  tsk.addError('Lead Status is Unqualified so can not convert the lead');
		   }
	}
    /*
	* @Description :method converts lead whenever sit visit status marked completed lead is getting convert into respective opportunity 
	*/
	public static void convertLeadFromTask (List<Task> newTaskList, Map<Id, Task> oldTaskMap, Boolean isInsert) {
	   Set<Id> leadIdSet = new Set<Id>();
	   
		for(Task tsk : newTaskList) {
		   if(tsk.whoId != null && (String.valueOf(tsk.whoId).substring(0,3) == '00Q')
			   && tsk.View_Status__c == Label.SiteVisitStatus && (isInsert || tsk.View_Status__c != oldTaskMap.get(tsk.Id).View_Status__c)) {
			   system.debug('inside lead id set') ;
			   leadIdSet.add(tsk.whoId);
		   }
		}
        
        system.debug('leadid set is'+leadIdSet);
	   
		LeadStatus convertStatus = [SELECT Id, MasterLabel, IsConverted FROM LeadStatus WHERE IsConverted=true limit 1];
	 
		list<Opportunity> opplist = new list<Opportunity>();
		List<OpportunityContactRole> opconList = new List<OpportunityContactRole>();
		List<Database.LeadConvert> lcList = new List<Database.LeadConvert>();
		
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id,Description, Email, OwnerId, Status, MobilePhone, Name, Source_Contact__c, Account__c, Phone, RecordTypeId FROM Lead WHERE Id in: leadIdSet]);
		
		//create leadlist for conversion
		for(Lead leadObj: leadMap.values()){
			
			//standard method for lead conversion
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(leadObj.Id);
			lc.setAccountId(leadObj.Account__c);
			lc.setDoNotCreateOpportunity(false);
			lc.setContactId(leadObj.Source_contact__c);
			lc.setConvertedStatus(GlobalConstants.QUALIFIED);
			lcList.add(lc);
		}
			
		if(!lcList.isEmpty()) {
			Database.LeadConvertResult[] lcrList = Database.convertLead(lcList, false);
			system.debug('lcrList is'+lcrList);
			for(Database.LeadConvertResult lcr : lcrList) {
				
				//create opportunity contact record
				OpportunityContactRole opcon = new OpportunityContactRole();
                system.debug('lcr opportunity id'+lcr.getOpportunityId());
				opcon.OpportunityId = lcr.getOpportunityId();
				opcon.ContactId = lcr.getContactId();
				
				opconList.add(opcon);
				
				//update opportunity
				if(leadMap.containsKey(lcr.getLeadId())) {
					Lead ld = leadMap.get(lcr.getLeadId());
					//update opportunity field from lead
					Opportunity opp = new Opportunity();
					opp.id = lcr.getOpportunityId();
					opp.Description = ld.Description;
					opp.PrimaryContactEmail__c = ld.Email;
					opp.OwnerId = ld.OwnerId;
					opp.Lead_Status__c = ld.Status;
					opp.Mobile__c = ld.MobilePhone;
					opp.Name = ld.Name;
					opp.Primary_contact__c = ld.Source_Contact__c;
					opp.AccountId = ld.Account__c;
					opp.Phone__c = ld.Phone; 
					opplist.add(opp);
				}
				
			}
			
			try {
				if(!opplist.isEmpty()) {
					update opplist;
				}
				if(!opconList.isEmpty()){
					insert opconList;
				}
			}catch(Exception ex) {
				System.debug('The following exception has occurred: ' + ex.getMessage());
			}
		}
			
	}

}