/*----------------------------------------------------------------------------
Company:       Salesforce
Description:   Helper class for Commission__c Object Trigger. Without sharing
               to fetch Invoice # for credit requests
Inputs:        NA
Test Class:    CommissionTriggerTest
History
11-12-2020     Abhishek Chaturvedi     Initial Release
----------------------------------------------------------------------------*/
public without sharing class CommissionTriggerHandlerHelper {
    String creditShareCommissionType = 'Credit Share';
    String actualCommissionType = 'Actual';
    String creditRequestCommissionType = 'Credit Request';
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';

    public void setDefaultsOnCreditShareRequest(List<Commission__c> commissionRecords) {
        Set<String> invoiceNumbers = new Set<String>();
        Map<String, Billed_Sales_Outstandings__c> invoiceNumberMap = new Map<String, Billed_Sales_Outstandings__c>();
        Map<Id, String> areaMap = new Map<Id, String>();
        Map<String, Area_Code_Branch_Champion__mdt> areaCodeMap = new Map<String, Area_Code_Branch_Champion__mdt>();
        Set<String> salaryCodes = new Set<String>();
        Set<Id> ownerIds = new Set<Id>();
        Map<String, Id> userMap = new Map<String, Id>();
        String requestingBranchCode, bookingBranchCode;
        Area_Code_Branch_Champion__mdt requestingBranch, bookingBranch;
        Map<Id, Set<Id>> uniqueOwnerMap = new Map<Id, Set<Id>>();
        Set<String> orderReferences = new Set<String>();
        Set<Id> invoiceIds = new Set<Id>();
        Map<String, Receivable__c> orderToInvoiceMap = new Map<String, Receivable__c>();
        Integer thresholdDays = 60;
        Map<Id, Set<String>> validBranchCodesByInvoice = new Map<Id, Set<String>>();
        String requestingUserBranch;
        Map<Id, Set<Id>> invoiceToOwnerIdMap = new Map<Id, Set<Id>>();
        Map<Id, String> userBranchMap = new Map<Id, String>();

        ownerIds.add(UserInfo.getUserId());
        for(Commission__c each : commissionRecords) {
            if(each.Type__c == creditRequestCommissionType) {
                each.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;
                if (String.isNotBlank(each.Invoice_Number__c)) {
                    invoiceNumbers.add(each.Invoice_Number__c);
                }
                if (String.isNotBlank(each.Order_Reference__c)) {
                    orderReferences.add(each.Order_Reference__c);
                }
            }
        }

        if (invoiceNumbers.isEmpty() && orderReferences.isEmpty()) {
            return;
        }

        for (Application_Settings__mdt each : [SELECT Value__c FROM Application_Settings__mdt WHERE DeveloperName = 'Credit_Sharing_Request_Threshold']) {
            thresholdDays = Integer.valueOf(each.Value__c);
        }

        if (!orderReferences.isEmpty()) {
            for (Receivable__c each : [SELECT Id, Invoice__c, Document__c, Document_Date__c, Invoice__r.OwnerId, Order__c FROM Receivable__c WHERE Order__c IN :orderReferences
                AND Record_Type__c = 'Invoice']) {
                orderToInvoiceMap.put(each.Order__c, each);
                invoiceIds.add(each.Invoice__c);
            }
        }
        if (!invoiceNumbers.isEmpty() || !invoiceIds.isEmpty()) {
            for (Billed_Sales_Outstandings__c each : [SELECT Id, Document_Number__c, Document_Date__c, (SELECT Id, OwnerId FROM Commissions__r
                WHERE Type__c = :actualCommissionType OR Type__c = :creditShareCommissionType), (SELECT Id, Branch__c, OwnerId FROM Invoice_Line_Items__r)
                FROM Billed_Sales_Outstandings__c WHERE (Document_Number__c IN :invoiceNumbers OR Id IN :invoiceIds)]) {
                invoiceNumberMap.put(each.Document_Number__c, each);
                uniqueOwnerMap.put(each.Id, new Set<Id>());
                for (Commission__c eachCommission : each.Commissions__r) {
                    uniqueOwnerMap.get(each.Id).add(eachCommission.OwnerId);
                }
                Set<String> branchSet = new Set<String>();
                Set<Id> ownerIdSet = new Set<Id>();
                for (Receivable__c eachLineItem : each.Invoice_Line_Items__r) {
                    branchSet.add(eachLineItem.Branch__c);
                    ownerIdSet.add(eachLineItem.OwnerId);
                }
                ownerIds.addAll(ownerIdSet);
                invoiceToOwnerIdMap.put(each.Id, ownerIdSet);
                validBranchCodesByInvoice.put(each.Id, branchSet);
            }
        }
        
        for (User each : [SELECT Id, Logistic_Company__c, Area_Code__c FROM User WHERE Id IN :ownerIds]) {
            if (String.isNotBlank(each.Area_Code__c)) {
                areaMap.put(each.Id, each.Area_Code__c);
            }
            if (String.isNotBlank(each.Logistic_Company__c)) {
                userBranchMap.put(each.Id, each.Logistic_Company__c);
            }
        }
        requestingUserBranch = userBranchMap.get(UserInfo.getUserId());
        for (Id each : invoiceToOwnerIdMap.keySet()) {
            if (!validBranchCodesByInvoice.containsKey(each)) {
                validBranchCodesByInvoice.put(each, new Set<String>());
            }
            for (Id eachOwnerId : invoiceToOwnerIdMap.get(each)) {
                validBranchCodesByInvoice.get(each).add(userBranchMap.get(eachOwnerId));
            }
        }

        for (Area_Code_Branch_Champion__mdt each : [SELECT Area_Code__c, Branch_head_Salary_code__c, Regional_Manager_Salary_Code__c FROM
            Area_Code_Branch_Champion__mdt WHERE Area_Code__c IN :areaMap.values()]) {
            areaCodeMap.put(each.Area_Code__c, each);
            if (String.isNotBlank(each.Branch_head_Salary_code__c)) {
                salaryCodes.add(each.Branch_head_Salary_code__c);
            }
            if (String.isNotBlank(each.Regional_Manager_Salary_Code__c)) {
                salaryCodes.add(each.Regional_Manager_Salary_Code__c);
            }
        }
        
        for (User each : [SELECT Id, Salary_Code__c FROM User WHERE Salary_Code__c IN :salaryCodes]) {
            userMap.put(each.Salary_Code__c, each.Id);
        }

        for (Commission__c each : commissionRecords) {
            Id invoiceOwnerId;
            if (each.Type__c != creditRequestCommissionType) {
                continue;
            }
            if (String.isNotBlank(each.Order__c) && String.isBlank(each.Order_Reference__c)) {
                each.addError(Label.Order_Not_Booked);
                continue;
            }
            if (String.isNotBlank(each.Order_Reference__c)) {
                if (!orderToInvoiceMap.containsKey(each.Order_Reference__c)) {
                    each.addError(Label.Order_Not_Invoiced);
                    continue;
                }
                if (orderToInvoiceMap.get(each.Order_Reference__c).Document_Date__c < Date.today() - thresholdDays) {
                    each.addError(Label.Credit_Sharing_Locked);
                    continue;
                }
                each.Invoice__c = orderToInvoiceMap.get(each.Order_Reference__c).Invoice__c;
                each.Invoice_Number__c = orderToInvoiceMap.get(each.Order_Reference__c).Document__c;
            } else if(String.isNotBlank(each.Invoice_Number__c)) {
                if (!invoiceNumberMap.containsKey(each.Invoice_Number__c)) {
                    each.addError(Label.Invalid_Invoice_Number);
                    continue;
                }
                if (invoiceNumberMap.get(each.Invoice_Number__c).Document_Date__c < Date.today() - thresholdDays) {
                    each.addError(Label.Credit_Sharing_Locked);
                    continue;
                }
                each.Invoice__c = invoiceNumberMap.get(each.Invoice_Number__c).Id;
            }
            if (String.isBlank(requestingUserBranch) || !validBranchCodesByInvoice.get(each.Invoice__c).contains(requestingUserBranch)) {
                each.addError(Label.Invalid_Request_For_Branch);
            }
            if (uniqueOwnerMap.get(each.Invoice__c).contains(each.OwnerId)) {
                each.addError(Label.Already_Credited);
            }
            for (Id eachOwnerId : invoiceToOwnerIdMap.get(each.Invoice__c)) {
                invoiceOwnerId = eachOwnerId;
                break;
            }

            each.Credit__c = 100/(uniqueOwnerMap.get(each.Invoice__c).size() + 1);
            requestingBranchCode = areaMap.get(UserInfo.getUserId());
            bookingBranchCode = areaMap.get(invoiceOwnerId);
            if (String.isNotBlank(requestingBranchCode)) {
                requestingBranch = areaCodeMap.get(requestingBranchCode);
            }
            if (String.isNotBlank(bookingBranchCode)) {
                bookingBranch = areaCodeMap.get(bookingBranchCode);
            }
            each.Requesting_Branch_Head__c = requestingBranch != null ? requestingBranch.Branch_head_Salary_code__c != null ? userMap.get(requestingBranch.Branch_head_Salary_code__c)
                : null : null;
            each.Requesting_Branch_RM__c = requestingBranch != null ? requestingBranch.Regional_Manager_Salary_Code__c != null ? userMap.get(requestingBranch.Regional_Manager_Salary_Code__c)
                : null : null;
            each.Level_1__c = bookingBranch != null ? bookingBranch.Branch_head_Salary_code__c != null ? userMap.get(bookingBranch.Branch_head_Salary_code__c)
                : null : null;
            each.Level_2__c = bookingBranch != null ? bookingBranch.Regional_Manager_Salary_Code__c != null ? userMap.get(bookingBranch.Regional_Manager_Salary_Code__c)
                : null : null;
        }
    }

    public void generateCommissionRecords(Map<Id,Commission__c> newItems, Map<Id,Commission__c> oldItems) {
        List<Commission__c> commissionRecordsToUpsert = new List<Commission__c>();
        Map<Id, Map<Id, List<Commission__c>>> invoiceToCommissionsMap = new Map<Id, Map<Id, List<Commission__c>>>();
        Set<Id> invoiceIds = new Set<Id>();
        List<Commission__c> approvedCreditRequests = new List<Commission__c>();
        for(Commission__c updatedRecord : newItems.values()) {
            if(updatedRecord.Type__c == creditRequestCommissionType && updatedRecord.Approval_Status__c.equalsIgnoreCase(APPROVAL_STATUS_APPROVED)
                && (oldItems.get(updatedRecord.Id)).Approval_Status__c != updatedRecord.Approval_Status__c) {
                invoiceIds.add(updatedRecord.Invoice__c);
                approvedCreditRequests.add(updatedRecord);
            }
        }

        if (approvedCreditRequests.isEmpty()) {
            return;
        }

        for (Billed_Sales_Outstandings__c each : [SELECT Id, (SELECT Id, Credit__c, Line_Item__c, Type__c, OwnerId FROM Commissions__r
            WHERE Type__c = :actualCommissionType OR Type__c = :creditShareCommissionType) FROM Billed_Sales_Outstandings__c WHERE Id IN :invoiceIds]) {
            Map<Id, List<Commission__c>> commissionListByOwner = new Map<Id, List<Commission__c>>();
            for (Commission__c eachCommission : each.Commissions__r) {
                if (commissionListByOwner.containsKey(eachCommission.OwnerId)) {
                    commissionListByOwner.get(eachCommission.OwnerId).add(eachCommission);
                } else {
                    commissionListByOwner.put(eachCommission.OwnerId, new List<Commission__c>{eachCommission});
                }
            }
            invoiceToCommissionsMap.put(each.Id, commissionListByOwner);
        }

        for (Commission__c each : approvedCreditRequests) {
            if (!invoiceToCommissionsMap.containsKey(each.Invoice__c)) {
                return;
            }
            Decimal credit = 100/(invoiceToCommissionsMap.get(each.Invoice__c).size() + 1);
            Id ownerId;
            for (Id eachOwner : invoiceToCommissionsMap.get(each.Invoice__c).keySet()) {
                ownerId = eachOwner;
                for (Commission__c eachCommission : invoiceToCommissionsMap.get(each.Invoice__c).get(ownerId)) {
                    if (Schema.sObjectType.Commission__c.fields.Credit__c.isCreateable()){
                        eachCommission.Credit__c = credit;
                       }
                    commissionRecordsToUpsert.add(eachCommission);
                }
            }
           
            for (Commission__c eachCommission : invoiceToCommissionsMap.get(each.Invoice__c).get(ownerId)) {
                Commission__c clonedCommission = eachCommission.clone(false, false, false, false);
                                clonedCommission.OwnerId = each.CreatedById;
                clonedCommission.Credit__c = credit;
                clonedCommission.Type__c = creditShareCommissionType;
                
                commissionRecordsToUpsert.add(clonedCommission);
            }
        }
        upsert commissionRecordsToUpsert;
      
    }

    public void shareCreditRequest(List<Commission__c> commissionRecords) {
        List<Commission__Share> commissionShareRecords = new List<Commission__Share>();
        Map<Id, Set<Id>> recordToUserMap = new Map<Id, Set<Id>>();
        for (Commission__c each : commissionRecords) {
            if(each.Type__c != creditRequestCommissionType) {
                continue;
            }
            recordToUserMap.put(each.Id, new Set<Id>{each.Level_1__c, each.Level_2__c});
        }
        for (Id each : recordToUserMap.keySet()) {
            for (Id userId : recordToUserMap.get(each)) {
                if (String.isBlank(userId)) {
                    continue;
                }
                commissionShareRecords.add(new Commission__Share(ParentId = each, UserOrGroupId = userId, AccessLevel = 'Edit',
                    RowCause = Schema.Commission__Share.RowCause.Credit_Share_Approver__c));
            }
        }
        insert commissionShareRecords;
    }
}