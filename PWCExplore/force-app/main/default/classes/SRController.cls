/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     SRController.cls
Company:       Stetig
Description:   Service Request class(controller) is used get the required data from case object through SOQL
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class SRController{
    
    public Case serviceRequest{get;set;}
    
    public void getDetails() {
       String srId = ApexPages.currentPage().getParameters().get('srId');
        
        serviceRequest = [select Job_Request_Number__c, Date__c, Time__c, Name_of_the_Client__c, Request_given_by__r.Name, ContactPhone, Locations__c, Client_Request__c, Type, Leasing_Case_Category__c,
                            Sub_Category__c, Job_assigned_to__c, Representative__c, Agency__c, Workman__c, Start_Time__c, End_Time__c, Job_Executed__c,
                            Material_Used_if_any__c, Customer_Assessment_Feedback__c, Level_of_Satisfaction__c, Assigned_To__c from Case
                            where id =: srID LIMIT 20000]; 
    
    }
}