/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test Data Factory for Leasing Business for Leads
 * History
 * --------
 * 02-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class LeaseTestDataFactory {
    public LeaseTestDataFactory() {

    }
    /**
     * Create Building
     * Create Floor / Leasable Asset
     */
    public static String  createOfficeSpaceBuilding(){
        Project_Unit__c b = new Project_Unit__c();
        b.Name  =  '02GBD';
        b.Building_code__c = '02GBD';
        b.Asset_Type__c = 'Building';
        b.Project__c = 'Godrej Business District';
        b.City__c = 'MUMBAI';
        b.Use_Of_Premises__c ='Office Space';
        b.Location__c = 'Vikhroli West';
        b.Carpet_Area__c = 813294;
        insert b;
        return b.Id;
    }
    public static String  createVacantUnits(Id buildingId){
        Floor__c f3 = new Floor__c();
        f3.Name = 'OF02 GBDOFFA4';
        f3.Asset_Code__c = buildingId;  
        f3.Total_Carpet_Area_Sq_ft__c = 40422;
        f3.Building__c = buildingId;
        f3.Type_of_Premise__c = 'Warm Shell';
        insert f3;
        return f3.Id;
    }
    public static String  createOccupiedUnits(Id buildingId){
        Floor__c f2 = new Floor__c();
        f2.Name = 'OF02 GBDOFFA5';
        f2.Asset_Code__c = '02 GBDOFFA5';
        f2.Total_Carpet_Area_Sq_ft__c = 40422;
        f2.Building__c = buildingId;
        f2.Type_of_Premise__c = 'Warm Shell';
        insert f2;

        Junction_Unit__c ju2 = new Junction_Unit__c();
        ju2.Status__c = 'Leased';
        ju2.Carpet_Area_in_Sq_Ft__c = 40422;
        ju2.start_date__c = system.today();
        ju2.end_date__c = system.today().addMOnths(60);
        Id accId = createAccount('OANIN1234K');
        Id oppId = createOpportunity(accId);
        Id hotId = createHot(oppId);
        ju2.Opportunity__c = oppId;
        ju2.HEAD_OF_TERMS__c = hotId;
        ju2.Floor__c = f2.Id;
        insert ju2;

        return f2.Id;
    }
    public static String  createChurnExpectedUnit(Id buildingId){
        Floor__c f = new Floor__c();
        f.Name = 'OF02 GBDOFFA6';
        f.Asset_Code__c = '02 GBDOFFA6';
        f.Total_Carpet_Area_Sq_ft__c = 40422;
        f.Building__c = buildingId;
        f.Type_of_Premise__c = 'Warm Shell';
        insert f;

        Junction_Unit__c ju = new Junction_Unit__c();
        ju.Status__c = 'Leased';
        ju.Carpet_Area_in_Sq_Ft__c = 40422;
        ju.start_date__c = system.today();
        ju.end_date__c = system.today().addMOnths(9);
        Id accId = createAccount('CANIN1234K');
        Id oppId = createOpportunity(accId);
        Id hotId = createHot(OppId);
        ju.Opportunity__c = oppId;
        ju.HEAD_OF_TERMS__c = hotId;
        ju.Leasing_Status__c = 'Coming up for renewal';
        ju.Floor__c = f.Id;
        insert ju;
        return f.Id;
    }
    public static String  createPartiallyVacantUnit(Id buildingId){
        Floor__c f1 = new Floor__c();
        f1.Name = 'OF02 GBDOFFA7';
        f1.Asset_Code__c = '02 GBDOFFA7';
        f1.Total_Carpet_Area_Sq_ft__c = 40422;
        f1.Building__c = buildingId;
        f1.Type_of_Premise__c = 'Warm Shell';
        insert f1;

        Junction_Unit__c ju1 = new Junction_Unit__c();
        ju1.Status__c = 'Leased';
        ju1.Carpet_Area_in_Sq_Ft__c = 20000;
        ju1.start_date__c = system.today();
        ju1.end_date__c = system.today().addMOnths(60);
        Id accId = createAccount('AANIN1234K');
        Id oppId = createOpportunity(accId);
        Id hotId = createHot(oppId);
        ju1.Opportunity__c = oppId;
        ju1.HEAD_OF_TERMS__c = hotId;
        ju1.Leasing_Status__c = ElbConstantsClass.LEASE_STATUS_ACTIVE;
        ju1.Floor__c = f1.Id;
        insert ju1;

        return f1.Id;
    }

    public static String createLead(){
        String leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.LEAD_LEASING_B2B_DEV).getRecordTypeId();
        Lead l = new Lead();
        l.lastName = 'ITemp Consulting-Ramesh Tiwari';
        l.leadSource  = 'Website';
        l.Company = 'iTemp Consulting';
        
        Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
            rChar.B2C_character__c = 'A';
            rChar.B2B_Account_Series_Char__c = 'X';
            rChar.B2B_character__c = 'AA';
            insert rChar;
        Account a = new Account();//
        a.Name = 'ABC Company';//
        a.Business_Unit__c = 'N';
        insert a;
        Id cId = createContact(a.Id);
        l.Source_Contact__c = cId;
        l.RecordTypeId = leadRecordTypeId;
        l.MobilePhone = '8877990099';
        l.Business_Unit__c = 'N';
        l.Segment__c = 'Others';
        l.Sector_If_others__c ='Others';
        l.Sub_Division__c = 'B2B';
        l.Location__c = 'Vikhroli';
        l.Initial_Space_needed__c = 20000;
        l.Description = 'Space needed in Q3';
        l.Account__c = a.Id;
        insert l;
        return l.Id;
    }
    /**
     *  Lead gets converted to opportuntiy when a site visit task
     * on lead is completed
     */
    public static String convertLead(Id LeadId){
        Task t = new Task();
        t.Status = 'Completed';
        t.Call_Attempt_Status__c = 'Visit Confirmed';
        t.Next_action_date__c = system.today().addDays(1);
        t.View_Status__c  = 'Completed';
        t.Site_Visit_date__c = system.today();
        t.whoId = leadId;
        insert t;
        return t.Id;
    }
    // with different PAN #s
    public static String createAccount(String PAN){
        String cleanedPAN =PAN.replaceAll('[^a-zA-Z0-9]', '');
        String email = cleanedPAN +'@godrej.com';
        String userId = createAdminUser(email);
     
        User contextuser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        Account acc;
        Address__c addr = createPrimaryAddress(PAN);
        System.runAs(contextuser) {
            acc = new Account(Name=PAN.toUpperCase(), 
                                      Account_Series__c='NIX',
                                      PAN__c=PAN,
                                      Account_Code__c = 'NIX' + PAN.mid(0,4));
                                       
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
        }
        acc.Primary_Address__c = addr.Id;
        acc.PAN__c = PAN;
       
        String SoId;
        List<Sales_Office__c> soList = new List<Sales_Office__c>();
        soList = [Select Id from Sales_Office__c LIMIT 1];
        if(soList != null && !soList.isEmpty())
           soId = soList[0].Id;
        else {
                soId = createSalesServiceOffice();
        }
        contextuser.Sales_Office__c = soId;
        Branch__c branch1=new Branch__c();
        branch1.Business_Partner__c=acc.Id;
        branch1.Ship_To_Address__c=addr.Id;
        insert branch1;
        createShipToAddress(addr,acc);
        return acc.Id;
    }
    
    public static String createAccountFromName(String Name){
       // User contextuser = [Select Id, Business_Unit__c,LastName FROM User where LastName ='User'AND Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        String userId = createAdminUser('leasetestdatauserAcc12345@godrej.com');
        User adminUser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        Account acc;
        Address__c addr = createPrimaryAddress();
        System.runAs(adminUser) {
            acc = new Account(Name= Name, 
                                      Account_Series__c='NIX',
                                      PAN__c='ABCDE1234P',
                                      Account_Code__c = 'NIX123457');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
        }
        acc.Primary_Address__c = addr.Id;
        acc.PAN__c = 'PANIN1234J';
        List<Sales_Office__c> soList = [Select Id from Sales_Office__c LIMIT 1];

        String SoId;
        if(soList != null && !soList.isEmpty())
           soId = soList[0].Id;
        else {
                soId = createSalesServiceOffice();
        }
        adminUser.Sales_Office__c = soId;
        Branch__c branch1=new Branch__c();
        branch1.Business_Partner__c=acc.Id;
        branch1.Ship_To_Address__c=addr.Id;
        insert branch1;
        
        createShipToAddress(addr,acc);
        return acc.Id;
    }
     // to create unique accounts
    public static String createIpcAccountFromName(String Name){
        User contextuser = [Select Id, Business_Unit__c FROM User where Allow_Business_Account_Creation__c = true And Profile.Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME And IsActive = true LIMIT 1];
        Account acc;
        Address__c addr = createPrimaryAddress();
        System.runAs(contextuser) {
            acc = new Account(Name= Name, 
                                      Account_Series__c='1DR',
                                      PAN__c='ABCDE1234Q',
                                      Account_Code__c = '1DR123457',
                             Business_Unit__c = 'N');
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Vendor');
            insert acc;
        }
        acc.Primary_Address__c = addr.Id;
        acc.PAN__c = 'PANIN1234L';
        List<Sales_Office__c> soList = [Select Id from Sales_Office__c LIMIT 1];

        String SoId;
        if(soList != null && !soList.isEmpty())
           soId = soList[0].Id;
        else {
                soId = createSalesServiceOffice();
        }
        contextuser.Sales_Office__c = soId;
        Branch__c branch1=new Branch__c();
        branch1.Business_Partner__c=acc.Id;
        branch1.Ship_To_Address__c=addr.Id;
        insert branch1;
        
        createShipToAddress(addr,acc);
        return acc.Id;
    }
    
    public static String createAdminUser(String emailAddress){
        
        Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = emailAddress, username = emailAddress, Business_Unit__c = 'N' );
        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2100';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        return userToRun.Id;
    }

    public static String createAccount(){
        String userId = createAdminUser('leasetestdatauserAcc1234@godrej.com');
        User adminUser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        Account acc;
        Address__c addr = createPrimaryAddress();
        System.runAs(adminUser) {
            acc = new Account(Name='iTemp Consulting'.toUpperCase(), 
                                      Account_Series__c='NIX',
                                      PAN__c='ABCDE1234S', 
                                      Account_Code__c = 'NIX123456'
                                      ,Business_Unit__c = 'N'
                              );
            acc.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
            insert acc;
        }
        acc.Primary_Address__c = addr.Id;
        acc.PAN__c = 'PANIN1234K';
        List<Sales_Office__c> soList = [Select Id from Sales_Office__c LIMIT 1];
        String SoId;
        if(soList != null && !soList.isEmpty())
           soId = soList[0].Id;
        else {
                soId = createSalesServiceOffice();
        }
        adminUser.Sales_Office__c = soId;   
        Branch__c branch1=new Branch__c();
        branch1.Business_Partner__c=acc.Id;  
        branch1.Ship_To_Address__c=addr.Id;    
        insert branch1;
        createShipToAddress(addr,acc);
        return acc.Id;
    }
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='iTemp Consulting'.toUpperCase());
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id);
        insert addr;
        return addr;
    }
    // to create unique accounts
    private static Address__c createPrimaryAddress(String PAN){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name=PAN.toUpperCase());
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id);
        return addr;
    }
    private static Address_by_BP__c createShipToAddress(Address__c addr, Account accRecord){
        Address_by_BP__c shipToAdd = new Address_by_BP__c(Address_Code__c = addr.id, Account__c = accRecord.id);
        insert shipToAdd;
        return ShipToAdd;
    }
    public static String createContact(Id accId){
        Contact c = new Contact();
        c.firstName = 'Test';
        c.lastName = 'Contact';
        c.AccountId =accId;
        c.MobilePhone = '9789871001';
        insert c;
        return c.Id;
    }
    
    public static Id createSalesServiceOffice(){
        Sales_Office__c salesoffice = new Sales_Office__c();
        String SORecordTypeId = Schema.SObjectType.Sales_Office__c.getRecordTypeInfosByDeveloperName().get('Sales_Office').getRecordTypeId();
        salesOffice.RecordTypeId = SORecordTypeId;
        salesoffice.Name = 'CON_2110_LEASING TEST';
        salesoffice.LN_Sales_Office_Code__c = ElbConstantsClass.SALES_OFFICE_CODE;
        salesoffice.Country__c = 'IND';
        salesoffice.State__c = 'IND_MH';
        salesoffice.Sales_Office_Code__c = 'D_NZER01';
        salesoffice.Sales_Order_Series__c = 'NOB';
        insert salesoffice;
        return salesoffice.Id;
    }
    
    public static String createLeasingUser(){
        Profile userProfile = [Select Id from Profile where Name =: ElbConstantsClass.LEASING_PROFILE LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Lease', lastname = 'User', Alias = 'luser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'lease.userAcc@godrej.com', username = 'lease.userAcc@godrej.com', Business_Unit__c = 'N');

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = true;
        userToRun.Logistic_Company__c = '2100';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        return userToRun.Id;
    }
    public static String createBillingUser(){
        Profile userProfile = [Select Id from Profile where Name =: ElbConstantsClass.BILLING_PROFILE LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Bill', lastname = 'User', Alias = 'buser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'bill.userAcc@godrej.com', username = 'bill.userAcc@godrej.com', Business_Unit__c = 'N',
                            Salary_Code__c = ElbConstantsClass.USER_SALARY_CODE_RAJEEV);

        userToRun.IsActive = true;
        userToRun.Allow_Business_Account_Creation__c = false;
        userToRun.Logistic_Company__c = '2100';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        return userToRun.Id;
    }
    
    public static string createOpportunity(Id accId){
        /*String userId = createAdminUser();
        User adminUser = [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        Account acc;*/
        String oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.OPPORTUNITY_RECORD_TYPE_LEASING).getRecordTypeId();
        Opportunity o = new Opportunity();
        o.Name = 'Leased Unit Opp';
        o.AccountId = accId;
        o.RecordTypeId = oppRecordTypeId;
        o.StageName = 'Qualification';
        o.CloseDate = Date.today();
        o.Business_Unit__c = 'N';
        insert o;
        return o.Id;
    }
    /** 
     * creates Head of terms under an opportunity with billing schedule, premise tagging and 
     * Term clauses
     */
    public static string createHOT(Id oppId){
        HEAD_OF_TERMS__c hot = new HEAD_OF_TERMS__c();
        hot.Opportunity__c = oppId;
        insert hot;
        return hot.Id;
    }
    public static string tagPremise(Id hotId, Id oppId){
        Id bId = createOfficeSpaceBuilding();
        Id fId = createVacantUnits(bId);
        Junction_Unit__c ju2 = new Junction_Unit__c();
        ju2.Status__c = ElbConstantsClass.UNIT_STATUS;
        ju2.Carpet_Area_in_Sq_Ft__c = 40422;
        ju2.Premise_Group__C = 'A';
        ju2.Opportunity__c = oppId;
        ju2.HEAD_OF_TERMS__c = hotId;
        ju2.Floor__c =fId;
        insert ju2;
        Id bId1 = createOfficeSpaceBuilding();
        Id fId1 = createVacantUnits(bId1);
        Junction_Unit__c ju3 = new Junction_Unit__c();
        ju3.Status__c = ElbConstantsClass.UNIT_STATUS;
        ju3.Carpet_Area_in_Sq_Ft__c = 40422;
        ju3.Premise_Group__C = 'B';
        ju3.Opportunity__c = oppId;
        ju3.HEAD_OF_TERMS__c = hotId;
        ju3.Floor__c =fId1;
        insert ju3;
        return hotId;
    }
    public static string tagMultiPremise(Id hotId, Id oppId){
        Id bId = createOfficeSpaceBuilding();
        Id fId = createVacantUnits(bId);
        Junction_Unit__c ju2 = new Junction_Unit__c();
        ju2.Status__c = ElbConstantsClass.UNIT_STATUS;
        ju2.Carpet_Area_in_Sq_Ft__c = 40422;
        ju2.Premise_Group__C = 'A';
        ju2.Opportunity__c = oppId;
        ju2.HEAD_OF_TERMS__c = hotId;
        ju2.Floor__c =fId;
        insert ju2;
        Id bId1 = createOfficeSpaceBuilding();
        Id fId1 = createVacantUnits(bId1);
        Junction_Unit__c ju3 = new Junction_Unit__c();
        ju3.Status__c = ElbConstantsClass.UNIT_STATUS;
        ju3.Carpet_Area_in_Sq_Ft__c = 40422;
        ju3.Premise_Group__C = 'B';
        ju3.Opportunity__c = oppId;
        ju3.HEAD_OF_TERMS__c = hotId;
        ju3.Floor__c =fId1;
        insert ju3;
        Junction_Unit__c ju4 = new Junction_Unit__c();
        ju4.Status__c = ElbConstantsClass.UNIT_STATUS;
        ju4.Carpet_Area_in_Sq_Ft__c = 40422;
        ju4.Premise_Group__C = 'B';
        ju4.Opportunity__c = oppId;
        ju4.HEAD_OF_TERMS__c = hotId;
        ju4.Floor__c =fId1;
        insert ju4;
        return hotId;
    }
    
    
     public static string tagPremiseWithStatusActive(Id hotId, Id oppId){
        Id bId = createOfficeSpaceBuilding();
        Id fId = createVacantUnits(bId);
        Junction_Unit__c ju2 = new Junction_Unit__c();
        ju2.Status__c = ElbConstantsClass.ACTIVE_STATUS;
        ju2.Start_Date__c = date.today().addDays(-5);
        ju2.End_Date__c = date.today().addDays(190);    
        ju2.Carpet_Area_in_Sq_Ft__c = 40422;
        ju2.Premise_Group__C = 'A';
        ju2.Opportunity__c = oppId;
        ju2.HEAD_OF_TERMS__c = hotId;
        ju2.Floor__c =fId;
        insert ju2;
        Id bId1 = createOfficeSpaceBuilding();
        Id fId1 = createVacantUnits(bId1);
        Junction_Unit__c ju3 = new Junction_Unit__c();
        ju3.Status__c = ElbConstantsClass.ACTIVE_STATUS;
        ju3.Carpet_Area_in_Sq_Ft__c = 40422;
        ju3.Premise_Group__C = 'B';
        ju3.Start_Date__c = date.today().addDays(-5);
        ju3.End_Date__c = date.today().addDays(190); 
        ju3.Opportunity__c = oppId;
        ju3.HEAD_OF_TERMS__c = hotId;
        ju3.Floor__c =fId1;
        insert ju3;
        return hotId;
    }
    
    public static Map<String,Charges_Type__c> createChargeTypes(){
        PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;

        PriceBook2 leasingPriceBook = new PriceBook2(Name = 'CON_2110 / Leasing Dummy Price Book', IsActive = true, LN_PriceList_Code__c = 'CON', PriceList_Code__c = 'CON_3000', Business_Unit__c='N');
        insert leasingPriceBook;

        List<Product2> allProducts = new List<Product2> {
            new TestProductBuilder().setName('ELB ITPrk C LicenseFee Main').setDescription('ELB ITPrk C LicenseFee Main').setItemCode('80131801SD00041').getTestRecord(),
            new TestProductBuilder().setName('ELB ITPrk C CAM Chrgs KPMG').setItemCode('80131801SD00102').setDescription('ELB ITPrk C CAM Chrgs KPMG').getTestRecord(),
            new TestProductBuilder().setName('ELB ITPrk C Common Fac Fees').setItemCode('80131801SD00042').setDescription('ELB ITPrk C Common Fac Fees').getTestRecord(),
            new TestProductBuilder().setName('ELB ITPrk C AC Chrgs Main').setItemCode('80131801SD00048').setDescription('ELB ITPrk C AC Chrgs Main').getTestRecord()
        };
        insert allProducts;

        List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(leasingPriceBook.Id).setUnitPrice(0).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(leasingPriceBook.Id).setUnitPrice(0).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(leasingPriceBook.Id).setUnitPrice(0).getTestRecord(),
            new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(leasingPriceBook.Id).setUnitPrice(0).getTestRecord()
        };
        insert allPBEs;
        Map<String,Charges_Type__c> chargeMap = new Map<String,Charges_Type__c>();
        Charges_Type__c cLicence = new Charges_Type__c();
        cLicence.Name = 'License Fee Monthly';
        cLicence.Billing_Cycle__c= 'Every Month';
        cLicence.Category__c = 'revenue generating';
        cLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
        cLicence.Tax_applicable__c =true;
        cLicence.Tax_Percentage__C = 10;
        cLicence.Type_Of_Billing__c = 'Monthly fixed';
        cLicence.Charge_CCode__c = allProducts[0].Id;
        insert cLicence;
        chargeMap.put(cLicence.Charge_Type__c, cLicence);
        
        Charges_Type__c qLicence = new Charges_Type__c();
        qLicence.Name = 'License Fee Quarterly';
        qLicence.Billing_Cycle__c= 'Every Month';
        qLicence.Category__c = 'revenue generating';
        qLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
        qLicence.Tax_applicable__c =true;
        qLicence.Tax_Percentage__C = 10;
        qLicence.Type_Of_Billing__c ='Quarterly Fixed';//ElbConstantsClass.TYPE_BILLING_QUARTERLY_FIXED;// 'Quarterly Fixed';
        qLicence.Charge_CCode__c = allProducts[0].Id;
        insert qLicence;
       // chargeMap.put(cLicence.Charge_Type__c, qLicence);
        chargeMap.put( 'License Fee Quarterly', qLicence);
        
        Charges_Type__c yLicence = new Charges_Type__c();
        yLicence.Name = 'License Fee Yearly';
        yLicence.Billing_Cycle__c= 'Every Month';
        yLicence.Category__c = 'revenue generating';
        yLicence.Charge_Type__c = ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE;
        yLicence.Tax_applicable__c =true;
        yLicence.Tax_Percentage__C = 10;
        yLicence.Type_Of_Billing__c = 'Yearly Fixed';
        yLicence.Charge_CCode__c = allProducts[0].Id;
        insert yLicence;
       // chargeMap.put(cLicence.Charge_Type__c, yLicence);
        chargeMap.put('License Fee Yearly', yLicence);
            
       	Charges_Type__c carpark = new Charges_Type__c();
        carpark.Name = 'Car Park';
        carpark.Billing_Cycle__c= '1st and 2nd of every month';
        carpark.Category__c = 'revenue generating';
        carpark.Charge_Type__c =ElbConstantsClass.CHARGE_TYPE_CAR_PARK;
        carpark.Tax_applicable__c =true;
        carpark.Tax_Percentage__C = 10;
        carpark.Type_Of_Billing__c = 'Monthly fixed';
        carpark.Charge_CCode__c = allProducts[2].Id;
        insert carpark;
        chargeMap.put(carpark.Charge_Type__c, carpark);
        
        //for additoanl ac charges
        Charges_Type__c accharge = new Charges_Type__c();
        accharge.Name = 'AC Charges (Additional)';
        accharge.Billing_Cycle__c= '1st and 2nd of every month';
        accharge.Category__c = 'revenue generating';
        accharge.Charge_Type__c ='AC Charges (Additional)';
        accharge.Tax_applicable__c =true;
        accharge.Tax_Percentage__C = 10;
        accharge.Type_Of_Billing__c = 'Monthly Variable';
        accharge.Charge_CCode__c = allProducts[2].Id;
        insert accharge;
        chargeMap.put(accharge.Charge_Type__c, accharge);
        
        //for Amount of Water
        Charges_Type__c wateram = new Charges_Type__c();
        wateram.Name = 'Water Consumption';
        wateram.Billing_Cycle__c= '1st and 2nd of every month';
        wateram.Category__c = 'revenue generating';
        wateram.Charge_Type__c ='Water Consumption';
        wateram.Tax_applicable__c =true;
        wateram.Tax_Percentage__C = 10;
        wateram.Type_Of_Billing__c = 'Monthly Variable';
        wateram.Charge_CCode__c = allProducts[2].Id;
        insert wateram;
        chargeMap.put(wateram.Charge_Type__c, wateram);
        
        Charges_Type__c cam = new Charges_Type__c();
        cam.Name = 'CAM Charges';
        cam.Billing_Cycle__c= '7th of every month';
        cam.Category__c = 'revenue generating';
        cam.Charge_Type__c =ElbConstantsClass.CHARGE_TYPE_CAM1;
        cam.Tax_applicable__c =true;
        cam.Tax_Percentage__C = 10;
        cam.Type_Of_Billing__c = 'Monthly variable';
        cam.Charge_CCode__c = allProducts[1].Id;
        insert cam;
        chargeMap.put(cam.Charge_Type__c, cam);
        
        Charges_Type__c hvac = new Charges_Type__c();
        hvac.Name = 'HVAC Charges';
        hvac.Billing_Cycle__c= '7th of every month';
        hvac.Category__c = 'revenue generating';
        hvac.Charge_Type__c = 'HVAC';
        hvac.Tax_applicable__c =true;
        hvac.Tax_Percentage__C = 10;
        hvac.Type_Of_Billing__c = 'Monthly variable';
        hvac.Charge_CCode__c = allProducts[3].Id;
        insert hvac;
        chargeMap.put(hvac.Charge_Type__c, hvac);
        
        Charges_Type__c Resi = new Charges_Type__c();
        Resi.Name = 'Residential rental billing';
        Resi.Charge_Type__c =ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL;
        Resi.Tax_applicable__c =true;
        Resi.Tax_Percentage__C = 10;
        Resi.Type_Of_Billing__c = 'Monthly fixed';
        Resi.Charge_CCode__c = allProducts[0].Id;
        insert Resi;
        chargeMap.put(Resi.Charge_Type__c,Resi);
        
        Charges_Type__c hous = new Charges_Type__c();
        hous.Name = 'Housing Billing';
        hous.Charge_Type__c =ElbConstantsClass.CHARGE_TYPES_HOUSING;
        hous.Tax_applicable__c =true;
        hous.Tax_Percentage__C = 10;
        hous.Type_Of_Billing__c = 'Monthly fixed';
        hous.Charge_CCode__c = allProducts[0].Id;
        insert hous;
        chargeMap.put(hous.Charge_Type__c,hous);

        return chargeMap;
        
    }
    /** 
     * create billing schedule
     */
    public static void createBillingSchedule(Head_Of_Terms__c h){
        Map<String,Charges_Type__c> chargeMap = createChargeTypes();
        system.debug('get(key)++:'+chargeMap.keySet());
        system.debug('get(size)-:'+chargeMap.size());
        List<Billing_Schedule__c> bschList = new List<Billing_Schedule__c>();
        Billing_Schedule__c bSch = new Billing_Schedule__c();
        bSch.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE).Id;
        bSch.Head_Of_Terms__c = h.Id;
        bSch.start_date__c = h.Licence_Commencement_Date__c;
        bsch.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bsch.Rate__c = 100;
        bsch.Amount__c = 500000;
        bsch.Number_of_Months__c = 24;
        bschList.add(bsch);
        
        Billing_Schedule__c bSch0 = new Billing_Schedule__c();
        bSch0.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE).Id;
        bSch0.Head_Of_Terms__c = h.Id;
        bSch0.start_date__c = h.Licence_Commencement_Date__c;
        bsch0.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bsch0.Rate__c = 120;
        bsch0.Amount__c = 600000;
        bsch0.Number_of_Months__c = 36;
        bschList.add(bsch0);

        Billing_Schedule__c bsch1 = new Billing_Schedule__c();
        bsch1.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPE_CAM1).Id;
        bsch1.Head_Of_Terms__c = h.Id;
        bsch1.start_date__c = h.Licence_Commencement_Date__c;
        bsch1.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bsch1.Number_of_Months__c = 0;
        bschList.add(bsch1);
        
        Billing_Schedule__c bsch2 = new Billing_Schedule__c();
        bsch2.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPE_CAR_PARK).Id;
        bsch2.Head_Of_Terms__c = h.Id;
        bsch2.start_date__c = h.Licence_Commencement_Date__c;
        bsch2.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bsch2.Number_of_Months__c = 0;
        bschList.add(bsch2);
        
        Billing_Schedule__c bsch3 = new Billing_Schedule__c();
        bsch3.Charges_Type__c = chargeMap.get('HVAC').Id;
        bsch3.Head_Of_Terms__c = h.Id;
        bsch3.Number_of_Months__c = 0;
        bschList.add(bsch3);

        Billing_Schedule__c bSch4 = new Billing_Schedule__c();
        bSch4.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE).Id;        
        bSch4.Head_Of_Terms__c = h.Id;
        bSch4.start_date__c = h.Licence_Commencement_Date__c;
        bSch4.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bSch4.Rate__c = 100;
        bSch4.Amount__c = 500000;
        bSch4.Number_of_Months__c = 24;
        bschList.add(bSch4);
        
        
        Billing_Schedule__c bSch5 = new Billing_Schedule__c();
        bSch5.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE).Id;
        bSch5.Head_Of_Terms__c = h.Id;
        bSch5.start_date__c = h.Licence_Commencement_Date__c;
        bSch5.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bSch5.Rate__c = 0;
        bSch5.Amount__c = 0;
        bSch5.Number_of_Months__c = 3;
        bschList.add(bSch5);
        system.debug('bSch5:--'+bSch5);
        
        Billing_Schedule__c bSch6 = new Billing_Schedule__c();
        bSch6.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_RESIDENTIAL).Id;        
        bSch6.Head_Of_Terms__c = h.Id;
        bSch6.start_date__c = h.Licence_Commencement_Date__c;
        bSch6.End_date__c = h.Licence_Commencement_Date__c.addMonths(24);
        bSch6.Rate__c = 100;
        bSch6.Amount__c = 500000;
        bSch6.Number_of_Months__c = 24;
        bschList.add(bSch6);
        system.debug('bSch6:--'+bSch6);
        
       // List<Charges_Type__c> QchargeTypes = [SELECT Id, Type_Of_Billing__c FROM Charges_Type__c WHERE  Type_Of_Billing__c=: ElbConstantsClass.TYPE_BILLING_QUARTERLY_FIXED OR
       //                                      Type_Of_Billing__c=: ElbConstantsClass.TYPE_BILLING_YEARLY_FIXED  ORDER BY Type_Of_Billing__c];
        
        Date nextMonth = h.Licence_Commencement_Date__c.addMonths(1);
        Date nextMonthFirstDate = h.Licence_Commencement_Date__c.toStartOfMonth().addMonths(1);
        Date nextMonthLastDay = nextMonthFirstDate.addMonths(1).addDays(-1);

        
        Billing_Schedule__c bSch7 = new Billing_Schedule__c();
       // bSch7.Charges_Type__c = QchargeTypes[0].ID;
        bSch7.Charges_Type__c = chargeMap.get( 'License Fee Quarterly').Id;
        bSch7.Head_Of_Terms__c = h.Id;
        bSch7.start_date__c = nextMonthFirstDate;
        bSch7.End_date__c = nextMonthLastDay;
        bSch7.To_be_billed_on__c=nextMonthFirstDate.addDays(-1);
        bSch7.Rate__c = 0;
        bSch7.Amount__c = 0;
        bSch7.Number_of_Months__c = 2;
        bschList.add(bSch7);
        system.debug('bSch7:--'+bSch7);
        
        Billing_Schedule__c bSch8 = new Billing_Schedule__c();
       // bSch8.Charges_Type__c = QchargeTypes[0].ID;
        bSch8.Charges_Type__c =  chargeMap.get( 'License Fee Quarterly').Id;
        bSch8.Head_Of_Terms__c = h.Id;
        bSch8.start_date__c =nextMonthFirstDate.addMonths(1); 
        bSch8.End_date__c = nextMonthFirstDate.addMonths(2).addDays(-1);
        bSch8.To_be_billed_on__c=nextMonthLastDay;
        bSch8.Rate__c = 0;
        bSch8.Amount__c = 0;
        bSch8.Number_of_Months__c = 1;
        bschList.add(bSch8);
        system.debug('bSch8:--'+bSch8);
        
        Billing_Schedule__c bSch9 = new Billing_Schedule__c();
       // bSch9.Charges_Type__c = QchargeTypes[1].ID;
        bSch9.Charges_Type__c =  chargeMap.get('License Fee Yearly').Id;
        bSch9.Head_Of_Terms__c = h.Id;
        bSch9.start_date__c = h.Licence_Commencement_Date__c.addMonths(1);
        bSch9.End_date__c = h.Licence_Commencement_Date__c.addMonths(13);
        bSch9.Rate__c = 0;
        bSch9.Amount__c = 0;
        bSch9.Number_of_Months__c = 12;
        bschList.add(bSch9);
        system.debug('bSch9:--'+bSch9);
        
        Billing_Schedule__c bSch10 = new Billing_Schedule__c();
        bSch10.Charges_Type__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_HOUSING).Id;        
        bSch10.Head_Of_Terms__c = h.Id;
        bSch10.start_date__c = h.Licence_Commencement_Date__c;
        bSch10.End_date__c = h.Licence_Commencement_Date__c.addMonths(12);
        bSch10.Rate__c = 100;
        bSch10.Amount__c = 500000;
        bSch10.Number_of_Months__c = 12;
        bschList.add(bSch10);
        system.debug('bSch10:--'+bSch10);
        
        insert bschList;
        system.debug('bschList:'+bschList.size());
    }
    
    public static String createBill(String h, String opp){
        Map<String,Charges_Type__c> chargeMap = createChargeTypes();
        List<Billing__c> billList = new List<Billing__c>();
        Billing__c bill = new Billing__c();
        bill.Charge__c = chargeMap.get(ElbConstantsClass.CHARGE_TYPES_LICENSE_FEE).Id;
        bill.Head_Of_Terms__c = h;
        bill.Billing_Start_Date__c = Date.newInstance(2021, 12, 1);
        bill.Billing_End_Date__c = Date.newInstance(2021, 12, 31);
        bill.Amount__c = 500000;
        bill.Opportunity__c = opp;
        bill.Approval_Status__c = 'Not Submitted';
        bill.Remarks__c = 'calculated a 5000000';
        bill.Narration__c = 'Test Narration for License fee';
        billList.add(bill);        
        insert billList;
        return bill.Id;
    }
    
    public static void createStandardTermClauses(){
        //Term Items
        Id cRecType =  Schema.SObjectType.Term_Item__c.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.RECORD_TYPE_STANDARD_CLAUSES).getRecordTypeId();
        Head_Of_Terms__c dummyHOT  = new Head_Of_Terms__c();
        insert dummyHOT;
        List<Term_Item__c> termList = new List<Term_Item__c>();      
        Term_Item__c  licenceTerm =new Term_Item__c();
        licenceTerm.Category__c = 'Commercial';
        licenceTerm.Sequence__c = 109;
        licenceTerm.Header__c = ElbConstantsClass.MONTHLY_COMP_FEE;
        licenceTerm.Value__c = 'Up to {M1} Car Parks will be allotted for the exclusive use of the Licensee.The compensation of {M2} car parks shall be included in the  Monthly Compensation.Balance {M3} number of car parking will be charged at additional cost as per prevailing charges in Godrej Business District. No separate Two-Wheeler Parking are available but the same can be provisioned in the allotted Car Parking bays.';
        licenceTerm.Merge_Field_1__c = 'Total_Number_Of_carparks_1__c';
        licenceTerm.Merge_Field_2__c='Number_of_carparks_included_in_the__c';
        licenceTerm.Merge_Field_3__c='Number_of_chargeable_carparks__c';
        licenceTerm.RecordTypeId = cRecType;
        licenceTerm.Head_Of_Terms__c = dummyHOT.id;
        termList.add(licenceTerm);

        //Term Items
        Term_Item__c  agreementTypeTerm =new Term_Item__c();
        agreementTypeTerm.Category__c = 'Commercial';
        agreementTypeTerm.Sequence__c = 110;
        agreementTypeTerm.Header__c = ElbConstantsClass.OFFERED_FLOOR_AREA;
        agreementTypeTerm.Value__c='check for Lessor,check for Lessee,check for Lease,check for Rent';
        agreementTypeTerm.REcordTypeId = cRecType;
        agreementTypeTerm.Head_Of_Terms__c = dummyHOT.id;
        termList.add(agreementTypeTerm);

        //Term Items
        Term_Item__c  lockinTerm =new Term_Item__c();
        lockinTerm.Category__c = 'Commercial';
        lockinTerm.Sequence__c = 110;
        lockinTerm.Header__c = 'Lockin Period';
        lockinTerm.Value__c='{M1}';
        lockinTerm.Merge_Field_1__c = 'Leasing_Term__c';
        lockinTerm.REcordTypeId = cRecType;
        lockinTerm.Head_Of_Terms__c = dummyHOT.id;
        termList.add(lockinTerm);

        //Term Items
        Term_Item__c  secTerm =new Term_Item__c();
        secTerm.Category__c = 'Commercial';
        secTerm.Sequence__c = 110;
        secTerm.Header__c = 'Security Deposit';
        secTerm.Value__c='{M1} {M2}';
        secTerm.Merge_Field_1__c = 'Security_Deposit_Calculation_Type__c';
        secTerm.Merge_Field_2__c = ElbConstantsClass.SEC_DEPOSIT;
        secTerm.REcordTypeId = cRecType;
        secTerm.Head_Of_Terms__c = dummyHOT.id;
        termList.add(secTerm);

        insert termList;

    }
    
    public static String createCase(){
        //String caseRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.CASE_RECORD_TYPE_LEASING).getRecordTypeId();
        Case cs = new Case();
        cs.Location__c = 'Mumabi';
        Id accId = createAccount();
        Id cId = createContact(accId);
        cs.Date__c = date.today();
        cs.Client_Request__c = 'N';
        cs.Type = 'IT Park';
        cs.Leasing_Case_Category__c ='Elevator';
        cs.Sub_Category__c = 'MAN TRAPPED IN LIFT';
        cs.Job_assigned_to__c = userInfo.getUserId();
        cs.Representative__c = 'Ajay B';
        cs.Agency__c = 'CBRE';
        cs.AccountId = accId;
        cs.Workman__c ='complex';
        cs.Job_to_be_performed__c = 'stetig consulting';
        cs.Job_Executed__c ='the person wokring on case';
        cs.Material_Used_if_any__c ='Hard material';
        cs.Customer_Assessment_Feedback__c ='Good';
        cs.Level_of_Satisfaction__c = '3 - Good';
       
        insert cs;
        return cs.Id;
    }
    
    /**
     * create Site visit with feedback
     */
    public void createSiteVisit(){

    }
}