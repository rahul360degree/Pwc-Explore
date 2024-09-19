/**
 * @description       : To send renewal notification of HoT record whose license date is within mentioned number of month 
 * @author            : shreela@godrej.com,vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-10-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public class HoTExpiryNotificationBatch implements Database.Batchable<SObject>, Schedulable  {
    public Database.QueryLocator start(Database.BatchableContext Bc){
        // Fetch the month from the config
        HoT_Notification_Setting__mdt config = [Select Id,Email_Address__c,Number_of_Month__c from HoT_Notification_Setting__mdt where DeveloperName='Default'];
        Integer months = Integer.valueOf(config.Number_of_Month__c);
        Date today = Date.today();
        Date endDate = today.addMonths(+months);
        //Query String
        String query = 'Select id,Name,Approval_Status__c,OwnerId,Licence_End_Date__c,Location__c,Owner.Email,Opportunity__r.Owner.Email,'+
            '(Select Id,Floor__r.Asset_Code__c from Rental_Units__r)'+
            ' from HEAD_OF_TERMS__c '+
            ' Where '+
            'Lease_Abstract__c = true and (Licence_End_Date__c>=:today and Licence_End_Date__c<=:endDate)';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext Bc, List<SObject> scope){
        //send email
        HoTExpiryNotificationHelper obj = new HoTExpiryNotificationHelper();
        obj.sendNotificationEmail(scope);
    }
    public void finish(Database.BatchableContext Bc){
        
    }
    
    //To schedule jobs of renewal notification on weekly basis
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(new HoTExpiryNotificationBatch());
    }
}