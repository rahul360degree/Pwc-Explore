/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Trigger to handle database events on 'Advance Payment Details' records
Inputs:        NA
Test Class:   

History
24-06-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
trigger AdvancePaymentDetailTrigger on Advance_Payment_Details__c (before insert, before update, before delete) {
	 TriggerDispatcher.Run(new AdvancePaymentDetailTriggerHandler());
}