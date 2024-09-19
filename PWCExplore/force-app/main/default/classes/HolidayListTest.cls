/*
Written by  : Sreekanth Jujare
On		    : 17/06/2022
Description : Returns Scheduled End Date on Task (Interio BMR) by summation of Start Date and SLA Excluding Holiday List 
*/


@isTest
public class HolidayListTest {
    //@testSetup
    /*public static void setScheduledEndDateTest(){
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', 
                                  username = 'test.user@godrej.com');
        insert userToRun;
    }
    */
    //Creating Task records with different Start date and Sub activity values
    @isTest
    private static void testm1(){
        //Inserting data to create a Task Record 
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'BOQ';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=DateTime.newInstance(2023, 6, 24, 12, 00, 00);
        tsks.CSG_Activity__c='Quotation';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        List<Task> newList = new List<Task>();
        newList.add(tsks);
        HolidayList.setScheduledEndDate(newList);
        system.debug('tsks.Start_Date__c:'+tsks.Start_Date__c);
        system.debug('tsks.Scheduled_End_Date__c:'+tsks.Scheduled_End_Date__c);
        system.assertEquals(DateTime.newInstance(2023, 6, 28, 12, 00, 00),tsks.Scheduled_End_Date__c);//gcp22
        //system.assertEquals('Quotation',tsks.CSG_Activity__c);
        test.stopTest();
        
    }
    /*@isTest
    private static void testm2(){
        //List<HolidayList__c> lstHolidays = [select name,Holidays__c from HolidayList__c where name='Day2'];
        //String userId = UserInfo.getUserId();
        Task tsks1 = new Task();
        tsks1.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks1.Sub_Activity__c = 'Standard Quote + Specification';
        //tsks1.OwnerId = userId;
        tsks1.Subject = 'Hello World';
        tsks1.Status = 'On hold';
        tsks1.Priority = 'Normal';
        tsks1.Start_Date__c=DateTime.newInstance(2022, 6, 24, 12, 00, 00);
        tsks1.CSG_Activity__c='Quotation';
        tsks1.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks1;
        test.stopTest();
        system.assertEquals('Quotation',tsks1.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm3(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'BOQ Large + Layout Counting';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Quotation';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Quotation',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm4(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Tender Support Documents';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Tender - Pre Qualification Doc';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('test@salesforce.com',tsks.Email_of_Int_Sal_Rep__c);//gcp22
    }
    @isTest
    private static void testm5(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'OB – NS1/ NS2 (COTS Registration for DSSH)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Order Booking';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('test@salesforce.com',tsks.Email_of_Int_Sal_Rep__c);//gcp22
    }
    @isTest
    private static void testm6(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Advance Payment (No Documents)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('test@salesforce.com',tsks.Email_of_Int_Sal_Rep__c);//gcp22
    }
    @isTest
    private static void testm7(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'OB – NS3/NS4 (COTS Registration for DSSH)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Order Booking';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Order Booking',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm8(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.Sub_Activity__c = 'Payment on Delivery';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Payments Follow up',tsks.CSG_Activity__c);//gcp22 
    }
    @isTest
    private static void testm9(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'APO (NS3, NS4 Complexity)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Quotation';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Quotation',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm10(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Payment before Dispatch';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Payments Follow up',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm11(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'OB - NS3 (OPOS/LAB) (OTIF+COTS)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Order Booking';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Order Booking',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm12(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Docket Submission (Invoice/POD/PO/CC)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Financial Documents';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Financial Documents',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm13(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'OB - NS4 (OPOS/LAB) (OTIF+COTS)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Order Booking';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Order Booking',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm14(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Payment on Delivery (30 Days Credit Period)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Payments Follow up',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm15(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Payment on Delivery (45 days Credit Period)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Payments Follow up',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm16(){
        //String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = 'Payment on Delivery (60 Days Credit Period)';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='Payments Follow up';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('Payments Follow up',tsks.CSG_Activity__c);//gcp22
    }
    @isTest
    private static void testm17(){
        ///String userId = UserInfo.getUserId();
        Task tsks = new Task();
        tsks.RecordTypeId = Globalconstants.Interio_BMR_RECORDTYPE;
        tsks.Sub_Activity__c = '';
        //tsks.OwnerId = userId;
        tsks.Subject = 'Hello World';
        tsks.Status = 'On hold';
        tsks.Priority = 'Normal';
        tsks.Start_Date__c=system.now()+1;
        tsks.CSG_Activity__c='';
        tsks.Email_of_Int_Sal_Rep__c='test@salesforce.com';
        test.startTest();
        insert tsks;
        test.stopTest();
        system.assertEquals('',tsks.CSG_Activity__c);//gcp22
    } 
        
  */ 
}