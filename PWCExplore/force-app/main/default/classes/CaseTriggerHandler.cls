/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Handler class for Case Trigger
Inputs:        NA
Test Class:    
History
19-10-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class CaseTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.CaseTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar 
    Company:       Salesforce
    Description:   Method to handle Before Insert event context of Case Trigger
    Inputs:        list of created records
    Test Class:   
    ---------------------------------------------------------------------------
    History
    20-10-2020      Kishor     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeInsert(List<sObject> newItems){
        CaseFieldPopulator fieldPopulator = new CaseFieldPopulator();
        
        fieldPopulator.populateDefaults((list<Case>)newItems);
        fieldPopulator.assignSSGCases((list<Case>)newItems);
        fieldPopulator.assignCases((list<Case>)newItems);
        fieldPopulator.populateZipCodeRule((list<Case>)newItems,null);
        fieldPopulator.populateAccount((list<Case>)newItems);
        fieldPopulator.populateEntitlement((list<Case>)newItems);
        fieldPopulator.checkOpenCasePerCategory((List<Case>)newItems,'insert');
        fieldPopulator.populateEscalationStartTime((list<Case>)newItems, null);
        fieldPopulator.populateEscalationEmailFields((list<Case>)newItems);
        CaseTriggerHelper.validateServiceRequestForDealer((List<Case>)newItems);
        CaseTriggerHelper.populateServiceRequestDefaultsFromOrderProduct((List<Case>)newItems);
        CaseTriggerHelper.populateServiceRequestDefaultsFromItemCodeOrProduct((List<Case>)newItems);
        //fieldPopulator.checkJobCardBeforeClosing((list<Case>)newItems);//no need to call here as it is checking for Resolved/Closed status which cant be at creation
        fieldPopulator.populateEntitlementForMHE_basedOn_callPendingReason((List<Case>)newItems, new Map<Id, Case>());
        fieldPopulator.validateActiveAssetBenefit((list<Case>)newItems,null);
        CaseTriggerHelper.CaseDeduplication((List<Case>)newItems);
        //fieldPopulator.BulkUploadServiceRequest((list<Case>)newItems);

    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Case Trigger
    Inputs:        map of created records
    Test Class:   

    History
    20-10-2020      Kishor Kumar     Initial Release
    10-12-2021      Saurabh Mehta    Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        CaseFieldPopulator fieldPopulator = new CaseFieldPopulator();
        fieldPopulator.executeZipCodeBasedAssignment((list<Case>)newItems.values());
        fieldPopulator.setAssignmentRule((list<Case>)newItems.values(),null);        
        fieldPopulator.shareCasesWithRoles((list<Case>)newItems.values(),null);
        fieldPopulator.createMilestone((Map<Id,Case>)newItems, null);
        fieldPopulator.addSSGCaseOwnerToCaseTeam((Map<Id,Case>)newItems, null);
        fieldPopulator.addUserToCaseTeam((list<Case>)newItems.values());
        fieldPopulator.SMSNotificationOnStatucChange((list<Case>)newItems.values(), null); 
        CaseFieldPopulator.setOwnerforAccountCreationRecordTypeCasesinInsertion((list<Case>)newItems.values()); //Added By Shreela on 27th September 2023  for SMEPB-123/124 
        CaseFieldPopulator.CreateAsset((list<Case>)newItems.values()); //Added by Sai Kumar on 22-04-2024 for asset creation when case created for amazon installation
        //fieldPopulator.BulkUploadWorkOrderCreation((list<Case>)newItems.values());
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle before Update event context of Case Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    20-10-2020      Kishor Kumar     Initial Release
    06-10-2021      Kartik Shetty    Added call to the method that resets the entitlement id for MHE Service Request,
                                     on change to Call Pending reason
    10-12-2021      Saurabh Mehta    Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        CaseFieldPopulator fieldPopulator = new CaseFieldPopulator();
        fieldPopulator.validateCaseChange((Map<Id,Case>)newItems, (Map<Id,Case>)oldItems);
        fieldPopulator.populateZipCodeRule((list<Case>)newItems.values(), (Map<Id,Case>)oldItems);
        fieldPopulator.populateAccount((list<Case>)newItems.values());
        fieldPopulator.populateEntitlement((list<Case>)newItems.values());
        fieldPopulator.populateEscalationStartTime((list<Case>)newItems.values(), (map<Id, Case>)oldItems);
        fieldPopulator.populateEscalationEmailFields((list<Case>)newItems.values());  
        fieldPopulator.checkOpenCasePerCategory((List<Case>)newItems.values(),'update');  
        fieldPopulator.ssgCaseClosingValidation((map<Id, Case>)newItems, (map<Id, Case>)oldItems);
        fieldPopulator.validateInterioCaseStatus((map<Id, Case>)newItems, (map<Id, Case>)oldItems);
        fieldPopulator.validateMHECaseStatus((map<Id, Case>)newItems, (map<Id, Case>)oldItems);
        fieldPopulator.checkJobCardBeforeClosing((List<Case>)newItems.values());
        fieldPopulator.populateDealerSupervisor((list<Case>)newItems.values(), (Map<Id,Case>)oldItems);
        CaseTriggerHelper.populateServiceRequestDefaultsFromItemCodeOrProduct((map<Id, Case>)newItems, (map<Id, Case>)oldItems);
        fieldPopulator.populateEntitlementForMHE_basedOn_callPendingReason((List<Case>)newItems.values(), (Map<Id, Case>) oldItems);
        fieldPopulator.validateActiveAssetBenefit((list<Case>)newItems.values(),(Map<Id, Case>) oldItems);
        fieldPopulator.CalculateTimeOnCase((list<Case>)newItems.values(),(Map<Id, Case>) oldItems); 
        //CaseTriggerHelper.CaseDeduplication((List<Case>)newItems.values(),(Map<Id, Case>) oldItems);

        //Transfer case to THD...
        CaseTriggerHelper.transferToTHD((List<Case>)newItems.values());

        //Legal Case Assignment to HO...
        // CaseTriggerHelper.legalCaseAssignment((List<Case>)newItems.values());

        //Case Esclation...
        CaseTriggerHelper.caseEsclation((List<Case>)newItems.values());

    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar

    Description:   Method to handle After Update event context of Case Trigger
    Inputs:        map of created records
    Test Class:   

    History
    20-10-2020      Kishor Kumar     Initial Release   
    21-10-2020      Amit Shingavi    Added a method to update the Asset commission date on the SR Closure
    12-01-2021      Kartik Shetty    Added method to update Case milestones if Escalation_process_start_time__c is modified
    10-12-2021      Saurabh Mehta    Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        
        CaseFieldPopulator fieldPopulator = new CaseFieldPopulator();
        fieldPopulator.updateCaseMilestones((Map<Id,Case>) newItems, (Map<Id,Case>) oldItems);
        fieldPopulator.setAssignmentRule((list<Case>)newItems.values(),(Map<Id,Case>)oldItems);
        fieldPopulator.executeZipCodeBasedAssignment((list<Case>)newItems.values());
        fieldPopulator.shareCasesWithRoles((list<Case>)newItems.values(),(Map<Id,Case>)oldItems);
        fieldPopulator.addBranchChampionToCaseTeam((Map<Id,Case>)newItems,(Map<Id,Case>)oldItems);
        fieldPopulator.addSSGCaseOwnerToCaseTeam((Map<Id,Case>)newItems, (Map<Id,Case>)oldItems);
        fieldPopulator.addUserToCaseTeam((list<Case>)newItems.values());
        fieldPopulator.addMHECaseOwnerToCaseTeam((Map<Id,Case>) newItems, (Map<Id,Case>) oldItems);
        fieldPopulator.updateAssetOnSRClosure((list<Case>)newItems.values(),(Map<Id,Case>)oldItems);
        //AddedBy Anupam Mishra on 01/04/2021
        fieldPopulator.ValidateAssetOnSRClosure((list<Case>)newItems.values(),(Map<Id,Case>)oldItems);
        fieldPopulator.calculateAssetHourMeter((list<Case>)newItems.values());
        fieldPopulator.updateAssetEnrollmentStatus((Map<Id,Case>) newItems);
        fieldPopulator.SMSNotificationOnStatucChange((list<Case>)newItems.values(), (Map<Id,Case>)oldItems); 
        CaseFieldPopulator.setOwnerforAccountCreationRecordTypeCasesinUpdation((list<Case>)newItems.values(), (Map<Id,Case>)oldItems); //Added By Shreela on 27th September 2023  for SMEPB-123/124 
  }
}