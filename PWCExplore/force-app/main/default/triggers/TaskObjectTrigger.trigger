/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     TaskObjectTrigger.apxt
Company:       Stetig, Stetig
Description:   Trigger on Task object whenever site visit status marked completed lead is getting convert into respective opportunity & HolidayList Interio BMR
Inputs:        NA
Last Modified: 10/10/2023
Last Modified by : Priyanka Mukkavalli
Test Class:    
----------------------------------------------------------------------------*/

trigger TaskObjectTrigger on Task (after Insert, after update, before Insert, before update) {
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert)){
        HolidayList.setScheduledEndDate(trigger.new);
        TaskObjectTriggerHandller.validateLeadBeforeConversion(Trigger.New, Trigger.OldMap, Trigger.isInsert);
    }
    
    if(Trigger.isAfter) {		
		if(Trigger.isInsert || Trigger.isUpdate) {
			TaskObjectTriggerHandller.convertLeadFromTask(Trigger.New, Trigger.OldMap, Trigger.isInsert);
		}
   }
}