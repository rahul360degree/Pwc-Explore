/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   batch class to create Opportunity and Task record for Competitor Products for MHE accounts.
			*Batch should create Opportunity record after 5 Years from Manufacturing Date
			*Batch should create Task record after 2 years from Manufacturing Date
Inputs:        
Test Class:  OptyAndTaskCreatorBatchSchedulerTest

History
12-08-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class OpportunityAndTaskCreatorBatchForCP implements Database.Batchable<sObject>{
    set<String> productCategories = new set<string> {'Class 1', 'Class 2', 'Class 31', 'Class 32'};
	String query;
    Date oppStartDate;
    Date taskStartDate;
    
    //Constructor to define the dates for which Record needs to be fetched
    public OpportunityAndTaskCreatorBatchForCP(){
        //Date to fetch Record for Opportunity
        oppStartDate = system.today().addYears(-5); 
        
        //Date to fetch Record for Task
        taskStartDate = system.today().addYears(-2); 
        
        //generate Query String
        query = generateQuery();
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Competitor_Product__c> competitorProducts){
        list<Opportunity> opportunities = new list<Opportunity>();
        list<Task> tasks = new list<Task>();
        
        //Processing all the fetched records
        for(Competitor_Product__c cp : competitorProducts){
            //Create Opportunity records
            if(Date.valueof(cp.Manufacturing_Date__c) == Date.valueof(oppStartDate)){
                Opportunity opp = new Opportunity();
                opp.CloseDate = cp.Manufacturing_Date__c.addMonths(61);
                opp.Name = cp.Customer_Name__r.Name + ' Opportunity';
                opp.StageName = 'Qualification';
                opp.AccountId = cp.Customer_Name__c;
                opp.Business_Unit__c = cp.Customer_Name__r.Business_Unit__c;
                opp.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Opportunity', 'MHE');
                opportunities.add(opp); 
            }
            
            //Create task records 
            if(Date.valueof(cp.Manufacturing_Date__c) == Date.valueof(taskStartDate) 
              	&& productCategories.contains(cp.Product_Category__c)){
                Task taskRecord = new Task();
                taskRecord.Subject = 'Follow Up Task for battery operated truck';
                taskRecord.OwnerId = cp.Customer_Name__r.OwnerId;
                taskRecord.WhatId = cp.Id;
                taskRecord.Status = 'Not Started';
                taskRecord.Priority = 'Normal';
                taskRecord.ActivityDate = cp.Manufacturing_Date__c.addYears(2);
                taskRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Task', 'MHE');
                tasks.add(taskRecord);
            }
        }

        try{
            
            //Insert Opportunities
            if(opportunities.size() > 0){
                Database.SaveResult[] oppResults = database.insert(opportunities, false);
                //Error Handling mechanism for this insert operation is yet to implement
            }
            
            
            //Insert Tasks
            if(tasks.size() > 0){
                Database.SaveResult[] taskResults = database.insert(tasks, false);
                //Error Handling mechanism for this insert operation is yet to implement
            }
            
        }catch(Exception ex){
            Logger.logError(OpportunityAndTaskCreatorBatchForCP.class.getName(), 'execute', null, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    //Method to generate Query string
    string generateQuery(){
        	return 'SELECT Id, Manufacturing_Date__c, Customer_Name__c, Customer_Name__r.Name,'+
            	' Product_Category__c,  Customer_Name__r.OwnerId, Customer_Name__r.Business_Unit__c'+
            	' FROM Competitor_Product__c'+
                ' WHERE Customer_Name__r.Business_Unit__c = \''+ GlobalConstants.BUSINESS_UNIT_MHE_DIVISION +'\' AND' +
                ' Customer_Name__r.isPersonAccount = false AND' +
                ' (Manufacturing_Date__c = : oppStartDate  OR' +
            	' (Manufacturing_Date__c =: taskStartDate AND '+
            		'Product_Category__c IN : productCategories)) LIMIT 40000'; 
    }
}