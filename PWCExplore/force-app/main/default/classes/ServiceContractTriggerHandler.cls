/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Handler class for Service Contract Trigger
Inputs:        NA
Test Class:    
History
26-11-2020      Manasi Londhe     Initial Release
09-11-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ServiceContractTriggerHandler extends VTriggerHandler {
	
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ServiceContractTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Order Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    13-01-2021     Amit Shingavi     Initial Draft
    ----------------------------------------------------------------------------*/
    public override void afterInsert(Map<Id, SObject> newItems){
        ServiceContractTriggerHelper helper = new ServiceContractTriggerHelper();
    	helper.populateIntegrationDefaults((map<Id, ServiceContract>)newItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Service Contract Trigger
    Inputs:        map of updated records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    19-11-2020      Manasi Londhe     Initial Release
    09-11-2020      Kishor Kumar     Initial Release   
    -----------------------------------------------------
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        ServiceContractTriggerHelper helper = new ServiceContractTriggerHelper();
	helper.createClaimRequest((List<ServiceContract>)newItems.values(),(Map<Id,ServiceContract>)oldItems);
        helper.deactivateAllAssetBenefitsForInactiveServiceContract((map<Id, ServiceContract>)newItems, (map<Id, ServiceContract>)oldItems);
    	helper.populateIntegrationStatusOnLines((map<Id, ServiceContract>)newItems, (map<Id, ServiceContract>)oldItems);
        helper.populateDefaultsOnLines((map<Id, ServiceContract>)newItems, (map<Id, ServiceContract>)oldItems);
    }
    
     /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to handle After Update event context of Service Contract Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    11-01-2020      Amit Shingavi    Populate Contract Renewal Duration and Unit 
    ----------------------------------------------------------------------------*/
    
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        ServiceContractTriggerHelper helper = new ServiceContractTriggerHelper();
        
        helper.populateTheContractRenewals((map<Id, ServiceContract>)newItems, (map<Id, ServiceContract>)oldItems);
        helper.ServiceContractNextApproverSelector((map<Id, ServiceContract>)newItems, (map<Id, ServiceContract>)oldItems);
    }
}