/*------------------------------------------------------------------------
     Author:        Varun Rajpoot & Anupam Mishra
     Company:       GITL
     Description:   Class to calculate Sales Amount and Sales Price on opportunity products.
    ----------------------------------------------------------------------------*/
public without sharing class SalesAmountAndBasicRateCalculation{
    
    public static Opportunity BasicRatePerCbm_TuffAACBlock (String landedRateType, Decimal landedRate, Opportunity opportunity){       
        Product2 product = [Select Id,Tax_Rate__c from Product2 where Type__c=:landedRateType limit 1];       
        if(product<>null){
                opportunity.Basic_Rate_Per_CBM__c = landedRate /((product.Tax_Rate__c + 100)/100);
       }
        return opportunity;
    }
    
    public static OpportunityLineItem BasicRatePerUnit_TuffAccBlock (OpportunityLineItem OLIRecord, Decimal LandedRate, decimal TaxRate, decimal volume){       
        OLIRecord.Basic_Rate_Per_Unit__c = LandedRate/((volume * (TaxRate + 100)/100));
        return OLIRecord;
    }
    
    public static OpportunityLineItem  BasicRate_AAC_WPS (OpportunityLineItem OLIrecord, Decimal LandedRate, decimal TaxRate){      
        
        OLIRecord.UnitPrice =LandedRate /((TaxRate + 100)/100);  
        return OLIRecord;
    }
    
    public static OpportunityLineItem  SalesAmountTuff_RMC_RCM (OpportunityLineItem OLIRecord, Decimal SalesPrice, decimal Taxrate, decimal Qty){
        OLIRecord.Sales_Amount__c =SalesPrice*Qty*((TaxRate + 100)/100);
        return OLIRecord;
    }  
    
}