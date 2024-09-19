public with sharing class PendingQuoteApprovalReportLocksSubClass {
    @AuraEnabled public List<ProcessInstanceWorkItem> processInstanceRecords;
    @AuraEnabled public List<Quote> quoteRecords;
    @AuraEnabled 
  	public static PendingQuoteApprovalReportLocksSubClass doInit(String sObjectName){
            return new PendingQuoteApprovalReportLocksSubClass(sObjectName);
        }
    //constructor
    public PendingQuoteApprovalReportLocksSubClass(String sObjectName){
        sObjectName = String.isEmpty(sObjectName)?'Quote':sObjectName;
        String query='SELECT id, actor.name,ElapsedTimeInDays,createddate, '
                +' ProcessInstance.TargetObjectId '
                //+fieldNames
                +' from ProcessInstanceWorkItem '
                +' where '
                +'ProcessInstance.targetObject.Type  =: sObjectName ' 
                + ' AND '
                + ' ProcessInstance.status = \'Pending\' '
                + ' limit 30000'
                +' ';
        processInstanceRecords=getProcessInstanceRecords(query,sObjectName);
        Set<Id> targetObjectIdSet = getTargetObjectIds(processInstanceRecords);
        quoteRecords = getQuoteRecords(targetObjectIdSet);
    }
    
    // get pending approvals
    private List<sObject> getProcessInstanceRecords(string query,String sObjectName){
        try{
            List<ProcessInstanceWorkItem> processItems= Database.query(query);
            return processItems;        
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
    //get parent Ids
    private Set<Id> getTargetObjectIds(List<ProcessInstanceWorkItem> processItems){
        try{
            Set<Id> recId = new Set<Id>();
                for(ProcessInstanceWorkItem workItem:processItems){recId.add(workItem.processInstance.TargetObjectId);}
            return recId;
        }catch(Exception ex){throw new AuraHandledException(ex.getMessage()); }
    }
    //get the quotes
    private List<Quote> getQuoteRecords(set<id> quoteId){
       id recordtypeid = Schema.Sobjecttype.Quote.getRecordTypeInfosByDeveloperName().get('Locks_B2B').getRecordTypeId();
        try{
            List<Quote> quoteRecord = [Select Id,OpportunityId, Opportunity.Name,Opportunity.owner.name,Last_Approved_Date__c,
                                        CreatedDate, QuoteNumber, Name, Account.Name,Agreed_by_customer__c,OwnerId,createdby.name
                                       from Quote
                                       where ID IN:quoteId
                                       AND 
                                       Opportunity.Business_Unit__c = 'L'
                                       AND 
                                       RecordtypeId=:recordtypeid
                                       ];
            return quoteRecord;
           
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    }   
}