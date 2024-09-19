/*------------------------------------------------------------------------------
 * Author:        Joshna
 * Company:       Salesforce
 * Description:   Trigger to handle Time Entry validations
 * ---------------------------------------------------------------------------
 * History
 * 16-11-2020      Joshna     Initial Release
 * ----------------------------------------------------------------------------*/
trigger TimeEntryTrigger on Time_Entry__c (before insert, before update) {
    TriggerDispatcher.Run(new TimeEntryTriggerHandler());
}