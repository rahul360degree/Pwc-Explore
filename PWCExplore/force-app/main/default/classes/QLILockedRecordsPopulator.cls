/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       GITL
Description:   Populator class to display Locked QLI Records.
               Also to update locked QLI records, by unlocking,updating and again locking records 
Inputs:        String recordId,String qliRecords
Test Class:    QLILockedRecordsPopulatorTest
History 
04-07-2023      Shreela Nair     Initial Release
----------------------------------------------------------------------------*/
public without sharing class QLILockedRecordsPopulator{
    
    //To fetch Locked QLI Records
    @AuraEnabled
    public static List<SObject> fetchQuoteLineItemforLocksB2CISTD(String recordId) {
        String quoteRecID = '\'' + String.escapeSingleQuotes(recordId) + '\'';  
        String query = 'SELECT Id,Product_Name__c,Search_Key_II_Referenced__c,UnitPrice,MRP__c,Quantity,Discount__c,Distributor_Retention__c,Retailer_Retention__c,Trade_Discount_Percent__c,Status__c FROM QuoteLineItem WHERE QuoteId = '+quoteRecID+'';  
        try{
            return Database.query(query);
        }
        catch(Exception e){
            Logger.logError('QLILockedRecordsPopulator', 'fetchQuoteLineItemforLocksB2CISTD', '', e);
            return null;
        } 
        
    }
    
    @AuraEnabled
    public static void updateQuoteLineItemforLocksB2CISTD(String recordId,String qliRecords)  {
        List<QuoteLineItem> qliLockList; //To fetch Locked records
        Set<Id> qliId = new Set<Id>();  //To fetch Quote Line Item Id from parameter called from LWC
        List<Quote> quoteUnlockList;  //To fetch Unlocked records
        List<QuoteLineItem> qliRecordsList = new List<QuoteLineItem>(); //To update Quote Line Item
        
        
        if(Approval.isLocked(recordId)){ //Check whether the records are locked or not
            qliLockList = [SELECT Id,Status__c FROM QuoteLineItem WHERE QuoteId =: recordId];
        }
        
        
        //1.Unlock record
        if(!qliLockList.isEmpty()){
            List<Approval.UnlockResult> ulrList = Approval.unlock(qliLockList, false);
            
            
            for(Approval.UnlockResult  ulr : ulrList) {  // Iterate through each returned result to check whether records unlock were successful or not
                if (ulr.isSuccess()) {       //Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully unlocked account with ID: ' + ulr.getId());  
                }
                else { 
                    for(Database.Error err : ulr.getErrors()) {    //Operation failed, so get all errors 
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        } 
        
        //2.Fetching data from UI to update in database
        List<Object> records = (List<Object>)JSON.deserializeUntyped(qliRecords);
        Map<String, Map<String, Object>> recordMap = new Map<String, Map<String, Object>>(); 
        
        for (Object record : records) {
            Map<String,Object> recordFields = (Map<String,Object>)((Map<String, Object>)record).get('fields');   //Data is saved in fields array
            String id = (String)recordFields.get('Id');   //Data contains Id 
            recordMap.put(id, recordFields);     //Storing Id as String format
            qliId.add(id);   //Fetching Id for querying QLI records
        }
          
        //Fetch Quote Line Item with the help of qliId set variable
        Map<Id,QuoteLineItem> qliMap = new Map<Id,QuoteLineItem>([SELECT Id,Quantity,Discount__c,Distributor_Retention__c,Retailer_Retention__c,Quote.RecordType.DeveloperName 
                                                                  FROM QuoteLineItem 
                                                                  WHERE QuoteId=: recordId and Id IN : qliId]);
        
        //Locks HO Team user can update Quantity, Discount % ,Distributor Retention and Retailer Retention of QLI records
        for(QuoteLineItem qli : qliMap.values()){
            if(recordMap.containsKey(qli.Id)){
                Map<String, Object> record = recordMap.get(qli.Id);
                
                //Set Retail Retention value ,else set null
                String retailRetention = String.valueOf(record.get('Retailer_Retention__c'));
                if (record.containsKey('Retailer_Retention__c') && String.isNotEmpty(retailRetention)){
                    qli.Retailer_Retention__c = Double.valueOf(record.get('Retailer_Retention__c'));
                } 
                
                else if (record.containsKey('Retailer_Retention__c') && String.isEmpty(retailRetention) ){
                    qli.Retailer_Retention__c = null;
                } 
                
                
                //Set Distributor Retention value ,else set null
                String distributorRetention = String.valueOf(record.get('Distributor_Retention__c'));
                if (record.containsKey('Distributor_Retention__c') && String.isNotEmpty(distributorRetention)){
                    qli.Distributor_Retention__c = Double.valueOf(record.get('Distributor_Retention__c'));
                } 
                
                else if (record.containsKey('Distributor_Retention__c') && String.isEmpty(distributorRetention)){
                    qli.Distributor_Retention__c = null;
                } 
                
                //Set Quantity value ,else set null
                String quantity = String.valueOf(record.get('Quantity'));
                if (record.containsKey('Quantity') && String.isNotEmpty(quantity)){
                    qli.Quantity = Double.valueOf(record.get('Quantity'));
                }
                
                else if (record.containsKey('Quantity') && String.isEmpty(quantity) ){
                    qli.Quantity = null;
                } 
                
                //Set Discount value ,else set null
                String discount = String.valueOf(record.get('Discount__c'));
                if (record.containsKey('Discount__c') && String.isNotEmpty(discount)){
                    qli.Discount__c = Double.valueOf(record.get('Discount__c'));
                }
                
                else if (record.containsKey('Discount__c') && String.isEmpty(discount) ){
                    qli.Discount__c = null;
                }                 
                
                
                qliRecordsList.add(qli);
            }
        }
            
            if(!qliRecordsList.isEmpty() && qliRecordsList!=null){ //Update QLI
            try{
                update qliRecordsList;
            }
            catch(Exception e){
                Logger.logError('QLILockedRecordsPopulator', 'updateQuoteLineItemforLocksB2CISTD', '', e); 
                throw new AuraHandledException(e.getMessage());
            } 
        } 
        
        
        //3.Lock records
        if(Approval.isLocked(recordId)!=false){ //Check unlocked records
            quoteUnlockList = [SELECT Id FROM Quote WHERE Id =: recordId];
        }
        //Lock record
        if(!quoteUnlockList .isEmpty()){
            //lock records
            List<Approval.LockResult> lrList = Approval.lock(quoteUnlockList , false);
            
            // Iterate through each returned result
            for(Approval.LockResult  lr : lrList) {
                if (lr.isSuccess()) {
                    //Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully locked account with ID: ' + lr.getId());
                }
                else {
                    //Operation failed, so get all errors                
                    for(Database.Error err : lr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        
    
   } 
}