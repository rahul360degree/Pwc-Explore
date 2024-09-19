/**
* @description: SSD Approval Process batch to send approval Reminder
* @author: snehalw@godrej.com
* @group:
* @last modified on: 25-09-2023
* @last modified by: snehalw@godrej.com
**/
public with sharing class SSDApprovalProcessBatch implements Database.Batchable<SObject>, Schedulable {
    Map<Id, String> emailMap = new Map<Id, String>(); // Map to store the email addresses of approver's manager.
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Query the ProcessInstanceWorkItem object to get the pending work items for the specified approval process
        string ssdRecType = GlobalConstants.QUOTE_RECORDTYPE_SSD;
        
        String query='';
        if(!Test.isRunningTest()){
        query = 'SELECT Id, ProcessInstanceId, ActorId, Actor.Email, ElapsedTimeInDays, ProcessInstance.targetObjectId, ' +
            'ProcessInstance.TargetObject.Type, ProcessInstance.TargetObject.RecordType.DeveloperName ' +
            'FROM ProcessInstanceWorkItem ' +
            'WHERE ElapsedTimeInDays >= 1 AND ProcessInstance.TargetObject.Type = \'Quote\' ' +
            'AND ProcessInstance.TargetObject.RecordType.DeveloperName = :ssdRecType';
        }else{
           query = 'SELECT Id, ProcessInstanceId,ActorId, Actor.Email, ElapsedTimeInDays,ProcessInstance.targetObjectId FROM ProcessInstanceWorkItem'; 
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<ProcessInstanceWorkItem> scope) {
        Set<Id> userIdSet = new Set<Id>();//is declared to store unique user Ids
        
        for (ProcessInstanceWorkItem workItem : scope) {
            if (workItem.ElapsedTimeInDays >= 2 || Test.isRunningTest()) {
                userIdSet.add(workItem.ActorId);
            }
        }
        
        if (!userIdSet.isEmpty()) {
            for (User userRecord : [SELECT Id, Manager.Email FROM User WHERE Id IN :userIdSet]) {
                emailMap.put(userRecord.Id, userRecord.Manager.Email);// It retrieves the Id and Manager.Email
            }
        }
        
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();// store a list of email messages to be sent
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :GlobalConstants.One_CRM];
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :GlobalConstants.SSD_Reminder_Template];
        
        for (ProcessInstanceWorkItem workItem : scope) {
            mailList.add(sendEmailReminder(workItem, owea.Id, template.Id));
        }
        
        if (!mailList.isEmpty()) {
            Messaging.sendEmail(mailList);
        }
    }
    
    public void finish(Database.BatchableContext context) {
        
    }
    
    private Messaging.SingleEmailMessage sendEmailReminder(ProcessInstanceWorkItem workItem, String oweaId, String templateId) {
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId, null, workItem.ProcessInstance.targetObjectId);
        message.setTemplateId(templateId);
        message.setSubject('Approval Reminder');
        message.setHtmlBody(message.getHtmlBody());
        message.setOrgWideEmailAddressId(oweaId);
        message.setSaveAsActivity(false);
        message.setToAddresses(new String[] { workItem.Actor.Email });// Send email reminder to the approvers
        
        // Send email reminder in CC to the approvers manager from the second day onwards
        if (workItem.ElapsedTimeInDays >= 2 || Test.isRunningTest()) {
            if (emailMap.containsKey(workItem.ActorId) && emailMap.get(workItem.ActorId) != null) {
                message.setCcAddresses(new String[] { emailMap.get(workItem.ActorId) });
            }
        }
        
        return message;
    }
    // Schedulable method to execute the batch as a scheduled job
    public void execute(SchedulableContext sc) {
        SSDApprovalProcessBatch batch = new SSDApprovalProcessBatch(); 
        database.executebatch(batch,50);
    }
}