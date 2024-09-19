@istest
public class InvocableOpportunityProductsCreatorTest {
      @istest
        static void createData(){       
       {
           /*Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OpportunityTriggerDisabled__c = true;
            setting.FireQLIValidationRules__c = false;
            setting.FireOpportunityProductValidationRules__c = false; */ //Commented by Shreela on 25th Jan 2023
            //Added by Shreela on 25th Jan 2023
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OpportunityTriggerDisabled__c = true;
            setting.FireQLIValidationRules__c = false;
            setting.FireOpportunityProductValidationRules__c = false;
            setting.DiscountMatrixTriggerDisabled__c = true;
            setting.BranchTriggerDisabled__c = true;
            setting.CaseTriggerDisabled__c = true;
            setting.UserTriggerDisabled__c = true;
            setting.PricingApprovalRequestTriggerDisabled__c = true;
            setting.ProductTriggerDisabled__c = true;
            setting.OpportunityProductTriggerDisabled__c = true;
            setting.AddressByBPTriggerDisabled__c = true;
            setting.QLITriggerDisabled__c = true;
            setting.LeadTriggerDisabled__c = true;
            insert setting ;
             
            //Create Sales Office Record
            Sales_Office__c salesOffice = new Sales_Office__c();
            salesOffice.RecordTypeId = Schema.SObjectType.Sales_Office__c.getRecordTypeInfosByDeveloperName().get('Sales_Office').getRecordTypeId();
            salesOffice.Country__c = 'IND';
            salesOffice.State__c = 'IND_MH';
            salesOffice.LN_Sales_Office_Code__c = '9876qm';
            insert salesOffice;
            
            //Create Registration Number Record
            Registration_Number__c registration = new Registration_Number__c();
            registration.State__c = 'IND_MH';
            registration.Commodity_Code__c = System.Label.Commodity_Code;
            registration.Effective_Date__c = System.today().addDays(6);
            insert registration;
                                    
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
    
            //insert rentalPriceBook;
            PriceBook2 rentalPriceBook = new PriceBook2(Name = 'MHE Contracts PL', IsActive = true, LN_PriceList_Code__c = 'MHE', PriceList_Code__c = 'MHEContractsPL_3000');
            insert rentalPriceBook;
            
            //insert Products
           List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').setIsActive(true).setIsGeneric(true).getTestRecord(),
                new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').setIsGeneric(true).setIsActive(true).getTestRecord(),
                new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').setIsActive(true).setIsGeneric(true).getTestRecord(),
                new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').setIsActive(true).setIsGeneric(true).getTestRecord(),
                new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').setIsActive(true).setIsGeneric(false).getTestRecord()
            };
            insert allProducts;
           
           //Insert PriceBook Entry with Standard Price -Added by Shreela on 31st Jan 2023
           Id pricebookId = Test.getStandardPricebookId();
           
           List<PriceBookEntry> allPBEstandard = new List<PriceBookEntry> { 
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(pricebookId).setUnitPrice(50000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(pricebookId).setUnitPrice(3000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(pricebookId).setUnitPrice(30000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(pricebookId).setUnitPrice(32000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(pricebookId).setUnitPrice(32000).getTestRecord()
            };
            insert allPBEstandard;
            
            // insert PricebookEntry
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord()
            };
            insert allPBEs;
    
            // insert Account
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            
            
            Contact contactRecord = createContactRecord(accountRecord.Id);
            insert contactRecord;
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
                .setMHEDivision('Contracts').getSavedTestRecord();       
          
            List<OpportunityLineItem> oppoProduct=createOpportunityLineItems(allPBEs,oppRecord);      
           
            Quote quoteRecord = new TestQuoteBuilder()
                .setRecordTypeId(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Contracts').getRecordTypeId())
                .setOpportunityId(oppRecord.Id).setPricebook2Id(rentalPriceBook.Id).getSavedTestRecord(); 
             
            // insert QuoteLineItem   
            List<QuoteLineItem> allQLI = new List<QuoteLineItem> {
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(50000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[0].Id).getTestRecord(),
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(3000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[1].Id).getTestRecord(),
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(30000).setSequenceNumber(1).setPriceBookEntryId(allPBEs[2].Id).getTestRecord(),
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[3].Id).getTestRecord(),
                new TestQuoteLineItemBuilder().setQuoteId(quoteRecord.Id).setUnitPrice(32000).setPriceBookEntryId(allPBEs[4].Id).getTestRecord()
            };
            insert allQLI;
           
           //Create Address Record						//Added by pc
            Address__c address = new Address__c();
            address.Address_Type__c = 'B2B';
            address.Address_Format__c = 'ADR';
            address.Name__c = 'Nuvoco Plant Pune';
            address.Telephone__c = '8765432111';
            address.Email__c = 'punetest1234@nuvoco.com';
            address.Building__c = 'Avenues';
            address.Street2__c = '1st Street';
           address.Street__c = '2nd street';
            insert address;      
            
            // insert Asset
            List<Asset> assetRecords = new List<Asset>();
            Asset assetRecord = createAssetRecord(accountRecord.Id, contactRecord.Id);
            assetRecord.Status = 'Unregistered'; //Added by Shreela on 31st Jan 2023
           	assetRecord.Address_Code__c = address.id;			//Added by pc 
            assetRecords.add(assetRecord);   
            assetRecord.Date_of_Commissioning__c=system.today();//added
            assetRecord.Equipment_Category__c='WE';//Added
            assetRecord.Product_Sub_Category__c='HPT';//Added
            assetRecord.Product_Category__c='Warehousing';//Added
            assetRecord.Product_Family__c='Equipment';//Added
            ServiceContract sc = new ServiceContract();
            sc.Name = 'Test Service Contract';
            sc.Status__c = GlobalConstants.SERVICE_CONTRACT_ACTIVE_STATUS;
            sc.AccountId = accountRecord.id;
            sc.Pricebook2Id = rentalPriceBook.Id;
            sc.Associated_Opportunity__c = oppRecord.id;
            sc.StartDate =system.today();
            sc.EndDate = system.today().adddays(30);
            insert sc;           
			
			
            //Asset newAsset = createAssetRecord(accountRecord.Id, contactRecord.Id);
            Asset newAsset = new Asset(); //Added by Shreela on 31st Jan 2023
            newAsset.Name= 'Asset 3';
            newAsset.SerialNumber = 'AX003';
            newAsset.Status = 'Unregistered';
            newAsset.Date_of_Commissioning__c=system.today();//added
            newAsset.Equipment_Category__c='WE';//added
            newAsset.Product_Sub_Category__c='HPT';//added
            newAsset.Product_Category__c='Warehousing';//added
            newAsset.Product_Family__c='Equipment';//added
            newAsset.AccountId = accountRecord.Id;   //Added by Shreela on 31st Jan 2023
            newAsset.ContactId = contactRecord.Id;
           	newAsset.Address_Code__c = address.id;			//Added by pc
            newAsset.Area_Code__c = 'NH1';
            newAsset.Product_Purchased_Warranty_Start_Date__c = System.today().addMonths(-1);
            newAsset.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(6);
            newAsset.Type_of_Warranty__c = 'Std Warranty';  //Ended by Shreela on 31st Jan 2023
            assetRecords.add(newAsset);	
            //AssetTriggerHandler.TriggerDisabled=true;
            insert assetRecords;
            //AssetTriggerHandler.TriggerDisabled=false;
            
            //Insert CLI record
            ContractLineItem cli = new ContractLineItem();
            cli.AssetId = newAsset.id;
            cli.ServiceContractId = sc.id; 
            cli.PricebookEntryId = allPBEs[0].Id;
            cli.UnitPrice = 10;
            cli.Quantity = 1;
            cli.StartDate = system.today();
            cli.EndDate = system.today().addDays(10);
            cli.Configuration_Line_Number__c= '1';
            insert cli;
            
            Opportunity oppRecord2 = new TestOpportunityBuilder()
            .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId())
            .setMHEDivision('Contracts').setPriceBookEntryId(rentalPriceBook.Id).getSavedTestRecord();
            
            oppRecord2.Previous_Service_Contract__c=sc.id;
            
            list<opportunity> opplist= new list<opportunity>();
            opplist.add(oppRecord2);
            list<list<opportunity>> opportunitylist= new list<list<opportunity>>();
            opportunitylist.add(opplist);
            
           test.starttest();
            InvocableOpportunityProductsCreator.createOpportunityProducts(opportunitylist);
            test.stopTest();
        }
    }
    
     public static List<OpportunityLineItem> createOpportunityLineItems(List<PricebookEntry> pricebookEntries, Opportunity oppRecord) {
          List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
          for(PricebookEntry pbe : pricebookEntries) {
            OpportunityLineItem oppProduct = new OpportunityLineItem();
            oppProduct.PricebookEntryId = pbe.Id;
            oppProduct.Quantity = 1;
            oppProduct.UnitPrice = pbe.UnitPrice;
            oppProduct.Sequence_Number__c = 1;
            oppProduct.OpportunityId = oppRecord.Id;
            oppProducts.add(oppProduct);
        }
        return oppProducts;
    }
    
    private static Contact createContactRecord(Id accountId) {
        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'John';
        contactRecord.LastName='Doe';
        contactRecord.Active__c = true;
        contactRecord.MobilePhone = '9012342120';
        contactRecord.Email = 'john.doe@godrej.com';
        contactRecord.AccountId = accountId;
        return contactRecord;
    }
    
     private static Asset createAssetRecord(Id accountId, Id contactId) {
        Asset assetRecord = new Asset();
        assetRecord.Name = 'Test Asset record';
        assetRecord.SerialNumber = 'AX001';
        assetRecord.AccountId = accountId;
        assetRecord.ContactId = contactId;
        assetRecord.Area_Code__c = 'NH1';
        assetRecord.Product_Purchased_Warranty_Start_Date__c = System.today().addMonths(-1);
        assetRecord.Product_Purchased_Warranty_End_Date__c = Date.today().addMonths(6);
        assetRecord.Status = GlobalConstants.ASSET_ACTIVE_STATUS;
        assetRecord.Type_of_Warranty__c = 'Std Warranty';
        return assetRecord;
    }
               
}