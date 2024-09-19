@isTest
class UpdateQliListOfApproversHelperTest{
@testSetup
    public static void createData(){   
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new TestUserBuilder()
            .setProfileId(userProfile.Id)
            .setLastName('GNBAdmin User')
            .setLogisticCompany('5020')
            .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
            .getTestRecord();        
        userRec.Sub_Division__c = 'B2B';
        userRec.Area_Code__c = 'WN1';
        userRec.IsActive = true;  
        userRec.Persona__c='Zonal Head';
        insert userRec;
        
        System.runAs(userRec)
        {    
            User userRec1 = new TestUserBuilder()
                .setProfileId(userProfile.Id)
                .setLogisticCompany('5020')
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();        
            userRec1.Sub_Division__c = 'B2B';
            userRec1.Area_Code__c = 'WN1';
            userRec1.IsActive = true;    
            userRec1.ManagerId=userRec.Id;
            insert userRec1;
            
            User userRec2 = new TestUserBuilder()
                .setProfileId(userProfile.Id)
                .setLogisticCompany('5020')
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();        
            userRec2.Sub_Division__c = 'B2B';
            userRec2.Area_Code__c = 'WN1';
            userRec2.IsActive = true; 
            userRec2.ManagerId=userRec1.Id;
            insert userRec2;
            
            User userRec3 = new TestUserBuilder()
                .setProfileId(userProfile.Id)
                .setLogisticCompany('5020')
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();        
            userRec3.Sub_Division__c = 'B2B';
            userRec3.Area_Code__c = 'WN1';
            userRec3.IsActive = true; 
            userRec3.ManagerId=userRec2.Id;
            insert userRec3;
            
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getTestRecord();
            acc.Industry='Manufacturing';
            acc.Account_Code__c='TPL'; 
            Insert acc;
            
            List<String> oppOrderTypeList=new List<String>();
            oppOrderTypeList.add(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER);
            oppOrderTypeList.add(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES);
            oppOrderTypeList.add(GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES);
            
            List<String> oppInterioSubDivisionList=new List<String>();
            oppInterioSubDivisionList.add(GlobalConstants.Interio_Sub_Division_B2B_KAM);
            oppInterioSubDivisionList.add(GlobalConstants.Interio_Sub_Division_B2B_NON_KAM);
            oppInterioSubDivisionList.add(GlobalConstants.Interio_Sub_Division_B2B_BD);
            
            List<Opportunity> oppList=new List<Opportunity>();
            for( String orderType : oppOrderTypeList)
            {
                for(String interioSubDivison:oppInterioSubDivisionList)
                {
                    Opportunity opp=new TestOpportunityBuilder()
                        .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId())
                        .setAccountId(acc.Id)
                        .getTestRecord();
                    opp.Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT;        
                    opp.Sales_Branch_Name__c='5010';
                    opp.Sales_Zone__c ='EST';
                    opp.StageName ='Qualification';
                    opp.Area_Code__c='WN1';        
                    opp.Sub_Division__c='B2B';
                    opp.Order_Type__c=orderType;
                    opp.Interio_Sub_Division__c=interioSubDivison;
                    opp.OwnerId=userRec3.Id;
                    oppList.add(opp);
                }
            }        
            insert oppList;
            
            List<String> productLineList=new List<String>();  
            productLineList.add(GlobalConstants.Product_Line_DESKING);
            productLineList.add(GlobalConstants.Product_Line_SEATING);
            productLineList.add(GlobalConstants.Product_Line_STORAGE);
            productLineList.add(GlobalConstants.Product_Line_OPOS);
            productLineList.add(GlobalConstants.Product_Line_LAB);
            productLineList.add(GlobalConstants.Product_Line_HEALTHCARE);
            productLineList.add(GlobalConstants.Product_Line_B2C);       
            
            List<Product2> productList=new List<Product2>();
            
            Integer count=1;
            for(String productLine:productLineList)
            {
                Product2 product = new TestProductBuilder()
                    .setItemCode('0000'+count)
                    .setProductCode('0000'+count)
                    .setIsActive(true)
                    .setComponentType(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE)
                    .setProductLine(productLine)
                    .getTestRecord();                
                product.Is_Independent_product__c = false;
                product.Product_Line__c=productLine;
                product.Product_Type__c=productLine;
                product.Product_Class__c='DTWHAA';
                product.Is_Generic_Product__c= true;
                product.Is_New_Equipment__c=true;  
                productList.add(product);
                count++;
            }             
            insert productList;
            
            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntryList=new List<PricebookEntry>();
            
            for(Product2 product : productList) {
                PricebookEntry standardPrice = new PricebookEntry(
                    Pricebook2Id = pricebookId, Product2Id = product.Id,
                    UnitPrice = 10000, IsActive = true);
                pricebookEntryList.add(standardPrice);
            }
            insert pricebookEntryList;
            
            
            List<Quote> quoteList=new List<Quote>();
            for(Opportunity opp:oppList)
            {
                if(opp.Order_Type__c==GlobalConstants.DIRECT_BILLING_TO_CUSTOMER)
                {
                    Quote objApplQuote1 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote1.ExpirationDate=System.today()+1;
                    objApplQuote1.Payment_Terms__c='10';
                    objApplQuote1.Dealer_Name__c= null;
                    objApplQuote1.Dealer_Retention__c=0;
                    objApplQuote1.Minimum_Dealer_Retention__c=0;
                    objApplQuote1.Dealer_Margin_Dealer_order__c=0;
                    objApplQuote1.Transaction_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
                    objApplQuote1.Area_Code__c='WN1';    
                    quoteList.add(objApplQuote1); 
                }
                else if(opp.Order_Type__c==GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES)
                {
                    Quote objApplQuote1 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote1.ExpirationDate=System.today()+1;
                    objApplQuote1.Payment_Terms__c='10';
                    objApplQuote1.Dealer_Name__c= null;
                    objApplQuote1.Dealer_Retention__c=0;
                    objApplQuote1.Dealer_Margin_Dealer_order__c=0;
                    objApplQuote1.Area_Code__c='WN1';  
                    objApplQuote1.Transaction_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES;
                    objApplQuote1.Req_WD_CONT__c=5;
                    objApplQuote1.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                    objApplQuote1.WD_marginfor_installation_above_std__c=0;
                    objApplQuote1.Minimum_Dealer_Retention__c=0;
                    quoteList.add(objApplQuote1); 
                    
                    Quote objApplQuote2 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote2.ExpirationDate=System.today()+1;
                    objApplQuote2.Payment_Terms__c='10';
                    objApplQuote2.Dealer_Name__c= null;
                    objApplQuote2.Dealer_Retention__c=0;
                    objApplQuote2.Dealer_Margin_Dealer_order__c=0;
                    objApplQuote2.Area_Code__c='WN1';  
                    objApplQuote2.Transaction_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES;
                    objApplQuote2.Req_WD_CONT__c=15;
                    objApplQuote2.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                    objApplQuote2.WD_marginfor_installation_above_std__c=0;
                    objApplQuote2.Minimum_Dealer_Retention__c=0;         
                    quoteList.add(objApplQuote2);
                }
                else if(opp.Order_Type__c==GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES)
                {
                    Quote objApplQuote1 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote1.ExpirationDate=System.today()+1;
                    quoteList.add(objApplQuote1); 
                    
                    Quote objApplQuote2 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote2.ExpirationDate=System.today()+1;
                    objApplQuote2.Area_Code__c='WN1';  
                    quoteList.add(objApplQuote2);
                    
                    Quote objApplQuote3 = new TestQuoteBuilder()
                        .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                        .setOpportunityId(opp.Id)
                        .setPricebook2Id(pricebookId)
                        .getTestRecord(); 
                    objApplQuote3.ExpirationDate=System.today()+1;
                    objApplQuote3.Req_WD_CONT__c=15;
                    objApplQuote3.Area_Code__c='WN1';  
                    quoteList.add(objApplQuote3);
                }
            }  
            disableTriggers();
            insert quoteList;    
            
        }
    }
    private static void disableTriggers()
    {
        GlobalConstants.SKIP_QUOTE_LOCK = true; 
        QuoteTriggerHandler.TriggerDisabled = true;
        QliTriggerHandler.TriggerDisabled = true;
        OpportunityTriggerHandler.TriggerDisabled = true;
    }
    
    private static QuoteLineItem createQuoteLineItem(Id quoteId,Id pbeId,Id productId,Integer reqCustDiscount,Integer reqNetRlizdBscDisc,Integer reqWDCont,String productLine){
        QuoteLineItem qli=new TestQuoteLineItemBuilder()
            .setQuoteId(quoteId)
            .setUnitPrice(1000)
            .setSequenceNumber(1)
            .setPriceBookEntryId(pbeId)
            .getTestRecord();
        qli.Product2Id=productId;
        qli.Requested_Customer_Discount__c=reqCustDiscount;
        qli.Req_Net_Rlizd_Bsc_Disc__c=reqNetRlizdBscDisc;
        qli.Requested_WD_CONT_Req_Disc_Basic__c =reqWDCont;
        qli.Requested_WD_Retention__c=0;
        qli.Requested_SAC_ORC__c=0;
        qli.Requested_Dealer_Discount__c=0;
        qli.Approval_Status__c='Submitted for Approval';
        qli.List_of_Approvers__c=UserInfo.getUserId();
        qli.Product_Line_c__c=productLine;
        return qli;
    }
    
    static testMethod void test_DirectBillingToCustomer1(){  
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Quote quote=[Select Id,Transaction_Type__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 1]; 
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry]; 
       
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>(); 
            
            for(PricebookEntry pbe:pricebookEntryList)
            {
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,4,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,8,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,13,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,20,20,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,31,31,0,pbe.Product2.Product_Type__c));    
            }
            insert quoteLineItemList;
            List<String> lstQli = new List<String>();
            for(QuoteLineItem qli :quoteLineItemList)
            {
                if(qli.Product_Line_c__c!=GlobalConstants.Product_Line_LAB &&
                   qli.Product_Line_c__c!=GlobalConstants.Product_Line_HEALTHCARE &&
                   qli.Product_Line_c__c!=GlobalConstants.Product_Line_B2C)
                    lstQli.add(qli.Id);
            } 
            UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            Opportunity opp=[Select Id,Interio_Sub_Division__c from Opportunity where Id=:quote.OpportunityId];
            opp.Interio_Sub_Division__c='';
            update opp;
            quote.Interio_Sub_Division__c='';
            update quote;
            
            lstQli = new List<String>();
            for(QuoteLineItem qli :quoteLineItemList)
            {
                if(qli.Product_Line_c__c==GlobalConstants.Product_Line_LAB ||
                   qli.Product_Line_c__c==GlobalConstants.Product_Line_HEALTHCARE ||
                   qli.Product_Line_c__c==GlobalConstants.Product_Line_B2C)
                    lstQli.add(qli.Id);
            } 
            UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer2(){   
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){            
            Quote quote=[Select Id,Transaction_Type__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_NON_KAM LIMIT :1]; 
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];        
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(PricebookEntry pbe:pricebookEntryList)
            { 
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,4,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,8,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,13,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,20,20,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,31,31,0,pbe.Product2.Product_Type__c));
            }
            insert quoteLineItemList;
            List<String> lstQli = new List<String>();
            for(QuoteLineItem qli :quoteLineItemList)
            {
                lstQli.add(qli.Id);
            } 
            UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer3(){    
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            Quote quote=[Select Id,Transaction_Type__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_BD LIMIT :1]; 
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(PricebookEntry pbe:pricebookEntryList)
            {
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,4,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,8,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,13,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,20,20,0,pbe.Product2.Product_Type__c));
                quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,31,31,0,pbe.Product2.Product_Type__c));
            }
            insert quoteLineItemList;
            List<String> lstQli = new List<String>();
            for(QuoteLineItem qli :quoteLineItemList)
            {
                lstQli.add(qli.Id);
            } 
            UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer4(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Quote> quoteList=new List<Quote>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=5;
                quoteList.add(quote);
            }            
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,5,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
     static testMethod void test_DirectBillingToCustomer4_1(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Set<Id> opptyIdSet=new Set<Id>();
            List<Quote> quoteList=new List<Quote>();
            List<Opportunity> opptyList=new List<Opportunity>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=5;
                quoteList.add(quote);
                opptyIdSet.add(quote.OpportunityId);
            }
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id IN:opptyIdSet])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,5,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer5(){ 
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Quote> quoteList=new List<Quote>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=15;
                quoteList.add(quote);
            }
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,15,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer5_1(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Set<Id> opptyIdSet=new Set<Id>();
            List<Quote> quoteList=new List<Quote>();
            List<Opportunity> opptyList=new List<Opportunity>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=15;
                quoteList.add(quote);
                opptyIdSet.add(quote.OpportunityId);
            }
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id IN:opptyIdSet])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,15,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer6(){ 
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Quote> quoteList=new List<Quote>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                quoteList.add(quote);
            }
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,0,pbe.Product2.Product_Type__c));          
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer6_1(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Set<Id> opptyIdSet=new Set<Id>();
            List<Quote> quoteList=new List<Quote>();
            List<Opportunity> opptyList=new List<Opportunity>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                quoteList.add(quote);
                opptyIdSet.add(quote.OpportunityId);
            }
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id IN:opptyIdSet])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer7(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Quote> quoteList=new List<Quote>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=5;
                quote.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                quoteList.add(quote);
            }
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,5,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
     static testMethod void test_DirectBillingToCustomer7_1(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Set<Id> opptyIdSet=new Set<Id>();
            List<Quote> quoteList=new List<Quote>();
            List<Opportunity> opptyList=new List<Opportunity>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=5;
                quote.WD_margin_for_Delivery_beyond_Mun_lmts__c=5;
                quoteList.add(quote);
                opptyIdSet.add(quote.OpportunityId);
            }
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id IN:opptyIdSet])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,0,0,5,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomer8(){ 
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Quote> quoteList=new List<Quote>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=15;
                quoteList.add(quote);
            }
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,15,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
    
      static testMethod void test_DirectBillingToCustomer8_1(){ 
       disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            Set<Id> opptyIdSet=new Set<Id>();
            List<Quote> quoteList=new List<Quote>();
            List<Opportunity> opptyList=new List<Opportunity>();
            for(Quote quote: [Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                              Minimum_Dealer_Retention__c,OpportunityId from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER])
            {
                quote.Req_WD_CONT__c=15;
                quoteList.add(quote);
                opptyIdSet.add(quote.OpportunityId);
            }
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id IN:opptyIdSet])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,15,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                   lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }  
            Test.stopTest();
        }
    }
   
    static testMethod void test_DirectBillingToCustomerWSeries1(){   
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 3]; 
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            
            quoteList[0].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            quoteList[1].Transaction_Type_c__c='Scheme';
            quoteList[2].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            update quoteList;
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,5,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,20,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,35,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerWSeries1_1(){   
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Opportunity> opptyList=new List<Opportunity>();
            List<Quote> quoteList=[Select Id,Transaction_Type__c,OpportunityId,Interio_Sub_Division__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 3]; 
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id=:quoteList[0].OpportunityId or Id=:quoteList[1].OpportunityId or Id=:quoteList[2].OpportunityId])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;            
            quoteList[0].Interio_Sub_Division__c='';
            quoteList[1].Interio_Sub_Division__c='';
            quoteList[2].Interio_Sub_Division__c='';
            quoteList[0].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            quoteList[1].Transaction_Type_c__c='Scheme';
            quoteList[2].Transaction_Type_c__c='3RD PARTY CONTRACTOR';            
            update quoteList;
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
           
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,5,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,20,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,35,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerWSeries2(){       
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_NON_KAM LIMIT 3]; 
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];         
       
            quoteList[0].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            quoteList[1].Transaction_Type_c__c='Scheme';
            quoteList[2].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            
            update quoteList;
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,5,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,20,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,35,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerWSeries3(){   
        disableTriggers();        
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_W_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_BD LIMIT 3]; 
            quoteList[0].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            quoteList[1].Transaction_Type_c__c='Scheme';
            quoteList[2].Transaction_Type_c__c='3RD PARTY CONTRACTOR';
            update quoteList;
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];        
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,4,5,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,8,20,0,pbe.Product2.Product_Type__c));
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,13,35,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerRSeries1(){      
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                                   Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 2]; 
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C]; 
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);               
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerRSeries1_1(){      
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            List<Opportunity> opptyList=new List<Opportunity>();
            List<Quote> quoteList=[Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                                   Minimum_Dealer_Retention__c,OpportunityId,Interio_Sub_Division__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 2]; 
            for(Opportunity opp:[Select Id,Interio_Sub_Division__c from Opportunity where Id=:quoteList[0].OpportunityId or Id=:quoteList[1].OpportunityId])
            {
                opp.Interio_Sub_Division__c='';
                opptyList.add(opp);
            }
            update opptyList;
            quoteList[0].Interio_Sub_Division__c='';
            quoteList[1].Interio_Sub_Division__c='';
            update quoteList;
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c=:GlobalConstants.Product_Line_LAB or Product2.Product_Type__c=:GlobalConstants.Product_Line_HEALTHCARE or Product2.Product_Type__c=:GlobalConstants.Product_Line_B2C]; 
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                        lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerRSeries2(){  
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                                   Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_NON_KAM LIMIT 2]; 
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];         
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_DirectBillingToCustomerRSeries3(){       
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                                   Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_BD LIMIT 2];   
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];        
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,31,5,0,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    static testMethod void test_DirectBillingToCustomerRSeries4(){       
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            List<Quote> quoteList=[Select Id,Transaction_Type__c,Req_WD_CONT__c,WD_margin_for_Delivery_beyond_Mun_lmts__c,WD_marginfor_installation_above_std__c,
                                   Minimum_Dealer_Retention__c from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER_R_SERIES and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_BD LIMIT 2];   
            
            List<PricebookEntry> pricebookEntryList=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry where Product2.Product_Type__c!=:GlobalConstants.Product_Line_LAB and Product2.Product_Type__c!=:GlobalConstants.Product_Line_HEALTHCARE and Product2.Product_Type__c!=:GlobalConstants.Product_Line_B2C];        
            
            Test.startTest();
            List<QuoteLineItem> quoteLineItemList=new List<QuoteLineItem>();
            for(Quote quote:quoteList)
            {
                quoteLineItemList=new List<QuoteLineItem>();
                for(PricebookEntry pbe:pricebookEntryList)
                {
                    quoteLineItemList.add(createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,31,5,15,pbe.Product2.Product_Type__c));
                }
                insert quoteLineItemList;
                List<String> lstQli = new List<String>();
                for(QuoteLineItem qli :quoteLineItemList)
                {
                    lstQli.add(qli.Id);
                } 
                UpdateQliListOfApprovers.handleQuoteSubmit(quote.id,lstQli);
            }
            Test.stopTest();
        }
    }
    
    static testMethod void test_handleAssignment(){ 
        disableTriggers();
        User adminUser = [Select Id,LastName From User where LastName='GNBAdmin User' Limit 1];  
        System.runAs(adminUser){
            
            Quote quote=[Select Id,Transaction_Type__c,
                         Opportunity.Owner.ManagerId,Opportunity.Owner.Manager.Persona__c,Opportunity.Owner.Manager.Name,
                         Opportunity.Owner.Manager.ManagerId,Opportunity.Owner.Manager.Manager.Persona__c,Opportunity.Owner.Manager.Manager.Name,
                         Opportunity.Owner.Manager.Manager.ManagerId,Opportunity.Owner.Manager.Manager.Manager.Persona__c,Opportunity.Owner.Manager.Manager.Manager.Name from Quote where Transaction_Type__c=:GlobalConstants.DIRECT_BILLING_TO_CUSTOMER and Interio_Sub_Division__c =:GlobalConstants.Interio_Sub_Division_B2B_KAM LIMIT 1]; 
            PricebookEntry pbe=[Select Id,Product2Id,Product2.Product_Line__c,Product2.Product_Type__c from PricebookEntry limit 1]; 
            
            Test.startTest();
            QuoteLineItem qliRecord=createQuoteLineItem(quote.Id,pbe.Id,pbe.Product2Id,5,5,0,pbe.Product2.Product_Type__c);      
            insert qliRecord;
            
            QuoteLineItem qli=[Select Id,QuoteId,List_of_Approvers__c,Current_Approver__c,Pending_with_owner__c,
                               Quote.Opportunity.Owner.ManagerId,Quote.Opportunity.Owner.Manager.Persona__c,Quote.Opportunity.Owner.Manager.Name,
                               Quote.Opportunity.Owner.Manager.ManagerId,Quote.Opportunity.Owner.Manager.Manager.Persona__c,Quote.Opportunity.Owner.Manager.Manager.Name,
                               Quote.Opportunity.Owner.Manager.Manager.ManagerId,Quote.Opportunity.Owner.Manager.Manager.Manager.Persona__c,Quote.Opportunity.Owner.Manager.Manager.Manager.Name from QuoteLineItem LIMIT 1]; 
            
            UpdateQliListOfApproversHelper apexInstance=new UpdateQliListOfApproversHelper();
            apexInstance.handleAssignment(GlobalConstants.Interio_VP_PERSONA,qli,1,null);  
            apexInstance.handleAssignment(GlobalConstants.Interio_VP_PERSONA,qli,2,null);  
            apexInstance.handleAssignment(GlobalConstants.Interio_VP_PERSONA,qli,3,null);  
            apexInstance.handleAssignment(GlobalConstants.Interio_VP_PERSONA,qli,4,null);  
            Test.stopTest(); 
        }
    }
}