/**
* @description       : It is covering AddOpportunityProductHelper
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 05-03-2022
* @last modified by  : vrajpoot@godrej.com
**/
@isTest
public class AddOpportunityProductHelperTest {
    @testSetup
    private static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT);
        insert userToRun;
        
        System.runAs(userToRun) {
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT)
                .getSavedTestRecord();   
            
            Product2 product = new TestProductBuilder().setName(System.Label.Construction_SO_from_SF_to_LN ).setDescription('GX 300 Forklift')
                .setItemCode(System.Label.Construction_SO_from_SF_to_LN ).setComponentType('Base Product')
                .setProductCode(System.Label.Construction_SO_from_SF_to_LN ).getTestRecord();
            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 10000, IsActive = true);
            insert pbe;
            
            
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
        }
    }
    
    
    static testmethod void upsertReecordCoverage_TUFFACCBlock(){
        Test.startTest();
        user userToRun = [Select Id from User where username='test.user@godrej.com'];
        System.runAs(userToRun) {
            Product2 product = [Select Id from Product2 limit 1];
            product.Type__c = GlobalConstants.TUFF_ACC_Block_Landed_Rate;
            product.Commodity_Set__c = 'R12V';
            product.Volume__c = 36.23;
            update product;
            
            Opportunity_Landed_rate__c landedRate = new Opportunity_Landed_rate__c();
            landedRate.Landed_rate__c = 100;
            landedRate.Related_Opportunity__c = [Select Id from Opportunity limit 1].Id;
            landedRate.Label__c = GlobalConstants.TUFF_ACC_Block_Landed_Rate;
            landedRate.Name = GlobalConstants.TUFF_ACC_Block_Landed_Rate;
            insert landedRate;
            
            
            List<Opportunity_Landed_rate__c> landedRateList = [Select Id, Name, Label__c,Landed_Rate__c,Related_Opportunity__c from Opportunity_Landed_rate__c] ;
            AddOpportunityProductHelper.fetchLandedRate(landedRate.Id, 'Select Id, Name, Label__c,Landed_Rate__c');
            
            AddOpportunityProductHelper.getProdList();
            AddOpportunityProductHelper.upsertReecord(landedRateList, landedRateList[0].Related_Opportunity__c);
        }
        Test.stopTest();
    }
    
    
    
    static testmethod void upsertReecordCoverage_ExceptionHandling(){
        Test.startTest();
        user userToRun = [Select Id from User where username='test.user@godrej.com'];
        System.runAs(userToRun) {
            try{
                Opportunity_Landed_rate__c landedRate = new Opportunity_Landed_rate__c();
                landedRate.Landed_rate__c = 100;
                landedRate.Related_Opportunity__c = [Select Id from Opportunity limit 1].Id;
                landedRate.Label__c = GlobalConstants.TUFF_ACC_Block_Landed_Rate;
                landedRate.Name = GlobalConstants.TUFF_ACC_Block_Landed_Rate;
                insert landedRate;
                
                List<Opportunity_Landed_rate__c> landedRateList = [Select Id, Name, Label__c,Landed_Rate__c,Related_Opportunity__c from Opportunity_Landed_rate__c] ;
                AddOpportunityProductHelper.fetchLandedRate(landedRate.Id, 'Select Id, Name, Label__c,Landed_Rate__c');
                
                AddOpportunityProductHelper.getProdList();
                AddOpportunityProductHelper.upsertReecord(landedRateList, landedRateList[0].Related_Opportunity__c);
            }catch(Exception ex){
            }
        }
        Test.stopTest();
    }
    
    static testmethod void upsertRecordCoverage_TUFFDuroplast(){
        Test.startTest();
        user userToRun = [Select Id from User where username='test.user@godrej.com'];
        System.runAs(userToRun) {
            Product2 product = [Select Id from Product2 limit 1];
            product.Type__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            product.Commodity_Set__c = 'R12V';
            product.Volume__c = 36.23;
            update product;
            
            Opportunity_Landed_rate__c landedRate = new Opportunity_Landed_rate__c();
            landedRate.Landed_rate__c = 100;
            landedRate.Related_Opportunity__c = [Select Id from Opportunity limit 1].Id;
            landedRate.Label__c = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            landedRate.Name = GlobalConstants.TUFF_Duroplast_Landed_Rate;
            insert landedRate;
            
            
            List<Opportunity_Landed_rate__c> landedRateList = [Select Id, Name, Label__c,Landed_Rate__c,Related_Opportunity__c from Opportunity_Landed_rate__c] ;
            AddOpportunityProductHelper.fetchLandedRate(landedRate.Id, 'Select Id, Name, Label__c,Landed_Rate__c');
            
            AddOpportunityProductHelper.getProdList();
            AddOpportunityProductHelper.upsertReecord(landedRateList, landedRateList[0].Related_Opportunity__c);
        }
        Test.stopTest();
    }
    
}