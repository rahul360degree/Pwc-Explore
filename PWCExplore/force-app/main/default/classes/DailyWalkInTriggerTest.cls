/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-08-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-08-2023   Varun Rajpoot   Initial Version
**/
@isTest
public with sharing class DailyWalkInTriggerTest {
    @isTest static void dailyWalkInTest(){

        Profile userProfile = [Select Id from Profile where Name = 'Interio Script HO Category Managers' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                            timezonesidkey = 'Asia/Kolkata', email = 'testInt.user@godrej.com', username = 'testInt.user@godrej.com',
                            Business_Unit__c = GlobalConstants.INTERIO_BUSINESS_UNIT,
                            Sub_Division__c = GlobalConstants.B2C_SUBDIVISION
                            );
        insert userToRun;

        // Create Account.
        System.runAs(userToRun) {
            Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
            rChar.B2C_character__c = 'A';
            rChar.B2B_Account_Series_Char__c = 'X';
            rChar.B2B_character__c = 'AA';
            insert rChar;
            Account accountRecord = new Account(LastName='Test Account', PersonMobilePhone='7902112113', Business_Unit__c = 'W', Branch_Code__c = 'P');
            accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Customer');
            insert accountRecord;
            

            Daily_Walk_Ins__c obj = new Daily_Walk_Ins__c();
            obj.No_Of_Walk_Ins__c  = 10;
            obj.Account__c = accountRecord.Id;
            obj.Date_of_Captured__c = Date.today();
            obj.Conversion__c = 5;
            obj.OB__c = 0;
            insert obj;
        }
    }



}