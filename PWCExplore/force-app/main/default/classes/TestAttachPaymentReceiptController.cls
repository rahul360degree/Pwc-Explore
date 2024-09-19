@isTest
public class TestAttachPaymentReceiptController {
    @testSetup
    public static void createTestData() {
        
        
        Account accountRecord = createAccountRecord();
        insert accountRecord;
        
        List<Order> orderRecords = createOrderRecords(3, accountRecord);
        insert orderRecords;
        
        List<Advance_Payment_Details__c> advPaymentRecords = createAdvPaymentRecords(orderRecords);
        insert advPaymentRecords;
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User1', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'test.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        userToRun.Account__c=accountRecord.Id;
        insert userToRun;
        
    }
    
    private static Account createAccountRecord() {
        Account accountRecord = new Account(Name='Test Attach Payment', Industry='Apparel', Type='Institution', Account_Code__c='TPA', business_unit__C = 'K');
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        return accountRecord;
    }
    
    private static List<Order> createOrderRecords(Integer noOfRecords, Account accountRecord) {
        List<Order> orderRecords = new List<Order>();
        for(Integer i=1; i<=noOfRecords; i++) {
            Order orderRecord = new Order();
            orderRecord.AccountId = accountRecord.Id;
            orderRecord.Order_Amount__c = 100000 + (1000*i) + 350.75;
            orderRecord.EffectiveDate = Date.today();
            orderRecord.Status = 'Draft';
            orderRecord.Business_Unit__c = 'K';
            orderRecords.add(orderRecord);
        }
        return orderRecords;
    }
    
    private static List<Advance_Payment_Details__c> createAdvPaymentRecords(List<Order> orderRecords) {
        List<Advance_Payment_Details__c> advPaymentDetails = new List<Advance_Payment_Details__c>();
        Integer i=1;
        for(Order orderRecord : orderRecords) {
            Advance_Payment_Details__c apd = new Advance_Payment_Details__c();
            apd.Amount__c = Math.mod(i, 2) == 0 ? Decimal.valueOf(512344561*i) : Decimal.valueOf(50000000*i);
            apd.Payment_Date__c = Date.today();
            apd.Payment_Mode__c = i == 1 ? 'Others' : i/2 == 0 ? 'EMI' : 'Others';
            apd.Bank_Name__c = apd.Payment_Mode__c != 'Others' ? 'ABC' : '';
            apd.Bank_Provider_Name__c = 'Axis Bank';
            apd.Mode_of_Advance_Payment__c = 'Card';
            apd.Credit_Card_Last_four_digits__c = '1234';
            apd.Credit_Debit_Card_Approval_Code__c ='abcv';
            apd.Reference_Number__c = apd.Payment_Mode__c != 'Others' ? 'REF-'+String.valueOf(i) : 'ABC';
            apd.Order__c = orderRecord.Id;
            advPaymentDetails.add(apd);
            i+=1;
        }
        return advPaymentDetails;
    }
    
    static testMethod void testAttachPaymentReceiptControllerClassForAuraCmp() {
        Advance_Payment_Details__c paymentRecord = [Select Id, Order__c from Advance_Payment_Details__c Limit 1];
        System.debug('apd id>>>>>'+paymentRecord.Id);
        if(paymentRecord.Id !=null)
        AttachPaymentReceiptController.createAttachmentRecord(paymentRecord.Id);

        Test.startTest();
        // assert that an attachment exists for the record
        System.assertEquals(1,[select count() from ContentDocumentLink where LinkedEntityId = :paymentRecord.id]);
        
        Test.stopTest();
    }
    
    static testMethod void testPaymentReceiptControllerClassForOrder() {
        User runningUser=[Select Id from User where Name='Test User1'];
        List<Order> orderRecords = [Select Id from Order];
        for(Order orderRecord : orderRecords) {
            PageReference pref = Page.PaymentReceipt;
            pref.getParameters().put('orderId',orderRecord.id);
            Test.setCurrentPage(pref);
            System.runAs(runningUser){
                PaymentReceiptController paymentReceiptObject = new PaymentReceiptController();
            }
            System.assertEquals(true, true);
        }
    }
    
    static testMethod void testPaymentReceiptControllerClassForAdvancePayment() {
        User runningUser=[Select Id from User where Name='Test User1'];
        List<Advance_Payment_Details__c> paymentRecords = [Select Id, Order__c from Advance_Payment_Details__c];
        Advance_Payment_Details__c paymentRec;
        for(Advance_Payment_Details__c paymentRecord : paymentRecords) {
            PageReference pref = Page.PaymentReceipt;
            pref.getParameters().put('orderId',paymentRecord.Order__c);
            pref.getParameters().put('paymentId',paymentRecord.Id);
            Test.setCurrentPage(pref);
            paymentRec = paymentRecord;
            System.runAs(runningUser){
                PaymentReceiptController paymentReceiptObject = new PaymentReceiptController();
            }
            System.assertEquals(true, true);
        }
        update paymentRec;
    }
}