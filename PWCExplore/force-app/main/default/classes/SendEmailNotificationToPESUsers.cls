public class SendEmailNotificationToPESUsers {
    @InvocableMethod(label='Send Email' description='Sends an email to multiple recipients')
    public static void sendEmailNotifcation(List<EmailParameter> emailParameters) {
        try{   
            OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM];
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();        
            for (EmailParameter parameter : emailParameters) {
                List<String> toAddressList=parameter.emailAddresses.split(',');
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddressList);
                email.setSubject(parameter.emailSubject);
                email.setHtmlBody(parameter.emailBody);
                email.setOrgWideEmailAddressId(owea.id);
                emailList.add(email);
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
        public String emailAddresses;
        
        @InvocableVariable(required=true)
        public String emailSubject;
        
        @InvocableVariable(required=true)
        public String emailBody;
    }

}