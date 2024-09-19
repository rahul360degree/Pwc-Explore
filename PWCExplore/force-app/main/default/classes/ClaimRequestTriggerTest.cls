/*------------------------------------------------------------------------
Author:        Kshipra 
Company:       Salesforce
Description:   Test class for Claim Request Trigger
Inputs:        NA
Test Class:    
History
15-12-2020      Kshipra      Initial Release
----------------------------------------------------------------------------*/
@isTest
public class ClaimRequestTriggerTest {
   @testSetup
    static void setupData() {
        Test.startTest();
        //List<Area_Code_Branch_Champion__mdt> areaMappings = [Select Area_Code__c,Branch_head_Salary_code__c,Regional_Manager_Salary_Code__c,Branch_Champion_salary_code__c From Area_Code_Branch_Champion__mdt Where Area_Code__c != NULL AND Branch_head_Salary_code__c != NULL AND Regional_Manager_Salary_Code__c != NULL AND Branch_Champion_salary_code__c != NULL]; //Commented by Shreela on 11th october 2022 for resolving test class error
        TestUserBuilder tub = new TestUserBuilder();
        Id profileId = [select id from profile where name = 'MHE Sales User'].Id;
        tub.setProfileId(profileId);
        User internalUser = tub.getTestRecord();
        internalUser.persona__c = 'MHE Sales-Sales Manager';
        Id roleId = [select id from userRole where name = 'MHE'].id;
        internalUser.userRoleId = roleId;
        internalUser.Business_unit__c = 'K';
        internalUser.Salary_Code__c = '1324';
        User partnerUser = tub.getPartnerUser();
        partnerUser.persona__c = 'MHE Sales-Dealer Sales Manager';    
        partnerUser.Salary_Code__c = '13245';
        partnerUser.profileId = [select id from profile where name = 'MHE Dealer Sales Manager Partner User' limit 1].Id;
        update partnerUser;
        insert internalUser;
        
        
        User u = [SELECT Id FROM User WHERE user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        System.runAs(u) {

            Discount_Matrix__c dm = new Discount_Matrix__c( 
                                       Name='No Discount', 
                                       Discount_Percent__c=0, 
                                       Discount_Amount__c=1,
                                       Gross_Net__c='1', 
                                       Level__c='3', 
                                       Stage__c='Active', 
                                       Start_Date__c=system.today(),
                                       Discount_Code__c='HDH'
                              );
       insert dm;
            Product2 prod = new TestProductBuilder().setItemCode('H').getSavedTestRecord();
            prod.Product_Storage_Clasification__c = 'Category A';
            prod.Is_generic_Product__c = true;
            update prod;
            
            PriceBookEntry entry = new TestPriceBookEntryBuilder().setPricebook2Id(Test.getStandardPricebookId()).setProduct2Id(prod.Id).getSavedTestRecord();
            
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').getSavedTestRecord();
            List<Order> orders = new List<Order>();
            Order so = new TestOrderBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Secondary').getRecordTypeId())
                .setBusinessUnit('K').setPriceBook2Id(Test.getStandardPricebookId()).getTestRecord(); //Changed Business unit from H to K by Shreela on 11th October 2022 fro resolving test class error
            so.intent__c = 'true';
            so.Sales_Type__c = 'Secondary';
            /*if(areaMappings.size() > 1) {
                so.Area__c = areaMappings[0].Area_Code__c;
            } else {
                so.Area__c = 'NG3';
            } */ //Commented by Shreela on 11th october 2022 for resolving test class error
            so.Area__c = 'SV1';
            so.sub_division__c = 'B2B';
            so.MHE_Division__c = 'Spare Parts';
            orders.add(so);
            Order po = new TestOrderBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('MHE_Order_Primary').getRecordTypeId())
                .setBusinessUnit('K').setPriceBook2Id(Test.getStandardPricebookId()).getTestRecord();   //Changed Business unit from H to K by Shreela on 11th October 2022 fro resolving test class error
            po.intent__c = 'true';
            po.Sales_Type__c = 'Primary';
            /*if(areaMappings.size() > 1) {
                po.Area__c = areaMappings[0].Area_Code__c;
            } else {
                po.Area__c = 'NG3';
            } */ //Commented by Shreela on 11th october 2022 for resolving test class error
            po.Area__c = 'SV1';
            po.MHE_Division__c = 'Spare Parts';
            po.sub_division__c = 'B2B';
            orders.add(po);
            insert orders;
            
            /*Payment_Term__c paymentTerm=new Payment_Term__c(Business_Unit__c='H',Area_Code__c='NG3');
            insert paymentTerm;*/
            
            List<OrderItem> ois = new List<OrderItem>();
            OrderItem oitem = new OrderItem(Orderid = so.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 1000);
            ois.add(oitem);
            
            OrderItem oitem2 = new OrderItem(Orderid = po.Id, PricebookEntryId = entry.id, Quantity = 1,UnitPrice = 5000,Discount_Amount__c = 10);
            ois.add(oitem2);
            insert ois;
            
            //Create Address Record							//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
            insert address;
        }
        Test.stopTest();
    }
    
    public static void createServiceContract(){
        User u=[Select Id,IsActive from User Where Profile.Name='MHE Sales User' And IsActive=true Limit 1];
        Opportunity oppRecord;
        Quote quoteRecord;
        System.runAs(u){
           oppRecord = new TestOpportunityBuilder()
                    .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                    .setMHEDivision('Contracts').getSavedTestRecord();
            //oppRecord.Duration_In_Days__c=2;
            oppRecord.Contract_Start_Date__c=system.today();
            oppRecord.StageName = 'closed won';
            Update oppRecord;
                
           quoteRecord = new TestQuoteBuilder()
                    .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId())
                    .setOpportunityId(oppRecord.Id).getSavedTestRecord();
    
        }
        
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
        update standardPriceBook;
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert accountRecord;
        Pricebook2 contractPriceBook = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                    Market_Pricelist__c = true);
        insert contractPriceBook;
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        sc.Status__c = 'Open';
        sc.AccountId = accountRecord.id;
        sc.Pricebook2Id = contractPriceBook.Id;
        sc.MHE_Division__c = 'Contracts';
        sc.Contract_Type__c = 'EWP';
        sc.Offloaded_to_Contractor__c = 2;
        sc.Associated_Opportunity__c=oppRecord.Id;
        sc.Associated_Quote__c=quoteRecord.Id;
        sc.StartDate=System.today();
        sc.EndDate=System.today().addDays(2);
        insert sc;
        List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord(),
                new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').getTestRecord(),
                new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').getTestRecord(),
                new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').getTestRecord()
        };
        insert allProducts;
    
        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(contractPriceBook.Id).setUnitPrice(32000).getTestRecord()
        };
        insert allPBEs;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = sc.id; 
        cli.PricebookEntryId = allPBEs[0].Id;
        cli.UnitPrice = 1011;
        cli.Quantity = 1;
        cli.Serial_Number__c='001Test';
        insert cli; 
    }

    @isTest
    public static void createAnnexureAClaimRequestForCategoryAStockAndSellShouldPass() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
            Order so = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Secondary']; 
            Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
            OrderItem poi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1];
            OrderItem soi = [SELECT Id FROM OrderItem WHERE OrderId =: so.Id LIMIT 1]; 
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
            claimRequest.Approval_Status__c = 'Draft';
            claimRequest.Order__c = so.Id;
            claimRequest.Godrej_Sales_Order__c = po.Id;
            claimRequest.Godrej_Order_Product__c = poi.Id;
            claimRequest.Order_Product__c = soi.Id;            
            insert claimRequest;
            Claim_Requests__c claim = [Select Request_Type__c FROM Claim_Requests__c WHERE Id =:claimRequest.Id LIMIT 1];
            System.assertEquals('Stock & Sell - Category A', claim.Request_Type__c); 
        }
        Test.stopTest();
    }

    @isTest
    public static void createAnnexureAClaimRequestForCategoryANonStockAndSellShouldFail() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
            Order so = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Secondary']; 
            Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
            OrderItem poi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1];
            OrderItem soi = [SELECT Id FROM OrderItem WHERE OrderId =: so.Id LIMIT 1]; 
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
            claimRequest.Approval_Status__c = 'Draft';
            claimRequest.Order__c = so.Id;
            claimRequest.Godrej_Sales_Order__c = po.Id;
            claimRequest.Godrej_Order_Product__c = poi.Id;
            claimRequest.Order_Product__c = soi.Id;
            try {
                insert claimRequest;
                System.assert(false); 
            } catch(Exception ex) {
                System.assert(true);
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void createAnnexureAClaimRequestForCategoryBShouldFail() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        Product2 p = [Select Id FROM Product2 WHERE Product_Storage_Clasification__c = 'Category A'];
        p.Product_Storage_Clasification__c = 'Category B';
        update p;

        System.runAs(userRec) {
            Order so = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Secondary']; 
            Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
            OrderItem poi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1];
            OrderItem soi = [SELECT Id FROM OrderItem WHERE OrderId =: so.Id LIMIT 1]; 
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
            claimRequest.Approval_Status__c = 'Draft';
            claimRequest.Order__c = so.Id;
            claimRequest.Godrej_Sales_Order__c = po.Id;
            claimRequest.Godrej_Order_Product__c = poi.Id;
            claimRequest.Order_Product__c = soi.Id;
            try {
                insert claimRequest;
                System.assert(false); 
            } catch(Exception ex) {
                System.assert(true);
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void createCreditNoteOnAnnexureAClaimRequest() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
            
            Order so = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Secondary']; 
            Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary']; 
            OrderItem poi = [SELECT Id FROM OrderItem WHERE OrderId =:po.Id LIMIT 1];
            OrderItem soi = [SELECT Id FROM OrderItem WHERE OrderId =: so.Id LIMIT 1]; 
            TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
            Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
            claimRequest.Approval_Status__c = 'Approved';
            claimRequest.Order__c = so.Id;
            claimRequest.Godrej_Sales_Order__c = po.Id;
            claimRequest.Godrej_Order_Product__c = poi.Id;
            claimRequest.Order_Product__c = soi.Id;
            insert claimRequest; 
            Claim_Requests__c creditNote;
            TestClaimRequestBuidler childClaimBuilder =  new TestClaimRequestBuidler(GlobalConstants.CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE);
            creditNote = childClaimBuilder.setAssociatedClaim(claimRequest.Id);
            insert creditNote;
        
        }
        Test.stopTest();
    }
    
    @isTest
    public static void createAnnexureBClaimRequestNonStockAndSellCategoryAShouldPass() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;
        Claim_Requests__c cr = [Select Id,Request_Type__c FROM Claim_Requests__c WHERE Id=:claimRequest.Id];
        System.assertEquals('Non Stock & Sell - Category A',cr.Request_Type__c);
        }
        Test.stopTest(); 
    }

    @isTest
    public static void createAnnexureBClaimRequestStockAndSellCategoryAShouldFail() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        try {
            insert claimRequest;
            System.assert(false); 
        } catch(Exception ex) {
            System.assert(true);
        }
        }
        Test.stopTest(); 
    }

    @isTest
    public static void createAnnexureBClaimRequestNonStockAndSellCategoryBShouldPass() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        Product2 p = [Select Id FROM Product2 WHERE Product_Storage_Clasification__c = 'Category A'];
        p.Product_Storage_Clasification__c = 'Category B';
        update p;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;
        Claim_Requests__c cr = [Select Id,Request_Type__c FROM Claim_Requests__c WHERE Id=:claimRequest.Id];
        System.assertEquals('Non Stock & Sell - Category B',cr.Request_Type__c);
        
        }
        Test.stopTest(); 
    }

    @isTest
    public static void createAnnexureBClaimRequestStockAndSellCategoryBShouldPass() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        Product2 p = [Select Id FROM Product2 WHERE Product_Storage_Clasification__c = 'Category A'];
        p.Product_Storage_Clasification__c = 'Category B';
        update p;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;
        Claim_Requests__c cr = [Select Id,Request_Type__c FROM Claim_Requests__c WHERE Id=:claimRequest.Id];
        System.assertEquals('Stock & Sell - Category B',cr.Request_Type__c);
        
        }
        Test.stopTest(); 
    }

    @isTest
    public static void createSCCClaimRequest() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Approved';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;
        
        Claim_Requests__c sccRequest;
        TestClaimRequestBuidler childClaimBuilder =  new TestClaimRequestBuidler('SCC');
        sccRequest = childClaimBuilder.setAssociatedClaim(claimRequest.Id);
        sccRequest.Area_Code__c = 'ST1';
        insert sccRequest;
    	
        }
    Test.stopTest();
    }

    @isTest
    public static void updateBusinessPartnerToStockAndSellCategoryAOnAnnexureBClaimRequestShouldFail() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;

        Account newAccount = new Account(Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId(),Name='TEST');
        insert newAccount;

        claimRequest.Business_Partner_Name__c = newAccount.Id;
        try{
            update claimRequest;
            System.assert(false);
        } catch(Exception ex) {
            System.assert(true);
        }
        }
        Test.stopTest();
    }

    @isTest
    public static void updateBusinessPartnerToNonStockAndSellCategoryBOnAnnexureBClaimRequestShouldPass() {
        Test.startTest();
        User userRec = [select id,Contact.AccountId,Name from User where user.profile.name = 'MHE Dealer Sales Manager Partner User' AND Name='lastname' limit 1];
        Account ac = new Account(Id = userRec.Contact.AccountId,Type='D',Dealer_Type__c = 'Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId());
        update ac;
        Product2 p = [Select Id FROM Product2 WHERE Product_Storage_Clasification__c = 'Category A'];
        p.Product_Storage_Clasification__c = 'Category B';
        update p;
        System.runAs(userRec) {
        Order po = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'MHE_Order_Primary'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId =: po.Id LIMIT 1]; 
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Claim_Request');
        Claim_Requests__c claimRequest = tcrb.setRecordType('Claim Request');
        claimRequest.Approval_Status__c = 'Draft';
        claimRequest.Godrej_Sales_Order__c = po.Id;
        claimRequest.Godrej_Order_Product__c = oi.Id;
        insert claimRequest;

        Account newAccount = new Account(Type='D',Dealer_Type__c = 'Non Stock & Sell',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId(),Name='TEST');
        insert newAccount;

        claimRequest.Business_Partner_Name__c = newAccount.Id;
        update claimRequest;

        Claim_Requests__c cr = [Select Id,Request_Type__c FROM Claim_Requests__c WHERE Id=:claimRequest.Id];
        System.assertEquals('Non Stock & Sell - Category B',cr.Request_Type__c);
        }
        Test.stopTest();
    }

    @isTest
    public static void createAdhocClaimRequest() {
        Test.startTest();
        TestClaimRequestBuidler tcrb =  new TestClaimRequestBuidler('Ad_hoc');
        Claim_Requests__c claimRequest = tcrb.getRecord();
        claimRequest.Area_Code__c = 'ST1';
        insert claimRequest;
        Test.stopTest();
    	
    }

    @isTest
    public static void createWarrantyClaimRequestForActiveAsset() {
        Test.startTest();
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        insert newAccount;
        
        Address__c add = [select id from Address__c where Name__c = 'Nuvoco Plant Pune' LIMIT 1]; 	//Added by pc
        
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Active';
        newAsset.Address_Code__c = add.id;
        newAsset.Type_of_Warranty__c='Not Applicable';
        insert newAsset;

        List<Claim_Requests__c> cr = [SELECT Id FROM Claim_Requests__c WHERE RecordType.DeveloperName ='Warranty' LIMIT 1];
        system.assertEquals(1, cr.size());

        Test.stopTest();
    }

    @isTest
    public static void updateWarrantyClaimRequestToApproved() {
        Test.startTest();
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        insert newAccount;
        
        Address__c add = [select id from Address__c where Name__c = 'Nuvoco Plant Pune' LIMIT 1];		//Added by pc
        
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Active';
        newAsset.Type_Of_Warranty__c='Not Applicable';
        newAsset.Address_Code__c = add.id;
        insert newAsset;

        List<Claim_Requests__c> cr = [SELECT Id,Approval_Status__c FROM Claim_Requests__c WHERE RecordType.DeveloperName ='Warranty' LIMIT 1];
        cr[0].Approval_Status__c ='Approved';
        cr[0].Company__c = '1020';
        try {
            update cr;
            System.assert(false);
        } catch(Exception ex) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void createContractClaimRequest() {
        Test.startTest();
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert accountRecord;
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                    Market_Pricelist__c = true);
        insert pricebookRecord;
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        sc.Status__c = 'Open';
        sc.AccountId = accountRecord.id;
        sc.Pricebook2Id = pricebookRecord.Id;
        sc.MHE_Division__c = 'Contracts';
        sc.Contract_Type__c = GlobalConstants.CMT_CONTRACT_TYPE;
        sc.Billing_Frequency__c='Yearly: Y20';
        insert sc;

        Claim_Requests__c req = new Claim_Requests__c(Service_contract__c = sc.Id,RecordTypeId = Schema.SObjectType.Claim_requests__c.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId());
        insert req;
        Test.stopTest();
   
    }

    @isTest
    public static void createIsrClaimRequest() {
        Test.startTest();
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA');
        accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
        insert accountRecord;
        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Test Pricebook', LN_PriceList_Code__c = '001', PriceList_Code__c = '001', 
                                    IsActive = true, Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE, 
                                    Market_Pricelist__c = true);
        insert pricebookRecord;
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test Service Contract';
        sc.Status__c = 'Open';
        sc.AccountId = accountRecord.id;
        sc.Pricebook2Id = pricebookRecord.Id;
        sc.MHE_Division__c = 'Contracts';
        sc.Contract_Type__c = GlobalConstants.CMT_CONTRACT_TYPE;
        sc.Offloaded_to_Contractor__c = 2;
        insert sc;
        
        ClaimRequestTriggerHandler.TriggerDisabled = true;
        Claim_Requests__c req = new Claim_Requests__c(Service_contract__c = sc.Id,RecordTypeId = Schema.SObjectType.Claim_requests__c.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId(),Price__c = 20);
        insert req;

        Claim_Requests__c isrReq = new Claim_Requests__c(Claim_Request__c = req.Id,Level_1__c = UserInfo.getUserId(),Godrej_Invoice_Number__c='2345' ,RecordTypeId = Schema.SObjectType.Claim_requests__c.getRecordTypeInfosByDeveloperName().get('Invoice_Submission_Request').getRecordTypeId(),Quantity__c = 1);
        insert isrReq;
        
        List<User> usersToInsert=new List<User>();
        Id profileId=[Select Id,Name From Profile Where Name = 'MHE Godrej Branch Champion'].Id;
        TestUserBuilder tub = new TestUserBuilder();
        tub.setProfileId(profileId);
        User salesUser = tub.getTestRecord();
        salesUser.IsActive=true;
        salesUser.LastName='Branch champion';
        usersToInsert.add(salesUser);
        Insert usersToInsert;
        
        isrReq.Level_1__c=usersToInsert[0].Id;
        Update isrReq;
        ClaimRequestTriggerHandler.TriggerDisabled = false;
        Test.stopTest();
         
    }
  /*  
    @isTest
    public static void systemGeneratedEWPContractClaimShouldBeCreated() {
        test.startTest();
        createServiceContract();
        ServiceContract sc=[Select Id,Approval_Status__c,Contract_Type__c From ServiceContract Limit 1];
        sc.Contract_Type__c='EWP';
        sc.Approval_Status__c='Approved';
        sc.Billing_Frequency__c='Monthly: M20';
        Update sc;
        test.stopTest();
        List<Claim_Requests__c> systemGeneratedClaim=[Select Id,Service_Contract__C 
                                                     From Claim_Requests__c 
                                                     Where Service_Contract__c=:sc.Id 
                                                     And Is_System_Generated__c=true
                                                     ];
        System.assert(systemGeneratedClaim.size()==1);
    }
    
    @isTest
    public static void systemGeneratedEWPContractClaimShouldNotBeCreated() {
        
        //Create Account Record
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        insert newAccount;
        
        //Create Asset record
        Asset newAsset = new Asset();
        newAsset.Name= 'testAsset';
        newAsset.AccountId = newAccount.id;
        newAsset.Status = 'Active';
        newAsset.Product_Purchased_Warranty_Start_Date__c=system.today();
        newAsset.Product_Purchased_Warranty_End_Date__c=Date.today()+2;
        newAsset.Equipment_Serial_No__c='001Test';
        newAsset.Type_Of_Warranty__c='Not Applicable';
        insert newAsset;
        System.debug('warranty claim'+[Select Id from claim_requests__c where Asset__c=:newAsset.Id and RecordType.developerName='Warranty']);
        test.startTest();
        createServiceContract();
        ContractLineItem cli=[Select AssetId From ContractLineItem Limit 1];
        cli.AssetId=newAsset.Id;
        Update cli;
        ServiceContract sc=[Select Id,Approval_Status__c,Contract_Type__c From ServiceContract Limit 1];
        sc.Approval_Status__c='Approved';
        Update sc;
        List<Claim_Requests__c> systemGeneratedClaim=[Select Id,Service_Contract__C 
                                                     From Claim_Requests__c 
                                                     Where Service_Contract__c=:sc.Id 
                                                     And Is_System_Generated__c=true
                                                     And Equipment_Serial_No__c='001Test'
                                                     And Start_Date_Of_Contract__c=:System.today()
                                                     And End_Date_Of_Contract__c=:System.today()+2];
        test.stopTest();
        System.assert(systemGeneratedClaim.size()==0);
        
    }
*/
}