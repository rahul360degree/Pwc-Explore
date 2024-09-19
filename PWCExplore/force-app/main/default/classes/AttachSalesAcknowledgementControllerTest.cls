@isTest
public with sharing class AttachSalesAcknowledgementControllerTest{
    
    @TestSetup static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) {
            //added by Shreela on 11th April 2022
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.OrderTriggerDisabled__c = true;
            insert setting;
            //ended by Shreela on 11th April 2022
            
            PriceBook2 standardPriceBook = new PriceBook2(Id = Test.getStandardPricebookId(), LN_PriceList_Code__c = 'ST', PriceList_Code__c = 'ST');
            update standardPriceBook;
            
            PriceBook2 rentalPriceBook = new PriceBook2(Name = System.Label.MHE_SF_Local_Rental_PB, IsActive = true, LN_PriceList_Code__c = 'REN', PriceList_Code__c = 'REN');
            insert rentalPriceBook;
            
            List<Product2> allProducts = new List<Product2> {
                new TestProductBuilder().setName('GX 300').setDescription('GX 300 Forklift').setItemCode('GX1').setComponentType('Base Product').getTestRecord(),
                new TestProductBuilder().setName('GX 300 Attachment').setItemCode('GX2').setDescription('GX 300 Forklift Attachment').setComponentType('Attachments').getTestRecord(),
                new TestProductBuilder().setName('Operator - Delhi').setItemCode('GX3').setDescription('Operator').setComponentType('Operator').getTestRecord(),
                new TestProductBuilder().setName('Technician - Delhi').setItemCode('GX4').setDescription('Technician').setComponentType('Technician').getTestRecord(),
                new TestProductBuilder().setName('Supervisor - Delhi').setItemCode('GX5').setDescription('Supervisor').setComponentType('Supervisor').getTestRecord()
                    };
            insert allProducts;
    
            List<PriceBookEntry> allPBEs = new List<PriceBookEntry> {
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[0].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(50000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[1].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(3000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[2].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(30000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[3].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord(),
                new TestPriceBookEntryBuilder().setProduct2Id(allProducts[4].Id).setPricebook2Id(rentalPriceBook.Id).setUnitPrice(32000).getTestRecord()
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
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2B').getRecordTypeId()).setBusinessUnit('W').getSavedTestRecord();
           
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Kitchen').getRecordTypeId();
            Date d = Date.parse('01/01/2022'); //added by Shreela on 11th April 2022
            List<Order> orderRecords = new List<Order> {
                new TestOrderBuilder().setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Kitchen').getRecordTypeId())
                    .setAccountId(accountRecord.Id).setBusinessUnit('W').setPricebook2Id(rentalPriceBook.Id).setAmount(50000).setStatus('Draft').setEffectiveDate(d).getTestRecord(), 
                new TestOrderBuilder().setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Kitchen').getRecordTypeId())
                    .setAccountId(accountRecord.Id).setBusinessUnit('W').setPricebook2Id(rentalPriceBook.Id).setAmount(50000).setStatus('Draft').setEffectiveDate(d).setIntegrationStatus(GlobalConstants.INTEGRATION_STATUS_SYNCED).getTestRecord()    
            };  //added setEffectiveDate() method by Shreela on 11th April 2022
            insert orderRecords;
            
            	
            
            Discount_Matrix__c defaultDiscountMatrix=new Discount_Matrix__c(Name='No Discount',Discount_Code__c='HDH',
                                                                            Start_Date__c=System.Today(),End_Date__c=System.Today(),
                                                                           Gross_Net__c='1', Level__c='2', Stage__c='Active',Discount_Amount__c=3400); //added Discount_Amount__c by Shreela on 11th April 2022
            Insert defaultDiscountMatrix;
            
            List<OrderItem> orderItems = createOrderItems(orderRecords, allPBEs);
            insert orderItems;
            
            List<Advance_Payment_Details__c> advPaymentRecords = createAdvPaymentRecords(orderRecords);
            insert advPaymentRecords; 
        }
    }
    
    private static List<OrderItem> createOrderItems(List<Order> orders, List<priceBookEntry> pbe){
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem oitem = new OrderItem(Orderid = orders[0].id, PricebookEntryId = pbe[0].id, Quantity = 1, UnitPrice = 50000);
        orderItems.add(oitem);
        return orderItems;
    }
    
     private static List<Advance_Payment_Details__c> createAdvPaymentRecords(List<Order> orderRecords) {
        List<Advance_Payment_Details__c> advPaymentDetails = new List<Advance_Payment_Details__c>();
        Integer i=1;
        for(Order orderRecord : orderRecords) {
            Advance_Payment_Details__c apd = new Advance_Payment_Details__c();
            apd.Amount__c = Decimal.valueOf(500*i);
            apd.Payment_Date__c = Date.today();
            
            //commented by Shreela for resolving Test class issue (No SRF/OTRS Raised for this)
            /*apd.Payment_Mode__c = i == 1 ? 'Cash' : i/2 == 0 ? 'Card' : 'Cheque';
              apd.Bank_Name__c = apd.Payment_Mode__c != 'Cash' ? 'ABC' : '';
              apd.Reference_Number__c = apd.Payment_Mode__c != 'Cash' ? 'REF-'+String.valueOf(i) : ''; */
            //commented by Shreela for resolving Test class issue (No SRF/OTRS Raised for this)
            
            //added by Shreela for resolving Test class issue (No SRF/OTRS Raised for this)
            apd.Payment_Mode__c = 'EMI';            
            apd.Bank_Name__c = 'ABC';            
            apd.Reference_Number__c = 'EMI';
            apd.Mode_of_Advance_Payment__c = 'Cash'; 
            apd.Bank_Provider_Name__c = 'ALLAHABAD BANK';
            //ended by Shreela for resolving Test class issue (No SRF/OTRS Raised for this)
            apd.Order__c = orderRecord.Id;
            advPaymentDetails.add(apd);
            i+=1;
        }
        return advPaymentDetails;
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
    
    @isTest private static void IncorrectOrderCtrlShouldAlertUser() {
        System.debug('dm'+[Select Id from Discount_Matrix__c Where Name='No Discount']);
        String URL;
        String actualErrMessage;
        Test.startTest();
        Order ordRec = [Select id from Order WHERE Integration_Status__c !=: GlobalConstants.INTEGRATION_STATUS_SYNCED LIMIT 1];
       
        PageReference pref = Page.InterioSalesAcknowledgement;
        
        pref.getParameters().put('orderId', ordRec.id);
        Test.setCurrentPage(pref);
            
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
		AttachSalesAcknowledgementController attachSalesAckCtrl = new AttachSalesAcknowledgementController(sc);
            
        
        URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;

        attachSalesAckCtrl.createAttachmentRecord();
        
        Test.stopTest();
            
        System.assertEquals(pref.getUrl(), URL);
        System.assertEquals('Cannot generate sales acknowledgement as order has not been synced to Infor yet', attachSalesAckCtrl.toastMessage , 'Order with this record type cannot be processed');
      }
    
       @isTest private static void ControllerShouldAttachSalesData() {
        String URL;
        String actualErrMessage;
        Order ordRec = [Select id from Order WHERE Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        PageReference pref = Page.InterioSalesAcknowledgement;
            
        pref.getParameters().put('orderId', ordRec.id);
        Test.setCurrentPage(pref);
            
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
		AttachSalesAcknowledgementController attachSalesAckCtrl = new AttachSalesAcknowledgementController(sc);
            
        Test.startTest();
        URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;

        attachSalesAckCtrl.createAttachmentRecord();
        
        Test.stopTest();
            
        System.assertEquals(pref.getUrl(), URL);
        System.assertEquals('Successfully created attachment. Will be redirected to acknowledgement page.', attachSalesAckCtrl.toastMessage , 'Attachment generated for valid order');
     }
    
  /*  @isTest private static void controllerShouldAlertUserAttachmentExists() {
        String URL;
        String actualErrMessage;
        Order ordRec = [Select id from Order WHERE Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        PageReference pref = Page.InterioSalesAcknowledgement;
            
        pref.getParameters().put('orderId', ordRec.id);
        Test.setCurrentPage(pref);
            
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
		AttachSalesAcknowledgementController attachSalesAckCtrl = new AttachSalesAcknowledgementController(sc);
            
        Test.startTest();
        URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;

        attachSalesAckCtrl.createAttachmentRecord();
        attachSalesAckCtrl.createAttachmentRecord();
        
        Test.stopTest();
            
        System.assertEquals(pref.getUrl(), URL);
        System.assertEquals('Cannot generate sales acknowledgement more than once.', attachSalesAckCtrl.toastMessage , 'Attachment generated for valid order');
     } */ //This method is commented by SREEKANTH JUJARE AS THIS CONDITION IS NEGLECTED ON MAIN CLASS
    
    @isTest private static void IncorrectOrderAuraShouldAlertUser() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order WHERE Integration_Status__c !=: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        Test.startTest();
        
        try {
            AttachSalesAcknowledgementController.createAttachmentRecord(ordRec.Id);
        } catch (Exception ex) {
            actualErrMessage = ex.getMessage();
        }
        
        Test.stopTest();
        // Change in main cls required to throw exception with a custom label and custom exception to handle it gracefully 
        System.assertEquals('Script-thrown exception', actualErrMessage , 'Invalid Order');
     }
    
     @isTest private static void createAttachmentRecordShouldAttachSalesData() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order WHERE Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        Test.startTest();
        
        actualErrMessage = AttachSalesAcknowledgementController.createAttachmentRecord(ordRec.Id);
        
        Test.stopTest();
         
        System.assertEquals('Successfully created attachment. View Notes & Attachments in Related Tab', actualErrMessage , 'Attachment generated for valid order');
     }
    
/*    @isTest private static void auraShouldAlertUserAttachmentExists() {
        String actualErrMessage; 
        Order ordRec = [Select id from Order WHERE Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        Test.startTest();
        
        AttachSalesAcknowledgementController.createAttachmentRecord(ordRec.Id);
        try {
            AttachSalesAcknowledgementController.createAttachmentRecord(ordRec.Id);
        } catch (Exception ex) {
            actualErrMessage = ex.getMessage();
        }
        
        Test.stopTest();
         
        // Change in main cls required to throw exception with a custom label and custom exception to handle it gracefully 
        System.assertEquals('Script-thrown exception', actualErrMessage , 'Attachment Exists');
     } */ //This method is commented by SREEKANTH JUJARE AS THIS CONDITION IS NEGLECTED ON MAIN CLASS
    
    @isTest private static void redirectToDetailPageShouldUpdatePageRef(){
        String URL = '';
 		Order ordRec = [Select id from Order WHERE Integration_Status__c =: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        PageReference pref = Page.InterioSalesAcknowledgement;
        pref.getParameters().put('orderId', ordRec.Id);
        
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
		AttachSalesAcknowledgementController attachSalesAckCtrl = new AttachSalesAcknowledgementController(sc);
            
        Test.startTest();
        URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;
    	//This method should be revisited in main class
        PageReference pgref = attachSalesAckCtrl.redirectToDetailPage();
        
        Test.stopTest();
        System.assertEquals(pref.getUrl(), URL);
    }
    
    @isTest private static void redirectToTermsOfOrderShouldUpdatePageRef(){
        String URL = '';
 		Order ordRec = [Select id from Order WHERE Integration_Status__c !=: GlobalConstants.INTEGRATION_STATUS_SYNCED];
        
        PageReference pref = Page.InterioSalesAcknowledgement;
        pref.getParameters().put('orderId', ordRec.Id);
        
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ordRec);    
		AttachSalesAcknowledgementController attachSalesAckCtrl = new AttachSalesAcknowledgementController(sc);
            
        Test.startTest();
        URL = '/apex/interiosalesacknowledgement?orderId=' + ordRec.id;
    	//This method should be revisited in main class
        PageReference pgref = attachSalesAckCtrl.showTermsOfOrderPDF();
        
        Test.stopTest();
        System.assertEquals(pref.getUrl(), URL);
    }
}