/**
* @description: To send Task Due reminders to Internal Sales Rep
* @author: Sreekanth Jujare
**/


@isTest
public class BankGuaranteeEmailBatchTest {
    @isTest
    static void testBatchExecution() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a user
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userToRun = new User(
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Email = 'test.user@godrej.com',
            Username = 'test.user@godrej.com'
        );
        insert userToRun;

        // Create a task
        Task testTask = new Task(
            Subject = 'Test Task',
            ActivityDate = Date.today().addDays(1), // Task due tomorrow
            CSG_Activity__c = 'Financial Documents',
            Sub_Activity__c = 'Bank Guarantee (ABG/PBG/Retention BG)',
            Customer_Name__c = testAccount.Id,
            Internal_Sales_Rep__c = userToRun.Id,
            Email_of_Int_Sal_Rep__c = 'testuser@example.com',
            Start_Date__c = Date.today(),
            Scheduled_End_Date__c = Date.today().addDays(1),
            PO_NO_Reference__c = 'Test PO',
            Estimated_Price__c = 100.00
        );
        insert testTask;
        
        Test.startTest();
        BankGuaranteeEmailBatch batch = new BankGuaranteeEmailBatch();
        String sch = '0 0 0 * * ?'; 
        system.schedule('BankGuaranteeEmails', sch, batch);
        Test.stopTest();

    }
}