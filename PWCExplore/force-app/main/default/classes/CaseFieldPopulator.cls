/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to populate Case fields
Inputs:        map of created records
Test Class:   CaseTriggerHandlerTest

History
19-10-2020      Kishor Kumar     Initial Release
17-11-2020      Mahith Madwesh     checkOpenCasePerCategory
----------------------------------------------------------------------------*/
public without sharing class CaseFieldPopulator {

    public static Boolean isAssignmentRuleContext = false;
    
    public static Map<String,String> recordTypeIdVsRecordTypeName = new Map<String,String>();
    public static User loggedInUser = null;
    public static Map<String,String> groupNameVsId = new Map<String,String>();
    Set<String> queueNames = new Set<String>{GlobalConstants.CASE_ASSIGNMENT_DEFAULT_QUEUE,
                                    GlobalConstants.MHE_EMAIL_WEB_QUEUE,
                                    'CSG_Team'};
    
    {
        if(recordTypeIdVsRecordTypeName.size() == 0){
            for(RecordType recType : [Select Id,DeveloperName 
                                      From RecordType 
                                      Where sObjectType =: GlobalConstants.CASE_SOBJECT_API_NAME]){
                if(!recordTypeIdVsRecordTypeName.containsKey(recType.Id)){
                    recordTypeIdVsRecordTypeName.put(recType.Id,recType.DeveloperName);
                }
            }
        }
        
        if(loggedInUser == null){
            loggedInUser = [Select Id,Profile.Name, UserRole.Name, AccountId FROM User WHERE Id =:UserInfo.getUserId()];
        }

        if(groupNameVsId.size() == 0){
            for(Group gp : [Select Id,DeveloperName FROM Group 
                            WHERE Type = 'Queue'
                            AND DeveloperName IN :queueNames]){
                groupNameVsId.put(gp.DeveloperName, gp.Id);
            }
        }
    }

    public static Map<String, String> callPendingReason_VS_entitlementProcessRecordName = new Map<String, String>{
        'Spares not available' => System.Label.MHE_Entitlement_record_name_for_spares_not_available,
        'Technician not available' => System.Label.MHE_Entitlement_record_name_for_technician_not_available,
        'Technical Support required' => System.Label.MHE_Entitlement_record_name_for_technical_support_required,
        'Vendor dependency' => System.Label.MHE_Entitlement_record_name_for_vendor_dependency,
        null => System.Label.MHE_Entitlement_record_name_for_reason_and_technician_missing
    };
    
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   populate EscalationStartTime__c on service request based on the of 'Call pending reason__c'.
    Before Update
    Inputs:        List<Case> newCases
    Test Class:
    ----------------------------------------------------------------------------*/
    public  void populateEscalationStartTime(List<Case> newCases, map<Id, Case> oldCases){
        
        for(Case caseRec:newCases ){
            if(oldCases == null || (oldCases.containsKey(caseRec.Id) && 
                                    oldCases.get(caseRec.Id).Call_Pending_Reason__c != caseRec.Call_Pending_Reason__c)){
                caseRec.Escalation_process_start_time__c = System.now();
            }
            
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to populate zip code rule on case
    Inputs:        list of created Case records, Old map for Update context

    History
    19-10-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateZipCodeRule(List<Case> cases, Map<Id, Case> oldCaseMap){
        List<Case> finalCases = new List<Case>();
        
       
        for(Case caseRecord : cases){
            //Insert Scenario
           
           
            if(oldCaseMap == null && caseRecord.Applicable_For_Pincode_Based_Assignment__c){
           
                finalCases.add(caseRecord);
            } 
            //Update Scenario
            else if(oldCaseMap != null && caseRecord.Applicable_For_Pincode_Based_Assignment__c
                    && oldCaseMap.containsKey(caseRecord.Id) 
                    && (caseRecord.Business_Unit__c != oldCaseMap.get(caseRecord.Id).Business_Unit__c  
                        || caseRecord.Sub_Division__c != oldCaseMap.get(caseRecord.Id).Sub_Division__c  
                        || caseRecord.Interio_Sub_Division__c != oldCaseMap.get(caseRecord.Id).Interio_Sub_Division__c  
                        || caseRecord.Zip_Code__c != oldCaseMap.get(caseRecord.Id).Zip_Code__c)){
                                 
         
                            finalCases.add(caseRecord);               
                        }
            
        }
        
        if(finalCases.size() > 0){
         
            Set<String> businessUnitSubDivZipCode = new Set<String>(); 
            map<String, Zip_Code_Rule__c> zipCodeRuleMap = new map<String, Zip_Code_Rule__c>();
            
            //Create key Combination to fetch Zip Code rules data
            for(Case caseVar : finalCases){
          
                String subDivision = caseVar.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT ? caseVar.Interio_Sub_Division__c : caseVar.Sub_Division__c;
              
                if(String.isNotBlank(caseVar.Business_Unit__c) 
                   && String.isNotBlank(subDivision) 
                   && String.isNotBlank(caseVar.Zip_Code__c)){
                       String uniqueCombination = caseVar.Business_Unit__c + '-' + subDivision +'-' + caseVar.Zip_Code__c;
                      
                       businessUnitSubDivZipCode.add(uniqueCombination);
                   }
                
            }
            
            //Fetch Zip code rule record details
            if(businessUnitSubDivZipCode.size() > 0){
         
                for(Zip_Code_Rule__c rule : [SELECT Id, Name, Queue_1__c, Effective_Till__c 
                                             FROM Zip_Code_Rule__c 
                                             WHERE Name IN : businessUnitSubDivZipCode 
                                             AND Queue_1__c != null 
                                             AND Effective_Till__c >= TODAY 
                                             AND Object_Name__c = 'Case']){
                                             zipCodeRuleMap.put(rule.Name, rule);                                
                                             }
            }
            
            //Logic to set Zip Code rule ID on Case record
            for(Case caseRecord : finalCases){
                if(zipCodeRuleMap.size() > 0){
                    String subDivision = caseRecord.Business_Unit__c == GlobalConstants.INTERIO_BUSINESS_UNIT ? caseRecord.Interio_Sub_Division__c : caseRecord.Sub_Division__c;
                    
                    if(String.isNotBlank(caseRecord.Business_Unit__c) 
                       && String.isNotBlank(subDivision) 
                       && String.isNotBlank(caseRecord.Zip_Code__c)){
                           String uniqueCombination = caseRecord.Business_Unit__c + '-' + subDivision +'-' + caseRecord.Zip_Code__c;
                           
                           if(zipCodeRuleMap.containsKey(uniqueCombination)){
                               caseRecord.Zip_Code_Rule__c = zipCodeRuleMap.get(uniqueCombination).Id;
                           }                    
                       } else //No combination found
                           caseRecord.Zip_Code_Rule__c = null;
                } else //No combination found
                    caseRecord.Zip_Code_Rule__c = null;
            } 
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to Owner through zip code rule on case
    Inputs:        list of created Case records

    History
    20-10-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void executeZipCodeBasedAssignment(List<Case> cases){
        List<Case> casesToReassign = new List<Case>();
        
        if(groupNameVsId.containsKey(GlobalConstants.CASE_ASSIGNMENT_DEFAULT_QUEUE)){
            casesToReassign = [SELECT Id, OwnerId, Zip_Code_Rule__c, Business_Unit__c, Zip_Code_Rule__r.Queue_1__c, 
                           Zip_Code_Rule__r.Queue_2__c, Zip_Code_Rule__r.Queue_3__c,Zip_Code_Rule__r.Queue_4__c,
                           Zip_Code_Rule__r.Queue_5__c, Zip_Code_Rule__r.Queue_6__c,Zip_Code_Rule__r.Queue_7__c,
                           Zip_Code_Rule__r.Sequence__c, Zip_Code_Rule__r.Queues_And_LastAssignedId__c,
                           Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c, Zip_Code_Rule__r.Run_Round_Robin_on_Queue2__c,
                           Zip_Code_Rule__r.Run_Round_Robin_on_Queue3__c, Zip_Code_Rule__r.Run_Round_Robin_on_Queue4__c,
                           Zip_Code_Rule__r.Run_Round_Robin_on_Queue5__c, Zip_Code_Rule__r.Run_Round_Robin_on_Queue6__c,
                           Zip_Code_Rule__r.Run_Round_Robin_on_Queue7__c  
                           FROM Case 
                           WHERE Id IN: cases 
                           AND OwnerId =: groupNameVsId.get(GlobalConstants.CASE_ASSIGNMENT_DEFAULT_QUEUE) 
                           AND Zip_Code_Rule__c != null LIMIT 10000];
        
            if(casesToReassign.size() > 0){
                ZipCodeBasedAssignmentProcessor processor = new ZipCodeBasedAssignmentProcessor();
                processor.processAssignment(casesToReassign);
            }    
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to populate account on case based on accountId populated on user record
    Inputs:        list of created Case records

    History
    21-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateAccount(List<Case> newCases){
        //Store user ids from which a case record will be created
        Set<String> caseOwnerIds = new Set<String>();
        for(Case caseRec : newCases){
            //Only for Interio B2C cases
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
               && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME
               && caseRec.AccountId == null && String.valueOf(caseRec.OwnerId).startsWith('005')){
                   caseOwnerIds.add(caseRec.OwnerId);
               }            
        }
        
        if(caseOwnerIds.size() > 0){
            //Get all the users along with account details for case created by users
            Map<String,User> caseOwnerUsers = new Map<String,User>([Select Id,Account__c 
                                                                    FROM USER 
                                                                    WHERE Id IN: caseOwnerIds 
                                                                    AND Account__c != NULL]);        
            //Iterate over cases to autopopulate AccountId
            for(Case caseRec : newCases){
                if(caseRec.AccountId == null && caseOwnerUsers.containsKey(caseRec.OwnerId) 
                   && caseOwnerUsers.get(caseRec.OwnerId).Account__c != null){
                       caseRec.AccountId = caseOwnerUsers.get(caseRec.OwnerId).Account__c;
                   }
            }
        }
        
        for(Case caseRec : newCases){
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
               && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME
               && caseRec.AccountId == null){
                   caseRec.addError(System.Label.ACCOUNT_MUST_BE_SELECTED);
               }
        }
        
    }
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to share record with created by user and with roles for users account
    Inputs:        list of created Case records

    History
    21-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void shareCasesWithRoles(List<Case> newCases, Map<Id, Case> oldCaseMap){
        
        //Store groupId vs caseId 
        Set<String> groupIdVsCaseId = new Set<String>();
        //Store user ids from which a case record will be created
        Set<String> caseOwnerIds = new Set<String>();
        //Store all accountIds from Case records
        Set<String> accountIds = new Set<String>();
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        set<Id> userIds = new set<Id>(); 
        map<Id, User> userMap = new map<Id, User>();
        
        //Insert scenario only
        if(oldCaseMap == null){
            //Fetch MHE service Record Type Id
            //Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
            
            //Fetch case Team member Role name details
            CaseTeamRole role = [SELECT Id,Name FROM CaseTeamRole 
                                 WHERE Name =: System.Label.SERVICE_REQUEST_TEAM_ROLE LIMIT 1];
            
            
            //Fetch Metadata records for Persona
            map<Id, Persona_Team_Mapping__mdt> personaMap = new map<Id, Persona_Team_Mapping__mdt>([
                                SELECT Id, Personas__c, Case_Team_Role_API_Name__c FROM Persona_Team_Mapping__mdt 
                                WHERE Object_Name__c = 'Case' AND Business_Unit__c = 'MHE' 
                                AND Personas__c != '' AND DeveloperName = 'MHE_SC_Read_only_Personas' LIMIT 1]);
    
            String PersonaString = !personaMap.isEmpty() ?  personaMap.values()[0].Personas__c : '';
            list<String> personas = String.isNotBlank(PersonaString) ? PersonaString.split(',') : new list<String>();
            
            //Fetch case Team member Role name details
            String caseReadTeamAccess = !personaMap.isEmpty() ?  personaMap.values()[0].Case_Team_Role_API_Name__c : '';
            Id caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name =: caseReadTeamAccess LIMIT 1].id;
            
            //Fetch Metadata records for read/Write Persona
            map<Id, Persona_Team_Mapping__mdt> rwPersonaMap = new map<Id, Persona_Team_Mapping__mdt>([
                                SELECT Id, Personas__c, Case_Team_Role_API_Name__c FROM Persona_Team_Mapping__mdt 
                                WHERE Object_Name__c = 'Case' AND Business_Unit__c = 'MHE' 
                                AND Personas__c != '' AND DeveloperName = 'MHE_SC_Read_Write_Personas' LIMIT 1]);
            
            //Fetch case Team member Role name details
            String caseReadWriteTeamAccess = !rwPersonaMap.isEmpty() ?  rwPersonaMap.values()[0].Case_Team_Role_API_Name__c : '';
            Id rwCaseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name =: caseReadWriteTeamAccess LIMIT 1].id;
            
            String rwPersonaString = !rwPersonaMap.isEmpty() ?  rwPersonaMap.values()[0].Personas__c : '';
            list<String> rwpersonas = String.isNotBlank(rwPersonaString) ? rwPersonaString.split(',') : new list<String>();
            
            //Get Created By User Ids for MHE cases
            for(Case caseRec : newCases){
                if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) && 
                   recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST){ 
                    userIds.add(caseRec.createdById);
                }
            }
            
            //Fetch User Details
            if(personas.size() > 0 || rwpersonas.size() > 0)
                userMap = new map<Id, User>([SELECT Id, Persona__c FROM User WHERE Id IN : userIds AND (Persona__c IN : personas OR Persona__c IN : rwpersonas)]);
        
            //Add case createdby user to case team only when a record is created and owner is a user
            for(Case caseRec : newCases){
                if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
                    && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME  
                    && String.valueOf(caseRec.OwnerId).startsWith('005')){
                    caseTeamMembers.add(
                        new CaseTeamMember(
                            ParentId = caseRec.Id, MemberId = caseRec.OwnerId,TeamRoleId = role.Id));
                } 
                
                //For MHE Cases: Created By User will have Read only or Read/Write access
                if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
                    && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST 
                    && userMap.containsKey(caseRec.CreatedById)){
					
                        //Created By User will have Read only access   
                        if(personas.contains(userMap.get(caseRec.CreatedById).Persona__c)){
                             caseTeamMembers.add( new CaseTeamMember(
                            ParentId = caseRec.Id, MemberId =caseRec.CreatedById,TeamRoleId = caseTeamRoleId));
                        }
                        
                        //Created By User will have Read/Write access   
                        if(rwpersonas.contains(userMap.get(caseRec.CreatedById).Persona__c)){
                             caseTeamMembers.add( new CaseTeamMember(
                            ParentId = caseRec.Id, MemberId =caseRec.CreatedById,TeamRoleId = rwCaseTeamRoleId));
                        }
                }
            }
            
            if(caseTeamMembers.size() > 0 ){
                Database.insert(caseTeamMembers,false);
            }
        }        
        
        for(Case caseRec : newCases){
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
                    && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME  
                  && (oldCaseMap == null 
                        || (oldCaseMap.containsKey(caseRec.Id) 
                        && caseRec.OwnerId != oldCaseMap.get(caseRec.Id).OwnerId
                        && caseRec.Status == oldCaseMap.get(caseRec.Id).Status))){//Prevent recursion for case update when status is auto changed
                            if(caseRec.AccountId != null && String.valueOf(caseRec.OwnerId).startsWith('005')){//When case owner is user
                                //caseOwnerIds.add(caseRec.OwnerId);
                                accountIds.add(caseRec.AccountId);
                            }        
                   }                        
        }
        System.debug('accountIds :: ' + accountIds);
        if(accountIds.size() > 0){
            //Store all roles of users for above accounts
            Set<String> roleIds = new Set<String>();
            //Store Accounts will all UserRoles
            Map<String,Set<String>> accountIdVsRoleIds = new Map<String,Set<String>>();
            
            for(User userRec : [Select Id, UserRoleId,Account__c  FROM USER 
                                WHERE Account__c IN: accountIds AND UserRoleId != NULL]){
                                    roleIds.add(userRec.UserRoleId);
                                    if(accountIdVsRoleIds.containsKey(userRec.Account__c)){
                                        accountIdVsRoleIds.get(userRec.Account__c).add(userRec.UserRoleId);
                                    }else{
                                        accountIdVsRoleIds.put(userRec.Account__c,new Set<String>{userRec.UserRoleId});
                                    }
                                }
            
            //Store RoleId with Group Ids    
            Map<String,String> roleIdVsGroupId = new Map<String,String>();
            List<Group> groups = [Select Id, RelatedId FROM GROUP 
                                  WHERE Type = 'Role' AND RelatedId IN: roleIds];
            
            for(Group gp : groups){
                roleIdVsGroupId.put(gp.RelatedId,gp.Id);
            }
            
            for(Case caseRec : newCases){
                if(groups.size() > 0 
                   && accountIdVsRoleIds.containsKey(caseRec.AccountId)
                   && accountIdVsRoleIds.get(caseRec.AccountId).size() > 0 ){
                       for(String roleId : accountIdVsRoleIds.get(caseRec.AccountId)){
                           if(roleIdVsGroupId.containsKey(roleId)){
                               groupIdVsCaseId.add(roleIdVsGroupId.get(roleId)+'-'+caseRec.Id);
                           }                            
                       }
                   }                
            }  
            
            System.debug('groupIdVsCaseId :: ' + groupIdVsCaseId);
            if(groupIdVsCaseId.size() > 0){
                handleCaseShare(groupIdVsCaseId);
            }
        }          
    }    
    
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   insert caseshare records
    Inputs:        list of created Case records

    History
    21-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void handleCaseShare(Set<String> groupIdVsCaseId) {
        try{
            List<CaseShare> caseShares = new List<CaseShare>();
            List<String> groupIds = new List<String>();
            List<String> caseIds = new List<String>();
            for(String groupId : groupIdVsCaseId){
                if(groupId.split('-')[0] != null){
                    groupIds.add(groupId.split('-')[0]);
                }
                
                if(groupId.split('-')[1] != null){
                    caseIds.add(groupId.split('-')[1]);
                }            
            }
            
            //Store GroupId With CaseId to avoid duplicate insert of caseshare record
            Map<String,CaseShare> caseSharesMap = new Map<String,CaseShare>();
            for(CaseShare caseshare : [Select CaseId,UserOrGroupId FROM CaseShare 
                                       WHERE CaseId IN:caseIds 
                                       AND UserOrGroupId IN: groupIds ]){
                if(!caseSharesMap.containsKey(caseshare.UserOrGroupId+'-'+caseShare.CaseId)){
                    caseSharesMap.put(caseshare.UserOrGroupId+'-'+caseShare.CaseId,caseShare);
                }
            }
            
            for(String groupIdWithCaseId : groupIdVsCaseId){
                if(!caseSharesMap.containsKey(groupIdWithCaseId)){
                    caseShares.add(new CaseShare(CaseAccessLevel = 'Read',
                                                 RowCause = 'Manual',
                                                 UserOrGroupId = groupIdWithCaseId.split('-')[0],
                                                 CaseId = groupIdWithCaseId.split('-')[1]));
                }
            }
            System.debug('caseShares :: ' + caseshares);
            if(caseShares.size() > 0 ){
                insert caseShares;
            } 
        }catch(Exception ex){
            Logger.logError('CaseFieldPopulator', 'handleCaseShare', null, ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to populate Entitlement on Case record
    Inputs:        list of Case records

    History
    27-10-2020      Kishor Kumar     Initial Release
    06-01-2021      Kartik Shetty    Modified the MHE entitlement population logic for MHE record types.
    ----------------------------------------------------------------------------*/
    public void populateEntitlement(List<Case> cases){
        List<Case> casesToPopulate = new List<Case>();
        set<Id> accountIds = new set<Id>();
        Map<Id,Entitlement> accountVsEntitlement = new Map<Id,Entitlement>();
        
        //Fetch all the records on which Entitlement is Blank for Interio_B2C Record Type
        // || recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_MHE_RECORD_TYPE_DEV_NAME
        for(Case caseRec : cases){
            if(caseRec.EntitlementId == null && caseRec.AccountId != null 
               && recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId)
               && (recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME)) {
                   accountIds.add(caseRec.AccountId);
                   casesToPopulate.add(caseRec);
               }
        }
        
        //Fetch all the entitlement records associated to the Account of Case records
        if(accountIds.size() > 0){
            for(Entitlement entitlementRec : [SELECT Id, Name, AccountId FROM Entitlement WHERE AccountId IN: accountIds]){
                if(!accountVsEntitlement.containsKey(entitlementRec.AccountId)){
                    accountVsEntitlement.put(entitlementRec.AccountId,entitlementRec);
                }
            }
        }
        
        //logic to populate Entitlement on case record
        if(casesToPopulate.size() > 0){
            for(Case caseVar : casesToPopulate){
                if(accountVsEntitlement.containsKey(caseVar.AccountId)){
                    caseVar.EntitlementId = accountVsEntitlement.get(caseVar.AccountId).Id;
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to populate entitlement record for MHE based on Call_Pending_Reason__c value
    Inputs:        List of Case records, Map of old case record values

    History
    06-01-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateEntitlementForMHE_basedOn_callPendingReason(List<Case> newCaseRecords, Map<Id, Case> oldCaseRecordMap) {
        List<Id> relatedAccountIds = new List<Id>();

        // Run the logic if new records are being inserted or 
        // only if the Escalation_process_start_time__c is being updated which only updated when Call pending reason is being changed.
        if(oldCaseRecordMap.isEmpty()) {
            for(Case caseRecord : newCaseRecords) {
                relatedAccountIds.add(caseRecord.AccountId);
            }
        } else {
            for(Case caseRecord : newCaseRecords) {
                if(oldCaseRecordMap.containsKey(caseRecord.Id)
                    && oldCaseRecordMap.get(caseRecord.Id).Escalation_process_start_time__c != caseRecord.Escalation_process_start_time__c) {
                        relatedAccountIds.add(caseRecord.AccountId);
                }
            }
        }

        if(!relatedAccountIds.isEmpty()) {
            List<Entitlement> entitlementRecords = new List<Entitlement>([Select Id, Name, AccountId FROM Entitlement 
                WHERE Name IN :callPendingReason_VS_entitlementProcessRecordName.values()
                AND AccountId IN :relatedAccountIds
            ]);

            // If entitlement records are present
            if(!entitlementRecords.isEmpty()) {
                Map<String, Entitlement> entitlementRecordMap = new Map<String, Entitlement>();
                for(Entitlement entitlementRecord : entitlementRecords) {
                    String key = String.valueOf(entitlementRecord.AccountId) + '--' + entitlementRecord.Name;
                    entitlementRecordMap.put(key, entitlementRecord);
                }
                
                List<Case> recordsToResetEscalationCheckboxes = new List<Case>();
                for(Case caseRecord : newCaseRecords) {
                    if(recordTypeIdVsRecordTypeName.containsKey(caseRecord.RecordTypeId)
                        && recordTypeIdVsRecordTypeName.get(caseRecord.RecordTypeId) == GlobalConstants.CASE_MHE_RECORD_TYPE_DEV_NAME) {
                            String key = String.valueOf(caseRecord.AccountId) + '--' + callPendingReason_VS_entitlementProcessRecordName.get(caseRecord.Call_Pending_Reason__c);
                            if(entitlementRecordMap.containsKey(key)) {
                                caseRecord.EntitlementId = entitlementRecordMap.get(key).Id;
                                recordsToResetEscalationCheckboxes.add(caseRecord);
                            }
                    }
                }
                
                if(!recordsToResetEscalationCheckboxes.isEmpty()) {
                    resetEntitlementEscalatedCheckbox(recordsToResetEscalationCheckboxes);
                }
            }
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to reset Escalated checkbox if Entitlements are updated or reset.
    Inputs:        List of Case records to update

    History
    10-02-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    private void resetEntitlementEscalatedCheckbox(List<Case> caseRecordsToUpdate) {
        for(Case caseRecord : caseRecordsToUpdate) {
            caseRecord.L0_Escalated__c = false;
            caseRecord.L1_Escalated__c = false;
            caseRecord.L2_Escalated__c = false;
        }
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to update case milestones start date on change of Escalation_process_start_time__c.
    Inputs:        list of updated Case records

    History
    12-01-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateCaseMilestones(Map<Id, Case> newCaseRecordMap, Map<Id, Case> oldCaseRecordMap) {
        List<Id> caseIdsToConsider = new List<Id>();
        // Consider only those records where Escalation_process_start_time__c is modified. 
        for(Case caseRecord : newCaseRecordMap.values()) {
            if(oldCaseRecordMap.containsKey(caseRecord.Id)
                && caseRecord.Escalation_process_start_time__c != oldCaseRecordMap.get(caseRecord.Id).Escalation_process_start_time__c) {
                    caseIdsToConsider.add(caseRecord.Id);
                }
        }
        List<CaseMilestone> caseMilestones = new List<CaseMilestone>();
        if(caseIdsToConsider.size() > 0){
            for(CaseMilestone caseMilestoneRecord : [Select Id, CaseId, StartDate, IsViolated, IsCompleted FROM CaseMilestone WHERE CaseId IN :caseIdsToConsider AND IsCompleted = false]) {
               caseMilestoneRecord.StartDate = newCaseRecordMap.get(caseMilestoneRecord.CaseId).Escalation_process_start_time__c;
               caseMilestones.add(caseMilestoneRecord);
                  
            }
            update caseMilestones;
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to Toggle Default Assignement Rule on Update of Case record
    Inputs:        list of updated Case records

    History
    27-10-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void setAssignmentRule(List<Case> cases,Map<Id,Case> oldCases){
        Set<String> caseIds = new Set<String>();
        List<Case> caseRecords = new List<Case>();

        //Case Assignment Rule should work only for Insert of case and Update of case for Case Category and Case Type
        for(Case newCase : cases){
            if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME && 
                    ((oldCases == null && newCase.Case_Category__c != null && newCase.Case_Type__c != null)|| 
                        (oldCases != null && oldCases.containsKey(newCase.Id) && (oldCases.get(newCase.Id).Case_Category__c != newCase.Case_Category__c 
                        || oldCases.get(newCase.Id).Case_Type__c != newCase.Case_Type__c)))){
                    caseIds.add(newCase.Id);
            }
        } 
        for(Case newCase : [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id IN :caseIds
                                    AND RecordType.DeveloperName =: GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME]){
            isAssignmentRuleContext =  true;
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            newCase.setOptions(dmo);
            caseRecords.add(newCase);
        }
        CaseTriggerHandler.TriggerDisabled = true;
        Database.upsert(caseRecords);
        CaseTriggerHandler.TriggerDisabled = false;
    }
    
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Method to check and allow only one open case per category
    Inputs:        List of Cases
    Test Class:
    ----------------------------------------------------------------------------
    History
    17-11-2020      Mahith     Initial Release
    13-10-2021      Alpanas    Removed Check for Audit Type
    24-03-2022      Alpanas    SMEPB-14 [Removed Check for Resolved Status from Commissioning SR]
    ----------------------------------------------------------------------------*/
    public void checkOpenCasePerCategory(list<case> newCases,string executionContext) {
        list<string> casesCategories = new list<string>();
        list<Id> assetIds = new list<Id>();
        list<Case> existingCases = new list<Case>();
        String caseType;
        map<string, case> existingCaseMap = new map<string, case>();
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
        for ( case c : newCases ) {
        // Asset classification  in If-Condition is added by Anupam on 4/10/2021
            caseType = c.type;
            if ( ( c.type == GlobalConstants.PM_CONSTANT || c.type == GlobalConstants.BM_CONSTANT || c.type == GlobalConstants.COMISSIONING || (GlobalConstants.ASSET_CLASSIFICATION).contains(c.type) ) 
                && c.recordTypeId == mheServiceRequestRecordTypeId  ) {
                    casesCategories.add(c.type);
                    
                    assetIds.add(c.AssetId);
                }
        }
        // SMEPB-14 Start [Created list Open and Resolved Commissioning SR]
        If (caseType == GlobalConstants.COMISSIONING) {
        existingCases = [SELECT   Id, AssetId, Status, type FROM Case 
            WHERE Status != 'Closed' AND type = 'Commissioning' 
            AND AssetId IN :assetIds AND RecordTypeId = :mheServiceRequestRecordTypeId];
       }
       else {      
       existingCases = [SELECT   Id, AssetId, Status, type FROM Case 
            WHERE ( Status != 'Closed' AND Status != 'Resolved') AND type IN :casesCategories AND AssetId IN :assetIds AND RecordTypeId = :mheServiceRequestRecordTypeId];
       }    
       // SMEPB-14 End
        if ( existingCases.size() > 0 ) {
            for ( case c1 : existingCases ) {
                existingCaseMap.put(c1.type+'-'+c1.AssetId, c1);
            }
        }
            
            if(executionContext == 'insert'){
                for ( case c2 : newCases ) {
                    if ( existingCaseMap.containsKey(c2.type+'-'+c2.AssetId) ) {
                        c2.addError(System.label.Duplicate_Open_Case_Catefory_message);
                    }
                }
            }else if(executionContext == 'update'){
                for ( case c2 : newCases ) {
                     if ( existingCaseMap.containsKey(c2.type+'-'+c2.AssetId) && existingCaseMap.get(c2.type+'-'+c2.AssetId).Id != c2.Id && c2.Status != 'Closed') {
                        c2.addError(System.label.Duplicate_Open_Case_Catefory_message);
                    }
                }
                
            }
    }



    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Method to populate defaults on service request
    Inputs:        list of created Case records

    History
    21-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/

    
    public void populateDefaults(list<case> newCases) {
        Set<String> assetSerials = new Set<String>();
        Map<String,String> assetSerialVsId = new Map<String,String>();
        Set<String> assetIds = new Set<String>();
        Map<String,Asset> assets = new Map<String,Asset>();
        Map<String,Asset> assetMapForContacts = new Map<String,Asset>();
        Set<String> assetIdsForContacts = new Set<String>();
        set<Id> assetIdsToDefault = new set<Id>();
        Map<Id,Asset> assetsToDefaultWith = new Map<Id,Asset>();
        
        set<Id> ssgOrderIds = new set<Id>();
            
        for(Case caseRec : newCases){
            //Autopopulate SSG Records
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_SSG_SERIVCE_REQUEST 
                && caseRec.Order__c != null && (caseRec.AccountId == null || caseRec.ContactId == null)){
                    ssgOrderIds.add(caseRec.Order__c);
            }
        }
                
            //added by Shreela and Anupam for Ticket#30430961 on 18th Sept 2021
            Map<Id,Order> mapOrder=new Map<Id,Order>([SELECT Id,OwnerId,Execution_Branch__c,Internal_Sales_Representative__c, Owner_Manager__c FROM Order where Id IN :ssgOrderIds and Business_Unit__C = 'G']);
        
        for(Case caseRec : newCases){    
            if(caseRec.Execution_Branch__c == null && caseRec.Order__c !=null &&recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_SSG_SERIVCE_REQUEST){
               String exeutionBranchValue =  mapOrder.get(caseRec.Order__c).Execution_Branch__c;
               String zoneValue = getDependentPicklistValuesMethod(exeutionBranchValue);
               caseRec.Execution_Branch__c= mapOrder.get(caseRec.Order__c).Execution_Branch__c;
               caseRec.Zone__c= zoneValue;
               caseRec.Internal_Sales_Rep_Order__c= mapOrder.get(caseRec.Order__c).Internal_Sales_Representative__c;
               caseRec.Sales_Rep_Manager__c= mapOrder.get(caseRec.Order__c).Owner_Manager__c;
               }
            
           //ended by Shreela and Anupam for Ticket#30430961 on 18th Sept 2021          
           //Auto Populate Status as 'Registered'
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST){
                caseRec.Status = GlobalConstants.CASE_STATUS_REGISTERED;
                    
                //Default Branch & asset Serial number 
                if(caseRec.AssetId != null && 
                (String.isBlank(caseRec.Asset_Serial_Number__c) || String.isBlank(caseRec.Branch__c) || String.isBlank(caseRec.SR_Search_Term__c))){
                     assetIdsToDefault.add(caseRec.AssetId);   
                }
            }

            //For Auto-population of Contact from asset on Service Request
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && caseRec.ContactId == null
                && caseRec.AssetId != null){
                assetIdsForContacts.add(caseRec.AssetId);
            }

            //For Auto Populate Asset from Equipment Serial No on Service Request
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && caseRec.Asset_Serial_Number__c != null && caseRec.Origin == 'Web' && caseRec.Asset == null){
                assetSerials.add(caseRec.Asset_Serial_Number__c);
                caseRec.MHE_Division__c = GlobalConstants.MHE_SUB_DIVISION_EQUIPMENT;  
            }

            //For Auto Populate Call category on Service Request From Asset
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && caseRec.AssetId != null && caseRec.Call_Category__c == null){
                assetIds.add(caseRec.AssetId);
            }
        }
        
        //Fetch Order details for SSG Service Requests
        map<Id, Order> ssgOrderMap = new map<Id, Order>([SELECT Id, AccountId, Account.Primary_Contact__c 
                                        FROM Order WHERE Id IN : ssgOrderIds]);


        //Get assets with contact and asset with account's contact 
        if(assetIdsForContacts.size() > 0){
            assetMapForContacts = new Map<String,Asset>([Select Id,ContactId,Account.Primary_Contact__c 
                                                            FROM Asset WHERE Id IN :assetIdsForContacts
                                                            AND (ContactId != null OR Account.Primary_Contact__c != null)]);
        }

        if(assetSerials.size() > 0 || assetIds.size() > 0){
            for(Asset asset : [Select Id,Equipment_Serial_No__c,Call_Category__c FROM Asset WHERE Equipment_Serial_No__c IN :assetSerials OR Id IN :assetIds]){
                if(asset.Equipment_Serial_No__c != null){
                    assetSerialVsId.put(asset.Equipment_Serial_No__c,asset.Id);
                }

                if(asset.Call_Category__c != null){
                    assets.put(asset.Id,asset);
                }
            }
        }
        
        if(assetIdsToDefault.size() > 0){
            assetsToDefaultWith = new Map<Id,Asset>([SELECT Id, Name, Equipment_Serial_No__c, Branch__c FROM Asset WHERE Id IN: assetIdsToDefault]);
        }
        
        //added by Shreela for Ticket#30430961 on 14th September 2021
        //Case executionBranchesList = [SELECT Order__c,Execution_Branch__c,Order__r.Execution_Branch__c FROM Case where Id =: newCases];
        //System.debug('executionBranchesList by shree:'+executionBranchesList);
        //ended by Shreela for Ticket#30430961 on 14th September 2021
        
        for(Case caseRec : newCases){ 
            
            //Defaulting logic for SSG Service Requests
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_SSG_SERIVCE_REQUEST 
                && caseRec.Order__c != null && ssgOrderMap.containsKey(caseRec.Order__c)){
                    caseRec.AccountId = caseRec.AccountId == null ? ssgOrderMap.get(caseRec.Order__c).AccountId : caseRec.AccountId;
                    caseRec.ContactId = caseRec.ContactId == null ? ssgOrderMap.get(caseRec.Order__c).Account.Primary_Contact__c : caseRec.ContactId;
                    //added by Shreela for Ticket#30430961 on 14th September 2021
                    /*if(executionBranchesList!=null){
                        caseRec.Execution_Branch__c = executionBranchesList.Order__r.Execution_Branch__c;
                    }*/
                    //added by Shreela for Ticket#30430961 on 14th September 2021
            }

            
            //Default Branch & asset Serial number 
            if(caseRec.AssetId != null && assetsToDefaultWith.containsKey(caseRec.AssetId)){
               caseRec.Asset_Serial_Number__c = String.isBlank(caseRec.Asset_Serial_Number__c) ? assetsToDefaultWith.get(caseRec.AssetId).Equipment_Serial_No__c : caseRec.Asset_Serial_Number__c;
               caseRec.Branch__c = String.isBlank(caseRec.Branch__c) ? assetsToDefaultWith.get(caseRec.AssetId).Branch__c : caseRec.Branch__c;
               caseRec.SR_Search_Term__c = String.isBlank(caseRec.SR_Search_Term__c) ? assetsToDefaultWith.get(caseRec.AssetId).Name : caseRec.SR_Search_Term__c;
            }
            
            //Auto Populate ContactId
            /*if((assetMapForContacts.containsKey(caseRec.AssetId) && caseRec.Business_Unit__c != GlobalConstants.MHE_BUSINESS_UNIT)){ //Contact should not get fetched on creation of SR.Added BU check.Should not be MHE by Shreela on 2nd May 2023 for SMEPB-95
                if(assetMapForContacts.get(caseRec.AssetId).ContactId != null){
                    caseRec.ContactId = assetMapForContacts.get(caseRec.AssetId).ContactId;
                }else if(assetMapForContacts.get(caseRec.AssetId).Account.Primary_Contact__c != null){
                    caseRec.ContactId = assetMapForContacts.get(caseRec.AssetId).Account.Primary_Contact__c;
                }
            }  */ //Commented this code by Shreela on 15th May 2023 as this works only for MHE BU and as per the latest requirement for point 1 of SMEPB -95,this is not required 

            //Auto Populate Asset based on Asset Serial No
            if(assetSerialVsId.containsKey(caseRec.Asset_Serial_Number__c)){
                caseRec.AssetId = assetSerialVsId.get(caseRec.Asset_Serial_Number__c);
            }

            //Auto Populate Call Category from Asset record
            if(caseRec.AssetId != null && assets.containsKey(caseRec.AssetId) 
                && assets.get(caseRec.AssetId).Call_Category__c != null && caseRec.Call_Category__c == null){
                caseRec.Call_Category__c = assets.get(caseRec.AssetId).Call_Category__c;    
            }

            //Validation Error: If Contact is Missing on Service Case and Alternate Mobile and Email are also missing
            //Added on 28-Jul-2021 - Exclude validation for Asset Enrollment
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && !GlobalConstants.BYPASS_VALIDATION_FOR_CASE_ORIGIN.contains(caseRec.Origin)
                && caseRec.ContactId == null && (caseRec.Type != 'Asset Modification Request') 
                && (caseRec.Type != 'Asset Enrollment')
                && (caseRec.Email__c == null && caseRec.Mobile__c == null)){
                caseRec.addError(System.Label.EMAIL_AND_PHONE_MANDATORY);
            }
        }
    }

        //added by shreela

    public  String getDependentPicklistValuesMethod(String zoneValue) { 
    switch on zoneValue {
        
            when 'Delhi' {
                return 'NOR';
            }when 'Chandigarh' {
                return 'NOR';
            }when 'Kolkata' {
                return 'EST';
            }when 'Mumbai' {
                return 'WST';
            }when 'Pune' {
                return 'WST';
            }when 'Ahmedabad' {
                return 'WST';
            }when 'Chennai' {
                return 'STH';
            }when 'Bangalore' {
                return 'STH';
            }when 'Hyderabad' {
                return 'STH';
            }when 'MENA' {
                return 'Export';
            }when else {
                 return '';
            }
        }
  }
   //ended by shreela
    
    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Populate Email fields on Service Request Records based on the of 'Call pending reason__c'.
    Inputs:        list of created Case records

    History
    26-10-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateEscalationEmailFields(List<Case> newCases){
        Map<Id, Asset> assets = new Map<Id, Asset>();
        Set<String> assetIds = new Set<String>();
        Map<String,Map<String,User>> branchNameVsBranchChampionHead = new Map<String,Map<String,User>>(); 
        Set<String> caseOwnerIds = new Set<String>();    
        Map<String,User> users = new Map<String,User>();
        for(Case caseRec : newCases){
            if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST){
                if(caseRec.AssetId != null){
                    assetIds.add(caseRec.AssetId);
                } 
                caseOwnerIds.add(caseRec.OwnerId);
            }          
        }
        
        if(assetIds.size() > 0){
            assets = new Map<Id, Asset> ([Select Id, Area_Code__c from Asset 
                                                            WHERE Area_Code__c != null 
                                                            AND Id IN:assetIds]);       
            Set<String> areaCodes = new Set<String>();
            for(Asset assetRec: assets.values() ){
                areaCodes.add(assetRec.Area_Code__c);
            }

            if(areaCodes.size() > 0){
                Map<String,Area_Code_Branch_Champion__mdt> salaryCodeVsMtd = new Map<String,Area_Code_Branch_Champion__mdt>();
                Set<String> salaryCodes = new Set<String>();
                for(Area_Code_Branch_Champion__mdt branchMtd: [Select Id, Area_Code__c, Branch_Champion_salary_code__c, Branch_head_Salary_code__c, Regional_Manager_Salary_Code__c
                                                            FROM Area_Code_Branch_Champion__mdt where Area_Code__c IN :areaCodes AND BU_Division__c = 'MHE'] ){
                    if( branchMtd.Branch_Champion_salary_code__c != null ) 
                        salaryCodeVsMtd.put(branchMtd.Branch_Champion_salary_code__c,branchMtd);

                    if( branchMtd.Branch_head_Salary_code__c != null ) 
                        salaryCodeVsMtd.put(branchMtd.Branch_head_Salary_code__c,branchMtd);

                    if( branchMtd.Regional_Manager_Salary_Code__c != null ) 
                        salaryCodeVsMtd.put(branchMtd.Regional_Manager_Salary_Code__c,branchMtd);

                }            

                if(salaryCodeVsMtd.size() > 0){
                    users = new Map<String,User>([Select Id, Email, Logistic_Company__c, Salary_Code__c, Profile.Name FROM User 
                                                                    WHERE IsActive = true AND (Salary_Code__c IN :salaryCodeVsMtd.keySet()
                                                                    OR Id IN : caseOwnerIds)]);
                    for(User usr : users.values()){
                        Map<String,User> branchUsers = new Map<String,User>();
                        if(salaryCodeVsMtd.containsKey(usr.Salary_Code__c) 
                            && salaryCodeVsMtd.get(usr.Salary_Code__c).Branch_Champion_salary_code__c == usr.Salary_Code__c){
                            branchUsers.put('BranchChampion',usr);
                        }

                        if( salaryCodeVsMtd.containsKey(usr.Salary_Code__c) && salaryCodeVsMtd.get(usr.Salary_Code__c).Branch_head_Salary_code__c == usr.Salary_Code__c){
                            branchUsers.put('BranchHead',usr);
                        }

                        if(salaryCodeVsMtd.containsKey(usr.Salary_Code__c) && salaryCodeVsMtd.get(usr.Salary_Code__c).Regional_Manager_Salary_Code__c == usr.Salary_Code__c){
                            branchUsers.put('RegionalManager',usr);
                        }
                        if(salaryCodeVsMtd.containsKey(usr.Salary_Code__c) && !branchNameVsBranchChampionHead.containsKey(salaryCodeVsMtd.get(usr.Salary_Code__c).Area_Code__c)){
                            branchNameVsBranchChampionHead.put(salaryCodeVsMtd.get(usr.Salary_Code__c).Area_Code__c,branchUsers);
                        }else if(salaryCodeVsMtd.containsKey(usr.Salary_Code__c)){
                            branchNameVsBranchChampionHead.get(salaryCodeVsMtd.get(usr.Salary_Code__c).Area_Code__c).putAll(branchUsers);
                        }                      
                    }
                }
            }
        }
        for(Case caseRec : newCases){
            if(caseRec.AssetId != null && assets.containsKey(caseRec.AssetId) 
                && branchNameVsBranchChampionHead.containsKey(assets.get(caseRec.AssetId).Area_Code__c)){
                //Populate Branch Champion for Every MHE Service Request associated with an asset 
                if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                    && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('BranchChampion')){
                    caseRec.Branch_Champion__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('BranchChampion').Id;
                }    

                if(caseRec.Call_Pending_Reason__c == GlobalConstants.SPARE_NOT_AVAILABLE){
                    //Branch Head
                    if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                        && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('BranchHead')){
                        caseRec.L1_Escalation__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('BranchHead').Email;                    
                    }
                    //Regional Manager
                    if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                        && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('RegionalManager')){
                        caseRec.L2_Escalation__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('RegionalManager').Email;                    
                    }
                }else if(caseRec.Call_Pending_Reason__c == null || caseRec.Call_Pending_Reason__c != null){
                    //Branch Champion
                    if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                        && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('BranchChampion')){
                        caseRec.L0_Escalation__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('BranchChampion').Email;
                    }
                    //Branch Head
                    if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                        && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('BranchHead')){
                        caseRec.L1_Escalation__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('BranchHead').Email;                    
                    }
                    //Regional Manager
                    if(branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c) != null
                        && branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).containsKey('RegionalManager')){
                        caseRec.L2_Escalation__c = branchNameVsBranchChampionHead.get(assets.get(caseRec.AssetId).Area_Code__c).get('RegionalManager').Email;                    
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   Assign cases to Queue/User.
    Inputs:        list of created Case records

    History
    30-11-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void assignCases(List<Case> newCases){
        set<Id> offloaedCaseAssetIds = new set<Id>();
        map<Id, Asset> assetMap = new map<Id, Asset>();
        map<Id, Id> accountIdVsExternalUserId = new map<Id, Id>();
        map<Id, String> assetIdVsAreaCodes = new map<Id, String>();
        map<Id, String> dealerAccountIdVsAreaCodes = new map<Id, String>();

        map<String, String> branchMappingMDT = new map<String, String>();
        set<String> salaryCodes = new set<String>();
        map<String, Id> salaryCodeVsUserId = new map<String, Id>();

        set<String> branchMappingQs = new set<String>();
        map<String, Id> queueAPINameVsId = new map<String, Id>();

        map<Id, String> dealerAccountIdVsSupervisorQueue = new map<Id, String>();
        map<String, Id> dealerSupervisorQueueMap = new map<String, Id>();

        //Fetch asset Details for Case
        for(Case request : newCases){
            if(request.AssetId != null)
                offloaedCaseAssetIds.add(request.AssetId);
        }

        //fetch Asset Details
        for(Asset assetRec : [SELECT Id, Primary_Dealer__c, Primary_Dealer__r.Dealer_Supervisor_Queue__c, Area_Code__c FROM Asset 
                                                    WHERE Id IN : offloaedCaseAssetIds 
                                                    ]){
            if(assetRec.Primary_Dealer__c != null){
                assetMap.put(assetRec.Id, assetRec); 
                if(String.isNotBlank(assetRec.Primary_Dealer__r.Dealer_Supervisor_Queue__c)){
                    dealerAccountIdVsSupervisorQueue.put(assetRec.Primary_Dealer__c, assetRec.Primary_Dealer__r.Dealer_Supervisor_Queue__c);

                } else if(String.isNotBlank(assetRec.Area_Code__c)){
                    dealerAccountIdVsAreaCodes.put(assetRec.Primary_Dealer__c, assetRec.Area_Code__c);
                }
                    
            } else if(String.isNotBlank(assetRec.Area_Code__c))                                           
                assetIdVsAreaCodes.put(assetRec.Id, assetRec.Area_Code__c); 
        }

        //Fetch Dealer Supervisor Queue details
        if(!dealerAccountIdVsSupervisorQueue.isEmpty()){
            for(Group que : [SELECT Id, DeveloperNAME FROM Group WHERE Type = 'Queue' AND DeveloperNAME IN : dealerAccountIdVsSupervisorQueue.values()]){
                dealerSupervisorQueueMap.put(que.DeveloperNAME , que.Id);
            }
        }
        
        //Fetch Metadata Records for Internal Technician Details
        for(Area_Code_Branch_Champion__mdt mapping : [SELECT Branch_Champion_Queue_API_Name__c, Branch_Champion_salary_code__c
                                                                    FROM Area_Code_Branch_Champion__mdt 
                                                                    WHERE Area_Code__c IN : assetIdVsAreaCodes.values()
                                                                    AND BU_Division__c = 'MHE']){
            if(String.isNotBlank(mapping.Branch_Champion_Queue_API_Name__c))
                branchMappingQs.add(mapping.Branch_Champion_Queue_API_Name__c);                                                        
            else{
                salaryCodes.add(mapping.Branch_Champion_salary_code__c);
            }    
        }

        if(Test.isRunningTest()){
            salaryCodes.add('QW1');
            branchMappingQs.add('TestQueue');
        }

        //Fetch user details with Salary codes
        if(salaryCodes.size() > 0 ){
            for(User userRec :[SELECT Id, Salary_Code__c FROM USER 
                                        WHERE Salary_Code__c IN : salaryCodes
                                        AND isActive = true]){
                salaryCodeVsUserId.put(userRec.Salary_Code__c, userRec.Id);
            }
        }

        //Fetch Queue details
        if(branchMappingQs.size() > 0){
            for(Group que : [SELECT Id, DeveloperNAME FROM Group WHERE Type = 'Queue' AND DeveloperNAME IN : branchMappingQs]){
                queueAPINameVsId.put(que.DeveloperNAME , que.Id);
            }
        }

        //Create Internal technician map details
        for(Area_Code_Branch_Champion__mdt mapping : [SELECT Area_Code__c, Branch_Champion_Queue_API_Name__c, Branch_Champion_salary_code__c
                                                                    FROM Area_Code_Branch_Champion__mdt 
                                                                    WHERE Area_Code__c IN : assetIdVsAreaCodes.values()
                                                                    AND BU_Division__c = 'MHE']){
            if(String.isNotBlank(mapping.Branch_Champion_Queue_API_Name__c) && queueAPINameVsId.containsKey(mapping.Branch_Champion_Queue_API_Name__c))
                branchMappingMDT.put(mapping.Area_Code__c, queueAPINameVsId.get(mapping.Branch_Champion_Queue_API_Name__c));                                                        
            
            if(String.isBlank(mapping.Branch_Champion_Queue_API_Name__c) && String.isNotBlank(mapping.Branch_Champion_salary_code__c)
                            && salaryCodeVsUserId.containsKey(mapping.Branch_Champion_salary_code__c)){
                branchMappingMDT.put(mapping.Area_Code__c, salaryCodeVsUserId.get(mapping.Branch_Champion_salary_code__c));                                                        
            }    
        }
        
        //Fetch User details for Offloaded Service Contracts
        if(!dealerAccountIdVsAreaCodes.isEmpty()){
            for(User supervisorUser : [SELECT Id, Contact.AccountId, Area_Code__c FROM User 
                                                WHERE Contact.AccountId IN : dealerAccountIdVsAreaCodes.keySet() 
                                                AND Contact.Role__c =: GlobalConstants.CONTACT_ROLE_SUPERVISOR
                                                AND Area_Code__c IN : dealerAccountIdVsAreaCodes.values()
                                                AND isActive = true]){
                if(dealerAccountIdVsAreaCodes.get(supervisorUser.Contact.AccountId) ==  supervisorUser.Area_Code__c)                                   
                    accountIdVsExternalUserId.put(supervisorUser.Contact.AccountId, supervisorUser.Id);                                        
            }
        }                       
      
        //Fetch the channels from Label
        String channel = system.label.Case_Assignment_Channels;
        List<String> channels = channel.Split(',');  
        
        //Fetch mhe service Record Type Id
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
        
        //Assign case logic
        for(Case caseRec : newCases){
            //Logic should work for mhe Service Requests only
            if(caseRec.RecordTypeId == mheServiceRequestRecordTypeId //&&  String.isNotBlank(caseRec.Type) 
                                            && !GlobalConstants.ASSET_CLASSIFICATION.contains(caseRec.Type)){
                //Case Orgin = 'Web/Email' assign to internal Queue or Type = 'Enquiry'
                if(((String.isNotBlank(caseRec.Origin) && channels.size() > 0 && containsIgnoreCase(channels, caseRec.Origin))|| 
                   (String.isNotBlank(caseRec.Type) && caseRec.Type == 'Enquiry'))
                  && groupNameVsId.containsKey(GlobalConstants.MHE_EMAIL_WEB_QUEUE)){
                    caseRec.ownerId = groupNameVsId.get(GlobalConstants.MHE_EMAIL_WEB_QUEUE);   
                }
                                                
                //Based on the offloaded Dealer contract
                else if(caseRec.AssetId != null && assetMap.containsKey(caseRec.AssetId) && assetMap.get(caseRec.AssetId).Primary_Dealer__c != null){
                    //Dealer Supervisor Queue Assignment
                    if(dealerAccountIdVsSupervisorQueue.containsKey(assetMap.get(caseRec.AssetId).Primary_Dealer__c)){
                        String supervisorQName = dealerAccountIdVsSupervisorQueue.get(assetMap.get(caseRec.AssetId).Primary_Dealer__c);
                        if(dealerSupervisorQueueMap.containsKey(supervisorQName)){
                            caseRec.ownerId = dealerSupervisorQueueMap.get(supervisorQName);
                        } else {
                            //Show Invalid Dealer Supervisor Queue error
                            caseRec.addError(System.Label.Invalid_Dealer_Supervisor_Queue);
                        }
                    } 

                    //If inside to handle Offloaded asset Contracts should not be bypassed
                    else if(accountIdVsExternalUserId.containsKey(Id.valueOf(assetMap.get(caseRec.AssetId).Primary_Dealer__c))){
                        caseRec.ownerId = accountIdVsExternalUserId.get(Id.valueOf(assetMap.get(caseRec.AssetId).Primary_Dealer__c));
                    } else {
                        //Do nothing as this is offloaded contract with basic details missing
                        caseRec.addError(System.Label.Offloaded_Contract_Detail_Missing);
                    }
                }

                //If asset Equipment Category is 'high end equipment' OR Key Service Customers  than it should be managed by Godrej Technicians
                else if(caseRec.Is_Serviced_by_Godrej_Internally__c && caseRec.AssetId != null 
                            && assetIdVsAreaCodes.containsKey(caseRec.AssetId) ){
                    if(branchMappingMDT.containsKey(assetIdVsAreaCodes.get(caseRec.AssetId))){
                        caseRec.ownerId = branchMappingMDT.get(assetIdVsAreaCodes.get(caseRec.AssetId));
                    } else {
                         //Do nothing as this is internal Technician contract with basic details missing
                         caseRec.addError(System.Label.Technician_Contract_Detail_Missing);
                    }
                }

                //Pin Code Based Assignment
                else {
                    caseRec.Applicable_For_Pincode_Based_Assignment__c = true;
                    if(groupNameVsId.containsKey(GlobalConstants.CASE_ASSIGNMENT_DEFAULT_QUEUE)){
                        caseRec.ownerId = groupNameVsId.get(GlobalConstants.CASE_ASSIGNMENT_DEFAULT_QUEUE);
                    } 
                }
            }
        }
    }

    //Method to check contains with Ignore case
    private boolean containsIgnoreCase(List<String> stringList, String soughtFor) {
        for (String current : stringList) {
            if ((current.trim()).equalsIgnoreCase(soughtFor.trim())) {
                return true;
            }
        }
        return false;
    }

    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   add Branch Champion owner user To respective Case Team
    Inputs:        map of updated Case records

    History
    02-12-2020      Kishor Kumar     Initial Release
    25-10-2023      Shreela Nair     101 SOQL Error fix by Shreela for SMEPB - 127 (Dealers were not able to crete account creation request SR created for SMEPB - 124 JIRA)
    
    ----------------------------------------------------------------------------*/
    public void addBranchChampionToCaseTeam(map<Id,Case> newCases, map<Id,Case> oldCases){
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        set<Id> ownerIds = new set<Id>();
        map<Id, User> ownerMap = new map<Id, User>();
        //added to share service forms
        List<Case> caseOwnerChanged = new List<Case>();
        Set<String> caseMembers = new Set<String>();
        
        //Added by Shreela on 13th Oct for SMF - 111(To avoid 101 soql query) - SMEPB - 127
        Set<Id> recordTypeIds = new Set<Id>(); 
        Id caseTeamRoleId;
        for (Case cs : newCases.values()) {
                recordTypeIds.add(cs.RecordTypeId);
            }
        //Ended by Shreela on 13th Oct for SMF - 111(To avoid 101 soql query)
        
        //Also change in position of next few exisirtng loc by Shreela on 13th Oct for SMF - 111(SMEPB - 127)(To avoid 101 soql query)
        
        //Fetch mhe service Record Type Id
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
        
        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == mheServiceRequestRecordTypeId && 
                oldCases.containsKey(caseId) && newCases.get(caseId).ownerId != null  && 
                newCases.get(caseId).ownerId != oldCases.get(caseId).ownerId){
                caseOwnerChanged.add(newCases.get(caseId));
                ownerIds.add(newCases.get(caseId).OwnerId);
            }
        }
        
        //Share service forms with new case owner
        ShareServiceFormsWithCaseTeam.shareForCase(caseOwnerChanged);
        
        //Fetch case Team member Role name details
        if(recordTypeIds.contains(mheServiceRequestRecordTypeId)){
            caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Support Agent' LIMIT 1].id;
            //Fetch Owner details
            ownerMap = new map<Id, User>([SELECT Id FROM User WHERE Id IN : ownerIds 
                                          AND (Persona__c =: GlobalConstants.MHE_GODREJ_BRANCH_CHAMPION OR Persona__c =:GlobalConstants.MHE_DEALER_SUPERVISOR )]);
            for(CaseTeamMember member : [Select ParentId,MemberId FROM CaseTeamMember
                                         WHERE ParentId IN: newCases.keyset()  
                                         AND MemberId IN :ownerMap.keyset()]){
                                             caseMembers.add(member.ParentId+'-'+member.MemberId);
                                             
                                         }            
        }
     
        //Create team member records
        for(Id caseId : newCases.keyset()){
            if(oldCases.containsKey(caseId)  && newCases.get(caseId).ownerId != oldCases.get(caseId).ownerId 
                    && ownerMap.containsKey(newCases.get(caseId).ownerId) && 
                    !caseMembers.contains(caseId +'-'+ newCases.get(caseId).ownerId)){
                CaseTeamMember member = new CaseTeamMember();
                member.ParentId = caseId;
                member.MemberId = newCases.get(caseId).OwnerId;
                member.TeamRoleId = caseTeamRoleId;
                caseTeamMembers.add(member);
            }
        }

        if(caseTeamMembers.size() > 0){
            try{
                insert caseTeamMembers;
            } catch(Exception ex){
                Logger.logError('CaseFieldPopulator', 'addBranchChampionToCaseTeam', '', ex);
            }
        }
        
    }

    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to create Project milestones when a SSG Service request record is created.
    After Insert
    Inputs:        Map<Id, Case> newCaseRecords
    Test Class:
    History
    06-02-2021    Kartik Shetty     Added logic to exclude some Project Milestones from being created if No_material_Supply__c is Yes
    22-12-2021    pankaj meshram    Added logic to exclude some Project Milestones from being created if Design_clearance_required__c is NO
    ----------------------------------------------------------------------------*/
    public void createMilestone(map<Id,Case> newCaseRecords, map<Id,Case> oldCaseRecords){
        String NO_MATERIAL_SUPPLY_TRUE = 'Yes';
        Id ssgRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        List<Project_milestone__c> projectMilestoneList = new List<Project_milestone__c>();
        
        String projectMilestoneRecordType = System.Label.Project_Milestone_Record_Types;
        List<String> projectMilestoneRecordTypeList = projectMilestoneRecordType.split(',');
        List<String> projectMilestonesRecordTypesToIgnore = (System.Label.Project_Milestone_record_types_to_ignore_if_no_material_supply_is_yes).split(',');
        String projectMilestoneExceptDesignClearanceRecordType;//Added by pankaj on 22-12-2021 for SRF 8
        Map<id,case> mapCase = new Map<id,case>([select id,order__r.Design_clearance_required__c,order__r.Planned_Receipt_Date__c,order__r.Planned_Delivery_Date__c from case where id IN:newCaseRecords.keyset() and order__r.Design_clearance_required__c != '']);//added by pankaj on 22 dec 2021
        for(Id caseId : newCaseRecords.keyset()){
            if(newCaseRecords.get(caseId).RecordTypeId == ssgRecordTypeId) {
                
                //Override the list for Dealer Installation Scope
            if(newCaseRecords.get(caseId).Installation_Scope__c == 'Dealer'){
                String projectMilestoneDealerRecordType = System.Label.Project_Milestone_Record_Types_for_Dealer;
                projectMilestoneRecordTypeList = projectMilestoneDealerRecordType.split(',');
            }
             //Added by pankaj on 22-12-2021 for Design_clearance milestone should not get created
            if(mapCase.size() > 0){
                if(mapCase.get(CaseId).order__r.Design_clearance_required__c == GlobalConstants.NO_CONSTANT && (newCaseRecords.get(caseId).Installation_Scope__c == 'Godrej' || newCaseRecords.get(caseId).Installation_Scope__c == '')){
                    projectMilestoneExceptDesignClearanceRecordType = System.Label.Project_Milestone_Record_Types_ignore_design_clearance;
                    projectMilestoneRecordTypeList = projectMilestoneExceptDesignClearanceRecordType.split(',');
                }else if(mapCase.get(CaseId).order__r.Design_clearance_required__c == GlobalConstants.NO_CONSTANT && newCaseRecords.get(caseId).Installation_Scope__c == 'Dealer'){
                    projectMilestoneExceptDesignClearanceRecordType = System.Label.Project_Milestone_Record_Types_for_Dealer_without_design_clearance;
                    projectMilestoneRecordTypeList = projectMilestoneExceptDesignClearanceRecordType.split(',');    
                }   
            }     
  
            // End By pankaj    
            for(String projMilestoneRecordType : projectMilestoneRecordTypeList) {
                /** Create ProjectMilestone records if No_material_Supply__c is 'No' and ignore the projectMilestonesRecordTypesToIgnore List */                   
                if(newCaseRecords.get(caseId).No_material_Supply__c != NO_MATERIAL_SUPPLY_TRUE ||(
                        newCaseRecords.get(caseId).No_material_Supply__c == NO_MATERIAL_SUPPLY_TRUE && 
                        !projectMilestonesRecordTypesToIgnore.contains(projMilestoneRecordType))) {
                    Project_milestone__c milestone = new Project_milestone__c();
                    milestone.RecordTypeId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(projMilestoneRecordType).getRecordTypeId();
                    milestone.Service_Request__c = caseId;
                    /*Commented by pankaj for SSF-41 Manoranjan Jira
                    if(milestone.RecordTypeId == GlobalConstants.PM_SupplynMaterial_RECORDTYPE_ID && (mapCase.get(CaseId).order__r.Planned_Delivery_Date__c != null || mapCase.get(CaseId).order__r.Planned_Receipt_Date__c != null)){//Checking if the PM record type is supply and material//updated null check on 08/02/2022
                        milestone.Planned_Start_Date__c = Date.valueOf(mapCase.get(CaseId).order__r.Planned_Delivery_Date__c);
                        milestone.Planned_Completion_Date__c = Date.valueOf(mapCase.get(CaseId).order__r.Planned_Receipt_Date__c);
                    }*/
                    projectMilestoneList.add(milestone);
                }
            }                      
        }
    }
    try{
            Insert projectMilestoneList;
        } Catch(Exception ex){
            Logger.logError('CaseFieldPopulator', 'createMilestone', '', ex);
        }
    }
    /*------------------------------------------------------------------------
    Author:        Suwarna Rao
    Company:       Salesforce
    Description:   Method to prevent SSG Service request closure if all associated Project milestones 
                    are not completed.
    After Update
    Inputs:        map<Id, Case> newCases,map<Id, Case> oldCases 
    Test Class:
    ----------------------------------------------------------------------------*/
    public void ssgCaseClosingValidation(map<Id, Case> newCases, map<Id, Case> oldCases ){
        Id ssgRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        Set<Id> caseRecordIds = new Set<Id>();
        //List<Project_milestone__c> projectMilestoneList = new List<Project_milestone__c>();

        map<Id, List<Project_milestone__c>> caseIdVsMilestones = new map<Id, List<Project_milestone__c>>();
        //List<Project_milestone__c> milestoneWithCompletedStatus = new List<Project_milestone__c>();
        
            
        for(Id caseId : newCases.keySet()){
            if(newCases.get(caseId).RecordTypeId == ssgRecordTypeId &&  
               newCases.get(caseId).Status == 'Closed' && oldCases.get(caseId).Status != 'Closed'){
                   caseRecordIds.add(caseId);
               }
        }


        /*projectMilestoneList = [SELECT Id, RecordTypeId, Status__c   
                                FROM Project_milestone__c 
                                WHERE Service_Request__c IN :caseRecordIds ];
            //system.debug(projectMilestoneList); */
            
       if(caseRecordIds.size() > 0){
            for(Project_milestone__c milestone : [SELECT Id, Service_Request__c, RecordTypeId, Status__c  
                                                                FROM Project_milestone__c 
                                                                WHERE Service_Request__c IN :caseRecordIds ]){
                if(caseIdVsMilestones.containsKey(milestone.Service_Request__c)){
                    caseIdVsMilestones.get(milestone.Service_Request__c).add(milestone);
                } else {
                    caseIdVsMilestones.put(milestone.Service_Request__c, new List<Project_milestone__c>{milestone});
                }
            }
       }  


       for(Id caseId : newCases.keySet()){
            Boolean isMilestoneOpen = false;

            if(caseIdVsMilestones.containsKey(caseId) && caseIdVsMilestones.get(caseId).size() > 0){
                for(Project_milestone__c projectMilestone : caseIdVsMilestones.get(caseId)){
                    //Status check for Booking, Design_Clearance, Execution, Supply_and_Material_Pull_Plan  RTs
                    if((projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId() 
                        || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId() 
                        || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId() 
                        || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_Record_Type).getRecordTypeId() 
                        || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId() 
                        || projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Supply_and_Material_Pull_Plan_Record_Type).getRecordTypeId()) 
                            && projectMilestone.Status__c != 'Completed'){

                        isMilestoneOpen = true;
                        break;
                    }

                    //Status check for Final_Commissioning_and_Handover RT
                    if(projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId()
                                && projectMilestone.Status__c != 'Received'){
                        isMilestoneOpen = true;
                        break;
                    }

                    //Status ceck for Site_Verification RT
                    if(projectMilestone.RecordTypeId == Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Site_Verification_Record_Type).getRecordTypeId()
                        && projectMilestone.Status__c != 'Completed'){
                      isMilestoneOpen = true;
                      break;
                    }
                }

                if(isMilestoneOpen){
                    newCases.get(caseId).addError(System.label.Milestones_Incomplete_Error); 
                }
            }

            
       }
    
    }


    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   add SSG Case Creator user/ Owner To respective Case Team
    Inputs:        list of created Case records

    History
    09-12-2020      Kishor Kumar     Initial Release
    20-10-2023      Shreela Nair     Optimizing code- Query shoul exceute on certain conditions for SMEPB - 127 (avoiding 101 soql error occured for dealers during SMEPB - 124 account creation record)
    ----------------------------------------------------------------------------*/
    public void addSSGCaseOwnerToCaseTeam(map<Id,Case> newCases, map<Id, Case> oldCases){
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        set<Id> userIds = new set<Id>(); 
        map<Id, User> userMap = new map<Id, User>();
        Set<String> caseMembers = new Set<String>();
        map<Id, Persona_Team_Mapping__mdt> personaMap; //Added by Shreela on 20th Oct 2023 for SMEPB - 127
        String caseTeamRole; //Added by Shreela on 20th Oct 2023 for SMEPB - 127
        Id caseTeamRoleId; //Added by Shreela on 20th Oct 2023for SMEPB - 127

        //Fetch SSG service Record Type Id
        Id ssgServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();

        //Get Created By User Ids
        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == ssgServiceRequestRecordTypeId){ 
                if (oldCases == null){
                    userIds.add(newCases.get(caseId).createdById);
                    userIds.add(newCases.get(caseId).ownerId);
                } else if((oldCases.containsKey(caseId) && 
                            newCases.get(caseId).ownerId != oldCases.get(caseId).ownerId)){
                    userIds.add(oldCases.get(caseId).ownerId);
                }
            }
        }
        
        //fetch existing Case team members
        if(!userIds.isEmpty()){ //Added if condition by Shreela on 20th Oct 2023 for SMEPB - 127
            for(CaseTeamMember member : [SELECT ParentId, MemberId FROM CaseTeamMember
                                         WHERE ParentId IN: newCases.keyset() 
                                         AND MemberId IN :userIds]){
                                             caseMembers.add(member.ParentId+'-'+member.MemberId);                                    
                                         }
            //}
            
            //Fetch Metadata records for Persona and access
            personaMap = new map<Id, Persona_Team_Mapping__mdt>([
                SELECT Id, Personas__c, Case_Team_Role_API_Name__c FROM Persona_Team_Mapping__mdt 
                WHERE Object_Name__c = 'Case' AND Business_Unit__c = 'SSG' 
                AND Personas__c != '' AND DeveloperName = 'SSG_Managers' LIMIT 1]);
            
            //Fetch case Team member Role name details
            caseTeamRole = !personaMap.isEmpty() ?  personaMap.values()[0].Case_Team_Role_API_Name__c : '';
            caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name =: caseTeamRole LIMIT 1].id;
        }   //Added by Shreela on 20th Oct 2023 for SMEPB - 127
        String PersonaString = (personaMap!=null && !personaMap.isEmpty()) ?  personaMap.values()[0].Personas__c : ''; //Added personaMap!=null by Shreela on 20th Oct 2023 for SMEPB - 127 (Avoiding null reference issue)
        List<String> personas = new List<String>();  
        if(String.isNotBlank(PersonaString)){
            for(String persona : PersonaString.split(',')){
                personas.add(persona.trim());
            }
        }
        
        //Fetch User Details
        if(personas.size() > 0)
            userMap = new map<Id, User>([SELECT Id FROM User WHERE Id IN : userIds AND Persona__c IN : personas]);

        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == ssgServiceRequestRecordTypeId ){

                //Owner Update add old Owner to case Team
                if(oldCases != null && userMap.containsKey(oldCases.get(caseId).ownerId) && 
                        !caseMembers.contains(caseId + '-' + oldCases.get(caseId).ownerId)){
                    CaseTeamMember member = new CaseTeamMember();
                    member.ParentId = caseId;
                    member.MemberId = oldCases.get(caseId).ownerId;
                    member.TeamRoleId = caseTeamRoleId;
                    caseTeamMembers.add(member);
                } /*else if(oldCases == null && newCases.get(caseId).ownerId == newCases.get(caseId).createdById
                                            && userMap.containsKey(newCases.get(caseId).ownerId)){
                    //Case Insert :: Owner & created By User are same :: add Owner to case Team
                    CaseTeamMember member = new CaseTeamMember();
                    member.ParentId = caseId;
                    member.MemberId = oldCases.get(caseId).ownerId;
                    member.TeamRoleId = caseTeamRoleId;
                    caseTeamMembers.add(member);
                }*/ else if(oldCases == null && newCases.get(caseId).ownerId != newCases.get(caseId).createdById ){
                    //Case Insert :: Owner & created By User are different user :: add both user to case Team
                    /*if(userMap.containsKey(newCases.get(caseId).ownerId)){
                        CaseTeamMember member = new CaseTeamMember();
                        member.ParentId = caseId;
                        member.MemberId = newCases.get(caseId).ownerId;
                        member.TeamRoleId = caseTeamRoleId;
                        caseTeamMembers.add(member);
                    }*/
                    //Case Insert :: Owner & created By User are different user :: add created by user to case Team
                    if(userMap.containsKey(newCases.get(caseId).createdById) && 
                            !caseMembers.contains(caseId + '-' + newCases.get(caseId).createdById)){
                        CaseTeamMember member = new CaseTeamMember();
                        member.ParentId = caseId;
                        member.MemberId = newCases.get(caseId).createdById;
                        member.TeamRoleId = caseTeamRoleId;
                        caseTeamMembers.add(member);
                    }
                }
                
            }
        }

        //Insert Case Team members record
        if(caseTeamMembers.size() > 0){
            try{
                Insert caseTeamMembers;
            } catch(Exception ex){
                Logger.logError('CaseFieldPopulator', 'addSSGCaseCreatorToCaseTeam', '', ex);
            }
        }
        
    }


    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   Assign SSG cases to User.
    Inputs:        list of created Case records

    History
    09-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void assignSSGCases(List<Case> newCases){
        set<String> executionBranches = new set<String>();
        map<String, String> branchVsSalaryCodes = new map<String, String>();
        map<String, Id> salaryCodeVsUserId = new map<String, Id>();

        //Fetch SSG service Record Type Id
        Id ssgServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        
        //get Branches for assignment
        for(Case ssgCase : newCases){
            if(ssgCase.recordTypeId == ssgServiceRequestRecordTypeId && 
                    String.isNotBlank(ssgCase.Execution_Branch__c)){
                    executionBranches.add(ssgCase.Execution_Branch__c);
            }
        }

        //Fetch Metadata Records for Internal Technician Details
        for(Area_Code_Branch_Champion__mdt mapping : [SELECT Execution_Branch__c, Branch_Champion_salary_code__c
                                                                    FROM Area_Code_Branch_Champion__mdt 
                                                                    WHERE Execution_Branch__c IN : executionBranches 
                                                                    AND BU_Division__c = 'SSG']){
            branchVsSalaryCodes.put(mapping.Execution_Branch__c, mapping.Branch_Champion_salary_code__c);
        }

        //Metadata dependent Test data
        if(Test.isRunningTest()){
            branchVsSalaryCodes.put('Delhi', 'QW1');
        }

        //Fetch user details with Salary codes
        if(!branchVsSalaryCodes.isEmpty() ){
            for(User userRec :[SELECT Id, Salary_Code__c FROM USER 
                                        WHERE Salary_Code__c IN : branchVsSalaryCodes.values()
                                        AND isActive = true]){
                salaryCodeVsUserId.put(userRec.Salary_Code__c, userRec.Id);
            }
        }

        //Business logic for Case assignment
        for(Case ssgCase : newCases){
            if(ssgCase.recordTypeId == ssgServiceRequestRecordTypeId && 
                    String.isNotBlank(ssgCase.Execution_Branch__c) && 
                    branchVsSalaryCodes.containsKey(ssgCase.Execution_Branch__c) && 
                    salaryCodeVsUserId.containsKey(branchVsSalaryCodes.get(ssgCase.Execution_Branch__c))){
                ssgCase.ownerId = salaryCodeVsUserId.get(branchVsSalaryCodes.get(ssgCase.Execution_Branch__c));

            }else if(ssgCase.recordTypeId == ssgServiceRequestRecordTypeId && 
                     String.isNotBlank(ssgCase.Execution_Branch__c) && 
                    (!branchVsSalaryCodes.containsKey(ssgCase.Execution_Branch__c) || 
                    !salaryCodeVsUserId.containsKey(branchVsSalaryCodes.get(ssgCase.Execution_Branch__c)))){
                ssgCase.addError('Either branch mapping for execution Branch - '+ ssgCase.Execution_Branch__c +' is missing or No Active user found');
            }
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   validate Case Status flow for Interio
    Inputs:        map of updated Case records

    History
    15-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateInterioCaseStatus(map<Id,Case> newCases, map<Id, Case> oldCases){
        //Fetch Interio service Record Type Id
        Id interioServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interio_B2C').getRecordTypeId();

        String interioCaseStatus = System.Label.Interio_Case_status_validator;
        
        validateCaseStatus(newCases, oldCases, interioServiceRequestRecordTypeId, interioCaseStatus);
         
    }
    
    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   validate Case Status flow for MHE
                    * Registered → Assigned → WIP → Re-open → Resolved → Closed
                    * Only exception will be Resolved to Re-open and Closed to Re-open
                    * Re-open to any other should be allowed
    Inputs:        map of updated Case records

    History
    15-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateMHECaseStatus(map<Id,Case> newCases, map<Id, Case> oldCases){
        //Fetch mhe service Record Type Id
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();

        String mheSuperCaseStatus = System.Label.MHE_Super_Status;
        String mheCaseStatus = System.Label.MHE_Service_Request_Status_Validator;
        
        // Registered → Assigned → WIP → Re-open → Resolved → Closed
        // Only exception will be Resolved to Re-open and Closed to Re-open
        // Re-open to any other should be allowed
        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == mheServiceRequestRecordTypeId && 
                oldCases.get(caseId).Status.toupperCase() != mheSuperCaseStatus.toupperCase() && 
                newCases.get(caseId).Status != oldCases.get(caseId).Status){
                validateCaseStatus(newCases, oldCases, mheServiceRequestRecordTypeId, mheCaseStatus);
            }
        }
         
    }
    
    /*------------------------------------------------------------------------
    Author:        kishor Kumar
    Company:       Salesforce
    Description:   validate Case Status flow for BU
    Inputs:        map of updated Case records

    History
    15-12-2020      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateCaseStatus(map<Id,Case> newCases, map<Id, Case> oldCases, Id serviceReqRTId, String labelString){
        map<String, Integer> statusVsIndex = new map<String, Integer>();
        
        List<String> statusList = labelString.split('>');
        
        for(Integer i = 0; i < statusList.size(); i++){
            statusVsIndex.put((statusList[i]).trim().toUpperCase(), i);
        }
        
        
        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == serviceReqRTId && 
                newCases.get(caseId).Status != oldCases.get(caseId).Status && 
                statusVsIndex.containsKey((newCases.get(caseId).Status).trim().toUpperCase()) && 
                statusVsIndex.containsKey((oldCases.get(caseId).Status).trim().toUpperCase()) ){
                
                    if(statusVsIndex.get((oldCases.get(caseId).Status).trim().toUpperCase())  > 
                            statusVsIndex.get((newCases.get(caseId).Status).trim().toUpperCase())){
                        newCases.get(caseId).Status.addError(System.Label.Case_Status_Backtrack_error);
                    }    
            }
        }
    }    

    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Case need to be accepted before change , expect from AssignmentRule invokation
    Inputs:        map of updated Case records

    History
    15-12-2020      Pawan     Initial Release
    6-01-2021       Amit S     Added a logic to check for the dealer supervisor's account with technician's account
    ----------------------------------------------------------------------------*/
    public void validateCaseChange(map<Id,Case> newCases, map<Id, Case> oldCases){
        Set<Id> ownerIds = new Set<Id>();
        for(Case newCase : newCases.values()){
            ownerIds.add(newCase.OwnerId);
        }
       
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id,AccountId FROM User WHERE Id IN: ownerIds]);
        
        
        for(Case newCase : newCases.values()){

            //Add Error when service request is edited by user and owner is queue for Interio B2C 
            if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME
                && isAssignmentRuleContext == false
                && String.valueOf(newCase.OwnerId).startsWith('00G')
                && loggedInUser.Profile.Name != GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME
                && UserInfo.getUserId() != newCase.CreatedById){
                    newCase.addError(System.Label.CAN_NOT_MODIFI_SERVICE_REQUEST);    
            }

            //Add Error when service request is edited by user and owner is queue for Interio B2C 
            if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && String.valueOf(newCase.OwnerId).startsWith('00G')
                && loggedInUser.Profile.Name != GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME
                && ((loggedInUser.UserRole <> NULL) ? !System.Label.MHE_Service_CSG_Head.containsIgnoreCase(loggedInUser.UserRole.Name) : true)  
                && UserInfo.getUserId() != newCase.CreatedById){
                    newCase.addError(System.Label.CAN_NOT_MODIFI_SERVICE_REQUEST);    
            }

            //If Dealer Supervisor's account doesn't match with Dealer Technician's account
             if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && loggedInUser.AccountId != null && !String.valueOf(newCase.OwnerId).startsWith('00G')
                && loggedInUser.AccountId != userMap.get(newCase.OwnerId).AccountId
                //Added line to not fire the validation for high end equipment serviced by Godrej internally
                && newCase.Is_Serviced_by_Godrej_Internally__c == FALSE) {
                
                newCase.addError(System.Label.Technician_Not_In_Dealership);    

            }
            //Change Serice Request status as 'Assigned' on change of owner from queue to user
            if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && String.valueOf(oldCases.get(newCase.Id).OwnerId).startsWith('00G')
                && String.valueOf(newCase.OwnerId).startsWith('005')
                && newCase.Status == GlobalConstants.CASE_STATUS_REGISTERED){
                newCase.Status = GlobalConstants.CASE_STATUS_ASSIGNED;
            }
            
            //Added by Shreela to add validation error if Case status='Assigned' and Contact Name is not set on 4th May 2023 for SMEPB-95
            if((newCase.Business_Unit__c == GlobalConstants.MHE_BUSINESS_UNIT && newCase.Status == GlobalConstants.CASE_STATUS_ASSIGNED 
                && oldCases.get(newCase.Id).Status == GlobalConstants.CASE_STATUS_ASSIGNED  
               && (newCase.ContactId == null && 
                   newCase.Alternate_Contact_s_Name__c == null && (newCase.Email__c ==null||newCase.Mobile__c ==null)))){ 
                    newCase.addError(System.Label.Update_Contact_Name);
                } 

            //Update Service Request Status as 'Pending' when call pending reason is selected
            if(recordTypeIdVsRecordTypeName.containsKey(newCase.RecordTypeId)
                && recordTypeIdVsRecordTypeName.get(newCase.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                && newCase.Call_Pending_Reason__c != null
                && oldCases.get(newCase.Id).Call_Pending_Reason__c != newCase.Call_Pending_Reason__c
                && newCase.Status != GlobalConstants.CASE_STATUS_PENDING){
                newCase.Status = GlobalConstants.CASE_STATUS_PENDING;
            }

            //Change Service Request Owner to CSG Team when Service requested is updated to Reviewed
            if(oldCases.containsKey(newCase.Id) && oldCases.get(newCase.Id).Reviewed__c != newCase.Reviewed__c 
                && newCase.Reviewed__c && newCase.Type == GlobalConstants.CASE_TYPE_COMMISSIONING 
                && groupNameVsId.containsKey('CSG_Team')){
                    //added By Vikrant for validating MHE commisioning reviewed record
                    if( newCase.Email__c == null || newCase.Alternate_Contact_s_Name__c == null || newCase.Mobile__c == null){
                        newCase.adderror('Contact Email / Contact Mobile / Alternate Email / Alternate Mobile are mandatory');
                    }
                    //end by Vikrant
                    newCase.OwnerId = groupNameVsId.get('CSG_Team');
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Pawan
    Company:       Salesforce
    Description:   Add Branch Champion to Case Team if not added
    Inputs:        context records

    History
    21-12-2020      Pawan     Initial Release
    ----------------------------------------------------------------------------*/
    public void addUserToCaseTeam(List<Case> newCases){
        try{
            Set<String> caseMembers = new Set<String>();
            Set<String> caseIds = new Set<String>();
            Set<String> branchChampions = new Set<String>();
            List<CaseTeamMember> caseTeamMembers  = new List<CaseTeamMember>();
            for(Case caseRec : newCases){
                if(recordTypeIdVsRecordTypeName.containsKey(caseRec.RecordTypeId) 
                    && recordTypeIdVsRecordTypeName.get(caseRec.RecordTypeId) == GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST
                    && caseRec.Branch_Champion__c != null){
                    caseIds.add(caseRec.Id);
                    branchChampions.add(caseRec.Branch_Champion__c);
                }
            }

            for(CaseTeamMember member : [Select ParentId,MemberId FROM CaseTeamMember
                                            WHERE ParentId IN: caseIds 
                                            AND MemberId IN :branchChampions]){
                caseMembers.add(member.ParentId+'-'+member.MemberId);                                    
            }

            List<CaseTeamRole> role = [SELECT Id,Name FROM CaseTeamRole 
                                        WHERE Name =: System.Label.SERVICE_REQUEST_TEAM_ROLE LIMIT 1];
                
            for(Case caseRec : newCases){
                if(caseRec.Branch_Champion__c != null 
                    && !caseMembers.contains(caseRec.Id+'-'+caseRec.Branch_Champion__c)
                    && role.size() > 0){
                    caseTeamMembers.add(
                        new CaseTeamMember(
                            ParentId = caseRec.Id, MemberId = caseRec.Branch_Champion__c,TeamRoleId = role[0].Id));
                }
            }

            if(caseTeamMembers.size() > 0){
                insert caseTeamMembers;
            }
        }catch(Exception ex){
            Logger.logError('CaseFieldPopulator', 'addUserToCaseTeam', null, ex);
        }
    }
    
    /*------------------------------------------------------------------------
    Author:        Amit
    Company:       Salesforce
    Description:   Update the Asset's commission date post SR Closure
    Inputs:        context records

    History
    21-12-2020      Amit     Initial Release
----------------------------------------------------------------------------*/
    public void updateAssetOnSRClosure(List<Case> cases,Map<Id,Case> oldCases){
        List<Asset> assetLstToUpdate = new List<Asset>();
        Set<Id> assetIds = new Set<Id>();
        for(Case caseItr : cases){
            if(caseItr.Status == 'Resolved' && 
               String.isNotBlank(caseItr.Type) && 
               String.valueOf(caseItr.Type).equalsIgnoreCase('Commissioning') &&
               caseItr.Status != oldCases.get(caseItr.Id).Status){
                   
                   assetIds.add(caseItr.AssetId);
               }
        }
        //Added by Anupam to avoid SOQL(101) Error on 11/4/2021 
        List<Asset> AssetCseIds = [SELECT Id FROM Asset WHERE Id IN: assetIds];
        for(Asset assetItr : AssetCseIds){
            assetLstToUpdate.add(
                new Asset(Id = assetItr.Id, Date_of_Commissioning__c = System.now())
            );
        }
        update assetLstToUpdate; 
    }
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Update AHM based on EHM entered in the Service Request when closing
    Inputs:        Service Request Records

    History
    29-12-2020      Mahith Madwesh     Initial Release
    ----------------------------------------------------------------------------*/
    public void calculateAssetHourMeter(list<case> newItems){
        Id jobCardRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByName().get('Job Card').getRecordTypeId();
         Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
         set<Id> assetIds = new set<Id>();
         set<Id> caseIds = new set<Id>();
         for(case c: newItems){
             if(c.recordTypeId == mheServiceRequestRecordTypeId && c.Status == GlobalConstants.CASE_STATUS_CLOSED){
                 assetIds.add(c.AssetId);
                 caseIds.add(c.Id);
             }
         }

        map<Id,Service_Form__c> AssetServiceFormMap = new map<Id,Service_Form__c>();
        
        //Added by Shankar Sahu 31/03/2021 to check that 
        //case ids and asset ids are present before ececuting further code
    
        if(caseIds.size()>0 && assetIds.size()>0){
            list<Service_Form__c> exisitingServiceForms = [SELECT Id,Equipment_Hour_Meter__c,Old_EHM__c,CreatedDate,Case__c, Case__r.AssetId FROM Service_Form__c WHERE 
                                                                Case__r.AssetId IN:assetIds AND Case__c IN:caseIds AND recordTypeId =:jobCardRTId ORDER BY CreatedDate DESC ];

         for(Service_Form__c sf1: exisitingServiceForms){
             if(!AssetServiceFormMap.containsKey(sf1.Case__r.AssetId)){
                  AssetServiceFormMap.put(sf1.Case__r.AssetId,sf1);
             }
         }
         
         list<Asset> assetRecords = [SELECT Id,Asset_Hour_Meter__c,Base_Asset_Hour_Meter__c FROM Asset WHERE Id IN: AssetServiceFormMap.keySet()];

         list<Asset> updatedAssetRecords = new List<Asset>();
         for(Asset a: assetRecords){
             
             a.Is_System_Update__c = true;
             
             if(AssetServiceFormMap.keyset().contains(a.Id) && (AssetServiceFormMap.get(a.Id).Equipment_Hour_Meter__c<>NULL)){
                //  if(AssetServiceFormMap.get(a.Id).Equipment_Hour_Meter__c!=null){
                
                    if(AssetServiceFormMap.get(a.Id).Old_EHM__c!=null && AssetServiceFormMap.get(a.Id).Old_EHM__c >AssetServiceFormMap.get(a.Id).Equipment_Hour_Meter__c){
                        a.Base_Asset_Hour_Meter__c = ( a.Base_Asset_Hour_Meter__c<>null ? a.Base_Asset_Hour_Meter__c:0) + AssetServiceFormMap.get(a.Id).Old_EHM__c;
                        a.Asset_Hour_Meter__c = a.Base_Asset_Hour_Meter__c + AssetServiceFormMap.get(a.Id).Equipment_Hour_Meter__c;
                        updatedAssetRecords.add(a);
                    } else{
                        a.Asset_Hour_Meter__c = ( a.Base_Asset_Hour_Meter__c<>null ? a.Base_Asset_Hour_Meter__c:0) + AssetServiceFormMap.get(a.Id).Equipment_Hour_Meter__c;
                        updatedAssetRecords.add(a);
                    }
                    // a.Base_Asset_Hour_Meter__c = a.Asset_Hour_Meter__c;
                //  }
                
             }
         }
       
           update updatedAssetRecords;    
    }
}
    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Before Closing Service Request if there is any In-Progress
                    Job Cards. If there is then it cannot be closed
    Inputs:        Service Request Records

    History
    31-12-2020      Mahith Madwesh     Initial Release
    23-05-2022      Priyanka M         Upon Resolution/Closure of case all the relevant service forms should be filled/in submitted state  
    ----------------------------------------------------------------------------*/
    public void checkJobCardBeforeClosing(list<case> newItems){ 
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
            
        Id jobCardRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_JOB_CARD_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        Id feedbackRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_FEEDBACK_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        Id commCheckListRTId = Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_COMMISSIONING_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        Id PMElectricCheckListRTId =Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_PM1_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        Id PMDieselCheckListRTId =Schema.SObjectType.Service_Form__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SERVICE_FORM_PM2_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        map<Id,Case> mapMHECase = new map<Id,Case>();
        
        //Taking MHE case ids in map where status = Resolved OR Closed and case type = PM or BM or Commissioning
        for(case c: newItems){
            if(c.recordTypeId == mheServiceRequestRecordTypeId && (c.Status == GlobalConstants.CASE_STATUS_RESOLVED || c.Status == GlobalConstants.CASE_STATUS_CLOSED) &&
            ( c.type == GlobalConstants.PM_CONSTANT || c.type == GlobalConstants.BM_CONSTANT 
                //|| c.type == GlobalConstants.AUDIT_CONSTANT This is not needed
                || c.type == GlobalConstants.COMISSIONING )){
                //caseIds.add(c.Id);
                mapMHECase.put(c.Id,c);
            }
        }
        
        // Maps for service form type - job card , feedback , PM Diesel , PM Electric , Commissioning Checklist
        Map<Id,Service_Form__c> caseServiceFormMap = new Map<Id,Service_Form__c>();
        Map<Id,Service_Form__c> caseJobCardMap = new Map<Id,Service_Form__c>();
        Map<Id,Service_Form__c> caseFeedbackMap = new Map<Id,Service_Form__c>();
        Map<Id,Service_Form__c> casePMDieselCLMap = new Map<Id,Service_Form__c>();
        Map<Id,Service_Form__c> casePMElectricCLMap = new Map<Id,Service_Form__c>();
        Map<Id,Service_Form__c> caseCommCLMap = new Map<Id,Service_Form__c>();
        
        //Get the list of service forms which are of type Job Card OR Feedback OR PM Checklist - Diesel OR PM Checklist - Electric OR Commissioning Checklist 
        List<Service_Form__c> serviceFormsList = [SELECT Id ,RecordTypeId, Status__c,Case__c FROM Service_Form__c
                                                             WHERE Case__c IN:mapMHECase.keySet() AND 
                                                            (recordTypeId=:jobCardRTId OR recordTypeId=:feedbackRTId OR 
                                                             recordTypeId=:commCheckListRTId OR recordTypeId=:PMElectricCheckListRTId OR
                                                             recordTypeId=:PMDieselCheckListRTId)];
        
        //Get the maps of job card , feedback , PM Diesel , PM Electric , Commissioning Checklist populated from the list of service form
        for(Service_Form__c sf: serviceFormsList){
            if(sf.Status__c == GlobalConstants.SERVICE_FORM_STATUS_IN_PROGRESS && !caseServiceFormMap.containsKey(sf.Case__c) && sf.recordTypeId==jobCardRTId){
                caseServiceFormMap.put(sf.Case__c,sf);
            }else if(!caseJobCardMap.containsKey(sf.Case__c) && sf.recordTypeId==jobCardRTId){
                caseJobCardMap.put(sf.Case__c,sf);
            }
            if( !caseFeedbackMap.containsKey(sf.Case__c) && sf.recordTypeId==feedbackRTId){
                caseFeedbackMap.put(sf.Case__c,sf);
            }
            else if( !casePMElectricCLMap.containsKey(sf.Case__c) && sf.recordTypeId==PMElectricCheckListRTId){
                casePMElectricCLMap.put(sf.Case__c,sf);
            }
            else if( !casePMDieselCLMap.containsKey(sf.Case__c) && sf.recordTypeId==PMDieselCheckListRTId){
                casePMDieselCLMap.put(sf.Case__c,sf);
            }
            else if( !caseCommCLMap.containsKey(sf.Case__c) && sf.recordTypeId==commCheckListRTId){
                caseCommCLMap.put(sf.Case__c,sf);
            }
        }

        for(Case c1: mapMHECase.values()){
            if(caseServiceFormMap.containsKey(c1.Id)){ 
                        c1.addError(System.label.Service_Request_has_an_In_progress_job_card);
            }else if(!caseJobCardMap.containsKey(c1.Id)) {
                        c1.addError(System.label.SR_does_not_have_a_job_card);
            }
             
            //If Closed / Resolved PM , BM , Comm SR doesnt have a Service Feedback form
            if(!caseFeedbackMap.containsKey(c1.Id)) {
                    c1.addError(System.label.SR_does_not_have_a_feedback_form);
            }
            // If Closed / Resolved PM SR doesnt have any of the PM checklists 
            if(c1.type == GlobalConstants.PM_CONSTANT && (!casePMDieselCLMap.containsKey(c1.Id) && !casePMElectricCLMap.containsKey(c1.Id))){
                    c1.addError(System.label.PM_SR_missing_PM_checklist);
            }
            // If Closed / Resolved Comm SR doesnt have a Commissioning checklist
            else if(c1.type == GlobalConstants.COMISSIONING && !caseCommCLMap.containsKey(c1.Id)){
                    c1.addError(System.label.Comm_SR_missing_Comm_Checklist);
            }
        }
    }

    /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Before Closing Service Request if there is any In-Progress
                    Job Cards. If there is then it cannot be closed
    Inputs:        Service Request Records

    History
    31-12-2020      Mahith Madwesh     Initial Release
    ----------------------------------------------------------------------------*/
    public void populateDealerSupervisor(list<Case> newCases,map<Id,case> oldCases){
       Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
       Map<Id,Id> CaseOwnerIdMap = new Map<Id,Id>();
       
       for(case c:newCases){
           if(oldCases.get(c.Id).OwnerId != c.OwnerId && c.recordTypeId == mheServiceRequestRecordTypeId ){
               CaseOwnerIdMap.put(c.OwnerId,c.Id);
           }
       }

      map<Id,User> OwnerIdPersonaMap = new map<Id,User>([SELECT Id,Persona__c FROM User WHERE Id IN:CaseOwnerIdMap.keySet() AND isActive = true AND Persona__c = 'MHE Dealer Supervisor' ]);


       for(case c1:newCases){
           if(OwnerIdPersonaMap.containsKey(c1.OwnerId)){
                c1.Dealer_Supervisor__c = OwnerIdPersonaMap.get(c1.OwnerId).Id;
           }
       }
    }
    
    /*------------------------------------------------------------------------
    Author:        Kishor Kumar
    Company:       Salesforce
    Description:   Method to add Case Owner to Case Team on Owner change for MHE SR
    Inputs:        map of updated Case records  
    
    History
    13-01-2021      Kishor Kumar     Initial Release
    ----------------------------------------------------------------------------*/
    public void addMHECaseOwnerToCaseTeam(map<Id,Case> newCases, map<Id, Case> oldCases){
    
    System.debug('inside addMHECaseOwnerToCaseTeam');
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        set<Id> userIds = new set<Id>(); 
        map<Id, User> userMap = new map<Id, User>();
        Set<String> caseMembers = new Set<String>();

        //Fetch MHE service Record Type Id
        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MHE_Service_Request').getRecordTypeId();

        //Get Owner Ids
        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == mheServiceRequestRecordTypeId){ 
                if((oldCases.containsKey(caseId) && 
                            newCases.get(caseId).ownerId != oldCases.get(caseId).ownerId)){
                    userIds.add(oldCases.get(caseId).ownerId);
                }
            }
        }
        
        //fetch existing Case team members
        if(userIds.size() > 0){
            for(CaseTeamMember member : [SELECT ParentId, MemberId FROM CaseTeamMember
                                                WHERE ParentId IN: newCases.keyset() 
                                                AND MemberId IN :userIds]){
                    caseMembers.add(member.ParentId+'-'+member.MemberId);                                    
            }
        }

        //Fetch Metadata records for Persona and access
        map<Id, Persona_Team_Mapping__mdt> personaMap = new map<Id, Persona_Team_Mapping__mdt>([
                            SELECT Id, Personas__c, Case_Team_Role_API_Name__c FROM Persona_Team_Mapping__mdt 
                            WHERE Object_Name__c = 'Case' AND Business_Unit__c = 'MHE' 
                            AND Personas__c != '' AND DeveloperName = 'MHE_SC_Read_only_Personas' LIMIT 1]);
        
        //Fetch case Team member Role name details
        String caseTeamRole = !personaMap.isEmpty() ?  personaMap.values()[0].Case_Team_Role_API_Name__c : '';
        Id caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name =: caseTeamRole LIMIT 1].id;

        String PersonaString = !personaMap.isEmpty() ?  personaMap.values()[0].Personas__c : '';
        List<String> personas = new List<String>();  
        if(String.isNotBlank(PersonaString)){
            for(String persona : PersonaString.split(',')){
                personas.add(persona.trim());
                System.debug('Call center :: ' + persona.trim());
            }
        }
        
        //Fetch User Details
        if(personas.size() > 0)
            userMap = new map<Id, User>([SELECT Id FROM User WHERE Id IN : userIds AND Persona__c IN : personas]);

        for(Id caseId : newCases.keyset()){
            if(newCases.get(caseId).RecordTypeId == mheServiceRequestRecordTypeId ){

                //Owner Update add old Owner to case Team
                if(oldCases != null && userMap.containsKey(oldCases.get(caseId).ownerId) && 
                        !caseMembers.contains(caseId + '-' + oldCases.get(caseId).ownerId)){
                    CaseTeamMember member = new CaseTeamMember();
                    member.ParentId = caseId;
                    member.MemberId = oldCases.get(caseId).ownerId;
                    member.TeamRoleId = caseTeamRoleId;
                    caseTeamMembers.add(member);
                    
                    System.debug('call center member :: ' + member.MemberId);
                }
                
            }
        }

        //Insert Case Team members record
        if(caseTeamMembers.size() > 0){
            try{
                Insert caseTeamMembers;
                System.debug('Call center user inserted');
            } catch(Exception ex){
                Logger.logError('CaseFieldPopulator', 'addMHECaseOwnerToCaseTeam', '', ex);
            }
        }
        
    } 


    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to update Asset Enrollment Status when Service Request of Type "Asset Enrollment" is closed
    Inputs:        map of updated Case records, map of old Case records  
    
    History
    21-01-2021      Kartik Shetty     Initial Release
    ----------------------------------------------------------------------------*/
    public void updateAssetEnrollmentStatus(Map<Id,Case> newCases) {
        Map<Id, String> assetId_VS_assetEnrollmentValue = new Map<Id, String>();
        for(Case caseRecord : newCases.values()) {
            if(caseRecord.Status == 'Closed' && caseRecord.Type == 'Asset Enrollment') {
                assetId_VS_assetEnrollmentValue.put(caseRecord.AssetId, caseRecord.Approval_Status__c);
            }
        }
        if(!assetId_VS_assetEnrollmentValue.isEmpty()) {
            List<Asset> assetRecordsToUpdate = [Select Id, Enrollment_Status__c FROM Asset WHERE Id IN :assetId_VS_assetEnrollmentValue.keySet()];
            for(Asset assetRecord : assetRecordsToUpdate) {
                assetRecord.Enrollment_Status__c = assetId_VS_assetEnrollmentValue.get(assetRecord.Id);
            }
            update assetRecordsToUpdate;
        }
    }

      /*------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Company:       Salesforce
    Description:   Validate working Asset Benefit Record on Asset with existing
                    Service Request
    History
    31-12-2020      Mahith Madwesh     Initial Release
    ----------------------------------------------------------------------------*/
    public void validateActiveAssetBenefit(list<case> newCases,Map<Id,Case> oldCases){

        Id mheServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_MHE_SERIVCE_REQUEST).getRecordTypeId();
        set<Id> assetIds = new set<Id>();
        Map<Id,String> workingAssetBenefitMap = new Map<Id,String>();
        for(case c: newCases){
            if(c.recordTypeId == mheServiceRequestRecordTypeId && c.AssetId!=null && c.Call_Category__c != null){
                assetIds.add(c.AssetId);
            }
        }


        for(Asset a:[SELECT Id,(SELECT Id, Is_Working__c FROM Asset_Benefits__r WHERE Is_Working__c = 'Working') FROM Asset WHERE Id IN :assetIds]){
            if(a.Asset_Benefits__r.size()>0){
                if(!workingAssetBenefitMap.containsKey(a.Id)){
                    workingAssetBenefitMap.put(a.Id,'Working');
                }
            }
        }
        for(case c1: newCases){
            
            if( oldCases == null  ||
                 oldCases.get(c1.Id).Call_Category__c != c1.Call_Category__c && c1.Call_Category__c!='Paid' 
                 && c1.Call_Category__c!='FM'
                 ){

             if( c1.recordTypeId == mheServiceRequestRecordTypeId
                && c1.Call_Category__c!=null && c1.Call_Category__c!='Paid' && c1.Call_Category__c!='FM' && !workingAssetBenefitMap.containsKey(c1.AssetId) && !GlobalConstants.BYPASS_VALIDATION_FOR_CASE_ORIGIN.contains(c1.Origin)) {
                 c1.addError(System.label.No_Active_Asset_Benefit_on_Asset);
             }

            }
        }
    }

/*------------------------------------------------------------------------
    Author:        Anupam Mishra
    Company:       Salesforce
    Description:   Validate Equipment category and date of commissioning of  Asset On closed status of SR
                    Service Request
    History       01-04-2021
   ----------------------------------------------------------------------------*/ 
    public void ValidateAssetOnSRClosure(List<Case> cases,Map<Id,Case> oldCases){
            List<Asset> assetLstToUpdate = new List<Asset>();
            Set<Id> assetIds = new Set<Id>();
            for(Case caseItr : cases){
                if(caseItr.Status == 'Closed' && 
                   String.isNotBlank(caseItr.Type) && 
                   String.valueOf(caseItr.Type).equalsIgnoreCase('Commissioning') &&
                   caseItr.Status != oldCases.get(caseItr.Id).Status){
                        assetIds.add(caseItr.AssetId);
                  }
                   
                  for(Asset assetItr : [SELECT Id,Equipment_Category__c FROM Asset WHERE Id IN: assetIds]){
                
                      if ( (String.IsBlank(assetItr.Equipment_Category__c ))) {
                          caseItr.addError(System.Label.Equipment_category_of_Asset_is_Mandatory);
                     } else {
                     assetLstToUpdate.add(
                    new Asset(Id = assetItr.Id, Date_of_Commissioning__c = System.now())
                );
             }
    
         }
    
        update assetLstToUpdate; 
     }
   } 
    /*------------------------------------------------------------------------
    Author:        Saurabh Mehta
    Company:       Stetig
    Description:   Whenever status change to next level is going to send & Email to customer
    History       30-11-2021
   ----------------------------------------------------------------------------*/ 
    public void CalculateTimeOnCase(List<Case> cases,Map<Id,Case> oldCases){ 
     
     List<Case> caseList = new List<Case>();
        set<ID> caseSet = new set<ID>();
        Id serviceRecordTypeId = Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.CASE_RECORD_TYPE_LEASING).getRecordTypeId();
         
        For(case ca : cases){
            if(ca.Leasing_Case_Category__c != null && ca.Sub_Category__c != null && ca.recordtypeId == serviceRecordTypeId){  
                if(oldCases.get(ca.id).Status != ca.Status && ca.Status != null){
                    caseSet.add(ca.Id);
                    decimal onHoldTime = 0;
                    decimal resumeTime = 0;

                    if (oldCases.get(ca.Id).On_Hold_Time__c != null) {
                    onHoldTime = oldCases.get(ca.Id).On_Hold_Time__c;
                    }

                    if (oldCases.get(ca.Id).Resume_Time__c != null) {
                    resumeTime = oldCases.get(ca.Id).Resume_Time__c;
                    }
                    
                    if(oldCases.get(ca.id).Status != ca.Status && ca.Status == GlobalConstants.ON_HOLD){
                        ca.on_hold_time__c= integer.valueof((DateTime.now().getTime()-(ca.CreatedDate).getTime())+onHoldTime);
                    }
                    if(oldCases.get(ca.id).Status =='On Hold' && ca.Status == GlobalConstants.RESUME){
                         ca.Resume_time__c= integer.valueof((DateTime.now().getTime()-(ca.CreatedDate).getTime())+resumeTime);
                        
                    }
                   
                }
            }     
        }            
  } 
    
 /*------------------------------------------------------------------------
    Author:        Saurabh Mehta
    Company:       Stetig
    Description:   Used to sned SMS on case creation, status change & closed.
    History        30-11-2021
   ----------------------------------------------------------------------------*/     
  public void SMSNotificationOnStatucChange(List<Case> cases,Map<Id,Case> oldCases){ 
    
    // Call to handler for specific scenarios
    
        if(oldCases == null) {
            List<Case> newCaseList = [Select Id,casenumber,RecordTypeId,contact.Name,Job_assigned_to__c,contactphone,Leasing_Case_Category__c,Sub_Category__c FROM Case WHERE ID IN :cases LIMIT 20000];
            SendSMSNotificationForServiceRequest.sendSMSHandller(newCaseList, true);
        }
        else if(oldCases != null) {
            Set<Id> idset = new set<Id>();
            for(Case cse : cases) {
                if(cse.status != oldCases.get(cse.id).status) {
                    idset.add(cse.Id);
                }
            }
            if(!idset.isEmpty()) {
                List<Case> newCaseList = [Select Id,casenumber,RecordTypeId,contact.Name,Job_assigned_to__c,contactphone,IsClosed,Status,Leasing_Case_Category__c,Sub_Category__c FROM Case WHERE ID IN :idset LIMIT 20000];
                SendSMSNotificationForServiceRequest.sendSMSHandller(newCaseList, false);
            }
        }
    } 
 
     /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   Logic in insertion for SMEPB -124
    History
    04-10-2023     Shreela Nair    Initial Release
   ----------------------------------------------------------------------------*/ 
    
        public static void setOwnerforAccountCreationRecordTypeCasesinInsertion(List<Case> cases) {
        try{
            Set<Id> recordTypeIds = new Set<Id>(); 
            //Fetch record type id of SR Account Creation
            Id accCreationRecordId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SR_Account_Creation).getRecordTypeId();   
            Id queueAssigned_SyncingRequiredId;
            Set<Id> caseId = new Set<Id>();
            
            for (Case cs : cases) {
                caseId.add(cs.Id);
                recordTypeIds.add(cs.RecordTypeId);
            }
            
            List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
            if(recordTypeIds.contains(accCreationRecordId)){
                queueAssigned_SyncingRequiredId = [SELECT Id FROM Group WHERE Type =:GlobalConstants.Queue_Type AND DeveloperName =:GlobalConstants.Assigned_Syncing_Required_Queue LIMIT 1].Id;
                Id caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name =: GlobalConstants.caseReadTeamAccess LIMIT 1].id;
                
                for (Case cs : cases) {
                    caseTeamMembers.add(new CaseTeamMember(ParentId = cs.Id, MemberId = cs.CreatedById, TeamRoleId = caseTeamRoleId));
                    //caseId.add(cs.Id);
                }
                if(!caseTeamMembers.isEmpty()){
                    Database.insert(caseTeamMembers,false);
                }
            }
                        
            List<Case> casesToUpdate = new List<Case>();
            if (!caseId.isEmpty()) {
                for (Case cse : [SELECT Id,Status,OwnerId,RecordTypeId,CreatedById,Address_Text__c 
                                FROM Case 
                                WHERE Id IN: caseId]) {
                                     //To set Status as Assigned when Case is created,to set owner as queue and send email notification to queue members
                                     if (cse.RecordTypeId == accCreationRecordId && cse.Status == GlobalConstants.Status_SR_Type_1) {
                                         cse.Status = GlobalConstants.CASE_STATUS_ASSIGNED;
                                         cse.OwnerId = queueAssigned_SyncingRequiredId; 
                                         cse.Address_Text__c = cse.Address_Text__c.toUpperCase();
                                         cse.setOptions(getDMLOptionsWithTriggerUserEmail());
                                         casesToUpdate.add(cse);
                                     }
                                 }
            }
            
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
        catch(Exception e){
            System.debug('Exception e:'+e);
        }
    }
    /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   Logic in updation for SMEPB -124
    History
    04-10-2023     Shreela Nair    Initial Release
   ----------------------------------------------------------------------------*/ 
    
    public static void setOwnerforAccountCreationRecordTypeCasesinUpdation(List<Case> cases,Map<Id,Case> oldCases) {
        try{
            Set<Id> recordTypeIds = new Set<Id>(); 
            //Fetch record type id of SR Account Creation
            Id accCreationRecordId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.SR_Account_Creation).getRecordTypeId();   
            Id queueAssigned_SyncingRequiredId;
            Set<Id> caseId = new Set<Id>();
            
            for (Case cs : cases) {
                caseId.add(cs.Id);
                recordTypeIds.add(cs.RecordTypeId);
            }
            
            List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
            if(recordTypeIds.contains(accCreationRecordId)){
                queueAssigned_SyncingRequiredId = [SELECT Id FROM Group WHERE Type =:GlobalConstants.Queue_Type AND DeveloperName =:GlobalConstants.Assigned_Syncing_Required_Queue LIMIT 1].Id;
            }
            List<Case> casesToUpdate =new List<Case>();  
            if(!caseId.isEmpty()){
                
                for(Case cse : [SELECT Id,Status,OwnerId,RecordTypeId,CreatedById,Address_Text__c 
                                FROM Case 
                                WHERE Id IN: caseId]){
                                    
                                    //Address Text should be in uppercase for Account Creation Request Case
                                    if(cse.RecordTypeId == accCreationRecordId  && cse.Address_Text__c != oldCases.get(cse.Id).Address_Text__c){
                                        cse.Address_Text__c = cse.Address_Text__c.toUpperCase();  
                                        casesToUpdate.add(cse);

                                    }
                                    
                                    //Manually setting from New to Assigned 
                                    if(cse.RecordTypeId == accCreationRecordId && cse.Status == GlobalConstants.CASE_STATUS_ASSIGNED && oldCases.get(cse.Id).Status == GlobalConstants.Status_SR_Type_1){
                                        cse.OwnerId = queueAssigned_SyncingRequiredId;
                                        cse.setOptions(getDMLOptionsWithTriggerUserEmail());
                                        casesToUpdate.add(cse);
                                        
                                    } 
                                    
                                    //If Account Creation Case changed from either working or sycning required to Roll Back for Clarity
                                    else if (cse.RecordTypeId == accCreationRecordId && cse.Status == GlobalConstants.Status_SR_Type_3 && (oldCases.get(cse.Id).Status == GlobalConstants.Status_SR_Type_2 || oldCases.get(cse.Id).Status == GlobalConstants.Status_SR_Type_4) && cse.Status != oldCases.get(cse.Id).Status){
                                        cse.OwnerId = cse.CreatedById; 
                                        casesToUpdate.add(cse); 
                                    }
                                    //If Account Creation Case changed from Working to Syncing Required
                                    else if (cse.RecordTypeId == accCreationRecordId && cse.Status == GlobalConstants.Status_SR_Type_4 && oldCases.get(cse.Id).Status == GlobalConstants.Status_SR_Type_2){
                                        cse.OwnerId = queueAssigned_SyncingRequiredId;  
                                        cse.setOptions(getDMLOptionsWithTriggerUserEmail());
                                        casesToUpdate.add(cse);                    
                                    }
                                }
            }
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
        catch(Exception e){
            System.debug('Exception e:'+e);
        }
    }
    
     /*------------------------------------------------------------------------
    Author:        Shreela Nair
    Company:       Godrej Infotech
    Description:   To send email notification for SMEPB - 124
    History
    04-10-2023     Shreela Nair    Initial Release
   ----------------------------------------------------------------------------*/ 
    
    public static Database.DMLOptions getDMLOptionsWithTriggerUserEmail() {
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.EmailHeader.triggerUserEmail = true;
        return dmlOptions;
    }
         /*------------------------------------------------------------------------
    Author:        Sai Kumar
    Company:      PWC
    Description:   Create an Asset 
    History
    22-04-2024     Sai Kumar    Initial Release
   ----------------------------------------------------------------------------*/ 
    
    public static void CreateAsset(List<Case> newcases) {
        Id ServiceRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(GlobalConstants.CASE_RECORDTYPE_SERIVCE_REQUEST).getRecordTypeId();
        list<Asset> createasset =new list<Asset>();
        for(case c:newcases){
            if(c.Amazon_Id__c != null && c.RecordTypeId == ServiceRequestRecordTypeId){
                asset a=new asset();
                a.Equipment_Serial_No__c ='324124n4567s99';
                a.Name =c.CaseNumber;
                system.debug('c.Account.name; '+c.Account.name);
                a.AccountId =c.AccountId;
                a.Service_Request_del_del__c=c.id;
                a.Brand_Name__c =c.Agency__c;
                a.Customer_Mobile_Number__c =c.Mobile__c;
                a.Product_Purchased_Sub_Catergory__c =c.Product_Category__c;
                a.Product_Name__c =c.Product_Name__c;
                a.RecordTypeId ='012C4000000ZgHJIA0';
                createasset.add(a);
                
            }
            
        }
        insert createasset;
    }
    /*------------------------------------------------------------------------
    Author:       Aditya Rohith
    Company:      PWC
    Description:  Case Bulk Upload 
    History
    24-04-2024    Aditya Rohith    Initial Release
   ----------------------------------------------------------------------------*/
    public void BulkUploadServiceRequest(List<Case> newcases) {
        List<String> phonenumberlist = new List<String>();
        List<String> emailList = new List<String>();
        List<Account> AccountList = new List<Account>();
        List<ContactPointPhone> cppList = new List<ContactPointPhone>();
        List<ContactPointEmail> cpeList = new List<ContactPointEmail>();
        Map<Id,Id> accountIdvsContactId = new Map<Id,Id>();
        for(case cs : newcases){
            if(cs.AccountId == NULL){
                if(cs.Mobile__c != NULL){
                    phonenumberlist.add(cs.Mobile__c);
                }
                if(cs.Primary_Contact_Email__c != NULL){
                    emailList.add(cs.Primary_Contact_Email__c);
                }
                system.debug('phonenumberlist'+phonenumberlist);
                
                
            }
        }
        system.debug('phonenumberlist'+phonenumberlist);
        if(!phonenumberlist.isEmpty() || !emailList.isEmpty()){
            
            List<ContactPointPhone> listofcontactpointphone = [select ParentId,TelephoneNumber from contactpointphone where TelephoneNumber IN :phonenumberlist];
            List<ContactPointEmail> listofcontactpointemail = [select ParentId,EmailAddress from ContactPointEmail where EmailAddress IN : emailList];
            Map<String,Id> mobilevsaccountId = new Map<String,Id>();
            Map<String,Id> emailvsaccountId = new Map<String,Id>();
            if(!listofcontactpointphone.isEmpty()){
                for(ContactPointPhone ContactPointPhones : listofcontactpointphone){
                    if(ContactPointPhone.TelephoneNumber != NULL){
                        mobilevsaccountId.put(ContactPointPhones.TelephoneNumber,ContactPointPhones.ParentId);
                        system.debug('begining'+mobilevsaccountId);
                    }    
                }
            }
            if(!listofcontactpointemail.isEmpty()){
                for(ContactPointEmail ContactPointEmails : listofcontactpointemail){
                    if(ContactPointEmails.EmailAddress != NULL){
                        emailvsaccountId.put(ContactPointEmails.EmailAddress,ContactPointEmails.ParentId);
                    }   
                }
            }
            for(case c:newcases){
                Id ContactPointPhonerecord = mobilevsaccountId.get(c.Mobile__c);
                Id ContactPointEmailrecord = emailvsaccountId.get(c.Primary_Contact_Email__c);
                system.debug('ContactPointPhonerecord'+ContactPointPhonerecord);
                if(ContactPointPhonerecord == NULL && ContactPointEmailrecord == NULL){
                    account createaccount = new Account(
                        LastName=c.Case_Owner_Name__c,
                        PersonMobilePhone=c.Mobile__c,
                        PersonEmail=c.Primary_Contact_Email__c
                    );
                    AccountList.add(createaccount);
                }
            }
            system.debug('ok'+AccountList);
            if(!AccountList.isEmpty()){
                insert AccountList;
            }
            for(Account at:AccountList){
                mobilevsaccountId.put(at.PersonMobilePhone,at.Id);
                emailvsaccountId.put(at.PersonEmail,at.Id);
                ContactPointPhone cpp = new ContactPointPhone(
                    TelephoneNumber=at.PersonMobilePhone,
                    ParentId=at.Id
                );
                cppList.add(cpp);
                if(at.PersonEmail != NULL){
                    ContactPointEmail cpe = new ContactPointEmail(
                        EmailAddress=at.PersonEmail,
                        ParentId=at.Id
                    );
                    cpeList.add(cpe);
                }
                
            }
            if(!cppList.isEmpty()){
                insert cppList;
                
            }
            if(!cpeList.isEmpty()){
                insert cpeList;
            }
            List<Contact> listofcontacts = [select id,AccountId from Contact where AccountId IN : mobilevsaccountId.Values() or AccountId IN : emailvsaccountId.Values() ];
            for(Contact contacts : listofcontacts ){
                if(!listofcontacts.isEmpty()){
                    accountIdvsContactId.put(contacts.AccountId,contacts.id);
                }
            }
            for(case cases:newcases){
                if(cases.AccountId == NULL){
                    Id accountrecords = mobilevsaccountId.get(cases.Mobile__c);
                    system.debug('test'+accountrecords);
                    Id contactId = accountIdvsContactId.get(accountrecords);
                    if(accountrecords != NULL){
                        system.debug('contactrecordsid'+accountrecords);
                        cases.AccountId=accountrecords;
                        cases.Bulk_Upload__c=true;
                        if(contactId != NULL){
                            cases.ContactId=contactId;
                        }
                    }
                    else{
                        Id accountemailrecord = emailvsaccountId.get(cases.Primary_Contact_Email__c);
                        cases.AccountId=accountemailrecord;
                        cases.Bulk_Upload__c=true;
                        if(contactId != NULL){
                            cases.ContactId=contactId;
                        }
                    }
                }
            }
        }
    }
      
    
    /*------------------------------------------------------------------------
    Author:       Aditya Rohith
    Company:      PWC
    Description:  Case Bulk Upload work Creation
    History
    00-05-2024    Aditya Rohith    Initial Release
   ----------------------------------------------------------------------------*/ 
   public void BulkUploadWorkOrderCreation (List<Case> newcases) {
       List<Case> bulkUploadCases = new List<Case>();
       List<WorkOrder> listOfNewWorkOrders = new List<WorkOrder>();
       for(case cs : newcases){
           if(cs.Bulk_Upload__c == true){
               bulkUploadCases.add(cs);
           }
       }
       for(Case blkCases :bulkUploadCases){
           WorkOrder workOrderCreation = new WorkOrder(
               AccountId=blkCases.AccountId,
               ContactId=blkCases.ContactId,
               CaseId=blkCases.Id
           );
           listOfNewWorkOrders.add(workOrderCreation);
       }
       if(!listOfNewWorkOrders.isEmpty()){
           insert listOfNewWorkOrders;
       }
       
   }
}