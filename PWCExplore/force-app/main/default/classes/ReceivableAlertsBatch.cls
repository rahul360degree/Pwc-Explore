/*------------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Batch job to generate receivables alerts for Sales reps
 * Test Class    :        ReceivableAlertsBatchTest
 * History
 * --------
 * 18-10-2020      Joshna Palla     Initial Release
 * 22-10-2020      Joshna Palla     Incorporated demo feedback (chatter message formatting)
 * -----------------------------------------------------------------------------------------*/
public without sharing class ReceivableAlertsBatch implements Database.Batchable<sObject>, Database.Stateful {
    Set<Date> dueDateSet;
    Map<String, Map<Integer, Receivable_Alerts__mdt>> alertsByBU;
    String queryString;
    Set<String> fieldList;
    String delimiterStart = '{';
    String delimiterEnd = '}';
    String newLineCharacter = '\n';
    String receivableObjectAPIName = 'Billed_Sales_Outstandings__c';
    Map<String, String> fieldSoapTypeMap;
    Map<Id, Decimal> balanceAmountMap = new Map<Id, Decimal>();
    String amountKey = 'BalanceAmount';
    String orderKey = 'SalesOrderNumber';
    Set<Id> processedRecords = new Set<Id>();
    Map<Id, String> invoiceToOrderMapping = new Map<Id, String>();

    /* Constructor to query Receivable Alerts and create set of "Date" values that records need to meet for creating alerts
     * As each BU's alert is configured with different intervals and for different date fields, this is stored in a map with BU + field as key
     * If alert is configured for "before" a specific date field, all records with TODAY + # of days are queried
     * If alert is configured for "after" a specific date field, all records with TODAY - # of days are queried
     */
    public ReceivableAlertsBatch() {
        dueDateSet = new Set<Date>();
        alertsByBU = new Map<String, Map<Integer, Receivable_Alerts__mdt>>();
        Integer numberOfDays;
        fieldList = new Set<String>();
        fieldSoapTypeMap = new Map<String, String>();

        for (Receivable_Alerts__mdt each : [SELECT Id, Alert_Date_Field__c, Alert_Rule__c, Alert_Content__c, Business_Unit__c, Days_Due_Overdue__c
                                            FROM  Receivable_Alerts__mdt LIMIT 49999]) {
            numberOfDays = (each.Alert_Rule__c == 'Before' ? 1 : -1) * (each.Days_Due_Overdue__c == null ? 0 : Integer.valueOf(each.Days_Due_Overdue__c));
            dueDateSet.add(Date.today().addDays(numberOfDays));                                   
            fieldList.add(each.Alert_Date_Field__c);
            if (alertsByBU.containsKey(each.Business_Unit__c + each.Alert_Date_Field__c)) {
                alertsByBU.get(each.Business_Unit__c + each.Alert_Date_Field__c).put(numberOfDays, each);
            } else {
                alertsByBU.put(each.Business_Unit__c + each.Alert_Date_Field__c, new Map<Integer, Receivable_Alerts__mdt>{numberOfDays => each});
            }
        }

        Map<String, Schema.SObjectField> receivableFieldMap = Schema.getGlobalDescribe().get(receivableObjectAPIName).getDescribe().fields.getMap();
        for (String eachField : receivableFieldMap.keySet()) {
            fieldSoapTypeMap.put(eachField, String.valueOf(receivableFieldMap.get(eachField).getDescribe().getSoapType()));
        }
    }

    // Start method of batch job. Queries for receivables where balance is > 0 and one of the due date fields is in the set
    // created in constructor
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator('SELECT Id, Account_Name__c, Business_Unit__c, Due_Date__c, Invoice_Currency__c, Document_Date__c,'
            + 'Document_Number__c, Planned_Collection_Date_1__c, Planned_Collection_Date_2__c, Planned_Collection_Date_3__c, OwnerId, Collection_Plan__c,'
            + 'Planned_Collection_Date_4__c, Planned_Collection_Date_5__c, Planned_Collection_Amount_1__c, Planned_Collection_Amount_2__c,'
            + 'Planned_Collection_Amount_3__c, Planned_Collection_Amount_4__c, Planned_Collection_Amount_5__c, (SELECT Id, Order__c, Balance_in_Home_Currency__c '
            + 'FROM Invoice_Line_Items__r WHERE RecordType.DeveloperName = \'Receivable\' AND Balance_in_Home_Currency__c > 10)'
            + 'FROM Billed_Sales_Outstandings__c WHERE '
            + 'Due_Date__c IN :dueDateSet OR Planned_Collection_Date_1__c IN :dueDateSet '
            + 'OR Planned_Collection_Date_2__c IN :dueDateSet '
            + 'OR Planned_Collection_Date_3__c IN :dueDateSet '
            + 'OR Planned_Collection_Date_4__c IN :dueDateSet '
            + 'OR Planned_Collection_Date_5__c IN :dueDateSet ORDER BY Collection_Plan__c');
    }

    /* Execute method of batch job. Queries the manager and business unit of receivable record's owner (a separate query is used
     * as they're not supported as parent fields). For each receivable, ChatterUtility is used to create a chatter post.
     * All chatter messages are posted on the receivable record tagging the owner and L+1
     */
    public void execute(Database.BatchableContext batchableContext, List<Billed_Sales_Outstandings__c> receivableRecords) {
        System.debug('receivableRecords 1 :'+receivableRecords);
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        List<ConnectApi.FeedItemInput> feedInputs = new List<ConnectApi.FeedItemInput>();
        Set<Id> ownerIdSet = new Set<Id>();
        Map<Id, User> userMap = new Map<Id, User>();
        Map<String, Map<Id, Id>> usersToBeMentioned = new Map<String, Map<Id, Id>>();
        String orderNumber;

        for (Billed_Sales_Outstandings__c each : receivableRecords) {
            if (processedRecords.contains(each.Id)) {
                continue;
            }
            Decimal balanceAmount = 0;
            if (!each.Invoice_Line_Items__r.isEmpty()) {
                for (Receivable__c eachReceivable : each.Invoice_Line_Items__r) {
                    balanceAmount += eachReceivable.Balance_in_Home_Currency__c;
                    if (each.Business_Unit__c == GlobalConstants.SSG_BUSINESS_UNIT && String.isNotBlank(eachReceivable.Order__c)) {
                        invoiceToOrderMapping.put(each.Id, eachReceivable.Order__c);
                    }
                }
            }
            balanceAmountMap.put(each.Id, balanceAmount);
            ownerIdSet.add(each.OwnerId);            
        }

        if (!invoiceToOrderMapping.isEmpty()) {
            for (Receivable__c each : [SELECT Invoice__c, OwnerId, Order__c FROM Receivable__c WHERE Order__c IN :invoiceToOrderMapping.values()]) {
                ownerIdSet.add(each.OwnerId);
                if (usersToBeMentioned.containsKey(each.Order__c)) {
                    usersToBeMentioned.get(each.Order__c).put(each.Invoice__c, each.OwnerId);
                } else {
                    usersToBeMentioned.put(each.Order__c, new Map<Id, Id>{each.Invoice__c => each.OwnerId});
                }
            }
        }

        for (User each : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIdSet]) {
            userMap.put(each.Id, each);
        }

        for (Billed_Sales_Outstandings__c each : receivableRecords) {
            Set<Id> mentionIdSet = new Set<Id>();
            orderNumber = invoiceToOrderMapping.get(each.Id);
            if (balanceAmountMap.get(each.Id) <= 0) {
                continue;
            }
            if (processedRecords.contains(each.Id)) {
                continue;
            }
            processedRecords.add(each.Id);
            mentionIdSet.add(each.OwnerId);
            mentionIdSet.add(userMap.get(each.OwnerId).ManagerId);
            if (each.Business_Unit__c == GlobalConstants.SSG_BUSINESS_UNIT && String.isNotBlank(orderNumber) && usersToBeMentioned.containsKey(orderNumber)) {
                for (Id eachInvoiceId : usersToBeMentioned.get(orderNumber).keySet()) {
                    processedRecords.add(eachInvoiceId);
                    mentionIdSet.add(usersToBeMentioned.get(orderNumber).get(eachInvoiceId));
                    mentionIdSet.add(userMap.get(usersToBeMentioned.get(orderNumber).get(eachInvoiceId)).ManagerId);
                }
            }
            ChatterUtility utilityInstance = new ChatterUtility();
            if (each.Business_Unit__c == GlobalConstants.SSG_BUSINESS_UNIT && String.isNotBlank(each.Collection_Plan__c)) {
                utilityInstance.setSubjectId(each.Collection_Plan__c);
            } else {
                utilityInstance.setSubjectId(each.Id);
            }
            for (Id eachMentionId : mentionIdSet) {
                utilityInstance.addMention(eachMentionId);
            }
            Boolean hasMessage = getChatterMessage(each, utilityInstance, each.Business_Unit__c);
            if (!hasMessage) {
                continue;
            }
            ConnectApi.FeedItemInput feedItemInput = utilityInstance.build();
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            feedInputs.add(feedItemInput);
            batchInputs.add(batchInput);
        }

        if (!batchInputs.isEmpty()) {
            try {
                if (Test.isRunningTest()) {
                    ChatterUtility.postChatterForTestClass(feedInputs);
                } else {
                    ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
                }
            } catch(Exception feedPostException) {
                Logger.logError('Receivable Alerts', ReceivableAlertsBatch.class.getName(), 'execute', null, feedPostException);
            }
        }
    }

    // Finish method of the batch job. Creates a logger record with "INFO" of job status
    public void finish(Database.BatchableContext batchableContext) {
        AsyncApexJob apexJobInst = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob
                                    WHERE Id = :batchableContext.getJobId()];
        Logger.logError('Receivable Alert Job Status', ReceivableAlertsBatch.class.getName(), 'Job Status: ' + apexJobInst.JobItemsProcessed
            + ' of ' + apexJobInst.TotalJobItems + ' jobs processed with ' + apexJobInst.NumberOfErrors + ' errors');
    }

    // Utility method to create chatter message for each receivable record. This method extracts the message from custom metadata
    // based on the date field and BU this record meets
    private Boolean getChatterMessage(sObject receivableRecord, ChatterUtility utilityInstance, String businessUnit) {
        String key;
        Boolean hasMessage = false;
        Map<Integer, Receivable_Alerts__mdt> receivableAlertMap;
        for (String each : fieldList) {
            receivableAlertMap = new Map<Integer, Receivable_Alerts__mdt>();
            key = (String.isNotBlank(businessUnit) ? businessUnit : '') + each;
            if (alertsByBU.containsKey(key)) {
                receivableAlertMap = alertsByBU.get(key);
            }
            for (Integer eachInt : receivableAlertMap.keySet()) {
                if (receivableRecord.get(each) != null && Date.today().addDays(eachInt) == Date.valueOf(receivableRecord.get(each))) {
                    hasMessage = prepareChatterMessage(receivableAlertMap.get(eachInt).Alert_Content__c, receivableRecord, utilityInstance);
                }
            }
        }
        return hasMessage;
    }

    // Utility method to update merge fields in chatter message with field values from receivable record
    private Boolean prepareChatterMessage(String message, sObject receivableRecord, ChatterUtility utilityInstance) {
        Boolean hasMessage = false;
        for (String each : message.split(newLineCharacter)) {
            do {
                if (String.isNotBlank(each.substringBetween(delimiterStart, delimiterEnd))) {
                    String fieldName = each.subStringBetween(delimiterStart, delimiterEnd);
                    String fieldValue;
                    if (fieldName == amountKey) {
                        fieldValue = String.valueOf(balanceAmountMap.get(receivableRecord.Id));
                    } else if (fieldName == orderKey) {
                        fieldValue = invoiceToOrderMapping.get(receivableRecord.Id);
                    } else {
                        fieldValue = getFormattedFieldValue(receivableRecord.get(fieldName), fieldName);
                    }
                    each = each.replace(delimiterStart + fieldName + delimiterEnd, fieldValue);
                }
            } while (each.contains(delimiterStart) && each.contains(delimiterEnd));
            utilityInstance.addTextWithMarkupType(each, ConnectApi.MarkupType.PARAGRAPH);
            if (!hasMessage && String.isNotBlank(each)) {
                hasMessage = true;
            }
        }
        return hasMessage;
    }

    // Utility method to return formatted field value
    private String getFormattedFieldValue(Object fieldValue, String fieldName) {
        if (fieldValue == null) {
            return '';
        }
        String formattedFieldValue = String.valueOf(fieldValue);
        if (fieldSoapTypeMap.get(fieldName.toLowerCase()) == 'DATE') {
            return Date.valueOf(formattedFieldValue).format();
        }
        return formattedFieldValue;
    }
}