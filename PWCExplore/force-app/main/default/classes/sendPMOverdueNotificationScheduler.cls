/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       Godrej Infotech
Description:   Class to send Email Notification to Overdue milestones                                          
                                                   Added for Jira number - SSEPB-19
Inputs:        project milestone where Planned_completion_date__c is less than 
                                                   Today and Status__c is not completed
Test Class:   sendPMOverdueNotificationBatchTest - 100% coverage

History
10-05-2022      Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
global class sendPMOverdueNotificationScheduler Implements Schedulable{
    global void execute(SchedulableContext sc){
        sendPMOverdueNotificationBatch sendEmail = new sendPMOverdueNotificationBatch();
        database.executeBatch(sendEmail,10);
    }   
}