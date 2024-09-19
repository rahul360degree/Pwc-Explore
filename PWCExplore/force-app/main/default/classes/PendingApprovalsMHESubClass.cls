/**
 * @description       : Created for https://gnbdigitalprojects.atlassian.net/browse/SMEPB-24
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 05-24-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class PendingApprovalsMHESubClass extends PendingApprovalsParent {
    @AuraEnabled public List<ProcessInstanceWorkitem> processInstanceRecords;
    @AuraEnabled public List<Pricing_approval_request__c> parRecords;
    @AuraEnabled public List<Quote> quoteRecords;
    private final String parquery = 'Select ID, Quote_Record_Type_Developer_Name__c,Opportunity_Name__c, Quote__c '
        +' from Pricing_approval_request__c '
        +' where ID IN:recId ';
    //constructor
    public PendingApprovalsMHESubClass(String sObjectName){
        processInstanceRecords = new List<ProcessInstanceWorkitem>();
        parRecords = new List<Pricing_approval_request__c>();
        quoteRecords = new List<Quote>();
        
        sObjectName = String.isEmpty(sObjectName)?'Pricing_approval_request__c':sObjectName;          
        String processInstanceQuery = processInstanceQuery('',sObjectName,'');
        processInstanceRecords = getProcessInstanceWorkitemRecords(processInstanceQuery,sObjectName);
        Set<Id> targetObjectIdSet = getTargetObjectIds(processInstanceRecords);
        parRecords= getTargetObjectRecords(parquery,targetObjectIdSet);
        quoteRecords = getQuoteRecords(parRecords);
    }
    //get the quotes
    private List<Quote> getQuoteRecords(List<Pricing_approval_request__c> parRecords){
        try{
            Set<ID> quoteId = new Set<Id>();
            for(Pricing_approval_request__c par:parRecords)  {
                quoteId.add(par.Quote__c);
            }
            List<Quote> quoteRecord = [Select Id, Area_Code__c,	OpportunityId, Opportunity.Name, Opportunity.MHE_Division__c,
                                        CreatedDate, QuoteNumber, Total_Unit_Basic__c,
                                       (Select ID, Product2Id, Product_Name__c, Requested_Customer_Discount__c,
                                        Approved_Customer_Discount__c from Quotelineitems)
                                       from Quote
                                       where ID IN:quoteId
                                       AND Opportunity.MHE_Division__c = 'Outright Sales'
                                       AND Opportunity.Business_Unit__c = 'K'
                                       ];
            return quoteRecord;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
    }   
}