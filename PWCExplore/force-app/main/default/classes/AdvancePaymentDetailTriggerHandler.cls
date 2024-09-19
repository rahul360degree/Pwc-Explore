/*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Handler class for Advance Payment Details Trigger
Test Class:  
---------------------------------------------------------------------------
History
24-06-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AdvancePaymentDetailTriggerHandler extends VTriggerHandler {
	// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    
    // flag to Skip order validations
    public static boolean SKIP_ORDER_VALIDATIONS = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AdvancePaymentDetailsTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
   /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of 
				   'Advance Payment Details' Trigger
    Inputs:        map of created records
    Test Class:   
	--------------------------------------------------------------------------
    History
    24-06-2020      Shailja     Initial Release
	----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        SKIP_ORDER_VALIDATIONS = true;
        AdvancePaymentDetailTriggeHandlerHelper helper = new AdvancePaymentDetailTriggeHandlerHelper();
        helper.populateDetailsAsPerSchemeSelected((List<Advance_Payment_Details__c>) newItems,null);
        helper.skipAdvancePaymentDetailGenerationForInterioB2C((List<Advance_Payment_Details__c>) newItems);//Added by Shreela and Namrata on 24-02-2023 for Jira SIEPB-69
        //added by Jalaj 30/04/2021
       	helper.updateDocumentNumberAsPerTransactionType((List<Advance_Payment_Details__c>) newItems);
       
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja
    Company:       Salesforce
    Description:   Method to handle Before Update event context of 
				   'Advance Payment Details' Trigger
    Inputs:        map of created records
    Test Class:   
	--------------------------------------------------------------------------
    History
    24-06-2020      Shailja     Initial Release
	----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        SKIP_ORDER_VALIDATIONS = true;
        AdvancePaymentDetailTriggeHandlerHelper helper = new AdvancePaymentDetailTriggeHandlerHelper();
        helper.populateDetailsAsPerSchemeSelected((List<Advance_Payment_Details__c>) newItems.values(),(Map<Id,Advance_Payment_Details__c>)oldItems);
    }
   
    /*------------------------------------------------------------------------
    Author:        Jalaj
    Company:       Godrej Infotech
    Description:   Method to handle Before Delete event context of 
				   'Advance Payment Details' Trigger
    Inputs:        map of created records
    Test Class:   
	--------------------------------------------------------------------------
    History
    13-07-2021      Jalaj     Initial Release
	----------------------------------------------------------------------------*/
    public override void BeforeDelete(Map<Id,sObject> oldItems){
        SKIP_ORDER_VALIDATIONS = true;
        AdvancePaymentDetailTriggeHandlerHelper helper = new AdvancePaymentDetailTriggeHandlerHelper();
		helper.deletionNotAllowedAfterSyncToInfor((List<Advance_Payment_Details__c>) oldItems.values(),'delete');
    }
}