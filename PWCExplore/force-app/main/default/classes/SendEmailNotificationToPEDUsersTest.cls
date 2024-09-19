/**
* @description       : SendEmailNotificationToPEDUsersTest
* @author            : jadhavr@godrej.com
* @group             : 
* @last modified on  : 10-10-2023
* @last modified by  : jadhavr@godrej.com
**/
@IsTest
public class SendEmailNotificationToPEDUsersTest {
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
            List<SendEmailNotificationToPEDUsers.EmailParameter> emailParameterList=new List<SendEmailNotificationToPEDUsers.EmailParameter>();
            SendEmailNotificationToPEDUsers.EmailParameter emailParameter=new SendEmailNotificationToPEDUsers.EmailParameter();
            List<String> emailAddressList=new List<String>(); 
            emailAddressList.add('test@godrej.com');
            emailAddressList.add('test2@godrej.com');
            emailParameter.toAddresses=emailAddressList;
            emailParameter.emailBody='Test Body';
            emailParameter.emailSubject='Test Subject';
            emailParameterList.add(emailParameter);
            
            SendEmailNotificationToPEDUsers.sendEmailNotifcation(emailParameterList);
            SendEmailNotificationToPEDUsers.sendEmailNotifcation(null);
        }
    }
}