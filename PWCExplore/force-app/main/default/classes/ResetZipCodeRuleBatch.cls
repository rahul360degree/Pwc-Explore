/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   batch class to reset sequence in zip code rule.
Inputs:        
Test Class:   

History
11-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
public without sharing class ResetZipCodeRuleBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext jobId){
        return Database.getQueryLocator('Select Id,Sequence__c,Queues_And_LastAssignedId__c From Zip_Code_Rule__c');
  }
  
  public Void execute(Database.BatchableContext bc, List<Zip_Code_Rule__c> rules){
      List<Zip_Code_Rule__c> rulesToUpdate=new List<Zip_Code_Rule__c>(); 
      for(Zip_Code_Rule__c rule:rules){
        if (Schema.sObjectType.Zip_Code_Rule__c.Fields.Sequence__c.isUpdateable()){  
            rule.Sequence__c=1;
          }
        Map<String,Object> queueVsLastAssignedId=rule.Queues_And_LastAssignedId__c!=null?(Map<String,Object>)JSON.deserializeUntyped(rule.Queues_And_LastAssignedId__c):new Map<String,Object>();  
        for(String queue:queueVsLastAssignedId.keySet()){
            queueVsLastAssignedId.put(queue,'');
        }
        if (Schema.sObjectType.Zip_Code_Rule__c.Fields.Queues_And_LastAssignedId__c.isUpdateable()){
        rule.Queues_And_LastAssignedId__c=JSON.Serialize(queueVsLastAssignedId);
          }
        rulesToUpdate.add(rule);
      }
      
      Database.update(rulesToUpdate,false);
  }
  
  public Void finish(Database.BatchableContext jobId) {}
}