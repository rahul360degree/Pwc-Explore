/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to contain business logic for Product Trigger
Inputs:        NA
Test Class:    
History
23-04-2020      Kishor Kumar     Initial Release
08-06-2020      Kartik Shetty    Updated createStandardPriceBookEntry function.
----------------------------------------------------------------------------*/
public with sharing class ProductRecordProcessor {

    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to handle After Insert event context of Product Trigger
    Inputs:        map of created records
    Test Class:   

    History
    23-04-2020      Kishor Kumar     Initial Release
    08-06-2020      Kartik Shetty    Updated variable type from single record to list.
    ----------------------------------------------------------------------------*/
    public void createStandardPriceBookEntry(map<Id, Product2> productMap){
        list<PricebookEntry> pBEntriesToInsert = new list<PricebookEntry>();
        
        Utility util = new Utility();
        // Get the Standard Price Book ID
        List<Pricebook2> standardPriceBook = util.fetchStandardPriceBookDetail();
        
        if(standardPriceBook.size() > 0 ){
            //Check for already existing Std PB entry 
           map<Id, Boolean> productVsStdPBEntryMap = checkForStdPriceBookEntry(productMap.keySet(), standardPriceBook[0].Id);
           
            for(Id productId : productMap.keyset()){
                //Check if Product has already Active entry in Standard PriceBook
                if(productVsStdPBEntryMap.isEmpty() || 
                            (!productVsStdPBEntryMap.isEmpty() & !productVsStdPBEntryMap.containsKey(productId))){
                    PricebookEntry standardPriceBookEntry = new PricebookEntry();
                    standardPriceBookEntry.Pricebook2Id = standardPriceBook[0].Id;
                    standardPriceBookEntry.Product2Id = productId;
                    standardPriceBookEntry.UnitPrice = String.isNotBlank(productMap.get(productId).Sales_Price__c) ? Decimal.valueOf(productMap.get(productId).Sales_Price__c) : 1;
                    standardPriceBookEntry.UseStandardPrice = false;
                    standardPriceBookEntry.IsActive = true;
                                
                    pBEntriesToInsert.add(standardPriceBookEntry);
                }
            }
        }
        
        // Insert the Product in the Standard Price Book
        if(pBEntriesToInsert.size() > 0){
            try{
                insert pBEntriesToInsert;
            } catch(Exception ex){
            } 
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to check if Product has already active Standard PriceBook entry 
    Inputs:        set of Product Id & Standard PriceBook Id
    Test Class:   

    History
    23-04-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public map<Id, Boolean> checkForStdPriceBookEntry(set<Id> productIds, Id standardPriceBookId){
        map<Id, Boolean> productVsStdPBEntryMap = new map<Id, Boolean>();
        
        for(PricebookEntry pbEntry : [SELECT Id, Pricebook2Id, Product2Id, IsActive 
                                        FROM PricebookEntry 
                                        WHERE Product2Id IN : productIds 
                                        AND Pricebook2Id =: standardPriceBookId 
                                        AND IsActive = true]){
            productVsStdPBEntryMap.put(pbEntry.Product2Id, true);
        }
        
        return productVsStdPBEntryMap;
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit Shingavi
    Company:       Salesforce
    Description:   Method to toggle the product entry based on the blocked status
    Inputs:        List<Product2>
    Test Class:   

    History
    14-07-2020     Amit Shingavi     Initial Release
    ----------------------------------------------------------------------------*/
    public void deactivateblockedsignalItems(List<Product2> productLst){
        
        Set<String> blockedCodes = new Set<String>();
        
        //Custom Metadata to store the blocked signals
        for(Blocked_Item_Signals__mdt itr : [SELECT DeveloperName,
                                                     Label 
                                              FROM Blocked_Item_Signals__mdt LIMIT 49999]){
             blockedCodes.add(itr.DeveloperName);                                         
        }
        
        List<Product2> itemToUpdate = new List<Product2>();
        for(Product2 prdItr : ProductLst){
            if(String.isNotBlank(prdItr.Item_Signal__c) && blockedCodes.contains(prdItr.Item_Signal__c)){
                prdItr.IsActive = false;
            	//itemToUpdate.add(new Product2(Id = prdItr.Id, isActive = false));    
            }
            //Added here by Praful G - 20-Nov-2020
            else{
                prdItr.IsActive = true;
            }
        }
        //Nupoor : Critical Review - This should be run in before context
        //update itemToupdate;
    }
}