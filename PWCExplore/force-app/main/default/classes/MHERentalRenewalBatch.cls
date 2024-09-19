/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   30 Days before the expiry of a Service Contract, 
               system should auto-create a renewal Opportunity for Godrej RenTRUST
Inputs:        
Test Class:   MHERentalRenewalBatchTest

History
23-06-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class MHERentalRenewalBatch implements Database.Batchable<sObject>
{
    
    public Database.QueryLocator start(Database.BatchableContext jobId) {
        Integer numberOfDaysForExpiry = Integer.ValueOf(RenewalHelper.getApplicationSetting('Number_Of_Days_for_Expiry_RenTrust'));
        Date expiryDate = System.today().addDays(numberOfDaysForExpiry);
        String mheDivision = GlobalConstants.MHE_SUB_DIVISION_RENTAL;
        return Database.getQueryLocator('Select ID FROM ServiceContract WHERE EndDate = :expiryDate and MHE_Division__c = :mheDivision');
    }

    public void execute(Database.BatchableContext bc, List<ServiceContract> contracts) {
        MHERentalRenewalHelper.processRenewalForRenTRUST(contracts);
    }
  
    public void finish(Database.BatchableContext jobId) {
    }
}