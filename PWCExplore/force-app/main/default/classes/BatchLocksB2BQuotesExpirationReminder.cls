////******************************************************************************************************
/**
* @Author            : Ashwin Thale
* @class name  : BatchLocksB2BQuotesExpirationReminder.apxc
* @description  : This Batch Apex Class is used for Email Notification to the Users. It takes quote records that are 
//going to be expire with in next 30 days from current day and it send the list of those records to the User and his Manager through Mail.
* @created date  : 31-10-2023
* @last modified on  : 31-10-2023
* @last modified by  : Ashwin Thale
* Modifications Log	 :
* Ver   Date         Author          Modification
* 1.0   31-10-2023   Ashwin Thale   Initial Version
**/
////******************************************************************************************************
public class BatchLocksB2BQuotesExpirationReminder implements Database.Batchable<sObject>, System.Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        String strSubDivision = GlobalConstants.B2B_SUBDIVISION;
        String strBusinessUnit = GlobalConstants.Locks_BUSINESS_UNIT;
        String userQuery = 'SELECT Id, LastName, Email, FirstName, ManagerId, Manager.Email, Name, Business_Unit__c, Sub_Division__c FROM User ';
        userQuery += 'Where Business_Unit__c = :strBusinessUnit AND Sub_Division__c = :strSubDivision AND IsActive = TRUE';
        return Database.getQueryLocator(userQuery);
    }

    public void execute(Database.BatchableContext context, List<User> listUser) {
        try {
            List<Quote> listQuote = getQuoteList(listUser);
            Map<Id, List<Quote>> mapUserIdQuotes = mapUserAndQuotes(listQuote);
            EmailTemplate objEmailTemp = getEmailTemp();
            OrgWideEmailAddress objOrgWideEmailAddress = getOrgWideEmailAddress();
			List<Messaging.SingleEmailMessage> emailList = emailTemplate(listUser,mapUserIdQuotes,objEmailTemp,objOrgWideEmailAddress);
            Messaging.sendEmail(emailList);
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'execute', '', ex);
        }
    }

    public void finish(Database.BatchableContext context) {
    }
    
    //This method is used to get the Quote Records that will expire after one month from current day.
    public List<Quote> getQuoteList(List<User> listUser) {
        try {
            List<Quote> listQuote = [SELECT Id, Name, RecordType.Name, Owner.Name, OpportunityId, QuoteNumber, Opportunity.Name, Account.Name, 
                Agreed_by_customer__c, Owner.Email, AccountId, ExpirationDate, Status FROM Quote 
                WHERE RecordType.DeveloperName = :GlobalConstants.RECORDTYPE_Locks_B2B AND Agreed_by_customer__c = TRUE 
                AND ExpirationDate >= :System.today() AND ExpirationDate <= :System.today().addDays(30) AND OwnerId IN :listUser];
    		return listQuote;
        } catch (Exception ex) {
        	System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'getLstQuote', '', ex);
            return null;
        }
    }
    
    //This method is used to create Map of User where each User will contain multiple Quotes as a List.
    public Map<Id, List<Quote>> mapUserAndQuotes(List<Quote> listQuote) {
        try {
            Map<Id, List<Quote>> mapUserIdQuotes = new  Map<Id, List<Quote>>();
            for (Quote objQuote : listQuote) {
                    if (!mapUserIdQuotes.containsKey(objQuote.OwnerId)) {
                        mapUserIdQuotes.put(objQuote.OwnerId, new List<Quote>());
                    }
                    mapUserIdQuotes.get(objQuote.OwnerId).add(objQuote);
                }
        return mapUserIdQuotes;
        } catch (Exception ex) {
        	System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'mapUserAndQuotes', '', ex);
            return null;
        }
    }

    //This method is used to get Email Template.
    public EmailTemplate getEmailTemp() {
        try {
            EmailTemplate objEmailTemplate = [SELECT Id, Name, OwnerId, Subject, Body, DeveloperName, HtmlValue 
            FROM EmailTemplate WHERE DeveloperName = :GlobalConstants.Locks_B2B_Weekly_Quotes_Expiration_Template];
        return objEmailTemplate;
        } catch (Exception ex) {
        	System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'getEmailTemp', '', ex);
            return null;
        }
    }
    
    //This method is used to get OrgWideEmailAddress Email.
    public OrgWideEmailAddress getOrgWideEmailAddress() {
        try {
            OrgWideEmailAddress objOrgWideEmailAddress = [SELECT Id, IsVerified, Address, DisplayName, IsAllowAllProfiles, Purpose 
            FROM OrgWideEmailAddress WHERE DisplayName = :GlobalConstants.OrgWideEmailAddressDisplayName];
        return objOrgWideEmailAddress;
        } catch (Exception ex) {
        	System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'getOrgWideEmailAddress', '', ex);
            return null;
        }
    }
    
    //This method is used to create Email Template.
    public List<Messaging.SingleEmailMessage> emailTemplate(List<User> listUser, Map<Id, List<Quote>> mapUserIdQuotes, EmailTemplate objEmailTemp, OrgWideEmailAddress objOrgWideEmailAddress) {
        try {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            for (User objUser : listUser) {
                List<Quote> userQuotes = mapUserIdQuotes.get(objUser.Id);
                if(userQuotes != null && !userQuotes.isEmpty()) {
            		email.setTemplateId(objEmailTemp.Id);
                    email.setOrgWideEmailAddressId(objOrgWideEmailAddress.Id);
                    email.setToAddresses(new String[] { objUser.Id });
                    if(String.isNotBlank(objUser.ManagerId)){
                    	email.setCcAddresses(new String[] { objUser.ManagerId });
                    }
                    email.setSubject(objEmailTemp.Subject);
                    email.setHtmlBody(buildEmailBody(userQuotes,objEmailTemp.HtmlValue));
                    emailList.add(email);
                }
            }
            return emailList;
        } catch (Exception ex) {
        	System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'emailTemplate', '', ex);
            return null;
        }
    }
    
    //This method is used to built Email Body for Multiple Quotes by Iteration.
    public static String buildEmailBody(List<Quote> quotes, String htmlBody) {
        try {
            String emailBody = '';
            emailBody += '<table border="1"><tr><th>Quote Number</th><th>Quote Name</th><th>Opportunity Name</th><th>Account Name<th>Expiry Date</th><th>Days to Expire</th></tr>';
            for (Quote quote : quotes){
                emailBody += '<tr>';
                emailBody += '<td><center>' + quote.QuoteNumber + '</center></td>';
                emailBody += '<td><center>' + quote.Name + '</center></td>';
                emailBody += '<td><center>' + quote.Opportunity.Name + '</center></td>';
                emailBody += '<td><center>' + quote.Account.Name + '</center></td>';
                emailBody += '<td><center>' + quote.ExpirationDate.day() + '/' + quote.ExpirationDate.month() + '/' + quote.ExpirationDate.year() + '</center></td>';
                emailBody += '<td><center>' + System.Today().daysBetween(quote.ExpirationDate) + '</center></td>';
                emailBody += '</tr>';
            }
            emailBody += '</table>';
            htmlBody = htmlBody.replaceFirst('DATA_TABLE',emailBody);
            return htmlBody;
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'buildEmailBody', '', ex);
            return null;
        }
    }
    
    //This method is used to Schedule the Batch Class with Batch Size 10.
    public void execute(SchedulableContext ctx) {
        try {
            BatchLocksB2BQuotesExpirationReminder bct = new BatchLocksB2BQuotesExpirationReminder();
        	database.executebatch(bct,10);
        }
        catch (Exception ex) {
            System.debug('Error: '+ex.getStackTraceString());
            Logger.logError('BatchLocksB2BQuotesExpirationReminder', 'execute', '', ex);
        }
    }
}