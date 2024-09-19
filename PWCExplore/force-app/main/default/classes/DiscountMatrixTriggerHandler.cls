/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Handler class for Discount Matrix Trigger
Inputs:        NA
Test Class:    
History
18-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class DiscountMatrixTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.DiscountMatrixTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Ashwin Thale
    Company:       Godrej Infotech
    Description:   Method to find similar Discount Matrix and Inactive it and update End Date.
    Inputs:        List of SObject of Discount Matrix Records.
    Test Class:    

    History
    17-01-2024      Ashwin Thale     Initial Release
    ----------------------------------------------------------------------------*/
    
    public override void AfterInsert(Map<Id, SObject> newItems){
        DiscountMatrixTriggerHelper helper=new DiscountMatrixTriggerHelper();
        helper.updateStageAndEndDate((list<Discount_Matrix__c>)newItems.values());
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to handle before Update event context of Discount Matrix.
    Inputs:        Map of new and old updated records.
    Test Class:   

    History
    18-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        DiscountMatrixTriggerHelper helper=new DiscountMatrixTriggerHelper();
        helper.UpdateOrderLinesIfMatrixDeactivated((list<Discount_Matrix__c>)newItems.values(),(Map<Id,Discount_Matrix__c>)oldItems);
    }
}