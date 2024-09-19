/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   SPEP 14 - GPE-SGF-23 - Generate task report for all leads with or without task..To send email notification of Lead and Task report of PES
Inputs:        -
Test Class:    PesLeadAndTaskReportSchedulerTestClass

History
05-08-2023     Shreela Nair    Initial Release
05-09-2023     Shreela Nair    Change from Lead_Incharge__c to Lead_Incharge_GPE__c.Name for SPEP -23
12-09-2023     Shreela Nair    Intergchange in header and label change.To replace Created Date with Start Date for SPEP - 24
29-09-2023     Shreela Nair    Removal of Task Type, Addition of Action to be taken and Renaming of Subject header for SPEP - 30
----------------------------------------------------------------------------*/
public class PesLeadAndTaskReportSchedulerClass implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        
        //To set data for csv file
        try{
        List<PesLeadAndTaskReportApexClass.DataWrapper> dWrapperList = new List<PesLeadAndTaskReportApexClass.DataWrapper>();
        
        String csvHeaders = '"'+'Lead Number'+'","'+'Lead Incharge'+'","'+'PES Sector'+'","'+'Title'+'","'+'Description'+'","'+'Customer/Company'+'","'+'Lead Status'+'","'+'Task Subject'+'","'+'Action to be Taken'+'","'+'Task Status'+'","'+'Task Start Date'+'","'+'Task End Date'+'"\n';        //CSV File Header //Replace Task Created Date with Task Start Date by Shreela on 12th Sept 2023 for SPEP-24
        //Changed from Task Subject/Descp to Task Subject,Removed Task Type and Added Action to be Taken by Shreela for SPEP - 30 on 29th Sept 2023 
        String csvRowVal='';                         //To set the rows of CSV File
        String csvFile = '';                         //To set the rows and headers of CSV File
        
        String taskQuery = '';
        taskQuery += '(SELECT Id, Status, CreatedDate,Start_Date_for_GPE__c, ActivityDate, WhoId, Subject,Action_to_be_taken__c FROM Tasks WHERE Who.Type = \''+GlobalConstants.Lead_SObject+'\' AND Who.RecordType.DeveloperName=\''+GlobalConstants.PES_Lead_RecordType+'\''+')'; //Added Start_Date_for_GPE__c by Shreela on 12th Sept 2023 for SPEP-24
        //Removed type and added Action_to_be_taken__c by Shreela on 29th Sept 2023 for SPEP - 30
        String leadQuery = '';
        leadQuery += 'SELECT Id,Lead_Number__c,Lead_Incharge_GPE__r.Name,PES_Sector__c,Title,Description,Company,Status,'+taskQuery+' FROM Lead WHERE RecordType.DeveloperName = \''+GlobalConstants.PES_Lead_RecordType+'\' ORDER BY CreatedDate desc'; //Modified from Lead_Incharge__c to Lead_Incharge_GPE__c.Name by Shreela for SPEP-23
        
        List<Lead> leads = Database.query(leadQuery);
                
        if(leads!=null && leads.size()>0){
            for(Lead ld : leads){
                
                
                if(ld.Tasks != null && !ld.Tasks.isEmpty()){
                    for(Task t : ld.Tasks){
                        PesLeadAndTaskReportApexClass.DataWrapper taskDataWrapperVar = PesLeadAndTaskReportApexClass.createLeadWithTaskDataWrapper(ld, t);
                        dWrapperList.add(taskDataWrapperVar);
                    }
                }
                else{
                    PesLeadAndTaskReportApexClass.DataWrapper dataWrapperVar = PesLeadAndTaskReportApexClass.createLeadDataWrapper(ld);
                    dWrapperList.add(dataWrapperVar);
                }
            }
        }
        
        for (PesLeadAndTaskReportApexClass.dataWrapper d : dWrapperList) {
            csvRowVal = csvRowVal+'"'+d.leadNumber+'","'+d.leadIncharge+'","'+d.pesSector+'","'+d.leadTitle+'","'+d.description+'","'+d.leadCompany+'","'+d.leadStatus+'","'+d.taskSubject+'","'+d.actionToBeTaken+'","'+d.taskStatus+'","'+d.taskStartDate+'","'+d.taskEndDate+'"\n'; //Replace taskCreatedDate with taskStartDateby Shreela on 12th Sept 2023 for SPEP-24
            //Removed task type by Shreela for SPEP - 30 on 29th Sept 2023
        }
                
        csvFile = csvHeaders + csvRowVal +'\n';
        if(String.isNotBlank(csvFile)){
            PesLeadAndTaskReportSchedulerClass.sendEmail(csvFile);
        }
            }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
        }
        
        
    }
    //To send email with csv attached
    public static void sendEmail(String csvFile){
        
        try{        
        List<OrgWideEmailAddress> lstOrgWideEmailId;
        //To set OneGodrej as Sender
        lstOrgWideEmailId = [SELECT id,DisplayName,Address 
                                 FROM OrgWideEmailAddress 
                                 WHERE Address='onecrm@godrej.com'];
        // Compose the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment();
        blob csvFileBody;
        if(Test.isRunningTest()) { 
            csvFileBody = blob.valueOf('Sending Notes of lead record in CSV File');
        } else {
            csvFileBody = Blob.valueOf(csvFile);
        } 
        attach1.setBody(csvFileBody);
        String fileName = 'CSV File of Lead and Task Report.csv';
        attach1.setFileName(fileName);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{attach1});
        email.setOrgWideEmailAddressId(lstOrgWideEmailId[0].id);
        List<string> setToAddresses=new List<string>();
        setToAddresses.addall(System.Label.PES_Common_Email_Address.split(',')); 
        email.setToAddresses(setToAddresses);
        email.setSubject('GPE Active Leads + Task Report');
        email.setHtmlBody('Dear GPE Team,<br><br>PFA the report related to Leads with and without Tasks.<br><br>Thanks!<br><br>Note: This is a system generated email, do not reply to this.');
        
        // Send the email
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        if (results[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Email sending failed.');
        }
            }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
        }
        
    }
}