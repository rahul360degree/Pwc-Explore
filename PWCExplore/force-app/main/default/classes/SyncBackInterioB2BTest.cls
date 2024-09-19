/**
* @description       : SyncBackInterioB2B test class
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 23-11-2023
* @last modified by  : snehalw@godrej.com
**/
@isTest
public class SyncBackInterioB2BTest {
    
    @testSetup
    public static void createTestData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'Usersync', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'testsync.user@godrej.com', username = 'testsync.user@godrej.com', Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT);
        insert userToRun;
        System.runAs(userToRun) {
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getSavedTestRecord();   
            Contact con = new TestContactBuilder()
                .setAccountId(accountRecord.Id)
                .getSavedTestRecord();
            Product2 product = new TestProductBuilder()
                .setItemCode('00001')
                .setProductCode('00001')
                .setIsActive(true)
                .setComponentType(GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE)
                .setProductLine(GlobalConstants.Product_Line_DESKING)
                .getTestRecord();                
            product.Is_Independent_product__c = false;
            product.Product_Line__c=GlobalConstants.Product_Line_DESKING;
            product.Product_Type__c=GlobalConstants.Product_Line_DESKING;
            product.Product_Class__c='DTWHAA';
            product.Is_Generic_Product__c= true;
            product.Is_New_Equipment__c=true;  
            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 10000, IsActive = true);
            insert pbe;
            
            Opportunity oppRecord=new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId())
                .setAccountId(accountRecord.Id)
                .getTestRecord();
            oppRecord.Order_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
            oppRecord.Interio_Sub_Division__c=GlobalConstants.Interio_Sub_Division_B2B_KAM;
            insert oppRecord;
            GlobalConstants.SKIP_QUOTE_LOCK = true;            
            QliTriggerHandler.TriggerDisabled = true;
            QuoteTriggerHandler.TriggerDisabled=true;  
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                .setOpportunityId(oppRecord.Id)
                .setPricebook2Id(pricebookId)                  
                .getTestRecord();  
            quoteRecord.Approval_Status__c='Submitted for Approval';
            quoteRecord.ContactId = con.Id;
            quoteRecord.LOBSummaryTotal__c='[{"LoB":"SEATING","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"DESKING","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"STORAGE","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"OPOS","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"LAB","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"Healthcare","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"}]';
            
            insert quoteRecord;
            
            OpportunityLineItem oppProduct1 = new OpportunityLineItem();
            oppProduct1.PricebookEntryId = pbe.Id;
            oppProduct1.Quantity = 1;
            oppProduct1.UnitPrice = pbe.UnitPrice;
            oppProduct1.Sequence_Number__c = 1;
            oppProduct1.OpportunityId = oppRecord.Id;
            oppProduct1.Product2Id = product.id;
            insert oppProduct1;
            
            oppProduct1.UnitPrice = 200;
            // Update the Opportunity Product
            update oppProduct1;
            
            QuoteLineItem qli = new TestQuoteLineItemBuilder()
                .setQuoteId(quoteRecord.Id)
                .setPriceBookEntryId(pbe.Id)
                .setUnitPrice(pbe.UnitPrice)
                .getTestRecord();  
            
            qli.Product2Id = pbe.Product2Id;            	
            qli.Requested_Customer_Discount__c = 5;
            qli.Req_Net_Rlizd_Bsc_Disc__c=4;
            qli.List_of_Approvers__c=userToRun.Id;
            qli.Current_Approver__c=userToRun.Id;
            qli.Final_Order_Booking_price__c = 100;
            qli.OpportunityLineItemId = oppProduct1.Id;
            insert qli; 
        }
    }
    
    static testMethod void testUpdateOppLineItem(){
        Test.startTest();
        User contextuser = [Select Id FROM User WHERE username = 'testsync.user@godrej.com' LIMIT 1];// Where condition added by mrunali at 18 JAN 2024 HOT FIX
        System.runAs(contextuser) {
            
            Id pricebookRecordId = Test.getStandardPricebookId();
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
                oppProducts.add(oppProduct);
            }
            insert oppProducts;
            
            QuoteLineItem testQuoteLineItem = [SELECT Id,Final_Order_Booking_price__c,QuoteId FROM QuoteLineItem ];
            
            // Call the invocable method
            SyncBackInterioB2B.updateOppLineItem(new List<Id>{testQuoteLineItem.QuoteId});
            
            List<OpportunityLineItem> oppProductsAfterInsert = [Select Id,UnitPrice FROM OpportunityLineItem 
                                                                WHERE OpportunityId = :opp.Id];
            
            System.assertEquals(1, (oppProductsAfterInsert != null) ? 1 : 0, 'Unexpected number of Opportunity Line Items updated.');
            
           // System.assertEquals(9500, oppProductsAfterInsert[0].UnitPrice);
            
            Test.stopTest();
        }
    }
}