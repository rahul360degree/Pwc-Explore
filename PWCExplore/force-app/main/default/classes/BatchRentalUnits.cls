/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Batch Class for add status to Rental units
Inputs:        NA
Last Modified: 22/12/2021
Test Class:    
----------------------------------------------------------------------------*/


global without sharing class BatchRentalUnits implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public String email;
    public List<Junction_Unit__c> rentalObject;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collecting the batches of records or objects to be passed to execute
        string query = 'Select Id, Status__c, Lease_Status__c, Leasing_Status__c from Junction_Unit__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Junction_Unit__c> rental) {
        rentalObject = new List<Junction_Unit__c>();
        // process each batch of records default size is 200 
                  
        for(Junction_Unit__c unit: rental){
            Junction_Unit__c unitItem = new Junction_Unit__c();
             unitItem.Id = unit.Id;
             if(unit.Lease_Status__c != 'Not Applicable'){
                if (Schema.sObjectType.Junction_Unit__c.fields.Leasing_Status__c.isUpdateable()){ 
                    unitItem.Leasing_Status__c = unit.Lease_Status__c;
                  }
            }
            
            rentalObject.add(unitItem);
        }
          update rentalObject;  
        
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
            string subject = 'Rental Unit Batch'; 
            mail.setSubject(subject);
            
            String body = 'Hi' + userList[0].FirstName + ',<br/><br/>';
            body += 'The batch for rental units has been completed <br/><br/>'; 
            body += 'Thanks & Regards,<br/>Stetig Team';
            
            // mail.setFileAttachments(attachments);
            mail.setHtmlBody(body);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
                    }); 
        }    
    }
}