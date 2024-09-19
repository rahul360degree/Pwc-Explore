/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Handler class for Claim Request Trigger
Inputs:        NA
Test Class:    
History
19-11-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public with sharing class ClaimRequestTriggerHandler extends VTriggerHandler {
      public static Boolean TriggerDisabled = false;
    
      public override Boolean IsDisabled(){
         Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
         if (setting.ClaimRequestTriggerDisabled__c)
             return true;
         else 
             return TriggerDisabled;
      }
     
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of claim request Trigger
    Inputs:        list of created records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    19-11-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        //If order__c and order_product__c are blank, annexure B
        //If order and order product are not blank, annexure A
        ClaimRequestTriggerHelper helper=new ClaimRequestTriggerHelper();
        helper.classifyNewRecordsAndPerformActions(newItems);
        helper.setDealerBasicAmount((List<Claim_Requests__c>)newItems,null);
        helper.populateUniqueKeyValueOnNewClaimRequestRecord((List<Claim_Requests__c>)newItems);
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe 
    Company:       Salesforce
    Description:   Method to handle Before Update event context of claim request Trigger
    Inputs:        Map of old and updated records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    19-11-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        ClaimRequestTriggerHelper helper=new ClaimRequestTriggerHelper();
        helper.validateSubmittedForApprovalClaimRequest((List<Claim_Requests__c>)newItems.values(),(Map<Id,Claim_Requests__c>)oldItems);
        helper.updateWarehouseOnCompanyUpdate((List<Claim_Requests__c>)newItems.values(),(Map<Id,Claim_Requests__c>)oldItems);
        helper.handleBusinessPartnerUpdatedForClaimRequestSccAndCreditNote((Map<Id, Claim_Requests__c>)newItems, (Map<Id, Claim_Requests__c>)oldItems);
        helper.validateWarrantyClaimRequest((Map<Id, Claim_Requests__c>)newItems, (Map<Id, Claim_Requests__c>)oldItems);
        helper.populatePriceOnWarrantyClaim((Map<Id,Claim_Requests__c>)newItems, (Map<Id,Claim_Requests__c>)oldItems);
        helper.handleGodrejSalesOrderUpdated((Map<Id,Claim_Requests__c>)newItems, (Map<Id,Claim_Requests__c>)oldItems);
        helper.integrationUpdateHelper((List<Claim_Requests__c>)newItems.values(),(Map<Id,Claim_Requests__c>)oldItems);
        helper.handleCompanyChangeOnSCCRecord((Map<Id,Claim_Requests__c>)newItems, (Map<Id,Claim_Requests__c>)oldItems);
        helper.setDealerBasicAmount((List<Claim_Requests__c>)newItems.values(),(Map<Id,Claim_Requests__c>)oldItems);
        helper.populateUniqueKeyValueOnUpdatedClaimRequestRecord((Map<Id,Claim_Requests__c>)newItems, (Map<Id,Claim_Requests__c>)oldItems);
        helper.updateApproversOnClaimRequestIfBranchOrAreaUpdated((Map<Id,Claim_Requests__c>)newItems, (Map<Id,Claim_Requests__c>)oldItems);
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of claim request Trigger
    Inputs:        map of inserted records
    Test Class:   

    History
    01-12-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        ClaimRequestTriggerHelper helper = new ClaimRequestTriggerHelper();
        helper.populatePrimaryDealerOnAsset((Map<Id, Claim_Requests__c>)newItems, null);
        helper.grantISREditAccessToBranchChampion((List<Claim_Requests__c>)newItems.values(),null);
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of claim request Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    01-12-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        ClaimRequestTriggerHelper helper = new ClaimRequestTriggerHelper();
        helper.populatePrimaryDealerOnAsset((Map<Id, Claim_Requests__c>)newItems, (Map<Id, Claim_Requests__c>)oldItems);
        helper.grantISREditAccessToBranchChampion((List<Claim_Requests__c>)newItems.values(), (Map<Id, Claim_Requests__c>)oldItems);
    }  
}