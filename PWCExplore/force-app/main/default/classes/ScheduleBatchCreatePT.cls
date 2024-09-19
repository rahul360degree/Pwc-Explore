/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     ScheduleBatchCreatePT.cls
Company:       Stetig 
Description:   Schedulable Batch Class for updating status on Premise Traction as per schedule
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/
global class ScheduleBatchCreatePT implements Schedulable {
   global void execute(SchedulableContext sc) {
      BatchCreatePT bpt = new BatchCreatePT(); 
      database.executebatch(bpt);
   }
}