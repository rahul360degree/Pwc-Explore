/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Responsible for updating service re
Inputs:        NA
Test Class:    ServiceRequestApexSchedulerTest
---------------------------------------------------------------------------
History
16-09-2020      Shailja Mishra     Initial Release
----------------------------------------------------------------------------*/
public class ServiceRequestApexScheduler Implements Schedulable{
    public static final String INTEGRATION_STATUS_DRAFT = 'Draft';
    public void execute(SchedulableContext ctx) {
        updateCases();
    }
    
    
   /*--------------------------------------------------------------------------
    Author:        Shailja Mishra
    Company:       Salesforce
    Description:   Method responsible for updating Service Requests(Cases) with Integration Status as 'Ready To Sync' based on following conditions -
                   1. Delivery_Date = today or (Created_Date = today and Delivery_Date = null)
				   2. Integration = Draft
                   3. Recordtype = Service Request
    Inputs:        NA
    Test Class:   
    -----------------------------------------------------------------------------
    History
    16-09-2020      Shailja Mishra     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateCases(){
        List<Case> casesToUpdate = new List<Case>();
        Id serviceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service_Request').getRecordTypeId();
        for(Case cs : [Select Id 
                         From Case 
                         Where (Delivery_Date__c = Today OR (Delivery_Date__c = null And CreatedDate = Today)) 
                               And Integration_Status__c = :INTEGRATION_STATUS_DRAFT
                               And RecordtypeId = :serviceRequestRecordTypeId]){
                                if(Schema.sObjectType.Case.fields.Integration_Status__c.isUpdateable()){ 
                                  cs.Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_READY_TO_SYNC; 
                                 }
            casesToUpdate.add(cs);
        }
        
        try{
            if(Schema.sObjectType.Case.fields.Integration_Status__c.isUpdateable()){
            if(casesToUpdate.size() > 0){
               update casesToUpdate;
            }
           }
        }catch(Exception ex){
            Logger.logError('Smartnet Request', 'ServiceRequestApexScheduler', 'updateCases', '', ex);
        }
    }
}