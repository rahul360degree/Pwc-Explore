@isTest
public class OppProductRecordProcessorTest {
    @testSetup
    public static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userQPRPT@godrej.com', username = 'test.userQPRPT@godrej.com', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT);//UserName added by mrunali at 18 JAN 2024 HOT FIX
        insert userToRun; 
        System.runAs(userToRun) {
        Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .getSavedTestRecord();   
            
            Product2 product = new TestProductBuilder().setName(System.Label.Construction_SO_from_SF_to_LN ).setDescription('GX 300')
                .setItemCode(System.Label.Construction_SO_from_SF_to_LN ).setComponentType('Base Product')
                .setProductCode(System.Label.Construction_SO_from_SF_to_LN ).getTestRecord();
             
            insert product;
            
            product = [Select Id from Product2 limit 1];
            product.Type__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            product.Commodity_Set__c = 'R12V';
            product.Volume__c = 36.23; 
            update product;
            
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 10000, IsActive = true);
            insert pbe;
            
            

            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId())
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setAccountId(accountRecord.Id).getSavedTestRecord();
            
            
            Opportunity_Landed_rate__c landedRate = new Opportunity_Landed_rate__c();
            landedRate.Landed_rate__c = 100;
            landedRate.Related_Opportunity__c = oppRecord.Id;
            landedRate.Label__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            landedRate.Name = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            insert landedRate;
            
            OpportunityLineItem oppProduct1 = new OpportunityLineItem();
            oppProduct1.PricebookEntryId = pbe.Id;
            oppProduct1.Quantity = 1;
            oppProduct1.UnitPrice = pbe.UnitPrice;
            oppProduct1.Sequence_Number__c = 1;
            oppProduct1.OpportunityId = oppRecord.Id;
            oppProduct1.Product2Id = product.id;
            insert oppProduct1;
            
            
        }
    }


    static testMethod void addingOpporunityProductsWithAsset_shouldpopulateAssetSerialNumberInThem(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'test.userQPRPT@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Id pricebookRecordId = Test.getStandardPricebookId();
            //Asset assetRecord = [Select Id, SerialNumber FROM Asset LIMIT 1];
            Opportunity opp = [Select Id FROM Opportunity LIMIT 1];
            List<PricebookEntry> pricebookEntries = [Select Id, Product2Id, ProductCode, Pricebook2Id, UnitPrice FROM PricebookEntry 
                                                     WHERE IsActive = true AND Pricebook2Id = :pricebookRecordId];
            List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
            
            for(PricebookEntry pbe : pricebookEntries) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                oppProduct.PricebookEntryId = pbe.Id;
                oppProduct.Quantity = 1;
                oppProduct.UnitPrice = pbe.UnitPrice;
                oppProduct.Sequence_Number__c = 1;
                oppProduct.OpportunityId = opp.Id;
                //oppProduct.Asset__c = assetRecord.Id;
                oppProducts.add(oppProduct);
            }
            
            insert oppProducts;
            
            List<OpportunityLineItem> oppProductsAfterInsert = [Select Id, Asset_Serial_Number__c FROM OpportunityLineItem 
                                                                WHERE OpportunityId = :opp.Id];
            
            
            
        }
        Test.stopTest();
    }
}