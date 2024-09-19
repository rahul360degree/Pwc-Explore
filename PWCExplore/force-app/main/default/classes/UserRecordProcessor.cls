/*---------------------------------------------------------------------------
Author:        Shailja
Company:       Salesforce
Description:   Class to process User records
Inputs:        NA
Test Class:
-----------------------------------------------------------------------------
History
02-06-2020     Shailja     Initial Release 
----------------------------------------------------------------------------*/
public without sharing class UserRecordProcessor {
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method to populate Account Name based on Account/ContactId
                       Beofore Update
        Inputs:        List<User> newUsers, Map<Id, User> oldUsersMap
    ----------------------------------------------------------------------------*/
    public static void populateAssociatedAccountName(List<User> newUsers, Map<Id, User> oldUsersMap){
        List<User> usrs = new List<User>();
        for(User usr : newUsers){
            if(usr.Account__c != oldUsersMap.get(usr.Id).Account__c){
                usrs.add(usr);
            }
        }
        if(usrs.size() > 0)
            populateAssociatedAccountName(usrs);
        
    }
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method to populate Account Name based on Account/ContactId
                       Beofore Insert
        Inputs:        list<User> newUsers
    ----------------------------------------------------------------------------*/
    public static void populateAssociatedAccountName(list<User> newUsers){
        //Store AccountIds in case of Internal Users
        List<Id> accountIds = new List<Id>();
        //Store ContactIds in case of External Users
        List<Id> contactIds = new List<Id>();
        Map<Id, String> idVsNames = new Map<Id, String>();
        for(User usr : newUsers){
            //check if user is internal user
            if(usr.ContactID == null
               && String.isNotBlank(usr.Account__c)
               && String.isBlank(usr.Account_Name__c)){
                   accountIds.add(usr.Account__c);
               }else if(usr.ContactID != null
                        && String.isBlank(usr.Account_Name__c)){      //check if user is external user
                            contactIds.add(usr.ContactID);
               }
        }
        
        // for internal users
        if(accountIds.size() > 0)
            idVsNames = getNames(accountIds, false);
        //for external users
        if(contactIds.size() > 0)
           idVsNames.putAll(getNames(contactIds, true));
        
        if(!idVsNames.isEmpty()){
            for(User usr : newUsers){
                if(idVsNames.containsKey(usr.Account__c)
                  || idVsNames.containsKey(usr.ContactId)){
                   usr.Account_Name__c = idVsNames.containsKey(usr.Account__c) ? idVsNames.get(usr.Account__c) : idVsNames.containsKey(usr.ContactId) ? idVsNames.get(usr.ContactId) : '' ;
                }
            }
        }
    }
    
     static Map<Id, String> getNames(List<Id> recIds, Boolean isExternalUsers){
        String sObjectApiName = '';
        Map<Id, String> idVsNames = new Map<Id, String>();
        if(isExternalUsers){
            sObjectApiName = GlobalConstants.CONTACT_SOBJECT_API_NAME;
        }else{
            sObjectApiName = GlobalConstants.ACCOUNTOBJAPINAME;
        }
        Set<String> sObjectFields = new Set<String>{'Id', 'Name'}; 
        if(isExternalUsers) sObjectFields.add('Account.Name');
        String query = QueryBuilder.build(sObjectApiName,
                                          sObjectFields,
                                          ' Id IN: recIds ');
        List<sObject> records =  (List<sObject>)Database.query(query);
        if(isExternalUsers){
            for(Contact cnt : (List<Contact>)records){
                idVsNames.put(cnt.Id, cnt.Account.Name);
            }
        }else{
            for(Account act : (List<Account>)records){
                idVsNames.put(act.Id, act.Name);
            }
        }
        return idVsNames;
    }
    
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method to populate Account Details based on BP Code
                       Beofore Update
        Inputs:        List<User> newUsers, Map<Id, User> oldUsersMap
    ----------------------------------------------------------------------------*/
    public static void populateAccountDetailsBasedOnBPCode(List<User> newUsers, Map<Id, User> oldUsersMap){
        List<User> usrs = new List<User>();
        for(User usr : newUsers){
            if(usr.Business_Partner_Code__c != oldUsersMap.get(usr.Id).Business_Partner_Code__c){
                usrs.add(usr);
            }
        }
        if(usrs.size() > 0)
            populateAccountDetailsBasedOnBPCode(usrs);
    }
    
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method to get Account Details based on BP Code
                       Before Insert
        Inputs:        NA
    ----------------------------------------------------------------------------*/
    public static void populateAccountDetailsBasedOnBPCode(list<User> newUsers){
        Set<String> bPCodes = new Set<String>();
        Map<String, Account> bpCodeVsAccount = new Map<String, Account>();
        for(User usr : newUsers){
            if(usr.Business_Partner_Code__c != null){
                bpCodes.add(usr.Business_Partner_Code__c);
            }
        }
        
        if(bpCodes.size() > 0){
            bpCodeVsAccount = getAccountForBPCode(bpCodes);
            if(!bpCodeVsAccount.isEmpty()){
                for(User usr : newUsers){
                    if(bpCodeVsAccount.containsKey(usr.Business_Partner_Code__c)){
                        usr.Account__c = bpCodeVsAccount.get(usr.Business_Partner_Code__c).Id;
                        usr.Account_Name__c = bpCodeVsAccount.get(usr.Business_Partner_Code__c).Name;
                    }
                }
            }
        }
        
    }
    
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method to get Accounts based on BP Code
        Inputs:        Set<String> bPCodes
    ----------------------------------------------------------------------------*/
    static Map<String, Account> getAccountForBPCode(Set<String> bPCodes){
        List<Account> accts = [Select Id, Name, Account_Code__c From Account Where Account_Code__c IN: bpCodes];
        Map<String, Account> bpCodeVsAccount = new Map<String, Account>();
        if(accts != null && accts.size() > 0){
            for(Account ac : accts){
                bpCodeVsAccount.put(ac.Account_Code__c, ac);
            }
        }
        return bpCodeVsAccount;
    }
    
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method is responsible for validating Sales Office
        Inputs:        NA
    ----------------------------------------------------------------------------*/   
    public static void validateSalesOffice(List<User> newUsers, Map<Id, User> oldUsersMap){
        List<User> usrs = new List<User>();
        for(User usr : newUsers){
            if(usr.Sales_Office__c != oldUsersMap.get(usr.Id).Sales_Office__c){
                usrs.add(usr);
            }
        }
        if(usrs.size() > 0)
            validateSalesOffice(usrs);
    }
     /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method is responsible for validating Sales Office
        Inputs:        NA
    ----------------------------------------------------------------------------*/
    public static void validateSalesOffice(list<User> newUsers){
        Set<String> salesOffices = new Set<String>();
        Map<String, Sales_Office__c> salesOfficeVsRecord = new Map<String, Sales_Office__c>();
        for(User usr : newUsers){
            if(String.isNotBlank(usr.Sales_Office__c)){
                salesOffices.add(usr.Sales_Office__c);
            }
        }
        if(salesOffices.size() > 0){
            salesOfficeVsRecord = getSalesOffices(salesOffices);
            for(User usr : newUsers){
                if(String.isNotBlank(usr.Sales_Office__c) 
                   && (salesOfficeVsRecord.isEmpty() || !salesOfficeVsRecord.containsKey(usr.Sales_Office__c))){
                    usr.addError(System.Label.Sales_Office_Validation_Error_On_User_Record);
                }
                
            }
        }
        
        
    }
    
    /*------------------------------------------------------------------------
        Author:        Amit Shingavi
        Company:       Salesforce
        Description:   Method to validate the entered warehouse as a primary warehouse and secondary warehouse
        Inputs:        NA
    ----------------------------------------------------------------------------*/ 
    public static void validateWarehouses(List<User> newUsers) {
        Set<String> warehouseCodes = new Set<String>();
        Map<String, Warehouse__c> warehouses = new Map<String, Warehouse__c>();
        Set<String> validWrCodes = new Set<String>();

        for(User usr : newUsers) {
            if(String.isNotBlank(usr.Primary_Warehouses__c)) {
                warehouseCodes.addAll((usr.Primary_Warehouses__c.deleteWhitespace()).split(','));
            }

            if(String.isNotBlank(usr.Secondary_Warehouses__c )) {
                warehouseCodes.addAll((usr.Secondary_Warehouses__c.deleteWhitespace()).split(','));
            }
        }

        for(Warehouse__c wareItr : [SELECT Warehouse__c FROM Warehouse__c WHERE Warehouse__c IN: warehouseCodes ]) {
         	validWrCodes.add(wareItr.Warehouse__c);   
        }

        System.debug('validWrCodes==='+validWrCodes);
        System.debug('warehouseCodes==='+warehouseCodes);

        for(User usr : newUsers) {
            if(String.isNotBlank(usr.Primary_Warehouses__c)) {
                List<String> prWarehouse = new List<String>();
                prWarehouse = usr.Primary_Warehouses__c.split(',');
                for(String str : prWarehouse){
                    System.debug('str==='+str);
                    if(!validWrCodes.contains(str.trim())) {
                        System.debug('Invalid Code: ' + str);
                        usr.addError(System.Label.ValidatePrimaryWarehouse);
                        break; 
                    }
                }
            }

            if(String.isNotBlank(usr.Secondary_Warehouses__c)) {
                List<String> prWarehouse = new List<String>();
                prWarehouse = usr.Secondary_Warehouses__c.split(',');
                for(String str : prWarehouse) {
                    if(!validWrCodes.contains(str.trim())) {
                        usr.addError(System.Label.ValidateSecondaryWarehouse);
                        break;
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
        Author:        Shailja
        Company:       Salesforce
        Description:   Method is responsible for validating Sales Office
        Inputs:        NA
    ----------------------------------------------------------------------------*/ 
    static Map<String, Sales_Office__c> getSalesOffices(Set<String> salesOfficeCodes){
        Map<String, Sales_Office__c> salesOfficeVsRecord = new Map<String, Sales_Office__c>();
        List<Sales_Office__c> salesOffices = [Select Id, LN_Sales_Office_Code__c From Sales_Office__c Where LN_Sales_Office_Code__c IN :salesOfficeCodes];
        for(Sales_Office__c so : salesOffices){
            salesOfficeVsRecord.put(so.LN_Sales_Office_Code__c, so);
        }
        return salesOfficeVsRecord;
    }
    
}