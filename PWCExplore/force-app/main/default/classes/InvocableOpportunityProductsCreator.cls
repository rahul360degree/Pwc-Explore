/*------------------------------------------------------------------------------------
Author :       Santosh Jahagirdar
Company:       GITL
Description:   class which invoke by flow to create Auto Renewal Opportunity Products 
Test Class:    InvocableOpportunityProductsCreatorTest 
---------------------------------------------------------------------------------------*/
global class InvocableOpportunityProductsCreator {

    @InvocableMethod(label='Create Opportunity Products for Renewal Opportunities' description='Used to Create Opportunity Products for Renewal Opportunities') 
    global static void createOpportunityProducts(List<List<Opportunity>> lstOpps){
    
    String mheContractsPriceBookName = 'MHE Contracts PL';    
    Map<Id, Id> mapOpptyServiceContract = new Map<Id, Id>();
    Map<Id, Double> mapPriceBookEntry = new Map<Id, Double>();
    List<String> lstServiceContractIDs = new List<String>();
    
    for (Opportunity opp: lstOpps[0]) {
        mapOpptyServiceContract.put(opp.Previous_Service_Contract__c, opp.Id);
        lstServiceContractIDs.add(opp.Previous_Service_Contract__c);
    }
    
    List<PriceBookEntry> lstPBE = new List<PriceBookEntry>([Select Id, Name, UnitPrice, PriceBook2Id, Product2Id, 
                                                                    Product2.ProductCode, Product2.Item_Code__c
                                                                    From PriceBookEntry  Where                                                                    
                                                                    IsActive = TRUE  And
                                                                    PriceBook2.Name = :mheContractsPriceBookName]);
    for(PriceBookEntry pbe : lstPBE) {
        mapPriceBookEntry.put(pbe.Product2Id, pbe.UnitPrice);
    }


    List<OpportunityLineItem> lstOpptyProducts = new List<OpportunityLineItem>();
    
    for(ContractLineItem cLine : [ 
    
            SELECT id, product2id, servicecontractid, servicecontract.startdate, servicecontract.enddate,
            unitprice, product2.Is_Generic_Product__c  
            FROM ContractLineItem where ServiceContractId in :lstServiceContractIDs and 
            product2.isactive = TRUE 
            order by ServiceContractId, Configuration_Line_Number__c  
             
        ]) {
                
            OpportunityLineItem oppProduct = new OpportunityLineItem();
            oppProduct.OpportunityId = mapOpptyServiceContract.get(cLine.servicecontractid);
            oppProduct.Product2Id = cLine.Product2Id;
            oppProduct.Quantity = 1;
        
        if (cLine.product2.Is_Generic_Product__c){
            oppProduct.UnitPrice = cLine.UnitPrice;
        }
        
        else {
            oppProduct.UnitPrice = mapPriceBookEntry.get(cLine.Product2Id);
        }
        
            oppProduct.Previous_Contract_Line_Item__c = cLine.Id;   
            lstOpptyProducts.add(oppProduct);
        }
    
        insert lstOpptyProducts;
    
    }
    
}