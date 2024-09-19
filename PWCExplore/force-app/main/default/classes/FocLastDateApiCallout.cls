/*------------------------------------------------------------------------
    Author:        Anupam Mishra && Shankar Sahu
    Company:       GITL
    Description:   Controller class for FOC Number Lightning components.
    Inputs:        NA
    Test Class:    TestFocLastDateApiCallout
    ----------------------------------------------------------------------------*/
public class FocLastDateApiCallout {
@InvocableMethod
   public static void invokeapexcallout(list<Project_milestone__c> BookingProjectMilestones) {
     GetProjectMilestoneLastDate.callGetLastDate(BookingProjectMilestones[0].id);
     system.debug('booking id'+BookingProjectMilestones[0].id);  
   }
}