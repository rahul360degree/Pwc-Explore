/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   batch class to set stage picklist value to inactive if end date has passed.
Inputs:        
Test Class:   DeactivateDiscountMatrixSchedulerTest

History
11-08-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class DeactivateDiscountMatrixBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext jobId){
        return Database.getQueryLocator('Select End_Date__c,Stage__c From Discount_Matrix__c Where End_Date__c!=null And End_Date__c<TODAY And Stage__c!=\'Inactive\'');
    }
    
    public Void execute(Database.BatchableContext bc, List<Discount_Matrix__c> matrices){
      List<Discount_Matrix__c> matricesToDeactivate=new List<Discount_Matrix__c>();
        for(Discount_Matrix__c dm:matrices){
            if(Schema.sObjectType.Discount_Matrix__c.fields.Stage__c.isUpdateable()){
               dm.Stage__c=GlobalConstants.DISCOUNT_MATRIX_INACTIVE_STAGE;
              }
            matricesToDeactivate.add(dm);
        }
        
        if(matricesToDeactivate.Size()>0){
            Runtime_Execution__c runtimeExecution=Runtime_Execution__c.getOrgDefaults();
            runtimeExecution.FireDiscountMatrixValidationRules__c=false;
            update runtimeExecution;
            DiscountMatrixTriggerHandler.TriggerDisabled=true;
            try{
            	Update matricesToDeactivate ;
            }
            catch(exception ex){
                Logger.logError('DeactivateDiscountMatrixBatch','execute', '', ex);
            }
            DiscountMatrixTriggerHandler.TriggerDisabled=false;
            runtimeExecution.FireDiscountMatrixValidationRules__c=true;
            update runtimeExecution;
        }
    }
  
    public Void finish(Database.BatchableContext jobId) {}
}