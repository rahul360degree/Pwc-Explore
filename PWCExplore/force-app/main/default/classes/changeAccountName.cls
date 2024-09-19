/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class fpr LWC component to change account Name of an account is already tagged over opportunity
Related:       NA
Last Modified: 22/11/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class changeAccountName {
    public changeAccountName() {

    }

    //fetch NIX Child Accounts
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String actName){
        List<Account> accountList = new List<Account>();
        if(actName!=''){
            String accountName = '%' + actName + '%';
            String accountSeries = ElbConstantsClass.ACCOUNT_SERIES_CHILD;
            accountList = [select Id, Name, ParentId, toLabel(Business_Unit__c), PAN__c, toLabel(Type), Account_Series__c, Account_Code__c, Primary_Contact__c
                            from Account 
                            where Name like:accountName AND Account_Series__c =: accountSeries AND Account_Code__c != null LIMIT 100];
            return accountList;  
        }
        return accountList;        
    }

    //fetch contact
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(String accountId){
        List<Contact> contactList = new List<Contact>();
            contactList = [select Id, Name, AccountId
                            from Contact 
                            where AccountId =: accountId LIMIT 1000];
        return contactList;        
    }
    
    //fetch Opportunity details 
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunityData(string oppId) {
        List<Opportunity> oppList = new List<Opportunity>();

        oppList = [select Id, Name, AccountId
                            from Opportunity 
                            where Id =: oppId LIMIT 10];
        return oppList;
    }

    //update the new account over opportunity
    @AuraEnabled
    public static void updateAccountName(string oppId, string accountId, string reasonForChange, string accountIdOld, string contactId) { 
        List<Opportunity> oppList = new List<Opportunity>();
        List<HEAD_OF_TERMS__c> hotList = new List<HEAD_OF_TERMS__c>();
        
        List<Opportunity> oppObject = new List<Opportunity>();
        List<HEAD_OF_TERMS__c> hotObject = new List<HEAD_OF_TERMS__c>();

        Datetime now  = system.now();
        String nowFormat = now.format();

        oppList = [select Id, Name, AccountId
                            from Opportunity 
                            where Id =: oppId LIMIT 10];

        hotList = [select Id, Name, Licence_End_Date__c, Opportunity__c
                        from HEAD_OF_TERMS__c 
                        where Opportunity__c =: oppId LIMIT 50];

        String accountNameOld = [select Id, Name
                                 from Account 
                                 where Id =: accountIdOld].Name;

        String accountNameNew = [select Id, Name
                                 from Account 
                                 where Id =: accountId].Name;
        if(!oppList.isEmpty()){
            for(Opportunity opp: oppList){
                opp.AccountId = accountId;
                opp.Reason_for_Account_Name_change__c = reasonForChange;
                opp.Original_Account__c = accountIdOld;
                opp.Primary_contact__c = contactId;
                opp.Account_Name_Change_Date__c = now;
                oppObject.add(opp);
            }

            for(HEAD_OF_TERMS__c hot: hotList){
                hot.Account_Name_Change_Comments__c = 'Name for the Account over this Opportunity has been change from ' + accountNameOld + ' to ' + accountNameNew + ' on ' + nowFormat + ' for ' + reasonForChange;
                hotObject.add(hot);
            }

            try {
                update oppObject;
                update hotObject;
            } catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
        }
    }
}