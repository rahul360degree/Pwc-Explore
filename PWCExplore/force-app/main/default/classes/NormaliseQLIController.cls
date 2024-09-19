/*------------------------------------------------------------------------------------
* Author        :        Sumit
* Company       :        Salesforce
* Description   :        Normalise Quote Lines
* Inputs        :        
* Test Class    :        NormaliseQLIControllerTest
* History
* --------
* 22-07-2020      Sumit Swami     Initial Release
* ----------------------------------------------------------------------------------*/
public with sharing class NormaliseQLIController {
    public static Boolean NormaliseQLIControllerDisabled = false;
    
    public void createNormalisedQLIs(Map<Id,QuoteLineItem> newQLIs, Map<Id,QuoteLineItem> oldQLIs) {
        Map<Id, QuoteLineItem> validQLIMap = new Map<Id,QuoteLineItem>();
        List<QuoteLineItem> newLineItems = new List<QuoteLineItem>();
        Set<Id> recordIds = new Set<Id>();
        //Metadata entries for validation
        QLI_Normalisation_Rule__mdt[] qliValidRules = [SELECT Field__c, Value__c FROM QLI_Normalisation_Rule__mdt];
        Integer Quantity = 1;
        //Fields used for validation should be included in this SOQL
        for( QuoteLineItem qli : [Select Id, Quote.Status, Approval_Status__c, Quote.RecordType.DeveloperName FROM QuoteLineItem WHERE Id IN: newQLIs.keySet()]){
            if( (oldQLIs.get( qli.Id ).Normalise_QLI__c != newQLIs.get( qli.Id ).Normalise_QLI__c) && newQLIs.get( qli.Id ).Normalise_QLI__c){
                validQLIMap.put(qli.Id,qli);
            }
        }
        
        //QLIs to be used in util
        if(validQLIMap.size() > 0){ 
            recordIds = validQLIMap.keySet();
            //Loop QLIs and get fields using query builder util
            if(recordIds.size() > 0){
                for (QuoteLineItem each : Database.query(QueryBuilder.build('QuoteLineItem', 'Id IN :recordIds', false))) {
                    if(validateQLIs(validQLIMap.get(each.Id), qliValidRules)){
                        Quantity = Integer.valueOf(newQlis.get(each.Id).Quantity);
                        //Add to Org List to update  
                        newQlis.get(each.Id).Quantity = 1;
                        newQlis.get(each.Id).Normalise_QLI__c = false;
                        
                        for(integer i=0; i< Quantity -1;i++){
                            //Clone the normalised qlis, add cloned qlis to list 
                            QuoteLineItem newLineItem = each.clone(false, false, false, false);
                            //Set QLI qty and normalise
                            newLineItem.Quantity = 1;
                            newLineItem.Normalise_QLI__c = false;
                            newLineItem.OpportunityLineItemId = null;
                            newLineItems.add(newLineItem);
                        }
                    }
                }
                if(newLineItems.size() > 0){
                    try {
                          NormaliseQLIControllerDisabled = true;
                        //Cloned QLIs
                          insert newLineItems;
                        }
                    catch (DMLException ex) {
                        Logger.logError('NormaliseQLIController', 'createNormalisedQLIs', '', ex);
                    }
                }
            }
        }
    }
    
    public boolean validateQLIs(QuoteLineItem qli, QLI_Normalisation_Rule__mdt[] qliValidRules){
        Map<String,String> qliFldVal = new Map<String,String>();
        for(QLI_Normalisation_Rule__mdt each : qliValidRules){
            qliFldVal.put(each.Field__c,each.Value__c);
        }
        //Assumption: Metadata record will have a corresponding entry for field and value
        //Quote Record Type entry left blank negates condition hence normalisation wont happen
        if(qli.Quote.Status == qliFldVal.get('Quote.Status') && 
          (qli.Approval_Status__c == qliFldVal.get('Approval_Status__c1') ||
           qli.Approval_Status__c == qliFldVal.get('Approval_Status__c2')) &&
           qliFldVal.get('Quote.RecordType') != '' &&
           qliFldVal.get('Quote.RecordType').Contains(qli.Quote.recordtype.DeveloperName)){
           //valid QLI    
            return true;
        }else{
            //Not valid
            return false;
        }
    }
    
}