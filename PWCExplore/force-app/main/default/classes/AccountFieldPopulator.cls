/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to populate Account fields
Inputs:        NA
Test Class:    AccountFieldPopulatorTest

History
02-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AccountFieldPopulator {
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate Account series on account
Inputs:        List of Account records
Logic:         if 'account code' not blank than Account_Series__c = first 3 digit of 'account code' 
else 
First Character = API value of Business Unit selected on account ,
Second Character = must be 'Type of account' defined on Account,
Third character = should be 'X' for now
Test Class:   

History
02-04-2020      Kishor Kumar     Initial Release
05-05-2020      Kishor Kumar     Update for ASP Type
08-08-2020      Amit Shingavi    Added a logic for corporate division for '9P1' series
----------------------------------------------------------------------------*/
    
    private Static String CORPORATE_DIVISION = 'Z';
    public static Map<String,String> recordTypeIdVsRecordTypeName = new Map<String,String>();
    
    {
        if(recordTypeIdVsRecordTypeName.size() == 0){
            for(RecordType recType : [Select Id,DeveloperName 
                                      From RecordType 
                                      Where sObjectType = 'Account']){
                                          if(!recordTypeIdVsRecordTypeName.containsKey(recType.Id)){
                                              recordTypeIdVsRecordTypeName.put(recType.Id,recType.DeveloperName);
                                          }
                                      }
        }
    }
    
    public static List<String> MHE_ENTITLEMENT_PROCESS_NAMES = new List<String>{
        System.Label.MHE_Entitlement_record_name_for_spares_not_available,
            System.Label.MHE_Entitlement_record_name_for_technician_not_available,
            System.Label.MHE_Entitlement_record_name_for_technical_support_required,
            System.Label.MHE_Entitlement_record_name_for_vendor_dependency,
            System.Label.MHE_Entitlement_record_name_for_reason_and_technician_missing
            };
                
                public void populateAccountSeriesOnAccount(list<Account> accounts){
                    
                    try{
                        //Fetching reserved chars from custom setting
                        Address_Code_reserved_char__c rChar = Address_Code_reserved_char__c.getOrgDefaults();
                        
                        for(Account acc : accounts){ 
                            //B2C Value
                            if(acc.IsPersonAccount && String.isNotBlank(acc.Business_Unit__c) 
                               && String.isNotBlank(acc.Branch_Code__c)){
                                   acc.Account_Series__c = string.valueOf(acc.Business_Unit__c + acc.Branch_Code__c  + rChar.B2C_character__c);
                                   
                               } else if(!acc.IsPersonAccount){ //B2B 
                                   if(String.isBlank(acc.Account_Code__c)  && String.isNotBlank(acc.Business_Unit__c) 
                                      && String.isNotBlank(acc.Type) 
                                      && (String.isBlank(acc.Account_Series__c) || !acc.Account_Series__c.startsWithIgnoreCase(System.Label.Parent_Account_Series))){
                                          
                                          if(acc.Type == '3'){ //Special Case for 'ASP' type
                                              acc.Account_Series__c = string.valueOf(acc.Type + acc.Business_Unit__c + rChar.B2B_Account_Series_Char__c);                      
                                          } 
                                          //Added else if block to handle vendor type
                                          else if(acc.Type == '1'){ //Special Case for 'Vendor' type
                                              acc.Account_Series__c = string.valueOf(acc.Type + rChar.Vendor_Character__c);                      
                                          }
                                          //end of code block to handle vendor type                       
                                          else 
                                              acc.Account_Series__c = string.valueOf(acc.Business_Unit__c + acc.Type  + rChar.B2B_Account_Series_Char__c);
                                      } else if(String.isNotBlank(acc.Account_Code__c) ){
                                          acc.Account_Series__c  = (acc.Account_Code__c).substring(0, 3);
                                      }
                                   
                               }
                            
                            //Check for parent account series and populate the business unit
                            updateCorporateDivisionforParentAccount(acc);
                            
                        }
                    }catch(Exception ex){
                        Logger.logError('AccountFieldPopulator', 'populateAccountSeriesOnAccount', '', ex);
                    }
                }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate Parent Account code on child account
Inputs:        List of Account records
Logic:         
Test Class:   

History
28-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void populateParentAccountCode(list<Account> accounts){  
        Set<Id> parentAccIds = new Set<Id>();
        for(Account ac : accounts){
            parentAccIds.add(ac.ParentId);
        }
        
        Map<Id, Account> parentIdVsRecord = new Map<Id, Account>([Select Id, Parent_Account_Code__c, Parent.Account_Series__c, Account_Series__c,
                                                                  Account_Code__c, ParentId, Parent.Account_Code__c 
                                                                  FROM Account WHERE Id IN: parentAccIds]); 
        try{
            if(!parentIdVsRecord.isEmpty()){
                //Update Parent Account Code on Child
                for(Account acc : accounts){
                    if(acc.ParentId != null 
                       && parentIdVsRecord.containsKey(acc.ParentId) 
                       && String.isNotBlank(parentIdVsRecord.get(acc.ParentId).Account_series__c)
                       && ((parentIdVsRecord.get(acc.ParentId).Account_Series__c).startsWithIgnoreCase(System.Label.Parent_Account_Series))
                       && String.isNotBlank(parentIdVsRecord.get(acc.ParentId).Account_Code__c)){
                           acc.Parent_Account_Code__c = parentIdVsRecord.get(acc.ParentId).Account_Code__c;
                       }
                }
            }
        }catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'populateParentAccountCode', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to Update Record type Based on Account Type 
Inputs:        List of Account records
Logic:         
Test Class:   

History
29-04-2020      Kishor Kumar     Initial Release
04-07-2022      Alpana Sahay     Modified for Development of BD Account Type 
User story : SIEPB-25 and SIEPB-34
Feature : SIF-37  
----------------------------------------------------------------------------*/
    public void updateRecordType(list<Account> accounts){
        
        try{
            //Fetch All The Account RTs
            Utility util = new Utility();
            map<String, Id> rtMap =  util.fetchRecordTypes(GlobalConstants.AccountObjApiName);
            
            //Fetch Retailer and Influencer RT details
            Id influencerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Influencer').getRecordTypeId();
            Id retailerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();
            Id KeyAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Key_Account').getRecordTypeId();
            Id BDAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BD_Account').getRecordTypeId();
            Id CompetitorAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Competitor_Accounts').getRecordTypeId(); //Added by Alpana on 14th March 2023
            
            //Update Record type
            for(Account acc: accounts){
                //Bypass for Retailer and Influencer Record types
                if(acc.RecordTypeId != influencerRecordTypeId &&  acc.RecordTypeId != retailerRecordTypeId 
                   && acc.RecordTypeId != KeyAccountRecordTypeId && acc.RecordTypeId != CompetitorAccountRecordTypeId && acc.RecordTypeId != BDAccountRecordTypeId //Added Competitor Record by Shreela on 14th April 2023
                   || acc.Is_BD_Account__c){
                       //Update RT to Person Account
                       if(String.isNOTBlank(acc.LastName)){
                           acc.RecordTypeId = rtMap.get(GlobalConstants.CustomerAccountRt);
                       } else if(acc.Is_Key_Account__c){
                           acc.RecordTypeId = KeyAccountRecordTypeId; 
                           // SIF-37 Start       
                       } else if(acc.Is_BD_Account__c){
                           acc.RecordTypeId = BDAccountRecordTypeId;  
                           // SIF-37 End     
                       } else if(String.isNotBlank(acc.Type) && !rtMap.isEmpty() && 
                                 GlobalConstants.ACCOUNT_TYPE_VS_RT.containsKey(acc.Type) &&
                                 rtMap.containsKey(GlobalConstants.ACCOUNT_TYPE_VS_RT.get(acc.Type))){
                                     //Update RT to Dealer 
                                     acc.RecordTypeId = rtMap.get(GlobalConstants.ACCOUNT_TYPE_VS_RT.get(acc.Type));
                                 } else { //Update RT to Business Account 
                                     acc.RecordTypeId = rtMap.get(GlobalConstants.BUSINESS_ACCOUNT_RT);               
                                 }
                   }
                
            }
        }catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'updateRecordType', '', ex);
        }
    }    
    
    
    /*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Method to validate if logged in user has permission to create business account
Inputs:        List of Account records

History
10-08-2020      Manasi Londhe    Initial Release
----------------------------------------------------------------------------*/
    public void validateIfUserCanCreateBusinessAccount(List<Account> accounts){
        try{
            Id systemAdminProfileId=[Select Id,Name From Profile Where Name = :GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME].Id;
            List<User> loggedInUser=[Select Id,Name,Allow_Business_Account_Creation__c,Business_Unit__c From User 
                                     Where Id =:UserInfo.getUserId() And Allow_Business_Account_Creation__c=true];
            Id businessAccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId();
            if(loggedInUser.size()==0 && UserInfo.getProfileId()!=systemAdminProfileId && businessAccountRecordTypeId!=null){
                for(Account acct:accounts){
                    if(acct.RecordTypeId==businessAccountRecordTypeId && acct.Business_Unit__c!=null && acct.Business_Unit__c !=GlobalConstants.SSG_BUSINESS_UNIT)
                        acct.addError(System.label.Cannot_Create_Business_Account);
                }
            }
        }
        catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'validateIfUserCanCreateBusinessAccount', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to populate 'BU' & 'Type of Account' from 'account code' on account
Inputs:        List of Account records
Logic:          
First Character of account code  = API value of Business Unit on account ,
Second Character = must be 'Type of account' defined on Account,
=>For 'ASP' Type: 
First Character of account code  = API value of 'Type of account' on account ,
Second Character = must be 'Business Unit' on Account
Test Class:   

History
15-04-2020      Kishor Kumar     Initial Release
05-05-2020      Kishor Kumar     Update for ASP Type
----------------------------------------------------------------------------*/
    public void populateBUandTypeFromAccountCode(list<Account> accounts){
        try{
            for(Account acc : accounts){
                if(String.isNotBlank(acc.Account_Code__c) && ( String.isBlank(acc.Account_Series__c) 
                                                              || ! (acc.Account_Series__c).equalsIgnoreCase(System.Label.Parent_Account_Series))){
                                                                  //Populate BU 
                                                                  if((acc.Account_Code__c).startsWith('3') 
                                                                     && String.isBlank(acc.Business_Unit__c)){//Special Case for 'ASP' type
                                                                         acc.Business_Unit__c = (acc.Account_Code__c).substring(1, 2);                                          
                                                                     } else if(!(acc.Account_Code__c).startsWith('3') && String.isBlank(acc.Business_Unit__c)){
                                                                         acc.Business_Unit__c = (acc.Account_Code__c).substring(0, 1);
                                                                     } 
                                                                  
                                                                  //Populate 'Account Type'
                                                                  if((acc.Account_Code__c).startsWith('3') 
                                                                     && String.isBlank(acc.Type)){//Special Case for 'ASP' type
                                                                         acc.Type = (acc.Account_Code__c).substring(0, 1);                                          
                                                                     } else if(!(acc.Account_Code__c).startsWith('3') && String.isBlank(acc.Type)){
                                                                         acc.Type = (acc.Account_Code__c).substring(1, 2);
                                                                     }
                                                              }
            }
        }catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'populateBUandTypeFromAccountCode', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to Populate Blank address Name on associated address 
with Account Name 
Inputs:        List of Account records
Logic:         
Test Class:   

History
21-04-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
    public void updateAddessNameOnAddress(list<Account> accounts, map<Id, Account> AccountNewMap){
        list<Address__c> addressesToUpdate = new list<Address__c>();
        set<Id> addressIds = new set<Id>();
        
        for(Account acc : accounts){
            if(acc.Primary_Address__c != null){
                addressIds.add(acc.Primary_Address__c);
            }
        }
        
        //Query to fetch Address Name
        if(addressIds.size() > 0){
            for(Account accnt : [Select Id, Name,  Primary_Address__c, Primary_Address__r.Name__c 
                                 FROM Account 
                                 WHERE Primary_Address__c IN : addressIds 
                                 AND Primary_Address__r.Name__c = ''
                                 AND Id IN : accounts] ){
                                     Address__c addr = new Address__c();
                                     if (Schema.sObjectType.Account.fields.Primary_Address__c.isCreateable() && Schema.sObjectType.Address__c.fields.Name__c.isUpdateable()){
                                         addr.Id = accnt.Primary_Address__c;
                                         addr.Name__c = accnt.Name;
                                     }
                                     addressesToUpdate.add(addr); 
                                 }
        }
        if(Schema.sObjectType.Account.fields.Primary_Address__c.isUpdateable()){
            if(addressesToUpdate.size() > 0){
                try{
                    update addressesToUpdate;
                } catch(Exception ex){
                    Logger.logError('AccountFieldPopulator', 'updateAddessNameOnAddress', '', ex);
                }
            }
        }
    }
    /*------------------------------------------------------------------------
Author:        Sumit Swami
Company:       Salesforce
Description:   Method to Populate Account Name on Address by BP records
Inputs:        List of Account records
Logic:         
Test Class:   

History
22-07-2020      Sumit Swami     Initial Release
----------------------------------------------------------------------------*/
    public void updateAccountNameOnAddressByBP(list<Account> accounts, map<Id, Account> AccountNewMap){
        
        list<Address_By_BP__c> addressesToUpdate = new list<Address_By_BP__c>();
        
        //Query to fetch Addresses
        if(accounts.size() > 0){
            addressesToUpdate = [ SELECT Id, Account_Text__c, Account__c FROM Address_By_BP__c WHERE Account__c IN : AccountNewMap.keySet() ];
        }
        
        if(addressesToUpdate.size() > 0){
            for ( Address_By_BP__c each : addressesToUpdate ) {
                if(AccountNewMap.get(each.Account__c).isPersonAccount){
                    each.Account_Text__c = AccountNewMap.get(each.Account__c).FirstName+' '+AccountNewMap.get(each.Account__c).LastName;  
                }else{
                    each.Account_Text__c = AccountNewMap.get(each.Account__c).Name;     
                }
            }
            try{
                update addressesToUpdate;
            } catch(Exception ex){
                Logger.logError('AccountFieldPopulator', 'updateAccountNameOnAddressByBP', '', ex);
            }
        }
    }
    
    public void convertAccountNameToUpperCase(List<Account> accounts,Map<Id,Account> oldAccounts){
        List<Account> applicableAccounts=new List<Account>();
        if(oldAccounts==null)
            applicableAccounts=accounts;
        else{
            for(Account acct:accounts){
                if(acct.Name!=null && !((acct.Name).equals(oldAccounts.get(acct.Id).Name)))
                    applicableAccounts.add(acct); 
            }
        }
        try{
            if(applicableAccounts.size()>0){
                Set<Id> recordTypesApplicable=new Set<Id>();
                recordTypesApplicable.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.BUSINESS_ACCOUNT_RT).getRecordTypeId());
                recordTypesApplicable.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.ACCOUNT_RECORDTYPE_DEALER).getRecordTypeId());
                for(Account acct:applicableAccounts){
                    if(!String.isBlank(acct.Name) && recordTypesApplicable.contains(acct.RecordTypeId))
                        acct.Name=acct.Name.toUpperCase(); 
                }
            }
        }
        catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'convertAccountNameToUpperCase', '', ex);
        }
    }   
    
    public void populateDefaults(list<Account> newItems){
        map<Id, User> userMap = new map<Id, User>();
        try{
           //Fetch details from logged In user records
             //Fetch details from logged In user records
            //Added by Mrunali Chaudhari 0n 03/08/2023 for JIRA SLF-123 to capture Locks_Regional_Manager__c value
            for(User userRec: [SELECT Id, Business_Unit__c, Sub_Division__c, Interio_Sub_Division__c,Persona__c,
                               ManagerId,Manager.Persona__c,
                               Manager.ManagerId,Manager.Manager.Persona__c,
                               Manager.Manager.ManagerId,Manager.Manager.Manager.Persona__c FROM User                                                                        
                               WHERE Id  =: userInfo.getUserId()]){
                                   userMap.put(userRec.Id, userRec);
                               }
            //Added by Mrunali Chaudhari 0n 03/08/2023 for JIRA SLF-123 to capture Locks_Regional_Manager__c value
            for(Account acc : newItems){
                if(acc.Business_Unit__c == GlobalConstants.Locks_BUSINESS_UNIT) {
                    if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_bde_persona) {
                        if(userMap.get(userInfo.getUserId()).Manager.Persona__c == GlobalConstants.locks_rm_persona) {
                            acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).ManagerId;
                        }
                        else if(userMap.get(userInfo.getUserId()).Manager.Manager.Persona__c == GlobalConstants.locks_rm_persona) {
                            acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).Manager.ManagerId;
                        }
                        else if(userMap.get(userInfo.getUserId()).Manager.Manager.Manager.Persona__c == GlobalConstants.locks_rm_persona) {
                            acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).Manager.Manager.ManagerId;
                        }
                    }
                    else if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_bdm_persona) {
                        if(userMap.get(userInfo.getUserId()).Manager.Persona__c == GlobalConstants.locks_rm_persona){
                            acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).ManagerId;
                        }
                        else if(userMap.get(userInfo.getUserId()).Manager.Manager.Persona__c == GlobalConstants.locks_rm_persona) {
                             acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).Manager.ManagerId;
                        }
                    }
                    else if (userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.locks_zm_persona) {
                        if (userMap.get(userInfo.getUserId()).Manager.Persona__c == GlobalConstants.locks_rm_persona) {
                            acc.Locks_Regional_Manager__c  = userMap.get(userInfo.getUserId()).ManagerId;
                        }
                    }
                }
                           
                
                //Added by Siddhesh Mayekar for Consturction Submitter hierarchy for approval process  
                if(acc.Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT){        
                    if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.const_engineer_persona){
                        acc.Construction_Manager__c=userMap.get(userInfo.getUserId()).Manager.ManagerId;
                    }else if(userMap.get(userInfo.getUserId()).Persona__c == GlobalConstants.const_manager_persona){
                        acc.Construction_Manager__c = userMap.get(userInfo.getUserId()).ManagerId;
                    }
                }
                
                //Populate Business Unit for Child Account
                if((String.isBlank(acc.Account_Series__c) || acc.Account_Series__c.substring(0,2) != GlobalConstants.PARENT_ACCOUNT_SERIES_FIRST_2_CHARACTER) 
                   && userMap.containsKey(userInfo.getUserId()) 
                   && userMap.get(userInfo.getUserId()) != null){
                       
                       if(String.isBlank(acc.Business_Unit__c))
                           acc.Business_Unit__c = userMap.get(userInfo.getUserId()).Business_Unit__c;
                       if(String.isBlank(acc.Business_unit_multiselect__c))
                           acc.Business_unit_multiselect__c = acc.Business_Unit__c;
                       
                       if(String.isBlank(acc.Sub_Division__c))    
                           acc.Sub_Division__c = userMap.get(userInfo.getUserId()).Sub_Division__c;
                       if(String.isBlank(acc.Interio_Sub_Division__c))
                           acc.Interio_Sub_Division__c = userMap.get(userInfo.getUserId()).Interio_Sub_Division__c;
                   }               
            }
        }catch(Exception ex){
            Logger.logError('AccountFieldPopulator', 'populateDefaults', '', ex);
        }
    }
    
    //This method will update the business unit to 'Corporate Division' in case of '9P1' series
    private void updateCorporateDivisionforParentAccount(Account pAccountObj){
        if(pAccountObj != null && String.isNOTBlank(pAccountObj.Account_Series__c)
           && pAccountObj.Account_Series__c == Label.Parent_Account_Series){
               pAccountObj.Business_Unit__c = CORPORATE_DIVISION;
           }
    }
    
    /*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Method to create Entitlements for Accoount records
Inputs:        List of Account records
Logic:         
Test Class:   

History
27-10-2020      Kishor Kumar     Initial Release
15-01-2021      Kartik Shetty    Updated method to populate muliple Entitlement process for MHE accounts.
----------------------------------------------------------------------------*/
    public void createEntitlementsForAccount(list<Account> accounts) {
        List<String> ENTITLEMENT_PROCESS_NAME = new List<String>{System.Label.INTERIO_B2C_ENTITLEMENT_PROCESS};
            ENTITLEMENT_PROCESS_NAME.addAll(MHE_ENTITLEMENT_PROCESS_NAMES);
        
        List<Entitlement> accountEntitlements = new List<Entitlement>();
        Map<String, List<SlaProcess>> slaProcesses = new Map<String, List<SlaProcess>>();
        
        for(SlaProcess sla : [Select Id, Name, BusinessHoursId, SObjectType 
                              FROM SlaProcess WHERE Name IN :ENTITLEMENT_PROCESS_NAME AND SObjectType =: GlobalConstants.CASE_SOBJECT_API_NAME
                              AND isActive = true]) {
                                  List<SlaProcess> INTERIO_SLA_ProcessList = new List<SlaProcess>();
                                  List<SlaProcess> MHE_SLA_ProcessList = new List<SlaProcess>();
                                  if(sla.Name.containsIgnoreCase('Interio')) {
                                      if(slaProcesses.containsKey('Interio')) {
                                          INTERIO_SLA_ProcessList = slaProcesses.get('Interio');
                                      }
                                      INTERIO_SLA_ProcessList.add(sla);
                                      slaProcesses.put('Interio', INTERIO_SLA_ProcessList);
                                  }
                                  
                                  if(sla.Name.containsIgnoreCase('MHE')) {
                                      if(slaProcesses.containsKey('MHE')) {
                                          MHE_SLA_ProcessList = slaProcesses.get('MHE');
                                      }
                                      MHE_SLA_ProcessList.add(sla);
                                      slaProcesses.put('MHE', MHE_SLA_ProcessList);
                                  }
                              }
        
        if(slaProcesses.size() > 0) {
            for(Account acc : accounts) {
                //For Interio B2C , COCO Store Users
                if(slaProcesses.size() > 0
                   && recordTypeIdVsRecordTypeName.containsKey(acc.RecordTypeId) 
                   && recordTypeIdVsRecordTypeName.get(acc.RecordTypeId) == GlobalConstants.BUSINESS_ACCOUNT_RT
                   && acc.Type == 'W'
                   && acc.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT) {
                       //Condition need to be there to check Record Type & COCO Store criteria
                       Entitlement ent = new Entitlement();
                       ent.AccountId = acc.Id;
                       ent.Name = slaProcesses.get('Interio')[0].Name;
                       ent.SlaProcessId = slaProcesses.get('Interio')[0].Id;
                       ent.BusinessHoursId = slaProcesses.get('Interio')[0].BusinessHoursId;
                       ent.StartDate = Date.today();
                       ent.EndDate = ent.StartDate.addYears(5);
                       accountEntitlements.add(ent);
                   }
                //For MHE Business and key account
                else if(slaProcesses.size() > 0
                        && recordTypeIdVsRecordTypeName.containsKey(acc.RecordTypeId) 
                        && (recordTypeIdVsRecordTypeName.get(acc.RecordTypeId) == GlobalConstants.BUSINESS_ACCOUNT_RT || recordTypeIdVsRecordTypeName.get(acc.RecordTypeId) == GlobalConstants.KEY_ACCOUNT_RECORDTYPE_DEV_NAME)
                        && acc.Business_Unit__c == GlobalConstants.MHE_BUSINESS_UNIT
                        && slaProcesses.containsKey('MHE') && (slaProcesses.get('MHE')).size() > 0) {
                            for(SlaProcess slaProcess : slaProcesses.get('MHE')) {
                                Entitlement ent = new Entitlement();
                                ent.AccountId = acc.Id;
                                ent.Name = slaProcess.Name;
                                ent.SlaProcessId = slaProcess.Id;
                                ent.BusinessHoursId = slaProcess.BusinessHoursId;
                                ent.StartDate = Date.today();
                                ent.EndDate = ent.StartDate.addYears(5);
                                accountEntitlements.add(ent);
                            }
                        }
            }
        }
        
        if(accountEntitlements.size() > 0 ) {
            try {
                insert accountEntitlements;
            }
            catch(Exception ex) {
                Logger.logError('AccountFieldPopulator', 'createEntitlementsForAccount', '', ex);
            }
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Mahit Madwesh
Company:       Salesforce
Description:   Method to capture Key Account field for the logger Object
Inputs:        List of Account records
Logic:         
Test Class:   

History
15-12-2020      Mahit Madwesh    Initial Release
----------------------------------------------------------------------------*/
    public void captureKeyAccountChange(List<Account> newAccounts){
        Id keyAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(GlobalConstants.KEY_ACCOUNT_RECORDTYPE_DEV_NAME).getRecordTypeId();
        list<logger__c> existingStagingTableRecords = [SELECT Id,Type__c,Status__c FROM Logger__c where Type__c='Metadata change - P1' AND Status__c='Pending'];
        list<Logger__c> loggerList = new list<Logger__c>();
        for(Account a:newAccounts){
            if(a.recordTypeId == keyAccountRecordTypeId){
                logger__c newLog = new logger__c();
                newLog.Account__c = a.id;
                newLog.Type__c = 'Key Account change - P2';
                if(existingStagingTableRecords.size()>0){
                    newLog.Status__c = 'Rejected';
                }else{
                    newLog.Status__c = 'Pending';
                }
                loggerList.add(newLog);
            }
        }
        insert loggerList;
    }
    
    /*------------------------------------------------------------------------
Author     :  Siddhesh Mayekar
Date       :  15/03/2022
Description:  Show validation for mandatory fields while user is trying to submit account for approval (Construction B2B)
Inputs     :  Map<Id, Order> mapNewAccountRecords, Map<Id, Order> mapOldAccountRecords)
----------------------------------------------------------------------------*/
    public void checkMandatoryFieldsForCONST(Map<Id, Account> mapNewAccountRecords, Map<Id, Account> mapOldAccountRecords){
        for(Id AccountId : mapNewAccountRecords.keySet()) {
            if(mapNewAccountRecords.get(AccountId).Business_Unit__c==GlobalConstants.Construction_BUSINESS_UNIT && 
               (mapNewAccountRecords.get(AccountId).Construction_LOB__c==GlobalConstants.Construction_LOB_WPS || mapNewAccountRecords.get(AccountId).Construction_LOB__c==GlobalConstants.Construction_LOB_RMC)&& 
               mapNewAccountRecords.get(AccountId).Approval_Status__c == GlobalConstants.Submitted_for_Approval && 
               mapOldAccountRecords.get(AccountId).Approval_Status__c != mapNewAccountRecords.get(AccountId).Approval_Status__c && 
               mapNewAccountRecords.get(AccountId).Profit__c== Null){
                   String errorMessage = ''; 
                   
                   if(String.isEmpty(mapNewAccountRecords.get(AccountId).Construction_LOB__c)){
                        errorMessage += System.Label.Construction_LOB_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Construction_Sub_LOB__c)){
                       errorMessage += System.Label.Construction_Sub_LOB_is_missing + '\n'; 
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Sub_Division__c)){
                       errorMessage += System.Label.Sub_Division_is_missing + '\n'; 
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).User__c)){
                       errorMessage += System.Label.Internal_Sales_Representative_is_missing + '\n';  
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).PAN__c)){
                       errorMessage += System.Label.PAN_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).CIN__c)){
                       errorMessage += System.Label.CIN_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Business_Partner_Type__c)){
                       errorMessage += System.Label.Business_Partner_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Financial_Customer_Group__c)){
                       errorMessage += System.Label.Financial_Customer_Group_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Credit_Rating__c	)){
                       errorMessage += System.Label.Credit_Rating_is_missing + '\n';
                   }if(mapNewAccountRecords.get(AccountId).Credit_Limit__c == null ||mapNewAccountRecords.get(AccountId).Credit_Limit__c == 0 ){
                       errorMessage += System.Label.Credit_Limit_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Exchange_Rate_Type__c)){
                       errorMessage += System.Label.Exchange_Rate_Type_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Invoicing_Method__c)){
                       errorMessage += System.Label.Invoicing_Method_is_missing + '\n';
                   }if(String.isEmpty(mapNewAccountRecords.get(AccountId).Payment_Terms__c)){
                       errorMessage += System.Label.Payment_Terms_is_missing + '\n';
                   }if(String.isNotBlank(errorMessage)) {
            			mapNewAccountRecords.get(AccountId).addError(errorMessage + '\n');
        		   }
                   /*Ended by poonam (SCF - 102)*/
               }
        }                
    }               
    
    
    /*------------------------------------------------------------------------
Author     :  Pankaj Meshram
Date       :  26/04/2023
Description:  Update Level of approvers for construction
Inputs     :  List of accounts
----------------------------------------------------------------------------*/
    public void populateApprovers(List<Account> newItems){
        Set<String> setApproverUsername = new Set<String>();        
        Map<String,Id> usernameVsUserIdMap = new Map<String,Id>();
        Map<String, Construction_Account_rate_Revision__mdt> mdtDevNameVsUsername = new Map<String,Construction_Account_rate_Revision__mdt>();
        List<ProcessInstance> initialSubmitter;
        Map<id,Account> mapAccIdVsAcc  = new Map<id,Account>();
        Map<id,id> mapAccIdVsAccSubmitterId  = new Map<id,id>();
        
        //Capture Approval status for process instance
        for(Account acc:newItems){        
            if(acc.business_unit__c == GlobalConstants.Construction_BUSINESS_UNIT && acc.Construction_LOB__c != Null && acc.Approval_Status__c == GlobalConstants.Submitted_for_Approval){                
                mapAccIdVsAcc.put(acc.id, acc);
            }
        }
        
        //Get initial Submitter for sending mail        
        initialSubmitter = [select CreatedBy.Id, SubmittedById, TargetObjectId from ProcessInstance where TargetObjectId IN :mapAccIdVsAcc.keySet()];
        
        for (ProcessInstance i :initialSubmitter){
            if(mapAccIdVsAccSubmitterId.get(i.TargetObjectId)==null)
                mapAccIdVsAccSubmitterId.put(i.TargetObjectId, i.SubmittedById);
        }
        
        //Get All custom metadata records
        List<Construction_Account_rate_Revision__mdt> mdtAccRateRev = Construction_Account_rate_Revision__mdt.getAll().values();
        
        for(Construction_Account_rate_Revision__mdt constructionMdt:mdtAccRateRev){    
            mdtDevNameVsUsername.put(constructionMdt.DeveloperName,constructionMdt);            
            setApproverUsername.add(constructionMdt.userName__c);            
        }  
        
        //Get user for setting approvers
        for(User u:[select id,Email,username from user where username IN:setApproverUsername]){            
            usernameVsUserIdMap.put(u.username,u.id);            
        }        
        
        for(Account acc:mapAccIdVsAcc.values()){
            //Set Approvers for BP Code Creation Approval Process       
            if(acc.Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT && acc.Profit__c == null){               
                If(acc.Construction_LOB__c == GlobalConstants.Construction_LOB_WPS && !usernameVsUserIdMap.isEmpty()){  
                    if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_WPS_MUM){
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,4)).userName__c);  
                    }else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_WPS_PUNE){
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,4)).userName__c);  
                    }
                }
                else If(acc.Construction_LOB__c == GlobalConstants.Construction_LOB_RMC && !usernameVsUserIdMap.isEmpty()){                    
                    if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_MUM){
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,5)).userName__c);                        
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_AMB){                        
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,5)).userName__c);                        
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_PUNE_EAST){
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,5)).userName__c);                        
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_PUNE_WEST){
                        acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,1)).userName__c);
                        acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,2)).userName__c);
                        acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,3)).userName__c);
                        acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,5)).userName__c);                       
                    }
                }
            }
            //Set Approvers for Construction Costing Sheet Account Rate Revision Approval process
            else if(acc.Business_Unit__c == GlobalConstants.Construction_BUSINESS_UNIT && acc.Profit__c != null){
                if(initialSubmitter != Null){
                    acc.Initial_Submitter__c = mapAccIdVsAccSubmitterId.get(acc.id);
                }
                
                //Reset Approvers for rate revision added by pankaj on  23/05/2023
                acc.Level_1_Approver__c = Null;
                acc.Level_2_Approver__c = Null;
                acc.Level_3_Approver__c = Null;
                acc.Level_4_Approver__c = Null;
                acc.Level_5_Approver__c = Null;
                
                If(acc.Construction_LOB__c == GlobalConstants.Construction_LOB_WPS && !usernameVsUserIdMap.isEmpty()){  
                    if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_WPS_MUM){
                        if(acc.Profit__c >= 8){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,4)).userName__c);
                        }else if(acc.Profit__c >= 2 && acc.Profit__c < 8){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,4)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_MUM,4)).userName__c);
                        }
                    }else{
                        if(acc.Profit__c >= 8){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,4)).userName__c);
                        }else if(acc.Profit__c >= 2 && acc.Profit__c < 8){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,4)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_WPS_PUNE,4)).userName__c);
                        }
                    }
                }
                else If(acc.Construction_LOB__c == GlobalConstants.Construction_LOB_RMC && !usernameVsUserIdMap.isEmpty()){  
                    if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_MUM){
                        if(acc.Profit__c > 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,5)).userName__c);
                        }else if(acc.Profit__c > 5 && acc.Profit__c <= 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,5)).userName__c);
                        }else if(acc.Profit__c >= -5 && acc.Profit__c <= 5){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,5)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,4)).userName__c);
                            acc.Level_5_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_MUM,5)).userName__c);
                        }
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_AMB){
                        if(acc.Profit__c > 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,5)).userName__c);
                        }else if(acc.Profit__c > 5 && acc.Profit__c <= 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,5)).userName__c);
                        }else if(acc.Profit__c >= -5 && acc.Profit__c <= 5){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,5)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,4)).userName__c);
                            acc.Level_5_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_AMB,5)).userName__c);
                        }
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_PUNE_EAST){
                        if(acc.Profit__c > 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,5)).userName__c);
                        }else if(acc.Profit__c > 5 && acc.Profit__c <= 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,5)).userName__c);
                        }else if(acc.Profit__c >= -5 && acc.Profit__c <= 5){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,5)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,4)).userName__c);
                            acc.Level_5_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_EAST,5)).userName__c);
                        }
                    }
                    else if(acc.Construction_Sub_LOB__c == GlobalConstants.Construction_subLOB_RMC_PUNE_WEST){
                        if(acc.Profit__c > 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,5)).userName__c);
                        }else if(acc.Profit__c > 5 && acc.Profit__c <= 10){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,5)).userName__c);
                        }else if(acc.Profit__c >= -5 && acc.Profit__c <= 5){
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,5)).userName__c);
                        }else{
                            acc.Level_1_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,1)).userName__c);
                            acc.Level_2_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,2)).userName__c);
                            acc.Level_3_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,3)).userName__c);
                            acc.Level_4_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,4)).userName__c);
                            acc.Level_5_Approver__c = usernameVsUserIdMap.get(mdtDevNameVsUsername.get(getDevName(GlobalConstants.Construction_subLOB_RMC_PUNE_WEST,5)).userName__c);
                        }
                    }
                }
            }
        }
    }   
    
    /*------------------------------------------------------------------------
Author     :  Pankaj Meshram
Date       :  05/05/2023
Description:  Replace '-' with '_' in SubLOB and create actual metadata DeveloperName
Inputs     :  Constuction Sub LOB and Approver level
----------------------------------------------------------------------------*/
    public string getDevName(String subLOB,integer approverLevel){
        subLOB = subLOB.replace(GlobalConstants.Hyphen,GlobalConstants.Underscore);
        String finalString = subLOB+GlobalConstants.Underscore+GlobalConstants.Level_Str+GlobalConstants.Underscore+approverLevel;        
        return finalString;
    }
    
    /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  26/03/2024
    Description:  Update Level of approvers for ASP onboarding
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void populateApproversForASPOnboarding(List<Account> newItems){
        Map <Id,Id> accOwnerMap = new Map <Id,Id>();
        List<ProcessInstance> initialSubmitter = new List<ProcessInstance>();
        Map <Id,Id> mapAccIdVsAccSubmitterId  = new Map <Id,Id>();
        Map<Id, User> approversList = new Map<Id,User>();

        for(Account acc : newItems) {
            if(acc.ASP_With_BSM_Approver__c == null && acc.type == '3') {
                accOwnerMap.put(acc.Id, acc.OwnerId);
            }
        }
        
        if(!accOwnerMap.isEmpty()) {
            initialSubmitter = [select CreatedBy.Id, SubmittedById, TargetObjectId from ProcessInstance where TargetObjectId IN :accOwnerMap.keySet()];
        }       
        
        for (ProcessInstance i :initialSubmitter){
            mapAccIdVsAccSubmitterId.put(i.TargetObjectId, i.SubmittedById);
        }

        if(!mapAccIdVsAccSubmitterId.isEmpty()) {
            approversList = new Map<Id, User>([SELECT Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.Manager.Manager.ManagerId, Manager.Manager.Manager.Manager.ManagerId FROM User WHERE ID = :mapAccIdVsAccSubmitterId.values()]);
        }

        for(Account acc : newItems) {
            if(approversList.containsKey(acc.OwnerId)) {
                User approver = approversList.get(acc.OwnerId);
                acc.ASP_With_BSM_Approver__c = approver?.ManagerId;
                acc.ASP_With_RSM_Approver__c = approver?.Manager?.ManagerId;
                acc.ASP_With_ZSM_Approver__c = approver?.Manager?.Manager?.ManagerId;
                acc.ASP_With_NSH_Approver__c = approver?.Manager?.Manager?.Manager?.ManagerId;
                acc.ASP_With_HO_Approver__c = approver?.Manager?.Manager?.Manager?.Manager?.ManagerId;
            }
        }
    }

    /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  08/04/2024
    Description:  To check manadatory documents
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void checkMandatoryDocuments(Map<Id, Account> accRecords){
        String metaDataLabel = '';
        Boolean isStatusNOC = false;
        Set<Id> conDocIdSet = new Set<Id>();
        Set<Id> accRecordIdSet = new Set<Id>();
        Map<Id, String> accIdtoBUmap = new Map<Id, String>();
        List<ProcessInstance> approvalProcesses = new List<ProcessInstance>();
        Map<ID, String> mandatoryDocumentsNameNotUploaded = new Map<ID, String>();
        for(Account a : accRecords.values()){
            if(a.Status__c == 'Under Review' || a.Status__c == 'Deactivation Submitted for Approval') {
                accRecordIdSet.add(a.Id);
                accIdtoBUmap.put(a.Id, a.Business_Unit__c);
            } else if(a.Status__c == 'Full and Final Settlement Done and ASP Closed') {
               isStatusNOC = true;
               accRecordIdSet.add(a.Id);
               metaDataLabel = 'NOC Documents'; 
            }
        }
        if(!isStatusNOC && !accRecordIdSet.isEmpty()) {
            for(ProcessInstance pi : [SELECT Id,Status, ProcessDefinition.DeveloperName,TargetObjectId
                                                    FROM ProcessInstance
                                                    WHERE TargetObjectId = :accRecordIdSet
                                                    AND Status = 'Started'
                                                    ]) {
                String bu = accIdtoBUmap.get(pi.TargetObjectId);
                if(pi.ProcessDefinition.DeveloperName == 'ASP_Onboarding_Approval_new') {
                    metaDataLabel = '('+bu+') ' + 'ASP Onboarding';
                    approvalProcesses.add(pi);
                } else if(pi.ProcessDefinition.DeveloperName == 'ASP_Termination_Approval_new'){
                    metaDataLabel = '('+bu+') ' + 'ASP_Deactivation_Documents';
                    approvalProcesses.add(pi);
                }
            }
        }
        if(!approvalProcesses.isEmpty() || isStatusNOC){
            UploadFilesCheckList__mdt metadataRecord = [SELECT RequiredDocuments__c,Related_Object__c,DocumentName__c,Business_Unit__c FROM UploadFilesCheckList__mdt WHERE Label=:metaDataLabel LIMIT 1];
            String requiredDocuments = metadataRecord.RequiredDocuments__c;
            List<String> requiredDocumentsList = new List<String>();
            if(requiredDocuments != null && String.isNotBlank(requiredDocuments)){
                requiredDocumentsList = requiredDocuments.split(',');
                
                Map<Id, Id> accDocMap = new Map<Id, Id>();
                for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :accRecordIdSet]) {
                    conDocIdSet.add(conDocLink.ContentDocumentId);
                    accDocMap.put(conDocLink.ContentDocumentId, conDocLink.LinkedEntityId);
                }
                // List<String> documentsUploaded = new List<String>();   
                Map<Id, List<String>> accFileMap = new Map<Id, List<String>>();     
                for(ContentVersion conVersions : [SELECT Id, Title, ContentDocumentId, FileType, Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN :conDocIdSet]){
                    String documentName = conVersions.Document_Name__c.trim().tolowerCase();
                    // documentsUploaded.add(documentName);
                    List<String> fileName = accFileMap.get(accDocMap.get(conVersions.ContentDocumentId));
                    if(fileName == null) {
                        fileName = new List<String>{documentName};
                    }
                    fileName.add(documentName);
                    accFileMap.put(accDocMap.get(conVersions.ContentDocumentId), fileName);
                }
                Map<Account, Boolean> accToAddError = new Map<Account, Boolean>();
                for(ID i : accRecordIdSet){
                    Boolean isContainsAllDocuments = true;
                    if(accFileMap.containsKey(i)) {
                        List<String> documentsUploaded = accFileMap.get(i);
                        for(String s : requiredDocumentsList){
                            if(!documentsUploaded.contains(s.trim().toLowerCase())){
                                String docName = mandatoryDocumentsNameNotUploaded.get(i);
                                if(docName == null){
                                    docName = s;
                                } else {
                                    docName += ', ' + s;
                                }
                                mandatoryDocumentsNameNotUploaded.put(i, docName);
                                isContainsAllDocuments = false;
                            }
                        }
                    } else {
                        isContainsAllDocuments = false;
                    }
                    if(!isContainsAllDocuments){
                        accToAddError.put(accRecords.get(i), isContainsAllDocuments);
                    }  
                }
                
                if(!accToAddError.isEmpty()){
                    for(Account a : accToAddError.keySet()){
                        Boolean isContainsAllDocuments = accToAddError.get(a);
                        String errorMessage = '';
                        if(mandatoryDocumentsNameNotUploaded.get(a.Id) != null && !isContainsAllDocuments){
                            errorMessage = 'Please upload required documents. These include ' + mandatoryDocumentsNameNotUploaded.get(a.Id) + '.';
                        } else {
                            errorMessage = 'Please upload all the required documents.';
                        }
                        a.addError(errorMessage);
                    }
                }
            }
        }    
    }

    private static String fillTheErrorField(String fieldString, String errorFieldtoAdd, String message){
        if(String.isEmpty(fieldString)){
            if(errorFieldtoAdd != ''){
                errorFieldtoAdd += ', ' + message;
            } else {
                errorFieldtoAdd = message;
            }
        }
        return errorFieldtoAdd;
    }

    private static String fillTheErrorFieldAndCheckIfTrue(Boolean field, String errorFieldtoAdd, String message){
        if(!field){
            if(errorFieldtoAdd != ''){
                errorFieldtoAdd += ', ' + message;
            } else {
                errorFieldtoAdd = message;
            }
        }
        return errorFieldtoAdd;
    }

    /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  08/04/2024
    Description:  To check ASP mandatory fields after updating type
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void checkMandatoryFieldsAfterUpdatingType(List<Account> newItems) {
        String errorFieldToAdd = '';
        for(Account a : newItems){
            if(a.Type == '3'){
                errorFieldToAdd = fillTheErrorField(a.ASP_Owner__c, errorFieldToAdd, 'ASP Owner');
                errorFieldToAdd = fillTheErrorField(a.Primary_Address__c, errorFieldToAdd, 'Address');
                errorFieldToAdd = fillTheErrorField(a.GST_Number__c, errorFieldToAdd, 'GST Number');
                errorFieldToAdd = fillTheErrorField(a.PAN__c, errorFieldToAdd, 'PAN');
                errorFieldToAdd = fillTheErrorField(a.AADHAR_Number__c?.toString(), errorFieldToAdd, 'Aadhar Number');
                errorFieldToAdd = fillTheErrorField(a.Tenure__c, errorFieldToAdd, 'Tenure');
                errorFieldToAdd = fillTheErrorField(a.IFSC_Code__c, errorFieldToAdd, 'IFSC Code');
                errorFieldToAdd = fillTheErrorField(a.Bank_Name__c, errorFieldToAdd, 'Bank Name');
                errorFieldToAdd = fillTheErrorField(a.Bank_Address__Street__s, errorFieldToAdd, 'Bank Address (Street)');
                errorFieldToAdd = fillTheErrorField(a.Bank_Address__StateCode__s, errorFieldToAdd, 'Bank Address (State/Province)');
                errorFieldToAdd = fillTheErrorField(a.Bank_Address__PostalCode__s, errorFieldToAdd, 'Bank Address (ZIP/Postal Code)');
                errorFieldToAdd = fillTheErrorField(a.Bank_Address__CountryCode__s, errorFieldToAdd, 'Bank Address (Country/Territory)');
                errorFieldToAdd = fillTheErrorField(a.Bank_Address__City__s, errorFieldToAdd, '	Bank Address (City)');
                errorFieldToAdd = fillTheErrorField(a.Product_Group__c, errorFieldToAdd, 'Product Group');
                errorFieldToAdd = fillTheErrorField(a.Email_Id_of_ASP_Owner__c, errorFieldToAdd, 'Email Id of ASP Owner');



                if(errorFieldToAdd != ''){
                    String errorToShow = 'All mandatory fields must be filled out before proceeding. These include ' + errorFieldToAdd + ' Please ensure that all required fields are completed.';
                    a.addError(errorToShow);
                }
            }
        }
    }

    public void changeCheckBoxAfterChangingStatusToActive(List<Account> newItems) {
        for(Account a : newItems){
            if(a.Type == '3' && a.Status__c == 'Active') {
                a.is_ASP_Active__c = true;
            }
        }
    }

    /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  26/04/2024
    Description:  To check All required checkBoxes before updating status to "Full and Final Settlement Done and ASP Closed"
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void checkMandatoryFieldBeforeFullAndFinalSettlement(List<Account> newItems) {
        String errorFieldToAdd = '';
        for(Account a : newItems){
            if(a.Type == '3' && a.Status__c == 'Full and Final Settlement Done and ASP Closed') {
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.NOC_Issued_to_ASP__c, errorFieldToAdd, 'NOC Issued to ASP');
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.Authorization_Letter_Collected__c, errorFieldToAdd, 'Authorization Letter Collected');
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.Identity_Card_Collected__c, errorFieldToAdd, 'Identity Card Collected');
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.Unused_AMC_forms_Collected__c, errorFieldToAdd, 'Unused AMC forms Collected');
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.Defective_Damaged_product_Collected__c, errorFieldToAdd, 'Defective Damaged product Collected');
                errorFieldToAdd = fillTheErrorFieldAndCheckIfTrue(a.ASP_has_settled_all_pending_receivable__c, errorFieldToAdd, 'ASP has settled all pending receivable');

                if(errorFieldToAdd != ''){
                    String errorToShow = 'All these mandatory fields must be true before proceeding. These include ' + errorFieldToAdd + ' Please ensure that all required fields are checked.';
                    a.addError(errorToShow);
                } else {
                    a.is_ASP_Active__c = false;
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  29/04/2024
    Description:  To make comments mandatory during rejection
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void makeCommentsMandatoryDuringRejection(Map<Id, Account> newRecorMap, Map<Id, Account> oldRecordMap) {
        // Map<Id, Account> accIdMap = new Map<Id, Account>();
        // for(Account a : newRecorMap.values()) {
        //     if((a.Status__c == 'Rejected' || a.Status__c == 'Deactivation Initiated') && (oldRecordMap.get(a.Id).Status__c != 'Rejected' || oldRecordMap.get(a.Id).Status__c != 'Deactivation Initiated')) {
        //         accIdMap.put(a.Id, a);
        //     }
        // }

        // if(!accIdMap.isEmpty()) {
        //     List<ProcessInstance> piList = new List<ProcessInstance>([SELECT ID,TargetObjectId,CompletedDate,Status,(SELECT Id,StepStatus,Comments FROM Steps) FROM ProcessInstance WHERE TargetObjectId IN : accIdMap.keySet() AND (ProcessDefinition.DeveloperName IN ('ASP_Onboarding_Approval_new' ,'ASP_Termination_Approval_new'))]);
        //     for(Account a : accIdMap.values()) {
        //         for(ProcessInstance pi : piList) {
        //             if(!pi.Steps.isEmpty()){
        //                 Boolean isNull = false;
        //                 System.debug(pi);
        //                 for(ProcessInstanceStep piStep : pi.Steps) {
        //                     System.debug(piStep);
        //                     if(piStep.StepStatus == 'Rejected' && String.isBlank(piStep.Comments)) {
        //                         isNull = true;
        //                     }
        //                 }
        //                 if(isNull){
        //                     a.addError('Rejection Comments must be filled');
        //                 }
        //             }
        //         }
        //     }
        // }
    }

     /*------------------------------------------------------------------------
    Author     :  Tarun Jangir
    Date       :  29/04/2024
    Description:  to check if ASM upload the renewal document before Updating the End Date
    Inputs     :  List of accounts
    ----------------------------------------------------------------------------*/
    public void checkRenewalDocumentBeforeChangingEndDate(Map<Id, Account> newRecorMap, Map<Id, Account> oldRecordMap) {
        Map<Id, Account> accIdMap = new Map<Id, Account>();
        for(Account a : newRecorMap.values()) {
            if(a.End_Date__c != oldRecordMap.get(a.Id).End_Date__c) {
                accIdMap.put(a.Id, a);
            }
        }
        if(!accIdMap.isEmpty()) {
            Set<Id> conDocIdSet = new Set<Id>();
            Map<Id, Id> accDocMap = new Map<Id, Id>();
            for(ContentDocumentLink conDocLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :accIdMap.keySet()]) {
                conDocIdSet.add(conDocLink.ContentDocumentId);
                accDocMap.put(conDocLink.ContentDocumentId, conDocLink.LinkedEntityId);
            }
            Map<Id, List<String>> accFileMap = new Map<Id, List<String>>();     
            for(ContentVersion conVersions : [SELECT Id, Title, ContentDocumentId, FileType, Document_Name__c FROM ContentVersion WHERE ContentDocumentId IN :conDocIdSet]){
                String documentName = conVersions.Document_Name__c.trim().tolowerCase();
                // documentsUploaded.add(documentName);
                List<String> fileName = accFileMap.get(accDocMap.get(conVersions.ContentDocumentId));
                if(fileName == null) {
                    fileName = new List<String>{documentName};
                }
                fileName.add(documentName);
                accFileMap.put(accDocMap.get(conVersions.ContentDocumentId), fileName);
            }
            List<Account> accToAddError = new List<Account>();
            for(Id i : accFileMap.keySet()) {
                Boolean isExist = false;
                List<String> documentsUploaded = accFileMap.get(i);
                for(String s : documentsUploaded) {
                    if(s == 'Renewal Letter or Letter of Extension') {
                        isExist = true;
                    }
                }
                if(!isExist) {
                    accToAddError.add(newRecorMap.get(i));
                }
            }
            for(Account a : accToAddError) {
                a.addError('Please Upload \'Renewal Letter or Letter of Extension\' document before updating the end date od ASP');
            }
        }
    }
}