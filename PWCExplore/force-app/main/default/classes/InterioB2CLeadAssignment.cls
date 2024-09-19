/**
 * @Description       : This class will be called from the trigger to assign the Lead as per new LDM SIEPB-127
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-23-2024
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   01-01-2024   Varun Rajpoot   Initial Version
**/

/*components:
Fields:
    user.Lead_Assignment_Indicatior__c, user.isOnVacation
    Zip_Code_Rule__r.Account__c
Class: 
    InterioB2CLeadAssignment
LeadFieldPopulator
    Rename profile:
Interio B2C VFD-Kitchen COCO Team User to Interio B2C VFD COCO Team User// change the reference in the test class

Flow:
1. Lead: After Update
2. Disable FacebookLeadRecordTypeUpdate flow
*/


public with sharing class InterioB2CLeadAssignment {
    private static FINAL String KITCHEN_PROFILE = 'Interio B2C Kitchen Dealer Partner User';
    private static FINAL String VFD_CRA_PROFILE = 'Interio B2C VFD CRA user';
    private static FINAL String VFD_CRE_DEALER_PROFILE = 'Interio B2C VFD Dealer Partner User';
    private static FINAL String VFD_COCO_PROFILE = 'Interio B2C VFD COCO Team User';

    @future
    public static void initLeadAssignment(Set<Id> leadIds){
        List<Lead> leadRecordList = getLeads(leadIds);
        if(leadRecordList.isEmpty()){
            return;
        }
        
        List<User> userList = getUsers(leadRecordList);
        if(userList.isEmpty()){
            return;
        }

        Map<Id,List<User>> accountIdVsUserList = getAccountIdVsUserList(userList);
        if(accountIdVsUserList.isEmpty()){
            return;
        }
        
        Map<String,Set<Id>> queueVsUserIdSet = getQueueVsUserIdSet(leadRecordList);
        // if(queueVsUserIdSet.isEmpty()){
        //     return;
        // }

        assignLeadOwner(leadRecordList,accountIdVsUserList,queueVsUserIdSet);

        LeadTriggerHandler.TriggerDisabled = true;
        Database.update(leadRecordList,false);
        Database.update(userList,false);
    }

    //Get Lead Data
    private Static List<Lead> getLeads(Set<Id> leadIds){
        String query = 'Select Id, Interio_Sub_Division__c, Zip_Code_Rule__c,'
                +' Zip_Code_Rule__r.Account__c, Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c,Zip_Code_Rule__r.Queue_1__c,Zip_Code_Rule__r.Account__r.Account_Code__c'
			   +' From Lead where '
               +' Applicable_For_Pincode_Based_Assignment__c = true '
			   +' AND ZipCode__c != null '
			   +' AND Zip_Code_Rule__c != null '
               +' AND Zip_Code_Rule__r.Account__c !=null'
               +' AND ID IN:leadIds ';
               //+' AND OnwerId=:Interio Default B2C Queue'
               return Database.query(query);
    }

    //get user queuebias for the where Queue based assignment is possible.
    private Static Map<String,Set<Id>> getQueueVsUserIdSet(List<Lead> leadRecordList){
        Set<String> queueNameSet = new Set<String> ();
        for(Lead lead:leadRecordList){
            System.debug(lead.Zip_Code_Rule__r.Queue_1__c);
            if(lead.Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c && !String.isEmpty(lead.Zip_Code_Rule__r.Queue_1__c)){
                queueNameSet.add(lead.Zip_Code_Rule__r.Queue_1__c);
            }
        }
        System.debug(queueNameSet);
        List<GroupMember> groupMember = [SELECT Id, Group.Type,UserOrGroupId,Group.DeveloperName FROM GroupMember where Group.Type = 'Queue' AND Group.DeveloperName IN:queueNameSet limit 10000 ];
        Map<String,Set<Id>> queueVsUserIdSet = new Map<String,Set<Id>> ();
        for(GroupMember gMember:groupMember){
            if(gMember.UserOrGroupId.getSObjectType() == Schema.User.sObjectType){
                if(!queueVsUserIdSet.containsKey(gMember.Group.DeveloperName)){
                    queueVsUserIdSet.put(gMember.Group.DeveloperName,new Set<Id>());
                }
                queueVsUserIdSet.get(gMember.Group.DeveloperName).add(gMember.UserOrGroupId);
            }
        }
        System.debug(queueVsUserIdSet);
        return queueVsUserIdSet;
    }

    //get all the users for the Accounts
    private static List<User> getUsers(List<Lead> leadRecordList){
        Set<Id> accountIdSet = new Set<Id>();
        for(Lead lead:leadRecordList){
            accountIdSet.add(lead.Zip_Code_Rule__r.Account__c);
        }
        if(accountIdSet.isEmpty()){
            return null;
        }else{
            Set<String> allowedProfiles = new Set<String>{KITCHEN_PROFILE, VFD_CRA_PROFILE, VFD_CRE_DEALER_PROFILE, VFD_COCO_PROFILE};
            String query = 'Select Id,Account__c,Lead_Assignment_Indicatior__c '
                            +' from User'
                            +' where'
                            +' Account__c IN: accountIdSet'
                            +' AND isActive = true'
                            +' AND isOnVacation__c = false'
                            +' AND Profile.Name IN : allowedProfiles';

            return Database.query(query);
        }
    }

    private static Map<Id,List<User>> getAccountIdVsUserList(List<User> userList){
        Map<Id,List<User>> accountIdVsUserList = new Map<Id,List<User>>();
        for(User user: userList){
            if(!accountIdVsUserList.containsKey(user.Account__c)){
                accountIdVsUserList.put(user.Account__c, new List<User>());
            }
            accountIdVsUserList.get(user.Account__c).add(user);
        }
        return accountIdVsUserList;
    }


    private static User getOwner(Lead lead, List<User> zipCodeUsers){
        User ownerUser;
        for(User user : zipCodeUsers){
                if(!user.Lead_Assignment_Indicatior__c){
                    ownerUser = user;			
                    break;
                }
        }
        
        
        if(ownerUser == null){
            for(User user:zipCodeUsers){
                user.Lead_Assignment_Indicatior__c = false;
            }
            ownerUser = zipCodeUsers[0];
        }

        return ownerUser;
    }


    private static void assignLeadOwner(List<Lead> leadRecords, Map<Id,List<User>> accountIdVsUserList, Map<String,Set<Id>> queueVsUserIdSet){
        for(Lead lead:leadRecords){
            User ownerUser;            
            List<User> zipCodeUsers = new List<User>();
            if(lead.Zip_Code_Rule__r.Run_Round_Robin_on_Queue1__c){
                List<User> tempUserList = accountIdVsUserList.get(lead.Zip_Code_Rule__r.Account__c);
                for(User tempUser:tempUserList){
                    if(queueVsUserIdSet.containsKey(lead.Zip_Code_Rule__r.Queue_1__c)){
                        Set<Id> userIdSet = queueVsUserIdSet.get(lead.Zip_Code_Rule__r.Queue_1__c);
                        if(userIdSet.contains(tempUser.Id)){
                            zipCodeUsers.add(tempUser);
                        }
                    }
                }

            }else{
                zipCodeUsers = accountIdVsUserList.get(lead.Zip_Code_Rule__r.Account__c);
            }
            
            
            if(zipCodeUsers.isEmpty()){
                break;
            }
            System.debug(zipCodeUsers);
            ownerUser = getOwner(lead,zipCodeUsers);
            lead.OwnerId = ownerUser.Id;				
            
            if(lead.Interio_Sub_Division__c == GlobalConstants.INTERIO_KITCHEN){
                lead.Channel__c = GlobalConstants.ChannelKitchen;
            }
            else if(lead.Interio_Sub_Division__c == GlobalConstants.INTERIO_VFD){
                if(!String.isEmpty(lead.Zip_Code_Rule__r.Account__r.Account_Code__c)){
                    String accountCode =''+lead.Zip_Code_Rule__r.Account__r.Account_Code__c;
                    if(accountCode.startsWithIgnoreCase('WWC')){
                        lead.Channel__c = GlobalConstants.ChannelCocoStores;
                    }else if(accountCode.startsWithIgnoreCase('WFX')){
                        lead.Channel__c = GlobalConstants.ChannelFranchisee;
                    }else if(accountCode.startsWithIgnoreCase('WDX')){
                        lead.Channel__c = GlobalConstants.ChannelDealer;
                    }
                }
            }
            ownerUser.Lead_Assignment_Indicatior__c = true;
        }
    }
}