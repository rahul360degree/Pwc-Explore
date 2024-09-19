/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Account Trigger
Inputs:        NA
Test Class:    
History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AccountTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.AccountTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Account Trigger
    Inputs:        list of inserted records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(list<SObject> newItems){
        
        AccountFieldPopulator populator = new AccountFieldPopulator();
        
        //Update BU & other defaults from Logged In User
        populator.populateDefaults((list<Account>) newItems);
        
        //convert accountName to upperCase
        populator.convertAccountNameToUpperCase((list<Account>) newItems,null);
        
        //Update BU & Type from Account Code
        populator.populateBUandTypeFromAccountCode((list<Account>) newItems);
        
        //validate if user can create MHE Business Account
        populator.validateIfUserCanCreateBusinessAccount((list<Account>) newItems);
        
        //populate Account series
        populator.populateAccountSeriesOnAccount((list<Account>) newItems);
        
        populator.populateParentAccountCode((list<Account>) newItems);
        
        //Update Account RT based on Type
        populator.updateRecordType((list<Account>) newItems);
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle Before Update event context of Account Trigger
    Inputs:        map of created records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){ 
        
        AccountFieldPopulator populator = new AccountFieldPopulator();
        
        //convert accountName to upperCase
        populator.convertAccountNameToUpperCase((list<Account>) newItems.values(),(map<Id,Account>)oldItems);
        
        //Update BU & Type from Account Code
        populator.populateBUandTypeFromAccountCode((list<Account>) newItems.values());
        
        //update Account series
        populator.populateAccountSeriesOnAccount((list<Account>) newItems.values());
        
        populator.populateParentAccountCode((list<Account>) newItems.values());
        
        //Update Account RT based on Type
        populator.updateRecordType((list<Account>) newItems.values());
        
        //to check mandatory fields required for Account Approval process-siddhesh
        populator.checkMandatoryFieldsForCONST((map<Id, Account>) newItems, (map<Id, Account>) oldItems); 
        
        //To populate approvers on account for construction rate revision approval process - Pankaj 3 may 2023
        populator.populateApprovers((list<Account>) newItems.values());

        //To populate approvers on account for ASP Onboarding - Tarun 26th March 2024
        populator.populateApproversForASPOnboarding((list<Account>) newItems.values());

        //To check manadatory documents - Tarun 8th April 2024
        populator.checkMandatoryDocuments((map<Id, Account>) newItems);

        //to check ASP mandatory fields after updating type
        populator.checkMandatoryFieldsAfterUpdatingType((list<Account>) newItems.values());

        //to check all required checkBoxes before updating status to "Full and Final Settlement Done and ASP Closed"
        populator.checkMandatoryFieldBeforeFullAndFinalSettlement((list<Account>) newItems.values());

        //to make comments mandatory during rejection
        populator.makeCommentsMandatoryDuringRejection((map<Id, Account>) newItems, (map<Id, Account>) oldItems);

        //to check the is ASP active checkbox after status change to active
        populator.changeCheckBoxAfterChangingStatusToActive((list<Account>) newItems.values());

        //to check if ASM upload the renewal document before Updating the End Date
        populator.checkRenewalDocumentBeforeChangingEndDate((map<Id, Account>) newItems, (map<Id, Account>) oldItems);
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Account Trigger
    Inputs:        map of created records
    Test Class:   

    History
    02-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        AccountFieldPopulator populator = new AccountFieldPopulator();
        
        //Update Blank Address Name
        populator.updateAddessNameOnAddress((list<Account>) newItems.values(),  (map<Id, Account>)newItems);
        
        //Add Entitlement record to account
        populator.createEntitlementsForAccount((list<Account>) newItems.values());
        
        //To get the records for staging table
        populator.captureKeyAccountChange((list<Account>) newItems.values());
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Account Trigger
    Inputs:        map of created records
    Test Class:   
    History
    02-04-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        AccountFieldPopulator populator = new AccountFieldPopulator();
        
        //Update Blank Address Name
        populator.updateAddessNameOnAddress((list<Account>) newItems.values(),  (map<Id, Account>)newItems);
        populator.updateAccountNameOnAddressByBP((list<Account>) newItems.values(),  (map<Id, Account>)newItems);
        
        //To get the records for staging table
        populator.captureKeyAccountChange((list<Account>) newItems.values());
    }


}