/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 09-30-2022
 * @last modified by  : vrajpoot@godrej.com
**/
global with sharing class BatchUpdatePBE_ForActiveProduct implements Database.Batchable<sObject>, Database.Stateful ,Schedulable{
    
    public void execute(SchedulableContext ctx) {
        BatchUpdatePBE_ForActiveProduct assigner = new BatchUpdatePBE_ForActiveProduct(); 
        Database.executeBatch(assigner,200);
    }


    Map<Id, String> productMap = new Map<Id, String>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime dt = System.Now();
        string query = 'Select id, isactive, product2.isactive, product2.id, product2.item__c from PriceBookEntry '+
                        +' where isactive = FALSE and product2.isactive = TRUE'
                        +' and (Expiriy_Date__c > :dt or Expiriy_Date__c = NULL)';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<PriceBookEntry> sobj) {
        List<PriceBookEntry> lstPBE = new List<PriceBookEntry>();
        List<product2> lstProductsToTouch = new List<product2>();        
        for(PriceBookEntry pbe : sobj){
            if(Schema.sObjectType.PriceBookEntry.fields.IsActive.isUpdateable()){ 
               pbe.IsActive = TRUE;
              }
            lstPBE.add(pbe);
            if(!(productMap.containsKey(pbe.product2.id))){
                productMap.put(pbe.product2.id, pbe.product2.item__c);
                lstProductsToTouch.add(new product2(id=pbe.product2.id));
            }
        }
        Database.Update(lstPBE,false);
        Database.Update(lstProductsToTouch,false);
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }
}