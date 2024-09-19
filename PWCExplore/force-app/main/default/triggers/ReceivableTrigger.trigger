/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Trigger to handle database events on 'Receivable__c' records
               Object Name - Line Item (Receivable__c)
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
01-12-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
trigger ReceivableTrigger on Receivable__c (before insert, after insert, before update, after update) {
	 TriggerDispatcher.Run(new ReceivableTriggerHandler());
}