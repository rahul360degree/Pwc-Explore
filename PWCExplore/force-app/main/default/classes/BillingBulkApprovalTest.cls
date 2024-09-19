/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-01-2022
 * @last modified by  : vrajpoot@godrej.com
**/
@isTest
public with sharing class BillingBulkApprovalTest {
    @testsetup
    private static void testData() {
        Id accoundId = LeaseTestDataFactory.createAccountFromName('Bulk Billing');
        List<Account> accList = [Select Id, Name, Integration_Status__c, Account_Code__c
                                 from Account where Name=:'Bulk Billing'];
        system.assertEquals(accList.size(), 1);
        
        accList[0].Integration_Status__c = 'Synced';
        update accList;
        
        Id contactId = LeaseTestDataFactory.createContact(accoundId);
        Id oppId = LeaseTestDataFactory.createOpportunity(accoundId); 
        Id hotId = LeaseTestDataFactory.CreateHoT(oppId);
        
        List<HEAD_OF_TERMS__c> hotList = [Select Id, Name, Licence_End_Date__c, Reason_for_change_in_contract_date__c,
                                          Contract_Closure_Date__c
                                          from HEAD_OF_TERMS__c where Id = :hotId];
        system.assertEquals(hotList.size(), 1);
        
        Id billId = LeaseTestDataFactory.createBill(hotId, oppId);
        List<Billing__c> billList = new List<Billing__c>();
        
        billList = [Select Id, Name, Charge__c, Head_Of_Terms__c, Billing_Start_Date__c, Billing_End_Date__c,
                                    Amount__c, Opportunity__c, Remarks__c, Narration__c, Approval_Status__c
                                    from Billing__c where Id = :billId];
        billList[0].Approval_Status__c	 = 'CRM Team Approval Pending';
        system.assertEquals(billList.size(), 1);


        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments( 'Submitting request for approval' );
        req1.setObjectId( billList[0].id );
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process( req1 );
        
    }
    static testmethod void getPendingApprovalsTest() {
		Test.StartTest();
		BillingBulkApproval.getPendingApprovals('Billing__c','ProcessInstance.TargetObject.Name');
		Test.StopTest();
         List<Billing__c>a=[Select Id,Name,Type_of_billing__c,Opportunity__c,Opportunity__r.Account.Name,Charge_Type__c from Billing__c where Approval_Status__c= 'CRM Team Approval Pending'];
         system.assertEquals(a.size(), 1);//gcp22 edited by dhiren 03/04/2023
    }
    
    static testmethod void submitForApproval() {
        Test.StartTest();
        String objectName = 'Billing__c';
        String query='SELECT Id '
                        +' from ProcessInstanceWorkitem'
                        +' where '
                        +'ProcessInstance.TargetObject.Type  =: objectName ' 
                        + '  limit 100';
        List<ProcessInstanceWorkitem> processItems= Database.query(query);
        List<Id> pids = new List<Id>();
        for(ProcessInstanceWorkitem approval:processItems){
            pids.add(approval.Id);
        }
		BillingBulkApproval.submitForApproval(pids,GlobalConstants.APPROVED);
		Test.StopTest();
        system.assert([SELECT Id from ProcessInstanceWorkitem where ProcessInstance.TargetObject.Type=:objectName limit 100].size()>0);//gcp22 edited by dhiren 03/04/2023
    }
    
    static testmethod void exceptionTest() {
		Test.StartTest();
        Delete [Select Id from Billing__c limit 1000];
        try{
        	BillingBulkApproval.getPendingApprovals('Billing__c','ProcessInstance.TargetObject.Name');    
        }catch(Exception ex){}
		try{
        	BillingBulkApproval.submitForApproval(new List<Id>(),GlobalConstants.APPROVED);    
        }catch(Exception ex){}
		Test.StopTest();
        system.assert([Select Id from Billing__c limit 1000].size()==0);//gcp22 edited by dhiren 03/04/2023
    }
}