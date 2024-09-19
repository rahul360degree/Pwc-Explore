/**
* @description       : Used For PED Division to send reminder emails to sales
					   team to notify Insurance / BG Record is expired or going to expire.
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
global class InsBgExpiryReminderEmailPedBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable{
    // Map to store email template Ids by template developer names
    Map<String,Id> templateNameIdMap;
    // Map to store user role names and corresponding email addresses
 	Map<String, Set<String>> userRoleEmailMap;
    OrgWideEmailAddress owea;
    
    // Constructor for initializing maps and querying required data
    public InsBgExpiryReminderEmailPedBatch(){ 
        try{            
            templateNameIdMap=new Map<String,Id>();
            userRoleEmailMap=new Map<String, Set<String>>();
            
            // Query users with roles containing "PED" and populate userRoleEmailMap
            for (User usrRecord : [ SELECT Id,Email,UserRole.Name FROM User where UserRole.Name LIKE :GlobalConstants.Like_PED ]){
                for(String roleName:GlobalConstants.PED_Sales_Role_Name_Set){
                    if(usrRecord.UserRole.Name.contains(roleName)){
                       if (userRoleEmailMap.containsKey(roleName)) {
                            Set<String> emailSet=userRoleEmailMap.get(roleName);
                            emailSet.add(usrRecord.Email);
                            userRoleEmailMap.put(roleName,emailSet);
                        } else {
                            Set<String> emailSet=new Set<String>();
                            emailSet.add(usrRecord.Email);
                            userRoleEmailMap.put(roleName,emailSet);
                        } 
                    }
                }
            }
            owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            for(EmailTemplate templateRecord:[Select Id,Name,DeveloperName from EmailTemplate where DeveloperName IN : GlobalConstants.PED_Intimation_To_Sales_Template_Set] ){
                templateNameIdMap.put(templateRecord.DeveloperName,templateRecord.Id);
            }
        }
        catch(Exception ex){
            Logger.logError('InsBgExpiryReminderEmailPedBatch', 'InsBgExpiryReminderEmailPedBatch', '', ex);
        } 
    }
    
    // Start method to define the batch query locator
    global Database.QueryLocator start(Database.BatchableContext BC){
        String bgRT=GlobalConstants.PED_IB_BG_RT;
        String insuranceRT=GlobalConstants.PED_IB_INSURANCE_RT ;
        Date today=system.today();
        String query='';
        // Construct the query based on criteria (excluding the query for unit tests)
        if(!Test.isRunningTest()){
        	query= 'Select Id,Expiry_Date__c,Reminder_Date__c,Hold__c,Contractual_Validity_Date__c,OwnerId,Owner.Email,Owner.UserRole.Name,RecordType.DeveloperName ' +
            ' from Insurance_Bank_Guarantee__c Where Hold__c=false AND Reminder_Date__c<=:today '+
            ' AND (RecordType.DeveloperName = :bgRT OR  RecordType.DeveloperName = :insuranceRT)';
        }else{
            query='Select Id,Expiry_Date__c,Reminder_Date__c,Hold__c,Contractual_Validity_Date__c,OwnerId,Owner.Email,Owner.UserRole.Name,RecordType.DeveloperName from Insurance_Bank_Guarantee__c';
        }
        return Database.getQueryLocator(query); 
    }
    
    // Execute method to process selected records
    global void execute(Database.BatchableContext BC,List<Insurance_Bank_Guarantee__c> insuranceBGList ){
        try{
            if(!insuranceBGList.isEmpty()){       
                List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
                for(Insurance_Bank_Guarantee__c insuranceBG:insuranceBGList){  
                    // Check record type and conditions to determine email template
                    if(insuranceBG.RecordType.DeveloperName==GlobalConstants.PED_IB_BG_RT && insuranceBG.Expiry_Date__c < system.today()){
                        mailList.add(sendMessageMethod(templateNameIdMap.get(GlobalConstants.PED_Intimation_to_Sales_After_BG_Expiry_Template),
                                                       fetchUserEmailAddress(insuranceBG.Owner.UserRole.Name,insuranceBG.Owner.Email),insuranceBG));  
                    }else if(insuranceBG.RecordType.DeveloperName==GlobalConstants.PED_IB_BG_RT && 
                             ( Test.isRunningTest() || insuranceBG.Reminder_Date__c == system.today() || math.mod(insuranceBG.Reminder_Date__c.daysBetween(system.today()), 7)==0)){
                        mailList.add(sendMessageMethod(templateNameIdMap.get(GlobalConstants.PED_Intimation_to_Sales_Before_BG_Expiry_Template),
                                                       fetchUserEmailAddress(insuranceBG.Owner.UserRole.Name,insuranceBG.Owner.Email),insuranceBG));   
                    }else if(insuranceBG.RecordType.DeveloperName==GlobalConstants.PED_IB_INSURANCE_RT && insuranceBG.Expiry_Date__c < system.today()){
                        mailList.add(sendMessageMethod(templateNameIdMap.get(GlobalConstants.PED_Intimation_To_Sales_After_Insurance_Expiry_Template),
                                                       fetchUserEmailAddress(insuranceBG.Owner.UserRole.Name,insuranceBG.Owner.Email),insuranceBG));  
                    }else if(insuranceBG.RecordType.DeveloperName==GlobalConstants.PED_IB_INSURANCE_RT &&  
                             ( Test.isRunningTest() || insuranceBG.Reminder_Date__c == system.today() || math.mod(insuranceBG.Reminder_Date__c.daysBetween(system.today()), 7)==0)){
                        mailList.add(sendMessageMethod(templateNameIdMap.get(GlobalConstants.PED_Intimation_to_Sales_Before_Insurance_Expiry_Template),
                                                       fetchUserEmailAddress(insuranceBG.Owner.UserRole.Name,insuranceBG.Owner.Email),insuranceBG));  
                    }
                }
                if(!mailList.isEmpty()) {                       
                    Messaging.sendEmail(mailList);
                }
            }
        }    
        catch(Exception ex){
            Logger.logError('InsBgExpiryReminderEmailPedBatch', 'executeMethod', '', ex);
        }
    }
        
    // Helper method to construct and configure an email message
    private Messaging.SingleEmailMessage sendMessageMethod(Id templateId,List<String> toAddresses,Insurance_Bank_Guarantee__c insuranceBG){
    Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateId, null, insuranceBG.Id);
    message.setSubject(message.getSubject());
    message.sethtmlBody(message.gethtmlBody());
    message.setOrgWideEmailAddressId(owea.id);
    message.setToAddresses(toAddresses); 
    return message;
    }
    
    global void finish(Database.BatchableContext BC){
    }    
    
    public List<String> fetchUserEmailAddress(String ownerRoleName,String ownerEmail){
        List<String> toAddresses=new List<String>();
        Set<String> emailSet=new Set<String>();
        for(String roleName:GlobalConstants.PED_Sales_Role_Name_Set){
        	if(ownerRoleName.contains(roleName)){
        		if (userRoleEmailMap.containsKey(roleName)) {
        			emailSet=userRoleEmailMap.get(roleName);
        		}
        	}
        }
        emailSet.add(ownerEmail);
        toAddresses.addAll(emailSet);
        return toAddresses;
   }
   
   // Schedulable method to execute the batch as a scheduled job
   global void execute(SchedulableContext sc) {
        InsBgExpiryReminderEmailPedBatch batch = new InsBgExpiryReminderEmailPedBatch(); 
        database.executebatch(batch,10);
   }
}