// Without sharing to allow collection plan updates for all order invoices regardless of the owner
public without sharing class CaptureCollectionPlanController {
    public static final String BILLED_SALES_API_NAME = 'Billed_Sales_Outstandings__c';
    public static final String RECEIVABLE_RECORD_TYPE = 'Receivable';

    @AuraEnabled
    public static Collection_Plan__c getCollectionPlan(String recordId) {
        Collection_Plan__c collectionPlanRec = new Collection_Plan__c(Balance_Amount__c = 0);
        Boolean hasInvoices = false;
        String orderNumber;
        if (String.isNotBlank(recordId)) {
            if (recordId.startsWith(Schema.getGlobalDescribe().get(BILLED_SALES_API_NAME).getDescribe().getKeyPrefix())) {
                for (Billed_Sales_Outstandings__c each : [SELECT Collection_Plan__c FROM Billed_Sales_Outstandings__c WHERE Id = :recordId]) {
                    collectionPlanRec.Id = each.Collection_Plan__c;
                }
                for (Receivable__c each : [SELECT Id, Order__c FROM Receivable__c WHERE Invoice__c = :recordId AND Record_Type__c = :RECEIVABLE_RECORD_TYPE]) {
                    orderNumber = each.Order__c;
                    break;
                }
                for (Receivable__c each : [SELECT Id, Balance_in_Home_Currency__c FROM Receivable__c WHERE Order__c = :orderNumber AND Record_Type__c = :RECEIVABLE_RECORD_TYPE]) {
                    collectionPlanRec.Balance_Amount__c += each.Balance_in_Home_Currency__c == null ? 0 : each.Balance_in_Home_Currency__c;
                }
                if (String.isBlank(orderNumber)) {
                    throw getAuraException(Label.Invoice_Has_No_Order_Reference);
                }
                for (Order each : [SELECT Id FROM Order WHERE OrderReferenceNumber = :orderNumber]) {
                    if (collectionPlanRec.Id == null) {
                        collectionPlanRec.Sales_Order__c = each.Id;
                    }
                }
            } else {
                for (Order each : [SELECT OrderReferenceNumber FROM Order WHERE Id = :recordId]) {
                    orderNumber = each.OrderReferenceNumber;
                }
                if (String.isBlank(orderNumber)) {
                    throw getAuraException(Label.Order_Not_Synced);
                }
                for (Receivable__c each : [SELECT Invoice__c, Balance_in_Home_Currency__c FROM Receivable__c WHERE Order__c = :orderNumber AND Record_Type__c = :RECEIVABLE_RECORD_TYPE]) {
                    hasInvoices = true;
                    collectionPlanRec.Balance_Amount__c += each.Balance_in_Home_Currency__c == null ? 0 : each.Balance_in_Home_Currency__c;
                }
                if (!hasInvoices) {
                    throw getAuraException(Label.Order_Not_Invoiced);
                } else {
                    for (Collection_Plan__c each : [SELECT Id FROM Collection_Plan__c WHERE Sales_Order__c = :recordId]) {
                        collectionPlanRec.Id = each.Id;
                    }
                }
                if (collectionPlanRec.Id == null) {
                    collectionPlanRec.Sales_Order__c = recordId;
                }
            }
        }
        return collectionPlanRec;
    }

    @AuraEnabled
    public static void updateCollectionPlan(String recordId) {
        Collection_Plan__c collectionPlanRec;
        Set<Id> invoiceIdSet = new Set<Id>();
        List<Billed_Sales_Outstandings__c> recordsToUpdate = new List<Billed_Sales_Outstandings__c>();
        try {
            for (Collection_Plan__c each : [SELECT Id, Sales_Order__r.OrderReferenceNumber, Planned_Collection_Date_1__c, Planned_Collection_Amount_1__c,
                Planned_Collection_Date_2__c, Planned_Collection_Amount_2__c, Planned_Collection_Date_3__c, Planned_Collection_Amount_3__c, Planned_Collection_Date_4__c,
                Planned_Collection_Amount_4__c, Planned_Collection_Date_5__c, Planned_Collection_Amount_5__c FROM Collection_Plan__c WHERE Id = :recordId]) {
                collectionPlanRec = each;
            }
            for (Receivable__c each : [SELECT Invoice__c FROM Receivable__c WHERE Order__c = :collectionPlanRec.Sales_Order__r.OrderReferenceNumber]) {
                invoiceIdSet.add(each.Invoice__c);
            }
            for (Billed_Sales_Outstandings__c each : [SELECT Id, Planned_Collection_Date_1__c, Planned_Collection_Amount_1__c, Planned_Collection_Date_2__c,
                Planned_Collection_Amount_2__c, Planned_Collection_Date_3__c, Planned_Collection_Amount_3__c, Planned_Collection_Date_4__c, Planned_Collection_Amount_4__c,
                Planned_Collection_Date_5__c, Planned_Collection_Amount_5__c, Collection_Plan__c FROM Billed_Sales_Outstandings__c WHERE Id IN :invoiceIdSet]) {
                each.Collection_Plan__c = collectionPlanRec.Id;
                each.Planned_Collection_Date_1__c = collectionPlanRec.Planned_Collection_Date_1__c;
                each.Planned_Collection_Date_2__c = collectionPlanRec.Planned_Collection_Date_2__c;
                each.Planned_Collection_Date_3__c = collectionPlanRec.Planned_Collection_Date_3__c;
                each.Planned_Collection_Date_4__c = collectionPlanRec.Planned_Collection_Date_4__c;
                each.Planned_Collection_Date_5__c = collectionPlanRec.Planned_Collection_Date_5__c;
                each.Planned_Collection_Amount_1__c = collectionPlanRec.Planned_Collection_Amount_1__c;
                each.Planned_Collection_Amount_2__c = collectionPlanRec.Planned_Collection_Amount_2__c;
                each.Planned_Collection_Amount_3__c = collectionPlanRec.Planned_Collection_Amount_3__c;
                each.Planned_Collection_Amount_4__c = collectionPlanRec.Planned_Collection_Amount_4__c;
                each.Planned_Collection_Amount_5__c = collectionPlanRec.Planned_Collection_Amount_5__c;
                recordsToUpdate.add(each);
            }
            update recordsToUpdate;
        } catch (Exception e) {
            throw getAuraException(e.getMessage());
        }
    }

    private static AuraHandledException getAuraException(String message) {
        AuraHandledException newException = new AuraHandledException(message);
        newException.setMessage(message);
        return newException;
    }
}