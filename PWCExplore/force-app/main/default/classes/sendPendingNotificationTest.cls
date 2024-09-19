/*
Written by  : Sreekanth Jujare
On		    : 26/06/2022
Description : Sends a Email Notification of all Pending Tasks to the Internal Sales Representative 
Batch Class	: sendPendingNotification 
*/

@isTest
public class sendPendingNotificationTest {
    @testSetup
    public static void pendingTasksEmailTest(){
        //UserRole r = new UserRole(DeveloperName = 'MyCustomRole',Name = 'My Role');
        //insert r;
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', 
                                  username = 'test.user@godrej.com');       /*, UserRoleId = r.Id);*/
        insert userToRun;
        
        
    }
    public static TestMethod void sendEmail(){
      User u = [SELECT id, email FROM User WHERE LastName = 'User' LIMIT 1];
        Test.startTest();
          Id RecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = RecTypeId;
        insert acc;
        Task tsk = new Task();
        tsk.Subject = 'Testing Batch Email';
        tsk.CSG_Activity__c = 'Tender - Pre Qualification Doc';
        tsk.Sub_Activity__c = 'Lead Generation';
        tsk.Status='Pending';
        tsk.Internal_Sales_Rep__c=u.id;
        tsk.Email_of_Int_Sal_Rep__c='test@godrej.com';
        tsk.Start_Date__c=DateTime.newInstance(2022, 6, 24, 12, 00, 00);
        tsk.Customer_Name__c = acc.id;
        tsk.ActivityDate = Date.newInstance(2022, 6, 25);
       
        insert tsk;
		sendPendingNotification b = new sendPendingNotification();
		database.executeBatch(b);
        Test.stopTest();
    }
}