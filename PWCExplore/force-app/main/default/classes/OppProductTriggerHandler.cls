/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Handler class for 'OpportunityProduct' Trigger
Inputs:        NA
Test Class:    
History
11-05-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public class OppProductTriggerHandler extends VTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.OpportunityProductTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle before insert event context of Opportunity Product Trigger
    Inputs:        map of created records
    Test Class:   

    History
    11-05-2020      Kartik Shetty     Initial Release
    26-05-2020      Kartik Shetty     Added method to populate Asset Serial Number
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems) {
        GlobalConstants.SKIP_QUOTE_LOCK = true;
        OppProductRecordProcessor recordProcessor = new OppProductRecordProcessor();
        recordProcessor.setDefaultWarehousesBasedOnOpportunity((List<OpportunityLineItem>) newItems);
        recordProcessor.productBundlingLogicFor_MHE_Equipments((List<OpportunityLineItem>) newItems, 'INSERT');
        recordProcessor.updateAssetSerialNumber((List<OpportunityLineItem>) newItems);
        recordProcessor.updateSalesPrice((List<OpportunityLineItem>) newItems);
        recordProcessor.validateSalesPrice((List<OpportunityLineItem>) newItems);
        recordProcessor.populateDefaultOpportunityProductWarehouses((List<OpportunityLineItem>) newItems);
        recordProcessor.calculateSalesAmount((List<OpportunityLineItem>) newItems);
        //Added by Praful - 22-Feb-2021
        recordProcessor.populateDefaultDurationFields((List<OpportunityLineItem>) newItems);
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to handle before update event context of Opportunity Product Trigger
    Inputs:        map of created records
    Test Class:   

    History
    26-05-2020      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems) {
        OppProductRecordProcessor recordProcessor = new OppProductRecordProcessor();
        recordProcessor.setDefaultWarehousesBasedOnOpportunity((List<OpportunityLineItem>) newItems.values());
        recordProcessor.productBundlingLogicFor_MHE_Equipments((List<OpportunityLineItem>) newItems.values(), 'UPDATE');
        recordProcessor.updateAssetSerialNumber((List<OpportunityLineItem>) newItems.values());
        recordProcessor.validateSalesPrice((Map<Id, OpportunityLineItem>) newItems, (Map<Id,OpportunityLineItem>) oldItems);
        recordProcessor.populateDefaultOpportunityProductWarehouses((List<OpportunityLineItem>) newItems.values());
        recordProcessor.validateOpportunityProductWarehouses((Map<Id, OpportunityLineItem>) newItems, (List<OpportunityLineItem>) oldItems.values());
        recordProcessor.calculateSalesAmount((List<OpportunityLineItem>) newItems.values());
    }
   
      /*------------------------------------------------------------------------
     Author:        Snehal W
     Company:       GITL
     Description:   
    ----------------------------------------------------------------------------*/
    public override void AfterDelete(Map<Id, SObject> oldItems) {
        OppProductRecordProcessor recordProcessor = new OppProductRecordProcessor();
        recordProcessor.callAutoLaunchFlow((List<OpportunityLineItem>) oldItems.values());
    }
}