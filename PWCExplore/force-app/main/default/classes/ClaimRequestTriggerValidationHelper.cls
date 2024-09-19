public with sharing class ClaimRequestTriggerValidationHelper {
    public static final Id WARRANTY_TYPE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_WARRANTY).getRecordTypeId();
    public static final Id ADHOC_CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_ADHOC).getRecordTypeId();
    public static final Id INVOICE_SUBMISSION_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST).getRecordTypeId();
    public static final Id CONTRACT_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_CONTRACTS).getRecordTypeId();
    public static final Id CREDIT_NOTE_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE).getRecordTypeId();
    public static final Id SCC_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_SCC).getRecordTypeId();
    public static final Id CLAIM_REQUEST_RECORDTYPE_ID = Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST).getRecordTypeId();

    //If order__c and order_product__c are blank, annexure B
    //If order and order product are not blank, annexure A
    public void validateAnnexureAAndBClaimRequest(List<Claim_Requests__c> newItems) {
        Id claimReqRecordTypeId = CLAIM_REQUEST_RECORDTYPE_ID;
        Set<Id> secondaryOrderProductIds = new Set<Id>();
        Set<Id> primaryOrderProductIds = new Set<Id>();
        for(Claim_Requests__c newItem : newItems ) {
            if(newItem.RecordTypeId == claimReqRecordTypeId) {
                if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL) {
                    secondaryOrderProductIds.add(newItem.Order_Product__c);
                }

                if(newItem.Order__c == NULL && newItem.Order_Product__c == NULL && newItem.Godrej_Sales_Order__c != NULL) {
                    if(newItem.Godrej_Order_Product__c != NULL) {
                        primaryOrderProductIds.add(newItem.Godrej_Order_Product__c);
                    } 
                }
            }
        }
        
        Set<Id> allOrderProductIds = new Set<Id>();
        allOrderProductIds.addAll(primaryOrderProductIds);
        allOrderProductIds.addAll(secondaryOrderProductIds);
        Map<Id,OrderItem> approvedClaimRequestsMap = new Map<Id,OrderItem>([SELECT Id,(SELECT Id FROM Claim_Requests__r WHERE RecordTypeId =: claimReqRecordTypeId LIMIT 1),(SELECT Id FROM Godrej_Claim_Requests__r WHERE RecordTypeId =: claimReqRecordTypeId LIMIT 1) FROM OrderItem WHERE Id IN :allOrderProductIds]);
        for(Claim_Requests__c newItem : newItems) {
            if(newItem.RecordTypeId == claimReqRecordTypeId) {
                if(newItem.Order__c != NULL && newItem.Order_Product__c != NULL) {
                    OrderItem orderProduct = approvedClaimRequestsMap.get(newItem.Order_Product__c);
                    if(orderProduct.Claim_Requests__r.size() > 0) {
                        newItem.addError(System.Label.ClaimRequestAlreadyExistsForOrderProduct);
                    }
                } else if(newItem.Order__c == NULL && newItem.Order_Product__c == NULL && newItem.Godrej_Sales_Order__c != NULL && newItem.Godrej_Order_Product__c != NULL) {
                    OrderItem orderProduct = approvedClaimRequestsMap.get(newItem.Godrej_Order_Product__c);
                    if(orderProduct.Godrej_Claim_Requests__r.size() > 0) {
                        newItem.addError(System.Label.ClaimRequestAlreadyExistsForOrderProduct);
                    }
                }
            }
        }
    }
}