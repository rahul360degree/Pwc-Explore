/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Processor class for 'Quote Line Item' Records
Inputs:        NA
Test Class:    
History
08-04-2020      Kishor Kumar     Initial Release
10-04-2020      Subhojit Chakraborty    Updated Amount Calculation 
10-06-2020      Kartik Shetty     Added method to update Asset Serial Number.
12-06-2020      Kartik Shetty     Added method to populate contract related fields in QLI.
----------------------------------------------------------------------------*/
public with sharing class QLIRecordProcessor {
    private static Map<Id, Quote> quoteRecordMap = new Map<Id, Quote>();
    
    /*------------------------------------------------------------------------
Author:        Subhojit
Company:       Salesforce
Description:   Method to set Approval category
Inputs:        NA
Test Class:    
History
11-04-2020      Subhojit     Initial Release
----------------------------------------------------------------------------*/
    public void setProductLineApprovalType(list<QuoteLineItem> newQLIRecords){
        Set<Id> setProductCode=new Set<Id>();
        Map<Id,Product2> mapProduct=new Map<Id,Product2>();
        Map<String,String> mapProductLine=new Map<String,String>();
        List<String> lstPL=new List<String>();
        Map<String,String> mapProductLineToAppType=new Map<String,String>();
        
        for(QuoteLineItem prVar: newQLIRecords){
            if(prVar.Product2Id!=null)
                setProductCode.add(prVar.Product2Id);
            lstPL.add(prVar.Product_Type__c);
        }
        mapProduct=new Map<Id,Product2>([select Id,Product_Line__c, Product_Class__c  from Product2 where Id IN :setProductCode]);
        
        for(Product2 prdVar: mapProduct.values()){
            mapProductLine.put(prdVar.Id,prdVar.Product_Class__c);
        }
        if(mapProductLine.size()>0)
            lstPL.addAll(mapProductLine.values());
        
        List<Product_Line_To_Category_Mapping__mdt> lstProductcategory=[select Id,Developername,Record_Type__c,Related_Approval_Category__c 
                                                                        from Product_Line_To_Category_Mapping__mdt 
                                                                        where Developername IN :lstPL];
        
        for(Product_Line_To_Category_Mapping__mdt categoryVar:lstProductcategory ){
            mapProductLineToAppType.put(categoryVar.DeveloperName,categoryVar.Related_Approval_Category__c);
        }                                                              
        
        for(QuoteLineItem QLVar: newQLIRecords){
            if(QLVar.Product2Id!=null && mapProductLine.containsKey(QLVar.Product2Id)){
                if(mapProductLineToAppType.containsKey(mapProductLine.get(QLVar.Product2Id))){
                    Qlvar.Approval_Product_Line__c=mapProductLineToAppType.get(mapProductLine.get(QLVar.Product2Id));
                }
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Subhojit
Company:       Salesforce
Description:   Method to add pricebook for Kitchen File upload Scenario
Inputs:        NA
Test Class:    
History
11-04-2020      Subhojit     Initial Release
----------------------------------------------------------------------------*/
    public void setPriceBookForKitchenFileUpload(list<QuoteLineItem> newQLIRecords){
        Set<String> setProduct=new Set<String>();
        Set<String> setQuoteId=new Set<String>();
        Set<String> setPB=new Set<String>();
        List<Quote> lstQuote=new List<Quote>();
        Map<String,Id> mapPRB=new Map<String,Id>();
        Map<Id,Map<String,String>> mapPricebook=new Map<Id,Map<String,String>> ();
        map<Id,Id> mapQotePriceBook=new map<Id,Id>();
        
        for(QuoteLineItem qlVar: newQLIRecords) {
            if(qlVar.Product2Id==null){
                setProduct.add(qlVar.Item__c);
                setQuoteId.add(qlVar.QuoteId);
            }  
        }
        
        lstQuote=[select Id,Opportunity.Pricebook2Id from Quote where Id IN :setQuoteId];
        if(lstQuote.size()==0)
            return;
        for(Quote qouteVar: lstQuote){
            setPB.add(qouteVar.Opportunity.Pricebook2Id);
            mapQotePriceBook.put(qouteVar.Id,qouteVar.Opportunity.Pricebook2Id);
        } 
        
        Map<Id,PricebookEntry> mapPB=new map<Id,PricebookEntry>([select Id,pricebook2Id,product2Id,Product2.Item__c,UnitPrice from PricebookEntry 
                                                                 where Product2.Item__c IN :setProduct  and pricebook2Id IN :setPB]);
        
        for(PricebookEntry pbEntry: mapPB.values()){
            Map<String,String> mapprdPBProduct = new Map<String,String>();
            if(mapPricebook.containsKey(pbEntry.pricebook2Id))
                mapprdPBProduct=mapPricebook.get(pbEntry.pricebook2Id);
            mapprdPBProduct.put(pbEntry.product2Id,pbEntry.Id);
            mapPRB.put(pbEntry.Product2.Item__c,pbEntry.product2Id);
            mapPricebook.put(pbEntry.pricebook2Id,mapprdPBProduct);
        }
        for(QuoteLineItem qlVar: newQLIRecords) {
            if(qlVar.Item__c!=null && mapPRB.containskey(qlVar.Item__c)){
                qlVar.product2Id=mapPRB.get(qlVar.Item__c);
                Id PBId=mapQotePriceBook.get(qlvar.QuoteId);
                if(mapPricebook.containsKey(pbId)){
                    Map<String,String> mapTemp=mapPricebook.get(pbId);
                    qlVar.PricebookEntryId=mapTemp.get(qlVar.product2Id);
                    qlVar.UnitPrice=(qlVar.UnitPrice==null)?mapPB.get(qlVar.PricebookEntryId).Unitprice:qlVar.UnitPrice;
                }
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate 'Pricing Approval Request' record Id 
associated with Parent Quote
Inputs:        NA
Test Class:    
History
11-04-2020      Kishor     Initial Release
----------------------------------------------------------------------------*/
    public void updatePricingApprovalRequestId(list<QuoteLineItem> newQLIRecords){
        set<Id> prentQuoteIds = new set<Id>();
        map<Id, Id> quoteIdVsParId = new map<Id, Id>();
        
        for(QuoteLineItem qli : newQLIRecords){
            if(qli.QuoteId!=null)
                prentQuoteIds.add(qli.QuoteId);
        }
        
        for(Pricing_approval_request__c par : [SELECT Id, Quote__c
                                               FROM Pricing_approval_request__c 
                                               WHERE Id IN : prentQuoteIds]){
                                                   quoteIdVsParId.put(par.Quote__c, par.Id);
                                               }
        
        for(QuoteLineItem qlitem : newQLIRecords){
            if(!quoteIdVsParId.isEmpty() && quoteIdVsParId.containsKey(qlitem.QuoteId))
                qlitem.Pricing_Approval_Request_Id__c = quoteIdVsParId.get(qlitem.QuoteId);
        }
    } 
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Method to update sequence number which will be used for approval of quote
Inputs:        NA
Test Class:    
History
10-04-2020      Pawan     Initial Release
----------------------------------------------------------------------------*/
    public void updateSequence(List<QuoteLineItem> newQLIRecords,Map<Id,QuoteLineItem>  oldQLIRecords,String contextVariable){
        
        //Added by Shreela on 4th Nov for SAEPB - 44
        Set<Id> qId=new Set<Id>();
        for(QuoteLineItem qlVar: newQLIRecords) {
            qId.add(qlVar.QuoteId);
        }
        
        Map<Id,Quote> qObj = new Map<Id,Quote>([SELECT Id,CreatedDate,Last_Approved_Date__c,Opportunity.Sub_Division__c
                                                FROM Quote
                                                WHERE Id IN :qId
                                                AND Opportunity.Sub_Division__c = : GlobalConstants.B2B_SUBDIVISION]);
        
        //Ended by Shreela on 4th Nov for SAEPB - 44
        for(QuoteLineItem QLIVar: newQLIRecords ){
            if(contextVariable == GlobalConstants.Context_Variable_Before) { //Added this line by Shreela 
                if(QLIVar.Requested_Customer_Discount__c != null){
                    if(QLIVar.Quote_Record_Type__c == System.Label.Interio_B2B_APO_recordtype || QLIVar.Quote_Record_Type__c == System.Label.Interio_B2B_Finished_Good_rectype){
                        if(QLIVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER){
                            if(String.isNotBlank(System.Label.B2B_RCD_V1) && String.isNotBlank(System.Label.B2B_RCD_V2)
                               && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V1) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V2)
                               && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1)  
                               && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else if(String.isNotBlank(System.Label.B2B_RCD_V2) && String.isNotBlank(System.Label.B2B_RCD_V3)
                                        && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V2) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V3)
                                        && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1) 
                                        && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                            QLIVar.Sequence__c = 2;
                                        }else if(String.isNotBlank(System.Label.B2B_RCD_V3) && String.isNotBlank(System.Label.B2B_RCD_V4)
                                                 && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                                 && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V3) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V4)
                                                 && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1) 
                                                 && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                                     QLIVar.Sequence__c = 3;
                                                 }else if(String.isNotBlank(System.Label.B2B_RCD_V4) && String.isNotBlank(System.Label.B2B_RCD_V5)
                                                          && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                                          && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V4) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V5)
                                                          && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1)
                                                          && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                                              QLIVar.Sequence__c = 4;
                                                          }else if(String.isNotBlank(System.Label.B2B_RCD_V5)
                                                                   && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                                                   && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V5)
                                                                   && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1)  
                                                                   && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                                                       QLIVar.Sequence__c = 5;
                                                                   }else{
                                                                       QLIVar.Sequence__c = 0;
                                                                   }
                        }else if(QLIVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_WITH_ORC_TO_DEALER){
                            if(String.isNotBlank(System.Label.B2B_RCD_V1) && String.isNotBlank(System.Label.B2B_RCD_V6) 
                               && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RSAC_V1)
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V1) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V6)
                               && QLIVar.Requested_WD_Retention__c == Decimal.valueOf(System.Label.B2B_RWD_V1) 
                               && QLIVar.Requested_SAC_ORC__c > Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else{
                                   QLIVar.Sequence__c = 0;
                               }
                        }else if(QLIVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES){
                            if(String.isNotBlank(System.Label.B2B_RCD_V3) && String.isNotBlank(System.Label.B2B_RCD_V4) 
                               && String.isNotBlank(System.Label.B2B_RWD_V2) && String.isNotBlank(System.Label.B2B_RWD_V3) 
                               && String.isNotBlank(System.Label.B2B_RSAC_V1)
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V3) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V4)
                               && QLIVar.Requested_WD_Retention__c > Decimal.valueOf(System.Label.B2B_RWD_V2) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V3)
                               && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else if(String.isNotBlank(System.Label.B2B_RCD_V4) 
                                        && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                                        && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V4)
                                        && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                                        && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                            QLIVar.Sequence__c = 2;
                                        }else if(String.isNotBlank(System.Label.B2B_RCD_V4) 
                                                 && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                                                 && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                                 && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V4)
                                                 && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                                                 && QLIVar.Requested_SAC_ORC__c > Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                                     QLIVar.Sequence__c = 3;
                                                 }else{
                                                     QLIVar.Sequence__c = 0;
                                                 }                        
                        }else if(QLIVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER_PRIMARY_WITH_SCHEME){
                            if(String.isNotBlank(System.Label.B2B_RCD_V7) && String.isNotBlank(System.Label.B2B_RCD_V4)
                               && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                               && String.isNotBlank(System.Label.B2B_RSAC_V1)
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V7) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V4)
                               && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                               && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else if(String.isNotBlank(System.Label.B2B_RCD_V7) && String.isNotBlank(System.Label.B2B_RCD_V6)
                                        && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                                        && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V7) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V6)
                                        && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                                        && QLIVar.Requested_SAC_ORC__c >= Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                            QLIVar.Sequence__c = 2;
                                        }else{
                                            QLIVar.Sequence__c = 0;
                                        }                        
                        }else if(QLIVar.Order_Type__c == GlobalConstants.BILLING_TO_DEALER_WITH_ADDITIONAL_DISCOUNT){
                            if(String.isNotBlank(System.Label.B2B_RCD_V7) && String.isNotBlank(System.Label.B2B_RCD_V4)
                               && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                               && String.isNotBlank(System.Label.B2B_RSAC_V1)
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V7) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V4)
                               && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                               && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else if(String.isNotBlank(System.Label.B2B_RCD_V7) && String.isNotBlank(System.Label.B2B_RCD_V6)
                                        && String.isNotBlank(System.Label.B2B_RWD_V4) && String.isNotBlank(System.Label.B2B_RWD_V5)
                                        && String.isNotBlank(System.Label.B2B_RSAC_V1)
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V7) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V6)
                                        && QLIVar.Requested_WD_Retention__c >= Decimal.valueOf(System.Label.B2B_RWD_V4) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V5)
                                        && QLIVar.Requested_SAC_ORC__c >= Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                            QLIVar.Sequence__c = 2;
                                        }else{
                                            QLIVar.Sequence__c = 0;
                                        }                        
                        }else if(QLIVar.Order_Type__c == GlobalConstants.DIRECT_BILLING_TO_DEALER_WITH_NO_DISCOUNT){
                            if(String.isNotBlank(System.Label.B2B_RCD_V1) && String.isNotBlank(System.Label.B2B_RCD_V8)  
                               && String.isNotBlank(System.Label.B2B_RWD_V1) && String.isNotBlank(System.Label.B2B_RWD_V6)
                               && String.isNotBlank(System.Label.B2B_RSAC_V1) 
                               && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.B2B_RCD_V1) && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.B2B_RCD_V8)
                               && QLIVar.Requested_WD_Retention__c > Decimal.valueOf(System.Label.B2B_RWD_V1) && QLIVar.Requested_WD_Retention__c <= Decimal.valueOf(System.Label.B2B_RWD_V6)
                               && QLIVar.Requested_SAC_ORC__c == Decimal.valueOf(System.Label.B2B_RSAC_V1)){
                                   QLIVar.Sequence__c = 1;
                               }else{
                                   QLIVar.Sequence__c = 0;
                               }                        
                        }
                    }else if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS //Modified condition for MHE Equipment by Shreela on 6th Dec 2023 for SMEPB 111
                             && (QLIVar.Product_Storage_Clasification__c == Decimal.valueof(1) || QLIVar.Product_Storage_Clasification__c == Decimal.valueof(2))){
                                 if(QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_PRIMARY || QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                                     if((String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MIN_V1) && String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V1))
                                        && (QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MIN_V1)) 
                                        && (QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V1))
										){
                                                QLIVar.Sequence__c = 1;
                                        }else if((String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V1) && String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V2))
                                                 && (QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V1)) 
                                                 && (QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V2))
                                                 ){
                                                     QLIVar.Sequence__c = 2;
                                                 }else if((String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V2) && String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V3))
                                                          && (QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V2))
                                                          && (QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V3))
                                                          ){
                                                              QLIVar.Sequence__c = 3;
                                                          }else if ((String.isNotBlank(System.Label.MHE_PRIMARY_ORDER_MAX_V3))
                                                                    && (QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PRIMARY_ORDER_MAX_V3))
                                                                     ) {
                                                                        QLIVar.Sequence__c = 4;
                                                                    }else{
                                                                        QLIVar.Sequence__c = 0;
                                                                    }
                                 } //Modified by adding conditon for secondary for MHE Equipment -end by Shreela on 8th Dec 2023 for SMEPB 111
                             }else if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS){
                                 if(QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_PRIMARY){
                                     if(String.isNotBlank(System.Label.MHE_PARTS_PRIMARY_MIN_V1) 
                                        && String.isNotBlank(System.Label.MHE_PARTS_PRIMARY_MIN_V2) 
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_PRIMARY_MIN_V1) 
                                        && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_PARTS_PRIMARY_MIN_V2)){
                                            QLIVar.Sequence__c = 1;
                                        }else if(String.isNotBlank(System.Label.MHE_PARTS_PRIMARY_MIN_V2) 
                                                 && String.isNotBlank(System.Label.MHE_PARTS_PRIMARY_MIN_V3)
                                                 && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_PRIMARY_MIN_V2) 
                                                 && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_PARTS_PRIMARY_MIN_V3)){
                                                     QLIVar.Sequence__c = 2;
                                                 }else if(String.isNotBlank(System.Label.MHE_PARTS_PRIMARY_MIN_V3) 
                                                          && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_PRIMARY_MIN_V3)){
                                                              QLIVar.Sequence__c = 3;
                                                          }else{
                                                              QLIVar.Sequence__c = 0;
                                                          }                        
                                 }else if(QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                                     if(String.isNotBlank(System.Label.MHE_PARTS_RDD_V1) && String.isNotBlank(System.Label.MHE_PARTS_RDD_V2)
                                        && QLIVar.Requested_Dealer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_RDD_V1) 
                                        && QLIVar.Requested_Dealer_Discount__c <= Decimal.valueOf(System.Label.MHE_PARTS_RDD_V2)){
                                            QLIVar.Sequence__c = 1;
                                        }else if(String.isNotBlank(System.Label.MHE_PARTS_RDD_V2) && String.isNotBlank(System.Label.MHE_PARTS_RDD_V3)
                                                 && QLIVar.Requested_Dealer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_RDD_V2) 
                                                 && QLIVar.Requested_Dealer_Discount__c <= Decimal.valueOf(System.Label.MHE_PARTS_RDD_V3)){
                                                     QLIVar.Sequence__c = 2;
                                                 }else if(String.isNotBlank(System.Label.MHE_PARTS_RDD_V3)
                                                          && QLIVar.Requested_Dealer_Discount__c > Decimal.valueOf(System.Label.MHE_PARTS_RDD_V3)){
                                                              QLIVar.Sequence__c = 3;
                                                          }else{
                                                              QLIVar.Sequence__c = 0;
                                                          }
                                 }
                             }else if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_CONTRACTS){ //SMEPB - 130 Removed chk for Primary to enable discount for MHE Contract Dealers 
                                 if(String.isNotBlank(System.Label.MHE_CONTRACTS_DISCOUNT_V1) 
                                    && String.isNotBlank(System.Label.MHE_CONTRACTS_DISCOUNT_V2) 
                                    && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CONTRACTS_DISCOUNT_V1) 
                                    && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CONTRACTS_DISCOUNT_V2)){
                                        QLIVar.Sequence__c = 1;
                                    }else if(String.isNotBlank(System.Label.MHE_CONTRACTS_DISCOUNT_V2) 
                                             && String.isNotBlank(System.Label.MHE_CONTRACTS_DISCOUNT_V3)
                                             && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CONTRACTS_DISCOUNT_V2) 
                                             && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CONTRACTS_DISCOUNT_V3)){
                                                 QLIVar.Sequence__c = 2;
                                             }else if(String.isNotBlank(System.Label.MHE_CONTRACTS_DISCOUNT_V4) 
                                                      && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CONTRACTS_DISCOUNT_V4)){
                                                          QLIVar.Sequence__c = 3;
                                                      }else{
                                                          QLIVar.Sequence__c = 0;
                                                      }                        
                             }
                    
                }
                
                if (QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME) {
                    if (QLIVar.Price_Difference__c > 5 && QLIVar.Price_Difference__c <= 10) {
                        QLIVar.Sequence__c = 1;
                    } else if (QLIVar.Price_Difference__c > 10 && QLIVar.Price_Difference__c <= 15) {
                        QLIVar.Sequence__c = 2;
                    } else if (QLIVar.Price_Difference__c > 15) {
                        QLIVar.Sequence__c = 3;
                    } else {
                        QLIVar.Sequence__c = 0;
                    }
                }
            }      
            
            //Added by Shreela on 1st November 2022 for SAEPB - 44
            try{ //Added try catch on 23rd November 2022
                if(contextVariable == GlobalConstants.Context_Variable_Before) {                
                    Integer noOfDays;
                    if(qObj.size()>0){  //Added this line to avoid Attempt to deference null object by Shreela on 19th January 2023
                        if(QLIVar.QuoteId == qObj.get(QLIVar.QuoteId).Id 
                           && qObj.get(QLIVar.QuoteId).Last_Approved_Date__c!=null){
                               noOfDays = qObj.get(QLIVar.QuoteId).Last_Approved_Date__c.date().daysBetween(System.today()); //To find no of days betwwen Last Approved Date and Today
                           }
                    }
                    Decimal custDiscRounded;
                    if(QLIVar.Requested_Customer_Discount__c!=null)
                        custDiscRounded  = QLIVar.Requested_Customer_Discount__c.setScale(1);
                    
                    Decimal oldcustDiscRounded;
                    if( oldQLIRecords!=null && oldQLIRecords.get(QLIVar.Id).Requested_Customer_Discount__c!=null)                 
                        oldcustDiscRounded = oldQLIRecords.get(QLIVar.Id).Requested_Customer_Discount__c.setScale(1);                               
                    
                    if(qObj.size()>0){  //Added this line to avoid Attempt to deference null object by Shreela on 19th January 2023
                        if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE && qObj.get(QLIVar.QuoteId).Opportunity.Sub_Division__c == GlobalConstants.B2B_SUBDIVISION){
                            
                            if(custDiscRounded > GlobalConstants.Req_Cust_Disc_Value_1 && custDiscRounded <=  GlobalConstants.Req_Cust_Disc_Value_2 && 
                               QLIVar.Payment_Terms__c != GlobalConstants.PAYMENT_MODE_OTHERS  && QLIVar.Payment_Terms__c != GlobalConstants.Payment_Terms_Value_Adv_Payment &&
                               (noOfDays==null || noOfDays<= GlobalConstants.No_of_Days_Check) 
                               && (custDiscRounded != oldcustDiscRounded )){                          
                                   QLIVar.Sequence__c = 1;
                               }
                            else if((custDiscRounded > GlobalConstants.Req_Cust_Disc_Value_2 && custDiscRounded <=  GlobalConstants.Req_Cust_Disc_Value_3 && 
                                     QLIVar.Payment_Terms__c != GlobalConstants.PAYMENT_MODE_OTHERS && QLIVar.Payment_Terms__c != GlobalConstants.Payment_Terms_Value_Adv_Payment &&
                                     (noOfDays==null || noOfDays<=GlobalConstants.No_of_Days_Check) 
                                     && (custDiscRounded != oldcustDiscRounded )) ||
                                    (QLIVar.Payment_Terms__c == GlobalConstants.Payment_Terms_Value_Within_7_Days && (noOfDays==null || noOfDays<=GlobalConstants.No_of_Days_Check) 
                                     && QLIVar.Payment_Terms__c != oldQLIRecords.get(QLIVar.Id).Payment_Terms__c)){
                                         QLIVar.Sequence__c = 2;
                                     } 
                            else if((
                                (custDiscRounded > GlobalConstants.Req_Cust_Disc_Value_3 && custDiscRounded != oldcustDiscRounded )  || 
                                (QLIVar.Payment_Terms__c == GlobalConstants.PAYMENT_MODE_OTHERS && QLIVar.Payment_Terms__c != oldQLIRecords.get(QLIVar.Id).Payment_Terms__c)) && 
                                    (noOfDays==null || noOfDays<=GlobalConstants.No_of_Days_Check)){
                                        QLIVar.Sequence__c = 3;
                                    } 
                            else if(((custDiscRounded != oldcustDiscRounded) || (QLIVar.Payment_Terms__c != oldQLIRecords.get(QLIVar.Id).Payment_Terms__c || oldQLIRecords.get(QLIVar.Id).Payment_Terms__c == null) )
                                    && noOfDays > GlobalConstants.No_of_Days_Check ){
                                        QLIVar.Sequence__c = 4;
                                        QLIVar.Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS;                                    
                                    }                      
                        }
                    }
                    //Ended by Shreela on 1st November 2022 for SAEPB - 44
                }
            }
            
            catch(Exception e){
                
            } 
        }
        
        
        //Added by Shreela on 4th Nov 2022 for SAEPB - 44
        if(contextVariable == GlobalConstants.Context_Variable_After){
            Set<Id> qliId=new Set<Id>();
            for(QuoteLineItem qlVar: newQLIRecords) {
                qliId.add(qlVar.Id);
            }          
            
            Map<Id,QuoteLineItem> quoteLineItemRecordMap = new Map<Id,QuoteLineItem>([SELECT Id,CreatedDate,Quote.CreatedDate,Quote_Record_Type__c,Requested_Customer_Discount__c,Sequence__c,Payment_Terms__c,Quote.Last_Approved_Date__c,Approval_Status__c,Quote.Approval_Status__c   
                                                                                      FROM QuoteLineItem 
                                                                                      WHERE Id IN: qliId
                                                                                      AND Quote_Record_Type__c =: GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE]);
            
            List<Quote> qList = new List<Quote>();
            
            for(QuoteLineItem QLIVar: quoteLineItemRecordMap.values()){ 
                Integer noOfDays;
                if(qObj.size()>0){  //Added this line to avoid Attempt to deference null object by Shreela on 19th January 2023
                    if(QLIVar.QuoteId == qObj.get(QLIVar.QuoteId).Id && qObj.get(QLIVar.QuoteId).Last_Approved_Date__c!=null){
                        noOfDays = qObj.get(QLIVar.QuoteId).Last_Approved_Date__c.date().daysBetween(System.today()); //To find no of days betwwen Last Approved Date and Today
                    } 
                }
                
                Decimal custDiscRounded = QLIVar.Requested_Customer_Discount__c.setScale(1);
                Decimal oldcustDiscRounded;
                if(!oldQLIRecords.isEmpty() && oldQLIRecords.get(QLIVar.Id).Requested_Customer_Discount__c != null)
                    oldcustDiscRounded = oldQLIRecords.get(QLIVar.Id).Requested_Customer_Discount__c.setScale(1);                                       
                
                if(!qObj.isEmpty() && qObj!=null){
                    if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE && qObj.get(QLIVar.QuoteId).Opportunity.Sub_Division__c == GlobalConstants.B2B_SUBDIVISION){
                        if(((custDiscRounded != oldcustDiscRounded)  ||(QLIVar.Payment_Terms__c != oldQLIRecords.get(QLIVar.Id).Payment_Terms__c ))
                           && noOfDays > GlobalConstants.No_of_Days_Check ){
                               Quote qRecord = new Quote(Id = QLIVar.QuoteId,Approval_Status__c = GlobalConstants.APPROVAL_REQUIRED_STATUS);
                               qList.add(qRecord);
                           } 
                    }
                }
            }              
            
            try{
                if(qList.size()>0)
                    update qList;
            }
            catch(DMLException e){
                
            }
        }  
        
        //Ended by Shreela on 4th Nov 2022 for SAEPB-44
    }
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update sequence number based from related opportunity product.
Inputs:        NA
Test Class:    
History
25-05-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
    public void updateSequenceNumber(List<QuoteLineItem> newQLIRecords) {
        // Create necessary datastructure.
        List<Id> quoteIdList = new List<Id>();
        List<Quote> quoteList = new List<Quote>();
        Map<Id, QuoteLineItem> quoteIdVSquoteLineItem = new Map<Id, QuoteLineItem>();
        Map<Id, Id> quoteIdVSopportunityId = new Map<Id, Id>();
        Map<Id, Opportunity> opportunityRecordMap;
        Map<Id, Decimal> opportunityAndProductIdVSsequenceNumber = new Map<Id, Decimal>();
        
        // Get related quotes.
        for(QuoteLineItem qli : newQLIRecords) {
            quoteIdList.add(qli.QuoteId);
            quoteIdVSQuoteLineItem.put(qli.QuoteId, qli);
        }
        quoteList = [Select Id, OpportunityId FROM Quote Where Id IN :quoteIdList];
        
        // Get related opportunity and opportunity products.
        for(Quote quoteObj : quoteList) {
            quoteIdVSopportunityId.put(quoteObj.Id, quoteObj.OpportunityId);
        }
        opportunityRecordMap = new Map<Id, Opportunity>([Select Id, (Select Id, Product2Id, Sequence_Number__c FROM OpportunityLineItems) 
                                                         FROM Opportunity WHERE Id IN :quoteIdVSopportunityId.values()
                                                        ]);
        
        // Create DS where an opportunity product can be indentified for different opportunities with similar product.
        for(Id oppId : opportunityRecordMap.keySet()) {
            Opportunity opp = opportunityRecordMap.get(oppId);
            for(OpportunityLineItem oppLineItem : opp.OpportunityLineItems) {
                opportunityAndProductIdVSsequenceNumber.put(oppLineItem.Id, oppLineItem.Sequence_Number__c);
            }
        }
        
        // Get the sequence number value based on the related opportunity product from the related opportunity.
        for(QuoteLineItem qli : newQLIRecords) {
            // Joshna - replaced the previous logic with single line to retrieve the sequence by opp line item ID
            // added a contains key check to ensure that if the product is added only at quote level, sequence # is not
            // overwritten
            if (qli.Opportunity_Line_Item_ID__c != null && opportunityAndProductIdVSsequenceNumber.containsKey(qli.Opportunity_Line_Item_ID__c)) {
                qli.Sequence_Number__c = opportunityAndProductIdVSsequenceNumber.get(qli.Opportunity_Line_Item_ID__c);
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update Asset Serial Number field on Quote Line Item if Asset is populated.
Inputs:        NA    
History
10-06-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
    public void updateAssetSerialNumber(List<QuoteLineItem> quoteLineItems) {
        Map<Id, QuoteLineItem> assetIdVSquoteLineItem = new Map<Id, QuoteLineItem>();
        for(QuoteLineItem qli : quoteLineItems) {
            if(qli.Asset__c != null) {
                assetIdVSquoteLineItem.put(qli.Asset__c, qli);
            }
        }
        
        if(assetIdVSquoteLineItem.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>([Select Id, SerialNumber FROM Asset WHERE Id IN :assetIdVSquoteLineItem.keySet()]);
            // Update those Quote Line Items that have asset records populated.
            
            for(Id assetId : assetMap.keySet()) {
                Asset assetRecord = assetMap.get(assetId);
                QuoteLineItem qli = assetIdVSquoteLineItem.get(assetId);
                qli.Asset_Serial_Number__c = assetRecord.SerialNumber != null ? assetRecord.SerialNumber : qli.Asset_Serial_Number__c;
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update Contract related fields based on contract type field values.
Inputs:        NA  
History
12-06-2020      Kartik Shetty     Initial Release
19-06-2020      Manasi Londhe     Added logic for syncing opportunity line item fields to QLI for mhe contracts
12-08-2020      Suwarna Rao       Added logic for editing fields "Distance__c" and "Operating_Hrs_Year__c" for generic products.
----------------------------------------------------------------------------*/
    public void prepopulateContractRelatedFields(List<QuoteLineItem> quoteLineItems,Boolean isInsert) {
        Set<Id> productIds = new Set<Id>();
        for(QuoteLineItem quoteLine : quoteLineItems) {
            productIds.add(quoteLine.Product2Id);
        } 
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Is_Generic_Product__c FROM Product2 WHERE Id IN :productIds]);           
        if(isInsert){
            syncOppLineItemFieldsToQLI(quoteLineItems);
        }
        for(QuoteLineItem quoteLineItem : quoteLineItems) {
            // Run this only if it's not a generic product.
            if(productMap.containsKey(quoteLineItem.Product2Id)){
                if(quoteLineItem.Contract_Type__c != null && !productMap.get(quoteLineItem.Product2Id).Is_Generic_Product__c){
                    // Populate default field values.
                    switch on quoteLineItem.Contract_Type__c {
                        when  'Bronze', 'Gold' {
                            quoteLineItem.Distance__c = '<100 Km';
                            quoteLineItem.Operating_Hrs_Year__c = '<2000';
                        }
                        when  'Silver' {
                            quoteLineItem.Distance__c = '<100 Km';
                            quoteLineItem.Operating_Hrs_Year__c = '';
                        }
                        when  'Platinum', 'Titanium' {
                            quoteLineItem.Distance__c = '<100 Km';
                            quoteLineItem.Operating_Hrs_Year__c = '<2000';
                        }
                        when else {
                        }
                        
                    }
                }     
            }
        }   
    }
    
    public void syncOppLineItemFieldsToQLI(List<QuoteLineItem> quoteLineItems){
        Set<Id> oppLineItemIds=new Set<Id>();
        for(QuoteLineItem qli:quoteLineItems){
            if(qli.Opportunity_Line_Item_ID__c!=null)
                oppLineItemIds.add(qli.Opportunity_Line_Item_ID__c);
        }
        Map<Id,OpportunityLineItem> IdVsOppLineItems=new Map<Id,OpportunityLineItem>([Select Contract_Type__c,opportunity.MHE_Division__c,Contract_Start_Date__c,Contract_End_Date__c,
                                                                                      //Added by Praful - 22-Feb-2021
                                                                                      Duration_Unit__c,Duration__c
                                                                                      From OpportunityLineItem
                                                                                      Where Id in :oppLineItemIds 
                                                                                      And opportunity.MHE_Division__c= :GlobalConstants.MHE_SUB_DIVISION_CONTRACT]);
        if(IdVsOppLineItems!=null && IdVsOppLineItems.size()>0){
            for(QuoteLineItem qli:quoteLineItems){
                if(qli.Opportunity_Line_Item_ID__c!=null && IdVsOppLineItems.containsKey(qli.Opportunity_Line_Item_ID__c)){
                    qli.Contract_Type__c=IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Contract_Type__c;
                    qli.Contract_Start_Date__c=IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Contract_Start_Date__c;
                    qli.Contract_End_Date__c=IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Contract_End_Date__c;
                    //Added by Praful - 22-Feb-2021
                    qli.Duration_Unit__c = IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Duration_Unit__c;
                    qli.Duration__c = IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Duration__c;
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to update quote line item fields based on opportunity product field values.
Inputs:        NA  
History
16-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
    public void copyOpportunityProductValuesToQLI(List<QuoteLineItem> quoteLineItems) {
        Set<Id> oppLineItemIds=new Set<Id>();
        for(QuoteLineItem qli:quoteLineItems) {
            if(qli.Opportunity_Line_Item_ID__c!=null) {
                oppLineItemIds.add(qli.Opportunity_Line_Item_ID__c);
            }
        }
        Map<Id,OpportunityLineItem> IdVsOppLineItems=new Map<Id,OpportunityLineItem>([Select Contract_Type__c, Opportunity.MHE_Division__c, 
                                                                                      Contract_Start_Date__c, Contract_End_Date__c, Warehouse__c
                                                                                      From OpportunityLineItem
                                                                                      Where Id in :oppLineItemIds]);
        if(IdVsOppLineItems!=null && IdVsOppLineItems.size()>0) {
            for(QuoteLineItem qli:quoteLineItems){
                if(qli.Opportunity_Line_Item_ID__c!=null && IdVsOppLineItems.containsKey(qli.Opportunity_Line_Item_ID__c)){
                    qli.Warehouse__c = IdVsOppLineItems.get(qli.Opportunity_Line_Item_ID__c).Warehouse__c;
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Subhojit C
Company:       Salesforce
Description:   Method to Calculate Amount from customer pecentage vice varsa
Inputs:        NA
Test Class:    
History
10-04-2020      Subhojit     Initial Release
----------------------------------------------------------------------------*/
    public void updateCustomerDiscount(List<QuoteLineItem> newQLIRecords,String contextVariable){
        Set<String> quoteIds = new Set<String>(); 
        Set<String> accountIds = new Set<String>();
        Set<String> products = new Set<String>();
        Map<String,Set<String>> branchVsQuoteIds = new Map<String,Set<String>>();
        Map<String,Set<String>> priceBookVsQuoteIds = new Map<String,Set<String>>();
        Map<String,Set<String>> quoteIdVsProducts = new Map<String,Set<String>>();
        Map<String,String> qliIdVsDealerPriceBook = new Map<String,String>();
        Map<String,PricebookEntry> quoteAndProductVsPriceBookEntry = new Map<String,PricebookEntry>();
        
        for(QuoteLineItem QLIVar: newQLIRecords ){
            if(trigger.isBefore && trigger.isUpdate){
                QuoteLineItem oldQliVar = (QuoteLineItem)Trigger.oldMap.get(QLIVar.Id);//get older values added by pankaj on 19 may 2023
                Decimal requested_Customer_Discount_New = QLIVar.Requested_Customer_Discount__c!= null ? QLIVar.Requested_Customer_Discount__c.setScale(3):null; //get older values added by pankaj on 19 may 2023
                Decimal requested_Customer_Discount_Old = oldQliVar.Requested_Customer_Discount__c!= null ? oldQliVar.Requested_Customer_Discount__c.setScale(3):null;//get older values added by pankaj on 19 may 2023
                
                if(QLIVar.Requested_Customer_Discount__c!=null && QLIVar.UnitPrice !=null && requested_Customer_Discount_New != requested_Customer_Discount_Old){//added by pankaj on 19 may 2023
                    QLIVar.Requested_CustomerAmount__c=(QLIVar.UnitPrice*QLIVar.Quantity)*(QLIVar.Requested_Customer_Discount__c/100);
                    QLIVar.Requested_Customer_Discount_Amount_Unit__c=QLIVar.UnitPrice*QLIVar.Requested_Customer_Discount__c/100;     //added by pankaj on 8/12/2020 for Requested Customer Discount Amount/Unit                   
                }
                else if(QLIVar.Requested_CustomerAmount__c != oldQliVar.Requested_CustomerAmount__c && QLIVar.UnitPrice !=null && QLIVar.Requested_CustomerAmount__c != null){
                    QLIVar.Requested_Customer_Discount__c=((QLIVar.Requested_CustomerAmount__c*100)/(QLIVar.UnitPrice*QLIVar.Quantity));
                    QLIVar.Requested_Customer_Discount_Amount_Unit__c = QLIVar.Requested_CustomerAmount__c/QLIVar.Quantity;//Added by pankaj on 24/06/2021 for Quick Discount                   
                }
                //Added by Pankaj  on 8/12/2020 Requested Customer Discount % based on  Requested Customer Discount Amount/Unit
                else if(QLIVar.Requested_Customer_Discount_Amount_Unit__c != oldQliVar.Requested_Customer_Discount_Amount_Unit__c && QLIVar.UnitPrice !=null && QLIVar.Requested_Customer_Discount_Amount_Unit__c != null){
                    QLIVar.Requested_Customer_Discount__c=((QLIVar.Requested_Customer_Discount_Amount_Unit__c*100)/(QLIVar.UnitPrice));
                    QLIVar.Requested_CustomerAmount__c = QLIVar.Requested_Customer_Discount_Amount_Unit__c * QLIVar.Quantity;//Added by pankaj on 24/06/2021 for Quick Discount                    
                }
            } // End by pankaj on 25/7/2023
            
            //Added by Pawan :: US160 :: Dealer Discount
            // For Base Product, Requested and Approved Customer discount should be same for Product_Storage_Clasification as 'Category A' i.e 1 
            
            /*if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS 
               && (QLIVar.Product_Storage_Clasification__c == Decimal.valueof(1) || QLIVar.Skip_Generic_SPR__c==True) //added by pankaj on 12 Oct 2021 Skip_Generic_SPR__c to skip dealer discount on freight
               && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                   if(QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_BASE_PRODUCT 
                      && String.isNotBlank(System.Label.BASE_PRODUCT_DISCOUNT)){
                          
                          QLIVar.Dealer_Discount__c = Decimal.valueOf(System.Label.BASE_PRODUCT_DISCOUNT);
                      }else if((QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_ATTACHMENTS || QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_ACCESSORIES) 
                               && String.isNotBlank(System.Label.ATTACHMENTS_AND_ACCESSORIES_DISCOUNT)){
                                   QLIVar.Dealer_Discount__c = Decimal.valueOf(System.Label.ATTACHMENTS_AND_ACCESSORIES_DISCOUNT);
                               }
                   QLIVar.Approved_Customer_Discount__c = QLIVar.Requested_Customer_Discount__c;
                   QLIVar.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS; //Commented by Shreela for SMEPB 111 as this is not required.Setting dealer discount will be written in separate method.
                   
               }else if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS // for Product_Storage_Clasification as 'Category A' i.e 2
                        && (QLIVar.Product_Storage_Clasification__c == Decimal.valueof(2) || QLIVar.Product_Storage_Clasification__c == Decimal.valueof(3)) 
                        && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                            //dealer discount formula added by pankaj on 8/6/2021 for annexture B 
                            //product storage classification -category AB added by pankaj 26-08-2021
                            if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1) 
                               && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V1)
                               && QLIVar.Requested_Customer_Discount__c >= 0 
                               && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)){
                                   QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1)); 
                                   
                               }else if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)  
                                        && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)
                                        && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V2)
                                        && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1) 
                                        && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){
                                            QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2));
                                        }else if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2) 
                                                 && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V3)
                                                 && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){
                                                     QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3));
                                                     
                                                 }
                            QLIVar.Approved_Customer_Discount__c = QLIVar.Requested_Customer_Discount__c;
                            System.debug('QLIVar.Approved_Customer_Discount__c by shreela 1:'+QLIVar.Approved_Customer_Discount__c);
                            QLIVar.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS;
                        } */ //Commented by Shreela on 8th Dec 2023 for SMEPB 111 as modified code will be written in new method
            
            //Added by Pawan :: For MHE Parts, Approved Customer Discount should be same as Requested Customer Discount
            if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS 
               && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                   QLIVar.Approved_Customer_Discount__c = QLIVar.Requested_Customer_Discount__c;
               }
            //Added by pankaj :: OR condition included for MHE Equipment on 03-02-2021 (|| QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS)
            if((QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS
                || QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS
                || QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_INTERIO_B2C_VFD)
               && QLIVar.Order_Type__c ==  GlobalConstants.ORDER_TYPE_SECONDARY ){
                   QLIVar.Approved_Customer_Discount_Derived__c = 0;
               }else{
                   QLIVar.Approved_Customer_Discount_Derived__c = QLIVar.Approved_Customer_Discount__c;
               }
            if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS 
               && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                   quoteIds.add(QLIVar.QuoteId);
                   products.add(QLIVar.Product2Id);
                   if(quoteIdVsProducts.containsKey(QLIVar.QuoteId)){
                       quoteIdVsProducts.get(QLIVar.QuoteId).add(QLIVar.Product2Id);
                   }else{
                       quoteIdVsProducts.put(QLIVar.QuoteId,new set<String>{QLIVar.Product2Id});
                   }
               }
        }
        
        
        if(quoteIds.size() > 0 && products.size() > 0){
            Set<String> branchNames = new Set<String>();
            Map<Id,Quote> quotes = new Map<Id,Quote>([Select Id,OpportunityId,Opportunity.OwnerId,Opportunity.Owner.ContactId,Opportunity.Sales_Branch_Name__c,Opportunity.Owner.AccountId 
                                                      FROM Quote 
                                                      WHERE Id IN : quoteIds
                                                      AND Opportunity.Sales_Branch_Name__c != null
                                                      AND Opportunity.Owner.ContactId != null
                                                      AND Opportunity.Owner.AccountId != null]);
            for(Quote quoteRec : quotes.values()){
                accountIds.add(quoteRec.Opportunity.Owner.AccountId);
                branchNames.add(quoteRec.Opportunity.Sales_Branch_Name__c);
                if(branchVsQuoteIds.containsKey(quoteRec.Opportunity.Sales_Branch_Name__c+'-'+quoteRec.Opportunity.Owner.AccountId)){
                    branchVsQuoteIds.get(quoteRec.Opportunity.Sales_Branch_Name__c+'-'+quoteRec.Opportunity.Owner.AccountId).add(quoteRec.Id);
                }else{
                    branchVsQuoteIds.put(quoteRec.Opportunity.Sales_Branch_Name__c+'-'+quoteRec.Opportunity.Owner.AccountId,new Set<String>{quoteRec.Id});
                }
            }
            
            Map<Id,Branch__c> branches = new Map<Id,Branch__c>([Select Id,Business_Partner__c, Sales_Price_List__c,Branch_Name__c 
                                                                FROM Branch__c
                                                                WHERE Business_Partner__c IN: accountIds
                                                                AND Branch_Name__c IN : branchNames]);
            for(Branch__c branchRec : branches.values()){
                if(branchVsQuoteIds.containsKey(branchRec.Branch_Name__c+'-'+branchRec.Business_Partner__c)){
                    priceBookVsQuoteIds.put(branchRec.Sales_Price_List__c,branchVsQuoteIds.get(branchRec.Branch_Name__c+'-'+branchRec.Business_Partner__c));
                }
            }
            
            if(priceBookVsQuoteIds.size() > 0 && products.size() > 0){
                
                for(PricebookEntry pbe : [Select Id,UnitPrice,Product2Id,Pricebook2Id
                                          FROM PricebookEntry
                                          WHERE Product2Id IN : products
                                          AND Pricebook2Id IN : priceBookVsQuoteIds.keySet()]){
                                              if(priceBookVsQuoteIds.containsKey(pbe.Pricebook2Id)){
                                                  for(String quoteId : priceBookVsQuoteIds.get(pbe.Pricebook2Id)){
                                                      if(quoteIdVsProducts.containsKey(quoteId)){
                                                          quoteAndProductVsPriceBookEntry.put(quoteId+'-'+pbe.Product2Id,pbe);
                                                      }
                                                  }
                                              }
                                          }
            }
            
            //Iterate over new QLI records to update the Dealer price from the branch price book
            for(QuoteLineItem QLIVar: newQLIRecords ){
                if(quoteAndProductVsPriceBookEntry.containsKey(QLIVar.QuoteId+'-'+QLIVar.Product2Id)){
                    QLIVar.Dealer_Price__c = quoteAndProductVsPriceBookEntry.get(QLIVar.QuoteId+'-'+QLIVar.Product2Id).UnitPrice;
                }
            }
        }
        
        //Added by Shreela on 9th November 2022 for SAEPB-44
        if(contextVariable == GlobalConstants.Context_Variable_Update){
            Set<Id> idValues = new Set<Id>();
            for(QuoteLineItem QLIVar: newQLIRecords ){
                if(QLIVar.Approval_Status__c == GlobalConstants.APPROVED && QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){ 
                    idValues.add(QLIVar.QuoteId);
                }               
            } 
            
            Map <Id,QuoteLineItem> mp;
            if(idValues.size()>0){
                mp = new Map<Id,QuoteLineItem>([SELECT Id,Quote_Record_Type__c,PricebookEntry.UnitPrice,Quote.Opportunity.Sub_Division__c,Approved_Customer_Discount__c,Requested_Customer_Discount__c 
                                                FROM QuoteLineItem 
                                                WHERE Quote_Record_Type__c =: GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE
                                                AND Quote.Opportunity.Sub_Division__c=: GlobalConstants.B2B_SUBDIVISION AND QuoteId IN:idValues]);               
            }
            
            if(mp!=null){
                for(QuoteLineItem qli: newQLIRecords){ 
                    qli.Approved_Customer_Discount__c = mp.get(qli.Id).Requested_Customer_Discount__c;
                }                
            }
            
        }  
        //Ended by Shreela on 9th November 2022 for SAEPB-44
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to get QuoteId Vs Quote Map
Inputs:        List<Id>
--------------------------------------------------------------------------- 
History
19-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public Map<Id, Quote> getIdVsQuote(List<Id> quoteIds){
        return (new Map<Id, Quote>([Select Id, RecordType.Name, Transaction_Type__c,Pricing_approval_request__c,
                                    Pricing_approval_request__r.Is_Generic_Product__c, Pricing_approval_request__r.Is_New_Equipment__c,
                                    (SELECT Id, Is_Generic_Product__c, Is_New_Equipment__c 
                                     FROM QuoteLineItems
                                     WHERE Is_Generic_Product__c = true OR Is_New_Equipment__c = true)
                                    From Quote Where Id IN: quoteIds]));
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to populate is generic product checkbox on Pricing Approval Request
Inputs:        Map<Id,QuoteLineItem> 
Test Class:   
--------------------------------------------------------------------------- 
History
19-05-2020      Shailja     Initial Release
----------------------------------------------------------------------------*/
    public void updateIsGenericCheckboxOnPricingApproval(Map<Id,QuoteLineItem> newQLIRecords){
        Set<Id> genericProductQuoteIds = new Set<Id>();
        Set<Id> newEquipmentQuoteIds = new Set<Id>();
        List<Id> allQuoteIds = new List<Id>();
        List<Pricing_approval_request__c> parList = new List<Pricing_approval_request__c>();
        Map<Id, Quote> idVsQuote;
        //Set<String> recordTypeSet = new Set<String> {GlobalConstants.QUOTE_RECORDTYPE_MHE_PARTS, GlobalConstants.QUOTE_RECORDTYPE_MHE_RENTALS,
        //GlobalConstants.QUOTE_RECORDTYPE_MHE_EQUIPMENTS, GlobalConstants.QUOTE_RECORDTYPE_MHE_CONTRACTS}; // commented (10thMay22) as this variable is not used below
        for(QuoteLineItem newQLIVar: newQLIRecords.values()){
            //Added by Pankaj on 05/10/2021//Skip_Generic_SPR__c added for setting flag false in PAR i.e par.Is_Generic_Product__c if there is freight item
            if(newQLIVar.Quote.Pricing_approval_request__c!=null){
                if(newQLIVar.Is_Generic_Product__c && !newQLIVar.Skip_Generic_SPR__c){                
                    genericProductQuoteIds.add(newQLIVar.QuoteId);
                }
                if (newQLIVar.Is_New_Equipment__c) {
                    newEquipmentQuoteIds.add(newQLIVar.QuoteId);
                }
            }
        }
        if(!genericProductQuoteIds.isEmpty() || !newEquipmentQuoteIds.isEmpty()){
            allQuoteIds.addAll(genericProductQuoteIds);
            allQuoteIds.addAll(newEquipmentQuoteIds);
            idVsQuote = getIdVsQuote(allQuoteIds);
            
            
            if(!idVsQuote.isEmpty()) {
                for (Id each : allQuoteIds) {                
                    Pricing_Approval_Request__c par = new Pricing_approval_request__c(Id = idVsQuote.get(each).Pricing_approval_request__c);
                    Logger.logDebugInfo('QLIRecordProcessor', 'updateIsGenericCheckboxOnPricingApproval', par, null);
                    if (genericProductQuoteIds.contains(each)) {
                        par.Is_Generic_Product__c = true;
                        parList.add(par);
                    }
                    if (newEquipmentQuoteIds.contains(each)) {
                        par.Is_New_Equipment__c = true;
                        parList.add(par);
                    }
                    Logger.logDebugInfo('QLIRecordProcessor', 'updateIsGenericCheckboxOnPricingApproval', null, parList);
                }
            }
        }
        try{
            if(parList != null && parList.size() > 0){
                update parList;
                Logger.logDebugInfo('QLIRecordProcessor', 'updateIsGenericCheckboxOnPricingApproval', null, parList);
            }
        }catch(Exception ex){
            Logger.logError('QLIRecordProcessor', 'updateIsGenericCheckboxOnPricingApproval', '', ex);
        }
    }
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to check if loggedin User have edit access to locked 'Quote Line Item' record
Inputs:        list of updated Quotes Line Item
Test Class:    
History
13-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public map<Id, Boolean> checkLockedRecordAccess(map<Id, QuoteLineItem> newQLIs, map<Id, QuoteLineItem> oldQLIs){
        map<Id, Id> QliIdVsPARId = new map<Id, Id>();
        map<Id,boolean> lockedParIdVsAccessMap = new map<Id,boolean>();
        map<Id, Boolean> qliVsAccessMap = new map<Id,boolean>();
        list<QuoteLineItem> qlisTocheck = new list<QuoteLineItem>();
        
        for(Id qliId : newQLIs.keySet()){
            if((newQLIs.get(qliId).Approval_Status__c == oldQLIs.get(qliId).Approval_Status__c ) 
               && (newQLIs.get(qliId).Approval_Status__c == GlobalConstants.Submitted_for_Approval)){
                   qlisTocheck.add(newQLIs.get(qliId));
               }
        }
        
        for(QuoteLineItem qli : qlisTocheck){
            QliIdVsPARId.put(qli.Id, qli.Pricing_Approval_Request_Id__c);
        }
        
        //Fetch Locked PAR Ids
        if(!QliIdVsPARId.isEmpty()){
            lockedParIdVsAccessMap = Utility.recordLockCheck(QliIdVsPARId.values());
        }
        
        if(!lockedParIdVsAccessMap.isEmpty()){
            for(Id qliId : QliIdVsPARId.keyset()){
                if(lockedParIdVsAccessMap.containsKey(QliIdVsPARId.get(qliId))){
                    qliVsAccessMap.put(qliId, lockedParIdVsAccessMap.get(QliIdVsPARId.get(qliId)));
                } else {
                    //if lockedParIdVsAccessMap doesn't contains so by default that user will have access to quote Line item record
                    qliVsAccessMap.put(qliId, true);
                }
                
            }
        }
        
        return qliVsAccessMap;
    }
    
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to check if loggedin User have edit access to locked 'Quote Line Item' record
Inputs:        list of updated Quotes Line Item
Test Class:    
History
13-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void checkForLockRecordOnUpdate(map<Id, QuoteLineItem> newQLIs, map<Id, QuoteLineItem> oldQLIs){
        map<Id, Boolean> qliVsAccessMap = new map<Id,boolean>();
        
        qliVsAccessMap = checkLockedRecordAccess(newQLIs, oldQLIs);
        
        for(Id qliId : newQLIs.keySet()){
            if(qliVsAccessMap.containsKey(qliId) && !qliVsAccessMap.get(qliId)){
                newQLIs.get(qliId).addError(GlobalConstants.RECORD_LOCK_ERROR_MSG);
            }
        }
    }
    
    /* Updates Sales Price (UnitPrice) on QuoteLineItem if Market Pricelist is used
* As Market Pricelist always has GST added, the Sales Price is removed with logic
*/
    public void updateSalesPrice(List<QuoteLineItem> newLineItems) {
        Set<Id> quoteIds=new Set<Id>();
        Set<Id> pBEIds = new Set<Id>();
        for (QuoteLineItem each : newLineItems) {
            pBEIds.add(each.PricebookEntryId);
            quoteIds.add(each.QuoteId);
        }
        Map<Id, Quote> idVsQuote = getQuotes(quoteIds);
        Map<Id, PriceBookEntry> taxRateMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c FROM PriceBookEntry WHERE Id IN :pBEIds 
                                                                          AND PriceBook2.Market_Pricelist__c = true]);
        // Will be true only if the related Pricebook is a Market Pricelist
        if (!taxRateMap.isEmpty()){
            for (QuoteLineItem each : newLineItems) {
                if (taxRateMap.containsKey(each.PricebookEntryId) 
                    && taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c != null 
                    && taxRateMap.get(each.PricebookEntryId).UnitPrice != null 
                    && idVsQuote!=null 
                    && idVsQuote.containsKey(each.QuoteId)  
                    && idVsQuote.get(each.QuoteId).Transaction_Type__c==GlobalConstants.ORDER_TYPE_SECONDARY) {
                        each.UnitPrice = ((taxRateMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + taxRateMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                    }
            }
        }
    }   
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to validate Sales Price on before update -
for standard/SKU products other than generic and MRP.
For - MRP pricebook unitprice = PBE.unitprice minus tax
other pricebook unitprice = PBE.unitprice
Inputs:        Map<Id, QuoteLineItem>, Map<Id,QuoteLineItem> 
----------------------------------------------------------------------------*/
    public void validateSalesPrice(Map<Id, QuoteLineItem> newItems, Map<Id,QuoteLineItem> oldItems){
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        for(QuoteLineItem qli : newItems.values()){
            if(qli.unitPrice != oldItems.get(qli.Id).unitPrice){
                quoteLineItems.add(qli);
            }
        }
        if(quoteLineItems.size() > 0)
            validateSalesPrice(quoteLineItems);
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to validate Sales Price before Insert
Inputs:        List<QuoteLineItem>
----------------------------------------------------------------------------*/
    public void validateSalesPrice(List<QuoteLineItem> newLineItems){
        //if profile(listed in custom label) is not allowed to edit SalesPrice then only validation should fire 
        if(!IsProfileAllowedToEditSalesPrice()){
            Set<Id> pBEIds = new Set<Id>();
            Set<Id> quoteIds = new Set<Id>();
            for (QuoteLineItem quoteLine : newLineItems) {
                quoteIds.add(quoteLine.QuoteId);
                pBEIds.add(quoteLine.PricebookEntryId);
            }
            Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice, Product2.Tax_Rate__c, PriceBook2.Market_Pricelist__c, PriceBook2.Consumer_Pricelist__c FROM PriceBookEntry WHERE Id IN :pBEIds
                                                                                     And Product2.Is_Generic_Product__c = false]);
            Map<Id, Quote> quoteMap = getQuotes(quoteIds);
            if (!priceBookEntryMap.isEmpty() && !quoteMap.isEmpty()){
                for (QuoteLineItem each : newLineItems) {
                    if(priceBookEntryMap.containsKey(each.PricebookEntryId) && quoteMap.containsKey(each.QuoteId) && quoteMap.get(each.QuoteId).Opportunity.Business_Unit__c != GlobalConstants.Locks_BUSINESS_UNIT){
                        Decimal expectedUnitPrice=priceBookEntryMap.get(each.PricebookEntryId).UnitPrice;
                        if(quoteMap.get(each.QuoteId).Transaction_Type__c==GlobalConstants.ORDER_TYPE_SECONDARY
                           && priceBookEntryMap.get(each.PricebookEntryId).PriceBook2.Market_Pricelist__c
                           && priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c!=null
                           && priceBookEntryMap.get(each.PricebookEntryId).UnitPrice!=null){
                               expectedUnitPrice=((priceBookEntryMap.get(each.PricebookEntryId).UnitPrice * 100)/(100 + priceBookEntryMap.get(each.PricebookEntryId).Product2.Tax_Rate__c)).setScale(2);
                           }
                        // Added by Sreekanth Jujare on 02/09/2022 to allow Interio B2B and SSD user to modify Salesprice.
                        if(quoteMap.get(each.QuoteId).Opportunity.MHE_Division__c != GlobalConstants.MHE_SUB_DIVISION_RENTAL && 
                           quoteMap.get(each.QuoteId).Opportunity.Business_Unit__c != GlobalConstants.INTERIO_BUSINESS_UNIT &&
                           quoteMap.get(each.QuoteId).Opportunity.Business_Unit__c != GlobalConstants.SSD_BUSINESS_UNIT){
                               if(((Decimal)each.unitPrice) != expectedUnitPrice
                                  && quoteMap.get(each.QuoteId).Opportunity.Business_Unit__c != GlobalConstants.Construction_BUSINESS_UNIT
                                  && (NormaliseQLIController.NormaliseQLIControllerDisabled == FALSE)){
                                      each.addError(System.Label.Order_SalesPrice_Validation_Error_Message);
                                  }
                           }
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method to get MHE Quotes
Inputs:        List<QuoteIds>
----------------------------------------------------------------------------*/
    public Map<Id, Quote> getQuotes(Set<Id> quoteIds){
        return (new Map<Id, Quote>([Select Id,Opportunity.Business_Unit__c, Opportunity.MHE_Division__c, Transaction_Type__c From Quote Where Id IN: quoteIds])); //And RecordType.Name Like '%MHE%']));
    }
    
    /*------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Method is responsible for checking if SalesPrice is allowed to edit
Inputs:        NA
----------------------------------------------------------------------------*/
    private Boolean IsProfileAllowedToEditSalesPrice(){
        String profilesLabel = System.Label.Profiles_Allow_To_Edit_SalesPrice;
        List<String> profiles = profilesLabel.split('\\,');
        List<User> usr = [Select Id, Profile.Name From User Where Id = :UserInfo.getUserId() AND Profile.Name IN :profiles ];
        //If Profile mentioned in Custom Label is Current User's profile then allow to edit Sales Price
        if(usr.size() > 0) return true;
        return false;
    }
    
    
    public void reevaluateIsGenericAndIsNew(Map<Id, QuoteLineItem> oldQLI) {
        List<Id> quoteIds = new List<Id>();
        for (QuoteLineItem each: oldQLI.values()) {
            quoteIds.add(each.QuoteId);
        }
        List<Pricing_Approval_Request__c> parList = new List<Pricing_Approval_Request__c>();
        for (Quote each: getIdVsQuote(quoteIds).values()) {
            Boolean hasGenericProduct = false;
            Boolean hasNewEquipment = false;
            for (QuoteLineItem eachQLI : each.QuoteLineItems) {
                if (eachQLI.Is_Generic_Product__c) {
                    hasGenericProduct = true;
                }
                if (eachQLI.Is_New_Equipment__c) {
                    hasNewEquipment = true;
                }
            }
            if (hasGenericProduct != each.Pricing_Approval_Request__r.Is_Generic_Product__c
                || hasNewEquipment != each.Pricing_Approval_Request__r.Is_New_Equipment__c) {
                    parList.add(new Pricing_Approval_Request__c(Id = each.Pricing_Approval_Request__c, Is_Generic_Product__c = hasGenericProduct,
                                                                Is_New_Equipment__c = hasNewEquipment));
                }
        }
        try {
            update parList;
        } catch(Exception ex){
            Logger.logError('QLIRecordProcessor', 'updateIsGenericCheckboxOnPricingApproval', '', ex);
        }
    }
    
    public void updateSalesPriceAccordingToAgeing(List<QuoteLineItem> quoteLines, Map<Id,QuoteLineItem> oldItems){
        List<QuoteLineItem> applicableQuoteLineItems=new List<QuoteLineItem>();
        Set<Id> quoteIds=new Set<Id>();
        Set<Id> mheContractQuoteIds=new Set<Id>();
        if(oldItems==null){
            applicableQuoteLineItems=quoteLines;
            for(QuoteLineItem qli:quoteLines){
                quoteIds.add(qli.QuoteId);
            }
        }
        else{
            for(QuoteLineItem qli:quoteLines){
                if(qli.Ageing__c!=oldItems.get(qli.Id).Ageing__c || qli.Attachment__c!=oldItems.get(qli.Id).Attachment__c
                   || qli.Contract_Type__c!=oldItems.get(qli.Id).Contract_Type__c){
                       quoteIds.add(qli.QuoteId);
                       applicableQuoteLineItems.add(qli);
                   }
            }
        }
        for(Quote q:[Select Id,RecordType.DeveloperName From Quote where RecordType.DeveloperName=:GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME and Id in :quoteIds]){
            mheContractQuoteIds.add(q.Id);
        }
        
        Set<Id> pbeIds = new Set<Id>();
        for(QuoteLineItem item:applicableQuoteLineItems){
            pbeIds.add(item.PriceBookEntryId);
        }
        
        Map<Id, PriceBookEntry> pbeMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice FROM PriceBookEntry where ID IN :pbeIds]);
        for(QuoteLineItem qli : quoteLines){
            if((oldItems==null)|| 
               (qli.Ageing__c!=oldItems.get(qli.Id).Ageing__c 
                || qli.Attachment__c!=oldItems.get(qli.Id).Attachment__c
                || qli.Contract_Type__c!=oldItems.get(qli.Id).Contract_Type__c)){
                    
                    //Getting the list price from Price Book Entry
                    Decimal listPrice;
                    if(pbeMap.get(qli.PricebookEntryId)<>NULL)
                        listPrice = pbeMap.get(qli.PricebookEntryId).UnitPrice;
                    
                    if(mheContractQuoteIds.contains(qli.Quoteid) && listPrice!=null){
                        
                        if((qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_TITANIUM) || (qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_PLATINUM)){
                            if((oldItems==null && qli.Attachment__c=='Yes') || (oldItems!=null && qli.Attachment__c=='Yes' && ( (oldItems.get(qli.Id).Attachment__c=='No') || (oldItems.get(qli.Id).Attachment__c==null) )))
                                qli.UnitPrice+=0.05*listPrice;
                            else if(oldItems!=null && (qli.Attachment__c=='No' || qli.Attachment__c==null) && oldItems.get(qli.Id).Attachment__c=='Yes')
                                qli.UnitPrice-=0.05*listPrice;  
                        }
                        if(qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_TITANIUM){
                            if((oldItems==null && qli.Ageing__c>=1 && qli.Ageing__c<=3) || 
                               (oldItems!=null && qli.Ageing__c>=1 && qli.Ageing__c<=3 && ((oldItems.get(qli.Id).Ageing__c>=4 && oldItems.get(qli.Id).Ageing__c<=7)|| oldItems.get(qli.Id).Ageing__c==null)))
                                qli.UnitPrice-=0.15*listPrice; 
                            else if(oldItems!=null && qli.Ageing__c>=1 && qli.Ageing__c<=3 && oldItems.get(qli.Id).Ageing__c>7)
                                qli.UnitPrice-=0.30*listPrice; 
                            else if(oldItems!=null && ((qli.Ageing__c>=4 && qli.Ageing__c<=7)|| qli.Ageing__c==null) && oldItems.get(qli.Id).Ageing__c>=1 && oldItems.get(qli.Id).Ageing__c<=3)
                                qli.UnitPrice+=0.15*listPrice;
                            else if(oldItems!=null && ((qli.Ageing__c>=4 && qli.Ageing__c<=7)|| qli.Ageing__c==null) && oldItems.get(qli.Id).Ageing__c>7)
                                qli.UnitPrice-=0.15*listPrice; 
                            else if((oldItems==null && qli.Ageing__c>7) || (oldItems!=null && qli.Ageing__c>7 && ((oldItems.get(qli.Id).Ageing__c>=4 && oldItems.get(qli.Id).Ageing__c<=7)||oldItems.get(qli.Id).Ageing__c==null)))
                                qli.UnitPrice+=0.15*listPrice;
                            else if(oldItems!=null && qli.Ageing__c>7 && oldItems.get(qli.Id).Ageing__c>=1 && oldItems.get(qli.Id).Ageing__c<=3)
                                qli.UnitPrice+=0.30*listPrice;  
                        }
                        else if(qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_PLATINUM){
                            if((oldItems==null && qli.Ageing__c>=1 && qli.Ageing__c<=3) || 
                               (oldItems!=null && qli.Ageing__c>=1 && qli.Ageing__c<=3 && ((oldItems.get(qli.Id).Ageing__c>=4 && oldItems.get(qli.Id).Ageing__c<=7)|| oldItems.get(qli.Id).Ageing__c==null)))
                                qli.UnitPrice-=0.20*listPrice; 
                            else if(oldItems!=null && qli.Ageing__c>=1 && qli.Ageing__c<=3 && oldItems.get(qli.Id).Ageing__c>7)
                                qli.UnitPrice-=0.35*listPrice; 
                            else if(oldItems!=null && ((qli.Ageing__c>=4 && qli.Ageing__c<=7)|| qli.Ageing__c==null) && oldItems.get(qli.Id).Ageing__c>=1 && oldItems.get(qli.Id).Ageing__c<=3)
                                qli.UnitPrice+=0.20*listPrice;
                            else if(oldItems!=null && ((qli.Ageing__c>=4 && qli.Ageing__c<=7)|| qli.Ageing__c==null) && oldItems.get(qli.Id).Ageing__c>7)
                                qli.UnitPrice-=0.15*listPrice; 
                            else if((oldItems==null && qli.Ageing__c>7) || (oldItems!=null && qli.Ageing__c>7 && ((oldItems.get(qli.Id).Ageing__c>=4 && oldItems.get(qli.Id).Ageing__c<=7)||oldItems.get(qli.Id).Ageing__c==null)))
                                qli.UnitPrice+=0.15*listPrice;
                            else if(oldItems!=null && qli.Ageing__c>7 && oldItems.get(qli.Id).Ageing__c>=1 && oldItems.get(qli.Id).Ageing__c<=3)
                                qli.UnitPrice+=0.35*listPrice;
                        }
                        if(oldItems!=null && qli.Contract_Type__c!=oldItems.get(qli.Id).Contract_Type__c && oldItems.get(qli.Id).Contract_Type__c==null
                           && qli.Ageing__c==oldItems.get(qli.Id).Ageing__c && qli.Attachment__c==oldItems.get(qli.Id).Attachment__c){
                               if(qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_TITANIUM || qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_PLATINUM){
                                   if(qli.Attachment__c=='Yes') 
                                       qli.UnitPrice+=0.05*listPrice;
                               }
                               if(qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_TITANIUM){
                                   if(qli.Ageing__c>=1 && qli.Ageing__c<=3)
                                       qli.UnitPrice-=0.15*listPrice;
                                   if(qli.Ageing__c>7)
                                       qli.UnitPrice+=0.15*listPrice;
                               }
                               else if(qli.Contract_Type__c==GlobalConstants.CONTRACT_TYPE_PLATINUM){
                                   if(qli.Ageing__c>=1 && qli.Ageing__c<=3)
                                       qli.UnitPrice-=0.20*listPrice;
                                   if(qli.Ageing__c>7)
                                       qli.UnitPrice+=0.15*listPrice;
                               }
                           }
                        qli.UnitPrice = qli.UnitPrice.divide(1, 2);
                        
                    }
                    
                }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Nupoor
Company:       Salesforce
Description:   Method to capture Sales Price Difference for MHE_Rental
if sales price is less than list price
Inputs:        List<QuoteLineItem> 
----------------------------------------------------------------------------*/
    public void captureSalesPriceDifference(List<QuoteLineItem> newItems){
        Set<Id> pbeIds = new Set<Id>();
        for (QuoteLineItem qli : newItems) {
            pbeIds.add(qli.PricebookEntryId);
        }
        Map<Id, PriceBookEntry> priceBookEntryMap = new Map<Id, PriceBookEntry>([SELECT Id, UnitPrice FROM PriceBookEntry WHERE Id IN :pbeIds]);
        for(QuoteLineItem qli : newItems)
        {
            if((priceBookEntryMap.get(qli.PricebookEntryId) <> NULL)
               && qli.Quote_Record_Type__c == GlobalConstants.QUOTE_MHE_RENTALS_RECORDTYPE_APINAME)
            {
                if(qli.unitPrice < priceBookEntryMap.get(qli.PricebookEntryId).UnitPrice)
                {
                    qli.Sales_Price_Difference__c = priceBookEntryMap.get(qli.PricebookEntryId).UnitPrice - qli.UnitPrice;
                }
                
                //Shankar Sahu 5-1-2021 for otrs#30308892
                else if(qli.unitPrice > priceBookEntryMap.get(qli.PricebookEntryId).UnitPrice)
                {
                    qli.Sales_Price_Difference__c = qli.UnitPrice - priceBookEntryMap.get(qli.PricebookEntryId).UnitPrice;
                }
                
                else
                {
                    qli.Sales_Price_Difference__c = NULL;
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor
Company:       Salesforce
Description:   Method to update PAR on autoapproval of QLI for certain scenario
Inputs:        Map<Id, QuoteLineItem>, Map<Id,QuoteLineItem> 
----------------------------------------------------------------------------*/
    public void updatePARForAutoapprovedQLI(Map<Id, QuoteLineItem> newItems, Map<Id,QuoteLineItem> oldItems){
        set<Id> qliIds = new set<Id>();
        map<Id, QuoteLineItem> idVsQueriedQLI = new map<Id, QuoteLineItem>();
        list<Pricing_approval_request__c> pricingRecordsToUpdate  = new list<Pricing_approval_request__c>();
        
        for(Id newQLIId : newItems.Keyset()){
            if(oldItems.containsKey(newQLIId) && newItems.get(newQLIId).Requested_Customer_Discount__c > 0 
               && newItems.get(newQLIId).Requested_Customer_Discount__c != oldItems.get(newQLIId).Requested_Customer_Discount__c
               && newItems.get(newQLIId).Is_autoapproved__c){
                   qliIds.add(newQLIId);
               } 
        }
        
        if(qliIds.size() > 0){
            //Fetch relevant details 
            for(QuoteLineItem qli : [SELECT Id, Quote.Pricing_approval_request__c  
                                     FROM QuoteLineItem  
                                     WHERE Id IN :qliIds 
                                     AND Quote.RecordType.DeveloperName =: GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN
                                     AND CreatedBy.Persona__c != '']){
                                         idVsQueriedQLI.put(qli.Id, qli);
                                     } 
        }
        
        if(!idVsQueriedQLI.isEmpty()){
            for(QuoteLineItem queriesQli : idVsQueriedQLI.values()){
                //Update PAR record approval status and Auto-approved flag
                Pricing_approval_request__c par = new Pricing_approval_request__c();
                if (Schema.sObjectType.Pricing_approval_request__c.fields.Id.isUpdateable()){ 
                    par.Id =  queriesQli.Quote.Pricing_approval_request__c;
                }
                if (Schema.sObjectType.Pricing_approval_request__c.fields.Is_autoapproved__c.isUpdateable() && Schema.sObjectType.Pricing_approval_request__c.fields.Approval_Status__c .isUpdateable()){ 
                    par.Is_autoapproved__c = true;
                    par.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
                }
                pricingRecordsToUpdate.add(par);        
            } 
        }
        if (Schema.sObjectType.Pricing_approval_request__c.fields.Approval_Status__c.isUpdateable()){ 
            if(pricingRecordsToUpdate.size() > 0){ 
                try{
                    update pricingRecordsToUpdate;
                }catch(Exception ex){
                    Logger.logError('QLIRecordProcessor', 'updatePARForAutoapprovedQLI', '', ex);
                } 
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Kishor
Company:       Salesforce
Description:   Method to auto approve QLI for certain scenario
Inputs:        Map<Id, QuoteLineItem>, Map<Id,QuoteLineItem> 
----------------------------------------------------------------------------*/
    public void validateAndAutoapproveForKitchen(Map<Id, QuoteLineItem> newItems, Map<Id,QuoteLineItem> oldItems){
        set<Id> qliIds = new set<Id>();
        set<Id> queriedQLIIds = new set<Id>();
        map<String, Integer> personaVsHierarchyLevel = new map<String, Integer>();
        
        for(Id newQLIId : newItems.Keyset()){
            if(oldItems.containsKey(newQLIId) 
               && newItems.get(newQLIId).Requested_Customer_Discount__c != oldItems.get(newQLIId).Requested_Customer_Discount__c){
                   qliIds.add(newQLIId);
               } 
        }
        
        if(qliIds.size() > 0){
            //Create PersonaVs Hierarchy data for Kitchen
            for(Approval_Submitter_Hierarchy_mapping__mdt sHierarchy : [SELECT Quote_Business_Unit__c, Submitter_Level__c, Quote_Submitter_Persona__c 
                                                                        FROM Approval_Submitter_Hierarchy_mapping__mdt 
                                                                        WHERE Quote_Business_Unit__c =: GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN]){
                                                                            
                                                                            if(String.isNotEmpty(sHierarchy.Quote_Submitter_Persona__c)){
                                                                                personaVsHierarchyLevel.put(sHierarchy.Quote_Submitter_Persona__c.toUpperCase(), Integer.valueOf(sHierarchy.Submitter_Level__c));
                                                                            }                                                            
                                                                        }
            
            //Fetch relevant details for Kitchen
            for(QuoteLineItem qli : [SELECT Id, CreatedBy.Persona__c    
                                     FROM QuoteLineItem  
                                     WHERE Id IN :qliIds 
                                     AND Quote.RecordType.DeveloperName =: GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN
                                     AND CreatedBy.Persona__c != '']){
                                         
                                         if(!personaVsHierarchyLevel.isEmpty() &&
                                            personaVsHierarchyLevel.containsKey(qli.CreatedBy.Persona__c.toUpperCase()) && 
                                            personaVsHierarchyLevel.get(qli.CreatedBy.Persona__c.toUpperCase()) >= Integer.valueOf(System.Label.Interio_B2C_KITCHEN_max_approver_level)){
                                                queriedQLIIds.add(qli.Id);                           
                                            }
                                         
                                     } 
        }
        
        if(queriedQLIIds.size() > 0 ){
            for(Id qliId : queriedQLIIds){
                //Update QLI and Auto-approved flag
                newItems.get(qliId).Is_autoapproved__c = true;
                newItems.get(qliId).Approved_Customer_Discount__c = newItems.get(qliId).Requested_Customer_Discount__c;
                newItems.get(qliId).Approval_Status__c = GlobalConstants.APPROVED_STATUS; 
            } 
        }
    }
    
    public Map<Id, Quote> getQuoteMap(Set<Id> quoteIds) {
        quoteRecordMap = new Map<Id, Quote>([Select Id, RecordTypeId, WarehouseCode__c, Account_Name__c,
                                             //Added by Praful - 22-Feb-2021
                                             Duration_Unit__c, Duration__c, Contract_Start_Date__c, Contract_End_Date__c
                                             From Quote Where Id IN:quoteIds]);
        return quoteRecordMap;
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to autopopulate the warehouse lookup field in Quote line items.
Inputs:        List<QuoteLineItem>
----------------------------------------------------------------------------*/
    public void populateDefaultQLIWarehouses(List<QuoteLineItem> newLineItems) {
        List<QuoteLineItem> qliWarehousesToDefault = new List<QuoteLineItem>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(QuoteLineItem quoteLineItem : newLineItems) {
            quoteIds.add(quoteLineItem.QuoteId);
        }
        Map<Id, Quote> quoteRecordMap = getQuoteMap(quoteIds);
        
        for(QuoteLineItem qliRecord : newLineItems) {
            if(qliRecord.Warehouse__c == null) {
                qliWarehousesToDefault.add(qliRecord);
            }
        }
        
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        if(qliWarehousesToDefault.size() > 0) {
            inventoryUtilityControllerObj.populateApplianceAndNormal_QLI_Warehouses(qliWarehousesToDefault, quoteRecordMap);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Method to validate whether the currect warehouse lookup field is populated in Quote line items.
Inputs:        Map<Id, QuoteLineItem>, List<QuoteLineItem>
----------------------------------------------------------------------------*/
    public void validateQLIWarehouses(Map<Id, QuoteLineItem> newLineItemMap, List<QuoteLineItem> oldLineItems) {
        InventoryUtilityController inventoryUtilityControllerObj = new InventoryUtilityController();
        
        Set<Id> quoteIds = new Set<Id>();
        
        for(QuoteLineItem qliRecord : newLineItemMap.values()) {
            quoteIds.add(qliRecord.QuoteId);
        }
        Map<Id, Quote> quoteRecordMap = getQuoteMap(quoteIds);
        
        if(oldLineItems.size() == 0) {
            inventoryUtilityControllerObj.validateApplianceAndNormal_QLI_Warehouses(newLineItemMap.values(), quoteRecordMap);
        } else {
            List<QuoteLineItem> qliWarehousesToValidate = new List<QuoteLineItem>();
            
            for(QuoteLineItem oldQLIRecord : oldLineItems) {
                QuoteLineItem newQLIRecord = newLineItemMap.get(oldQLIRecord.Id);
                if(newQLIRecord.Warehouse__c != null && oldQLIRecord.Warehouse__c != newQLIRecord.Warehouse__c) {
                    qliWarehousesToValidate.add(newQLIRecord);
                }
            }
            
            if(qliWarehousesToValidate.size() > 0) {
                inventoryUtilityControllerObj.validateApplianceAndNormal_QLI_Warehouses(qliWarehousesToValidate, quoteRecordMap);
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Siddhesh Mayekar & Anupam Mishra
Company:       GITL
Description:   Method to auto populate fields from Opportunity Line Item
Inputs:        QLI record 
----------------------------------------------------------------------------*/
    public void populateFieldsFromOLI(List<QuoteLineItem> newItems){
        Set<Id> OLIids = new Set<Id>(); 
        for(QuoteLineItem qlis : newItems)
        {
            OLIids.add(qlis.Opportunity_Line_Item_ID__c);
        }
        
        Map<Id, OpportunityLineitem> OLIrecord = new Map<Id, OpportunityLineItem>([Select Id,Basic_Rate_Per_Unit__c,C_GST__c,S_GST__c,Is_it_a_customised_item__c,Search_Key_I__c,Search_Key_II__c,Competitor__c,Competitor_Price__c,Reason_for_Lost__c,Status__c,Sales_Amount__c,product2Id, product2.Type__c, Unitprice,Competitors__c,
                                                                                   Equipment_Name__c,Tag_Number__c,Sales_Price__c,Conversion_Rate__c from OpportunityLineItem where Id IN : OLIids]);       
        for(QuoteLineItem qli : newItems){
            //Added by siddhesh to populate related Opp Line Item fields on QLI's for Construction B2B
            if(qli.Quote_Record_Type__c == GlobalConstants.RECORDTYPE_Construction_B2B && qli.Opportunity_Line_Item_ID__c != null){
                if(qli.C_GST__c == null && OLIrecord.get(qli.Opportunity_Line_Item_ID__c).C_GST__c  !=null){qli.C_GST__c = OLIrecord.get(qli.Opportunity_Line_Item_ID__c).C_GST__c;}
                
                if(qli.S_GST__c == null && OLIrecord.get(qli.Opportunity_Line_Item_ID__c).S_GST__c !=null){qli.S_GST__c = OLIrecord.get(qli.Opportunity_Line_Item_ID__c).S_GST__c;  }
                
                if(qli.Basic_Rate_Per_Unit__c == null && OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Basic_Rate_Per_Unit__c !=null){qli.Basic_Rate_Per_Unit__c = OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Basic_Rate_Per_Unit__c;}
                
                if(qli.Sales_Amount__c == null && OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Sales_Amount__c !=null){qli.Sales_Amount__c = OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Sales_Amount__c;}
                if(qli.Basic_Rate_Per_unit__c== null && (OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c ==GlobalConstants.TUFF_Duroplast_Landed_Rate || OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c ==GlobalConstants.TUFF_Easy_Fix_Landed_Rate || OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c =='Broken_Blocks'  || OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILE_FIX_PREMIUM_20_KG ||
                           OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILEFIX_PREMIUM_40_KG || OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_20_KG ||OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_40_KG || 
                           OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_20_KG || OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Product2.Type__c== GlobalConstants.TUFF_TILEFIX_SUPREME_PLUS_40_KG)){qli.Basic_Rate_Per_Unit__c = OLIrecord.get(qli.Opportunity_Line_Item_ID__c).UnitPrice; } //Added by poonam (SCF- 102)
                
                
            } 
            //Added by Anupam to populate related Opp Line Item fields on QLI's for Locks B2B
            ////Added Locks B2C ISTD Record Type By Rohit Jadhav
            if((qli.Quote_Record_Type__c == GlobalConstants.RECORDTYPE_Locks_B2B  || qli.Quote_Record_Type__c == GlobalConstants.RECORDTYPE_Locks_B2C_ISTD) && qli.Opportunity_Line_Item_ID__c != null){
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Is_it_a_customised_item__c !=null){qli.Is_it_a_customised_item__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Is_it_a_customised_item__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Search_Key_I__c !=null){qli.Search_Key_I__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Search_Key_I__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Search_Key_II__c !=null){qli.Search_Key_II__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Search_Key_II__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitor__c !=null){qli.Competitor__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitor__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitor_Price__c!=null){qli.Competitor_Price__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitor_Price__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Reason_for_Lost__c!=null){qli.Reason_for_Lost__c=OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Reason_for_Lost__c; }
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Status__c!=null){qli.Status__c=OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Status__c; }
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Is_it_a_customised_item__c)   {qli.Product_Type__c='Customised';}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitors__c !=null){qli.Competitor__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Competitors__c;}
                
            }
            //Added by Rohit Jadhav for PED on 5th July 2023
            if(qli.Quote_Record_Type__c == GlobalConstants.PED_QUOTE_RT && qli.Opportunity_Line_Item_ID__c != null){
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Equipment_Name__c !=null){qli.Equipment_Name__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Equipment_Name__c;}
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Tag_Number__c !=null){qli.Tag_Number__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Tag_Number__c;} 
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Sales_Price__c !=null){qli.Sales_Price__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Sales_Price__c;} 
                
                if(OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Conversion_Rate__c !=null){qli.Conversion_Rate__c =OLIrecord.get(qli.Opportunity_Line_Item_ID__c).Conversion_Rate__c;} 
                
                qli.Approval_Status__c =GlobalConstants.Approval_Required;
            }
        }
    }     
    
    
    /*------------------------------------------------------------------------
Author:        Pawan
Company:       Salesforce
Description:   Method to auto populate defaults
Inputs:         
----------------------------------------------------------------------------*/
    public void populateDefaults(List<QuoteLineItem> newItems){
        Set<String> assets = new Set<String>();
        for(QuoteLineItem qli : newItems){
            if(qli.Asset__c != null){
                assets.add(qli.Asset__c);
            }   
        }
        
        if(assets.size() > 0){
            Map<String,Asset> assetMap = new Map<String,Asset>([Select Id,Equipment_Serial_No__c,Date_of_Commissioning__c FROM ASSET WHERE Id IN :assets ]);
            for(QuoteLineItem qli : newItems){
                if(qli.Asset__c != null && assetMap.containsKey(qli.Asset__c)){
                    qli.Asset_Serial_Number__c = assetMap.get(qli.Asset__c).Equipment_Serial_No__c;
                    if(assetMap.get(qli.Asset__c).Date_of_Commissioning__c != null){
                        DateTime dt = assetMap.get(qli.Asset__c).Date_of_Commissioning__c;
                        qli.Date_of_Dispatch__c = Date.newinstance(dT.year(), dT.month(), dT.day());
                    }                    
                }
            }
        }
    }
    
    
    public void populateDurationFields(List<QuoteLineItem> newLineItemMap){
        
        Set<Id> quoteIds = new Set<Id>();
        
        for(QuoteLineItem qliRecord : newLineItemMap) {
            quoteIds.add(qliRecord.QuoteId);
        }
        Map<Id, Quote> quoteRecordMap = getQuoteMap(quoteIds);
        
        for(QuoteLineItem newQLI : newLineItemMap) {
            newQLI.Duration_Unit__c = quoteRecordMap.get(newQLI.QuoteId).Duration_Unit__c;
            newQLI.Duration__c = quoteRecordMap.get(newQLI.QuoteId).Duration__c;
            newQLI.Contract_Start_Date__c = quoteRecordMap.get(newQLI.QuoteId).Contract_Start_Date__c;
            newQLI.Contract_End_Date__c = quoteRecordMap.get(newQLI.QuoteId).Contract_End_Date__c;
        }
    }
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Method to populate NPP Basic field for SAEPB-44 Appliance B2B
Inputs:         
----------------------------------------------------------------------------*/
    public void populateNPPFieldForAppliances(Map<Id,QuoteLineItem> newQLIRecords){
        Set<Id> qliIds = new Set<Id>();
        Set<String> ItemCode = new Set<String>();
        Set<String> AreaCode = new Set<String>();
        
        List<QuoteLineItem> lstQLI = [SELECT Item_Code__c,Product2Id,Quote.Area_Code__c,Product2.Name,Product2.Tax_Rate__c,PriceBookEntry.UnitPrice,PriceBookEntry.Reference_MRP__c,QuoteId,Quote_Record_Type__c FROM QuoteLineItem WHERE Id IN: newQLIRecords.keySet() AND Quote.Opportunity.Sub_Division__c =:GlobalConstants.B2B_SUBDIVISION AND Quote_Record_Type__c =:GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE];
        
        for(QuoteLineItem qliRecord : lstQLI){
            ItemCode.add(qliRecord.Product2Id);
            AreaCode.add(qliRecord.Quote.Area_Code__c);
        }        
        Map<Id,Discount_Matrix__c> dm;
        if(!ItemCode.isEmpty() && !AreaCode.isEmpty()){
            dm = new Map<Id,Discount_Matrix__c>([ SELECT Item_Code__c,Area__c,Stage__c,Discount_Amount__c FROM Discount_Matrix__c WHERE  Stage__c='Active' and Channel__c='D2D' AND Item_Code__c IN: ItemCode AND Area__c IN: AreaCode]);            
        }
        
        List<QuoteLineItem> lstQLIupdate = new List<QuoteLineItem>();
        for(QuoteLineItem qliRecord : lstQLI){
            for(Discount_Matrix__c dmRecord : dm.values()){
                if(dmRecord.Item_Code__c == qliRecord.Product2Id && dmRecord.Area__c == qliRecord.Quote.Area_Code__c){
                    qliRecord.NPP_Basic__c = qliRecord.PriceBookEntry.UnitPrice - dmRecord.Discount_Amount__c;
                    lstQLIupdate.add(qliRecord); 
                }                     
            }                         
        }
        try{
            if(lstQLIupdate.size()>0)
                update lstQLIupdate; 
        }
        catch(DmlException e){
            Logger.logError('QLIRecordProcessor', 'populateNPPFieldForAppliances', '', e);
        }       
    }
    
    
    /*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       Godrej Infotech
Description:   Update Approval Status on new quote creation
History :      16 Nov 2022 Update Approval Status for Interio B2B
----------------------------------------------------------------------------*/ 
    public void updateApprovalStatus(List<QuoteLineItem> newItems){
        for(QuoteLineitem QLIVar: newItems) {
            if(QLIVar.Quote_Record_Type__c == System.Label.Interio_B2B_Finished_Good_rectype)
                QLIVar.Approval_Status__c = GlobalConstants.DRAFT;        
        }
    }
    /*-------------------------------------------------------------------------------------------
Author:        Sreekanth Jujare
Company:       Godrej Infotech
Description:   Populate Retention values based on Inputs on QLI for SSD
---------------------------------------------------------------------------------------------*/
    public void populateRetentionValues(Map<Id, QuoteLineItem> newItemsMap, Map<Id,QuoteLineItem> oldItemsMap) {
        List<SSDRetentions__c> lstSSDRetentions = SSDRetentions__c.getAll().values();
        Decimal decSumReqCustDiscSalesExp;
        map <Decimal, Decimal> mapDSEMinRet = new map<Decimal, Decimal>();
        map <Decimal, Decimal> mapDSEDelInstln = new map<Decimal, Decimal>();
        Set<Id> qliRecordIdSet=new Set<Id>();
        for (SSDRetentions__c objSSDRetention:lstSSDRetentions){
            mapDSEMinRet.put(objSSDRetention.Disc_Sales_Expenses__c,objSSDRetention.Minimum_Retention__c);
            mapDSEDelInstln.put(objSSDRetention.Disc_Sales_Expenses__c,objSSDRetention.Delivery_and_Installation__c);
        }
        set<Id> qliIdSet = new set<id>();
        for (QuoteLineitem QLIVar : newItemsMap.values()) {
            if (QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_SSD && QLIVar.QuoteId != null){
                qliIdSet.add(QLIVar.Id);
            }
        } 
        if(!qliIdSet.isEmpty())
        {
            for(QuoteLineItem qliRecord:[Select Id from QuoteLineItem where Id IN :qliIdSet and (Quote.Booking_Option__c !=: GlobalConstants.DEALER_PRICE and Quote.Transaction_Type__c !=: GlobalConstants.DIRECT_BILLING_TO_CUSTOMER and Quote.Transaction_Type__c !=: GlobalConstants.DIRECT_SCHEME_BILLING)])
            {
                qliRecordIdSet.add(qliRecord.Id);
            }
            if(!qliRecordIdSet.isEmpty())
            {
                for (QuoteLineitem qliRecord : newItemsMap.values()) {
                    if (qliRecordIdSet.contains(qliRecord.Id)){
                        decSumReqCustDiscSalesExp= qliRecord.Requested_Customer_Discount__c+((qliRecord.Sales_Expenses_SSD__c==null)?0:qliRecord.Sales_Expenses_SSD__c);
                        decSumReqCustDiscSalesExp = decSumReqCustDiscSalesExp>=GlobalConstants.FORTY ? GlobalConstants.FORTY : (decSumReqCustDiscSalesExp.intValue()+0.0);
                            if (mapDSEMinRet.containsKey(decSumReqCustDiscSalesExp)){
                                qliRecord.Min_Retention_SSD__c = mapDSEMinRet.get(decSumReqCustDiscSalesExp);
                                qliRecord.Regular_Delivery_and_Installation_SSD__c = mapDSEDelInstln.get(decSumReqCustDiscSalesExp);
                            }decSumReqCustDiscSalesExp=0;//resetting the summation variable
                    }
                }
            }
        }
    }
    
    // Added by Rohit Jadhav for PED on 6th july 2023
    public void populateDefaultsPED(List<QuoteLineItem> newItems){
        Set<String> quoteIdSet = new Set<String>();
        for(QuoteLineItem qli : newItems){
            if(qli.Quote_Record_Type__c == GlobalConstants.PED_QUOTE_RT && qli.Opportunity_Line_Item_ID__c==null){
                quoteIdSet.add(qli.QuoteId);
            }   
        }
        
        if(quoteIdSet.size() > 0){
            Map<String,Quote> quoteMap = new Map<String,Quote>([Select Id,Conversion_Rate__c FROM Quote WHERE Id IN :quoteIdSet ]);
            for(QuoteLineItem qli : newItems){
                if(quoteMap.containsKey(qli.QuoteId)){
                    qli.Conversion_Rate__c = quoteMap.get(qli.QuoteId).Conversion_Rate__c;
                    if(qli.Sales_Price__c == null){
                        qli.Sales_Price__c=qli.UnitPrice * qli.Conversion_Rate__c;
                    }else{
                        qli.UnitPrice=qli.Sales_Price__c * qli.Conversion_Rate__c;
                    }
                    qli.Approval_Status__c=GlobalConstants.APPROVAL_REQUIRED_STATUS;
                }
            }
        }
    }
    
        
    /*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   Update Dealer Discount of QLI for MHE Equipment Secondary records post  quote record gets approved. Similar code was written in updateCustomerDiscount which is commented.
               Also commented Approved Customer Discount AND Approval Status line of code as it was affecting Total Customer Price of Quote and was showing Approval Not required for QLI even after submitting for approval respectively.
History :      08 Dec 2023 
----------------------------------------------------------------------------*/ 
    public void updateDealerDiscountforMHE(List<QuoteLineItem> newItems){
        try{
            for(QuoteLineItem QLIVar: newItems ){
                if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS 
                   && (QLIVar.Product_Storage_Clasification__c == Decimal.valueof(1) || QLIVar.Skip_Generic_SPR__c==True) //added by pankaj on 12 Oct 2021 Skip_Generic_SPR__c to skip dealer discount on freight
                   && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                       if(QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_BASE_PRODUCT 
                          && String.isNotBlank(System.Label.BASE_PRODUCT_DISCOUNT)){
                              
                              QLIVar.Dealer_Discount__c = Decimal.valueOf(System.Label.BASE_PRODUCT_DISCOUNT);
                          }else if((QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_ATTACHMENTS || QLIVar.Component_Type__c == GlobalConstants.COMPONENT_TYPE_ACCESSORIES) 
                                   && String.isNotBlank(System.Label.ATTACHMENTS_AND_ACCESSORIES_DISCOUNT)){
                                       QLIVar.Dealer_Discount__c = Decimal.valueOf(System.Label.ATTACHMENTS_AND_ACCESSORIES_DISCOUNT);
                                   }
                       /*QLIVar.Approved_Customer_Discount__c = QLIVar.Requested_Customer_Discount__c;
                       QLIVar.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS;*/ 
                       
                   }
                else if(QLIVar.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS // for Product_Storage_Clasification as 'Category B' i.e 2 and as Category 'C' Or Category 'AB' i.e 3 
                        && (QLIVar.Product_Storage_Clasification__c == Decimal.valueof(2) || QLIVar.Product_Storage_Clasification__c == Decimal.valueof(3)) && QLIVar.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                            if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1) && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V1) && QLIVar.Requested_Customer_Discount__c >= 0 && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)){
                                QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V1)); 
                            }else if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)  && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2) && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V2) && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V1)  && QLIVar.Requested_Customer_Discount__c <= Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){
                                QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V2));
                            }else if(String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2) && String.isNotBlank(System.Label.MHE_CATEGORY_B_DISCOUNT_V3) && QLIVar.Requested_Customer_Discount__c > Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_MIN_V2)){
                                QLIVar.Dealer_Discount__c = (QLIVar.Requested_Customer_Discount__c + Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3))-((QLIVar.Requested_Customer_Discount__c/100)*Decimal.valueOf(System.Label.MHE_CATEGORY_B_DISCOUNT_V3));
                            }
                            /*QLIVar.Approved_Customer_Discount__c = QLIVar.Requested_Customer_Discount__c;
                             QLIVar.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS; */
                        } 
            }
        }
        catch(Exception e){
            Logger.logError('QLIRecordProcessor', 'updateDealerDiscountforMHE', '', e);
        }
    }
    
/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   If Requested Dealer Amount is lesser/Requested Discount % is higher than DPP for Category A/AB Products then approval is required. For SMEPB -111
History :      08 Dec 2023 Initial Release
----------------------------------------------------------------------------*/ 
    public void isApprovalRequiredForCategoryAorAB(Map<Id,QuoteLineItem> newItems, Map<Id,QuoteLineItem> oldItems){
        try{
            Map<Id,PricebookEntry> priceBookEntryMap = new Map<Id,PricebookEntry>();
            Set<Id> qliIds = new Set<Id>();
            Set<Id> qliProductIds = new Set<Id>();
            for(QuoteLineItem qli : newItems.values()){
                if(qli.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS
                   && qli.Requested_Customer_Discount__c != null && 
                   (oldItems.get(qli.Id).Requested_Customer_Discount__c == null || 
                    (oldItems.get(qli.Id).Requested_Customer_Discount__c!=null && 
                     qli.Requested_Dealer_Discount__c != oldItems.get(qli.Id).Requested_Customer_Discount__c))
                  ){
                      qliIds.add(qli.Id); 
                      qliProductIds.add(qli.Product2Id);
                  }     
            }
            
            if(!qliProductIds.isEmpty()){
                priceBookEntryMap = new Map<Id,PricebookEntry>([SELECT Id,UnitPrice,Product2Id,PriceBook2.Name
                                                                FROM PricebookEntry
                                                                WHERE Product2Id IN: qliProductIds
                                                                AND (PriceBook2.Name LIKE : ('%'+GlobalConstants.DPP_List_Price+'%') OR PriceBook2.Name LIKE  : ('%'+GlobalConstants.FG_List_Price+'%'))]);  
            }
            
            if(!qliIds.isEmpty()){
                for(QuoteLineItem qli : newItems.values()){
                    Decimal dppPrice;
                    Decimal reqDealerDisc;
                    Decimal fopPrice;
                    if(qliIds.contains(qli.Id) && qli.Requested_Customer_Discount__c != null && (oldItems.get(qli.Id).Requested_Customer_Discount__c == null || (oldItems.get(qli.Id).Requested_Customer_Discount__c!=null && qli.Requested_Customer_Discount__c != oldItems.get(qli.Id).Requested_Customer_Discount__c))&& (qli.Product_Storage_Clasification__c == GlobalConstants.Product_Category_A  || qli.Product_Storage_Clasification__c == GlobalConstants.Product_Category_AB_C)){
                        for(PriceBookEntry pbe : priceBookEntryMap.values()){
                            if(pbe.Product2Id == qli.Product2Id){
                                if(pbe.PriceBook2.Name.contains(GlobalConstants.DPP_List_Price)){
                                    dppPrice = pbe.UnitPrice; }
                                if(pbe.PriceBook2.Name.contains(GlobalConstants.FG_List_Price)){
                                    fopPrice = pbe.UnitPrice;
                                    reqDealerDisc =  fopPrice - ((qli.Requested_Customer_Discount__c/100) * (fopPrice)); }
                            }
                        }
                        if(reqDealerDisc < dppPrice){
                                qli.Check_Category_A_Secondary__c = GlobalConstants.True_Constant; 
                                  
                        }
                        else if(reqDealerDisc >= dppPrice){
                            qli.Check_Category_A_Secondary__c = GlobalConstants.False_Constant;} 
                    }
                }
            } 
        }
        catch(Exception e){
            Logger.logError('QLIRecordProcessor', 'isApprovalRequiredForCategoryAorAB', '', e);
        }
        
    }
    
/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   To set quote level checkbox for Category A or B as true on the basis of product category for Secondary MHE Equipment Quote.
               Based on this checkbox, approval process entry criteria will be check developed for MHE Equipment Secondary.
History :      20 Dec 2023  Initial Release
----------------------------------------------------------------------------*/ 
    public void isSecondaryCategoryAorCategoryB(List<QuoteLineItem> newItems, Map<Id,QuoteLineItem> oldItems){
        try{
            Set<Id> quoteIdForCategoryB = new Set<Id>();
            Set<Id> quoteIdForCategoryA = new Set<Id>();
            List<Quote> quoteList = new List<Quote>();
            Map<Id,Quote> quoteMap;
            if(!GlobalConstants.SKIP_Recursion){
                for(QuoteLineItem qli : newItems){
                    if(qli.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS && qli.Product_Storage_Clasification__c == GlobalConstants.Product_Category_B && qli.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                        quoteIdForCategoryB.add(qli.QuoteId);}
                    else if(qli.Quote_Record_Type__c == GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS && qli.Product_Storage_Clasification__c == GlobalConstants.Product_Category_A && qli.Order_Type__c == GlobalConstants.ORDER_TYPE_SECONDARY){
                        quoteIdForCategoryA.add(qli.QuoteId);}
                }
                if(!quoteIdForCategoryB.isEmpty()){
                    quoteMap = new Map<Id,Quote>([SELECT Id,Check_Secondary_Category_A__c,Check_Secondary_Category_B__c FROM Quote  WHERE Id IN:quoteIdForCategoryB AND  Check_Secondary_Category_B__c =: GlobalConstants.False_Constant]);   }
                else if(!quoteIdForCategoryA.isEmpty()){
                    quoteMap = new Map<Id,Quote>([SELECT Id,Check_Secondary_Category_A__c,Check_Secondary_Category_B__c FROM Quote WHERE Id IN:quoteIdForCategoryA AND Check_Secondary_Category_A__c =: GlobalConstants.False_Constant]);   }
                
                if(quoteMap!=null && !quoteMap.isEmpty()){
                    for(Quote qt : quoteMap.values()){
                        if(qt.Check_Secondary_Category_B__c == GlobalConstants.False_Constant){
                            qt.Check_Secondary_Category_B__c = GlobalConstants.True_Constant;
                            qt.Check_Secondary_Category_A__c = GlobalConstants.False_Constant;
                            quoteList.add(qt);}
                        else if(qt.Check_Secondary_Category_A__c == GlobalConstants.False_Constant){
                            qt.Check_Secondary_Category_A__c = GlobalConstants.True_Constant; //Used to check approval process of PAR
                            qt.Check_Secondary_Category_B__c = GlobalConstants.False_Constant;
                            quoteList.add(qt); }  
                    }
                }
                if(!quoteList.isEmpty()){
                    update quoteList;
                    GlobalConstants.SKIP_Recursion = true; //To avoid 101 query error 
                }
            }
        }
        catch(Exception e){
            Logger.logError('QLIRecordProcessor', 'isSecondaryCategoryAorCategoryB', '', e);
        }
    } 
     // Added by snehal W 17/01/24
    public void handleBeforeInsertOrDelete(List<QuoteLineItem> QuoteLineItems) {
        Set<Id> quoteIds = new Set<Id>();
        // Collecting the Quote Ids from the Quote Line Items being inserted
        for (QuoteLineItem qli : QuoteLineItems) {
            if(qli.Quote_Record_Type__c == GlobalConstants.Interio_B2B_Finished_Good_RT){
            quoteIds.add(qli.QuoteId);
            }
        }
        Map<Id, Quote> quotesWithStatus = new Map<Id, Quote>(
            [SELECT Id, Approval_Status__c FROM Quote WHERE Id IN :quoteIds]// Query for the Approval Status of the associated Quotes
        );
        
        // Iterate through the Quote Line Items to check the Approval Status
        for (QuoteLineItem qli : QuoteLineItems) {
            Quote associatedQuote = quotesWithStatus.get(qli.QuoteId);
            if (associatedQuote != null && 
                (associatedQuote.Approval_Status__c == 'Submitted for Approval' || 
                 associatedQuote.Approval_Status__c == 'Approved')) {
                qli.addError('Cannot Insert/Delete Quote Line Item when Quote Status is in "Submitted for Approval" or "Approved".');
            }
        }
}
  
}