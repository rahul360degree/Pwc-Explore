/*------------------------------------------------------------------------
    Author:        Shailja Mishra 
    Company:       Salesforce
    Description:   Helper class for ReceivableTrigger 
                   Object Name - Line Item (Receivable__c)
    Inputs:        NA
    Test Class:   
    ---------------------------------------------------------------------------
    History
    02-12-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/

public with sharing class ReceivableTriggerHelper {
    public static final Map<String, Schema.RecordTypeInfo> RECEIVABLE_RECORDTYPES = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName();
    
    /*------------------------------------------------------------------------
    Author:        Shailja Mishra  
    Company:       Salesforce
    Description:   Method is responsible for populating defaults on Receivables
                   Before Insert
    Input:         List<Receivable__c> newReceivables
    Test Class:   
    ---------------------------------------------------------------------------
    History
    02-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void populateDefaultsOnReceivable(List<Receivable__c> newReceivables){
        List<String> orderList = new List<String>();
        Map<String, Id> orderMap = new Map<String, Id>();
        String delimiter = '_';
        
        for(Receivable__c re : newReceivables) {
            if (String.isNotBlank(re.Order__c) && String.isNotBlank(re.Branch__c)) {
                orderList.add(re.Branch__c + delimiter + re.Order__c);
            }
            if(String.isNotBlank(re.Record_Type__c) && RECEIVABLE_RECORDTYPES.containsKey(re.Record_Type__c)) {
                re.RecordTypeId = RECEIVABLE_RECORDTYPES.get(re.Record_Type__c).getRecordTypeId();
            }
        }
        for (Order each : [SELECT Id, Order_Reference_Number_Ext__c FROM Order WHERE Order_Reference_Number_Ext__c IN :orderList]) {
            orderMap.put(each.Order_Reference_Number_Ext__c, each.Id);
        }
        
        for (Receivable__c each : newReceivables) {
            if (String.isNotBlank(each.Order__c) && String.isNotBlank(each.Branch__c) && orderMap.containsKey(each.Branch__c + delimiter + each.Order__c)) {
                each.Related_Order__c = orderMap.get(each.Branch__c + delimiter + each.Order__c);
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Abhishek 
    Company:       Salesforce
    Description:   Method is responsible for creating commission records for invoices W-248
    Input:         Map<Id, Receivable__c> newReceivables
    ---------------------------------------------------------------------------
    History
    11-12-2020      Abhishek     Initial Release
    -----------------------------------------------------------------------*/
    public void createCommissionsRecordForInvoiceTypeRecords(Map<Id, Receivable__c> newReceivables){
        Id invoiceRecordTypeId = RECEIVABLE_RECORDTYPES.get('Invoice').getRecordTypeId();
        List<Commission__c> commissionsToInsert = new List<Commission__c>();
        for(Receivable__c newRecord : newReceivables.values()) {
            if(newRecord.RecordTypeId == invoiceRecordTypeId && newRecord.Business_Unit__c == 'K') {
                commissionsToInsert.add(new Commission__c(Credit__c = 100, Line_Item__c = newRecord.Id, OwnerId = newRecord.OwnerId, Type__c = 'Actual',
                    Invoice__c = newRecord.Invoice__c));
            }
        }
        insert commissionsToInsert;
    }
    
    
    
    public void updateSalesRepresentative(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        ReceivableTriggerHelper helper = new ReceivableTriggerHelper();
        List<Receivable__c> newReceivableItems = newItems.values();
        List<Receivable__c> updateReceivable = new List<Receivable__c>();
        for(Receivable__c receive: newReceivableItems){
            System.debug(receive.Salary_Code__c);
            System.debug(((Receivable__c)oldItems.get(receive.Id)).Salary_Code__c);
            if(receive.Salary_Code__c !=((Receivable__c)oldItems.get(receive.Id)).Salary_Code__c){
                updateReceivable.add(receive);
            }
        }
        helper.populateSalesRepresentative(updateReceivable);
        
    }
    
    public void populateSalesRepresentative(List<Receivable__c> newReceivables){
        Set<String> salaryCodeSet = new Set<String>();
        for(Receivable__c re : newReceivables) {
            if(String.isNotEmpty(re.Salary_Code__c)){
                salaryCodeSet.add(re.Salary_Code__c.trim());
            }
        }
        
       // List<Receivable_Sales_Representative__mdt> salesRep_mdt= [SELECT Id, DeveloperName, User_Id__c FROM Receivable_Sales_Representative__mdt LIMIT 49999];
        List<Receivable_Sales_Representative__mdt> salesRep_mdt = Receivable_Sales_Representative__mdt.getAll().values();
        Map<String,ID> salesRepMDT_Map = new Map<String,ID>();
        for(Receivable_Sales_Representative__mdt salesRep:salesRep_mdt){
            salesRepMDT_Map.put(salesRep.DeveloperName,salesRep.User_Id__c);
        }
        Map<String,ID> salaryCodeUserIdMap = new Map<String,ID>();
        for(User user:[Select Id,Salary_Code__c from user where Salary_Code__c IN:salaryCodeSet]){
            salaryCodeUserIdMap.put(user.Salary_Code__c,user.Id);
        }
        Set<ID> includedRecordTypeIds = new Set<ID>();
        includedRecordTypeIds.add(Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId());
        includedRecordTypeIds.add(Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId());
        for (Receivable__c each : newReceivables) {
            if(salaryCodeUserIdMap.containsKey(each.Salary_Code__c)){
                each.Sales_Representative__c = salaryCodeUserIdMap.get(each.Salary_Code__c);
            }else if(includedRecordTypeIds.contains(each.RecordTypeId)){
                each.Sales_Representative__c = salesRepMDT_Map.get(each.Business_Unit__c);
            }
            if(String.isNotEmpty(each.Sales_Representative__c))
                each.OwnerId = each.Sales_Representative__c;
        }
    }
    


}