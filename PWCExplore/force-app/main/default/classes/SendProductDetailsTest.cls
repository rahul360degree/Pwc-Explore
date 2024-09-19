@isTest
public class SendProductDetailsTest {
    @testSetup
    static void createData(){
        //create appliance user
         Profile appliancesProfile = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
         User appliancesUser = new TestUserBuilder().setProfileId(appliancesProfile.Id)
         .setBusinessUnit('H').setSalaryCode('25345').getSavedTestRecord();

        
         //create interio user
         Profile interioProfile = [SELECT Id FROM Profile WHERE Name = 'Interio B2C VFD Sales Marketing Logistic User'];
         User interioUser = new TestUserBuilder().setProfileId(interioProfile.Id)
         .setBusinessUnit('W').setSalaryCode('769198').getSavedTestRecord();
        
        //create account
        System.runAs(appliancesUser){
        Account partnerAccount = new TestAccountBuilder()
                    .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                    .setBusinessUnit('H').getSavedTestRecord();
        
        Account accountRecord2 = new Account(LastName='Test Account1', PersonMobilePhone='7902112112', Business_Unit__c = 'H',PersonEmail='invalid1@test.com' );
        accountRecord2.RecordTypeId =(RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
        insert accountRecord2; 
            
        // Create Pricebook.
        Pricebook2 pricebookRecord = createPricebookRecord();
        insert pricebookRecord;
        
        Product2 product = createProductRecords(true);
        product.Product_Storage_Clasification__c='Category A';
        insert product;
        
        PricebookEntry standardPricebookEntry = createStandardPricebookEntries(product);
        insert standardPricebookEntry;
        
        Order orderRecord= new TestOrderBuilder().setAccountId(partnerAccount.Id)
                    .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
                    .setBusinessUnit('H').getSavedTestRecord();  
        
        Opportunity appOppRecord = new TestOpportunityBuilder()
                    .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                    .setBusinessUnit('H').setAccountId(accountRecord2.Id).getTestRecord();
                    appOppRecord.Sub_Division__c = GlobalConstants.B2C_SUBDIVISION;
                    appOppRecord.Interio_Sub_Division__c = GlobalConstants.INTERIO_KITCHEN;
                    appOppRecord.Pricebook2Id = pricebookRecord.id;
                    appOppRecord.AccountId = accountRecord2.Id;
                    appOppRecord.Business_Unit__c = accountRecord2.Business_Unit__c;
                    appOppRecord.Name = 'APPLIANCE Opp record';
        insert appOppRecord;
            
        OpportunityLineItem oppProduct1 = new OpportunityLineItem();
                oppProduct1.PricebookEntryId = standardPricebookEntry.Id;
                oppProduct1.Quantity = 1;
                oppProduct1.UnitPrice = standardPricebookEntry.UnitPrice;
                oppProduct1.Sequence_Number__c = 1;
                oppProduct1.OpportunityId = appOppRecord.Id;
                oppProduct1.Product2Id = product.id;
            insert oppProduct1;
   
        OpportunityLineItem oppProduct = createOpportunityLineItem(standardPricebookEntry,appOppRecord,product);
        }
    }
    private static Pricebook2 createPricebookRecord() {
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'test price book 1', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true
                                    );
        return pricebookRecord;
    }
    private static Product2 createProductRecords(Boolean isGeneric) {
        Product2 baseproduct1 = new Product2(Name = 'Test Base Product 1', Item__c = '00001', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='DTWHAA';
        baseproduct1.Product_Class__c='DTWHAA';
        baseproduct1.Is_Generic_Product__c= isGeneric;
        baseproduct1.Is_New_Equipment__c=true;
        return baseproduct1;
    }
    private static PricebookEntry createStandardPricebookEntries(Product2 product) {
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = product.Id,
            UnitPrice = 10000, IsActive = true);

        return standardPriceEntry;
    }
    
    //create Opportunity Product
        private static OpportunityLineItem createOpportunityLineItem(PricebookEntry pbe,Opportunity opp,product2 product) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
               // oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = opp.Id;
                oppProduct.Product2Id = product.id;
            return oppProduct;
    }
    
     static testmethod void getOpportunityRelatedData(){
        test.startTest();
        Opportunity oppRecord = [select id from Opportunity where Name='APPLIANCE Opp record' Limit 1];
        //System.debug('oppRecord---->'+oppRecord);
        //
        OpportunityLineItem oppLineRecord = [select id,product2id from OpportunityLineItem where opportunityId =:oppRecord.id limit 1];
              
        String trackIdValue = System.Label.ContentDocumentIdLabel;
         
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = oppLineRecord.product2id;
        contentlink.contentdocumentid =  trackIdValue; 
        contentlink.ShareType = 'V';        
        insert contentlink;
        
        ContentDocumentLink contentVersionVar = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:contentlink.LinkedEntityId]; 
         
        ContentVersion contVersion = [SELECT Id,Title FROM ContentVersion WHERE ContentDocumentiD =:contentVersionVar.ContentDocumentId];
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];       
         
        List<contentDistribution> ContentDistributionList = new List<contentDistribution>();
        contentDistributionList = [SELECT PdfDownloadUrl 
                                   FROM ContentDistribution 
                                   ];  
        
        SendProductDetails.SendProductDetailsMethod(oppRecord.id);
         
        Test.setMock(HttpCalloutMock.class, new mockTinyUrlService());
        Test.setMock(HttpCalloutMock.class, new mockPaymentReceiptResponseClass());
         
        test.stopTest();
      }

}