/**
* @description       : Used For PED Division to send email to multiple receipents, this class is getting called from multiple flow's.
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
public class SendEmailNotificationToPEDUsers {
    @InvocableMethod(label='Send Email' description='Sends an email to multiple recipients')
    public static void sendEmailNotifcation(List<EmailParameter> emailParameters) {
        try{   
            OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();        
            for (EmailParameter parameter : emailParameters) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(parameter.toAddresses);//emailAddresses
                email.setCcAddresses(parameter.ccAddresses);
                email.setSubject(parameter.emailSubject);
                email.setHtmlBody(parameter.emailBody);
                email.setOrgWideEmailAddressId(owea.id);
                emailList.add(email);
                system.debug(email);
            }
            if(!emailList.isEmpty()) {                 
                Messaging.sendEmail(emailList);                        
            }
        }
        catch (Exception ex) {
            Logger.logError('SendEmailNotificationToPESUsers', 'sendEmailNotifcation', '', ex);
        }        
    }

    public class EmailParameter {
        @InvocableVariable(required=true)
        public List<String> toAddresses;	//emailAddresses
        
        @InvocableVariable(required=true)
        public String emailSubject;
        
        @InvocableVariable(required=true)
        public String emailBody;
        
        @InvocableVariable
        public List<String> ccAddresses;
    }
}