/*------------------------------------------------------------------------
Author:        Shailja Mishra
Company:       Salesforce
Description:   Responsible for creating PJP and Dealer Visit Records
Inputs:        NA
Test Class:    GeneratePJPBatchTest,GeneratePJPBatchTest2
---------------------------------------------------------------------------
History
07-05-2020      Shailja Mishra     Initial Release
06-11-2020      Shailja Mishra	   Added SalesChannel in keyVsNumberOfDealerVisits() for phase 3B 
06/10/2021      Pankaj Meshram	   Added Teammember Roles ASM,RSO,Visual Merchandiser in createPJPRecords()
----------------------------------------------------------------------------*/
global class GeneratePJPBatch implements Database.Batchable<AggregateResult>{
    global final String Query; 
    global List<PJP__c> pjps;
    global List<Dealer_Visit__c> dealerVisits;
    global String ACCOUNT_RECORDTYPE_DEALER = 'Dealer';
    global String ACCOUNT_RECORDTYPE_RETAILER = 'Retailer';
    global String DEALER_VISIT_RECORDTYPE_INTERIO_B2C = 'Interio_B2C';
    global String DEALER_VISIT_RECORDTYPE_APPLIANCES = 'Appliances'; 
    global String DEALER_VISIT_RECORDTYPE_SPARE_PARTS = 'Spare_Part_Dealer_Visit'; //Added by Pankaj on 06/10/2021
    global String DEALER_VISIT_RECORDTYPE_VISUAL_MERCHANDISER = 'Visual_Merchandiser'; //Added by Pankaj on 06/10/2021
    global static string INTERIO_BUSINESS_UNIT='W'; 
    global static string APPLIANCE_BUSINESS_UNIT = 'H';
    global string B2C_SUBDIVISION = 'B2C';
    global static string B2B_INTERIO_SUBDIVISION = 'B2B';
    global static String b2bInterioSubDivision = '%'+ B2B_INTERIO_SUBDIVISION + '%';
    global Id INTERIO_B2C_RECORDTYPE_ID = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get(DEALER_VISIT_RECORDTYPE_INTERIO_B2C).getRecordTypeId();
    global Id APPLIANCE_RECORDTYPE_ID = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get(DEALER_VISIT_RECORDTYPE_APPLIANCES).getRecordTypeId();
    global Id SPARE_PARTS_RECORDTYPE_ID = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get(DEALER_VISIT_RECORDTYPE_SPARE_PARTS).getRecordTypeId();//Added by Pankaj on 06/10/2021
    global Id VISUAL_MERCHANDISER_RECORDTYPE_ID = Schema.SObjectType.Dealer_Visit__c.getRecordTypeInfosByDeveloperName().get(DEALER_VISIT_RECORDTYPE_VISUAL_MERCHANDISER).getRecordTypeId();//Added by Pankaj on 06/10/2021
    global Set<String> buSubDivisionRoleKeys = new Set<String>();
    global Set<String> Roles =  new Set<String>(); 
    global List<BU_Role_Catego_Wise_Dealer_Visit_Records__mdt> categoryWiseMetadataRecords = new List<BU_Role_Catego_Wise_Dealer_Visit_Records__mdt>();
    global Map<String, Integer> keyVsNumberOfDealerVisits = new Map<String, Integer>();
    global GeneratePJPBatch() {
        categoryWiseMetadataRecords = [Select Id, Account_Team_Member_Role__c, Business_Unit__c, Dealer_Retailer_Category__c, Sales_Channel__c, Number_Of_Dealer_Visits__c 
                                       From BU_Role_Catego_Wise_Dealer_Visit_Records__mdt limit 999];
        for(BU_Role_Catego_Wise_Dealer_Visit_Records__mdt rec : categoryWiseMetadataRecords){
            Roles.add(rec.Account_Team_Member_Role__c);
            String salesChannel = String.isNotBlank(rec.Sales_Channel__c) ? rec.Sales_Channel__c : '';
            keyVsNumberOfDealerVisits.put(rec.Account_Team_Member_Role__c + '-' + rec.Business_Unit__c + '-' + rec.Dealer_Retailer_Category__c + salesChannel, Integer.valueOf(rec.Number_Of_Dealer_Visits__c));
        } 
        if(Roles.size() > 0)
            Query = 'select UserId, COUNT_DISTINCT(AccountID) From AccountTeamMember where TeamMemberRole IN: roles '
            +' AND ((Account.Business_Unit__c = :INTERIO_BUSINESS_UNIT AND (Account.Interio_Sub_Division__c != null AND (NOT Account.Interio_Sub_Division__c LIKE :b2bInterioSubDivision))) ' 
            +    ' OR Account.Business_Unit__c = :APPLIANCE_BUSINESS_UNIT) group by UserId';
        
    }
    
    global Iterable<AggregateResult> start(Database.BatchableContext BC){ 
        return new AggregateResultIterable(Query, Roles);  
    }  
    
    global Void execute(Database.BatchableContext jobId, List<sObject> aggregateATMRecords){
        createPJPRecords(aggregateATMRecords);
    }
    
    global Void finish(Database.BatchableContext jobId) {}
    
    void createPJPRecords(List<sObject> aggregateATMRecords) {
        Map<Id, List<Id>> userIdVsAccountIds = new Map<Id, List<Id>>();
        Set<Id> acctIds = new Set<Id>();
        Map<Id, Account> acctIdVsAccount = new Map<Id, Account>();
        Map<Id, User> userIdVsUser = new Map<Id, User>();
        Map<Id, String> userIdVsAccountTeamMemberRole = new Map<Id, String>();
        
        Set<Id> userIds = new Set<Id>();
        for(sObject atm: aggregateATMRecords){
            AggregateResult ar = (AggregateResult)atm;
            userIds.add((Id)ar.get('UserId'));  
        }
        
        for(User usr : [select Id, Name, Profile.Name, UserRoleId,UserRole.Name, Business_Unit__c, Sub_Division__c, Interio_Sub_Division__c
                        From User Where Id IN: userIds]){
                            userIdVsUser.put(usr.Id, usr);
                        }
        for (AccountTeamMember atm : [Select Id, AccountID, UserId, TeamMemberRole 
                                      From AccountTeamMember 
                                      where UserId IN: userIds and TeamMemberRole IN: roles]){                                          
                                          acctIds.add(atm.AccountID);                                           
                                          if(userIdVsAccountIds.containsKey(atm.UserId)){
                                              userIdVsAccountIds.get(atm.UserId).add(atm.AccountID);                                              
                                          }else{
                                              userIdVsAccountIds.put(atm.UserId, new List<Id>{atm.AccountID});                                              
                                          } 
                                          
                                          if(!userIdVsAccountTeamMemberRole.containsKey(atm.UserId)){
                                              userIdVsAccountTeamMemberRole.put(atm.UserId, atm.TeamMemberRole);
                                          }
                                      }
        for(Account acct : [Select Id, Name, Primary_Contact__c, Dealer_Category__c, Business_Unit__c, Sub_Division__c, Retailer_Category__c, Sales_Channel__c
                            From Account 
                            Where Id IN: acctIds 
                            And (RecordType.Name = :ACCOUNT_RECORDTYPE_DEALER OR RecordType.Name = :ACCOUNT_RECORDTYPE_RETAILER)
                            And ((Business_Unit__c = :INTERIO_BUSINESS_UNIT AND (Interio_Sub_Division__c != null AND (NOT Interio_Sub_Division__c LIKE :b2bInterioSubDivision))) 
                                 OR Business_Unit__c = :APPLIANCE_BUSINESS_UNIT)]){
                                     acctIdVsAccount.put(acct.Id, acct);
                                 }
        pjps = new List<PJP__c>();
        for(User user : userIdVsUser.values()){
            pjps.add(new PJP__c(
                Name = user.Name + '-' +
                (user.Business_Unit__c == INTERIO_BUSINESS_UNIT ? (String.isBlank(user.Interio_Sub_Division__c)?'':('-' + user.Interio_Sub_Division__c )) : '') +
                '-' + String.valueOf(Date.today().month()) + '-' + String.valueOf(Date.today().year())+'-'+ user.Business_Unit__c + '-' + user.Sub_Division__c,
                Business_Unit__c = user.Business_Unit__c,
                OwnerId = user.Id
            ));
        }
        
        try{
            if(pjps != null && pjps.size() > 0){
                insert pjps;
            }
            
            dealerVisits = new List<Dealer_Visit__c>();
            for(PJP__c pjp : pjps){
                List<Id> userAccountIds = userIdVsAccountIds.get(pjp.ownerId);               
                for(Id acctId : userAccountIds){                    
                    //check if AcctIdVsAccount map contains Account Id
                    if(acctIdVsAccount.containsKey(acctId)){
                        Integer recordsSize = numberOfRecordsToBeCreated(acctIdVsAccount.get(acctId), userIdVsAccountTeamMemberRole.get(pjp.ownerId));                            
                        for(Integer i = 0; i < recordsSize; i++){
                            Dealer_Visit__c dv = new Dealer_Visit__c();
                            dv.Name =
                                acctIdVsAccount.get(acctId).Name + '-' + userIdVsUser.get(pjp.ownerId).Name+
                                '-' + String.valueOf(Date.today().month()) + '-' + String.valueOf(Date.today().year()) +'-'+ 
                                (String.isBlank(acctIdVsAccount.get(acctId).Dealer_Category__c) ? '' : (acctIdVsAccount.get(acctId).Dealer_Category__c ) ) +
                                (String.isBlank(acctIdVsAccount.get(acctId).Retailer_Category__c) ? '' : (acctIdVsAccount.get(acctId).Retailer_Category__c ) ) ; 
                            dv.PJP__c = pjp.Id;
                            dv.Account_Information__c = acctId;
                            dv.Visit_Due_Date__c = datetime.now() + 2;
                            dv.Intent__c = 'true';
                            dv.OwnerId = pjp.OwnerId;
                            if(acctIdVsAccount.get(acctId).Primary_Contact__c != null ) 
                                dv.Contact_Information__c = acctIdVsAccount.get(acctId).Primary_Contact__c;
                            if(acctIdVsAccount.get(acctId).Business_Unit__c == INTERIO_BUSINESS_UNIT){
                                dv.RecordTypeId = INTERIO_B2C_RECORDTYPE_ID;
                            }
                            system.debug(acctIdVsAccount);
                            if(acctIdVsAccount.get(acctId).Business_Unit__c == APPLIANCE_BUSINESS_UNIT){
                                //Added by pankaj on 06/10/2021 for assigning different pageout for auto PJP generation 
                                
                                if(userIdVsAccountTeamMemberRole.get(pjp.OwnerId) ==GlobalConstants.ACCOUNT_TEAM_MEMBER_ROLE_ASM || userIdVsAccountTeamMemberRole.get(pjp.OwnerId) ==GlobalConstants.ACCOUNT_TEAM_MEMBER_ROLE_RSO){
                                    dv.RecordTypeId = APPLIANCE_RECORDTYPE_ID;
                                }
                                if(userIdVsAccountTeamMemberRole.get(pjp.OwnerId) ==GlobalConstants.SALES_SERVICE_MANAGER_ROLE){
                                    dv.RecordTypeId = SPARE_PARTS_RECORDTYPE_ID;
                                }
                                if(userIdVsAccountTeamMemberRole.get(pjp.OwnerId) ==GlobalConstants.ACCOUNT_TEAM_MEMBER_ROLE_VM){
                                    dv.RecordTypeId = VISUAL_MERCHANDISER_RECORDTYPE_ID;
                                }
                            }
                            //end by pankaj
                            
                            //add dealer visit to List
                            dealerVisits.add(dv);
                        }
                    }
                }    
            }
            if(dealerVisits != null && dealerVisits.size() > 0)
                insert dealerVisits;
        }catch(Exception ex){
        }
    }
    
    integer numberOfRecordsToBeCreated(Account acc, String pjpOwnerRole){
        String dealer_retailer_category = (String.isBlank(acc.Dealer_Category__c) ? '' : ('Dealer- ' + acc.Dealer_Category__c) ) +
            (String.isBlank(acc.Retailer_Category__c) ? '' : ('Retailer- ' + acc.Retailer_Category__c) );
        String salesChannel = pjpOwnerRole.contains('Merchandiser') && String.isNotBlank(acc.Sales_Channel__c) ? acc.Sales_Channel__c : '';
        //key to Map Custom metadata records
        String key = pjpOwnerRole + '-' + acc.Business_Unit__c + '-'+ dealer_retailer_category + salesChannel;
        if(keyVsNumberOfDealerVisits.containsKey(key)){
            return keyVsNumberOfDealerVisits.get(key);
        }
        return 1;
    }
}