/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       Godrej Infotech
Description:   Class to send Email Notification to Overdue milestones Added for Jira number - SSEPB-19
Inputs:        project milestone where Planned_completion_date__c is less than Today and Status__c is not completed
Test Class:   sendPMOverdueNotificationBatchTest - 95% coverage

History
10-05-2022      Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
global class sendPMOverdueNotificationBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> lstStatus = new List<String>{'Completed'};
        List<String> lstSupplyRecordType = new List<String>{'supply and material pull plan'};
        List<String> lstDesignRecordType = new List<String>{'Design clearance'};
        List<String> lstHoProjectsRecordType = new List<String>{'Ho projects update'};
        List<String> lstExecutionRecordType = new List<String>{'Execution'};
        
        String query = 'select id,CreatedById,Project_Number__c,recordtype.name,recordtypeId,Service_request__c,status__c from Project_milestone__c where planned_completion_date__c > 2022-04-01 AND planned_completion_date__c != Null AND planned_completion_date__c <Today AND Status__c Not IN: lstStatus AND (recordType.Name IN:lstSupplyRecordType OR recordType.Name IN:lstDesignRecordType OR recordType.Name IN:lstHoProjectsRecordType OR recordType.Name IN:lstExecutionRecordType)';
        system.debug('1'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Project_milestone__c> lstPM) {
        List<EmailTemplate> emailTemplate =[Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where 
                                            DeveloperName = 'Overdue_Supply_and_Material_Pull_Plan_Milestone_Notification' OR  
                                            DeveloperName = 'Overdue_Milestone_Notification' OR DeveloperName = 'Overdue_HO_Projects_Milestone_Notification'];
       
        Set<id> setUserInCollaborationGroup = new Set<Id>();
        try{
            CollaborationGroup collGrp = [select id,name from CollaborationGroup where name =:Label.SSG_Design_Post_collaboration_group];        
            List<CollaborationGroupMember> lstCollGrpMem = [select id,memberid from CollaborationGroupMember where CollaborationGroupid =:collGrp.Id];
            
            //Add Collaboration group member in Set            
            for(CollaborationGroupMember collGrpMemObj:lstCollGrpMem)
                setUserInCollaborationGroup.add(collGrpMemObj.MemberId);            
        }catch(Exception e){
            
        }
        
        List<User> userdetail = [SELECT ID,EMAIL,UserRole.Name FROM USER WHERE UserRole.Name =:GlobalConstants.SSG_HO_PROJECTS_ROLE OR UserRole.Name =:GlobalConstants.SSG_CHEN_Mgr_ROLE
                                 OR id IN:setUserInCollaborationGroup];
        
        List<String> supplyEmailList = new List<String>();
        List<String> designEmailList = new List<String>();
        List<String> executionEmailList = new List<String>();
        
        //Get all execution milestone which is not completed//this query rquired because Completion date is not available in execution milestone 
        List<Project_milestone__c> lstExecutionProMilestone = [select id,CreatedById,Project_Number__c,recordtype.name,recordtypeId,Service_request__c,status__c from 
                                                               Project_milestone__c where Status__c !=: GlobalConstants.PROJECTMILESTONE_COMPLETED_STATUS AND recordTypeId =: GlobalConstants.Execution_milestone_RECORDTYPE_ID ];
        
        //Map for comparing parent of project milestone
        Map<String,String> mapIdVsStatus =  new Map<String,String>();
        for(Project_milestone__c exeMilstoneObj:lstExecutionProMilestone){               
            if(exeMilstoneObj.recordTypeId == GlobalConstants.Execution_milestone_RECORDTYPE_ID)
                mapIdVsStatus.put(exeMilstoneObj.Service_Request__c,exeMilstoneObj.Status__c);             
        }
        
        If(userdetail.size() > 0){
            for(User u:userdetail){
                if(u.UserRole.Name == GlobalConstants.SSG_HO_PROJECTS_ROLE){                     
                    supplyEmailList.add(u.Email);                    
                    designEmailList.add(u.Email);                   
                    executionEmailList.add(u.Email);                     
                }
                else if(u.UserRole.Name == GlobalConstants.SSG_CHEN_Mgr_ROLE){
                    supplyEmailList.add(u.Email);                    
                }
                else{
                    designEmailList.add(u.Email);                    
                }
            }
        }      
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        if(!lstPM.isEmpty() && !emailTemplate.isEmpty()){          
            for(Project_milestone__c proMilstoneObj:lstPM){                
                for(EmailTemplate template:emailTemplate){
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();  
                    email.setTemplateID(template.Id);
                    email.setSaveAsActivity(false);
                    email.targetobjectid = proMilstoneObj.CreatedById;
                    String subject = template.Subject;
                    subject =  subject.replace('{!Order.OrderReferenceNumber}', proMilstoneObj.Project_Number__c);
                    email.setSubject(subject);
                    //Change body dynamically
                    String plainBody = template.Body;
                    plainBody = plainBody.replace('{!Order.OrderReferenceNumber}', proMilstoneObj.Project_Number__c);
                    plainBody = plainBody.replace('{!Project_milestone__c.Project_Number__c}', proMilstoneObj.Project_Number__c+' ');
                    plainBody = plainBody.replace('{!Project_milestone__c.Id}', proMilstoneObj.id); 
                    plainBody = plainBody.replace('{!Project_milestone__c.RecordType}', proMilstoneObj.recordType.name+' ');
                    email.setPlainTextBody(plainBody);
                        
                    if(proMilstoneObj.recordTypeId == GlobalConstants.Supply_milestone_RECORDTYPE_ID && template.DeveloperName == GlobalConstants.SUPPLY_MILESTONE_OVERDUE_EMAIL_ALERT){
                        email.setToAddresses(supplyEmailList);                        
                        lstEmail.add(email);                        
                    }
                    else if(proMilstoneObj.recordTypeId == GlobalConstants.Design_milestone_RECORDTYPE_ID && template.DeveloperName == GlobalConstants.DESIGN_MILESTONE_OVERDUE_EMAIL_ALERT){                        
                        email.setToAddresses(designEmailList);                        
                        lstEmail.add(email);
                    }
                    else if(proMilstoneObj.recordTypeId == GlobalConstants.Ho_Project_milestone_RECORDTYPE_ID && template.DeveloperName == GlobalConstants.HO_PROJECTS_MILESTONE_OVERDUE_EMAIL_ALERT && mapIdVsStatus.containsKey(proMilstoneObj.Service_Request__c)){                      
                        email.setToAddresses(executionEmailList);                        
                        lstEmail.add(email);
                    }
                }
            }//end of for
        }
        Messaging.sendEmail(lstEmail); 
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}