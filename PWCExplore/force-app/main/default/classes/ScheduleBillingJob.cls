/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Schedulable Class of Bills for creating a job 
Inputs:        NA
Last Modified: 23/12/2021
Test Class:    
----------------------------------------------------------------------------*/

global class ScheduleBillingJob implements Schedulable {
   global void execute(SchedulableContext sc) {
       BillingServicesBatch b = new BillingServicesBatch(); 
       database.executebatch(b);
   }
}