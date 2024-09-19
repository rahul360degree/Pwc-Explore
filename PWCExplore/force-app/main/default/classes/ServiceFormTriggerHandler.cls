/*------------------------------------------------------------------------
Author:        Nupoor Sharma
Company:       Salesforce
Description:   Handler class for Service Form Trigger
Inputs:        NA
Test Class:    
History
16-12-2020      Nupoor Sharma     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ServiceFormTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
     *  Checks to see if the trigger has been disabled either by custom setting or by running code
     */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ServiceFormTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
     /*------------------------------------------------------------------------
    Description:   Method to now to allow users to create multiple job card for the same day against a SR
    Inputs:        map of created records
    Test Class:   

    History
    17-12-2020      Amit Shingavi     Initial Draft
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<SObject> newItems){
        
        ServiceFormTriggerHelper helper = new ServiceFormTriggerHelper();
        helper.validatetheJobCardForms((List<Service_Form__c>)newItems);
        helper.populateOldEHM((List<Service_Form__c>)newItems);
        helper.populateBranchChampion((List<Service_Form__c>)newItems);
     }


    /*------------------------------------------------------------------------
    Description:   Method to handle After Insert event context of Service Form Trigger
    Inputs:        map of created records
    Test Class:   

    History
    16-12-2020      Nupoor Sharma     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        
        ServiceFormTriggerHelper helper = new ServiceFormTriggerHelper();
        helper.shareWithCaseTeam((map<Id, Service_Form__c>)newItems);
        helper.mandateSignatureToSubmit((List<Service_Form__c>)newItems.values(), NULL );

    }
    
    /*------------------------------------------------------------------------
    Description:   Method to handle Before Update event context of Service Form Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    08-02-2021      Nupoor Sharma     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ServiceFormTriggerHelper helper = new ServiceFormTriggerHelper();
        helper.mandateSignatureToSubmit((List<Service_Form__c>)newItems.values(),(Map<Id, Service_Form__c>) oldItems );

    }

}