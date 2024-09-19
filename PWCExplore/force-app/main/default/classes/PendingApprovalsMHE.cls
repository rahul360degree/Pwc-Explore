/**
 * @description       : Created for https://gnbdigitalprojects.atlassian.net/browse/SMEPB-24
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 05-23-2022
 * @last modified by  : vrajpoot@godrej.com
**/
    public with sharing class PendingApprovalsMHE extends PendingApprovalsParent{    
        @AuraEnabled 
        public static PendingApprovalsMHESubClass doInit(String sObjectName){
            return new PendingApprovalsMHESubClass(sObjectName);
        }    
    }