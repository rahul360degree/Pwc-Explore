/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Handler class for 'projectMilestonTrigger'.
Inputs:        NA
Test Class:   

History
02-12-2020      Suwarna Rao     Initial Release
----------------------------------------------------------------------------*/
public class ProjectMilestoneTriggerHandler extends VTriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public override Boolean IsDisabled(){
        system.debug('ProjectMilestoneTriggerHandler - IsDisabled'); 
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        if (setting.ProjectMilestoneTriggerDisabled__c)
            return true;
        else 
            return TriggerDisabled;
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to handle before Insert event context of Project Milestone Trigger
    Inputs:        List of created records
    Test Class:   
    
    History
    02-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/   
    
    public override void BeforeInsert(list<SObject> newItems){
       system.debug('ProjectMilestoneTriggerHandler - BeforeInsert'); 
       ProjectMilestoneTriggerHelper helper = new ProjectMilestoneTriggerHelper();
       helper.preventDuplicateMilestoneRecords((list<Project_milestone__c>) newItems, null);
       helper.populateRevisedPlannedHandoverDate((list<Project_milestone__c>)newItems, null);
       helper.updateCCStatus((list<Project_milestone__c>)newItems);
       helper.validateData((list<Project_milestone__c>)newItems);
       helper.populateFields((list<Project_milestone__c>) newItems);//Moved by pankaj from after insert to before insert
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Project Milestone Trigger
    Inputs:        map of created records
    Test Class:   

    History
    31-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public override void AfterInsert(map<Id, sObject> newItems){
        system.debug('ProjectMilestoneTriggerHandler - AfterInsert'); 
        ProjectMilestoneTriggerHelper helper = new ProjectMilestoneTriggerHelper();
        //helper.populateFields((list<Project_milestone__c>) newItems.values());//commented by pankaj and added in before insert
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to handle before Update event context of Project Milestone Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    02-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        system.debug('ProjectMilestoneTriggerHandler - BeforeUpdate'); 
        ProjectMilestoneTriggerHelper helper = new ProjectMilestoneTriggerHelper();
        helper.preventDuplicateMilestoneRecords((list<Project_milestone__c>) newItems.values(), (Map<Id, Project_milestone__c>)oldItems);
        helper.bookingEndDateValidation((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.populateRevisedPlannedHandoverDate((list<Project_milestone__c>)newItems.values(), (Map<Id, Project_milestone__c>)oldItems);
        helper.populateRevisedPlannedHandoverDateOnPlannedHandoverDateChange((list<Project_milestone__c>)newItems.values(), (Map<Id, Project_milestone__c>)oldItems);
        helper.installationStartDateValidation((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.ccDateValidation((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.updateIsBookingPlannedHandoverDateModifiedFlag((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.roundOffToMultipleOfFive((Map<Id, Project_milestone__c>)newItems);
        helper.updateFieldValues((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.projectCompletionValidation((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.populateOTIFDetailsOnCCDateChange((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.populateOTIFDetails((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.updateCCStatus((list<Project_milestone__c>)newItems.values());
        helper.validateData((list<Project_milestone__c>)newItems.values());
        helper.validateCCDateUpdate((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.validateMilestonesThatShouldBeLocked((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
      }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Update event context of Project Milestone Trigger
    Inputs:        map of updated records
    Test Class:   

    History
    10-12-2020      Kishor Kumar     Initial Release   
    ----------------------------------------------------------------------------*/
    public override void AfterUpdate(map<Id, sObject> newItems, map<Id, sObject> oldItems){
        system.debug('ProjectMilestoneTriggerHandler - AfterUpdate'); 
       	ProjectMilestoneTriggerHelper helper = new ProjectMilestoneTriggerHelper();
    	helper.reasonForHandoverDateChangeValidation((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
    	helper.ccStatusUpdate((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.populateOTIFDetails((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);
        helper.populateProjectStatus((Map<Id, Project_milestone__c>)newItems);
        helper.populateExecutionFields((Map<Id, Project_milestone__c>)newItems);        
        helper.validateAndUpdateSupplyFieldValues((Map<Id, Project_milestone__c>)newItems, (Map<Id, Project_milestone__c>)oldItems);       
    }
}