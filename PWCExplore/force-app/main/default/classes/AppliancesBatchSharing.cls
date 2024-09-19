/*-----------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Batch job for reports to updates. As it could have multiple
 *                        related records, async process is used
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 30-05-2020      Joshna Palla     Initial Release
 * ---------------------------------------------------------------------------------*/
public without sharing class AppliancesBatchSharing implements Database.Batchable<sObject>{
    Set<String> applianceProfiles = new Set<String>();
    String delimiter = ';';
    String draftStatusCode = 'Draft';

    public AppliancesBatchSharing() {
        for (Profile each: [SELECT Id, Name FROM Profile WHERE Name LIKE 'Appliance%' AND UserType = 'PowerPartner']) {
            applianceProfiles.add(each.Name);
        }
        applianceProfiles.addAll(System.Label.Appliances_L1_Profile.split(';'));
        applianceProfiles.add(System.Label.Appliances_L2_Profile);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Contact WHERE Has_Reports_To_Changed__c = true');
    }

    public void execute(Database.BatchableContext bc, List<Contact> contactRecords){
        List<sObject> relatedOpenRecords = new List<sObject>();
        Set<Id> partnerUsers = new Set<Id>();
        try {
            for (User each: [SELECT Id
                             FROM User
                             WHERE ContactId IN :contactRecords]) {
                partnerUsers.add(each.Id);
            }
            for (Lead each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                             FROM Lead 
                             WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND IsConverted = false]) {
                relatedOpenRecords.add(each);
            }
            for (Opportunity each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                                    FROM Opportunity 
                                    WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND IsClosed = false]) {
                relatedOpenRecords.add(each);
            }
            for (Order each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                              FROM Order 
                              WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND StatusCode = :draftStatusCode]) {
                relatedOpenRecords.add(each);
            }
            for (Attendance__c each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                                FROM Attendance__c 
                                WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND 
                                Approval_Status__c = :draftStatusCode]) {
                relatedOpenRecords.add(each);
            }
            for (Receivable__c each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                                FROM Receivable__c 
                                WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND 
                                Document_Date__c = THIS_YEAR]) {
                relatedOpenRecords.add(each);
            }
            for (Billed_Sales_Outstandings__c each: [SELECT Id, OwnerId, Level_1__c, Level_2__c
                                FROM Billed_Sales_Outstandings__c 
                                WHERE OwnerId IN :partnerUsers AND Owner.Profile.Name IN :applianceProfiles AND 
                                Document_Date__c = THIS_YEAR]) {
                relatedOpenRecords.add(each);
            }

            SharingUtility.setParentContacts(relatedOpenRecords, null, true, false);
            for(Contact each: contactRecords) {
                each.Has_Reports_To_Changed__c = false;
            }
            update contactRecords;
        } catch (Exception ex) {
            Logger.logError(AppliancesBatchSharing.class.getName(), 'execute', null, ex);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}