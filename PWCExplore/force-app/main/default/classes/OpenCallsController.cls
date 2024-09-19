/*------------------------------------------------------------------------
Author:        Rahul Yadav
Company:       Salesforce
Description:   This class will be handle the Exception handling and method calling from OpenCallsService for open calls.
Inputs:        NA
Test Class:    OpenCallsControllerTest
History
28-05-2024      Rahul Yadav
----------------------------------------------------------------------------*/
public with sharing class OpenCallsController {
    @AuraEnabled
    public static void fetchOpenCalls(){
        try {
            List<Case> caseList = new List<Case>();
            set<Id> aspIds = new set<Id>();
            caseList = [SELECT id, ASP_Account__c FROM Case];
            for(Case cs : caseList){
                if(cs.ASP_Account__c != null){
                    aspIds.add(cs.ASP_Account__c);
                }
            }
            List<Case> serviceRequestList = new List<Case>();
            serviceRequestList = [SELECT id,Status,Subject,Account_Benefit_Override__c,Priority,Product_Sub_Category__c,Origin,Product_Category__c,Service_Required_For__c,Account_Code__c,AccountId, ASP_Account__c,ContactId   FROM Case Where ASP_Account__c In : aspIds AND Status != 'Closed' AND CreatedDate = Today];
            Map<id, Open_Calls_Tmp__c> existingOpenCallsMap = new Map<id, Open_Calls_Tmp__c>();
        for (Open_Calls_Tmp__c oct : [SELECT Id, Status__c, Subject__c,ServiceRequest__c, Account_Benefit_Override__c, Priority__c, Origin__c, ProductCategory__c, Account__c, ASP_Account__c 
                                      FROM Open_Calls_Tmp__c]) {
            if(!existingOpenCallsMap.containsKey(oct.ServiceRequest__c)){
                existingOpenCallsMap.put(oct.ServiceRequest__c,oct);
            }
        }
        List<Open_Calls_Tmp__c> openCallTampList = new List<Open_Calls_Tmp__c>();
        for (Case cs : serviceRequestList) {
            if (!existingOpenCallsMap.containsKey(cs.Id)) {
                Open_Calls_Tmp__c octObj = new Open_Calls_Tmp__c();
                octObj.Status__c = cs.Status;
                octObj.Subject__c = cs.Subject;
                octObj.Account_Benefit_Override__c = cs.Account_Benefit_Override__c;
                octObj.Priority__c = cs.Priority;
                octObj.Origin__c = cs.Origin;
                octObj.ProductCategory__c = cs.Product_Category__c;
                octObj.Account__c = cs.AccountId;
                octObj.ASP_Account__c = cs.ASP_Account__c;
                openCallTampList.add(octObj);
            }
        }
        if (!openCallTampList.isEmpty()) {
            upsert openCallTampList;
        }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}