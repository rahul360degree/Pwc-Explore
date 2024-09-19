@isTest
public class QuoteApprovalHandler_Helper_Test {
    
    @IsTest
    private static void Regular_salesEng(){
        User user = testCreateData('SSG- Sales Engineer','Regular',10);
        System.runAs(user){
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.QuoteTriggerDisabled__c = True;
            insert setting;
        Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(true, isAutoApproved);//gcp22
      }
    }
    @IsTest
    private static void Regular_TSM(){
        User user = testCreateData('SSG- Territory Sales Manager','Regular',18);
        System.runAs(user){
           Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(true, isAutoApproved);//gcp22
        }
    }
    @IsTest
    private static void Regular_RSM(){
        User user = testCreateData('SSG- Regional sales manager (Domestic )','Regular',18);
        System.runAs(user){
         Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(true, isAutoApproved);//gcp22
        }
    }
    @IsTest
    private static void Regular_NSM(){
        User user = testCreateData('SSG- National sales manager (Regular)','Regular',35);
        System.runAs(user){            
           Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(true, isAutoApproved);//gcp22
        }
    }
    @IsTest
    private static void Regular_BU_Head(){
        User user = testCreateData('SSG- Sales & Marketing Head','Regular',18);
        System.runAs(user){
           Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(true, isAutoApproved);//gcp22
        }
    }
    @IsTest
    private static void Regular_ApprovalRequired(){
        User user = testCreateData('SSG- Sales Engineer','Regular',18);
        System.runAs(user){
          Pricing_approval_request__c request = [SELECT Id, Requested_Customer_discount_max__c FROM Pricing_approval_request__c
                                               LIMIT 1];
        Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular(request);
        System.assertEquals(false, isAutoApproved);//gcp22
        }
    }
    
    
    @IsTest
    private static void Key_BU_Head(){
        User user = testCreateData('SSG- Sales & Marketing Head','Key',18);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Key([SELECT Id,Requested_Customer_discount_max__c,Dealer_Margin_Dealer_order__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void Key_TSM(){
        User user = testCreateData('SSG- Territory Sales Manager','Key',18);
        System.runAs(user){
             Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Key([SELECT Id,Requested_Customer_discount_max__c,Dealer_Margin_Dealer_order__c FROM Pricing_approval_request__c][0]);
             System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void Key_RSM(){
        User user = testCreateData('SSG- Regional sales manager (Domestic )','Key',18);
        System.runAs(user){
             Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Key([SELECT Id,Requested_Customer_discount_max__c,Dealer_Margin_Dealer_order__c FROM Pricing_approval_request__c][0]);
             System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void Key_ApprovalRequired(){
        User user = testCreateData('SSG- Territory Sales Manager','Regular',40);
        System.runAs(user){
             Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_Regular([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
             System.assertEquals(false, isAutoApproved, 'Expected result: falses');//gcp22
        }
    }
    
    
      
    @IsTest
    private static void LCS_salesEng(){
        User user = testCreateData('SSG- Sales Engineer','Life Cycle Services',10);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void LCS_TSM(){
        User user = testCreateData('SSG- Territory Sales Manager','Life Cycle Services',18);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void LCS_RSM(){
        User user = testCreateData('SSG- Regional sales manager (Domestic )','Life Cycle Services',18);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void LCS_NSM(){
        User user = testCreateData('SSG- National sales manager (Regular)','Life Cycle Services',18);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void LCS_BU_Head(){
        User user = testCreateData('SSG- Sales & Marketing Head','Life Cycle Services',18);
        System.runAs(user){
            Boolean isAutoApproved =QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(true, isAutoApproved, 'Expected result: true');//gcp22
        }
    }
    @IsTest
    private static void LCS_ApprovalRequired(){
        User user = testCreateData('SSG- Sales Engineer','Life Cycle Services',18);
        System.runAs(user){
            Boolean isAutoApproved = QuoteApprovalHandler_Helper.isAutoApproved_SSG_LCS([SELECT Id,Requested_Customer_discount_max__c FROM Pricing_approval_request__c][0]);
            System.assertEquals(false, isAutoApproved, 'Expected result: false');//gcp22
        }
    }
    
    
    private static User testCreateData(String persona, String category, integer discount){
        // Added Runtime Execution by Namrata on 30/03/2023
 		Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.AccountTriggerDisabled__c = true;
        insert setting; 
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User user = new TestUserBuilder().setProfileId(profile.Id).setBusinessUnit(GlobalConstants.SSG_BUSINESS_UNIT).setSalaryCode('12346').setPersona(persona).getTestRecord();    
        Account accountRecord = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            .getTestRecord();
        accountRecord.Business_Unit__c = GlobalConstants.SSG_BUSINESS_UNIT;
        accountRecord.Sub_industry_Segment__c = 'Government';
        accountRecord.Sectors__c = 'Railways';
        insert accountRecord;
        System.runAs(user){ 
            Opportunity oppRecord = new TestOpportunityBuilder().getSavedTestRecord();            
            Product2 product = new TestProductBuilder().setName('ELB ITPrk C AC Chrgs Main')
                .setItemCode('80131801SD00048').setDescription('ELB ITPrk C AC Chrgs Main').getTestRecord();

            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
            insert pbe;
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId())
                .setOpportunityId(oppRecord.Id).getTestRecord();
            QuoteRecord.Pricebook2Id =pricebookId;
            QuoteRecord.Dealer_SAC_Applicable__c = 'No';
            quoteRecord.Disable_PC_Sync__c=false;
            quoteRecord.Category__c = category;
            insert QuoteRecord;
            
            QuoteLineItem qli = new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(pbe.UnitPrice).setSequenceNumber(1).setPriceBookEntryId(pbe.Id).getTestRecord();
            qli.Product2Id = product.Id;
            qli.Requested_Customer_Discount__c = discount;
            qli.Quantity  = 1;
         	insert qli;
            System.debug([SELECT Id FROM Pricing_approval_request__c WHERE Quote__c=:quoteRecord.id]);
            
            
            
        }
        return user;
    }
       
}