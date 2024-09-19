/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Processor class for PricingApprovalRequest Trigger
Inputs:        NA
Test Class:    
History
06-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public without sharing class PricingApprovalRequestProcessor {
    /*------------------------------------------------------------------------
    Author:        Subhojit
    Company:       Salesforce
    Description:   Calculate Product type field for Approval assignment
                   for Quote approval process
    Inputs:        Old and New trigger map records
    Test Class:  

    History
    06-04-2020      Subhojit    Initial Release
    ----------------------------------------------------------------------------*/
    public void updateProductTypeOnQuote(map<Id, Pricing_approval_request__c> newPaRequestMap,
                                            map<Id, Pricing_approval_request__c> oldPaRequestMap){
      try{
        Set<Id> setQuote=new Set<Id>();
        Set<String> setProductType=new Set<String>();
        Map<Id,Quote> mapQuote=new Map<Id,quote>();
        Set<String> setQuoteRecordType=new Set<String>();
        Map<String,String> mapProductLineToAppType=new Map<String,String>();
        List<QuoteLineItem> lstQL=new List<QuoteLineItem>();
        for(Pricing_approval_request__c prVar: newPaRequestMap.values()){
            if(prVar.Assign_Approver_Dynamically__c && !oldPaRequestMap.get(prVar.Id).Assign_Approver_Dynamically__c){
                setQuote.add(prVar.Quote__c);
                setQuoteRecordType.add(prVar.Quote_Record_Type_Developer_Name__c);
            }
        }

        if(setQuote.size()>0)    
        lstQL=[select Id,Approval_Status__c,Approval_Product_Line__c,Quote.recordType.DeveloperName,Product2.Product_Line__c,Product2.Product_Class__c from QuoteLineItem where QuoteId IN : setQuote];
              
          for(QuoteLineItem QLVar: lstQL){
              if(QLVar.Product2.Product_Class__c!=null){
                  
                  if(QLVar.Approval_Status__c==GlobalConstants.Submitted_for_Approval
                     || QLVar.Approval_Status__c==GlobalConstants.APPROVAL_REQUIRED_STATUS
                     || QLVar.Approval_Status__c==GlobalConstants.Rejected)   { 
                         
                         setProductType.add(QLVar.Approval_Product_Line__c);
                     }
              }  
              mapQuote.put(QLVar.QuoteId,new Quote(Id=QLVar.QuoteId,Product_Type__c=String.join((new List<String>(setProductType)),',')));          
          }
        if(mapQuote.size()>0)
            update mapQuote.values();
      }catch(Exception ex){
          Logger.logError('PricingApprovalRequestProcessor', 'updateProductTypeOnQuote',null , ex);
          
          if(String.isNotBlank(ex.getMessage()) && ex.getMessage().contains('Record submitted for Approval. This record is locked from editing:')){
              throw new PricingApprovalException('You are not member of the approver queue. Please contact system administrator.');
          }
      }    
    }                                   
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to update Parent Quote from Pricing Approval Request 
                   for Quote approval process
    Inputs:        Old and New trigger map records
    Test Class:  

    History
    06-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateParentQuote(map<Id, Pricing_approval_request__c> oldPaRequestMap, 
                                    map<Id, Pricing_approval_request__c> newPaRequestMap){
        
        list<Quote> parentQuotesToUpdate = new list<Quote>();
                                        
        for(Id parId : newPaRequestMap.keySet()){
             
            if(!newPaRequestMap.isEmpty() && newPaRequestMap.containsKey(parId) 
                && newPaRequestMap.get(parId).Approval_Status__c != oldPaRequestMap.get(parId).Approval_Status__c
                && newPaRequestMap.get(parId).Approval_Status__c != GlobalConstants.Submitted_for_Approval){
                Quote quotesToUpdate = new Quote();
                quotesToUpdate.Id = newPaRequestMap.get(parId).Quote__c;   
                quotesToUpdate.Approval_Status__c = newPaRequestMap.get(parId).Approval_Status__c;
                
                parentQuotesToUpdate.add(quotesToUpdate);
            }                                    
        }  
        
        if(parentQuotesToUpdate.size() > 0){
            try{
                GlobalConstants.EXECUTE_METHOD = false;
                update parentQuotesToUpdate;
            } catch(Exception ex){
                Logger.logError('PricingApprovalRequestProcessor', 'updateParentQuote', '', ex);
            }                                
        }
    }

    public class PricingApprovalException extends Exception {}
    
}