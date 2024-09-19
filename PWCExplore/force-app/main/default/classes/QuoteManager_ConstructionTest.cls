@isTest
public class QuoteManager_ConstructionTest {
    @TestSetup 
    static void prepareData(){
        
        Runtime_Execution__c csdata = new Runtime_Execution__c();
        csdata.AddressByBPTriggerDisabled__c = true;
        csdata.UserTriggerDisabled__c  = true;
        csdata.ProductTriggerDisabled__c  = true;    
        csdata.ZipCodeRuleTriggerDisabled__c  = true;    
        csdata.AssetTriggerDisabled__c = true;
        csdata.OpportunityProductTriggerDisabled__c = true;
        csdata.OpportunityTriggerDisabled__c = true;
        csdata.BranchTriggerDisabled__c=true;
        csdata.QuoteTriggerDisabled__c=true;
        csdata.QLITriggerDisabled__c=true;
        insert csdata;
        
        Product2 product = new TestProductBuilder().setName(System.Label.Construction_SO_from_SF_to_LN ).setDescription('GX 300 Forklift')
            .setItemCode(System.Label.Construction_SO_from_SF_to_LN ).setComponentType('Base Product')
            .setProductCode(System.Label.Construction_SO_from_SF_to_LN ).getTestRecord();
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 10000, IsActive = true);
        insert pbe;
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Construction';
        accountRecord.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
            //.setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            //.setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
            //.getSavedTestRecord();
        accountRecord.Construction_LOB__c = 'RMC';
        insert accountRecord;
        
        Address__c firstaddress = new Address__c(Name__c  = 'firstaddress SoldToPricebookUtility', Address_Type__c  = 'B2B',Building__c='Raevenues',Street__c = '2nd street');
        insert firstaddress;
        
        //Added by siddhesh
        Branch__c branch = new Branch__c();
            branch.Business_Partner__c = accountRecord.Id;
            branch.Business_Partner_Status__c = 'Open';
            branch.Business_Partner_Status_Ship_To__c = 'Open';
            branch.Branch_Name__c = '2110';
            branch.Line_of_Business__c = 'AGRO';
            branch.Area__c = 'WN1';
            
            insert branch; 
        //Ended by siddhesh
        
        Address_by_BP__c firstAddressByBp = new Address_by_BP__c(Account__c  = accountRecord.Id,Branch__c = branch.id, 
                                                                 Address_Code__c  = firstaddress.Id, isPrimary__c = TRUE, Ship_To__c = TRUE, Sold_To__c  = TRUE,Integration_Status__c ='Synced');
        insert firstAddressByBp;
        
        Opportunity oppRecord = new TestOpportunityBuilder()
            .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId())
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setAccountId(accountRecord.Id).getSavedTestRecord();
        
        OpportunityLineItem oppProduct1 = new OpportunityLineItem();
        oppProduct1.PricebookEntryId = pbe.Id;
        oppProduct1.Quantity = 1;
        oppProduct1.UnitPrice = pbe.UnitPrice;
        oppProduct1.Sequence_Number__c = 1;
        oppProduct1.OpportunityId = oppRecord.Id;
        oppProduct1.Product2Id = product.id;
        insert oppProduct1;
        
        
        Quote quoteRecord = new TestQuoteBuilder()
            .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId())
            .setOpportunityId(oppRecord.Id).getSavedTestRecord();
        
        QuoteLineItem qli =new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(pbe.Id).getSavedTestRecord();
        
    }
    
    
    @IsTest
    static void createOrderTest(){
        try{
            Test.startTest();
            User contextuser = [Select Id FROM User LIMIT 1];
            System.runAs(contextuser) {           
                List<QuoteLineItem> qlit;
                Quote quoteRecord = [Select Id, Name FROM Quote  LIMIT 1];
                List<QuoteLineItem> quoteLineItems = [Select Id, Quantity FROM QuoteLineItem WHERE QuoteId = :quoteRecord.Id];
                qlit = quoteLineItems;
                List<QuoteLineItemMapper> qliMapperList = new List<QuoteLineItemMapper>();
                for(QuoteLineItem qli : quoteLineItems) {
                    QuoteLineItemMapper qliMapper = new QuoteLineItemMapper();
                    qliMapper.id = qli.Id;
                    qliMapper.name = quoteRecord.Name;
                    qliMapper.available_quantity = Integer.valueOf(qli.Quantity);
                    qliMapper.order_quantity = Integer.valueOf(qli.Quantity);
                    qliMapperList.add(qliMapper);
                }    
                Opportunity oppRecord=QuoteManager.getOpportunityData(quoteRecord.Id);
                QuoteManager.createOrder(quoteRecord.Id, JSON.serialize(qliMapperList),oppRecord, Null);
                
                
            }
            Test.stopTest();
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
    @IsTest
    static void QLIRecordProcessorConstructionTest(){
        try{
            Test.startTest();
            User contextuser = [Select Id FROM User LIMIT 1];
            System.runAs(contextuser) {           
                
                Quote quoteRecord = [Select Id, Name FROM Quote  LIMIT 1];
                
                PricebookEntry pbe= [Select Id from PricebookEntry limit 1];
                Opportunity opportunity = [Select Id from Opportunity limit 1];
                QuoteLineItem qli =new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(pbe.Id)
                    .setOpportunityLineItemId(opportunity.Id)
                    .getSavedTestRecord();
                
            }
            Test.stopTest();
        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }   
    
}