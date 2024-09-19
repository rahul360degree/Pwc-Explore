/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   SPEP 14 - GPE-SGF-23 - Generate task report for all leads with or without task - To display Lead and Task data oF PES from UI
Inputs:        -
Test Class:    PesLeadAndTaskReportApexTestClass

History
03-08-2023     Shreela Nair    Initial Release
05-09-2023     Shreela Nair    For replacing text field with Lookup field for SPEP -23 
12-09-2023     Shreela Nair    Replacing Creation date of task to newly Created Start date for SPEP - 24 and displaying lead data in decsending order based on Created date
29-09-2023     Shreela Nair    Removal of Task Type, Addition of Action to be taken and Renaming of Subject header for SPEP - 30
----------------------------------------------------------------------------*/
public class PesLeadAndTaskReportApexClass {
    
    //Used to set Lead and Task data
    public class DataWrapper {
        @AuraEnabled public String leadNumber;
        @AuraEnabled public String leadIncharge;
        @AuraEnabled public String pesSector;
        @AuraEnabled public String leadTitle;
        @AuraEnabled public String description;
        @AuraEnabled public String leadCompany;
        @AuraEnabled public String leadStatus;
        @AuraEnabled public String taskSubject;
        //@AuraEnabled public String taskType; //Commented by Shreela as Task type is not required anymore by PES -Changed by Shreela for SPEP - 30 for Sept 29 2023
        @AuraEnabled public String actionToBeTaken; //Added by Shreela on 29th Sept 2023 for SPEP-30
        @AuraEnabled public String taskStatus;
        @AuraEnabled public String taskStartDate; //Replaced taskCreatedDate with taskStartDate by Shreela on 12th September 2023 for SPEP-24
        @AuraEnabled public String taskEndDate;
        
    }
    
    
    @AuraEnabled //To fetch data in UI according to the filters provided by User
    public static String fetchFilteredRecords(String leadFromCreationDate, String leadToCreationDate, Id leadIncharge, String leadStatus) {
        
        try{
        Date ldFromCreationDate = (String.isNotBlank(leadFromCreationDate)) ? Date.valueOf(leadFromCreationDate) : null;
        Date ldToCreationDate = (String.isNotBlank(leadToCreationDate)) ? Date.valueOf(leadToCreationDate) : null;
        
        List<DataWrapper> dWrapperList = new List<DataWrapper>();
        String taskQuery = '';
        taskQuery += '(SELECT Id, Status, CreatedDate,Start_Date_for_GPE__c, ActivityDate, WhoId, Subject,Action_to_be_taken__c FROM Tasks WHERE Who.Type = \''+GlobalConstants.Lead_SObject+'\' AND Who.RecordType.DeveloperName=\''+GlobalConstants.PES_Lead_RecordType+'\''; //Added	Start_Date_for_GPE__c by Shreela on 12th September 2023 for SPEP-24
        //Removed Type in above query And added Action_to_be_taken__c by Shreela on 29th Sept 2023 for SPEP - 30 as Task type not required
        taskQuery += (ldFromCreationDate <> null)?' AND DAY_ONLY(CreatedDate) >= :ldFromCreationDate ':'';
        taskQuery += ' ORDER BY WhoId)';
        
        String leadQuery = '';
        leadQuery += 'SELECT Id,Lead_Number__c,Lead_Incharge_GPE__r.Name,PES_Sector__c,Title,Description,Company,Status,'+taskQuery+' FROM Lead WHERE RecordType.DeveloperName = \''+GlobalConstants.PES_Lead_RecordType+'\'';  //Modified from Lead_Incharge__c to Lead_Incharge_GPE__c by Shreela on 5th September 2023 for SPEP-23
        leadQuery += (ldFromCreationDate <> null  && ldToCreationDate <> null) ?' AND DAY_ONLY(CreatedDate) >= :ldFromCreationDate AND DAY_ONLY(CreatedDate) <= :ldToCreationDate ' : '';
        leadQuery += (leadIncharge <> null) ?' AND Lead_Incharge_GPE__c = :leadIncharge' : ''; //Modified datatype by Shreela on 5th September 2023 for SPEP-23
        leadQuery += (String.isNotBlank(leadStatus))?' AND Status =:leadStatus ':'';
        leadQuery += ' ORDER BY CreatedDate desc'; //Added by Shreela on 12th Sept 2023 for SPEP - 24
        List<Lead> leads = Database.query(leadQuery);
        
        if(leads!=null && leads.size()>0){
            dWrapperList = PesLeadAndTaskReportApexClass.setLeadAndTaskRecords(leads);
            return JSON.serialize(dWrapperList);
        }
        else{
            return null;
        }  
            }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
            return null;
        }
        
    }
    
    //To set dataWrapper on basis of tasks/no tasks records
    public static List<DataWrapper> setLeadAndTaskRecords(List<Lead> leads) {
        List<DataWrapper> dWrapperList = new List<DataWrapper>();
        
        for(Lead ld : leads){
            
            if(ld.Tasks != null && !ld.Tasks.isEmpty()){
                for(Task t : ld.Tasks){
                    DataWrapper taskDataWrapperVar = createLeadWithTaskDataWrapper(ld, t);
                    dWrapperList.add(taskDataWrapperVar);
                }
            }
            else{
                DataWrapper dataWrapperVar = createLeadDataWrapper(ld);
                dWrapperList.add(dataWrapperVar);
            }
        }
        return dWrapperList;
        
    }
    
    //To create dataWrapper instance for Lead records which doesn't contain Task record
    public static DataWrapper createLeadDataWrapper(Lead ld) {
        try{
        DataWrapper dataWrapperVar = new DataWrapper();
        dataWrapperVar.leadNumber = (String.isNotBlank(ld.Lead_Number__c)) ? ld.Lead_Number__c : '-';
        dataWrapperVar.leadIncharge = (String.isNotBlank(ld.Lead_Incharge_GPE__r.Name)) ? ld.Lead_Incharge_GPE__r.Name : '-'; //Modified from Lead_Incharge__c to Lead_Incharge_GPE__c by Shreela on 5th September 2023 for SPEP-23
        dataWrapperVar.pesSector = (String.isNotBlank(ld.PES_Sector__c)) ? ld.PES_Sector__c : '-';
        dataWrapperVar.leadTitle = (String.isNotBlank(ld.Title)) ? ld.Title : '-';
        dataWrapperVar.description = (String.isNotBlank(ld.Description)) ? ld.Description : '-';
        dataWrapperVar.leadCompany = (String.isNotBlank(ld.Company)) ? ld.Company : '-';
        dataWrapperVar.leadStatus = (String.isNotBlank(ld.Status)) ? ld.Status : '-';
        dataWrapperVar.taskSubject = '-';
        //dataWrapperVar.taskType = '-'; //Commnented by Shreela as Task Type is not required for SPEP - 30 on sept 29th 2023
        dataWrapperVar.actionToBeTaken = '-'; //Added by Shreela for SPEP-30 on 29th Sept 2023
        dataWrapperVar.taskStatus = '-';
        dataWrapperVar.taskStartDate = '-'; //Replaced taskCreatedDate with taskStartDate by Shreela on 12th September 2023 for SPEP-24
        dataWrapperVar.taskEndDate = '-';
        
        return dataWrapperVar;
            }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
            return null;
        }
    }
    
    //To create dataWrapper instance for Lead records which contains Task record
    public static DataWrapper createLeadWithTaskDataWrapper(Lead ld, Task t) {
        try{
        DataWrapper dataWrapperVar = createLeadDataWrapper(ld);
        dataWrapperVar.taskSubject = (String.isNotBlank(t.Subject)) ? t.Subject : '-';
        //dataWrapperVar.taskType = (String.isNotBlank(t.Type)) ? t.Type : '-'; //Commented by Shreela on 29th Sept 2023 for SPEP - 30 as Task Type is not required
        dataWrapperVar.actionToBeTaken = (String.isNotBlank(t.Action_to_be_taken__c)) ? t.Action_to_be_taken__c : '-'; //Added by Shreela for SPEP - 30 on 29th Sept 2023
        dataWrapperVar.taskStatus = (String.isNotBlank(t.Status)) ? t.Status : '-';
        dataWrapperVar.taskStartDate = (t.Start_Date_for_GPE__c != null) ? String.valueOf(t.Start_Date_for_GPE__c) : '-'; //Replaced taskCreatedDate with taskStartDate and t.CreatedDate with t.Start_Date_for_GPE__c by Shreela on 12th September 2023 for SPEP-24
        dataWrapperVar.taskEndDate = (t.ActivityDate != null) ? String.valueOf(t.ActivityDate) : '-';
        
        return dataWrapperVar;
        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
            return null;
        }
    }
    
}