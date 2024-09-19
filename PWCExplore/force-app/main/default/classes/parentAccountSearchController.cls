/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class to create a Lead using global lightning action
Related:       Global action Button(Create Leasing Lead)
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/

public with sharing class parentAccountSearchController {
    public parentAccountSearchController() {

    }
    
    public static map < String, Id > fetchRecordTypes(String ObjApiName) {
        map < String, Id > rtMap = new map < String, Id > (); 
        for (RecordType rt: [select Id, Name, DeveloperName from RecordType where sObjectType =: ObjApiName]) {
            rtMap.put(rt.Name, rt.Id);
        }
        return rtMap;
    }

    @AuraEnabled(cacheable=true)
    public static String getLeadRecordTypeId(){
        String leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.LEAD_LEASING_B2B_DEV).getRecordTypeId();
        return leadRecordTypeId;
    }

    //fetch contact details of searched child account
    @AuraEnabled(cacheable=true)
    public static List<Contact> fetchContactDetails(String contactId){
        List<Contact> contacttList = new List<Contact>();
        if(contactId != ' '){
            contacttList = [select Id, Name, Firstname, Lastname, Email, MobilePhone, AccountId 
                            from Contact 
                            where Id =: contactId 
                            LIMIT 1000];
        }
        return contacttList;        
    }




    //fetch IPC account details
    @AuraEnabled(cacheable=true)
    public static List<Account> getIpcAccounts(String actName){
        List<Account> accountList = new List<Account>();
            String accountName = '%' + actName + '%';
            String accountCode = ElbConstantsClass.ACCOUNT_CODE_IPC + '%';
			String accType = ElbConstantsClass.ACCOUNT_TYPE_VENDOR;
            String accSeries = ElbConstantsClass.ACCOUNT_CODE_IPC;
            accountList = [select Id, Name, ParentId, RecordTypeId, Account_Code__c, Account_Series__c, Type 
                            from Account 
                            where Type =: accType AND Account_Series__c =: accSeries and Name like: accountName LIMIT 50];
        return accountList;     
    }

    //fetch IPC Contact details
    @AuraEnabled(cacheable=true)
    public static List<Contact> fetchContactIpc(String accountId){
        List<Contact> contacttList = new List<Contact>();
        if(accountId != null){
            contacttList = [select Id, Name, Firstname, Lastname, Email, MobilePhone, AccountId 
                            from Contact 
                            where AccountId =: accountId 
                            LIMIT 1000];
        }
        return contacttList;       
    }

    //fetch contact details of searched child account
    @AuraEnabled
    public static List<Contact> getContacts(String childAcountId){
        List<Contact> contacttList = new List<Contact>();
        if(childAcountId != null){

            contacttList = [select Id, Name, Firstname, Lastname, Email, MobilePhone, AccountId 
                            from Contact 
                            where AccountId =: childAcountId 
                            LIMIT 1000];
        }
        return contacttList;        
    }

    //fetch Child account details
    @AuraEnabled(cacheable=true)
    public static List<Account> fetchChildAccountId(Id accountId){
        List<Account> childAccountList = new List<Account>();
        if(accountId != null){
            String businessUnit = 'N'; //construction BU
            childAccountList = [select Id, Name, Primary_Contact__c, Primary_Contact__r.Name, Primary_Contact__r.MobilePhone, Primary_Contact__r.Email, ParentId, Business_Unit__c, Account_Series__c
                                from Account 
                                where ParentId !=: null and ParentId =: accountId and Business_Unit__c =: businessUnit LIMIT 1000];
            return childAccountList;  
        }
        return childAccountList;        
    }


    
    //Ipc Contact Wrapper
    public class IpcContactWrapper{
        @AuraEnabled
        public String updatedAccountIdIpc{get;set;}
        @AuraEnabled
        public String updatedContactNameIpc{get;set;}
        @AuraEnabled
        public String updatedContactMobileIpc{get;set;}
        @AuraEnabled
        public String updatedContactEmailIpc{get;set;}
    }
    
    //Add record of new IPC contact 
    @AuraEnabled
    public static List<Contact> createNewContactIpcRecord(IpcContactWrapper contactFieldDetails) {

        List<Contact> contactObject = new List<Contact>();
        Contact contactLineItem = new Contact();
        contactLineItem.Lastname  = contactFieldDetails.updatedContactNameIpc;
        contactLineItem.AccountId = contactFieldDetails.updatedAccountIdIpc;
        contactLineItem.MobilePhone = contactFieldDetails.updatedContactMobileIpc;
        contactLineItem.Phone = contactFieldDetails.updatedContactMobileIpc;
        contactLineItem.Email = contactFieldDetails.updatedContactEmailIpc;

        //Default Values being set
        contactObject.add(contactLineItem);
        try{
            insert contactObject;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        return contactObject;
    }

    public class LeadObjectWrapper{
        @AuraEnabled
        public String updatedParentAccountId{get;set;}
        @AuraEnabled
        public String updatedParentAccountName{get;set;}

        @AuraEnabled
        public String addedAccountName{get;set;}
        
        @AuraEnabled
        public Id updatedAccountId{get;set;}
        @AuraEnabled
        public String updatedAccountName{get;set;}

        @AuraEnabled
        public String updatedLocation{get;set;}
        @AuraEnabled
        public Integer updatedSpaceRequired{get;set;}

        @AuraEnabled
        public String updatedContactOld{get;set;}
        @AuraEnabled
        public String updatedName{get;set;}
        @AuraEnabled
        public String updatedFirstName{get;set;}
        @AuraEnabled
        public String updatedLastName{get;set;}
        @AuraEnabled
        public String updatedMobileNumber{get;set;}
        @AuraEnabled
        public String updatedEmail{get;set;}
        @AuraEnabled
        public String updatedDescription{get;set;}

        @AuraEnabled
        public String updatedLeadSource{get;set;}

        @AuraEnabled
        public String updatedAccountIpc{get;set;}
        @AuraEnabled
        public String updatedContactValueIpc{get;set;}
        @AuraEnabled
        public String updatedContactIdIpc{get;set;}
        @AuraEnabled
        public String updatedContactNameIpc{get;set;}
    }

    @AuraEnabled
    public static ResponseWrapper createNewLeadRecord(LeadObjectWrapper leadFieldDetails) {
        Map < String, Id > recordTypes = new Map < String, Id > ();
        List<Lead> leadObject = new List<Lead>();
        Lead leadLineItem = new Lead();

        recordTypes = fetchRecordTypes(ElbConstantsClass.LEAD_API);

        if(leadFieldDetails.updatedContactOld != null && leadFieldDetails.updatedContactIdIpc != null ){
            //Adding Lead Field Details

            System.debug('Inside If');
            if(leadFieldDetails.updatedParentAccountName != null){
                leadLineItem.Firstname  = leadFieldDetails.updatedParentAccountName;
            }
            else{
                leadLineItem.Firstname  = leadFieldDetails.addedAccountName;
            }

            if(leadFieldDetails.updatedContactIdIpc != null){
                List<Contact> ipccontactList = [Select Id, Name from Contact where Id =: leadFieldDetails.updatedContactIdIpc Limit 1];

                leadLineItem.Lastname  =  ' - ' + ipccontactList[0].Name;  
            }
            
            leadLineItem.Account__c = leadFieldDetails.updatedAccountId;

            if(leadFieldDetails.updatedParentAccountName != null){
                leadLineItem.Company__c  = leadFieldDetails.updatedParentAccountName;
            }
            else{
                leadLineItem.Company__c = leadFieldDetails.addedAccountName;
            }

            if(leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER') {
                leadLineItem.source_contact__c = leadFieldDetails.updatedContactOld;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.Phone = leadFieldDetails.updatedMobileNumber;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.MobilePhone = leadFieldDetails.updatedMobileNumber;
            }     

            if(leadFieldDetails.updatedEmail != null && leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER'){  
                leadLineItem.Email = leadFieldDetails.updatedEmail;
            }

            leadLineItem.Lead_Source__c = leadFieldDetails.updatedLeadSource;

            if(leadFieldDetails.updatedAccountIpc != null){
                leadLineItem.IPC__c = leadFieldDetails.updatedAccountIpc;
            }

            if(leadFieldDetails.updatedContactIdIpc != null){
                leadLineItem.IPC_Contact__c = leadFieldDetails.updatedContactIdIpc;
            }
        }
        else if(leadFieldDetails.updatedContactOld != null && leadFieldDetails.updatedContactIdIpc == null ){
            //Adding Lead Field Details

            System.debug('Inside Else If');
            if(leadFieldDetails.updatedParentAccountName != null){
                leadLineItem.Firstname  = leadFieldDetails.updatedParentAccountName;
            }
            else{
                leadLineItem.Firstname  = leadFieldDetails.addedAccountName;
            }

            if(leadFieldDetails.updatedContactIdIpc != null){
                List<Contact> ipccontactList = [Select Id, Name from Contact where Id =: leadFieldDetails.updatedContactIdIpc Limit 1];

                leadLineItem.Lastname  =  ' - ' + ipccontactList[0].Name;  
            }

            if(leadFieldDetails.updatedContactOld != null){
                List<Contact> contactList = [Select Id, Name from Contact where Id =: leadFieldDetails.updatedContactOld Limit 1];
                leadLineItem.Lastname  =  ' - ' + contactList[0].Name; 
            }
            
            leadLineItem.Account__c = leadFieldDetails.updatedAccountId;

            /*
            if(leadFieldDetails.updatedAccountId != null){
                //List<Account> accList = [Select Id, Name, Sub_Division__c, Business_Unit__c from Account where Id =: leadFieldDetails.updatedAccountId Limit 1];
                
            }
*/

            if(leadFieldDetails.updatedParentAccountName != null){
                leadLineItem.Company__c  = leadFieldDetails.updatedParentAccountName;
            }
            else{
                leadLineItem.Company__c = leadFieldDetails.addedAccountName;
            }

            if(leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER') {
                leadLineItem.source_contact__c = leadFieldDetails.updatedContactOld;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.Phone = leadFieldDetails.updatedMobileNumber;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.MobilePhone = leadFieldDetails.updatedMobileNumber;
            }     

            if(leadFieldDetails.updatedEmail != null && leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER'){  
                leadLineItem.Email = leadFieldDetails.updatedEmail;
            }

            leadLineItem.Lead_Source__c = leadFieldDetails.updatedLeadSource;

            if(leadFieldDetails.updatedAccountIpc != null){
                leadLineItem.IPC__c = leadFieldDetails.updatedAccountIpc;
            }

            if(leadFieldDetails.updatedContactIdIpc != null){
                leadLineItem.IPC_Contact__c = leadFieldDetails.updatedContactIdIpc;
            }
        }
        else {
            //Adding Lead Field Details

            System.debug('Inside Else');
            List<Contact> contactObject = new List<Contact>();
            Contact contactLineItem = new Contact();

            if(leadFieldDetails.updatedName != null){
                contactLineItem.Firstname  = (leadFieldDetails.updatedName).substring(0, (leadFieldDetails.updatedName).indexOf(' '));
                contactLineItem.Lastname  = (leadFieldDetails.updatedName).substring((leadFieldDetails.updatedName).indexOf(' ')+1);
            }
            if(leadFieldDetails.updatedAccountId != null){
                contactLineItem.AccountId = leadFieldDetails.updatedAccountId;
            }
            if(leadFieldDetails.updatedMobileNumber != null){
                contactLineItem.MobilePhone = leadFieldDetails.updatedMobileNumber;
            }
            if(leadFieldDetails.updatedMobileNumber != null){
                contactLineItem.Phone = leadFieldDetails.updatedMobileNumber;
            }
            if(leadFieldDetails.updatedEmail != null){
                contactLineItem.Email = leadFieldDetails.updatedEmail;
            }      
            
            contactObject.add(contactLineItem);
            
            try{
                insert contactObject; 
            } catch(DmlException e) {
                System.debug('The following exception has occurred while inserting contactObject: ' + e.getMessage());
            } 

            if(leadFieldDetails.updatedName != null){
                if(leadFieldDetails.updatedParentAccountName != null){
                    leadLineItem.Firstname  = leadFieldDetails.updatedParentAccountName;
                }
                else{
                    leadLineItem.Firstname  = leadFieldDetails.addedAccountName;
                }

                leadLineItem.Lastname  =  ' - ' + leadFieldDetails.updatedName; 
            }

            if (leadFieldDetails.updatedName == null && leadFieldDetails.updatedContactNameIpc != null) {
                if(leadFieldDetails.updatedParentAccountName != null){
                    leadLineItem.Firstname  = leadFieldDetails.updatedParentAccountName;
                }
                else{
                    leadLineItem.Firstname  = leadFieldDetails.addedAccountName;
                }
                
                leadLineItem.Lastname  =  ' - ' + leadFieldDetails.updatedContactNameIpc;
            }

            if(leadFieldDetails.updatedAccountId != null){
                leadLineItem.Account__c = leadFieldDetails.updatedAccountId;
                List<Account> acc = [Select Id, Name, Firstname, Lastname from Account where Id =: leadFieldDetails.updatedAccountId LIMIT 1];
                if(acc.size() > 0){
                    //leadLineItem.Firstname  = (acc[0].Name).substring(0, (acc[0].Name).indexOf(' '));
                    //leadLineItem.Lastname  = ' - ' + (acc[0].Name).substring((acc[0].Name).indexOf(' ')+1);
                    leadLineItem.Company__c =  acc[0].Name;   
                }
            }
            else{
                if(leadFieldDetails.updatedParentAccountName != null){
                    leadLineItem.Company__c  = leadFieldDetails.updatedParentAccountName;
                }
                else{
                    leadLineItem.Company__c = leadFieldDetails.addedAccountName;
                }
            }
            /*
            if(leadFieldDetails.updatedParentAccountName == 'UNDISCLOSED CUSTOMER') {
                if(leadFieldDetails.updatedParentAccountName != null){
                    leadLineItem.Lastname  = leadFieldDetails.updatedParentAccountName;
                }
                else{
                    leadLineItem.Lastname  = leadFieldDetails.addedAccountName;
                }
            }
            */
            if(leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER') {
                leadLineItem.source_contact__c = contactObject[0].Id;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.Phone = leadFieldDetails.updatedMobileNumber;
            }

            if(leadFieldDetails.updatedMobileNumber != null){
                leadLineItem.MobilePhone = leadFieldDetails.updatedMobileNumber;
            }
            
            if(leadFieldDetails.updatedParentAccountName == 'UNDISCLOSED CUSTOMER') {
                List<Contact> ipccontact = [Select Id, Name, Firstname, Lastname, MobilePhone from Contact where Id =: leadFieldDetails.updatedContactIdIpc LIMIT 1];
                leadLineItem.MobilePhone = ipccontact[0].MobilePhone;
                leadLineItem.Firstname  = leadFieldDetails.updatedParentAccountName; 
                leadLineItem.Lastname  = ' - ' + ipccontact[0].Name;
            }
            

            if(leadFieldDetails.updatedEmail != null && leadFieldDetails.updatedParentAccountName != 'UNDISCLOSED CUSTOMER'){  
                leadLineItem.Email = leadFieldDetails.updatedEmail;
            }

            leadLineItem.Lead_Source__c = leadFieldDetails.updatedLeadSource;

            if(leadFieldDetails.updatedAccountIpc != null){
                leadLineItem.IPC__c = leadFieldDetails.updatedAccountIpc;
            }

            if(leadFieldDetails.updatedContactIdIpc != null){
                leadLineItem.IPC_Contact__c = leadFieldDetails.updatedContactIdIpc;
            }
            
            if(leadFieldDetails.updatedParentAccountName == 'UNDISCLOSED CUSTOMER') {
                List<Contact> ipcContactList = [select Id, Name from Contact where Id=: leadFieldDetails.updatedContactIdIpc LIMIT 1];
            	leadLineItem.Company__c  = leadFieldDetails.updatedParentAccountName + ' - ' + ipcContactList[0].Name;
            }
        }

        leadLineItem.Customer_Type__c = 'Institutional';
        leadLineItem.Business_Unit__c = 'N';
        leadLineItem.Segment__c = 'Others';
        leadLineItem.Sector_If_others__c = 'Others'; 
        leadLineItem.Sub_Division__c = 'B2B';
        
        leadLineItem.Location__c = leadFieldDetails.updatedLocation;
        leadLineItem.Initial_Space_needed__c = leadFieldDetails.updatedSpaceRequired;
        leadLineItem.Description = leadFieldDetails.updatedDescription;
        leadLineItem.RecordTypeId  = recordTypes.get(ElbConstantsClass.RECORD_TYPES_B2B_LEASING_LEAD);
        leadObject.add(leadLineItem);

        ResponseWrapper rw = new ResponseWrapper();
        try {
            insert leadObject;
            rw.success = true;
            rw.recId = leadObject[0].Id;
            rw.message = 'Lead ' + leadObject[0].LastName + ' has been created';
            return rw;

        } catch (Exception ex) {
            rw.success = false;
            rw.recId = null;
            rw.message = 'Error in creating lead:' +  ex.getMessage();
            return rw;
        }
    }
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean success {get; set;}
        @AuraEnabled
        public String recId {get; set;}
        @AuraEnabled
        public String message {get; set;}
    }

}