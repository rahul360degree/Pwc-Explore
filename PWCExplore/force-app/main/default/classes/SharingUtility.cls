/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Sharing utility for Appliances for Lead, Opportunity & Order
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 30-05-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public without sharing class SharingUtility {
    static final String OWNERIDFIELDNAME = 'OwnerId';
    static final String CREATEDBYIDFIELDNAME = 'CreatedById';
    static final String LEVEL0FIELDNAME = 'Level_0__c';
    static final String LEVEL1FIELDNAME = 'Level_1__c';
    static final String LEVEL2FIELDNAME = 'Level_2__c';
    static final String DELIMITER = ';';
    @TestVisible static Boolean hasSharingUtilityRun = false;
    
    /* Utility class that accepts new records for Leads, Opps and order
     * For each record type, it uses created by to fetch the reports to users
     * Sets them in L0 & L1 fields
     */
    public static void setParentContacts(List<sObject> newRecords, Map<Id, sObject> oldRecordMap, Boolean executeDML, Boolean isLead) {
        try {
            if (hasSharingUtilityRun) {
                return;
            } else {
                hasSharingUtilityRun = true;
            }
            Map<Id, String> contactIdToUserMap = new Map<Id, String>();
            Set<Id> reportsToUsers = new Set<Id>();
            Map<Id, User> userMap = new Map<Id, User>();
            Map<String, String> applianceProfileToFieldMap = new Map<String, String>();
            Set<Id> userIds = new Set<Id>();
            Id loggedInUserId = UserInfo.getUserId();
            Boolean isInsertOrBatch = oldRecordMap == null ? true : false;
            
            for (String each : Label.Appliances_L1_Profile.split(';')) {
                applianceProfileToFieldMap.put(each, LEVEL1FIELDNAME);
            }
            applianceProfileToFieldMap.put(System.Label.Appliances_L2_Profile, LEVEL2FIELDNAME);
            
            // Lead insertion only needs access to be provisioned for lead created by
            // as the owner changes to queue
            if (isInsertOrBatch && isLead) {
                userIds.add(loggedInUserId);
            } else {
                // For all other scenarios, get owner on insert or update when owner changes
                // this includes lead owner update
                // opp & order insert
                // opp & order owner update
                for (sObject each: newRecords) {
                    if (isInsertOrBatch || ((Id) oldRecordMap.get(each.Id).get(OWNERIDFIELDNAME) != (Id) each.get(OWNERIDFIELDNAME))) {
                        if (isLead) {
                            each.put(LEVEL0FIELDNAME, null);
                        }
                        each.put(LEVEL1FIELDNAME, null);
                        each.put(LEVEL2FIELDNAME, null);
                        userIds.add((Id) each.get(OWNERIDFIELDNAME));
                    }
                }
            }
            
            if (userIds.isEmpty()) {
                return;
            }
            
            for (User each: [SELECT Id, ContactId, Contact.ReportsToId, Contact.ReportsTo.ReportsToId, Profile.Name
                             FROM User
                             WHERE Id IN :userIds]) {
               // Fetch users for L0 irrespective of their profile. This is needed for Lead sharing
               if (String.isNotBlank(each.ContactId)) {
                   userMap.put(each.Id, each);
                   if (String.isNotBlank(each.Contact.ReportsToId)) {
                       reportsToUsers.add(each.Contact.ReportsToId);
                       if (String.isNotBlank(each.Contact.ReportsTo.ReportsToId)) {
                           reportsToUsers.add(each.Contact.ReportsTo.ReportsToId);
                       }
                   }
               }
            }

            if (userMap.isEmpty()) {
                return;
            }

            if(!reportsToUsers.isEmpty()) {
                // Get L1 & L2 only for appliance profiles as it applies only to that BU
                for (User each: [SELECT Id, Profile.Name, ContactId
                                 FROM User
                                 WHERE ContactId IN :reportsToUsers AND Profile.Name IN :applianceProfileToFieldMap.keySet()]) {
                    contactIdToUserMap.put(each.ContactId, each.Profile.Name);
                }
            }

            for (sObject each: newRecords) {
                // Set to null in case the lead is cloned, we wouldn't want the same values copied
                Id userId = (Id) each.get(OWNERIDFIELDNAME);

                if (isInsertOrBatch && isLead) {
                    userId = loggedInUserId;
                    if (userMap.containsKey(userId)) {
                        if (applianceProfileToFieldMap.containsKey(userMap.get(userId).Profile.Name)) {
                            each.put(applianceProfileToFieldMap.get(userMap.get(userId).Profile.Name), userMap.get(userId).ContactId);
                        } else {
                            each.put(LEVEL0FIELDNAME, userMap.get(userId).ContactId);
                        }
                    } else {
                        each.put(LEVEL0FIELDNAME, null);
                    }
                    continue;
                }

                // If user is a partner
                if (userMap.containsKey(userId)) {
                    // Appliance L1 scenario
                    if (String.isNotBlank(userMap.get(userId).Contact.ReportsToId) && contactIdToUserMap.containsKey(userMap.get(userId).Contact.ReportsToId)) {
                        each.put(applianceProfileToFieldMap.get(contactIdToUserMap.get(userMap.get(userId).Contact.ReportsToId)), userMap.get(userId).Contact.ReportsToId);
                    }
                    // Appliance L2 scenario
                    if (String.isNotBlank(userMap.get(userId).Contact.ReportsTo.ReportsToId) && contactIdToUserMap.containsKey(userMap.get(userId).Contact.ReportsTo.ReportsToId)) {
                        each.put(applianceProfileToFieldMap.get(contactIdToUserMap.get(userMap.get(userId).Contact.ReportsTo.ReportsToId)), userMap.get(userId).Contact.ReportsTo.ReportsToId);
                    }
                }
            }
            if (executeDML) {
                update newRecords;
            }
        } catch (Exception ex) {
            Logger.logError(SharingUtility.class.getName(), 'execute', null, ex);
        }
    }
}