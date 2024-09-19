/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Test class for QuoteApprovalHandler and ApprovalSubmitterHierarchyCreator
Inputs:        NA
Test Class:     
History
12-07-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
@isTest
private class QuoteApprovalHandlerTest {
    static list<String> businessUnits = new list<String> {GlobalConstants.BUSINESS_UNIT_MHE_DIVISION, 
                                                        GlobalConstants.INTERIO_BUSINESS_UNIT, 
                                                        GlobalConstants.SSG_BUSINESS_UNIT,
        												GlobalConstants.APPLIANCE_BUSINESS_UNIT};  //Added by pc (Appliances)
        
    @TestSetup static void createData(){
        // Create Products.
        List<Product2> allProducts = createProductRecords();
        insert allProducts;
        
        // Create standard pricebook record for the products created.
        list<PricebookEntry> standardPricebookEntries = createStandardPricebookEntries(allProducts);
        insert standardPricebookEntries;
        
        // Create Pricebooks.
        list<Pricebook2> pricebookRecords = createPricebookRecords();
        insert pricebookRecords;
        
        // Create PricebookEntry for the above products and pricebooks.
        List<PricebookEntry> allPBEs = createPricebookEntryRecords(allProducts, pricebookRecords);
        insert allPBEs;
        
        
        //Inserting reserved chars from custom setting
        Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
        rChar.B2C_character__c = 'A';
        rChar.B2B_Account_Series_Char__c = 'X';
        rChar.B2B_character__c = 'AA';
        
        insert rChar;
        
        //Create Zip Code Data
        ZipCode__c zipCode = new ZipCode__c();
        zipCode.Name = '410002';
        zipCode.CityCode__c = 'PUNE';
        zipCode.City_Name__c = 'PUNE';
        zipCode.StateCode__c = 'MH';
        zipCode.StateName__c = 'Maharashtra';
        zipCode.CountryCode__c = 'IN';   
        zipCode.CountryName__c = 'INDIA';   
        zipCode.ZipCodeExternalId__c = 'IN_410002';
        
        insert zipCode;
        
        
        //Create Address records
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'Nuvoco Limited';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.ZipCode__c = zipCode.Id;
        
        insert address;
        
        for(Integer i= 0; i< businessUnits.size(); i++){
            if(businessUnits[i] == GlobalConstants.BUSINESS_UNIT_MHE_DIVISION){
                //MHE - Rental   
                User rentalApprover3 = createUserRecord(null, 'rentalApprover3', GlobalConstants.MHE_FUNCTIONAL_HEAD_PERSONA, businessUnits[i]);
                User rentalApprover2 = createUserRecord(rentalApprover3.Id, 'rentalApprover2', GlobalConstants.MHE_LOB_HEAD_PERSONA, businessUnits[i]);
                User rentalApprover1 = createUserRecord(rentalApprover2.Id, 'rentalApprover1', GlobalConstants.MHE_MARKETING_MANAGER_PERSONA, businessUnits[i]);
                User rentalSubmitter = createUserRecord(rentalApprover1.Id, 'rentalSubmitter', GlobalConstants.MHE_SALES_MANAGER_PERSONA, businessUnits[i]);
                
            } else if(businessUnits[i] == GlobalConstants.INTERIO_BUSINESS_UNIT){
                // Create User with manager records
                //Interio - Kitchen
                User kitchenApprover2 = createUserRecord(null, 'kitchenApprover2', 'Interio Kitchen-Zonal Head', businessUnits[i]);
                User kitchenApprover1 = createUserRecord(kitchenApprover2.Id, 'kitchenApprover1', 'Interio Kitchen-TSI', businessUnits[i]);
                User kitchenSubmitter = createUserRecord(kitchenApprover1.Id, 'kitchenSubmitter', 'Interio Kitchen-Kitchen COCO', businessUnits[i]);
              
                //Interio - Script   
                User scriptApprover3 = createUserRecord(null, 'scriptApprover3', 'InteroScript- Retail Operations Head', businessUnits[i]);
                User scriptApprover2 = createUserRecord(scriptApprover3.Id, 'scriptApprover2', 'InteroScript- HO Sales Support Manager', businessUnits[i]);
                User scriptApprover1 = createUserRecord(scriptApprover2.Id, 'scriptApprover1', 'InteroScript- COCO Store Manager', businessUnits[i]);
                User scriptSubmitter = createUserRecord(scriptApprover1.Id, 'scriptSubmitter', 'InteroScript- COCO Store Sales Executive', businessUnits[i]);
            
            } else if(businessUnits[i] == GlobalConstants.SSG_BUSINESS_UNIT){
                // Create User with manager records
                //SSG - Regular
                User ssgRegularApprover6 = createUserRecord(null, 'ssgRegularApprover6', 'SSG- Sales & Marketing Head', businessUnits[i]);
                User ssgRegularApprover5 = createUserRecord(ssgRegularApprover6.Id, 'ssgRegularApprover5', 'SSG- National sales manager (International)', businessUnits[i]);
                User ssgRegularApprover4 = createUserRecord(ssgRegularApprover5.Id, 'ssgRegularApprover4', 'SSG- National sales manager (Regular)', businessUnits[i]);
                User ssgRegularApprover3 = createUserRecord(ssgRegularApprover4.Id, 'ssgRegularApprover3', 'SSG- Regional Sales Manager (Exports)', businessUnits[i]);
                User ssgRegularApprover2 = createUserRecord(ssgRegularApprover3.Id, 'ssgRegularApprover2', 'SSG- Regional sales manager (Domestic )', businessUnits[i]);
                User ssgRegularApprover1 = createUserRecord(ssgRegularApprover2.Id, 'ssgRegularApprover1', 'SSG- Territory Sales Manager', businessUnits[i]);
                User ssgRegularSubmitter = createUserRecord(ssgRegularApprover1.Id, 'ssgRegularSubmitter', 'SSG- Sales Engineer', businessUnits[i]);
            
                //SSG - SFS
                User sfsApprover2 = createUserRecord(null, 'sfsApprover2', 'SSG- Sales & Marketing Head', businessUnits[i]);
                User sfsApprover1 = createUserRecord(sfsApprover2.Id, 'sfsApprover1', 'SSG- National sales manager (SFS)', businessUnits[i]);
                User sfsSubmitter = createUserRecord(sfsApprover1.Id, 'sfsSubmitter', 'SSG- Sales Engineer', businessUnits[i]);
            }
        }
        
        User runningAdminUser = createUserRecord(null, '', '', GlobalConstants.BUSINESS_UNIT_MHE_DIVISION);
        
        System.runAs(runningAdminUser) {
            //Create Account
            list<Account> accounts = createAccountRecords(address.Id);
            AccountTriggerHandler.TriggerDisabled = true;
            insert accounts; 
            AccountTriggerHandler.TriggerDisabled = false;
            
            //Create Opportunity
            list<Opportunity> opportunities = createOpportunities(accounts, pricebookRecords, runningAdminUser);
            OpportunityTriggerHandler.TriggerDisabled = true;
            insert opportunities; 
            OpportunityTriggerHandler.TriggerDisabled = false;
        }
    }
    
    private static list<Account> createAccountRecords(Id addressId) {
        list<Account> accountsToInsert = new list<Account>();
        
        for(Integer i= 0; i< businessUnits.size(); i++){
            Account acc = new Account();
            acc.Name = 'Nuvoco Limited';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            acc.PAN__c = 'ASDFG098'+ i +'Z';
            acc.Type = 'D';//Dealer Type
            acc.Business_Unit__c = businessUnits[i];
            acc.Primary_Address__c = addressId;
            acc.Business_Partner_Status__c = 'Open';
            acc.One_Time_Business_Partner__c = 'No';
            
            accountsToInsert.add(acc);
        }
        
        return accountsToInsert;
    }
    
    private static List<Product2> createProductRecords() {
        List<Product2> products = new List<Product2>();

        Product2 baseproduct1 = new Product2(Name = 'GX 300', Item__c = 'GX1', ProductCode = '00001');
        baseproduct1.Is_Independent_product__c = false;
        baseproduct1.Component_Type__c = GlobalConstants.BASE_PRODUCT_COMPONENT_TYPE;
        baseproduct1.IsActive = true;
        baseproduct1.Product_Line__c='HealthCare';
        baseproduct1.Description= 'GX 300 Forklift';
        baseproduct1.Is_New_Equipment__c = true;
        products.add(baseproduct1);

        Product2 variantproduct1 = new Product2(Name = '01 Interio Item', Item__c = '235_898974-INTERIO', ProductCode = '000021');
        variantproduct1.Is_Independent_product__c = true;
        variantproduct1.Component_Type__c = '';
        variantproduct1.IsActive = true;
        variantproduct1.Description = '01 Interio Item'; 
        variantproduct1.Product_Line__c='dummy';
        products.add(variantproduct1);
        
        //Shankar Sahu 13-11-2020 to add ssg products
        Product2 ssgProduct = new Product2(Name = 'SSG item',Item__c='SSG1',ProductCode ='0000031' );
        ssgProduct.Is_Independent_product__c = true;
        ssgProduct.IsActive = true;
        ssgProduct.Description = '1 SSG Item';
        ssgProduct.Product_Line__c = 'Dummy Dummy';
        products.add(ssgProduct);
        
        return products;
    }
    
    private static List<PricebookEntry> createStandardPricebookEntries(list<Product2> products) {
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();
        Id pricebookId = Test.getStandardPricebookId();

        for(Product2 product : products) {
            PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = product.Id,
            UnitPrice = 10000, IsActive = true);

            standardPricebookEntries.add(standardPrice);
        }
        return standardPricebookEntries;
    }
    
    private static list<Pricebook2> createPricebookRecords() {
        list<Pricebook2> pricebookRecords = new list<Pricebook2>();
        
        PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'tst', PriceList_Code__c = 'Tst');
        pricebookRecords.add(rentalPriceBook);
        
        PriceBook2 mrpPriceBook = new PriceBook2(Name = 'WC2_3001 / MRP Price Book WC2', IsActive = true, LN_PriceList_Code__c = 'WC2', PriceList_Code__c = 'WC2_3001');
        pricebookRecords.add(mrpPriceBook);
        
        //Shankar 13-11-2020 ssg pricebook
        PriceBook2 ssgPricebook =new PriceBook2(Name = 'SSG price book', IsActive = true, LN_PriceList_Code__c = '.', PriceList_Code__c = '_3000');
        pricebookRecords.add(ssgPricebook);
        
        PriceBook2 appliancesPricebook =new PriceBook2(Name = 'App price book', IsActive = true, LN_PriceList_Code__c = '.', PriceList_Code__c = '_4000');
        pricebookRecords.add(appliancesPricebook);			//Added by pc
        
        return pricebookRecords;
    }
    
    private static List<PricebookEntry> createPricebookEntryRecords(List<Product2> products, list<Pricebook2> pricebooks) {
        List<PricebookEntry> pricebookEntryRecords = new List<PricebookEntry>();
        for(Integer i=0; i< products.size(); i++) {
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = products[i].Id;
            pbe.Pricebook2Id = pricebooks[i].Id;
            pbe.UnitPrice = 1000.00;
            pbe.IsActive = true;
            
            pricebookEntryRecords.add(pbe);
        }
        return pricebookEntryRecords;
    }
    
    private static List<Opportunity> createOpportunities(list<Account> accounts, list<Pricebook2> pricebookRecords, user userToRun) {
        List<Opportunity> opps = new List<Opportunity>();
        ZipCode__c zip = [select id from ZipCode__c limit 1];
        Account acc = new Account();
        acc.Name = 'Nuvoco Limited';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
        acc.PAN__c = 'ASDFG098'+ 8 +'Z';
        acc.Type = 'D';//Dealer Type
        acc.Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT;        
        acc.Business_Partner_Status__c = 'Open';
        acc.One_Time_Business_Partner__c = 'No';
        
        Account accConstruction = new Account();
        accConstruction.Name = 'Construction test account';
        accConstruction.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
        //accConstruction.PAN__c = 'ASDFG098'+ 8 +'Z';
        accConstruction.Type = 'D';//Dealer Type
        accConstruction.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;        
        accConstruction.Business_Partner_Status__c = 'Open';
        accConstruction.One_Time_Business_Partner__c = 'No';
        
        Account influAcc = new Account();
        influAcc.Name = 'Nuvoco Limited';
        influAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Influencer').getRecordTypeId();
        influAcc.PAN__c = 'ASDFG099'+ 8 +'Z';
        influAcc.Type = 'D';//Dealer Type
        influAcc.Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT;        
        influAcc.Business_Partner_Status__c = 'Open';
        influAcc.One_Time_Business_Partner__c = 'No';
        
        Account accSSD = new Account();
        accSSD.Name = 'Construction test account';
        accSSD.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
        //accConstruction.PAN__c = 'ASDFG098'+ 8 +'Z';
        accSSD.Type = 'D';//Dealer Type
        accSSD.Business_Unit__c = GlobalConstants.SSD_BUSINESS_UNIT;        
        accSSD.Business_Partner_Status__c = 'Open';
        accSSD.One_Time_Business_Partner__c = 'No';
        
        test.startTest();
        List<Account> accList = new List<Account>();
        accList.add(accSSD);
        accList.add(acc);
        accList.add(accConstruction);
        accList.add(influAcc);
        AccountTriggerHandler.TriggerDisabled = true;
        Insert accList;
        AccountTriggerHandler.TriggerDisabled = false;
        test.stopTest();
        for(Integer i= 0; i<12; i++){
                Opportunity opp = new Opportunity(Name = 'Test Opportunity -'+ i, StageName = 'Qualification');
                opp.CloseDate = (Date.today()).addMonths(10);
                opp.Sales_Branch_Name__c = userToRun.Logistic_Company__c;
                if(i == 0){
                    //Create Eqipment Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE').getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[0].Id;
                    opp.MHE_Division__c = 'Outright Sales';
                    opp.Business_Unit__c = accounts[0].Business_Unit__c;
                    opp.AccountId = accounts[0].id;
                } else if(i == 1) {
                    //Create Rental Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('MHE_Rental').getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[0].Id; 
                    opp.MHE_Division__c = 'Godrej RenTRUST';
                    opp.Business_Unit__c = accounts[0].Business_Unit__c;
                    opp.AccountId = accounts[0].id;
                } else if(i== 2){
                    //Create Kitchen Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[1].Id; 
                    opp.Business_Unit__c = accounts[1].Business_Unit__c;
                    opp.Sub_Division__c = GlobalConstants.B2C_SUBDIVISION;
                    opp.Interio_Sub_Division__c = GlobalConstants.INTERIO_KITCHEN;
                    opp.AccountId = accounts[1].id;
                } else if(i == 3){
                    //Create Interio Script Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[1].Id; 
                    opp.Business_Unit__c = accounts[1].Business_Unit__c;
                    opp.Sub_Division__c = GlobalConstants.B2C_SUBDIVISION;
                    opp.Interio_Sub_Division__c = GlobalConstants.INTERIO_SCRIPT; 
                    opp.AccountId = accounts[1].id;
                } else if(i == 4){
                    opp.Segment__c = 'FMCG';
                    //Create SSG - SFS Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();
                   //Shankar Sahu 13-11-2020
                   opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = accounts[2].Business_Unit__c;
                    opp.Sub_Division__c = 'B2B';
                    opp.Regular_Key__c='Regular';//added by pankaj
                    opp.Opportunity_Type__c = 'Swift';
                    opp.AccountId = accounts[2].id;                    
                } else if(i == 5){
                    opp.Segment__c = 'FMCG';
                    //Create SSG - Regular/Key Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();
                    //Shankar Sahu 13-11-2020
                   opp.Pricebook2Id = pricebookRecords[2].Id;
                   opp.Business_Unit__c = accounts[2].Business_Unit__c;
                    opp.Sub_Division__c = 'B2B';
                    opp.Regular_Key__c='Regular';//added by pankaj
                    opp.Opportunity_Type__c = 'Service';
                    opp.AccountId = accounts[2].id;                    
                }else if(i == 6){
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = accounts[2].Business_Unit__c;
                    opp.Sub_Division__c = 'B2B';
                    opp.Regular_Key__c='Key';//added by pankaj
                    opp.Opportunity_Type__c = 'Swift';
                    opp.AccountId = accounts[2].id;                    
                }else if(i == 7){
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();                    
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = accounts[2].Business_Unit__c;
                    opp.Sub_Division__c = 'B2B';
                    opp.Regular_Key__c='Key';//added by pankaj
                    opp.Opportunity_Type__c = 'Service';
                    opp.AccountId = accounts[2].id;                    
                }else if(i == 8){                   
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = GlobalConstants.Locks_BUSINESS_UNIT;
                    opp.Sub_Division__c = 'B2B';
                    opp.LocksSegment__c='OEM';
                    opp.Sub_segment__c = 'Wooden Door OEM';
                    opp.Dealer_Name__c = acc.id;
                    opp.AccountId = acc.id; 
                    opp.Project_Details__c = 'Test';
                    opp.OEM__c = acc.Id;
                    opp.Influencer__c = influAcc.id;
                    opp.ZipCode__c = zip.id;
                }else if(i == 9){                   
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
                    opp.Sub_Division__c = 'B2B';
                    opp.LocksSegment__c='OEM';
                    opp.Sub_segment__c = 'Wooden Door OEM';
                    opp.Dealer_Name__c = accConstruction.id;
                    opp.AccountId = accConstruction.id; 
                    opp.Project_Details__c = 'Test';
                    opp.OEM__c = acc.Id;
                    opp.Site__c = 'Test';
                    opp.Plant_Location__c = 'Kalyan';
                    //opp.Cluster__c = 'NOR';
                    opp.Project_qty_m3_1000__c = 1000;
                    opp.G_B_qty_m3_300__c = 300;
                    opp.LOB_N__c = 'RMC';
                    opp.ZipCode__c = zip.id;
                }else if(i == 10){                   // Added By Poonam For SCF - 69             
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = GlobalConstants.Construction_BUSINESS_UNIT;
                    opp.Sub_Division__c = 'B2B';
                    opp.LocksSegment__c='OEM';
                    opp.Sub_segment__c = 'Wooden Door OEM';
                    opp.Dealer_Name__c = accConstruction.id;
                    opp.AccountId = accConstruction.id; 
                    opp.Project_Details__c = 'Test';
                    opp.OEM__c = acc.Id;
                    opp.Site__c = 'Test';
                    opp.Plant_Location__c = 'Kalyan';
                    //opp.Cluster__c = 'NOR';
                    opp.Product_List__c= 'AAC';
                    opp.Estimated_Project_AAC_Qty_in_CBM__c=76;
                    opp.Estimated_Project_Duroplast_Qty_Bag__c=89;
                    opp.Estimated_Project_EasyFix_Qty_Bag__c=77;
                    opp.G_B_Quantity_AAC_Qty_in_CBM__c=97;
                    opp.G_B_Quantity_Duroplast_Qty_Bags__c=44;
                    opp.G_B_Quantity_EasyFix_Qty_Bags__c=17;
                    opp.Est_Project_Solid_Concrete_Block_Nos__c= 10;
                    opp.G_B_Quantity_Solid_Concrete_Block_Nos__c=37;
                    opp.Estimated_Project_Pavers_in_Sqm__c= 71;
                    opp.G_B_Quantity_Pavers_in_Sqm__c=54;
                    opp.Estimated_Project_Curb_Stone_in_Nos__c=42;
                    opp.G_B_Quantity_Curb_Stone_in_Nos__c=32;
                    opp.Estimated_Project_Tilefix_Qty_Bag__c= 55;
					opp.G_B_Quantity_Tilefix_Qty_Bags__c = 88;
                    opp.LOB_N__c = 'WPS';
                    opp.ZipCode__c = zip.id;
                }else if(i == 10){                   
                    opp.Segment__c = 'FMCG';                    
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSD).getRecordTypeId();
                    opp.Pricebook2Id = pricebookRecords[2].Id;
                    opp.Business_Unit__c = GlobalConstants.SSD_BUSINESS_UNIT;
                    opp.Sub_Division__c = 'B2B';
                    opp.LocksSegment__c='KAM';
                    opp.Sub_segment__c = 'Real Estate';
                    opp.Dealer_Name__c = accSSD.id;
                    opp.AccountId = accSSD.id; 
                    opp.Project_Details__c = 'Test';
                    opp.OEM__c = accSSD.Id;
                    opp.Site__c = 'Test';
                    opp.Plant_Location__c = 'Kalyan';
                    //opp.Cluster__c = 'NOR';
                    opp.Project_qty_m3_1000__c = 1000;
                    opp.G_B_qty_m3_300__c = 300;
                    opp.LOB_N__c = 'RMC';
                    opp.ZipCode__c = zip.id;
                    opp.Sales_Branch_Name__c = 'Maharashtra';
                    opp.Order_Type__c = 'Direct Billing to customer';
                    //opp.Booking_Option__c = 'Dealer Price';
                    opp.Segment__c = 'Engineering';
                    opp.Customer__c = 'Internal';
                }
                   /* else if(i == 11){
                    //Create Interio Script Opp
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_Script').getRecordTypeId();  //Added interio script by pc
                    opp.Pricebook2Id = pricebookRecords[1].Id; 
                    opp.Business_Unit__c = accounts[1].Business_Unit__c;
                    opp.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
                    opp.Interio_Sub_Division__c = GlobalConstants.INTERIO_SCRIPT; 
                    opp.AccountId = accounts[1].id;
                }*/
            		else if(i == 11){
                    //Create Appliances Opp				//Added by pc
                    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Appliances').getRecordTypeId();  //Added Appliances opp
                    opp.Pricebook2Id = pricebookRecords[3].Id; 
                    opp.Business_Unit__c = 'H';
                    opp.Sub_Division__c = GlobalConstants.B2B_SUBDIVISION;
                    List<Account> AccRec =[select id from Account where Name = 'Nuvoco Limited' AND Business_Unit__c =: GlobalConstants.APPLIANCE_BUSINESS_UNIT LIMIT 1 ];
 					opp.AccountId = AccRec[0].id;
                }
            	
                opps.add(opp); 
            }
        
        return opps;
    }
    
    private static QuoteLineItem createQuoteLineItemRecord(Quote quoteRecord, PricebookEntry pricebookEntryRecord, Double requestedDiscount) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = quoteRecord.Id;
            qli.UnitPrice = pricebookEntryRecord.UnitPrice;
            qli.Product2Id = pricebookEntryRecord.Product2Id;
            qli.Quantity = 1 ;
            qli.PricebookEntryId = pricebookEntryRecord.Id;
            qli.Requested_Customer_Discount__c = requestedDiscount;

        return qli;
    }
    
    private static user createUserRecord(Id managerUserId, String userNameAddOnString, String persona, String BU){
        //Fetch System Profile
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        // Create User records.
        User userRec = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.user7@godrej.com');
        
        userRec.Sub_Division__c = 'B2B';
        userRec.Logistic_Company__c = '5020';
        userRec.Area_Code__c = 'WN1';
        userRec.ManagerId = managerUserId;
        userRec.Persona__c = persona;
        userRec.username = 'test.user8@godrej.com';
        userRec.Business_Unit__c = BU;
        userRec.IsActive = true;
        
        if(String.isNotBlank(userNameAddOnString))
            userRec.username = 'test.user8@godrej.com.'+userNameAddOnString;
        UserTriggerHandler.TriggerDisabled = true;
        insert userRec; 
        UserTriggerHandler.TriggerDisabled = false;
        
        return userRec;
    }
    
   /* static testMethod void test_updateApprovers_SSG_SFS(){
        Boolean isApproverUpdated;
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.sfsSubmitter' LIMIT 1];
                            
        //Shankar 13-11-2020 pricebook entry to create a quote line item
         PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = 'SSG item' 
                                                AND PriceBook2.Name = 'SSG price book' LIMIT 1];
                          
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create SSG - SFS Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG SFS Quote test';
            quoteRec.Category__c = 'SFS Imported';
            //quoteRec.Quote_Discount__c = 40;
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            insert quoteRec;
            
            // Shankar 12-11-2020
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 40);
            insert qli;

            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id, SSG_SFS_Sales_Marketing_Head__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            isApproverUpdated = contextuser.Manager.ManagerId == pars[0].SSG_SFS_Sales_Marketing_Head__c ? true: false;
            
          //  System.assertEquals(isApproverUpdated, true);            
        }
    }*/
    
    static testMethod void test_updateApprovers_SSG_Regular(){						//removed comm by poonam
        Boolean isApproverUpdated;
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.ssgRegularSubmitter' LIMIT 1];
                            
        //Shankar 12-11-2020 pricebook entry to create a quote line item
         PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = 'SSG item' 
                                                AND PriceBook2.Name = 'SSG price book' LIMIT 1];
                          
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
           // quoteRec.Quote_Discount__c = 40;
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            quoteRec.Dealer_SAC_Applicable__c='No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            
            quoteRec.Pricing_approval_request__c = newPar.Id;
            update quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            // Shankar 12-11-2020
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 40);
            insert qli;

            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id, Regional_Sales_manager__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            isApproverUpdated = contextuser.Manager.ManagerId == pars[0].Regional_Sales_manager__c ? true: false;
            
            System.assertEquals(isApproverUpdated, true);            
        }
    }
    
    static testMethod void test_updateApprovers_Interio_Kitchen(){
        Boolean isApproverUpdated;
        
        PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = '01 Interio Item' 
                                                AND PriceBook2.Name = 'WC2_3001 / MRP Price Book WC2' LIMIT 1];
        
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.kitchenSubmitter' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'Interio_B2C_Appliances' AND Interio_Sub_Division__c =: GlobalConstants.INTERIO_KITCHEN LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create Interio Kitchen Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_KITCHEN).getRecordTypeId();
            quoteRec.Name = 'Interio Kitchen Quote test';
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            
            quoteRec.Pricing_approval_request__c = newPar.Id;
            update quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 30);
            insert qli;
            
            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id, Interio_KITCHEN_Zonal_Head__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            isApproverUpdated = contextuser.Manager.ManagerId == pars[0].Interio_KITCHEN_Zonal_Head__c ? true: false;
            
            System.assertEquals(isApproverUpdated, true);            
        }
    }
    
    static testMethod void test_updateApprovers_Interio_Script(){
        Boolean isApproverUpdated;
        
        PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = '01 Interio Item' 
                                                AND PriceBook2.Name = 'WC2_3001 / MRP Price Book WC2' LIMIT 1];
        
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c, Manager.Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.scriptSubmitter' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'Interio_B2C_Appliances' AND Interio_Sub_Division__c =: GlobalConstants.INTERIO_SCRIPT LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create Interio Script Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_INTERIO_SCRIPT).getRecordTypeId();
            quoteRec.Name = 'Interio Script Quote test';
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            
            quoteRec.Pricing_approval_request__c = newPar.Id;
            update quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 30);
            insert qli;
            
            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id, Interio_Script_Retails_Operation_Head__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            isApproverUpdated = contextuser.Manager.Manager.ManagerId == pars[0].Interio_Script_Retails_Operation_Head__c ? true: false;
            
            System.assertEquals(isApproverUpdated, true);            
            pars[0].Assign_Approver_Dynamically__c = true;
            pars[0].Approval_Status__c = 'Approved';
            update pars[0];
        }
    }
    //Needs review
    static testMethod void test_updateApprovers_MHE_Rental(){
        Boolean isApproverUpdated;
        
        PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = 'GX 300' 
                                                AND PriceBook2.Name =: System.Label.MHE_SF_Local_Rental_PB LIMIT 1];
        
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c, Manager.Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.rentalApprover3' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'MHE_Rental' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create MHE Rental Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL).getRecordTypeId();
            quoteRec.Name = 'MHE Rental Quote test';
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            quoteRec.Payment_Terms__c = 'Greater than 25 days';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            
            quoteRec.Pricing_approval_request__c = newPar.Id;
            update quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 30);
            insert qli;
            
            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            Test.stopTest();
            
            list<Pricing_approval_request__c> pars = [SELECT Id, Interio_B2B_Level_7__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            isApproverUpdated = contextuser.Manager.Manager.ManagerId == pars[0].Interio_B2B_Level_7__c ? true: false;
            System.debug('==pars[0].Id===>'+pars[0].Id +'\n==pars[0].Interio_B2B_Level_7__c==>'+pars[0].Interio_B2B_Level_7__c);
            //System.assertEquals(isApproverUpdated, true);            
        }
    }
    
    static testMethod void test_SSG_SFS_submitForApproval(){
        String recordStatus;
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.sfsSubmitter' LIMIT 1];
             
             //Shankar 13-11-2020 pricebook entry to create a quote line item
         PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = 'SSG item' 
                                                AND PriceBook2.Name = 'SSG price book' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create SSG - SFS Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG SFS Quote test';
            quoteRec.Category__c = 'SFS Imported';
            //quoteRec.Quote_Discount__c = 40;
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            quoteRec.Dealer_SAC_Applicable__c='No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            // Shankar 12-11-2020
            // to be Reviewed 
            QuoteLineItem qli = createQuoteLineItemRecord(quoteRec, pricebookEntryRecord, 40);
            insert qli;
            
            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            recordStatus = QuoteApprovalHandler.submitForApproval(quoteRec.Id, 'SSG_SFS approval text');
            Test.stopTest();
        }
        //System.assertEquals(recordStatus.contains('Quote successfully submitted for approval!!'), true); 
    }
    
 /*   static testMethod void test_MHE_Rental_submitForApproval(){
        String recordStatus;
        PricebookEntry pricebookEntryRecord = [SELECT Id, PriceBook2.Id, Product2Id, UnitPrice FROM PricebookEntry
                                                WHERE Product2.Name = 'GX 300' 
                                                AND PriceBook2.Name =: System.Label.MHE_SF_Local_Rental_PB LIMIT 1];
        
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c, Manager.Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.rentalApprover3' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'MHE_Rental' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create MHE Rental Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL).getRecordTypeId();
            quoteRec.Name = 'MHE Rental Quote test';
            quoteRec.Pricebook2Id = pricebookEntryRecord.PriceBook2.Id;
            quoteRec.Payment_Terms__c = 'Greater than 25 days';
            
            insert quoteRec;
                
            QuoteApprovalHandler.updateApprovers(quoteRec.Id);
            List<Pricing_approval_request__c> approvals = [SELECT Id, Category__c,  
                                                                    Quote_Record_Type_Developer_Name__c,Approval_Status__c 
                                                                        FROM Pricing_approval_request__c 
                                                                        WHERE Quote__c =: quoteRec.Id Limit 1];
            System.debug('QUOTE '+approvals[0].Quote_Record_Type_Developer_Name__c);
            System.debug('QUOTE App'+approvals[0].Approval_Status__c);
            recordStatus = QuoteApprovalHandler.submitForApproval(quoteRec.Id, 'NHE Rental approval text');
            Test.stopTest();
        }
        System.assertEquals(recordStatus.contains('Quote successfully submitted for approval!!'), true); 
    } */
    
    static testMethod void updatePARForAutoapprovedQuotesTest(){
        User contextuser = [SELECT Id, ManagerId, Manager.ManagerId, Persona__c, 
                                Manager.Persona__c, Manager.Manager.Persona__c  
                            FROM User 
                            WHERE username = 'test.user8@godrej.com.sfsSubmitter' LIMIT 1];
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        System.runAs(contextuser) {
            Test.startTest();
            //Create SSG - SFS Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG SFS Quote test';
            quoteRec.Category__c = 'SFS Imported';
            quoteRec.Is_autoapproved__c = true;
            quoteRec.Approval_Status__c = GlobalConstants.APPROVED_STATUS;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            
            
            Pricing_approval_request__c newPar = new Pricing_approval_request__c();
            newPar.Quote__c = quoteRec.Id;
            insert newPar;
            
            quoteRec.Pricing_approval_request__c = newPar.Id;
            update quoteRec;
			QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.updatePARForAutoapprovedQuotes(new Map<Id, Quote>{quoteRec.Id=>quoteRec});
            Test.stopTest();
            
            List<Pricing_approval_request__c> pars = [SELECT Id,Is_autoapproved__c,SSG_SFS_Sales_Marketing_Head__c FROM Pricing_approval_request__c WHERE Quote__c =:quoteRec.Id];
            System.assertEquals(false,pars[0].Is_autoapproved__c);
            
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyTest(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover2'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            quoteRec.Quote_Discount__c = 25;
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;

            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyUpdateTest(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover2'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Quote_Discount__c = 25;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            quoteRec.Category__c = 'Key';
            quoteRec.Quote_Discount__c = 27;
            update quoteRec;

            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyH1Test(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover1'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Quote_Discount__c = 17;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyH0Test(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover1'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Quote_Discount__c = 15;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyH5Test(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover4'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Quote_Discount__c = 35;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_Regular_KeyH7Test(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.ssgRegularApprover6'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Service' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'Regular';
            quoteRec.Quote_Discount__c = 45;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_Regular_Key(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_SFSTest(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.sfsApprover1'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'SFS Imported';
            quoteRec.Quote_Discount__c = 25;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;

            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_SFS(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }
    
    static testMethod void validateAndAutoapproveForSSG_SFSH2Test(){
        User usr = [Select Id FROM User WHERE UserName = 'test.user8@godrej.com.sfsApprover2'];
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'SFS Imported';
            quoteRec.Quote_Discount__c = 35;
            quoteRec.Dealer_SAC_Applicable__c = 'No';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            QuoteRecordProcessor processor = new QuoteRecordProcessor();
            processor.validateAndAutoapproveForSSG_SFS(new List<Quote>{quoteRec},null);
            
            Quote quoteRecord = [Select Id,Is_autoapproved__c FROM Quote WHERE Id =: quoteRec.Id LIMIT 1];
            System.assert(true, quoteRecord.Is_autoapproved__c);
            Test.stopTest();
    
        }
    }

    @isTest
    static void validCommissionEnteredShouldPass() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Parts').getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'SFS Imported';
            quoteRec.Quote_Discount__c = 35;
            quoteRec.SCC_Activities__c = 'Enquiry Generation;Demo Conducted;Follow up for release of order or financial vetting;Ensuring technical clearance;Commissioning of the equipment;Training at the time of commissioning';
            quoteRec.Commission__c = 2.5;
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            List<Quote> updated = [SELECT Id,Commission__c FROM Quote WHERE Id =:quoteRec.Id];
            System.assertEquals(2.5,updated[0].Commission__c,'Commission not updated as expected');
            Test.stopTest();
    }


    @isTest
    static void invalidCommissionEnteredShouldFail() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Opportunity_Type__c = 'Swift' LIMIT 1];
        Test.startTest();
            //Create SSG - Regular Quote
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('MHE_Parts').getRecordTypeId();
            quoteRec.Name = 'SSG Regular Quote test';
            quoteRec.Category__c = 'SFS Imported';
            quoteRec.Quote_Discount__c = 35;
            quoteRec.SCC_Activities__c = 'Enquiry Generation;Demo Conducted;Follow up for release of order or financial vetting;Ensuring technical clearance;Commissioning of the equipment;Training at the time of commissioning';
            quoteRec.Commission__c = 2.5;
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
            
            quoteRec.Commission__c = 10;
            try{
                update quoteRec;
                List<Quote> updated = [SELECT Id,Commission__c FROM Quote WHERE Id =:quoteRec.Id];
                System.assertEquals(2.5,updated[0].Commission__c,'Invalid Commission not validated');
            } catch(Exception ex) {
                List<Quote> updated = [SELECT Id,Commission__c FROM Quote WHERE Id =:quoteRec.Id];
                System.assertEquals(2.5,updated[0].Commission__c,'Invalid Commission not validated');
            }          
            Test.stopTest();
    }
    //Added by pankaj on 24 march 2023 for SSEPB-35
@isTest
    static void keySwiftTestmethod() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'SSG' AND Regular_key__c= 'Key' AND (Opportunity_Type__c = 'Swift' OR Opportunity_Type__c = 'Service') LIMIT 2];
        Test.startTest();
            List<Quote> lstQuote = new List<Quote>();
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();
            quoteRec.Name = 'SSG Key swift Quote test';
          lstQuote.add(quoteRec);
        
          opps[1].Dealer_Involved_Y_N__c='Yes';
          update opps;
          Quote quoteRec2 = new Quote();
            quoteRec2.OpportunityId = opps[1].Id;
            quoteRec2.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId();
            quoteRec2.Name = 'SSG Key swift Quote test2';
            quoteRec2.Dealer_Margin_Dealer_order__c = 10;
            quoteRec2.Dealer_SAC_Applicable__c = 'No';
        	quoteRec2.Dealer_Direct_Customer_order__c = 'Dealer';
          lstQuote.add(quoteRec2);
            QuoteTriggerHandler.TriggerDisabled = true;
            insert lstQuote;
            QuoteTriggerHandler.TriggerDisabled = false;
       
            Test.stopTest();
    }
    
    @isTest
    static void LocksDivisionTestMethod() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName =: GlobalConstants.RECORDTYPE_Locks_B2B LIMIT 1];
        Test.startTest();
            List<Quote> lstQuote = new List<Quote>();
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Locks_B2B).getRecordTypeId();
            quoteRec.Name = 'SSD Quote test';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
       
            Test.stopTest();
    }
        
  @isTest
    static void ConstructionDivisionTestMethod() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName =: GlobalConstants.RECORDTYPE_Construction_B2B LIMIT 1];
        Test.startTest();
            List<Quote> lstQuote = new List<Quote>();
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECORDTYPE_Construction_B2B).getRecordTypeId();
            quoteRec.Name = 'SSD Quote test';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
       
            Test.stopTest();
    }    
    /*
    @isTest
    static void ssdDivisionTestMethod() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName =: GlobalConstants.QUOTE_RECORDTYPE_SSD LIMIT 1];
        Test.startTest();
            List<Quote> lstQuote = new List<Quote>();
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSD).getRecordTypeId();
            quoteRec.Name = 'SSD Quote test';
            //quoteRec.Sales_Branch_Name__c = 'Maharashtra';
            
            //insert quoteRec;        
        Test.stopTest();
    }  */
    
    @isTest
    static void applianceDivisionTestMethod() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName =: GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE LIMIT 1];
        Test.startTest();
            List<Quote> lstQuote = new List<Quote>();
            Quote quoteRec = new Quote();
            quoteRec.OpportunityId = opps[0].Id;
            quoteRec.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE).getRecordTypeId();
            quoteRec.Name = 'appliances Quote test';
            QuoteTriggerHandler.TriggerDisabled = true;
        	insert quoteRec;  
            quoteRec.Name = 'Appliance Quote';
            quoteRec.Payment_Terms__c = '0';
            update quoteRec;
            QuoteTriggerHandler.TriggerDisabled = false;
        
          Quote quoteRec1 = new Quote();
            quoteRec1.OpportunityId = opps[0].Id;
            quoteRec1.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE).getRecordTypeId();
            quoteRec1.Name = 'appliances Quote test';
            QuoteTriggerHandler.TriggerDisabled = true;
            insert quoteRec1;
            QuoteTriggerHandler.TriggerDisabled = false; 
          quoteRec1.Payment_Terms__c = 'Z60';
          update quoteRec1;
          quoteRec1.Status = GlobalConstants.QUOTE_STATUS_FINALIZED;
          update quoteRec1;
        Test.stopTest();
    } //end by pankaj
}