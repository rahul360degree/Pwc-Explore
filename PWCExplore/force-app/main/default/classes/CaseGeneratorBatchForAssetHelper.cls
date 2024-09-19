/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Helper class for CaseGeneratorBatchForPMscheduling.
Inputs:            

----------------------------------------------------------------------------*/
public class CaseGeneratorBatchForAssetHelper {
    
    //Method to fetch Picklist values for Case Creation status field
    public Map<String, String> getCaseCreationStatusValues(){
        Map<String, String> caseStatusMap = new Map<String, String>();
        List<String> picklistValues = new List<String>();
        
       Schema.DescribeFieldResult fieldResult = Asset.Case_creation_status__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
       for( Schema.PicklistEntry f : ple){
          picklistValues.add(String.valueOf(f.getValue()));
       }    
       
       for(Integer i=0; i< picklistValues.size(); i++){
            Integer index = i;
            if(i < (picklistValues.size())-1 ){
                caseStatusMap.put(picklistValues[index], picklistValues[index+1]);
            }
       }
       return caseStatusMap;
    }
    
    public string generateQuery(){
    //10-Jan-2022: Updated the query to exclude any check on Case_Creation_Status__c
    
    /*
     String query= 'SELECT Id, Scheduled_PM_Visit_1__c, Scheduled_PM_Visit_2__c, Scheduled_PM_Visit_3__c, Scheduled_PM_Visit_4__c,'+
                              'Scheduled_PM_Visit_5__c, Scheduled_PM_Visit_6__c, Scheduled_PM_Visit_7__c, Scheduled_PM_Visit_8__c, Scheduled_PM_Visit_9__c, '+
                      'Scheduled_PM_Visit_10__c, Scheduled_PM_Visit_11__c, Scheduled_PM_Visit_12__c, '+ 
                              'Case_creation_status__c, AccountId, ContactId, SerialNumber, OwnerId,Equipment_Serial_No__c FROM Asset WHERE RecordType.DeveloperName = \'MHE_Asset\' AND (Status = \'Active\' OR Status = \'Inactive\') AND '+
                              '((((Scheduled_PM_Visit_1__c!= null) AND (Scheduled_PM_Visit_1__c >= TODAY and Scheduled_PM_Visit_1__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'\')) OR'+
                              '(((Scheduled_PM_Visit_2__c!= null) AND (Scheduled_PM_Visit_2__c >= TODAY and Scheduled_PM_Visit_2__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_1_created\')) OR'+
                              '(((Scheduled_PM_Visit_3__c!= null) AND (Scheduled_PM_Visit_3__c >= TODAY and Scheduled_PM_Visit_3__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_2_created\')) OR'+
                              '(((Scheduled_PM_Visit_4__c!= null) AND (Scheduled_PM_Visit_4__c >= TODAY and Scheduled_PM_Visit_4__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_3_created\')) OR'+
                              '(((Scheduled_PM_Visit_5__c!= null) AND (Scheduled_PM_Visit_5__c >= TODAY and Scheduled_PM_Visit_5__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_4_created\')) OR'+
                              '(((Scheduled_PM_Visit_6__c!= null) AND (Scheduled_PM_Visit_6__c >= TODAY and Scheduled_PM_Visit_6__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_5_created\')) OR'+
                              '(((Scheduled_PM_Visit_7__c!= null) AND (Scheduled_PM_Visit_7__c >= TODAY and Scheduled_PM_Visit_7__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_6_created\')) OR'+
                              '(((Scheduled_PM_Visit_8__c!= null) AND (Scheduled_PM_Visit_8__c >= TODAY and Scheduled_PM_Visit_8__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_7_created\')) OR'+
                      '(((Scheduled_PM_Visit_9__c!= null) AND (Scheduled_PM_Visit_9__c >= TODAY and Scheduled_PM_Visit_9__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_8_created\')) OR'+
                              '(((Scheduled_PM_Visit_10__c!= null) AND (Scheduled_PM_Visit_10__c >= TODAY and Scheduled_PM_Visit_10__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_9_created\')) OR'+
                              '(((Scheduled_PM_Visit_11__c!= null) AND (Scheduled_PM_Visit_11__c >= TODAY and Scheduled_PM_Visit_11__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_10_created\')) OR'+
                              '(((Scheduled_PM_Visit_12__c!= null) AND (Scheduled_PM_Visit_12__c >= TODAY and Scheduled_PM_Visit_12__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))AND(Case_creation_status__c = \'Case_11_created\' )))';
    */
    
    String query= 'SELECT Id, Scheduled_PM_Visit_1__c, Scheduled_PM_Visit_2__c, Scheduled_PM_Visit_3__c, Scheduled_PM_Visit_4__c,'+
                              'Scheduled_PM_Visit_5__c, Scheduled_PM_Visit_6__c, Scheduled_PM_Visit_7__c, Scheduled_PM_Visit_8__c, Scheduled_PM_Visit_9__c, '+
                      'Scheduled_PM_Visit_10__c, Scheduled_PM_Visit_11__c, Scheduled_PM_Visit_12__c, '+ 
                              'Case_creation_status__c, AccountId, ContactId, SerialNumber, OwnerId,Equipment_Serial_No__c FROM Asset WHERE RecordType.DeveloperName = \'MHE_Asset\' AND (Status = \'Active\' OR Status = \'Inactive\') AND '+
                              '((((Scheduled_PM_Visit_1__c!= null) AND (Scheduled_PM_Visit_1__c > TODAY and Scheduled_PM_Visit_1__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_2__c!= null) AND (Scheduled_PM_Visit_2__c > TODAY and Scheduled_PM_Visit_2__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_3__c!= null) AND (Scheduled_PM_Visit_3__c > TODAY and Scheduled_PM_Visit_3__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_4__c!= null) AND (Scheduled_PM_Visit_4__c > TODAY and Scheduled_PM_Visit_4__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_5__c!= null) AND (Scheduled_PM_Visit_5__c > TODAY and Scheduled_PM_Visit_5__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_6__c!= null) AND (Scheduled_PM_Visit_6__c > TODAY and Scheduled_PM_Visit_6__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_7__c!= null) AND (Scheduled_PM_Visit_7__c > TODAY and Scheduled_PM_Visit_7__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_8__c!= null) AND (Scheduled_PM_Visit_8__c > TODAY and Scheduled_PM_Visit_8__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_9__c!= null) AND (Scheduled_PM_Visit_9__c > TODAY and Scheduled_PM_Visit_9__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_10__c!= null) AND (Scheduled_PM_Visit_10__c > TODAY and Scheduled_PM_Visit_10__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_11__c!= null) AND (Scheduled_PM_Visit_11__c > TODAY and Scheduled_PM_Visit_11__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))) OR'+
                              '(((Scheduled_PM_Visit_12__c!= null) AND (Scheduled_PM_Visit_12__c > TODAY and Scheduled_PM_Visit_12__c <= NEXT_N_DAYS:'+System.Label.No_of_days_to_create_PM_visit_Case_record+'))))';
        return query;
    }

}