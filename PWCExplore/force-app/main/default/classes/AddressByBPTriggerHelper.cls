/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Helper class for Address_by_BP__c Trigger
Inputs:        NA
Test Class:    AddressByBPTriggerHelperTest
History
26-05-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AddressByBPTriggerHelper {
    Boolean associatedBranchEmpty = false; //Added false by Shreela on 7th Dec 2022
    public void validateTaxNumberForSelectedAddress(list<Address_by_BP__c> abpRecords){ 
        //Profile profile = [Select Id,Name from Profile where id=:Userinfo.getProfileId() ]; //[WIX and WC0 account fix]
        //if(profile.name !=GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME){
        if(UserInfo.getProfileId()!='00e2x000000lGU6AAM'){   //Hardcoded Profile Id Instead of query and Commented above two lines by shreela on 1st Dec 2022
            set<Id> addressIds = new set<Id>();
            map<Id,Address__c> addressMap = new map<Id,Address__c>();
            set<Id> accountIds = new set<Id>();
            map<Id, list<Tax_Number__c>> AccountIdVsTaxNumbers = new map<Id, list<Tax_Number__c>>();
            try{
                
                for(Address_by_BP__c abp : abpRecords){
                    if(abp.Address_Code__c != null && abp.Sold_To__c 
                       && abp.Account__c != null){
                           addressIds.add(abp.Address_Code__c);
                           accountIds.add(abp.Account__c);
                       }
                }
                
                //fetch Address State details 
                if(addressIds.size() > 0){
                    for(Address__c address : [SELECT Id, State_Province__c , StateName__c 
                                              FROM Address__c 
                                              WHERE ID IN: addressIds AND State_Province__c  != '']){
                                                  addressMap.put(address.Id, address);                         
                                              }
                }
                
                //fetch Account details with relevant Tax Number records
                if(accountIds.size() > 0){
                    for(Account acc : [SELECT Id, (SELECT Id, State_Province__c, Business_Partner__c FROM Tax_Numbers__r WHERE State_Province__c != '') 
                                       FROM Account 
                                       WHERE Id IN: accountIds 
                                       AND IsPersonAccount = false]){
                                           if((acc.Tax_Numbers__r).size() > 0) {  
                                               AccountIdVsTaxNumbers.put(acc.Id, new list<Tax_Number__c>(acc.Tax_Numbers__r)); 
                                           }else {
                                               AccountIdVsTaxNumbers.put(acc.Id, new list<Tax_Number__c>());
                                           }                        
                                       } 
                }
                
                
                //Validate Address By BP records with Corresponding sold To Address & relevant Tax Number details
                for(Address_by_BP__c abpRecord : abpRecords){
                    Boolean showerror = false;
                    if(abpRecord.Address_Code__c != null && abpRecord.Sold_To__c 
                       && abpRecord.Account__c != null){
                           
                           if(!AccountIdVsTaxNumbers.isEmpty() && !addressMap.isEmpty() && AccountIdVsTaxNumbers.containsKey(abpRecord.Account__c)) {
                               //No tax number across Account is found: Show error
                               if(AccountIdVsTaxNumbers.get(abpRecord.Account__c).size() == 0){
                                   showerror = true;
                               }else{
                                   for(Tax_Number__c taxNumber : AccountIdVsTaxNumbers.get(abpRecord.Account__c)){
                                       //Iterate Tax number across the account to check for valid Tax number with Address's State code
                                       if((addressMap.get(abpRecord.Address_Code__c).State_Province__c).toUpperCase() == (taxNumber.State_Province__c).toUpperCase()){
                                           showerror = false;
                                           break;
                                       } else {
                                           showerror = true;
                                       }
                                   }
                               }
                           }
                           
                           if(showerror){
                               abpRecord.addError(System.Label.Tax_Number_error_for_Address + ' - ' + addressMap.get(abpRecord.Address_Code__c).StateName__c + '('+ addressMap.get(abpRecord.Address_Code__c).State_Province__c +')');
                           }
                       }
                }
            }catch(Exception ex){
                Logger.logError('AddressByBPTriggerHelper', 'validateTaxNumberForSelectedAddress', '', ex);
            }
        }
    }
        public void updateAddressByBPRecordTypeAndAccount(list<Address_by_BP__c> abpRecords){
            set<Id> branchIds = new set<Id>();
            set<Id> accountIds = new set<Id>();
            set<Id> b2bAccountIds = new set<Id>();
            map<Id, Id> branchIdVsAccountId = new map<Id, Id>();
            
            try{
                Id b2bRecordTypeId = Schema.SObjectType.Address_by_BP__c.getRecordTypeInfosByDeveloperName().get('B2B_Additional_Address').getRecordTypeId();
                Id b2cRecordTypeId = Schema.SObjectType.Address_by_BP__c.getRecordTypeInfosByDeveloperName().get('B2C_Additional_Address').getRecordTypeId();
                
                //DE752 :: Pawan :: Update Branch__c from Branch_Name__c selected/defaulting from user
                Set<String> branchNames = new Set<String>();
                Set<String> bpAccountIds = new Set<String>();
                Map<String,String> branchNameWithAccountIds = new Map<String,String>();
                
                for(Address_By_BP__c abp : abpRecords){
                    if(String.isNotBlank(abp.Branch_Name__c)){
                        branchNames.add(abp.Branch_Name__c);
                    }
                    
                    if(String.isNotBlank(abp.Account__c)){
                        bpAccountIds.add(abp.Account__c);
                    }
                } 
                
                if(!branchNames.isEmpty() && !bpAccountIds.isEmpty()){
                    Map<Id,Account> b2bAccounts = new Map<Id,Account>([Select Id FROM Account 
                                                                       WHERE Id IN: bpAccountIds 
                                                                       AND (RecordType.DeveloperName =: GlobalConstants.BUSINESS_ACCOUNT_RT
                                                                            OR RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER)]);
                    if(b2bAccounts.size() > 0 ){
                        List<Branch__c> branches = [Select Id,Branch_Name__c,Business_Partner__c 
                                                    FROM Branch__c 
                                                    WHERE Branch_Name__c IN:branchNames 
                                                    AND Business_Partner__c IN: b2bAccounts.keySet() ];
                        for(Branch__c bp : branches){
                            branchNameWithAccountIds.put(bp.Branch_Name__c+'-'+bp.Business_Partner__c,bp.Id);
                        }
                        for(Address_By_BP__c abp : abpRecords){
                            if(String.isNotBlank(abp.Branch_Name__c) 
                               && String.isBlank(abp.Branch__c)
                               && b2bAccounts.containsKey(abp.Account__c)
                               && (!branchNameWithAccountIds.containsKey(abp.Branch_Name__c+'-'+abp.Account__c)
                                   || ( branchNameWithAccountIds.containsKey(abp.Branch_Name__c+'-'+abp.Account__c)
                                       && branchNameWithAccountIds.get(abp.Branch_Name__c+'-'+abp.Account__c) == null))){
                                           abp.addError(System.Label.Branch_Record_Missing);
                                       }else if(String.isNotBlank(abp.Branch_Name__c) 
                                                && String.isBlank(abp.Branch__c)
                                                && b2bAccounts.containsKey(abp.Account__c)
                                                && branchNameWithAccountIds.containsKey(abp.Branch_Name__c+'-'+abp.Account__c)
                                                && branchNameWithAccountIds.get(abp.Branch_Name__c+'-'+abp.Account__c) != null){
                                                    abp.Branch__c = branchNameWithAccountIds.get(abp.Branch_Name__c+'-'+abp.Account__c);
                                                }
                        }
                    }                                                
                    
                }          
                
                for(Address_by_BP__c abp : abpRecords){
                    if(abp.Account__c == null && abp.Branch__c != null){
                        branchIds.add(abp.Branch__c);
                    }else if(abp.Account__c != null){
                        accountIds.add(abp.Account__c);
                    }
                }
                
                //fetch Account for Address By BP records
                if(branchIds.size() > 0){
                    for(Address_by_BP__c abpRec : [SELECT Branch__c,  Branch__r.Business_Partner__c
                                                   FROM Address_by_BP__c 
                                                   WHERE Branch__c IN: branchIds]){
                                                       branchIdVsAccountId.put(abpRec.Branch__c, abpRec.Branch__r.Business_Partner__c);                         
                                                       
                                                       //Add delta Account Ids
                                                       if(!accountIds.contains(abpRec.Branch__r.Business_Partner__c)){
                                                           accountIds.add(abpRec.Branch__r.Business_Partner__c);
                                                       }                         
                                                   }
                }
                
                //Fetch B2B Account details
                if(accountIds.size() > 0){
                    for(Account acc : [SELECT Id  
                                       FROM Account 
                                       WHERE Id IN: accountIds 
                                       AND IsPersonAccount = false]){
                                           b2bAccountIds.add(acc.Id); 
                                       }
                }
                
                
                for(Address_by_BP__c abp : abpRecords){
                    //Update Account
                    if(abp.Account__c == null && branchIdVsAccountId.containskey(abp.Branch__c)){
                        abp.Account__c = branchIdVsAccountId.get(abp.Branch__c);
                    }
                    
                    //Update Record Type
                    if((abp.Account__c != null  || (abp.Account__c == null && abp.Branch__c != null))
                       && b2bAccountIds.contains(abp.Account__c) 
                       && abp.RecordTypeId != b2bRecordTypeId){
                           abp.RecordTypeId = b2bRecordTypeId ;
                       } else if((abp.Account__c != null || (abp.Account__c == null && abp.Branch__c != null))
                                 && !b2bAccountIds.contains(abp.Account__c) 
                                 && abp.RecordTypeId != b2cRecordTypeId){
                                     abp.RecordTypeId = b2cRecordTypeId;
                                 } 
                }
            }catch(Exception ex){
                Logger.logError('AddressByBPTriggerHelper', 'updateAddressByBPRecordTypeAndAccount', '', ex);
            }
            
        }
        
        public void updateAccountNameOnAddressByBP(list<Address_By_BP__c> addresses){
            Set<Id> accountIds = new Set<Id>(); 
            Map<Id,Account> accountMap; 
            //Fetch AccountIds from Address records 
            for(Address_By_BP__c each : addresses){
                If(each.Account__c != Null){
                    accountIds.add(each.Account__c);
                }
            }
            //Create a map of Account and Name
            if(accountIds.size() > 0){
                accountMap = new Map<Id, Account>([SELECT Id, Name, FirstName, LastName, IsPersonAccount FROM Account WHERE Id IN :accountIds]);
            }
            //Update the address field
            try{
                for(Address_By_BP__c each : addresses){
                    if(accountMap.get(each.Account__c).isPersonAccount){
                        each.Account_Text__c = accountMap.get(each.Account__c).FirstName+' '+accountMap.get(each.Account__c).LastName;
                    }else{
                        each.Account_Text__c = accountMap.get(each.Account__c).Name;
                    }
                }
            }catch(Exception ex){
                Logger.logError('AddressByBPTriggerHelper', 'updateAccountNameOnAddressByBP', '', ex);
            }    
        }
        /*------------------------------------------------------------------------
Author:        Alpana Sahay
Company:       GITL
Description:   Method to get the Account and Branch details from the Address By BP details in SOAP Request and associate it either with existing account and branch or dummy account
Inputs:        List of Address By BP records
Test Class:    AddressByBPTriggerHelperTest
History
09-11-2022     Alpana Sahay    Initial Release.
29-11-2022     PSM     Modified.
----------------------------------------------------------------------------*/
        public void populateDefaults(list<Address_by_BP__c> abpRecords){

            Profile profile = [Select Id,Name from Profile where id=:Userinfo.getProfileId() ]; //Commented by Shreela on 7th Dec 2022

            if(profile.name==GlobalConstants.INTEGRATION_ADMINISTRATOR_PROFILE_NAME){
                List <String> lstBPCodes = New list <String>();
                List <String> lstBranchNames = New list <String>();
                Map<String,String> branchNameWithAccountIds = new Map<String,String>();
                Set<Id> setAccountId = new Set<Id>();
                
                for(Address_by_BP__c objAddressByBP : abpRecords) {     // fetch and store in resp lists 1) account code 2) branch code / name from Address by BP 
                    if(objAddressByBP.BPCode_AddressCode_LogisticCompany__c!=null && objAddressByBP.Account__c!=null){
                        System.debug('objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9) :'+(objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9));
                        System.debug('objAddressByBP.BPCode_AddressCode_LogisticCompany__c).right(4) :'+(objAddressByBP.BPCode_AddressCode_LogisticCompany__c).right(4));
                        System.debug('objAddressByBP.Account__c :'+objAddressByBP.Account__c);
                        lstBPCodes.add((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9));
                        lstBranchNames.add((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).right(4));
                        //setAccount.add(objAddressByBP.Account__c); 
                    }
                }
                //Make list of b2bAccounts and then make  Map<Id,String>
                /*map<id,Account> b2bAccounts = new map<id,Account>([Select Id,account_code__c  FROM Account WHERE //(Id in: setAccount
account_code__c in : lstBPCodes //)
AND (RecordType.DeveloperName =: GlobalConstants.BUSINESS_ACCOUNT_RT 
OR RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER)]);
setAccount.addAll(b2bAccounts.values());  */
                Map<String,id> b2bAccounts = new map<String,id>();
                
                List<Account> b2bAccountsList = [Select Id,account_code__c  FROM Account WHERE //(Id in: setAccount
                                                 account_code__c in : lstBPCodes //)
                                                 AND (RecordType.DeveloperName =: GlobalConstants.BUSINESS_ACCOUNT_RT 
                                                      OR RecordType.DeveloperName =: GlobalConstants.ACCOUNT_RECORDTYPE_DEALER)];
                for(Account b2bAcc : b2bAccountsList){
                    b2bAccounts.put(b2bAcc.account_code__c,b2bAcc.Id);
                }
                
                List<Branch__c> branches = [Select Id,Branch_Name__c,Business_Partner__c 
                                            FROM Branch__c 
                                            WHERE Branch_Name__c IN:lstBranchNames 
                                            AND Business_Partner__c IN: b2bAccounts.values() ]; //Changed from keySet to values by Shreela on 6th Dec 
                
                for(Branch__c objBranch : branches){
                    //System.debug('objBranch.Branch_Name__c :'+objBranch.Branch_Name__c);
                    //System.debug('objBranch.Business_Partner__c :'+objBranch.Business_Partner__c);
                    //System.debug('objBranch.Id :'+objBranch.Id);
                    branchNameWithAccountIds.put(objBranch.Branch_Name__c+'-'+objBranch.Business_Partner__c,objBranch.Id); 
                }
                
                
                for(Address_by_BP__c objAddressByBP : abpRecords) {
                    if( b2bAccounts.size()>0) { //Added by Shreela on 7th Dec 2022                                    
                        if (//(objAddressByBP.Account__c!=null && (b2bAccounts.containskey(objAddressByBP.Account__c))) &&   //Account exists 
                            //setAccount.contains((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9)) &&                  
                            b2bAccounts.containskey((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9)) &&
                            branchNameWithAccountIds.containsKey(((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).right(4))+'-'+b2bAccounts.get((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9)))){ //branch name exists
                                objAddressByBP.Account__c =b2bAccounts.get((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9)) ;
                                objAddressByBP.Branch_Name__c=(objAddressByBP.BPCode_AddressCode_LogisticCompany__c).right(4);
                                objAddressByBP.Branch__c = branchNameWithAccountIds.get(objAddressByBP.Branch_Name__c+'-'+b2bAccounts.get((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9)));
                            } 
                    }
                    /*else if (b2bAccounts.containskey((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9))){//only Account exists
associatedBranchEmpty = true;
objAddressByBP.Account__c =b2bAccounts.get((objAddressByBP.BPCode_AddressCode_LogisticCompany__c).substring(0,9));
//Should have been acc sf id not bp code
}*/
                    else {// Both Account and branch name dont exist
                        associatedBranchEmpty = true;
                        objAddressByBP.Account__c = System.Label.Dummy_Account;
                    }
                } 
            }
            //}
        }
    }