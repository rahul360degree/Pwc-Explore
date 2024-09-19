@isTest
public with sharing class TestClaimRequestBuidler {
    Claim_Requests__c claimRequest;
    public TestClaimRequestBuidler(String recordTypeDeveloperName) {
        Id recordTypeId = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        claimRequest =  new Claim_Requests__c();
        claimRequest.recordTypeId = recordTypeId;
    }

    public Claim_Requests__c setRecordType(String recordType) {
        claimRequest.Record_Type__c = recordType;
        return claimRequest;
    }

    public Claim_Requests__c setBusinessPartnerName(Id accountId) {
        claimRequest.Business_Partner_Name__c = accountId;
        return claimRequest;
    }

    public Claim_Requests__c setAssociatedClaim(Id claimId) {
        claimRequest.Claim_Request__c = claimId;
        return claimRequest;
    }

    public Claim_Requests__c setApprovalStatus(String approvalStatus) {
        claimRequest.Approval_Status__c = approvalStatus;
        return claimRequest;
    }
        
    public Claim_Requests__c setLevel1Approver(Id approverId) {
        claimRequest.Level_1__c = approverId;
        return claimRequest;
    }
    
    public Claim_Requests__c setGRNNumber(String grnNumber) {
        claimRequest.GRN_No__c = grnNumber;
        return claimRequest;
    }
    
    public Claim_Requests__c getRecord(){
        return claimRequest;
    }
    
    public Claim_Requests__c getSavedRecord(){
        insert claimRequest;
        return claimRequest;
    }
}