/*
Written by  : Sreekanth Jujare
On		    : 21/06/2022
Description : Sends a Email Notification of all Pending Tasks to the Internal Sales Representative 
Test Class	: sendPendingNotificationTest 
*/
global class sendPendingNotification implements Database.Batchable<sObject>, schedulable {
    map<string,list<task>> userEmailTasklistmap = new map<string,list<task>>();
    global void execute(SchedulableContext BC){
        sendPendingNotification b = new sendPendingNotification();
        database.executebatch(b);
    }
    
    /* Start Method: Returns the data from the Task Records which are status = Pending or On hold */
    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT ID,createddate,what.id,who.name,Owner.Email,OwnerId,Internal_Sales_Rep__r.Name,ActivityDate,
                                         Internal_Sales_Rep__r.Email,Email_of_Int_Sal_Rep__c, CSG_Activity__c,Customer_Name__r.Name,Start_Date__c,
                                         Scheduled_End_Date__c,Status,Subject,RecordTypeId from Task WHERE Status != 'Completed']);
       
    }
    
    /* Execute Method: Checks for the Email of Int Sal Rep and Make the data ready to send to Int Sal Rep */
    global void execute(Database.BatchableContext BC, List<Task> scope){
        EmailTemplate emailTemplate =[SELECT Id,Subject,Description,DeveloperName,HtmlValue,Body 
                                      FROM EmailTemplate
                                      WHERE DeveloperName ='sendPendingNotification']; 
        for(Task Tsk : scope){
            if(!userEmailTasklistmap.Containskey(tsk.Internal_Sales_Rep__r.email)){
                userEmailTasklistmap.put(tsk.Internal_Sales_Rep__r.email, new list<task>());
            }
            userEmailTasklistmap.get(tsk.Internal_Sales_Rep__r.email).add(tsk);
        }  
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(string email : userEmailTasklistmap.keyset()){
            if(!string.isBlank(email)){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                list<string> toAddresses = new list<string>();
                toAddresses.add(email);
                mail.setToAddresses(toAddresses);
                //mail.setSubject('Pending Tasks with you');                
                String username = userEmailTasklistmap.get(email)[0].Internal_Sales_Rep__r.name;
                String htmlBody = ''; /*HTML Format for Email Template */
                htmlBody = emailTemplate.HtmlValue;
                htmlBody += '<table width="100%" border="0" cellspacing="0" cellpadding="8" align="center" bgcolor="#F7F7F7">'+
                    +'<tr>'+
                    +'<td style="font-size: 14px; font-weight: normal; font-family:Calibri;line-height: 18px; color: #333;"><br />'+
                    +'<br />'+
                 //   +'Dear '+username+',</td>'+
                    +'</tr>'+
                    +'<tr>'+
                 //   +'<td style="font-size: 14px; font-weight: normal; font-family:Calibri; line-height: 18px; color: #333;">Following are the pending tasks as on today</td>'+
                    +'</tr>'+
                    +'</table>';
                
                htmlBody +=  '<table border="1" style="border-collapse: collapse"><tr><th>Type of Activity</th><th>Customer Name</th><th>CST Contact</th><th>Start Date</th><th>Scheduled End Date</th></tr>';
                for(task tsk : userEmailTasklistmap.get(email)){
                    
                    String duedate = '';
                    if (tsk.ActivityDate != null)
                        duedate = tsk.ActivityDate.format();                    
                    else
                        duedate = '';
                    String Subject = tsk.subject;
                    String CSG = tsk.CSG_Activity__c;
                    String Acc = tsk.Customer_Name__r.Name;
                    String Who = tsk.Who.name;
                    datetime Startdate = tsk.Start_Date__c;
                    datetime ScheduledEnddate = tsk.Scheduled_End_Date__c;
                    string link = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ tsk.id; 
                    htmlBody += '<tr><td>' + CSG + '</td><td>' + Acc + '</td><td>' + Who + '</td><td>' + Startdate + '</td><td>' + ScheduledEnddate + '</td></tr>';                    
                }
                htmlBody += '</table><br>';
                mail.sethtmlBody(htmlBody);
                mails.add(mail);                    
            }
        }
        
        if(mails.size()>0)
            Messaging.sendEmail(mails);				
    }
    /*Finish Method: Executes the operation and Sends the Email */
    global void finish(Database.BatchableContext BC){        
    }
}