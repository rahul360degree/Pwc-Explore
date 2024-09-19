/**
* @description       : Interio B2B Quotation controller test class
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 3-03-2023
* @last modified by  : snehalw@godrej.com
**/
@isTest
public class InterioB2BQuotationControllerTest {
    @testSetup
    public static void createData(){  
        
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        runningAdminUser.Persona__c ='Sales Person';
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        {             
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.INTERIO_BUSINESS_UNIT)
                .getSavedTestRecord();
            
            Contact con = new TestContactBuilder()
                .setAccountId(acc.Id)
                .getSavedTestRecord();
            
            Opportunity oppRecord=new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId())
                .setAccountId(acc.Id)
                .getTestRecord();
            oppRecord.Order_Type__c=GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
            oppRecord.Interio_Sub_Division__c=GlobalConstants.Interio_Sub_Division_B2B_KAM;
            insert oppRecord;
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
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
            insert pbe;            
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.Interio_B2B_Finished_Good_RT).getRecordTypeId())
                .setOpportunityId(oppRecord.Id)
                .setPricebook2Id(pricebookId)                  
                .getTestRecord();  
            quoteRecord.Approval_Status__c='Submitted for Approval';
            quoteRecord.ContactId = con.Id;
            quoteRecord.LOBSummaryTotal__c='[{"LoB":"SEATING","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"DESKING","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"STORAGE","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"OPOS","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"LAB","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"},{"LoB":"Healthcare","summation_listPrice":"1234","summation_unitPrice":"1234","summationApprovedCustomerDiscountedBasicPrice":"1234","summationReqWDRetSACOnReqDiscBasic":"1234","summationAppWDRetReqDiscbasic":"1234","summationReqWDCONT":"1234","summationApprovedWDCONT":"1234","summationReqNetRealizdBsicAmntRateUnit":"1234","summationApprovedNetRealizedBasicRateUnit":"1234","summationCOPperUnit":"1234","summationRequestedCOPFactor":"1234","summationApprovedCOPFactor":"1234"}]';
            
            insert quoteRecord;
            
            GlobalConstants.SKIP_QUOTE_LOCK = true;            
            QliTriggerHandler.TriggerDisabled = true;
            
            QuoteLineItem qli = new TestQuoteLineItemBuilder()
                .setQuoteId(quoteRecord.Id)
                .setPriceBookEntryId(pbe.Id)
                .setUnitPrice(pbe.UnitPrice)
                .getTestRecord();  
            
            qli.Product2Id = pbe.Product2Id;            	
            qli.Requested_Customer_Discount__c = 5;
            qli.Req_Net_Rlizd_Bsc_Disc__c=4;
            qli.List_of_Approvers__c=runningAdminUser.Id;
            qli.Current_Approver__c=runningAdminUser.Id;
            insert qli;
            
            Quote_Approval_History__c quoteApprovalHistory=new Quote_Approval_History__c();
            quoteApprovalHistory.Approval_Comments__c=GlobalConstants.Submitted_for_Approval;
            quoteApprovalHistory.Status__c=GlobalConstants.Submitted_for_Approval;
            quoteApprovalHistory.Quote__c=quoteRecord.Id;
            insert quoteApprovalHistory;
        }
    }
    
    static testMethod void test_submitForApproval(){
        Test.startTest();  
        String URL;
        Quote QuoteRec =[Select ID FROM Quote LIMIT 1];
        User adminUser = [Select Id,LastName From User where LastName='Admin User' Limit 1];  
        List<QuoteLineItem> qliList=new List<QuoteLineItem>();
        System.runAs(adminUser){
            ApexPages.StandardController sc = new ApexPages.StandardController(QuoteRec);
            InterioB2BQuotatationController cae=new InterioB2BQuotatationController(sc);
            cae.createPDF();
            Test.stopTest();
            InterioB2BQuotatationController.Summation obj = new InterioB2BQuotatationController.Summation();
            obj.Summation_ListPrice = '600';
            obj.Summation_unitPrice = '500';
            obj.summationApprovedCustomerDiscountedBasicPrice ='10';
            obj.summationReqWDRetSACOnReqDiscBasic ='7';
            obj.summationAppWDRetReqDiscbasic ='7';
            obj.summationReqWDCONT ='3';
            obj.summationApprovedWDCONT ='2';
            obj.summationReqNetRealizdBsicAmntRateUnit ='12';
            obj.summationApprovedNetRealizedBasicRateUnit = '11';
            obj.summationCOPperUnit = '1234';
            obj.summationRequestedCOPFactor = '2';
            obj.summationApprovedCOPFactor = '2';
            obj.summationReqWDRetSACOnReqDiscBasic_Percentage = '7.5';
            obj.summationReqWDRetSACOnConsumerBasic_Percentage = '7.5';
            obj.summationAppWDRetReqDiscBasic_Percentage = '7.5';
            obj.summationAppWDRetConsumerBasic_Percentage = '7.5';
            obj.summationReqWDCONTOnReqDiscBasic_Percentage = '7.5';
            obj.summationReqWDCONTOnConsumerBasic_Percentage = '7.5';
            obj.summationApprovedWDCONTOnReqDiscBasic_Percentage = '7.5';
            obj.summationApprovedWDCONTOnConsumerBasic_Percentage = '7.5';
            obj.summationUnitPrice_Percentage = '7.5';
                
           obj.summationApprovedCustomerDiscountedBasicPrice_Percentage  = '7.5';
         obj.summationReqNetRealizdBsicAmntRateUnit_Percentage  = '7.5';
          obj.summationApprovedNetRealizedBasicRateUnit_Percentage = '7.5';
               
        }
    }
}