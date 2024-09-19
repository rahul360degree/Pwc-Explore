/**
* @description       : SendEmailNotificationToPESUsersTest
* @author            : jadhavr@godrej.com
* @group             : 
* @last modified on  : 25-05-2023
* @last modified by  : jadhavr@godrej.com
**/
@IsTest
public class SendEmailNotificationToPESUsersTest {
    @IsTest
    static void testSendEmailNotificationToPESUsers() {
    Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User runningAdminUser =new TestUserBuilder()
            .setProfileId(profile.Id)
            .setLastName('Admin User')
            .getTestRecord();        
        runningAdminUser.IsActive = true;
        insert runningAdminUser;
        
        System.runAs(runningAdminUser)
        {     
            List<SendEmailNotificationToPESUsers.EmailParameter> emailParameterList=new List<SendEmailNotificationToPESUsers.EmailParameter>();
            SendEmailNotificationToPESUsers.EmailParameter emailParameter=new SendEmailNotificationToPESUsers.EmailParameter();
            emailParameter.emailAddresses='test@godrej.com,test2@godrej.com';
            emailParameter.emailBody='Test Body';
            emailParameter.emailSubject='Test Subject';
            emailParameterList.add(emailParameter);
            
            SendEmailNotificationToPESUsers.sendEmailNotifcation(emailParameterList);
            SendEmailNotificationToPESUsers.sendEmailNotifcation(null);
        }
    }
}