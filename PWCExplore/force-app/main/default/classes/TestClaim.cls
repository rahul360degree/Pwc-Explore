@isTest 
private class TestClaim {
    
    
    @isTest static void invoiceSubmissionSample(){
        User mheUser = TestDataFactory.createUser();
        System.runAs(mheUser){
            
            Discount_Matrix__c dm = TestDataFactory.createDiscountMatric();            
            Product2 prod = TestDataFactory.createProduct();
            PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
            
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').getSavedTestRecord();
            
            //create Order
            Order orderRecord= TestDataFactory.createOrder(partnerAccount.Id,'MHE_Order_Primary');
            OrderItem oitem = new OrderItem(Orderid = orderRecord.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
            Warehouse__c warehouseRecord1 = TestDataFactory.createWarehouse();
            
            //TestDataFactory.createSampleData();
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Invoice_Submission_Request');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Rental');
            claimRequest.RecordTypeId=Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST).getRecordTypeId();
            claimRequest.Approval_Status__c = 'Draft';
            //claimRequest.Order__c = orderRecord.Id;
            //claimRequest.Godrej_Sales_Order__c = orderRecord.Id;
            //claimRequest.Godrej_Order_Product__c = oitem.Id;
            //claimRequest.Order_Product__c = [Select Id from OrderItem].Id;   
            claimRequest.Unique_Key__c='';  
            //claimRequest.Level_1__c = mheUser.Id;
            claimRequest.Dealer_Invoice_Basic_amount__c = 1000;            
            insert claimRequest;    
        }
        
        
        
        
    }  
    
    
    @isTest 
    static void testContractsClaim(){
        User mheUser = TestDataFactory.createUser();
        System.runAs(mheUser){
            Discount_Matrix__c dm = TestDataFactory.createDiscountMatric();            
            Product2 prod = TestDataFactory.createProduct();
            PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
            
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').getSavedTestRecord();
            
            //create Order
            Order orderRecord= TestDataFactory.createOrder(partnerAccount.Id,'MHE_Order_Primary');
            OrderItem oitem = new OrderItem(Orderid = orderRecord.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
            
            Warehouse__c warehouseRecord1 = TestDataFactory.createWarehouse();
            
            
            
            
            Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                                        IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                                        Market_Pricelist__c = true);
            insert pricebookRecord;
            
            ServiceContract sc = new ServiceContract();
            sc.Name = 'Test Service Contract';
            sc.Status__c = 'Open';
            sc.AccountId = partnerAccount.id;
            sc.Pricebook2Id = pricebookRecord.Id;
            sc.MHE_Division__c = 'Contracts';
            sc.Contract_Type__c = GlobalConstants.CMT_CONTRACT_TYPE;
            sc.Billing_Frequency__c='Yearly: Y20';
            insert sc;
            
            
            
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Contracts');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Rental');
            claimRequest.Approval_Status__c = 'Draft';
            claimRequest.Order__c = orderRecord.Id;
            //claimRequest.Godrej_Sales_Order__c = orderRecord.Id;
            //claimRequest.Godrej_Order_Product__c = oitem.Id;
            claimRequest.Order_Product__c = oitem.Id;   
            claimRequest.Unique_Key__c='';  
            claimRequest.Dealer_Invoice_Basic_amount__c = 1000;
            claimRequest.Service_Contract__c = sc.Id;
            insert claimRequest;
            claimRequest.RecordTypeId=Schema.SObjectType.Claim_Requests__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CLAIM_REQUEST_Contracts).getRecordTypeId();//'0122h000000CzG9';
            claimRequest.Company__c ='2010';
            update claimRequest;
        }
        
        
    }    
    
    
    
    
    
    @isTest 
    static void testAdhoc(){
        User mheUser = TestDataFactory.createUser();
        System.runAs(mheUser){
            Discount_Matrix__c dm = TestDataFactory.createDiscountMatric();            
            Product2 prod = TestDataFactory.createProduct();
            PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
            
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').setIntegrationStatus('Synced').getSavedTestRecord();
            
            
            //create Order
            Order orderRecord= TestDataFactory.createOrder(partnerAccount.Id,'MHE_Order_Primary');
            System.debug(orderRecord);
            OrderItem oitem = new OrderItem(Orderid = orderRecord.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
            
            Warehouse__c warehouseRecord1 = TestDataFactory.createWarehouse();
            
            
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Ad_hoc');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Warranty');
            claimRequest.Approval_Status__c = 'Draft';
            claimRequest.Order__c = orderRecord.Id;
            //claimRequest.Godrej_Sales_Order__c = orderRecord.Id;
            //claimRequest.Godrej_Order_Product__c = oitem.Id;
            claimRequest.Order_Product__c = oitem.Id;   
            claimRequest.Unique_Key__c='';  
            claimRequest.Dealer_Invoice_Basic_amount__c = 1000;
            insert claimRequest;
            
            claimRequest.RecordTypeId=  (RecordTypeUtils.getInstance()).getRecordTypeId('Claim_Requests__c', 'Contracts');
            claimRequest.Company__c ='2010';            
            update claimRequest;
        }
        
        
    }
   
        @isTest 
    static void testWarrantyClaim(){
        User mheUser = TestDataFactory.createUser();
        System.runAs(mheUser){
            Discount_Matrix__c dm = TestDataFactory.createDiscountMatric();            
            Product2 prod = TestDataFactory.createProduct();
            prod.Claim_Type__c = 'Warranty';
            update prod;
            
            PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
            
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').setIntegrationStatus('Synced').getSavedTestRecord();
            
            
            //create Order
            Order orderRecord= TestDataFactory.createOrder(partnerAccount.Id,'MHE_Order_Primary');
            System.debug(orderRecord);
            OrderItem oitem = new OrderItem(Orderid = orderRecord.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
            
            Warehouse__c warehouseRecord1 = TestDataFactory.createWarehouse();

			//Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
            
            Asset newAsset = new Asset();
            newAsset.Name= 'test Asset';
            newAsset.AccountId = partnerAccount.id;
            newAsset.Address_Code__c = address.id;		//Added by pc
            newAsset.Status = 'Active';
            newAsset.Coverage__c = 'KFTWC01200001';
            newAsset.Type_of_Warranty__c = 'Special Warranty';
            insert newAsset;
            
            
            TestClaimRequestBuidler tcrb_warranty =  new TestClaimRequestBuidler('Warranty');
            Claim_Requests__c warrantyClaimRequest = tcrb_warranty.setRecordType('Warranty');
            warrantyClaimRequest.Approval_Status__c = 'Draft';
            warrantyClaimRequest.Order__c = orderRecord.Id;
            //claimRequest.Godrej_Sales_Order__c = orderRecord.Id;
            //claimRequest.Godrej_Order_Product__c = oitem.Id;
            warrantyClaimRequest.Order_Product__c = oitem.Id;   
            warrantyClaimRequest.Unique_Key__c='';  
            warrantyClaimRequest.Dealer_Invoice_Basic_amount__c = 1000;
            warrantyClaimRequest.Approval_Status__c = 'Draft';
            warrantyClaimRequest.Asset__c = newAsset.Id;
            insert warrantyClaimRequest;
            
            warrantyClaimRequest.Approval_Status__c = 'Approved';
            warrantyClaimRequest.Company__c = '2010';
            warrantyClaimRequest.Effective_Date_Time__c = System.now();
            warrantyClaimRequest.Quantity__c=1;
            warrantyClaimRequest.Product_Item_Code__c = prod.Id;
            warrantyClaimRequest.Requisition_Series__c = 'KS1';
            warrantyClaimRequest.Location__c = warehouseRecord1.Id;     
        }       
    }    
}