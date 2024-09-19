/*------------------------------------------------------------------------
    Author:        Varun Rajpoot & Anupam Mishra
    Company:       GITL
    Description:   Controller class for AddOpportunityProduct
    last modified on: 03-11-2022
     ----------------------------------------------------------------------------*/
public with sharing class AddOpportunityProductHelper {
    
    
   /*------------------------------------------------------------------------
    Author:        Varun Rajpoot & Anupam Mishra
    Company:       GITL
    Description:   Method to fetch landed Rates for the added products
    ----------------------------------------------------------------------------*/
    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Landed_Rate__c> fetchLandedRate(Id recordId,String query){
        recordId = String.escapeSingleQuotes(recordId);
        query=query+' from Opportunity_Landed_Rate__c where Related_Opportunity__c= \''+recordId+'\'   ';
        return Database.query(query);
    }
    
  /*------------------------------------------------------------------------
    Author:        Varun Rajpoot & Anupam Mishra
    Company:       GITL
    Description:   Method to get productList form Customer Master metadata
    ----------------------------------------------------------------------------*/
    
    @AuraEnabled
    public static List<Construction_master_product__mdt> getProdList(){
        try {
            return [select DeveloperName, Default_Price__c, GST__c, Label, Product_Sequence__c from Construction_master_product__mdt  Limit 500];		//Product_Sequence__c added by Poonam for SCF - 102
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
   /*------------------------------------------------------------------------
    Author:        Varun Rajpoot & Anupam Mishra
    Company:       GITL
    Description:   Method to upsert  Opportunity and Line Items  records
    ----------------------------------------------------------------------------*/
    
    @AuraEnabled
    public static String upsertReecord(List<Opportunity_Landed_Rate__c> landedRecords,Id opportunityId){
        
        try { 
            List<string> prodList = new List<string>();                           
            upsert landedRecords; 
            Map<string, decimal> OLRrecordmap = new Map<string, decimal>();
            for(Opportunity_Landed_Rate__c OLR: LandedRecords){
                OLRrecordmap.put(OLR.Name,OLR.Landed_rate__c);                  
            }
            set<opportunity>opptyList= new set<Opportunity>();
            set<string> OLRrecords =OLRrecordmap.keyset();
            List<OpportunityLineItem> oLIs =[select Id,OpportunityId,Type__c, UnitPrice,C_GST__c,S_GST__c,Product2Id,Product2.Tax_Rate__c,
                                             Product2.Type__c,Product2.Volume__c  from OpportunityLineItem where Type__c In:OLRrecords and OpportunityId =:opportunityId];
            if(OLRrecordmap.containsKey(GlobalConstants.TUFF_ACC_Block_Landed_Rate)){    
                Opportunity opportunity = new opportunity(Id=opportunityId);            
                opportunity= SalesAmountAndBasicRateCalculation.BasicRatePerCbm_TuffAACBlock(GlobalConstants.TUFF_ACC_Block_Landed_Rate,
                                                                                             OLRrecordmap.get(GlobalConstants.TUFF_ACC_Block_Landed_Rate),
                                                                                             opportunity);
                update opportunity;
            }
            
            if(!oLIs.isEmpty()){
                for(OpportunityLIneItem oLI :oLIs){               
                    decimal landedRate = OLRrecordmap.get(oLI.Product2.Type__c);
                    if(oLI.Type__c==GlobalConstants.TUFF_ACC_Block_Landed_Rate){
                        Opportunity opportunity = new Opportunity(Id =oLI .OpportunityId);
                        if(landedRate != null){
                            SalesAmountAndBasicRateCalculation.BasicRatePerUnit_TuffAccBlock(oLI,landedRate,oLI.Product2.Tax_rate__c,oLI.Product2.Volume__c);
                            SalesAmountAndBasicRateCalculation.BasicRatePerCbm_TuffAACBlock(GlobalConstants.TUFF_ACC_Block_Landed_Rate,
                                                                                             landedRate,opportunity);
                        }
                    }
                    else if(oLI.Type__c==GlobalConstants.TUFF_Duroplast_Landed_Rate || oLI.Type__c==GlobalConstants.TUFF_Easy_Fix_Landed_Rate || oLI.Type__c== GlobalConstants.Broken_Blocks  || oLI.Type__c== GlobalConstants.TUFF_TILE_FIX_PREMIUM_20_KG ||
                           oLI.Type__c== GlobalConstants.TUFF_TILEFIX_PREMIUM_40_KG || oLI.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_20_KG || oLI.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_40_KG || 
                           oLI.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_20_KG || oLI.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_40_KG){               //Added condition for Tilefix product (SCF - 102)
                        SalesAmountAndBasicRateCalculation.BasicRate_AAC_WPS(oLI,landedRate,oLI.Product2.Tax_rate__c);
                    } 
                }      
                update oLIs;
                
            }    
            return 'Success';
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
    
}