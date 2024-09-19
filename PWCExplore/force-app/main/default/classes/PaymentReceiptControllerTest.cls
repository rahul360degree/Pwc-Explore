@isTest
public with sharing class PaymentReceiptControllerTest {
    @TestSetup static void createData(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.userPRC@godrej.com', username = 'test.userPRC@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);
        
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;
        
        System.runAs(userToRun) { 
            Address__c addr = createPrimaryAddress();
            insert addr;
            
            Account accountRecord = new TestAccountBuilder()
                .setName('TEST ACC')
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
                .getSavedTestRecord();
            accountRecord.Primary_Address__c = addr.id;
            accountRecord.Business_Unit__c = 'K';
            update accountRecord;
            
            List<Order> orderRecords = createOrderRecords(3, accountRecord);
            insert orderRecords;
            
            List<Advance_Payment_Details__c> advPaymentRecords = createAdvPaymentRecords(orderRecords);
            insert advPaymentRecords; 
            
            User userWithRole = new User(UserRoleId = UserInfo.getUserRoleId(), ProfileId = UserInfo.getProfileId(), Account__c = accountRecord.id, 
                                         Alias = 'hasrole', Email='userwithrole@godrej.com',
                                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                         TimeZoneSidKey='America/Los_Angeles',Username = 'test12345_gnbtest@godrej.com',CommunityNickname = 'test12345'); 
            insert UserWithRole;
        }
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
            apd.Amount__c = Decimal.valueOf(500*i);
            apd.Payment_Date__c = Date.today();
            apd.Payment_Mode__c = i == 1 ? 'Others' : i/2 == 0 ? 'EMI' : 'EMI';
            apd.Transaction_Type__c = '328';
            apd.Type_of_Transaction__c = 'Advance Receipt';
            apd.Mode_of_Advance_Payment__c = i == 1 ? 'Cash' : i/2 == 0 ? 'Card' : 'Cheque';
            apd.Bank_Provider_Name__c = apd.Payment_Mode__c != 'Others' ? 'Axis Bank' : '';
            apd.Reference_Number__c = apd.Mode_of_Advance_Payment__c != 'Others' ? 'REF-'+String.valueOf(i) : '';
            apd.Order__c = orderRecord.Id;
            advPaymentDetails.add(apd);
            i+=1;
        }
        return advPaymentDetails;
    }
    
    private static Address__c createPrimaryAddress(){
        ZipCode__c zipcd = new ZipCode__c(City_Name__c ='citytst', StateName__c = 'sttetst', name='zpcdtst');
        insert zipcd;
        Address__c addr = new Address__c(Name__c = 'TEST ACC', Street__c='strttst',ZipCode__c = zipcd.id);
        return addr;
    }
    
    @isTest private static void PaymentReceiptControllerShouldProcessOrderandPayment() {
        
        Advance_Payment_Details__c paymentRecord = [Select Id, Order__c from Advance_Payment_Details__c Limit 1];
        User usr = [Select id, Account__c from User WHERE username =: 'test12345_gnbtest@godrej.com'];
        
        System.runAs(usr){
        PageReference pref = Page.PaymentReceipt;
        pref.getParameters().put('orderId', paymentRecord.Order__c);
        pref.getParameters().put('paymentId', paymentRecord.Id);
        Test.setCurrentPage(pref);
                        PaymentReceiptController prc = new PaymentReceiptController();
        
        system.debug('tst'+usr.Account__c);
        String URL;
        Test.startTest();
                                    URL = '/apex/paymentreceipt?orderId=' + paymentRecord.Order__c + '&paymentId=' + paymentRecord.Id;
        Test.stopTest();
             System.assertEquals(pref.getUrl(), URL); 
         }
    }
    
    @isTest private static void PaymentReceiptControllerShouldProcessOrderNoPayment() {
        
        Advance_Payment_Details__c paymentRecord = [Select Id, Order__c from Advance_Payment_Details__c Limit 1];
        User usr = [Select id, Account__c from User WHERE username =: 'test12345_gnbtest@godrej.com'];
        
        System.runAs(usr){
        PageReference pref = Page.PaymentReceipt;
        pref.getParameters().put('orderId', paymentRecord.Order__c);
        pref.getParameters().put('paymentId', null);
        Test.setCurrentPage(pref);
                        PaymentReceiptController prc = new PaymentReceiptController();
        
        system.debug('tst'+usr.Account__c);
        String URL;
        Test.startTest();
                                    URL = '/apex/paymentreceipt?orderId=' + paymentRecord.Order__c;
        Test.stopTest();
             System.assertEquals(pref.getUrl(), URL); 
         }
    }
    
}