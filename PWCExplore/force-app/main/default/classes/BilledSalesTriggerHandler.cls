/*------------------------------------------------------------------------
Company:       Salesforce
Description:   Handler class for Billed_Sales_Outstandings Object Trigger
Inputs:        NA
Test Class:    BilledSalesTriggerTest
History
27-11-2020     Abhishek Chaturvedi     Initial Release
----------------------------------------------------------------------------*/
public with sharing class BilledSalesTriggerHandler extends VTriggerHandler{
    public static Boolean tiggerDisabled = false;

    /*
     *   Checks to see if the trigger has been disabled either by custom setting or by running code
     */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.BilledSalesTriggerDisabled__c)
            return true;
        else 
            return tiggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Abhishek Chaturvedi
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of 'Billed_Sales_Outstandings' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    27-11-2020      Abhishek     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        BilledSalesTriggerHelper helper = new BilledSalesTriggerHelper();
        helper.populateDefaultsOnReceivable((List<Billed_Sales_Outstandings__c>) newItems);
        SharingUtility.setParentContacts(newItems, null, false, false);
    }

    /*------------------------------------------------------------------------
    Author:        Abhishek Chaturvedi
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 'Billed_Sales_Outstandings' Trigger
    Inputs:        map of created records
    Test Class:   
    --------------------------------------------------------------------------
    History
    27-11-2020      Abhishek     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems) {
        BilledSalesTriggerHelper helper = new BilledSalesTriggerHelper();
        helper.updateSalesRepresentative(newItems,oldItems);
        helper.setStatusAndNotDueSince((Map<Id,Billed_Sales_Outstandings__c>) newItems, (Map<Id,Billed_Sales_Outstandings__c>) oldItems);
        helper.setDetailsForApprovals((Map<Id,Billed_Sales_Outstandings__c>) newItems, (Map<Id,Billed_Sales_Outstandings__c>) oldItems);
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, false);
    }
}