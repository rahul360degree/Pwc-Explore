/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   30 Days before the expiry of a Service Contract, 
               system should auto-create a renewal Opportunity for Godrej RenTRUST
Inputs:        
Test Class:   

History
23-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class MHERentalRenewalScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Integer chunkSize = Integer.valueOf(RenewalHelper.getApplicationSetting('MHERentalRenewal_ScopeSize'));
        MHERentalRenewalBatch batchClassObject = new MHERentalRenewalBatch(); 
        Database.executeBatch(batchClassObject, chunkSize);
    }
}