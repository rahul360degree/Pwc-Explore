/*------------------------------------------------------------------------
Company:       Salesforce
Description:   Helper class for Billed_Sales_Outstandings Object Trigger
Inputs:        NA
Test Class:    BilledSalesTriggerTest
History
27-11-2020     Abhishek Chaturvedi     Initial Release
----------------------------------------------------------------------------*/
public with sharing class BilledSalesTriggerHelper {    
   /*------------------------------------------------------------------------
    Author:        Shailja Mishra  
    Company:       Salesforce
    Description:   Method is responsible for populating defaults on header
    Inputs:        List<Billed_Sales_Outstandings__c> newBilledSales
    Test Class:   
    ---------------------------------------------------------------------------
    History
    04-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    
    public void updateSalesRepresentative(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        BilledSalesTriggerHelper helper = new BilledSalesTriggerHelper();
        List<Billed_Sales_Outstandings__c> newBilledSales = newItems.values();
        List<Billed_Sales_Outstandings__c> updatenewBilledSales = new List<Billed_Sales_Outstandings__c>();
        for(Billed_Sales_Outstandings__c receive: newBilledSales){
            System.debug(receive.Salary_Code__c);
            System.debug(((Billed_Sales_Outstandings__c)oldItems.get(receive.Id)).Salary_Code__c);
            if(receive.Salary_Code__c !=((Billed_Sales_Outstandings__c)oldItems.get(receive.Id)).Salary_Code__c){
                updatenewBilledSales.add(receive);
            }
        }
        helper.populateDefaultsOnReceivable(updatenewBilledSales);
        
    }
    
    
    public void populateDefaultsOnReceivable(List<Billed_Sales_Outstandings__c> newBilledSales){
        Set<String> salaryCodeSet = new Set<String>();
        for(Billed_Sales_Outstandings__c bso : newBilledSales){
            if(String.isNotEmpty(bso.Salary_Code__c)){
                salaryCodeSet.add(bso.Salary_Code__c.trim());
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
        
        for(Billed_Sales_Outstandings__c bso : newBilledSales){
            if(salaryCodeUserIdMap.containsKey(bso.Salary_Code__c)){
                bso.Sales_Representative__c = salaryCodeUserIdMap.get(bso.Salary_Code__c);
            }else{
                bso.Sales_Representative__c = salesRepMDT_Map.get(bso.Business_Unit__c);
            }            
            if (String.isNotBlank(bso.Sales_Representative__c)){
                bso.OwnerId = bso.Sales_Representative__c;
            }
        }
        
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra  
    Company:       Salesforce
    Description:   Method to set Not Due Since field
    Inputs:        Map<Id, Billed_Sales_Outstandings__c> newItems
                   Map<Id, Billed_Sales_Outstandings__c> oldItems
    Test Class:   
    ---------------------------------------------------------------------------
    History
    04-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void setStatusAndNotDueSince(Map<Id, Billed_Sales_Outstandings__c> newItems, Map<Id, Billed_Sales_Outstandings__c> oldItems) {
        for (Billed_Sales_Outstandings__c each : newItems.values()) {
            if (each.Business_Unit__c != GlobalConstants.SSG_BUSINESS_UNIT) {
                continue;
            }
            if (each.Status__c != oldItems.get(each.Id).Status__c) {
                if (each.Status__c == GlobalConstants.NOT_DUE_STATUS) {
                    each.Not_Due_Since__c = Date.today();
                } else {
                    each.Not_Due_Since__c = null;
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Shailja Mishra  
    Company:       Salesforce
    Description:   Method to set Not Due Since field
    Inputs:        Map<Id, Billed_Sales_Outstandings__c> newItems
                   Map<Id, Billed_Sales_Outstandings__c> oldItems
    Test Class:   
    ---------------------------------------------------------------------------
    History
    04-12-2020      Shailja Mishra     Initial Release
    -----------------------------------------------------------------------*/
    public void setDetailsForApprovals(Map<Id, Billed_Sales_Outstandings__c> newItems, Map<Id, Billed_Sales_Outstandings__c> oldItems) {
        Set<Id> updatedReceivables = new Set<Id>();
        Map<Id, String> soNumberMap = new Map<Id, String>();
        Map<Id, Decimal> totalBalance = new Map<Id, Decimal>();
        for (Billed_Sales_Outstandings__c each : newItems.values()) {
            if (String.isNotBlank(each.SF_Short_Code__c) && each.SF_Short_Code__c != oldItems.get(each.Id).SF_Short_Code__c) {
                updatedReceivables.add(each.Id);
            }
        }
        for (Receivable__c each : [SELECT Id, Order__c, Balance_in_Home_Currency__c, Invoice__c FROM Receivable__c WHERE Invoice__c IN :updatedReceivables
            AND Record_Type__c = 'Receivable']) {
            if (totalBalance.containsKey(each.Invoice__c)) {
                totalBalance.put(each.Invoice__c, totalBalance.get(each.Invoice__c) + each.Balance_in_Home_Currency__c);
            } else {
                totalBalance.put(each.Invoice__c, each.Balance_in_Home_Currency__c);
            }
            if (String.isNotBlank(each.Order__c)) {
                soNumberMap.put(each.Invoice__c, each.Order__c);
            }
        }
        for (Billed_Sales_Outstandings__c each : newItems.values()) {
            if (!updatedReceivables.contains(each.Id)) {
                continue;
            }
            each.Total_Balance__c = totalBalance.containsKey(each.Id) ? totalBalance.get(each.Id) : 0;
            each.SO__c = soNumberMap.get(each.Id);
        }
    }
}