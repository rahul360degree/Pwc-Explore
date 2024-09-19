/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     BatchCreatePT.cls
Company:       Stetig
Description:   Batch Class for updating status as occupied over Premise Traction
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/

global class BatchCreatePT implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
         
        String query =  'select Id, Name, Building__c,  Start_Date__c, End_Date__c, Floor__c, HEAD_OF_TERMS__c, Leasing_Status__c, Lease_Status__c, Status__c from Junction_Unit__c  where Lease_Status__c = \'Active Lease\' LIMIT 20000';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Junction_Unit__c> rentalList) {
        
        // process each batch of records default size is 200
        List<Premise_Tracking__c> newPrimeTractionlist = new List<Premise_Tracking__c>();
        
        for(Junction_Unit__c rental : rentalList) {        
                Premise_Tracking__c premise = new Premise_Tracking__c();
                premise.Leasable_Unit__c = rental.Floor__c;
                premise.Tracking_Date__c = Date.Today();
                premise.Event__c = Label.Set_Occupied;
                newPrimeTractionlist.add(premise);
        }
        if(!newPrimeTractionlist.isEmpty()) {
            try{
                insert newPrimeTractionlist;
            } catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }   
        }   
    }   
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}