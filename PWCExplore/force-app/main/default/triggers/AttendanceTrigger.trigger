/*------------------------------------------------------------------------
Author:        Kshipra Kankariya
Company:       Salesforce
Description:   Trigger to handle database events on 'Attendance' records
               Object Name - Attendance
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
13-10-2020      Kshipra Kankariya     Initial Release
----------------------------------------------------------------------------*/
trigger AttendanceTrigger on Attendance__c (before insert, before update) {
    
    TriggerDispatcher.Run(new AttendanceTriggerHandler());

}