/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
Description:   Handler class for ISOB/Order generate for SSG
Inputs:        RecordIds (Quote and Order)
Test Class:    
History
11-09-2023      Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
public class IsobController {

    /*------------------------------------------------------------------------
    Author:        Pankaj Meshram
    Company:       GITL
    Description:   Method for getting order specification Id
    Inputs:        OrderId    
    ----------------------------------------------------------------------------*/
    @AuraEnabled(cacheable=true)
    public static String getOrderSpecificationDetails(Id OrderId){
        String osId;
        Order_Specification__c osObj =  [select Id from Order_Specification__c where Order__c =:OrderId];        
        osId = osObj.id;
        return osId;
    }
    
    /*------------------------------------------------------------------------
    Author:        Pankaj Meshram
    Company:       GITL
    Description:   Method for getting order specification Id
    Inputs:        OrderId    
    ----------------------------------------------------------------------------*/    
    @AuraEnabled(cacheable=true)
    public static Order_Specification__c getProductSpecifications(String recordId){ 
        String firstCharacters = recordId.substring(0,2);
		if(firstCharacters=='0Q')        
        	return [select Id,Product_Attribute__c from Order_Specification__c where Quote__c =:recordId]; 
		else 
            return [select Id,Product_Attribute__c from Order_Specification__c where order__c =:recordId];
    }
    
     /*------------------------------------------------------------------------
    Author:        Pankaj Meshram
    Company:       GITL
    Description:   Method to fetch JSON objects from product and merge all Json
				   Object into the array and store in Product_Attribute__c on Order_Specification__c
    Inputs:        OrderId    
    ----------------------------------------------------------------------------*/    
    @InvocableMethod
    public static void jsonMerger(List<Id> recordId){
        List<Id> lstProductIds = new List<Id>();
        String jsonStr= '';
        integer iterationCounter= 0;
        List<QuoteLineItem> lstQlis = [select id,product2.id from QuoteLineItem where QuoteId IN:recordId];
        if(lstQlis.size()>0 && lstQlis!= null){
            for(QuoteLineItem qli:lstQlis){
                lstProductIds.add(qli.product2.id);
            }      
        }

        List<product2> lstProdRecords = [select id,product_attribute__c from product2 where id IN: lstProductIds];
        integer totalNumberOfProduct = lstProdRecords.size();
        if(lstProdRecords.size() > 0 && lstProdRecords != null){
            for(product2 prod:lstProdRecords){   
                iterationCounter += 1;
                jsonStr += prod.product_attribute__c;
                if(totalNumberOfProduct != iterationCounter){
                    jsonStr += ',';
                }else{
                    jsonStr = '['+jsonStr + ']'; 
                }
            }
            List<Order_Specification__c> lstOrderSP= [select Id,Product_Attribute__c from Order_Specification__c where Quote__c IN: recordId];
            if(lstOrderSP.size() > 0){
				for(Order_Specification__c osObj:lstOrderSP){
                	osObj.Product_Attribute__c = jsonStr;
            	}
                try{
           			update lstOrderSP;   
                }
                catch(DmlException e){
                    
                }
            }
            
        }
    }

     /*------------------------------------------------------------------------
    Author:        Pankaj Meshram
    Company:       GITL
    Description:   Method to update Product_Attribute__c on Order_Specification__c
    Inputs:        jsonString    
    ----------------------------------------------------------------------------*/    
    @AuraEnabled
    public static void updateJsonField(String recordId,string jsonString){
        system.debug('test lwc');
        //Map<String,Object> updatedData = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        Order_Specification__c osObj = [select Id,Product_Attribute__c from Order_Specification__c where Quote__c=:recordId];
        osObj.Product_Attribute__c = jsonString;//JSON.serialize(updatedData);
        try{
            update osObj;
        }
        catch(DmlException e){
            
        }
    }
}