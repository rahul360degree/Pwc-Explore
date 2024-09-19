/**
* @description       : Test class for SSDAutoSyncOrderBatch
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 17-08-2023
* @last modified by  : snehalw@godrej.com
**/
@isTest
private class TestSSDAutoSyncOrderBatchScheduler {
    @isTest
    public static void createData(){  
          
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        insert runningAdminUser;
        System.runAs(runningAdminUser)
        {             
            //Insert custom setting
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.FireQuoteValidationRules__c = false;
            setting.FireOpportunityValidationRules__c = false;
            setting.FireAccountValidationRules__c = false;
            setting.OrderTriggerDisabled__c = true;
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
            quoteRecord.SSD_Zonal_Manager__c = runningAdminUser.Id ;
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
            // Create test data - Failed Orders
            List<Order> failedOrders = new List<Order>();
            for (Integer i = 0; i < 5; i++) {
                failedOrders.add(new Order(
                    Logistics_Company_Branch__c = '5010', Area__c = 'WN1',
                    Planned_Delivery_Date__c = Datetime.now().addDays(10),
                    AccountId = acc.Id,OwnerId = runningAdminUser.Id,
                    Business_Unit__c = GlobalConstants.SSD_BUSINESS_UNIT,
                    Integration_Status__c = GlobalConstants.INTEGRATION_STATUS_SYNC_FAILED,
                    EffectiveDate = System.today(),
                    Status = 'Draft'
                ));
            }
            insert failedOrders;
            
            // Schedule the batch job
            Test.startTest();
            
            String jobId = System.schedule('Test SSDAutoSyncOrderBatch', '0 02 12 * * ?', new SSDAutoSyncOrderBatch()); // Schedule for a specific time
            
            Test.stopTest();
            
            
            // Verify the results
            List<Order> updatedOrders = [SELECT Id, Integration_Status__c FROM Order
                                         WHERE Business_Unit__c = :GlobalConstants.SSD_BUSINESS_UNIT
                                         AND Integration_Status__c = :GlobalConstants.INTEGRATION_STATUS_READY_TO_SYNC LIMIT 5];
            
           System.assertEquals(failedOrders.size(), updatedOrders.size(), 'Number of updated orders should match failed orders');
        }
    }
    }