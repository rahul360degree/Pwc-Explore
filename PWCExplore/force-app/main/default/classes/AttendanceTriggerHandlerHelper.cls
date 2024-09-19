/*------------------------------------------------------------------------
Company:       Salesforce
Description:   Handler helper class for Attendance Object Trigger
Inputs:        NA
Test Class:    AttendanceTriggerTest
History
13-10-2020     Kshipra Kankariya     Initial Release
----------------------------------------------------------------------------*/
public without sharing class AttendanceTriggerHandlerHelper {   

    public static final User userRec=[select id, managerid, contactid,contact.ReportstoId,persona__c,Business_Unit__c From User Where id =: Userinfo.getUserId()];
    /*
    * This method checks for duplicates and populates approver id.
    * Create trigger on attendance to set "approver" field to created user's contacts reports
    * to if logged in user is D2D, else set it to user's manager
    * Add a validation in the trigger to ensure user cannot save the record if 
    * a record for the logged in user where start date = start date entered is already available
    * Add a regular validation rule to ensure Start & End day have the same day
    * and they're <= TODAY during creation
    */
    public void populateApproverAndCheckForDuplicates(List<Attendance__c> attendanceList) {
        Id approverId;
        Set<Id> ownerIds=new Set<Id>();
        Map<Id,Map<String,Integer>> idVsMonthYearVsMissingAttnRecords=new Map<Id,Map<String,Integer>>();
        Map<String,Attendance__c> compositeKeys = new Map<String,Attendance__c> ();
        String businessUnit;
        Decimal CountOfTime;
        Integer buMissingAttendanceLimit;
        try {
                //check for D2D persona
            if(!isD2DPersona(userRec.persona__c)) {
                    approverId = userRec.managerid;
            }else {
                if(userRec.contact.ReportstoId <> null ) {
                    approverId = [select id from user where contactid =: userRec.contact.ReportstoId limit 1].Id;
                }                
                else
                {
                    //Added On 16-03-2021 for Appliances
                    //Added By Alpana S
                    //if logged in D2D user is reporting to internal user, set approver to user's manager
                   approverId = userRec.managerid; 
                }
            }
            Map<String,String> picklistValueVsLabel=Utility.getPicklistLabels('User','Business_Unit__c');
            businessUnit=picklistValueVsLabel.containsKey(userRec.Business_Unit__c)?picklistValueVsLabel.get(userRec.Business_Unit__c):null;
            for(Attendance__c attendanceRec : attendanceList) {
                if(attendanceRec?.Start_Of_Day__c?.format('ddMMyyyy') == attendanceRec?.End_Of_Day__c?.format('ddMMyyyy')){
                    CountOfTime=decimal.valueof(attendanceRec.End_Of_Day__c.getTime()-attendanceRec.Start_Of_Day__c.getTime());
                    decimal CountOfHour=(CountOfTime/(1000*60*60));
                    if(attendanceRec?.start_of_Day__c?.format('HH:mm a')<=System.label.SwipeIn_at_10_30 && attendanceRec?.End_Of_Day__c?.format('HH:mm a')<=System.label.SwipeOut_at_19_30 &&  CountOfHour> 4.5){
                        attendanceRec.Type__c='Leave';
                        attendanceRec.Sub_Type__c='Second Half';
                    }
                    if( attendanceRec?.start_of_Day__c?.format('HH:mm a')>System.label.SwipeIn_at_10_30 && attendanceRec?.start_of_Day__c?.format('HH:mm a')<=System.label.SwipeIn_at_15_00  &&  attendanceRec?.End_Of_Day__c?.format('HH:mm a')>=System.label.SwipeOut_at_18_30 && CountOfHour> 4.5){
                        attendanceRec.Type__c='Leave';
                        attendanceRec.Sub_Type__c='First Half';
                    }
                    if((attendanceRec?.start_of_Day__c?.format('HH:mm a')>System.label.SwipeIn_at_10_30 && attendanceRec?.End_Of_Day__c?.format('HH:mm a')<System.label.SwipeOut_at_18_30 && CountOfHour < 9) || CountOfHour < 4.5){
                        attendanceRec.Type__c='Leave';
                        attendanceRec.Sub_Type__c='Full Day';
                    }
                     if(attendanceRec?.start_of_Day__c?.format('HH:mm a')<=System.label.SwipeIn_at_10_30 && attendanceRec?.End_Of_Day__c?.format('HH:mm a')>=System.label.SwipeOut_at_18_30  && CountOfHour>=9){
                        attendanceRec.Type__c='Regular';
                        attendanceRec.Sub_Type__c='';
                    }
                }    

                if(attendanceRec.Approval_Status__c==GlobalConstants.DRAFT){
                    //various validations. 
                    if(userRec.Business_Unit__c==GlobalConstants.APPLIANCE_BUSINESS_UNIT && approverId == null && attendanceRec.OwnerId == Userinfo.getUserId() ){
                        attendanceRec.addError(System.Label.Attendance_No_Approver);
                    }
                    if((attendanceRec?.Start_Of_Day__c?.format('ddMMyyyy') <> attendanceRec?.End_Of_Day__c?.format('ddMMyyyy')) 
                        && attendanceRec.Type__c!=GlobalConstants.ATTENDANCE_LOCATION_RESET_REQUEST
                        && attendanceRec.End_Of_Day__c <> null ){
                        attendanceRec.addError(System.Label.Attendance_Same_Start_End);                           
                    }
                    if((attendanceRec?.Start_Of_Day__c?.date() >= System.today() ||attendanceRec?.End_Of_Day__c?.date() >= System.today()) 
                        && attendanceRec.type__c == GlobalConstants.ATT_MISSING_ATTENDANCE) {
                        attendanceRec.addError(System.Label.Attendance_Missed_Future_Date);
                    }
                    if(attendanceRec?.Start_Of_Day__c>= attendanceRec?.End_Of_Day__c){ 
                        attendanceRec.addError(system.label.Attendance_EndOfDayEarlier);
                    } 
                    ownerIds.add(attendanceRec.OwnerId);
                    //set approver
                    if(approverId!=null)
                    attendanceRec.approver__c = approverId;
                    //composite key for identifying duplicates.
                    if(attendanceRec.Start_Of_Day__c!=null){
                        attendanceRec.Attendance_Composite_Key__c = UserInfo.getUserName() + 
                        attendanceRec.Start_Of_Day__c.format('ddMMyyyy');
                    }
                    if((attendanceRec.Attendance_Composite_Key__c!=null && attendanceRec.Type__c!=GlobalConstants.ATT_REGULAR) || (attendanceRec.Attendance_Composite_Key__c!=null && attendanceRec.Type__c==GlobalConstants.ATT_REGULAR && attendanceRec.End_Of_day__c==null))
                    compositeKeys.put(attendanceRec.Attendance_Composite_Key__c,attendanceRec);
                }
            }
    
            for(Attendance__c existingAttendance:[Select Id,Attendance_Composite_Key__c,Type__c,OwnerId,Start_Of_Day__c,CreatedDate,End_Of_Day__c 
                                                    From Attendance__c
                                                    Where OwnerId In :ownerIds
                                                    And Attendance_Composite_Key__c!=null    
                                                    And Type__c In (:GlobalConstants.ATT_MISSING_ATTENDANCE,:GlobalConstants.ATT_LEAVE,:GlobalConstants.ATT_REGULAR) 
                                                    And CreatedDate = LAST_N_DAYS:60 Limit 20000]){
                
                // Shankar Sahu- 18-6-2021 - modified the first if condition to check End_Of_Day__c is not null for otrs #30390471                                       
                // if(compositeKeys.containsKey(existingAttendance.Attendance_Composite_Key__c)                                        
                if(compositeKeys.containsKey(existingAttendance.Attendance_Composite_Key__c) && existingAttendance.End_Of_Day__c !=null)
                    compositeKeys.get(existingAttendance.Attendance_Composite_Key__c).addError(system.label.Attendance_Duplicate_Records);
                if(existingAttendance.Type__c==GlobalConstants.ATT_MISSING_ATTENDANCE && existingAttendance.Start_Of_Day__c!=null){
                    String monthYear=existingAttendance.Start_Of_Day__c.month()+'-'+existingAttendance.Start_Of_Day__c.year();
                    if(!idVsMonthYearVsMissingAttnRecords.containsKey(existingAttendance.OwnerId)){ 
                        Map<String,Integer> monthYearVsRecords=new Map<String,Integer>{monthYear=>1};
                        idVsMonthYearVsMissingAttnRecords.put(existingAttendance.OwnerId,monthYearVsRecords);
                    }
                    else{
                        if(!idVsMonthYearVsMissingAttnRecords.get(existingAttendance.OwnerId).containsKey(monthYear)){
                            idVsMonthYearVsMissingAttnRecords.get(existingAttendance.OwnerId).put(monthYear,1);
                        }
                        else{
                            Integer recCount=idVsMonthYearVsMissingAttnRecords.get(existingAttendance.OwnerId).get(monthYear);
                            idVsMonthYearVsMissingAttnRecords.get(existingAttendance.OwnerId).put(monthYear,recCount+1);
                        }
                    }
                }
            }
            List<Business_Unit_And_Attendance_Limits__mdt> limitRec=[Select Missing_attendance_Limit__c,MasterLabel 
                                                                     From Business_Unit_And_Attendance_Limits__mdt
                                                                     Where MasterLabel =:businessUnit
                                                                     And Missing_attendance_Limit__c!=null Limit 1];
            if(limitRec.size()==1)
            buMissingAttendanceLimit=Integer.ValueOf(limitRec[0].Missing_attendance_Limit__c);
            for(Attendance__c newAttendance : attendanceList){
                if(newAttendance.Type__c==GlobalConstants.ATT_MISSING_ATTENDANCE 
                   && buMissingAttendanceLimit!=null
                   && newAttendance.Start_Of_Day__c!=null){
                    String monthYear=newAttendance.Start_Of_Day__c.month()+'-'+newAttendance.Start_Of_Day__c.year();
                    if(idVsMonthYearVsMissingAttnRecords.containsKey(newAttendance.OwnerId) 
                        && idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).containsKey(monthYear)
                        && idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).get(monthYear)>=buMissingAttendanceLimit){
                            newAttendance.addError(system.label.Attendance_Missing_Requests_Exceeded);
                    }
                    else{
                        if(!idVsMonthYearVsMissingAttnRecords.containsKey(newAttendance.OwnerId)){
                            Map<String,Integer> monthYearVsRecords=new Map<String,Integer>{monthYear=>1};
                            idVsMonthYearVsMissingAttnRecords.put(newAttendance.OwnerId,monthYearVsRecords);
                        }
                        else if(idVsMonthYearVsMissingAttnRecords.containsKey(newAttendance.OwnerId)
                                && !idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).containsKey(monthYear)){
                            idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).put(monthYear,1);
                        }
                        else{
                            Integer recCount=idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).get(monthYear);
                            idVsMonthYearVsMissingAttnRecords.get(newAttendance.OwnerId).put(monthYear,recCount+1);
                        }
                    }
                }
            }
        }
        catch(Exception e) {
            Logger.logError('AttendanceTriggerHandlerHelper', 'populateApproverAndCheckForDuplicates', '', e);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to validate reset user base location personas
    Inputs:        new attendance records
    Test Class:   

    History
    03-11-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/ 
    public void validateBaseLocationResetRequestPersona(List<Attendance__c> attendanceList){
        Set<String> personas=new Set<String>{'Appliances- Self calling executive',
                                             'Appliances- Customer Advisor',
                                             'Appliances- Tele appointment executive - direct sales'};
          for(Attendance__c att:attendanceList){
              if(att.Type__c==GlobalConstants.ATTENDANCE_LOCATION_RESET_REQUEST && !personas.contains(userRec.persona__c)){
                  att.addError(System.Label.Cannot_log_Base_location_reset_request);
              }
          }

    }

    /*
    * Method for checking whether the logged in user's persona is 
    * from D2D external users
    */
    private boolean isD2DPersona(String personaName) {
        List<String> d2dPersonas = new List<String>();
        for(Attendance_Personas__mdt persona : [select Persona_name__c from Attendance_Personas__mdt where D2D__c = true]) {
            d2dPersonas.add(persona.Persona_name__c);
        }
        if(d2dPersonas.contains(personaName)) {
            return true;
        } 
        return false;
    }
    

   /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to reset user base location
                   User story - W-000121 Sprint 2
    Inputs:        map of updated records
    Test Class:   

    History
    03-11-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/ 
    public void resetUserBaseLocation(List<Attendance__c> attendances,Map<Id,Attendance__c> mapOldAttendances){
        Set<Id> userIds=new Set<Id>();
        List<User> userRecordsToUpdate=new List<User>();
        system.debug('attendances=>'+attendances);
         for(Attendance__c attendance:attendances){
             if(attendance.Type__c==GlobalConstants.ATTENDANCE_LOCATION_RESET_REQUEST
                && attendance.Approval_Status__c!=mapOldAttendances.get(attendance.Id).Approval_Status__c
                && attendance.Approval_Status__c==GlobalConstants.APPROVED){
                   userIds.add(attendance.createdById);
                }
         }
         for(User u:[Select Id,Latitude,Longitude From User Where Id in :userIds]){
             if (Schema.sObjectType.User.fields.Latitude.isAccessible() && Schema.sObjectType.User.fields.Longitude.isAccessible()){ 
                 u.Latitude=null;
                 u.Longitude=null;
               }
             userRecordsToUpdate.add(u);
         }
        Update userRecordsToUpdate;
   } 
   
   /*------------------------------------------------------------------------
    Author:        Manasi Londhe
    Company:       Salesforce
    Description:   Method to check duplicate reset location request
    Inputs:        map of updated records
    Test Class:   

    History
    04-11-2020      Manasi Londhe     Initial Release
    ----------------------------------------------------------------------------*/ 
   public void checkDuplicateResetBaseLocationRequest(List<Attendance__c> attendances){
       Id resetLocationRequestRecordType = Schema.SObjectType.Attendance__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BASE_LOCATION_RESET_REQUEST_RECORD_TYPE).getRecordTypeId();
       Set<Id> newOwnerIds=new Set<Id>();
       Set<Id> existingOwnerIds=new Set<Id>();
       for(Attendance__c attendance:attendances){
           if(attendance.RecordTypeId==resetLocationRequestRecordType)
           newOwnerIds.add(attendance.ownerId);
       }
       for(Attendance__c attn:[Select Id,ownerId From Attendance__c 
                                Where ownerId in :newOwnerIds
                                And RecordTypeId=:resetLocationRequestRecordType 
                                And Type__c=:GlobalConstants.ATTENDANCE_LOCATION_RESET_REQUEST
                                And Approval_Status__c=:GlobalConstants.Submitted_for_Approval]){
                                    existingOwnerIds.add(attn.ownerId);
                                }
        for(Attendance__c a:attendances){
             if(existingOwnerIds.contains(a.ownerId))
             a.addError(System.label.Location_Reset_Duplicate_Request);
        }
        
   }
  }