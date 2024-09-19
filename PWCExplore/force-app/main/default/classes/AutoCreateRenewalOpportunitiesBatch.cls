/*
Written by  : Deepali Bhorkar
On          : 17/03/2023
Description : JIRA Bug - SMEPB - 71
*/

public class AutoCreateRenewalOpportunitiesBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        Date Expiry=system.Today()+60;
        return Database.getQueryLocator('Select Id,Name,AccountId,Branch__c,Duration_Unit__c,Duration__c,OwnerId,MHE_Division__c,EndDate, Associated_Opportunity__r.Enquiry_Type__c, Associated_Opportunity__r.WarehouseCode__c,Associated_Opportunity__r.Pricebook2Id from ServiceContract where Duration__c!=null and Duration_Unit__c!=null and Duration__c!=\'0\' and EndDate =:Expiry');
    }
    public void execute(Database.BatchableContext bc, List<ServiceContract> servconList){
        // process each batch of records
        List<Opportunity> oppToBeCreated = new List<Opportunity>();
        Date Expiry=system.Today()+60;
        Id devRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('MHE').getRecordTypeId();
        List<Id> OwnerIds = new List<Id>(); 
        for(ServiceContract contracts : servConList){
            OwnerIds.add(contracts.OwnerId);
        }
        Map<Id,User> Ownerdetails = New Map<Id,User>([Select Area_code__c,Id,isActive,ManagerId,Manager.isActive from User Where Id in :OwnerIds]);
        if (servConList.size()>0){
            for(ServiceContract servcon : servConList){
                Opportunity opp = new Opportunity();
                opp.Name = 'Renewal Opportunity for '+ servcon.name;  
                opp.AccountId = servcon.AccountId;
                opp.OwnerId = Ownerdetails.get(servcon.OwnerId).isActive ? servcon.OwnerId : //assigning L+1 / Anurag Singh(MHE Sales KAM Functional User) in case of inactive service engg/ engg L+1
                (
                    Ownerdetails.get(servcon.OwnerId).Manager.isActive ? 
                    Ownerdetails.get(servcon.OwnerId).ManagerId:
                    System.Label.Default_Renewal_Opportunity_Owner	
                );
                opp.RecordTypeId = devRecordTypeId;
                opp.CloseDate = Expiry;
                opp.MHE_Division__c = GlobalConstants.MHE_DIVISION_CONTRACTS;
                opp.StageName = GlobalConstants.Opp_StageName_Inquiry;
                opp.Previous_Service_Contract__c = servcon.Id; 
                opp.Sales_Branch_Name__c = servcon.Branch__c;
                opp.Area_Code__c = Ownerdetails.get(servcon.OwnerId).Area_Code__c; 
                opp.Contract_Start_Date__c = servcon.EndDate+1;
                opp.Duration_Unit__c = servcon.Duration_Unit__c;
                opp.Duration__c = decimal.valueof(servcon.Duration__c);
                opp.Competitor1__c = GlobalConstants.Competitor1_None;
                if (servcon.Associated_Opportunity__r != null) {
                    opp.Enquiry_Type__c = servcon.Associated_Opportunity__r.Enquiry_Type__c;
                    opp.WarehouseCode__c = servcon.Associated_Opportunity__r.WarehouseCode__c;
                    opp.Pricebook2Id = servcon.Associated_Opportunity__r.Pricebook2Id;
                    
                }
                              
                oppToBeCreated.add(opp);
            }
        }
        if(oppToBeCreated.size()>0){
            Database.SaveResult[] srList = Database.insert(oppToBeCreated,false); 
            List<Id> oppID = new List<Id>(); 
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    oppID.add(sr.getId()); 
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Opp. ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opp fields that affected this error: ' + err.getFields());
                    }
                }
            }  
            List<Opportunity> oppCreated =[Select Id,Previous_Service_Contract__c from Opportunity where ID in : oppID];
            //insert oppProductsToBeCreated;
            InvocableOpportunityProductsCreator.createOpportunityProducts(new List<List<Opportunity>>{oppCreated});    
        } 
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations	
    }
}