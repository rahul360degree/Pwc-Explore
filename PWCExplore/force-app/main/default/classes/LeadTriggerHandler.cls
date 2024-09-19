/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Lead Trigger
Inputs:        NA
Test Class:    
History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class LeadTriggerHandler extends VTriggerHandler {
    
    //Store logged in user branch
    public static User loggedInUser;
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    {
        //Check if branch name is already populated [To reduce SOQL query count]
        if(loggedInUser == null){
            loggedInUser = [Select Id,Logistic_Company__c,Interio_Sub_Division__c,Business_Unit__c, area_code__c FROM USER WHERE Id =: UserInfo.getUserId() LIMIT 1];
        }
    }
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.LeadTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Shailja 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Lead Trigger
    Inputs:        list of created records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    20-04-2020      Shailja     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        LeadFieldPopulator fieldPopulator = new LeadFieldPopulator();
        fieldPopulator.populateZipCodeRule((list<Lead>)newItems,null);
        fieldPopulator.populateEmailDomain((list<Lead>)newItems,null);
        //fieldPopulator.SendNotificationtoLeadQueueMembers((List<Lead>) newItems);
        fieldPopulator.populateDefaults((list<Lead>)newItems, loggedInUser);
        //findDuplicateLeads.checkDuplicateLeads((list<Lead>)newItems);
        SharingUtility.setParentContacts(newItems, null, false, true);
        //LeadFieldPopulator.validateEmail((list<Lead>)newItems); //Added by Shreela on 28th Feb 2023 for SIEPB 70 
        fieldPopulator.populateNameForPES((list<Lead>) newItems); // Added by Shreela on 17th April 2023
        fieldPopulator.interioB2CUpdateStoreLocationFields((list<Lead>) newItems,null); // Added by rohit jadhav on 6th Feb 2024
    }

    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to handle before Update event context of Lead Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    08-05-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        LeadFieldPopulator fieldPopulator = new LeadFieldPopulator();
        fieldPopulator.populateZipCodeRule((list<Lead>)newItems.values(),(Map<Id,Lead>)oldItems);
        fieldPopulator.populateEmailDomain((list<Lead>)newItems.values(),null);
        fieldPopulator.populateDefaults((list<Lead>)newItems.values(), loggedInUser);
        fieldPopulator.calculateQualifiedDate((list<Lead>)newItems.values(), (Map<Id, Lead>) oldItems);  //Added by Sreekanth Jujare on 05/12/2022 for SIF-89
        SharingUtility.setParentContacts(newItems.values(), oldItems, false, true);
        fieldPopulator.interioB2COnLeadQualification((Map<Id, Lead>) newItems, (Map<Id, Lead>) oldItems); // Added by Deep 
        fieldPopulator.populateNameForPES((list<Lead>) newItems.values()); // Added by Shreela on 17th April 2023
        fieldPopulator.interioB2CUpdateSyncWithSFMCFieldOnOwnerChange((Map<Id, Lead>) newItems,(Map<Id, Lead>) oldItems); // Added by Rohit on 2nd Feb 2024
        fieldPopulator.interioB2CUpdateStoreLocationFields((list<Lead>) newItems.values(),(Map<Id, Lead>) oldItems); // Added by rohit jadhav on 6th Feb 2024
    }
    
    public override void AfterUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        LeadFieldPopulator fieldPopulator = new LeadFieldPopulator();
        fieldPopulator.createB2CAddresses((Map<Id, Lead>) newItems);
        fieldPopulator.sendCouponCodeEmailToGeneratedLeads((Map<Id, Lead>) newItems);
    }
     //Added by Shreela on 14th Feb 2023
    public override void AfterInsert(Map<Id, sObject> newItems){
        LeadFieldPopulator fieldPopulator = new LeadFieldPopulator();
        //fieldPopulator.sendCouponCodeEmailToGeneratedLeads((Map<Id, Lead>) newItems);
        //fieldPopulator.SendNotificationtoLeadQueueMembers((Map<Id, Lead>) newItems); //Added by Srini on 18th Feb 2023
        fieldPopulator.interioB2COwnerAssignment((List<Lead>)newItems.values()); //LDM
    }
    
    
}