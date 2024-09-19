/**
Description: To send Task Due reminders to Internal Sales Rep
Author:  Sreekanth Jujare
Company: GITL
**/

global class BankGuaranteeEmailBatch implements Database.Batchable<SObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext context) {
        String query =  '';
        if (!Test.isRunningTest()) {
            query = 'SELECT Id, Subject, Internal_Sales_Rep__r.Name, Internal_Sales_Rep__r.Zone__c, Internal_Sales_Rep__r.Manager.Email, Email_of_Int_Sal_Rep__c, ActivityDate, Sub_Activity__c, Customer_Name__r.Name, Start_Date__c, Scheduled_End_Date__c, PO_NO_Reference__c, Estimated_Price__c FROM Task ' +
                'WHERE RecordType.DeveloperName = \'Interio_BMR\' ' + 
                'AND Sub_Activity__c = \'Bank Guarantee (ABG/PBG/Retention BG)\' ' + 
                'AND (ActivityDate =LAST_N_DAYS:'+System.Label.TWO+' OR ActivityDate = NEXT_N_DAYS:'+System.Label.TWO+' OR ActivityDate = TODAY)';
        }
        else{
            query = 'SELECT Id, Subject, Internal_Sales_Rep__r.Name, Internal_Sales_Rep__r.Zone__c, Internal_Sales_Rep__r.Manager.Email, Email_of_Int_Sal_Rep__c, ActivityDate, Sub_Activity__c, Customer_Name__r.Name, Start_Date__c, Scheduled_End_Date__c, PO_NO_Reference__c, Estimated_Price__c FROM Task ';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext context, List<Task> scope) {
        Set<Id> processedTaskIds = new Set<Id>();
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :GlobalConstants.One_CRM];
        for (Task task : scope) {
            // Check if this task has already been processed
            if (!processedTaskIds.contains(task.Id)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setCcAddresses(new List<String>{System.Label.BMR_CC_Mail_Id, System.Label.BMR_CST_HO_CC_Email_Id});
                email.setTargetObjectId(task.Internal_Sales_Rep__c);
                email.setSaveAsActivity(false);
                email.setSubject('Urgent: Bank Guarantee Expiry Approaching');
                email.setOrgWideEmailAddressId(owea.Id);
                
                String username = task.Internal_Sales_Rep__r.Name;
                String dueDate = task.ActivityDate != null ?  task.ActivityDate.day() + '-' + task.ActivityDate.month() + '-' + task.ActivityDate.year() : '';
                String htmlBody = '';
                String taskUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + task.Id;
                
                //Recipients based on the Internal Sales Rep's zone
                if (task.Internal_Sales_Rep__r.Zone__c == GlobalConstants.NORTH) {
                    email.setToAddresses(new List<String>{task.Email_of_Int_Sal_Rep__c, task.Internal_Sales_Rep__r.Manager.Email, System.Label.WCC_North_Zone_Email_Id});
                } else if (task.Internal_Sales_Rep__r.Zone__c == GlobalConstants.SOUTH) {
                    email.setToAddresses(new List<String>{task.Email_of_Int_Sal_Rep__c, task.Internal_Sales_Rep__r.Manager.Email, System.Label.WCC_South_Zone_Email_Id});
                } else if (task.Internal_Sales_Rep__r.Zone__c == GlobalConstants.WEST) {
                    email.setToAddresses(new List<String>{task.Email_of_Int_Sal_Rep__c, task.Internal_Sales_Rep__r.Manager.Email, System.Label.WCC_West_Zone_Email_Id});
                } else if (task.Internal_Sales_Rep__r.Zone__c == GlobalConstants.EAST) {
                    email.setToAddresses(new List<String>{task.Email_of_Int_Sal_Rep__c, task.Internal_Sales_Rep__r.Manager.Email, System.Label.WCC_East_Zone_Email_Id});
                }
                
                htmlBody += '<table width="100%" border="0" cellspacing="0" cellpadding="8" align="center">'+
                    '<tr>'+
                    '<td style="font-size: 15px;">Dear '+username+',<br/><br/>Our Bank Guarantee is expiring soon, Kindly take necessary action on priority basis.<br/><br/>Details:<br/></td>'+
                    '</tr>'+
                    '</table>';
                htmlBody += '<table border="1" style="cellspacing="0" cellpadding="8"><tr><td>Customer Name</td><td>' + task.Customer_Name__r.Name + '</td></tr><tr><td>Bank Guarantee Ref</td><td>' + task.PO_NO_Reference__c + '</td></tr><tr><td>Amount (Rs.)</td><td>' + task.Estimated_Price__c + '</td></tr><tr><td>Expiry Date</td><td>' + dueDate + '</td></tr></table>';
                htmlBody += '<table width="100%" border="0" cellspacing="0" cellpadding="8" align="center"><tr><td style="font-size: 15px;">Please confirm whether the bank guarantee should be extended, renewed, or cancelled. For further assistance, you can contact our team members on Extension 022-6111 8244 or 8358.<br/><br/>Click on this Hyperlink to view the Task:<a href="' + taskUrl + '">View Task Record</a><br/><br/>Regards, <br/>OneCRM Admin</td></tr></table>';
                
                email.setHtmlBody(htmlBody);  
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                
                processedTaskIds.add(task.Id);
            }
        }
    }
    
    global void finish(Database.BatchableContext context) {
    }
    
    global void execute(SchedulableContext sc) {
        BankGuaranteeEmailBatch batch = new BankGuaranteeEmailBatch(); 
        Database.executeBatch(batch);
    }
}