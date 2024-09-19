/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Batch Class for generation of Bills in Leasing
Inputs:        NA
Last Modified: 13/01/2022
Test Class:    
----------------------------------------------------------------------------*/


global class BillingServicesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public String email;
    public Date today;
    public String stageName;
    public BillingServices bs;
    public Integer totalCount = 0;
    public Integer successCount = 0;
    public Integer errorCount = 0;
    
    public List<BillingServices.SurveyWrapper> wrapList = new List<BillingServices.SurveyWrapper>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collecting the batches of records or objects to be passed to execute
        today = system.today().addMonths(1); //Date.newInstance(2021, 12, 14).addMonths(1);
        stageName = System.Label.Leasing_Stage_Name;
        string query = 'Select Id, Name, Lease_Abstract__c, Opportunity__c, Opportunity__r.StageName, Licence_End_Date__c from HEAD_OF_TERMS__c where Lease_Abstract__c = true and Opportunity__r.StageName =: stageName and Licence_End_Date__c >=: today';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<HEAD_OF_TERMS__c> hotList) {
        
        //process each batch of records default size is 200   
        //Calling the method in billing services for batch generation 
        bs = new BillingServices();
        wrapList = bs.generateBills(hotList);
        
        for(BillingServices.SurveyWrapper wrapItem: wrapList){
            if(wrapItem.responseCount != 0 && wrapItem.responsePositiveCount != null && wrapItem.responseNegativeCount != null){
                totalCount += wrapItem.responseCount;
                successCount += wrapItem.responsePositiveCount;
                errorCount += wrapItem.responseNegativeCount;
            }
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
        AsyncApexJob a = [
            SELECT Id, ApexClassId, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<User> userList = [SELECT id, Name, FirstName, LastName, Email 
                               FROM User 
                               WHERE id =: userInfo.getUserId()];  
        
        List < String > sendTo = new List < String > ();
        //sendTo.add('jayasurya.g@stetig.in');
        sendTo.add(userList[0].Email);
        
        if (sendTo != null && sendTo.size() > 0) {
            mail.setToAddresses(sendTo);
            string subject = 'Billing Services Batch'; 
            mail.setSubject(subject);
            
            String body = 'Hi ' + userList[0].FirstName + ',<br/><br/>';
            body += 'The details regarding generated bills are as follows: <br/><br/>';
            body += 'Total number of bills :- '+ totalCount +'<br/><br/>';    
            body += 'Bills generated:- ' + successCount +'<br/><br/>'; 
            body += 'Bills not generated:- ' + (totalCount - successCount) + '<br/><br/>'; 
            body += 'Thanks & Regards,<br/>Stetig Team';
            
            // mail.setFileAttachments(attachments);
            mail.setHtmlBody(body);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
                    }); 
        }    
    }
}