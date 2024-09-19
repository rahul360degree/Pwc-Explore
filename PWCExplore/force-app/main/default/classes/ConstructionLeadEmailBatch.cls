/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 05-18-2023
 * @last modified by  : vrajpoot@godrej.com
**/

public with sharing class ConstructionLeadEmailBatch implements Database.Batchable<sObject>,Schedulable{
            
    public Database.QueryLocator start(Database.BatchableContext BC) {     
        Set<String> status = new Set<String>{GlobalConstants.QUALIFIED,GlobalConstants.UNQUALIFIED};
        String businessUnit  = GlobalConstants.Construction_BUSINESS_UNIT;
        String query = 'Select Id,Internal_Sales_Rep__c,ownerId,Next_Reminder_Date__c,Auto_Closing_Date__c,Cluster__c '
                        +' from Lead '
                        +' where '
                        +' (Status NOT IN: status) And (Next_Reminder_Date__c = Today OR Auto_Closing_Date__c = Today)  AND Business_Unit__C=:businessUnit ';
        return Database.getQueryLocator(query);
    }
    
    //execute the records
    public static void execute(Database.BatchableContext BC, List<lead> leadRecords) {         
        EmailTemplate emailTemplate = [Select Id from EmailTemplate where DeveloperName =:GlobalConstants.CM_Lead_Reminder_Template];
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:GlobalConstants.ONECRMEMAIL][0].Id;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>{} ;

        Map<Id,Lead> leadMapToUpdate = new Map<Id,Lead>();
        Set<String> userEmail = new Set<String>{System.Label.Construction_Material_Mumbai_Sales_Manager,
                                             System.Label.Construction_Material_MMR_Sales_Manager, 
                                             System.Label.Construction_Material_Pune_East_Sales_Manager,
                                             System.Label.Construction_Material_Pune_West_Sales_Manager,
                                             System.Label.Construction_Material_WPS_Sales_Manager};
        Map<String,User> userEmailMap = new Map<String,User>();
        for(User user : [Select Id,Email from User where Email IN: userEmail]){
            userEmailMap.put(user.Email, User);
        }


        for(Lead lead:leadRecords){
            if(lead.Next_Reminder_Date__c == Date.today()){
                Messaging.SingleEmailMessage mail= new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String [] {lead.OwnerId, lead.Internal_Sales_Rep__c});
                String salesManagerId = '';
                if(lead.Cluster__c == GlobalConstants.CLUSTER_MUMBAI && userEmailMap.containsKey(System.Label.Construction_Material_Mumbai_Sales_Manager)){
                    salesManagerId = userEmailMap.get(System.Label.Construction_Material_Mumbai_Sales_Manager).Id;
                }else if(lead.Cluster__c == GlobalConstants.CLUSTER_MMR && userEmailMap.containsKey(System.Label.Construction_Material_MMR_Sales_Manager)){
                    salesManagerId = userEmailMap.get(System.Label.Construction_Material_MMR_Sales_Manager).Id;
                }else if(lead.Cluster__c == GlobalConstants.CLUSTER_PUNE_EAST && userEmailMap.containsKey(System.Label.Construction_Material_Pune_East_Sales_Manager)){
                    salesManagerId = userEmailMap.get(System.Label.Construction_Material_Pune_East_Sales_Manager).Id;
                }else if(lead.Cluster__c == GlobalConstants.CLUSTER_PUNE_WEST && userEmailMap.containsKey(System.Label.Construction_Material_Pune_West_Sales_Manager)){
                    salesManagerId = userEmailMap.get(System.Label.Construction_Material_Pune_West_Sales_Manager).Id;
                }else if(lead.Cluster__c == GlobalConstants.CLUSTER_WPS && userEmailMap.containsKey(System.Label.Construction_Material_WPS_Sales_Manager)){
                    salesManagerId = userEmailMap.get(System.Label.Construction_Material_WPS_Sales_Manager).Id;
                }

                if(!String.isBlank(salesManagerId)){
                    mail.setCCAddresses(new String [] {salesManagerId});
                }
                mail.setOrgWideEmailAddressId(orgWideEmailId);
                mail.setTargetObjectId(lead.Id);
                mail.setTemplateId(emailTemplate?.Id);
                mail.setSaveAsActivity(true);
                mail.setTreatTargetObjectAsRecipient(false);

                emailList.add(mail);
                lead.Auto_Closing_Date__c = Date.Today().addDays(15);
            }else if(lead.Auto_Closing_Date__c == Date.today()){
                lead.Status = GlobalConstants.UNQUALIFIED;
                lead.Reason_for_Lost__c = GlobalConstants.OPPORTUNITY_SECTOR;
                lead.Reason_for_lost_if_others__c = 'Auto Closed by Automation';
            }

            leadMapToUpdate.put(lead.Id, lead);
        }

        if(!emailList.isEmpty()){
            Messaging.SendEmailResult [] result = Messaging.sendEmail(emailList);
            Set<Id> errorLeadId = new Set<Id>();
            for(Messaging.SendEmailResult rr: result){ 
                for(Messaging.SendEmailError err : rr.getErrors()){
                    leadMapToUpdate.remove(err.targetobjectid);
                }
            }
        }
            if(!leadMapToUpdate.values().isEmpty()){
                Database.SaveResult[] leadUpdateResult = Database.update(leadMapToUpdate.values(), false);
                for (Database.SaveResult sr : leadUpdateResult) {
                    if (!sr.isSuccess()) {
                        for(Database.Error objErr : sr.getErrors()) {
                            System.debug('Error: ' + objErr.getMessage());
                        }
                    }
                }
            }
        

    }
    //finish method
    public void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }   
    
    //Scehdule the email
    public void execute(SchedulableContext ctx) {
		ConstructionLeadEmailBatch batch = new ConstructionLeadEmailBatch(); 
        Database.executeBatch(batch,25);
    }

}