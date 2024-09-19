trigger AutoApprovalEventTrigger on Auto_Approval_Event__e (after insert) {

  DynamicApprovalAssignmentHelper.allocateApprover(Trigger.new[0]. Pricing_Approval_Request_Id__c, Trigger.new[0].Quote_ID__c, 
                                                  Trigger.new[0].Related_Quote_Record_Type_ID__c);
}