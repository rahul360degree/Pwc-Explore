/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for 'Opportunity' Trigger
Inputs:        NA
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class OpportunityTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    /*
    Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.OpportunityTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Opportunity Trigger
    Inputs:        list of inserted records
    Test Class:   
    
    History
    08-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        OpportunityFieldPopulator fieldPopulator = new OpportunityFieldPopulator();
        // Added by rohit jadhav on 31 July 2023 for PED
        fieldPopulator.validateOpportunityFieldsForPED((List<Opportunity>) newItems);
        fieldPopulator.checkLeadIsPresentForPED((list<Opportunity>)newItems);
        fieldPopulator.populateDefaults((list<Opportunity>)newItems);
        fieldPopulator.validateStage((list<Opportunity>)newItems,null);
        SoldToPricebookUtility.setPriceBookAtOpportunity((list<Opportunity>)newItems);
        SharingUtility.setParentContacts(newItems, null, false, false);
       	fieldPopulator.populateOpportunityWarehouse((List<Opportunity>) newItems);
        
        //Added here by Praful - 22-Feb-2021
        fieldPopulator.populateEndDate((List<Opportunity>) newItems);
        fieldPopulator.updateOpportunityNumbers((List<Opportunity>) newItems);
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 'Opportunity' Trigger
    Inputs:        map of created records
    Test Class:   
    
    History
    08-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        OpportunityFieldPopulator fieldPopulator = new OpportunityFieldPopulator();
        fieldPopulator.validateStage((list<Opportunity>)newItems.values(),(Map<Id,Opportunity>)oldItems);
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, false);
        fieldPopulator.populateOpportunityWarehouse((List<Opportunity>) newItems.values());
        fieldPopulator.validateOpportunityWarehouses((Map<Id, Opportunity>) newItems, (List<Opportunity>) oldItems.values());
        
        //Added here by Praful - 22-Feb-2021
        fieldPopulator.populateEndDate((Map<Id, Opportunity>) newItems, (Map<Id, Opportunity>) oldItems);

    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle After Update event context of 'Opportunity' Trigger
    Inputs:        map of created records
    Test Class:   
    
    History
    22-10-2020      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        OpportunityFieldPopulator fieldPopulator = new OpportunityFieldPopulator();
        fieldPopulator.updateOpportunityProductWarehouses((Map<Id, Opportunity>) newItems, (List<Opportunity>) oldItems.values());
        // Added by rohit jadhav on 31 July 2023 for PED
        fieldPopulator.updateBalanceOpportunityValueOnLeadForPED((Map<Id, Opportunity>) newItems, (Map<Id, Opportunity>) oldItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Opportunity Trigger
    Inputs:        list of inserted records
    Test Class:   
    
    History
    27-06-2023      Rohit Jadhav     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(Map<Id, SObject> newItems) {
        OpportunityFieldPopulator fieldPopulator = new OpportunityFieldPopulator();
        fieldPopulator.updateBalanceOpportunityValueOnLeadForPED((Map<Id, Opportunity>) newItems, null);
    }
}