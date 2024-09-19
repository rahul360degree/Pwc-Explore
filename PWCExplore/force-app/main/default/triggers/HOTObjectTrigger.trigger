/*------------------------------------------------------------------------
Author:        Saurabh Mehta, Jayasurya G
File Name:     HOTObjectTrigger.apxt
Company:       Stetig, Stetig
Description:   Trigger on Head of Terms for creating record in premise traction, Updating end date of Licence & Licence Abstarction
Inputs:        NA
Last Modified: 16/12/2021
Test Class:    
----------------------------------------------------------------------------*/

trigger HOTObjectTrigger on HEAD_OF_TERMS__c (before insert, before update, after insert, after update) {
    
    // Call to handler for specific scenarios which is before update
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {            
            // Method is to check if the unit is not under lease
            HOTObjectTriggerHandler.unitUnderLeaseCheck(Trigger.new, Trigger.oldMap);
        }
    }
    // Call to handler for specific scenarios which is after update
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            // Method is use to create Premise traction record with event LOI
            HOTObjectTriggerHandler.createPTonLOI(Trigger.new, Trigger.oldMap);
            
            // Method is use to create Premise traction record with event LNL
            HOTObjectTriggerHandler.createPTonLNL(Trigger.new, Trigger.oldMap);
            
            // Method is use to update Licence end date on rental Unit
            HOTObjectTriggerHandler.updateLienceEndDateOnRentalUnit(Trigger.new, Trigger.oldMap);
            
            // Method is use to update Licence Abstraction
            HOTObjectTriggerHandler.updateLicenseAbstract(Trigger.new, Trigger.oldMap);
            
            // Method is use to hide Prmise Action on HOT
            HOTObjectTriggerHandler.hidePremiseAction(Trigger.new, Trigger.oldMap);
        }
        
    }
    
}