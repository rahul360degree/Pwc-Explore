/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Schedulable Class for Batch Rental Units
Inputs:        NA
Last Modified: 22/12/2021
Test Class:    
----------------------------------------------------------------------------*/

global class ScheduleRentalJob implements Schedulable {
   global void execute(SchedulableContext sc) {
      BatchRentalUnits rental = new BatchRentalUnits(); 
      database.executebatch(rental);
   }
}