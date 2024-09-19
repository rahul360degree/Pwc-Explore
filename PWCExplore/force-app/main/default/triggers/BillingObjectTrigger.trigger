/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan, Saurabh Mehta
Company:       Stetig, Stetig
Description:   Trigger on Billing
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/

trigger BillingObjectTrigger on Billing__c (before insert, before update, after insert, after update) {

    // Call to handler for specific scenarios
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            BillingObjectTriggerHandler.calculateAmountForWater(Trigger.new, Trigger.oldmap);
        }
    }
    
    // Call to handler for specific scenarios
     if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            AdditionalACChargesHandler.calculateACCharges(Trigger.new, Trigger.oldmap);
        }
    }

    
    // Call to handler for specific scenarios
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            PrimaryRecordCreationHandler.createOrderandLineItem(Trigger.new, Trigger.oldmap);
        }
   }
}