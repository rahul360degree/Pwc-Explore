/**
* @description       : Used For PED Division to send reminder emails to finance
					   team to provide Instrument Number for related BG Record.
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
global class EmailToFinanceForBGRequestPedBatch implements Database.Batchable<sObject>,Schedulable{    
    // Start method to define the batch query locator
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('Inside Start Method');
        String bgRT=GlobalConstants.PED_IB_BG_RT;
        Date today=system.today();
        String query;
        if(!Test.isRunningTest()){
            query = 'Select Id,Name,Expiry_Date__c,CreatedDate,Instrument_Number__c,Project_Name__c,Project_Number__c from Insurance_Bank_Guarantee__c ' +
                       'Where Instrument_Number__c=null AND CreatedDate<:today AND RecordType.DeveloperName = :bgRT';
        }else{
            query = 'Select Id,Name,Expiry_Date__c,CreatedDate,Instrument_Number__c,Project_Name__c,Project_Number__c from Insurance_Bank_Guarantee__c ' +
                       'Where Instrument_Number__c=null AND RecordType.DeveloperName = :bgRT';
        }
        return Database.getQueryLocator(query); 
    }
    
    // Execute method to process selected records
    global void execute(Database.BatchableContext BC,List<Insurance_Bank_Guarantee__c> insuranceBGList ){
        try{
        if(!insuranceBGList.isEmpty()){       
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
            OrgWideEmailAddress owea = Utility.getOrgWideEmailAddress(GlobalConstants.One_CRM);
            EmailTemplate templateRecord=Utility.getEmailTemplate(GlobalConstants.PED_Follow_up_email_to_Finance_for_BG_Request_Template);
            List<String> toAddresses=new List<String>();
            toAddresses.addAll(System.Label.PedFinanceTeamEmailAddress.split(','));
            for(Insurance_Bank_Guarantee__c insuranceBG:insuranceBGList){ 
                 // Check if the number of days is divisible by 3
                 if(math.mod((insuranceBG.CreatedDate).date().daysBetween(system.today()), 3)==0){
                    Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(templateRecord.Id, null, insuranceBG.Id);
                    
                     // Replace place holder's present in email template htmlBody.
                    String recordLink ='SFDC Link for '+insuranceBG.Name+' : '+ URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Insurance_Bank_Guarantee__c/'+insuranceBG.Id+'/view';  
                	String htmlBody=message.gethtmlBody();                
                	htmlBody=htmlBody.replace('RECORD_LINK', recordLink);
                    
                    message.setSubject('BG/LC Request Was Raised On '+insuranceBG.CreatedDate.format('MMMMM dd, yyyy')+' for '+insuranceBG.Project_Name__c+' '+insuranceBG.Project_Number__c +' | '+insuranceBG.Name);
                    message.sethtmlBody(message.gethtmlBody());
                    message.setOrgWideEmailAddressId(owea.id);
                    message.setToAddresses(toAddresses);  
                    mailList.add(message);  
                }              
                
            }
            if(!mailList.isEmpty()) {
                Messaging.sendEmail(mailList);
            }
        }  
        }
        catch(Exception ex){
            Logger.logError('EmailToFinanceForBGRequestPedBatch', 'ExecuteMethod', '', ex);
        } 
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
     // Schedulable method to execute the batch as a scheduled job
    global void execute(SchedulableContext sc) {
        EmailToFinanceForBGRequestPedBatch  batch = new EmailToFinanceForBGRequestPedBatch (); 
        database.executebatch(batch,100);
    }
}