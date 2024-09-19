/**
* @description       : This class is being used by Leasing Finance, Leasing CRM, Leasing System Admin and Leasing Team Profiles to approve bills in bulk
* @author            : vrajpoot@godrej.com
* @group             : 
* @next modified by & on  : vrajpoot@godrej.com & 04-06-2023 
* @last modified by & on  : priyamu@godrej.com & 25-09-2023 , added delegated approver logic
**/
public with sharing class BillingBulkApproval {
    public class WrapperClass{
        @AuraEnabled public List<ProcessInstanceWorkitem> workRecords;
        @AuraEnabled public  List<SObject> records;
        @AuraEnabled public  List<SObject> hotList;
        public WrapperClass(){
            workRecords = new List<ProcessInstanceWorkitem> ();
            records = new List<SObject>();
            hotList = new List<SObject>();
        }
    }
    /* Fetch all pending approvals */
    @AuraEnabled
    public static WrapperClass getPendingApprovals(String objectName,String fieldNames){
        List <user>  delegatedApprover = new List <user> ();
        try {
            Id userId = userinfo.getUserId();
            // Id delegatedApproverId;
            delegatedApprover = [select id from user where DelegatedApproverId=:userId];
            system.debug('delegatedApprover:--'+delegatedApprover);
            system.debug('userId:--'+userId);
            String query='SELECT Id, Actor.name, ProcessInstanceId, ProcessInstance.Status, '
                +'ProcessInstance.ProcessDefinition.DeveloperName,'
                +'ProcessInstance.ProcessDefinition.Type, '
                +'ProcessInstance.ProcessDefinition.TableEnumOrId, '
                +'ProcessInstance.TargetObjectId, '
                +fieldNames
                +' from ProcessInstanceWorkitem '
                +' where '
                +'ProcessInstance.TargetObject.Type  =: objectName'
                + (((delegatedApprover.size()>0) && !Test.isRunningTest())? ' and (ActorId=:userId or ActorId IN: delegatedApprover) ' :'')
                + (((delegatedApprover.isempty()) && !Test.isRunningTest())? ' and (ActorId=:userId) ' : '')
                + '  limit 1000';
            system.Debug('query:--'+query);
            List<ProcessInstanceWorkitem> processItems= Database.query(query);
            if(!processItems.isEmpty()){
                Set<Id> recId = new Set<Id>();
                for(ProcessInstanceWorkitem workItem:processItems){
                    recId.add(workItem.ProcessInstance.TargetObjectId);
                }
                WrapperClass wrap = new WrapperClass();
                wrap.workRecords = processItems;
                wrap.records = [Select Id,Name,Type_of_billing__c,Opportunity__c,Opportunity__r.Account.Name,
                                Billing_Start_Date__c, Billing_End_Date__c, 
                                Charge__c, Amount_Payable__c,Charge_Type__c,tax__c,total_amount__c,HEAD_OF_TERMS__c
                                from Billing__c 
                                where ID IN:recId
                               ];
                List<HEAD_OF_TERMS__c> hotList = hotList(wrap.records);
                wrap.hotList = hotList;
                return wrap;
            }else{
                String message = 'No Pending Approval found';
                AuraHandledException error = new AuraHandledException(message);
                error.setMessage(message);
                throw error;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //fetch HOT items to setup Assets
    public static List<HEAD_OF_TERMS__c> hotList(List<Billing__c> billingList){
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();
        if(!billingList.isEmpty()){
            Set<Id> opportunityIds = new Set<Id> ();
            for(Billing__c billing: billingList){
                opportunityIds.add(billing.Opportunity__c);
            }
            if(!opportunityIds.isEmpty()){
                hotList = [Select Id,Opportunity__c, (Select Id,Floor__r.Asset_Code__c from Rental_Units__r) 
                           from HEAD_OF_TERMS__c where Lease_Abstract__c=true and Opportunity__c IN:opportunityIds];
            }
        }
        return hotList;
    }
    //Approve selected items
    @AuraEnabled
    public static boolean submitForApproval(List<Id> workItemIds,string buttonName){
        try {
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();            
            for(String workid:workItemIds){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workid);
                if(buttonName==GlobalConstants.APPROVED){  //SCF-95
                    req.setAction('Approve');
                    req.setComments('Bulk Approved');
                }
                if(buttonName==GlobalConstants.Rejected){  //SCF-95
                    req.setAction('Reject');
                    req.setComments('Bulk Rejected');
                }
                requests.add(req);
            }
            Approval.ProcessResult[] processResults = Approval.process(requests);
            String errorMsg='';
            boolean success=true;
            for(Approval.ProcessResult result:processResults){
                if(!result.isSuccess()){
                    for(Database.Error errorList: result.getErrors()){
                        errorMsg +='; '+errorList.getMessage();        
                    }
                }
            }
            if(String.isEmpty(errorMsg)){
                return true;
            }
            else{
                throw new AuraHandledException(errorMsg);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}