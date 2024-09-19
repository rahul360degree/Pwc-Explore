/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Helper class for 'projectMilestoneTrigger'.
Inputs:        NA
Test Class:   

History
02-12-2020      Suwarna Rao     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ProjectMilestoneTriggerHelper {
    
    public static Map<String,String> recordTypeIdVsRecordTypeName = new Map<String,String>();
    private static final String PROJECT_MILESTONE_OBJECT_API_NAME = 'Project_milestone__c';

    {
        if(recordTypeIdVsRecordTypeName.size() == 0){
            for(RecordType recType : [Select Id,DeveloperName 
                                      From RecordType 
                                      Where sObjectType = :PROJECT_MILESTONE_OBJECT_API_NAME]){
                if(!recordTypeIdVsRecordTypeName.containsKey(recType.Id)){
                    recordTypeIdVsRecordTypeName.put(recType.Id,recType.DeveloperName);
                }
            }
        }      
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to populate fields
    Inputs:        maps of updated project Milestone records
    
    History
    31-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateFields(List<Project_milestone__c> newProjectMilestones){
        list<Project_milestone__c> milestones = new list<Project_milestone__c>();
        
        for(Project_milestone__c pm : [SELECT Id,Service_Request_and_Project_Name__c, Service_Request_Number__c, 
                                       			Name, Service_Request__c  
                                       	FROM Project_milestone__c 
                                      	WHERE Id IN: newProjectMilestones]){
            //Populate Service_Request_and_Project_Name__c with SR Number & Project Milestone Name
            if(pm.Service_Request__c != null){
                if(Schema.sObjectType.Project_milestone__c.fields.Service_Request_and_Project_Name__c.isupdateable()){ 
                   pm.Service_Request_and_Project_Name__c = pm.Service_Request_Number__c + ' - '+ pm.Name;
                  }
                milestones.add(pm);
            }
        }
        
        try{
            update milestones;
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateFields', '', ex);
        }
    }
    
   
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to prevent Duplicate records for Project Milestones
    Inputs:        maps of updated project Milestone records
    
    History
    08-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    public void preventDuplicateMilestoneRecords(List<Project_milestone__c> newProjectMilestones, map<Id,Project_milestone__c> oldMilestones){
       Set<Id> caseRecordIds = new Set<Id>();
       Map<Id, List<Project_milestone__c>> caseVsExistingMilestones = new Map<Id, List<Project_milestone__c>>();

       //get the restricted RT from label
       String restrictedMilestoneRecordType = System.Label.Restricted_PM_Record_Types;
       List<String> restrictedMilestoneRTs = restrictedMilestoneRecordType.split(',');
        
        //get all the parent service request
        for(Project_milestone__c projectMilestone :newProjectMilestones ){
            if(projectMilestone.Service_Request__c != null && 
              	(oldMilestones == null ||(oldMilestones != null && oldMilestones.containsKey(projectMilestone.Id) 
                                          && projectMilestone.RecordTypeId != oldMilestones.get(projectMilestone.Id).RecordTypeId))){
                caseRecordIds.add(projectMilestone.Service_Request__c);
            }
        }   
        
        //Fetch existing PM record for Cases
        for(Case caseRec : [SELECT Id, (SELECT Id, Service_Request__r.CaseNumber, RecordTypeId, RecordType.DeveloperName FROM Project_Milestones__r 
                                            WHERE RecordType.DeveloperName IN : restrictedMilestoneRTs) 
                            FROM Case WHERE Id IN: caseRecordIds]){
            caseVsExistingMilestones.put(caseRec.Id, new list<Project_milestone__c>(caseRec.Project_Milestones__r));                   
        }
    
        //Validation Logic & error
        for(Project_milestone__c pm : newProjectMilestones ){
            if(pm.Service_Request__c != null && caseVsExistingMilestones.containsKey(pm.Service_Request__c)){
                //Iterate Existing Milestones to check duplicate

                for(Project_milestone__c existingPm : caseVsExistingMilestones.get(pm.Service_Request__c)){
                    if(pm.RecordTypeId == existingPm.RecordTypeId){
                        pm.addError(existingPm.RecordType.DeveloperName + ' record type milestone already exist for the case -'+ existingPm.Service_Request__r.CaseNumber);
                    }
                }
            }
        }                 
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate Booking End dates for Booking RT based on the Design status
    Inputs:        maps of updated project Milestone records
    
    History
    08-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    public void bookingEndDateValidation(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> caseIds = new set<Id>();
        map<Id, Project_milestone__c> inCompleteDesignPMs = new map<Id, Project_milestone__c>();
        String incompleteStatus = GlobalConstants.PROJECT_MILESTONE_COMPLETED_STATUS;
        
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
        Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
        
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == bookingRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null &&
               	newMilestoneMap.get(pmId).End_Date__c != oldMilestoneMap.get(pmId).End_Date__c){
                caseIds.add(newMilestoneMap.get(pmId).Service_Request__c);
            }
        }
        
        //Fetch incomplete PMs
       if(caseIds.size() > 0){
           for(Project_milestone__c pm : [SELECT Id, Service_Request__c FROM Project_milestone__c 
                                          WHERE Service_Request__c IN : caseIds
                                          AND RecordTypeId =: designRTId 
                                          AND Status__c != : incompleteStatus]){
              inCompleteDesignPMs.put(pm.Service_Request__c, pm);                                
           }
       }
        
        //Validation logic
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == bookingRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null && 
               	newMilestoneMap.get(pmId).End_Date__c != oldMilestoneMap.get(pmId).End_Date__c &&
               	inCompleteDesignPMs.containsKey(newMilestoneMap.get(pmId).Service_Request__c)){
                newMilestoneMap.get(pmId).End_Date__c.addError(System.label.Project_Milestone_Incomplete_error_message);   
            }
        }        
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate for Ho Project Persona for edit & 
					populate revised Planned Date for Execution RT 
					With Booking RT Planned Handover Date
    Inputs:        list of created Project Milestone records
    
    History
    08-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //populate revised planned handover date(exe2) from planned handover date(booking)
    public void populateRevisedPlannedHandoverDate(list<Project_milestone__c> milestones, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> caseIds = new set<Id>();
        map<Id, Project_milestone__c> caseIdVsBookingPM = new map<Id, Project_milestone__c>();
        List<Project_milestone__c> executionMilestoneToUpdate = new List<Project_milestone__c>();
        
        //fetch RT Ids
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        
       /* //Fetch Admin Profile Id
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1].Id;
        
        //Fetch Current USer details
        User currentUser = [SELECT Id, Persona__c, profileId FROM User WHERE Id =: UserInfo.getUSerId() Limit 1];
        Boolean isHoProjectPersona = ((String.isNotBlank(currentUser.Persona__c) && currentUser.Persona__c == GlobalConstants.PROJECT_MILESTONE_HO_PROJECT_PERSONA) 
                                      	|| Id.valueOf(currentUser.profileId) == systemAdminProfileId) ? true : false;
        */
        for(Project_milestone__c pm : milestones){
            if(pm.RecordTypeId == executionRTId && pm.Revised_Planned_Handover_Date_ISOB_IDD__c == null && 
              pm.Service_Request__c != null){
               caseIds.add(pm.Service_Request__c); 
            }
        }
        
        //Fetch Booking PM details
       if(caseIds.size()>0){
           for(Project_milestone__c pm : [SELECT Id, Service_Request__c, Planned_Handover_Date_ISOB_IDD__c
                                          FROM Project_milestone__c 
                                          WHERE Service_Request__c IN : caseIds
                                          AND RecordTypeId =: bookingRTId 
                                          AND Planned_Handover_Date_ISOB_IDD__c != null]){
              caseIdVsBookingPM.put(pm.Service_Request__c, pm);                                
           }
       }
        
      //Population logic
        for(Project_milestone__c pm : milestones){
            //Insert: population logic
            //if(oldMilestoneMap == null){
                if(pm.RecordTypeId == executionRTId && pm.Revised_Planned_Handover_Date_ISOB_IDD__c == null && 
                   pm.Service_Request__c != null && caseIdVsBookingPM.containsKey(pm.Service_Request__c)){
                       pm.Revised_Planned_Handover_Date_ISOB_IDD__c = caseIdVsBookingPM.get(pm.Service_Request__c).Planned_Handover_Date_ISOB_IDD__c;
                       executionMilestoneToUpdate.add(pm);
                }
            /*} else {//Validation would be controlled by FLS
                //Update ::validate for edit permission for Ho Project Persona User
                if(pm.RecordTypeId == executionRTId && oldMilestoneMap.containsKey(pm.Id) && !isHoProjectPersona && 
                   pm.Revised_Planned_Handover_Date_ISOB_IDD__c != oldMilestoneMap.get(pm.Id).Revised_Planned_Handover_Date_ISOB_IDD__c){
                    //show error
                    pm.Revised_Planned_Handover_Date_ISOB_IDD__c.addError(system.label.Project_Milestone_plan_handover_date_edit_error_message);
                }
            }*/
            
        }
        
        
        
        try{
            insert executionMilestoneToUpdate;
        }catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateRevisedPlannedHandoverDate', '', ex);
        }
        
    }
    
    
    public void populateRevisedPlannedHandoverDateOnPlannedHandoverDateChange(list<Project_milestone__c> milestones, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> caseIds = new set<Id>();
        map<Id, Project_milestone__c> caseIdVsBookingPM = new map<Id, Project_milestone__c>();
        map<Id, list<Project_milestone__c>> caseIdVsExecutionPM = new map<Id, list<Project_milestone__c>>();
        List<Project_milestone__c> executionMilestoneToUpdate = new List<Project_milestone__c>();
        
        //fetch RT Ids
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
     
        for(Project_milestone__c pm : milestones){
            if(pm.RecordTypeId == bookingRTId && pm.Planned_Handover_Date_ISOB_IDD__c != null && 
              pm.Service_Request__c != null){
               	caseIds.add(pm.Service_Request__c);
               	caseIdVsBookingPM.put(pm.Service_Request__c, pm);
            }
        }
        
        //Fetch Booking PM details
       for(Project_milestone__c pm : [SELECT Id, Service_Request__c, Revised_Planned_Handover_Date_ISOB_IDD__c
                                      FROM Project_milestone__c 
                                      WHERE Service_Request__c IN : caseIds
                                      AND RecordTypeId =: executionRTId 
                                      AND Revised_Planned_Handover_Date_ISOB_IDD__c = null]){
          if(caseIdVsExecutionPM.containsKey(pm.Service_Request__c)){
              caseIdVsExecutionPM.get(pm.Service_Request__c).add(pm);
          } else {
              caseIdVsExecutionPM.put(pm.Service_Request__c, new list<Project_milestone__c>{pm});
          }
       }
        
        for(Id caseId : caseIdVsBookingPM.keySet()){
            if(caseIdVsExecutionPM.containsKey(caseId) && caseIdVsExecutionPM.get(caseId).size() > 0){
                for(Project_milestone__c exe: caseIdVsExecutionPM.get(caseId)){
                    exe.Revised_Planned_Handover_Date_ISOB_IDD__c = caseIdVsBookingPM.get(caseId).Planned_Handover_Date_ISOB_IDD__c;
                    executionMilestoneToUpdate.add(exe);
                }
            }            
        }
        
        try{
            update executionMilestoneToUpdate;
        }catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateRevisedPlannedHandoverDateOnPlannedHandoverDateChange', '', ex);
        }
        
    }
    
     /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate Installation  Start dates for Execution RT based on the Site verification status
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //installationStartDate -Should be editable only if Site verification date(from site verification record type) is entered
    public void installationStartDateValidation(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> caseIds = new set<Id>();
        map<Id, Project_milestone__c> siteVerificationDateIsNull = new map<Id, Project_milestone__c>();
        Map<Id, List<Project_milestone__c>> caseIdVsSteVerificationMilestones = new Map<Id, List<Project_milestone__c>>();
        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();        
        Id siteVerificationRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Site_Verification_Record_Type).getRecordTypeId();
        
        //fetch parent case records of project milestone with execution RT if start of installation date is changed
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null &&
                newMilestoneMap.get(pmId).Start_Date__c	 != oldMilestoneMap.get(pmId).Start_Date__c	){
                   caseIds.add(newMilestoneMap.get(pmId).Service_Request__c);
             }           
        }
        
        
        //fetch project milestones records of site verification RT with Site verification date is blank
        for(Project_milestone__c pm : [SELECT Id, Service_Request__c, Phase__c FROM Project_milestone__c 
                                      WHERE Service_Request__c IN : caseIds
                                      AND RecordTypeId =: siteVerificationRTId 
                                      AND Site_Verification_Done_On__c = null]){
        	if(caseIdVsSteVerificationMilestones.containsKey(pm.Service_Request__c)){
                   caseIdVsSteVerificationMilestones.get(pm.Service_Request__c).add(pm);
               } else{
                   caseIdVsSteVerificationMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
               }   
                                          
                                         
       }
            
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null && newMilestoneMap.get(pmId).Start_Date__c != oldMilestoneMap.get(pmId).Start_Date__c){
                   
                    Id caseId = newMilestoneMap.get(pmId).Service_Request__c;
                    
                    if(caseIdVsSteVerificationMilestones.containsKey(caseId) && caseIdVsSteVerificationMilestones.get(caseId).size()>0){
                        for(Project_milestone__c pm : caseIdVsSteVerificationMilestones.get(caseId)){
                            if(pm.Phase__c == newMilestoneMap.get(pmId).Phase__c){
                                newMilestoneMap.get(pmId).Start_Date__c.addError(system.label.Project_Milestone_Installation_Start_date_Error);
                            }                            
                        }
                    }    
               }
        }
        
        
        
        /*
        //fetch project milestones records of site verification RT with Site verification date is blank
        for(Project_milestone__c pm : [SELECT Id, Service_Request__c FROM Project_milestone__c 
                                      WHERE Service_Request__c IN : caseIds
                                      AND RecordTypeId =: siteVerificationRTId 
                                      AND Site_Verification_Done_On__c = null]){
          siteVerificationDateIsNull.put(pm.Service_Request__c, pm);                                
       }
        
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null &&
                newMilestoneMap.get(pmId).Start_Date__c	 != oldMilestoneMap.get(pmId).Start_Date__c	 && 
                siteVerificationDateIsNull.containsKey(newMilestoneMap.get(pmId).Service_Request__c)){
                newMilestoneMap.get(pmId).Start_Date__c.addError(system.label.Project_Milestone_Installation_Start_date_Error);
            }
        }*/
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate CC Dates for Final Commissioning & Hand over RT based on the End of installation date
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //CC Date Should be editable only if End of installation date(Execution) is entered

    public void ccDateValidation(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        
       // map<Id, Project_milestone__c> finalCommMilestone = new map<Id, Project_milestone__c>();
        Map<Id, List<Project_milestone__c>> caseIdVsfinalCommMilestones = new Map<Id, List<Project_milestone__c>>();
        Map<Id, List<Project_milestone__c>> caseIdVsExecutionMilestones = new Map<Id, List<Project_milestone__c>>();
        
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        //fetch parent case records of project milestone with Final Commissioning & Hand over RT if CC_Date__c is changed
        for(Project_milestone__c pm : newMilestoneMap.values()){
            if(oldMilestoneMap.containsKey(pm.Id) && pm.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	pm.Service_Request__c != null &&
                oldMilestoneMap.get(pm.Id).CC_Date__c != pm.CC_Date__c ){
                    if(caseIdVsfinalCommMilestones.containsKey(pm.Service_Request__c)){
               			caseIdVsfinalCommMilestones.get(pm.Service_Request__c).add(pm);
                   } else {
                       caseIdVsfinalCommMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
                   }
            }
        } 
        
        
        //fetch project milestones records of execution RT with End of Installation date is blank
        if(caseIdVsfinalCommMilestones.keyset().size() > 0){
            for(Project_milestone__c pm : [SELECT Id, Service_Request__c,Phase__c FROM Project_milestone__c 
                                          WHERE Service_Request__c IN : caseIdVsfinalCommMilestones.keyset() 
                                          AND RecordTypeId =: executionRTId 
                                          AND End_Date__c = null]){
                                              
               if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
                   caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
               } else{
                   caseIdVsExecutionMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
               }                                                                             
            }
        }
            
        
        	//Phase should be same for execution and final comm. records
            for(Id caseId : caseIdVsfinalCommMilestones.keySet()){
                for(Project_milestone__c comm : caseIdVsfinalCommMilestones.get(caseId)){
                    if(caseIdVsExecutionMilestones.containsKey(caseId) && caseIdVsExecutionMilestones.get(caseId).size() > 0){
                        for(Project_milestone__c exe : caseIdVsExecutionMilestones.get(caseId)){
                            if(comm.Phase__c == exe.Phase__c){
                                comm.CC_Date__c.addError(system.label.Project_Milestone_CC_Date_error_message);
                            }
                        }
                  	}
                }
            }        
	 	}
    
   
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to update updateIsBookingPlannedHandoverDateModified Flag
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //Reason for Handover date Change(Execution2) Should be editable only for HO projects team and only if Planned handover date(Booking) is modified.

    public void updateIsBookingPlannedHandoverDateModifiedFlag(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        
        //fetch RT Ids
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();

        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == bookingRTId 
               	&& oldMilestoneMap.get(pmId).Planned_Handover_Date_ISOB_IDD__c != newMilestoneMap.get(pmId).Planned_Handover_Date_ISOB_IDD__c){
                   newMilestoneMap.get(pmId).isBooking_Planned_handover_date_modified__c = true;
            }
        }
                
    }

	/*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate reasonForHandoverDateChange 
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //Reason for Handover date Change(Execution2) Should be editable only for HO projects team and only if Planned handover date(Booking) is modified.

    public void reasonForHandoverDateChangeValidation(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> caseIds = new set<Id>();
        map<Id, Project_milestone__c> caseIdVsBookingPM = new map<Id, Project_milestone__c>();
        
        //fetch RT Ids
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();
        
        /*
        //Fetch Admin Profile Id
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1].Id;
        
        //Fetch Current User details
        User currentUser = [SELECT Id, Persona__c, profileId FROM User WHERE Id =: UserInfo.getUSerId() Limit 1];
        Boolean isHoProjectPersona = ((String.isNotBlank(currentUser.Persona__c) && currentUser.Persona__c == GlobalConstants.PROJECT_MILESTONE_HO_PROJECT_PERSONA) 
                                      	|| Id.valueOf(currentUser.profileId) == systemAdminProfileId) ? true : false;
        
		*/	
        
        //fetch parent case records of project milestone with execution RT
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               oldMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c != newMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c &&
               newMilestoneMap.get(pmId).Service_Request__c != null){
                   caseIds.add(newMilestoneMap.get(pmId).Service_Request__c);
               }           
        }
        
        if(caseIds.size() > 0){
            //Fetch Booking RT record
            for(Project_milestone__c bookingPm : [SELECT Id, Service_Request__c FROM Project_milestone__c 
                                                    WHERE Service_Request__c IN : caseIds AND RecordTypeId =: bookingRTId 
                                                    AND isBooking_Planned_handover_date_modified__c = true]){
                caseIdVsBookingPM.put(bookingPm.Service_Request__c, bookingPm);                                    
            }
        }
        
        for(Id pmId : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId 
               && newMilestoneMap.get(pmId).Service_Request__c != null 
               && oldMilestoneMap.get(pmId).Service_Request__c == newMilestoneMap.get(pmId).Service_Request__c){
                                 
               if(!caseIdVsBookingPM.containskey(oldMilestoneMap.get(pmId).Service_Request__c) && 
                  	oldMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c != newMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c){
                        newMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c.addError('Reason for Handover date Change can be modified only when Planned hand over date is modified');
                    }
                   else if(oldMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c != newMilestoneMap.get(pmId).Reason_for_Handover_Date_Change__c){
                       caseIdVsBookingPM.get(newMilestoneMap.get(pmId).Service_Request__c).isBooking_Planned_handover_date_modified__c = false;
                   }
        	}
        }
        
        try{
            if(caseIdVsBookingPM.size() > 0){
                update caseIdVsBookingPM.values();
            }
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'reasonForHandoverDateChangeValidation', '', ex);
        }
                
    }        
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   To populate Installation Pending reason and Project Active / Completed 
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //Update Installation_Pending_reason__c to 'Not Applicable and Project_Active_Completed__c to 'Completed' when CC Date(Final Commissioning&Hand over) date is entered
   //*Installation_Pending_reason__c = 'Not Applicable'
    
    public void populateExecutionFields(Map<Id, Project_milestone__c> newMilestoneMap){
        Set<Id> caseIds = new set<Id>();
        list<Project_milestone__c> exMilestones = new list<Project_milestone__c>();
        Map<Id, List<Project_milestone__c>> caseIdVsExecutionMilestones = new Map<Id, List<Project_milestone__c>>();
        list<Project_milestone__c> milestones = new list<Project_milestone__c>();
        
        //Fetch RT ids
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        
        //fetch parent case records of project milestone with final commission RT
        for(Id pmId : newMilestoneMap.keySet()){
            if(newMilestoneMap.get(pmId).RecordTypeId == finalCommissioningAndHandOverRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null && 
              	newMilestoneMap.get(pmId).CC_Date__c != null){
                   caseIds.add(newMilestoneMap.get(pmId).Service_Request__c);
             }           
        }
        
        if(caseIds.size() > 0){
            for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c from Project_milestone__c
                                          WHERE Service_Request__c IN : caseIds
                                           AND RecordTypeId =: executionRTId ]){
               if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
                   caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
               } else{
                   caseIdVsExecutionMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
               } 
            }
        }
        
        for(Id pmId : newMilestoneMap.keySet()){
            if(newMilestoneMap.get(pmId).RecordTypeId == finalCommissioningAndHandOverRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null && newMilestoneMap.get(pmId).CC_Date__c != null){
                    
                    Id caseId = newMilestoneMap.get(pmId).Service_Request__c;
                    
                    if(caseIdVsExecutionMilestones.containsKey(caseId) && caseIdVsExecutionMilestones.get(caseId).size()>0){
                        for(Project_milestone__c pm : caseIdVsExecutionMilestones.get(caseId)){
                            if(pm.Phase__c == newMilestoneMap.get(pmId).Phase__c){
                                if (Schema.sObjectType.Project_milestone__c.fields.Installation_Pending_reason__c.isUpdateable()){ 
                                   pm.Installation_Pending_reason__c = 'Not Applicable';
                                 }
                                milestones.add(pm);
                            }                            
                        }
                    }                   
               }            
        }
        
        try{
            update milestones;
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateExecutionFields', '', ex);
        }
                
    }
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to round off Percentage of work completed to the nearest multiple of 5.
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    public void roundOffToMultipleOfFive(Map<Id, Project_milestone__c> newMilestoneMap ){
        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        for(Id pmId : newMilestoneMap.keySet()){
            if(newMilestoneMap.get(pmId).RecordTypeId == executionRTId && newMilestoneMap.get(pmId).Percentage_of_Work_Complete__c != null ){
                    newMilestoneMap.get(pmId).Percentage_of_Work_Complete__c = Math.round(newMilestoneMap.get(pmId).Percentage_of_Work_Complete__c / 5) * 5;                    
             }           
        }
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to validate projectCompletionValidation 
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    // If any of the status of Design, booking, supply,  installation and site verification status is not marked as complete,
    // then the project status(Execution) should not get updated to completed
    
    public void projectCompletionValidation(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        Set<Id> caseRecordIds = new set<Id>();
        Map<Id, Case> caseIdVsCaseRec = new map<Id, Case>();
        Map<Id, List<Project_milestone__c>> caseIdVsMilestones = new map<Id, List<Project_milestone__c>>();
        
        for(Id pmID : newMilestoneMap.keySet()){
            if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null &&
                oldMilestoneMap.get(pmId).Project_Active_Completed__c != 'Completed' && newMilestoneMap.get(pmId).Project_Active_Completed__c == 'Completed'){
                    caseRecordIds.add(newMilestoneMap.get(pmId).Service_Request__c);   
            }
        }
        
        if(caseRecordIds.size() > 0){
            for(Project_milestone__c milestone : [SELECT Id, Service_Request__c, RecordTypeId, Status__c, Project_Active_Completed__c 
                                                                FROM Project_milestone__c 
                                                                WHERE Service_Request__c IN :caseRecordIds ]){
                if(caseIdVsMilestones.containsKey(milestone.Service_Request__c)){
                    caseIdVsMilestones.get(milestone.Service_Request__c).add(milestone);
                } else {
                    caseIdVsMilestones.put(milestone.Service_Request__c, new List<Project_milestone__c>{milestone});
                }
            }
       }
       
       for(Id pmID : newMilestoneMap.keySet()){
           if(oldMilestoneMap.containsKey(pmId) && newMilestoneMap.get(pmId).RecordTypeId == executionRTId && 
               	newMilestoneMap.get(pmId).Service_Request__c != null &&
                oldMilestoneMap.get(pmId).Project_Active_Completed__c != 'Completed' && newMilestoneMap.get(pmId).Project_Active_Completed__c == 'Completed'){
             
                Id caseId = newMilestoneMap.get(pmId).Service_Request__c;
                Boolean isMilestoneOpen = false;

                if(caseIdVsMilestones.containsKey(caseId) && caseIdVsMilestones.get(caseId).size() > 0){
                    for(Project_milestone__c projectMilestone : caseIdVsMilestones.get(caseId)){
                        if((projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId() 
                            || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId() 
                            || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId() 
                            //|| projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_Record_Type).getRecordTypeId() 
                            //|| projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId() 
                            || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Supply_and_Material_Pull_Plan_Record_Type).getRecordTypeId()) 
                                && projectMilestone.Status__c != 'Completed'){
    
                            isMilestoneOpen = true;
                            break;
                        }
    
                        //Status check for Site_Verification RT
                        if(projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Site_Verification_Record_Type).getRecordTypeId()
                            && projectMilestone.Status__c != 'Completed'){
                          isMilestoneOpen = true;
                          break;
                        }
                         
                    }
                }
                    
                if(isMilestoneOpen){
                	newMilestoneMap.get(pmId).Project_Active_Completed__c.addError(System.label.Project_milestone_Project_cannot_be_completed_error_message); 
                }
            }
       	}
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to update CC status 
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //populate CC status to 'Awaiting' if End of installation date(Execution) is entered
    
    public void ccStatusUpdate(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        //Fetch RT ids
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();  
        
        Map<Id, list<Project_milestone__c>> caseIdVsExecutionMilestones = new map<Id, list<Project_milestone__c>>();
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestones = new map<Id, list<Project_milestone__c>>();
        list<Project_milestone__c> finalCommMilestonesToUpdate = new list<Project_milestone__c>();
        
        //get parent cases for execution RT
        for(Project_milestone__c pm : newMilestoneMap.values()){
            if(oldMilestoneMap.containsKey(pm.Id) && pm.RecordTypeId == executionRTId && 
               	pm.Service_Request__c != null &&
                oldMilestoneMap.get(pm.Id).End_Date__c == null && pm.End_Date__c != null){
                    if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
               			caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
                   } else {
                       caseIdVsExecutionMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
                   }
            }
        }        
        //get project milestones with final commissioning and handover RT
        for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c,Status__c from Project_milestone__c
                                      WHERE Service_Request__c IN : caseIdVsExecutionMilestones.keyset() 
                                       AND RecordTypeId =: finalCommissioningAndHandOverRTId ]){
           if(caseIdVsFinalCommMilestones.containsKey(pm.Service_Request__c)){
               caseIdVsFinalCommMilestones.get(pm.Service_Request__c).add(pm);
           } else {
               caseIdVsFinalCommMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
           }                                
        }
        
        
        for(Id caseId : caseIdVsExecutionMilestones.keyset()){
            for(Project_milestone__c exe : caseIdVsExecutionMilestones.get(caseId)){
                if(caseIdVsFinalCommMilestones.containsKey(exe.Service_Request__c) && 
                                caseIdVsFinalCommMilestones.get(exe.Service_Request__c).size() > 0){
                    for(Project_milestone__c comm : caseIdVsFinalCommMilestones.get(exe.Service_Request__c)){
                        if(exe.Phase__c == comm.Phase__c){
                            if (Schema.sObjectType.Project_milestone__c.fields.Status__c.isUpdateable()){ 
                                comm.Status__c = 'Awaiting';
                             }
                            finalCommMilestonesToUpdate.add(comm);
                        }
                    }
                }       
            }       
        }
        try{
            update finalCommMilestonesToUpdate;
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'updateCCStatus', '', ex);
        }
    }
    
    public void updateCCStatus(List<Project_milestone__c> newMilestones){
        //Fetch RT ids
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();  
        
        Map<Id, list<Project_milestone__c>> caseIdVsExecutionMilestones = new map<Id, list<Project_milestone__c>>();
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestones = new map<Id, list<Project_milestone__c>>();
        
        //get parent cases for final commissioning RT
        for(Project_milestone__c pm : newMilestones){
            if(pm.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	pm.Service_Request__c != null && pm.Status__c != 'Awaiting' && pm.CC_Date__c == null){
                    if(caseIdVsFinalCommMilestones.containsKey(pm.Service_Request__c)){
               			caseIdVsFinalCommMilestones.get(pm.Service_Request__c).add(pm);
                   } else {
                       caseIdVsFinalCommMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
                   }
            }
        }
        
        //get project milestones with execution RT
        for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c,End_Date__c from Project_milestone__c
                                       WHERE Service_Request__c IN : caseIdVsFinalCommMilestones.keyset() 
                                       AND RecordTypeId =: executionRTId 
                                       AND End_Date__c != null]){
           if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
               caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
           } else {
               caseIdVsExecutionMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
           }                                
        }
        
        for(Id caseId : caseIdVsExecutionMilestones.keyset()){
            for(Project_milestone__c exe : caseIdVsExecutionMilestones.get(caseId)){
                if(caseIdVsFinalCommMilestones.containsKey(exe.Service_Request__c) && caseIdVsFinalCommMilestones.get(exe.Service_Request__c).size() > 0){
                    for(Project_milestone__c comm : caseIdVsFinalCommMilestones.get(exe.Service_Request__c)){
                        if(exe.Phase__c == comm.Phase__c){
                            
                            comm.Status__c = 'Awaiting';
                        }
                    }
                }       
            }       
        }
        
        
        
        
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to populate OTIF details field 
    Inputs:        maps of updated project Milestone records
    
    History
    16-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //populate OTIF details field 
    
    public void populateOTIFDetails(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        //Fetch RT ids
        Id execution2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();  
        
        Map<Id, list<Project_milestone__c>> caseIdVsExecutionMilestones = new map<Id, list<Project_milestone__c>>();
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestones = new map<Id, list<Project_milestone__c>>();
        list<Project_milestone__c> finalCommMilestones = new list<Project_milestone__c>();
        
        //get parent cases for execution records
        for(Project_milestone__c pm : newMilestoneMap.values()){
            if(oldMilestoneMap.containsKey(pm.Id) && pm.RecordTypeId == execution2RTId && 
               	pm.Service_Request__c != null &&
                oldMilestoneMap.get(pm.Id).Revised_Planned_Handover_Date_ISOB_IDD__c != pm.Revised_Planned_Handover_Date_ISOB_IDD__c){
                    if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
                        caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
                    } else{
                        caseIdVsExecutionMilestones.put(pm.Service_Request__c,new list<Project_milestone__c>{pm});
                    }
            }
        }
        
            //get project milestones with final commissioning and handover RT
            for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c,CC_Date__c from Project_milestone__c
                                           WHERE Service_Request__c IN : caseIdVsExecutionMilestones.keySet() 
                                           AND RecordTypeId =: finalCommissioningAndHandOverRTId ]){
                   if(caseIdVsFinalCommMilestones.containsKey(pm.Service_Request__c)){
                       caseIdVsFinalCommMilestones.get(pm.Service_Request__c).add(pm);
                   } else{
                       caseIdVsFinalCommMilestones.put(pm.Service_Request__c,new list<Project_milestone__c>{pm});
                   }
             }
        
        	for(Id caseId : caseIdVsExecutionMilestones.keySet()){
                if(caseIdVsFinalCommMilestones.containsKey(caseId) && caseIdVsFinalCommMilestones.get(caseId).size() > 0){
                    for(Project_milestone__c exe : caseIdVsExecutionMilestones.get(caseId)){
                        for(Project_milestone__c comm : caseIdVsFinalCommMilestones.get(caseId)){
                            if(comm.Phase__c == exe.Phase__c){
                                if(comm.CC_Date__c > exe.Revised_Planned_Handover_Date_ISOB_IDD__c){
                                     comm.OTIF_details__c = 'OTIF - Delayed';                                    
                                    Integer num =  exe.Revised_Planned_Handover_Date_ISOB_IDD__c.daysBetween(comm.CC_Date__c);
                                    if(num < = 7){
                                        comm.OTIF_Delayed_By__c = '1 Week';
                                    }
                                    else if(num > = 8 && num < = 14){
                                        comm.OTIF_Delayed_By__c = '2 Weeks';
                                    }
                                    else{
                                        comm.OTIF_Delayed_By__c = '> 2 Weeks';
                                    }
                                 	finalCommMilestones.add(comm);
                                } else{
                                    //if (Schema.sObjectType.Project_milestone__c.fields.OTIF_details__c.isAccessible() && Schema.sObjectType.Project_milestone__c.fields.OTIF_Delayed_By__c.isAccessible()){ GCP-22
                                     comm.OTIF_details__c = 'OTIF - On Time';
                                    comm.OTIF_Delayed_By__c = '';
                                    //}
                                    finalCommMilestones.add(comm);
                                 }
                            }
                        }
                    }
                }
            }
        
            try{
                update finalCommMilestones;
            } catch(Exception ex){
                Logger.logError('projectMilestoneTriggerHelper', 'populateOTIFDetails', '', ex);
            }    
	}
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to populate OTIF details field 
    Inputs:        maps of updated project Milestone records
    
    History
    16-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //populate OTIF details field 
    
    public void populateOTIFDetailsOnCCDateChange(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        //Fetch RT ids
        Id execution2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();  
        
        Map<Id, list<Project_milestone__c>> caseIdVsExecutionMilestones = new map<Id, list<Project_milestone__c>>();
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestones = new map<Id, list<Project_milestone__c>>();
        list<Project_milestone__c> finalCommMilestones = new list<Project_milestone__c>();
        
        for(Project_milestone__c pm : newMilestoneMap.values()){ 
            if(oldMilestoneMap.containsKey(pm.Id) && pm.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	pm.Service_Request__c != null &&
                oldMilestoneMap.get(pm.Id).CC_Date__c != pm.CC_Date__c){
                    if(caseIdVsFinalCommMilestones.containsKey(pm.Service_Request__c)){
                        caseIdVsFinalCommMilestones.get(pm.Service_Request__c).add(pm);
                    } else{
                        caseIdVsFinalCommMilestones.put(pm.Service_Request__c,new list<Project_milestone__c>{pm});
                    }
            }
        }
        
        //get project milestones with execution RT
        if(caseIdVsFinalCommMilestones.keyset().size() > 0){
            for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c,Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c
                                               WHERE Service_Request__c IN : caseIdVsFinalCommMilestones.keySet() 
                                               AND RecordTypeId =: execution2RTId ]){
                    if(caseIdVsExecutionMilestones.containsKey(pm.Service_Request__c)){
                            caseIdVsExecutionMilestones.get(pm.Service_Request__c).add(pm);
                        } else{
                            caseIdVsExecutionMilestones.put(pm.Service_Request__c,new list<Project_milestone__c>{pm});
                        }
            }
        }
        
        for(Id caseId : caseIdVsFinalCommMilestones.keySet()){
            for(Project_milestone__c comm : caseIdVsFinalCommMilestones.get(caseId)){
               if(caseIdVsExecutionMilestones.containsKey(caseId) && caseIdVsExecutionMilestones.get(caseId).size() > 0){
                   for(Project_milestone__c exe : caseIdVsExecutionMilestones.get(caseId)){
                       if(comm.CC_Date__c > exe.Revised_Planned_Handover_Date_ISOB_IDD__c ){
                           comm.OTIF_details__c = 'OTIF - Delayed';
                           Integer num =  exe.Revised_Planned_Handover_Date_ISOB_IDD__c.daysBetween(comm.CC_Date__c);
                           if(num < = 7){
                               comm.OTIF_Delayed_By__c = '1 Week';
                           }
                           else if(num > = 8 && num < = 14){
                               comm.OTIF_Delayed_By__c = '2 Weeks';
                           }
                           else{
                               comm.OTIF_Delayed_By__c = '> 2 Weeks';
                           }
                       		finalCommMilestones.add(comm);
                       } else{
                           comm.OTIF_details__c = 'OTIF - On Time';
                           comm.OTIF_Delayed_By__c = '';
                           finalCommMilestones.add(comm);
                       }
                   }
            	} 
            }
        }
        
        try{
            update finalCommMilestones;
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateOTIFDetails', '', ex);
        }
        
    }
    
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   To populate Installation Pending reason and Project Active / Completed 
    Inputs:        maps of updated project Milestone records
    
    History
    09-12-2020      Suwarna Rao     Initial Release
    ----------------------------------------------------------------------------*/
    //Update Installation_Pending_reason__c to 'Not Applicable and Project_Active_Completed__c to 'Completed' when CC Date(Final Commissioning&Hand over) date is entered
    //*Project_Active_Completed__c= completed 
    
    public void populateProjectStatus(Map<Id, Project_milestone__c> newMilestoneMap){
        Map<Id, list<Project_milestone__c>> caseIdVsExecutionMilestone = new Map<Id, list<Project_milestone__c>>();
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestone = new Map<Id, list<Project_milestone__c>>();
        list<Project_milestone__c> executionsPMs = new list<Project_milestone__c>();
        
        //Fetch RT ids
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        
        //fetch parent case records of project milestone with commission RT
        for(Project_milestone__c pm : newMilestoneMap.values()){
            if(pm.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	pm.Service_Request__c != null && 
              	pm.CC_Date__c != null){
                    if(caseIdVsFinalCommMilestone.containsKey(pm.Service_Request__c)){
                      caseIdVsFinalCommMilestone.get(pm.Service_Request__c).add(pm);  
                    } else{
                        caseIdVsFinalCommMilestone.put(pm.Service_Request__c, new list<Project_milestone__c>{pm});
                    }
                   
             }           
        }
        
        //Fetch Execution record type detail for cases
        if(caseIdVsFinalCommMilestone.keyset().size() > 0){
            for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c from Project_milestone__c
                                          WHERE Service_Request__c IN : caseIdVsFinalCommMilestone.keyset() 
                                           AND RecordTypeId =: executionRTId ]){
                
                if(caseIdVsExecutionMilestone.containsKey(pm.Service_Request__c)){
                    caseIdVsExecutionMilestone.get(pm.Service_Request__c).add(pm);  
                } else {
                    caseIdVsExecutionMilestone.put(pm.Service_Request__c, new list<Project_milestone__c>{pm});
                }
            }
        }
        
        for(Id caseId : caseIdVsFinalCommMilestone.keySet()){
            for(Project_milestone__c comm : caseIdVsFinalCommMilestone.get(caseId)){
                for(Project_milestone__c exe : caseIdVsExecutionMilestone.get(caseId)){
                    if(comm.Phase__c == exe.Phase__c){
                        //if (Schema.sObjectType.Project_milestone__c.fields.Project_Active_Completed__c.isUpdateable()){ GCP-22
                        exe.Project_Active_Completed__c = 'Completed' ; 
                   // }
                        executionsPMs.add(exe);
                    }
                }
            }
            
        }
        
        
        try{
            update executionsPMs;
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'populateExecutionFields', '', ex);
        }
                
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to update status to 'Completed' if End date(Booking) is entered
					OR viceversa
    Inputs:        maps of updated project Milestone records
    
    History
    05-01-2021      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateFieldValues(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> recordTypeIds = new set<Id>();
        //Fetch RT ids
        Id supplyRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Supply_and_Material_Pull_Plan_Record_Type).getRecordTypeId();
        Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId(); 
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
                           
        recordTypeIds.add(supplyRTId);
        recordTypeIds.add(booking2RTId);
        recordTypeIds.add(executionRTId);
        recordTypeIds.add(designRTId);
        
        Map<Id, list<Project_milestone__c>> caseIdVsFinalCommMilestones = new map<Id, list<Project_milestone__c>>();
        
        //get project milestones with final commissioning and handover RT
        for(Project_milestone__c pm : [SELECT Id,Service_Request__c,Phase__c,CC_Date__c from Project_milestone__c
                                      WHERE RecordTypeId =: finalCommissioningAndHandOverRTId 
                                      AND CC_Date__c != null]){
           if(caseIdVsFinalCommMilestones.containsKey(pm.Service_Request__c)){
               caseIdVsFinalCommMilestones.get(pm.Service_Request__c).add(pm);
           } else {
               caseIdVsFinalCommMilestones.put(pm.Service_Request__c, new List<Project_milestone__c>{pm});
           }                                
        }
        
        
        
        for(Project_milestone__c newPM : newMilestoneMap.values()){
            
            //Logic to update Status for Final Commissioning RT
            if(newPM.recordTypeId == finalCommissioningAndHandOverRTId && newPM.CC_Date__c != null 
               && newPM.Status__c != 'Received'){
                   newPM.Status__c = 'Received';
            }
            
            if(recordTypeIds.contains(newPM.recordTypeId)){
                //Update Status to Complete
                if(newPM.End_Date__c != null && newPM.Status__c != 'Completed'){
                	newPM.Status__c = 'Completed';
                }
                
                //Logic to update status for popualated Start Date but blank End date
                /*if(newPM.End_Date__c == null && newPM.Start_Date__c != null && newPM.Status__c != 'Work in progress'){
                	newPM.Status__c = 'Work in progress';
                }*/
                
                //Logic to update End date for Completed status
                if(newPM.End_Date__c == null && newPM.Status__c == 'Completed'){
                	newPM.End_Date__c = System.today();
                }
                
                //Logic to update Installation Pending Reason for Execution RT
                if(newPM.recordTypeId == executionRTId && newPM.End_Date__c != null){
                    //Update Completion Status
                    if(newPM.Percentage_of_Work_Complete__c != 100)
                    		newPM.Percentage_of_Work_Complete__c = 100;
                    
                    if(newPM.Service_Request__c != null && newPM.Installation_Pending_reason__c != 'CC Awaited'
                      && caseIdVsFinalCommMilestones.containsKey(newPM.Service_Request__c)){
                            for(Project_milestone__c pm : caseIdVsFinalCommMilestones.get(newPM.Service_Request__c)){
                                if(pm.Phase__c == newPM.Phase__c && pm.CC_Date__c == null){
                                    newPM.Installation_Pending_reason__c = 'CC Awaited';
                                }
                            }
                    }else{
                        newPM.Installation_Pending_reason__c = 'CC Awaited';
                    }
              	}
            } 
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   Helper method to validate SO/ FOC Number field 
    
    Inputs:        map of updated PM records
    
    History
    12-01-2021      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateData(list<Project_milestone__c> newMilestones){
        
        String regex = '[a-zA-Z]{3}[0-9]{6}';
        Pattern patternStr = Pattern.compile(regex);

		//Logic to validate string
		for(Project_milestone__c pm : newMilestones){
			Boolean isMatchFound = true;

			//validate FOC Number string
			if(String.isNotEmpty(pm.FOC_Number__c)){
				for(String focStr : pm.FOC_Number__c.split(',')){
					Matcher matcherStr = patternStr.matcher(focStr.trim());
        			isMatchFound = matcherStr.matches(); 
                    if(!isMatchFound)
                        break;
				}
			}

			//validate SO Number string
			if(String.isNotEmpty(pm.SO_Number__c)){
				for(String soStr : pm.SO_Number__c.split(',')){
					Matcher matcherStr = patternStr.matcher(soStr.trim());
        			isMatchFound = matcherStr.matches(); 
                    
                    if(!isMatchFound)
                        break;
				}
			}

			//didn't Match
            if(!isMatchFound){
            	pm.addError('Please enter valid FOC/SO Number. First 3 characters should be text, remaining 6 should be numbers'); 
            }
		}
    }

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to update Start Date & End Date on Supply RT 
				depending on Booking SO Number

    Inputs:        maps of updated project Milestone records
    
    History
    22-01-2021      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateAndUpdateSupplyFieldValues(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
    	set<String> orderNumbers = new set<String>();
        map<Id, list<String>> caseIdVsSONumbers = new map<Id, list<String>>();
        map<Id, Case> serviceReqMap = new map<Id, Case>();
        map<Id, Project_milestone__c> milestonesToUpdate = new map<Id, Project_milestone__c>();
        Map<String, List<Receivable__c>> orderNoVsReceivable = new Map<String, List<Receivable__c>>();
        map<Id, Decimal> caseIdVscumulativeAmount = new map<Id, Decimal>();
        
        //Fetch RT
        Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
        Id supplyRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Supply_and_Material_Pull_Plan_Record_Type).getRecordTypeId();
        
        
        //logic to check SO Number field value change
        for(Project_milestone__c milestone : newMilestoneMap.values()){
            if(milestone.RecordTypeId == booking2RTId && oldMilestoneMap.containsKey(milestone.id) && 
              	String.isNotBlank(milestone.SO_Number__c) && milestone.Service_Request__c != null && 
                milestone.SO_Number__c != oldMilestoneMap.get(milestone.id).SO_Number__c) {
                //trim 'SO Numbers' 
                list<String> soNumbers =  milestone.SO_Number__c.remove(' ').split(','); 
                orderNumbers.addAll(soNumbers);    
                caseIdVsSONumbers.put(milestone.Service_Request__c, soNumbers);
            }
        }
        
        //Fetch Case Details to validate
        if(!caseIdVsSONumbers.isEmpty())
        	serviceReqMap = new map<Id, Case>([SELECT Id, (SELECT Id, End_Date__c, Start_Date__c FROM Project_Milestones__r 
                                                           WHERE RecordTypeId =: supplyRTId), SO_Order_Amount__c 
                                               FROM Case WHERE Id IN: caseIdVsSONumbers.keyset()]);
        
        //Fetch Line Item details
        if(orderNumbers.size() > 0) {
            List<Receivable__c> tempReceivableRecords;
            for(Receivable__c recv : [SELECT Net_Billed_Sales__c, Document_Date__c, Order__c   
                                        FROM Receivable__c
                                        WHERE Order__c IN : orderNumbers]
            ) {
                tempReceivableRecords = new List<Receivable__c>();
                if(orderNoVsReceivable.containsKey(recv.Order__c)) {
                    tempReceivableRecords.addAll(orderNoVsReceivable.get(recv.Order__c));
                }
                tempReceivableRecords.add(recv);
                orderNoVsReceivable.put(recv.Order__c, tempReceivableRecords);
            }
            
            //get Cumulative amount against the Case
            if(!orderNoVsReceivable.isEmpty() && !caseIdVsSONumbers.isEmpty()){
                for(Id caseId : caseIdVsSONumbers.keyset()){
                    Decimal totalAmount = 0;
                    for(String soNum : caseIdVsSONumbers.get(caseId)){
                        totalAmount += orderNoVsReceivable.containsKey(soNum) ? getTotalAmountForReceivablesForCommonOrderNo(orderNoVsReceivable.get(soNum)) : 0;
                    }
                    
                    caseIdVscumulativeAmount.put(caseId, totalAmount);
                }
            }
        }
        
        //Business Logic
        for(Project_milestone__c milestone : newMilestoneMap.values()){
            if(milestone.RecordTypeId == booking2RTId && oldMilestoneMap.containsKey(milestone.id) && 
              	String.isNotBlank(milestone.SO_Number__c) && milestone.Service_Request__c != null && 
                milestone.SO_Number__c != oldMilestoneMap.get(milestone.id).SO_Number__c && 
              	caseIdVsSONumbers.containsKey(milestone.Service_Request__c) && 
              	serviceReqMap.containsKey(milestone.Service_Request__c)){
                    
                String firstOrderNumber =  caseIdVsSONumbers.get(milestone.Service_Request__c)[0];
                String lastOrderNumber =  caseIdVsSONumbers.get(milestone.Service_Request__c)[(caseIdVsSONumbers.get(milestone.Service_Request__c).size())-1];
                Decimal difference = 0;
                if(caseIdVscumulativeAmount.containsKey(milestone.Service_Request__c)) {
                    difference = (caseIdVscumulativeAmount.get(milestone.Service_Request__c) - serviceReqMap.get(milestone.Service_Request__c).SO_Order_Amount__c);
                }
                  
                if(caseIdVscumulativeAmount.containsKey(milestone.Service_Request__c) && 
                    (caseIdVscumulativeAmount.get(milestone.Service_Request__c)) > (serviceReqMap.get(milestone.Service_Request__c).SO_Order_Amount__c + Decimal.valueOf(system.label.SSG_SO_amount_Buffer))){
                        milestone.addError(system.label.SR_Net_amount_exceeding_error);
                }
                
                //Populate End Date logic
                else if(caseIdVscumulativeAmount.containsKey(milestone.Service_Request__c) && 
                    Math.sqrt(difference*difference) <= Decimal.valueOf(System.label.SSG_SO_amount_Buffer)) {
                        (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].End_Date__c = getAppropriateReceivableDocumentDate(orderNoVsReceivable.get(lastOrderNumber), true);
                        
                        //Start Date is also blank populate it with Document date
                        if((serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Start_Date__c == null){
                            (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Start_Date__c = getAppropriateReceivableDocumentDate(orderNoVsReceivable.get(firstOrderNumber), false);
                        }
                        
                    milestonesToUpdate.put((serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Id, (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0]);   
                } 
                //Populate Start Date logic
                else if(orderNoVsReceivable.containsKey(firstOrderNumber) && 
                    (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Start_Date__c == null) {
                        (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Start_Date__c = getAppropriateReceivableDocumentDate(orderNoVsReceivable.get(firstOrderNumber), false);
                        milestonesToUpdate.put((serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0].Id, (serviceReqMap.get(milestone.Service_Request__c).Project_Milestones__r)[0]);   
                }
            }
        }
        
        //Update Supply Milestones 
        try{
            if(milestonesToUpdate.size() > 0)
                update milestonesToUpdate.values();
        } catch(Exception ex){
            Logger.logError('projectMilestoneTriggerHelper', 'validateAndUpdateSupplyFieldValues', '', ex);
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the total Net Billed Sales for receivables that share a common Order No.
    Inputs:        List of Receivable records
    Output:        Decimal totalNetBilledSales
    History
    08-02-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    private Decimal getTotalAmountForReceivablesForCommonOrderNo(List<Receivable__c> receivableRecords) {
        Decimal totalNetBilledSales = 0;
        for(Receivable__c receivableRecord : receivableRecords) {
            totalNetBilledSales += receivableRecord.Net_Billed_Sales__c;
        }
        return totalNetBilledSales;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get appropriate Document Date for a list of Receivable records
    Inputs:        List of Receivable records, Boolean GET_MOST_RECENT_DATE
    Output:        Date documentDate
    History
    08-02-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    private Date getAppropriateReceivableDocumentDate(List<Receivable__c> receivableRecords, Boolean GET_MOST_RECENT_DATE) {
        Date mostRecentDate;
        if(receivableRecords.size() > 0) {
            mostRecentDate = receivableRecords[0].Document_Date__c;
            if(GET_MOST_RECENT_DATE) {
                for(Receivable__c receivableRecord: receivableRecords) {
                    if(mostRecentDate < receivableRecord.Document_Date__c) {
                        mostRecentDate = receivableRecord.Document_Date__c;
                    }
                }
            } else {
                for(Receivable__c receivableRecord: receivableRecords) {
                    if(mostRecentDate > receivableRecord.Document_Date__c) {
                        mostRecentDate = receivableRecord.Document_Date__c;
                    }
                }
            }
            System.debug('mostRecentDate: ' + mostRecentDate);
        }
        return mostRecentDate;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to validate CC date with Related Files for Final Commissioning RT

    Inputs:        maps of updated project Milestone records
    
    History
    25-01-2021      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateCCDateUpdate(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap){
        set<Id> pmIds = new set<Id>();
        set<Id> milestoneHavingFileAttached = new set<Id>();
        
        //Fetch RT ids
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId(); 
        
        //logic to check CC-Date field value change
        for(Project_milestone__c milestone : newMilestoneMap.values()){
            if(milestone.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	oldMilestoneMap.containsKey(milestone.id) && 
                milestone.CC_Date__c != oldMilestoneMap.get(milestone.id).CC_Date__c){
                pmIds.add(milestone.Id);
            }
        }
        
        if(pmIds.size() > 0){
            for(ContentDocumentLink cdLink : [SELECT LinkedEntityId FROM ContentDocumentLink 
                                              						WHERE LinkedEntityId IN : pmIds]){
                milestoneHavingFileAttached.add(cdLink.LinkedEntityId);
            }
        }
        
        //logic to validate
        for(Project_milestone__c milestone : newMilestoneMap.values()){
            if(milestone.RecordTypeId == finalCommissioningAndHandOverRTId && 
               	oldMilestoneMap.containsKey(milestone.id) && 
                milestone.CC_Date__c != oldMilestoneMap.get(milestone.id).CC_Date__c && 
              	!milestoneHavingFileAttached.contains(milestone.id)){
               milestone.CC_Date__c.addError('Please upload CC certificate in Files related list.'); 
            }
        }
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to ensure that Project Milestones dependent on Site Verification completion are not updated.
    Inputs:        maps of updated project Milestone records
    History
    17-02-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateMilestonesThatShouldBeLocked(Map<Id, Project_milestone__c> newMilestoneMap, Map<Id, Project_milestone__c> oldMilestoneMap) {
        String SITE_VERIFICATION_COMPLETED_STATUS = System.Label.SITE_VERIFICATION_COMPLETED_STATUS;
        String SITE_VERIFICATION_RECORDTYPEID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.Label.Site_Verification_PM_Recordtype).getRecordTypeId();
        List<String> recordTypesToBeLocked = (System.Label.Record_Types_to_be_locked_until_site_verification_is_complete).remove(' ').split(',');
        Map<Id, Id> milestonesToConsider = new Map<Id, Id>();

        for(Project_milestone__c projectMilestone : newMilestoneMap.values()) {
            if(recordTypesToBeLocked.contains(recordTypeIdVsRecordTypeName.get(projectMilestone.RecordTypeId))) {
                milestonesToConsider.put(projectMilestone.Id, projectMilestone.Service_Request__c);
            }
        }

        if(!milestonesToConsider.isEmpty()) {
            Set<Id> casesWithCompletedSites = new Set<Id>();
            List<Project_milestone__c> siteVerificationMilestones = [Select Id, Status__c, Service_Request__c FROM Project_milestone__c 
                WHERE RecordTypeId = :SITE_VERIFICATION_RECORDTYPEID AND Status__c = :SITE_VERIFICATION_COMPLETED_STATUS
                AND Service_Request__c IN :milestonesToConsider.values()
            ];

            for(Project_milestone__c siteVerificationMilestone : siteVerificationMilestones) {
                casesWithCompletedSites.add(siteVerificationMilestone.Service_Request__c);
            }

            for(Id mileStoneId : milestonesToConsider.keySet()) {
                if(!casesWithCompletedSites.contains( (newMilestoneMap.get(mileStoneId)).Service_Request__c) ) {
                    (newMilestoneMap.get(mileStoneId)).addError(System.Label.Site_verification_not_complete_error);
                }
            }
        }
    }
    
}