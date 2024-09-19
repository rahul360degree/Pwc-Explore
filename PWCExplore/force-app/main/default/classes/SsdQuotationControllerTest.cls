/*-----------------------------------------------------------------------
Author    : Sreekanth Jujare
Test Class: Written for SsdQuotationController.apxc
Company   : GITL
-------------------------------------------------------------------------*/
@isTest
public class SsdQuotationControllerTest {
    @testSetup
    public static void createData(){  
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser1 =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User 1')
            .getTestRecord();        
        runningAdminUser1.IsActive = true;
        insert runningAdminUser1;
        
        User runningAdminUser2 =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User 2')
            .getTestRecord();        
        runningAdminUser2.IsActive = true;
        runningAdminUser2.ManagerId = runningAdminUser1.Id;
        insert runningAdminUser2;
        
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        runningAdminUser.ManagerId = runningAdminUser2.Id;
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        {             
            //Insert custom setting
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FireQuoteValidationRules__c = false;
            setting.FireOpportunityValidationRules__c = false;
            setting.FireAccountValidationRules__c = false;
            insert setting;
            
            Account acc = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .setBusinessUnit(GlobalConstants.SSD_BUSINESS_UNIT)
                .getSavedTestRecord();
            
            Contact con = new TestContactBuilder()
                .setAccountId(acc.Id)
                .getSavedTestRecord();
            
            Opportunity oppRecord=new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Security_Solutions_B2B').getRecordTypeId())
                .setAccountId(acc.Id)
                .setBusinessUnit('U')
                .getTestRecord();
            oppRecord.Order_Type__c = GlobalConstants.DIRECT_BILLING_TO_CUSTOMER;
            oppRecord.Booking_Option__c = 'Special Price';
            oppRecord.Customer_Type_SSD__c = 'BFSI';
            oppRecord.End_Customer_Segment_SSD__c = 'BNKPSU';
            oppRecord.Area_Code__c = 'WN1';
            oppRecord.Sales_Zone__c = 'EST';
            oppRecord.Region__c = 'WB_NE';
            oppRecord.Opportunity_Type__c = 'Std';
            insert oppRecord;
            Product2 product = new TestProductBuilder()
                .setItemCode('00001')
                .setProductCode('00001')
                .setIsActive(true)
                .getTestRecord();                
            product.Is_Generic_Product__c= true;
            product.Is_New_Equipment__c=true;  
            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
            insert pbe;  
            
            //Create a new OpportunityLineItem record
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppRecord.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = pbe.UnitPrice
            );
            
            insert oli;
            
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSD).getRecordTypeId())
                .setOpportunityId(oppRecord.Id)
                .setPricebook2Id(pricebookId)                  
                .getTestRecord();  
            quoteRecord.ContactId = con.Id;
            quoteRecord.SSD_Zonal_Manager__c = runningAdminUser2.Id ;
            insert quoteRecord;
            
            //     GlobalConstants.SKIP_QUOTE_LOCK = true;            
            QliTriggerHandler.TriggerDisabled = true;
            QuoteLineItem qli = new TestQuoteLineItemBuilder()
                .setQuoteId(quoteRecord.Id)
                .setPriceBookEntryId(pbe.Id)
                .setUnitPrice(pbe.UnitPrice)
                .getTestRecord();  
            qli.Product2Id = pbe.Product2Id;            	
            qli.Requested_Customer_Discount__c = 5;
            qli.Approved_Max_Outflow_SSD__c = 5;
            insert qli;
            
        }
    }
    static testMethod void testQuotationController(){
        Test.startTest();  
        String URL;
        Quote QuoteRec =[Select ID FROM Quote LIMIT 1];
        User adminUser = [Select Id,LastName From User where LastName='Admin User' Limit 1];  
        List<QuoteLineItem> qliList=new List<QuoteLineItem>();
        System.runAs(adminUser){
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Test Submit For Approval');
            req.setObjectId(QuoteRec.Id);
            Approval.ProcessResult result = Approval.process(req);
            
            System.assert(result.isSuccess());
            
            ApexPages.StandardController sc = new ApexPages.StandardController(QuoteRec);
            SsdQuotationController cae=new SsdQuotationController(sc);
            cae.getUser(QuoteRec.Id);
            cae.createPDF();
            Test.stopTest();
        }
    }
}