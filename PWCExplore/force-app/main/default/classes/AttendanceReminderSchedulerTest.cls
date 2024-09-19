@isTest
public with sharing class AttendanceReminderSchedulerTest {
    static testmethod void schedulerTest(){
        Id sysAdminProfile=[Select Id From Profile Where Name='System Administrator'].Id;
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'Partner' Limit 1];         
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Appliances Door to Door Sales exec Partner User'].Id;
        User sysAdminUser = new TestUserBuilder().setLastName('AttendanceRemTest1').setProfileId(sysAdminProfile).setBusinessUnit('H')
            .getTestRecord();
        insert sysAdminUser;
        Account partnerAccount = new TestAccountBuilder().setBusinessUnit('H')
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId()).getSavedTestRecord();
        Contact partnerContact = new TestContactBuilder().setAccountId(partnerAccount.Id).getSavedTestRecord();
        Network networkRec = [SELECT Id FROM Network LIMIT 1];
        List<CollaborationGroup> chatterGroups = new List<CollaborationGroup>{
            new CollaborationGroup(Name = 'Appliances Community Test Group', CollaborationType = 'Public', NetworkId = networkRec.Id),
            new CollaborationGroup(Name = 'Appliances Test Group', CollaborationType = 'Public')};
        insert chatterGroups;
        System.runAs(sysAdminUser){
            testUserBuilder tub = new TestUserBuilder();
        	User partnerUser = tub.getPartnerUser();
        	partnerUser.persona__c = 'Appliances- Door to Door Sales executive';
            partnerUser.profileId=profileId;
        	update partnerUser;
        }
        Test.startTest();
        String CRON_EXP = '0 30 16 * * ? *';
            String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new AttendanceReminderScheduler(AttendanceReminderScheduler.NotificationType.STARTOFDAY));
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }
}