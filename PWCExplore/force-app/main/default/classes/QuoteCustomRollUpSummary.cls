/*------------------------------------------------------------------------
Author:        PANKAJ MESHRAM
Company:       GITL
Description:   Custom rollup summary for Quote(Calculate Sum and Max for MHE Equipments) 
Inputs:        List of Quote Line Items
Test Class:    qliRecordProcessorTest
History
04-04-2023     PANKAJ MESHRAM     Initial Release  
----------------------------------------------------------------------------*/
public class QuoteCustomRollUpSummary {
    List<Decimal> lstLeadTime = new List<Decimal>();
    List<Quote> lstQuote = new List<Quote>();
    List<Quote> lstQuoteRecords = new List<Quote>();
    Set<Id> QuoteIds = new Set<Id>();
    
    public void updateLeadTimeAndBomCost(List<QuoteLineItem> newItems){
        for(QuoteLineItem qliVar:newItems){
            if(qliVar.Quote_Record_Type__c== GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS){
                QuoteIds.add(qliVar.QuoteId);
            }
        }
        if(QuoteIds.size()>0){
            lstQuote = [Select id,Total_BOM_Cost__c,Record_Type_Developer_Name__c,Status,(Select id,QuoteId,product2.Lead_Time__c,product2.Bom_Cost__c,ListPrice,quote.Lead_Time__c,quote.Total_BOM_Cost__c,UnitPrice,Quantity from QuoteLineItems) from Quote where id IN:QuoteIds];
        }
        for(Quote quoteVar:lstQuote){
            if(quoteVar.Status != GlobalConstants.QUOTE_STATUS_FINALIZED && quoteVar.Record_Type_Developer_Name__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS){               
                Decimal sumOfValues = 0.00;
                for(QuoteLineItem qliVar:quoteVar.QuoteLineItems){
                    lstLeadTime.add(qliVar.product2.Lead_Time__c);

                    //Calculate Sum(Total BOM Cost) based on BOM Cost available on produts
                    if(qliVar.ListPrice > 0 && qliVar.product2.Bom_Cost__c != Null)
                        sumOfValues+= (qliVar.product2.Bom_Cost__c*qliVar.Quantity);
                    else if((qliVar.ListPrice == 0 || qliVar.ListPrice == Null) && qliVar.UnitPrice != Null)
                        sumOfValues+= (qliVar.UnitPrice * qliVar.Quantity);
                }
                
                //Calculate Max Lead Time based on lead time available on produts
                Decimal maxValue = lstLeadTime[0];
                for(integer i =0;i<lstLeadTime.size();i++){                    
                    if(lstLeadTime[i] > maxValue)
                        maxValue = lstLeadTime[i];             
                }        
                quoteVar.Total_BOM_Cost__c = sumOfValues;
                quoteVar.Lead_Time__c = maxValue;
                lstQuoteRecords.add(quoteVar);
            }
        }
        if(lstQuoteRecords.size()>0){
            try{
                update lstQuoteRecords;
            }catch(Exception ex){
                logger.logError('QuoteCustomRollUpSummary', 'updateLeadTimeAndBomCost','', ex);                
            }
        }
    }
}