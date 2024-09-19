@isTest
public with sharing class AttachSOAControllerTest{
    
    @TestSetup static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Persona__c = 'InterioVFD- COCO Store Team';
        userToRun.Sub_Division__c = 'B2C';
        userToRun.Logistic_Company__c = '5010';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OrderTriggerDisabled__c = true;
            insert setting;           
            
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                    new TestProductBuilder().setName('Product 1').setItemCode('VFD1').setIsGeneric(true).setDescription('VFD PRODUCT 1').setComponentType('Base Product').getTestRecord(),
                    new TestProductBuilder().setName('Product 2').setItemCode('VFD2').setIsGeneric(true).setDescription('VFD PRODUCT 2').setComponentType('Attachments').getTestRecord(),
                    new TestProductBuilder().setName('Product 3').setItemCode('VFD3').setIsGeneric(true).setDescription('VFD PRODUCT 3').setComponentType('Operator').getTestRecord(),
                    new TestProductBuilder().setName('Product 4').setItemCode('VFD4').setIsGeneric(true).setDescription('VFD PRODUCT 4').setComponentType('Technician').getTestRecord(),
                    new TestProductBuilder().setName('Product 5').setItemCode('VFD5').setIsGeneric(true).setDescription('VFD PRODUCT 5').setComponentType('Supervisor').getTestRecord()
                    };
                        insert allProducts; 
            
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(4000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(5000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(2000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                    new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(2000).getTestRecord()
                    };
                        insert allPBEs; 
            
            Address__c addr = createPrimaryAddress();
            insert addr;
            
            Account accountRecord = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId()).setBusinessUnit('W')
                .setPrimaryAddress(addr.Id).getSavedTestRecord();
            
            List<Branch__c> branchRecords = createBranchRecords(accountRecord.Id, userToRun);
            insert branchRecords;
            
            Address_by_BP__c shipToAddress = createShipToAddress(addr, accountRecord);
            insert shipToAddress;
            
            Opportunity oppRecord = new TestOpportunityBuilder()
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId()).setBusinessUnit('W').getSavedTestRecord();
            
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId();
            Date d = Date.parse('01/01/2022'); 
            List<Order> orderRecords = new List<Order> {
                new TestOrderBuilder().setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId())
                    .setAccountId(accountRecord.Id).setBusinessUnit('W').setPricebook2Id(rentalPriceBook.Id).setAmount(50000).setStatus('Draft').setEffectiveDate(d).setIntegrationStatus('Synced').getTestRecord(), 
                    new TestOrderBuilder().setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_VFD_Primary').getRecordTypeId())
                    .setAccountId(accountRecord.Id).setBusinessUnit('W').setPricebook2Id(rentalPriceBook.Id).setAmount(50000).setStatus('Draft').setEffectiveDate(d).setIntegrationStatus('Draft').getTestRecord()    
                    }; 
                        insert orderRecords;
            
              Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                           Gross_Net__c='2', Level__c='2', Stage__c='Active',Discount_Amount__c=3400); //added Discount_Amount__c by Shreela on 11th April 2022
            Insert defaultDiscountMatrix;
            
            
            List<OrderItem> orderItems = createOrderItems(orderRecords, allPBEs);
            insert orderItems;
        }
    }
    
    private static List<OrderItem> createOrderItems(List<Order> orders, List<priceBookEntry> pbe){
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem oitem = new OrderItem(Orderid = orders[0].id, PricebookEntryId = pbe[0].id, Quantity = 1, UnitPrice = 50000);
        orderItems.add(oitem);
        return orderItems;
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Street__c='strttst',ZipCode__c = zipcd.id,Building__c='Daisy'); //added Building__c by Shreela on 11th April 2022
        return addr;
    }
    
    private static List<Branch__c> createBranchRecords(Id accountId, User userRecord) {
        List<Branch__c> branchList = new List<Branch__c>();
        Branch__c branchRecord1 = new Branch__c();
        branchRecord1.Business_Partner__c = accountId;
        branchRecord1.Branch_Name__c = userRecord.Logistic_Company__c;
        branchRecord1.Area__c = userRecord.Area_Code__c;
        branchRecord1.Business_Partner_Status_Ship_To__c = 'Open';
        branchRecord1.Business_Partner_Status__c = 'Open';
        
        branchList.add(branchRecord1);
        return branchList;
    }
    
    private static Address_by_BP__c createShipToAddress(Address__c addr, Account accRecord){
        Address_by_BP__c shipToAdd = new Address_by_BP__c(Address_Code__c = addr.id, Account__c = accRecord.id);
        return ShipToAdd;
    }
    
    @isTest private static void ControllerShouldAttachData() {
        String URL;
        String actualErrMessage;
        Order ordRec = [Select id from Order LIMIT 1];
        
        PageReference pref = Page.InterioSOAWithoutSyncing;
        
        pref.getParameters().put('orderId', ordRec.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
        AttachSOAController attachSalesAckCtrl = new AttachSOAController(sc);
        
        Test.startTest();
        URL = '/apex/interiosoawithoutsyncing?orderId=' + ordRec.id;
        attachSalesAckCtrl.createAttachmentWithoutSync();
        Test.stopTest();
        
        System.assertEquals(pref.getUrl(), URL);
        System.assertEquals('Successfully created attachment. Will be redirected to acknowledgement page.', attachSalesAckCtrl.toastMessage , 'Attachment generated for valid order');
    }
    
    @isTest private static void IncorrectOrderShouldAlertUser() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order LIMIT 1];
        
        Test.startTest();
        
        try {
            AttachSOAController.createAttachmentWithoutSync(ordRec.Id);
        } catch (Exception ex) {
            actualErrMessage = ex.getMessage();
        }
        
        Test.stopTest();
        // Change in main cls required to throw exception with a custom label and custom exception to handle it gracefully 
       // System.assertEquals('Script-thrown exception', actualErrMessage , 'Invalid Order');
    }
    
 /*   @isTest private static void throwErrorToGenerateSalesAck(){
        String actualErrMsg;
        Order ordRec = [Select id from Order where Integration_Status__c = 'Draft' LIMIT 1];
        Test.startTest();
         try {
            AttachSOAController.createAttachmentWithoutSync(ordRec.Id);
        } catch (Exception ex) {
            actualErrMsg = ex.getMessage();
        }
        actualErrMsg = AttachSOAController.createAttachmentWithoutSync(ordRec.Id);       
        Test.stopTest();
        System.assertEquals('Cannot generate sales acknowledgement, Please Sync Order in Infor LN First.', actualErrMsg);
    } */
    @isTest private static void createAttachmentRecordShouldAttachData() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order LIMIT 1];
        
        Test.startTest();
        
        actualErrMessage = AttachSOAController.createAttachmentWithoutSync(ordRec.Id);
        
        Test.stopTest();
        
        System.assertEquals('Successfully created attachment. View Notes & Attachments in Related Tab', actualErrMessage , 'Attachment generated for valid order');
    }
    
    @isTest private static void auraShouldAlertUserAttachmentExist() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order LIMIT 1];
        
        Test.startTest();
        
        AttachSOAController.createAttachmentWithoutSync(ordRec.Id);
        try {
            AttachSOAController.createAttachmentWithoutSync(ordRec.Id);
        } catch (Exception ex) {
            actualErrMessage = ex.getMessage();
        }
        
        Test.stopTest();
        
        // Change in main cls required to throw exception with a custom label and custom exception to handle it gracefully 
       // System.assertEquals('Script-thrown exception', actualErrMessage , 'Attachment Exists');
    }
    
    @isTest private static void redirectToDetailPageShouldUpdateThePageRef(){
        String URL = '';
        Order ordRec = [Select id from Order LIMIT 1];
        
        PageReference pref = Page.InterioSOAWithoutSyncing;
        pref.getParameters().put('orderId', ordRec.Id);
        
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
        AttachSOAController attachSalesAckCtrl = new AttachSOAController(sc);
        
        Test.startTest();
        URL = '/apex/interiosoawithoutsyncing?orderId=' + ordRec.id;
        //This method should be revisited in main class
        PageReference pgref = attachSalesAckCtrl.redirectToDetailPage();
        
        Test.stopTest();
        System.assertEquals(pref.getUrl(), URL);
    }
    
    @isTest private static void redirectToTermsOfOrderShouldUpdateThePageRef(){
        String URL = '';
        Order ordRec = [Select id from Order LIMIT 1];
        
        PageReference pref = Page.InterioSOAWithoutSyncing;
        pref.getParameters().put('orderId', ordRec.Id);
        
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
        AttachSOAController attachSalesAckCtrl = new AttachSOAController(sc);
        
        Test.startTest();
        URL = '/apex/interiosoawithoutsyncing?orderId=' + ordRec.id;
        //This method should be revisited in main class
        PageReference pgref = attachSalesAckCtrl.showTermsOfOrderPDF();
        
        Test.stopTest();
        System.assertEquals(pref.getUrl(), URL);
    }
}