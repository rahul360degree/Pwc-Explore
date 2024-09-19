/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   batch class to execute lead assignment rule engine.
Inputs:        
Test Class:   AssignLeadSchedularTest

History
11-05-2020      Manasi Londhe     Initial Release
11-04-2022		Rohit Jadhav	  Added Business Unit filter on line No 76 to bypass 'Appliances' Business Unit.
----------------------------------------------------------------------------*/

public without sharing class AssignLeadsBatch implements Database.Batchable<sObject>, Database.Stateful{
    public Map<Id,Zip_Code_Rule__c> rules=new Map<Id,Zip_Code_Rule__c>();
    public Id defaultQueueId;
    String query; 

    public AssignLeadsBatch() {
        defaultQueueId=[select Id From Group Where Type = 'Queue' AND DeveloperName = :GlobalConstants.LEAD_ASSIGNMENT_DEFAULT_QUEUE].Id;
        query=generateQuery();
    }

    public Database.QueryLocator start(Database.BatchableContext bc){     
        return Database.getQueryLocator(query);
    }

    public Void execute(Database.BatchableContext bc, List<Lead> leads){
        if(defaultQueueId!=null){
            if(rules.size()>0){
                for(Lead l:leads){
                    if(rules.containsKey(l.Zip_Code_Rule__c)){
                    l.Zip_Code_Rule__r.Sequence__c=rules.get(l.Zip_Code_Rule__c).Sequence__c;
                    l.Zip_Code_Rule__r.Queues_And_LastAssignedId__c=rules.get(l.Zip_Code_Rule__c).Queues_And_LastAssignedId__c;
                    }
                }
            }
            LeadAssignmentProcessor processor=new LeadAssignmentProcessor();
            processor.processAssignment(leads);
            for(Id sobjectId:processor.rulesAndLeadsToUpdate.keySet()){
                if(processor.rulesAndLeadsToUpdate.get(sobjectId).getsObjectType() == Zip_Code_Rule__c.sObjectType){
                    rules.put(sobjectId,(Zip_Code_Rule__c)processor.rulesAndLeadsToUpdate.get(sobjectId));
                }    
            }
        }
    }
    
    public Void finish(Database.BatchableContext bc) {
        //Error handling mechanism to default the batch size
        Integer assignerBatchSize  = GlobalConstants.DEFAULT_BATCH_SIZE;
        //Fetch Batch Size from Custom setting
        if(Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssignLeadsSchedular').Batch_Size__c) != null){
            assignerBatchSize = Integer.valueOf(Apex_Batch_Configurations__c.getValues('AssignLeadsSchedular').Batch_Size__c);
        }
        /*
        List<AsyncApexJob> batches=[Select Id,ApexClass.Name,JobType,Status From AsyncApexJob 
                                    Where JobType='BatchApex' And ApexClass.Name=:GlobalConstants.LEAD_ASSIGNER_BATCH_CLASS 
                                    And Status In ('Holding','Queued','Preparing','Processing')];
        if(batches.size()==0){
            List<Lead> leadsRemainingToProcess=[Select id From Lead where OwnerId=:defaultQueueId Limit 100];
            if(leadsRemainingToProcess.size()==100){
                AssignLeadsBatch assigner = new AssignLeadsBatch(); 
                Database.executeBatch(assigner,assignerBatchSize);
            }
        }*/
    }

    string generateQuery(){
        return 'Select Id,OwnerId,Zip_Code_Rule__c,Business_Unit__c,Zip_Code_Rule__r.Queue_1__c,'+
        'Zip_Code_Rule__r.Queue_2__c,'+
        'Zip_Code_Rule__r.Queue_3__c,Zip_Code_Rule__r.Queue_4__c,Zip_Code_Rule__r.Queue_5__c,'+
        'Zip_Code_Rule__r.Queue_6__c,Zip_Code_Rule__r.Queue_7__c,Zip_Code_Rule__r.Sequence__c,'+
        'Zip_Code_Rule__r.Queues_And_LastAssignedId__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c,'+
        'Zip_Code_Rule__r.Run_Round_Robin_on_Queue2__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue3__c,'+
        'Zip_Code_Rule__r.Run_Round_Robin_on_Queue4__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue5__c,'+
        'Zip_Code_Rule__r.Run_Round_Robin_on_Queue6__c,Zip_Code_Rule__r.Run_Round_Robin_on_Queue7__c'+
        ' From Lead Where IsConverted= false  AND OwnerId=\''+defaultQueueId+'\' and Business_Unit__c!=\''+GlobalConstants.APPLIANCE_BUSINESS_UNIT+'\''+
        ' AND ( '+
        '(not(Business_Unit__c = \''+GlobalConstants.INTERIO_BUSINESS_UNIT+'\'  AND Sub_Division__c =\''+GlobalConstants.B2C_SUBDIVISION+'\' ))'+
        'OR'+
        '(Business_Unit__c = \''+GlobalConstants.INTERIO_BUSINESS_UNIT+'\'  AND Sub_Division__c =\''+GlobalConstants.B2C_SUBDIVISION+'\' AND Status=\''+GlobalConstants.QUALIFIED+'\' )'+
        ')';


    }
}