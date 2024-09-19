/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test class for AppliancesBatchSharing, SharingUtility,
 *                        AppliancesScheduleSharing & trigger invocations
 * History
 * --------
 * 27-07-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class AppliancesBatchSharingTest {
    static final String D2D_PARTNER_PROFILE = 'Appliances Door to Door Sales exec Partner User';
    static final String ADMIN_PROFILE = 'System Administrator';
    static final List<String> USER_LAST_NAMES_LIST = new List<String>{
        'OriginalL2', 'Level1User', 'D2DUser', 'UpdatedL2', 'AdminD2DTest'
    };
    static final String L1_PROFILE = Label.Appliances_L1_Profile.split(';')[0];

    @TestSetup static void createData(){
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = :ADMIN_PROFILE];
        UserRole appliancesRole = [SELECT Id FROM UserRole WHERE Name = 'Appliances'];
        User newAdminuser = new TestUserBuilder().setLastName('AdminD2DTest').setProfileId(adminProfile.Id).setUserRoleId(appliancesRole.Id)
            .setSalaryCode('ADMIN123').getSavedTestRecord();
        
        System.runAs(newAdminuser) {
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();

            List<Contact> partnerContacts = new List<Contact> {
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord()
            };
            insert partnerContacts;
            partnerContacts[1].ReportsToId = partnerContacts[0].Id;
            partnerContacts[2].ReportsToId = partnerContacts[1].Id;
            update new List<Contact>{partnerContacts[1], partnerContacts[2]};

            Set<String> applianceProfileNames = new Set<String>{L1_PROFILE, Label.Appliances_L2_Profile, D2D_PARTNER_PROFILE};
            Map<String, Id> profileMap = new Map<String, Id>();
            for (Profile each : [SELECT Id, Name FROM Profile WHERE Name IN :applianceProfileNames]) {
                profileMap.put(each.Name, each.Id);
            }

            List<User> partnerUsers = new List<User> {
                new TestUserBuilder().setLastName(USER_LAST_NAMES_LIST[0]).setProfileId(profileMap.get(Label.Appliances_L2_Profile))
                    .setContactId(partnerContacts[0].Id).setBusinessUnit('H').getTestRecord(),
                new TestUserBuilder().setLastName(USER_LAST_NAMES_LIST[1]).setProfileId(profileMap.get(L1_PROFILE))
                    .setContactId(partnerContacts[1].Id).setBusinessUnit('H').getTestRecord(),
                new TestUserBuilder().setLastName(USER_LAST_NAMES_LIST[2]).setPersona('Appliances- Door to Door Sales executive').setProfileId(profileMap.get(D2D_PARTNER_PROFILE))
                    .setContactId(partnerContacts[2].Id).setBusinessUnit('H').getTestRecord(),
                new TestUserBuilder().setLastName(USER_LAST_NAMES_LIST[3]).setProfileId(profileMap.get(Label.Appliances_L2_Profile))
                    .setBusinessUnit('H').setContactId(partnerContacts[3].Id).getTestRecord()
            };
            insert partnerUsers;
                   
            Apex_Batch_Configurations__c abc = new Apex_Batch_Configurations__c(Name = 'AppliancesScheduleSharing', Batch_Size__c = 10);
            insert abc;
        }
        
    }

    @isTest private static void reportsToUpdatesShouldBeReplicatedOnLead() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Lead newD2DLead;

        // Create new Lead as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DLead = new TestLeadBuilder()
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Appliances_B2C_Lead').getRecordTypeId())
                .setBusinessUnit('H').setOwnerId(partnerUsersMap.get(ADMIN_PROFILE).get(0).Id).getSavedTestRecord();
        }

        // Validate that Level 1 & Level 2 is updated appropriate - this is via trigger
        Lead updatedLead = [SELECT Id, Level_0__c FROM Lead WHERE Id = :newD2DLead.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0).ContactId, updatedLead.Level_0__c, 'Level 0 user not updated on Lead creation');

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        updatedLead.OwnerId = partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0).Id;
        update updatedLead;
        updatedLead = [SELECT Id, Level_1__c, Level_2__c FROM Lead WHERE Id = :newD2DLead.Id];
        System.assertEquals(originalL2User.ContactId, updatedLead.Level_2__c, 'Level 2 user not updated on Lead update');
        System.assertEquals(level1User.ContactId, updatedLead.Level_1__c, 'Level 1 user not updated on Lead update');

        // Update reports to on contact and ensure the reports to is updated
        Contact reportsToUpdate = new Contact(Id = level1User.ContactId, ReportsToId = newL2User.ContactId);
        update reportsToUpdate;
        Contact updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(true, updatedContact.Has_Reports_To_Changed__c, 'Reports To update is not flagged');

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        Database.executeBatch(new AppliancesBatchSharing());
        Test.stopTest();

        updatedLead = [SELECT Id, Level_1__c, Level_2__c FROM Lead WHERE Id = :newD2DLead.Id];
        updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(false, updatedContact.Has_Reports_To_Changed__c, 'Reports To updated flag is not reset after batch is run');
        System.assertEquals(newL2User.ContactId, updatedLead.Level_2__c, 'Level 2 user not updated after batch execution');
    }

    @isTest private static void reportsToUpdatesShouldBeReplicatedOnOrder() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Order newD2DOrder;
        Account partnerAccount = [SELECT Id FROM Account];

        // Create new Order as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOrder = new TestOrderBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Order updatedOrder = [SELECT Id, Level_1__c, Level_2__c FROM Order WHERE Id = :newD2DOrder.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOrder.Level_2__c, 'Level 2 user not updated on Order creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOrder.Level_1__c, 'Level 1 user not updated on Irder creation');

        // Update reports to on contact and ensure the reports to is updated
        Contact reportsToUpdate = new Contact(Id = level1User.ContactId, ReportsToId = newL2User.ContactId);
        update reportsToUpdate;
        Contact updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(true, updatedContact.Has_Reports_To_Changed__c, 'Reports To update is not flagged');

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        Database.executeBatch(new AppliancesBatchSharing());
        Test.stopTest();

        updatedOrder = [SELECT Id, Level_1__c, Level_2__c FROM Order WHERE Id = :newD2DOrder.Id];
        updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(false, updatedContact.Has_Reports_To_Changed__c, 'Reports To updated flag is not reset after batch is run');
        System.assertEquals(newL2User.ContactId, updatedOrder.Level_2__c, 'Level 2 user not updated after batch execution');
    }

    @isTest private static void reportsToUpdatesShouldBeReplicatedOnOpportunity() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Opportunity newD2DOpportunity;
        Account partnerAccount = [SELECT Id FROM Account];

        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOpportunity = new TestOpportunityBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Opportunity updatedOpportunity = [SELECT Id, Level_1__c, Level_2__c FROM Opportunity WHERE Id = :newD2DOpportunity.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOpportunity.Level_2__c, 'Level 2 user not updated on Opportunity creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOpportunity.Level_1__c, 'Level 1 user not updated on Opportunity creation');

        // Update reports to on contact and ensure the reports to is updated
        Contact reportsToUpdate = new Contact(Id = level1User.ContactId, ReportsToId = newL2User.ContactId);
        update reportsToUpdate;
        Contact updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(true, updatedContact.Has_Reports_To_Changed__c, 'Reports To update is not flagged');

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        Database.executeBatch(new AppliancesBatchSharing());
        Test.stopTest();

        updatedOpportunity = [SELECT Id, Level_1__c, Level_2__c FROM Opportunity WHERE Id = :newD2DOpportunity.Id];
        updatedContact = [SELECT Id, Has_Reports_To_Changed__c FROM Contact WHERE Id = :reportsToUpdate.Id];
        System.assertEquals(false, updatedContact.Has_Reports_To_Changed__c, 'Reports To updated flag is not reset after batch is run');
        System.assertEquals(newL2User.ContactId, updatedOpportunity.Level_2__c, 'Level 2 user not updated after batch execution');
    }

    @isTest private static void newLeadCreationShouldSetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Lead newD2DLead;

        Test.startTest();
        // Create new Lead as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DLead = new TestLeadBuilder()
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Appliances_B2C_Lead').getRecordTypeId())
                .setBusinessUnit('H').setOwnerId(partnerUsersMap.get(ADMIN_PROFILE).get(0).Id).getSavedTestRecord();
        }
        Test.stopTest();

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Lead updatedLead = [SELECT Id, Level_0__c FROM Lead WHERE Id = :newD2DLead.Id];
        System.assertEquals(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0).ContactId, updatedLead.Level_0__c, 'Level 0 user not updated on Lead creation');
    }

    @isTest private static void updatingLeadOwnerShouldResetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Lead newD2DLead;

        // Create new Lead as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DLead = new TestLeadBuilder()
                .setRecordTypeId(Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Appliances_B2C_Lead').getRecordTypeId())
                .setBusinessUnit('H').setOwnerId(partnerUsersMap.get(ADMIN_PROFILE).get(0).Id).getSavedTestRecord();
        }

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Lead updatedLead = [SELECT Id, Level_0__c FROM Lead WHERE Id = :newD2DLead.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0).ContactId, updatedLead.Level_0__c, 'Level 0 user not updated on Lead creation');

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        updatedLead.OwnerId = partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0).Id;

        Test.startTest();
        update updatedLead;
        Test.stopTest();

        updatedLead = [SELECT Id, Level_1__c, Level_2__c FROM Lead WHERE Id = :newD2DLead.Id];
        System.assertEquals(originalL2User.ContactId, updatedLead.Level_2__c, 'Level 2 user not updated on Lead update');
        System.assertEquals(level1User.ContactId, updatedLead.Level_1__c, 'Level 1 user not updated on Lead update');
    }

    @isTest private static void newOrderCreationShouldSetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Order newD2DOrder;
        Account partnerAccount = [SELECT Id FROM Account];

        Test.startTest();
        // Create new Order as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOrder = new TestOrderBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }
        Test.stopTest();

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Order updatedOrder = [SELECT Id, Level_1__c, Level_2__c FROM Order WHERE Id = :newD2DOrder.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOrder.Level_2__c, 'Level 2 user not updated on Order creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOrder.Level_1__c, 'Level 1 user not updated on Irder creation');
    }

    @isTest private static void updatingOrderOwnerShouldResetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Order newD2DOrder;
        Account partnerAccount = [SELECT Id FROM Account];

        // Create new Order as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOrder = new TestOrderBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }
        
        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Order updatedOrder = [SELECT Id, Level_1__c, Level_2__c FROM Order WHERE Id = :newD2DOrder.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOrder.Level_2__c, 'Level 2 user not updated on Order creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOrder.Level_1__c, 'Level 1 user not updated on Irder creation');

        updatedOrder.OwnerId = UserInfo.getUserId();
        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        update updatedOrder;
        Test.stopTest();
        updatedOrder = [SELECT Id, Level_1__c, Level_2__c FROM Order WHERE Id = :newD2DOrder.Id];
        System.assertEquals(null, updatedOrder.Level_2__c, 'Level 2 user not updated on Order update');
        System.assertEquals(null, updatedOrder.Level_1__c, 'Level 1 user not updated on Order update');
    }

    @isTest private static void newOpportunityCreationShouldSetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Opportunity newD2DOpportunity;
        Account partnerAccount = [SELECT Id FROM Account];

        Test.startTest();
        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOpportunity = new TestOpportunityBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }
        Test.stopTest();

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Opportunity updatedOpportunity = [SELECT Id, Level_1__c, Level_2__c FROM Opportunity WHERE Id = :newD2DOpportunity.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOpportunity.Level_2__c, 'Level 2 user not updated on Opportunity creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOpportunity.Level_1__c, 'Level 1 user not updated on Opportunity creation');
    }

    @isTest private static void updatingOpportunityOwnerShouldResetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Opportunity newD2DOpportunity;
        Account partnerAccount = [SELECT Id FROM Account];

        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newD2DOpportunity = new TestOpportunityBuilder().setAccountId(partnerAccount.Id)
                .setRecordTypeId(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Interio_B2C_Appliances').getRecordTypeId())
                .setBusinessUnit('H').getSavedTestRecord();
        }
        
        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Opportunity updatedOpportunity = [SELECT Id, Level_1__c, Level_2__c FROM Opportunity WHERE Id = :newD2DOpportunity.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedOpportunity.Level_2__c, 'Level 2 user not updated on Opportunity creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedOpportunity.Level_1__c, 'Level 1 user not updated on Opportunity creation');

        updatedOpportunity.OwnerId = UserInfo.getUserId();
        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        update updatedOpportunity;
        Test.stopTest();
        updatedOpportunity = [SELECT Id, Level_1__c, Level_2__c FROM Opportunity WHERE Id = :newD2DOpportunity.Id];
        System.assertEquals(null, updatedOpportunity.Level_2__c, 'Level 2 user not updated on Opportunity update');
        System.assertEquals(null, updatedOpportunity.Level_1__c, 'Level 1 user not updated on Opportunity update');
    }


    @isTest private static void newAttendanceCreationShouldSetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Attendance__c newAttendance;
        Account partnerAccount = [SELECT Id FROM Account];

        Test.startTest();
        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newAttendance = new TestAttendanceBuilder().setStartOfDayTime(System.now().addDays(-1)).setEndOfDayTime(System.now().addDays(-1).addHours(1))
                .setTypeValue('Leave').setAutoSubmit(false).getSavedTestRecord();
        }
        Test.stopTest();

        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Attendance__c updatedAttendance = [SELECT Id, Level_1__c, Level_2__c FROM Attendance__c WHERE Id = :newAttendance.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedAttendance.Level_2__c, 'Level 2 user not updated on Attendance creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedAttendance.Level_1__c, 
        'Level 1 user not updated on Attendance creation');
    }

    @isTest private static void updatingAttendanceOwnerShouldResetHierarchy() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Attendance__c newAttendance;
        Account partnerAccount = [SELECT Id FROM Account];

        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            newAttendance = new TestAttendanceBuilder().setStartOfDayTime(System.now().addDays(-1)).setEndOfDayTime(System.now().addDays(-1).addHours(1))
                .setTypeValue('Leave').setAutoSubmit(false).getSavedTestRecord();
        }
        
        // Validate that Level 1 & Level 2 is updated appropriately - this is via trigger
        Attendance__c updatedAttendance = [SELECT Id, Level_1__c, Level_2__c FROM Attendance__c WHERE Id = :newAttendance.Id];
        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }
        System.assertEquals(originalL2User.ContactId, updatedAttendance.Level_2__c, 'Level 2 user not updated on Attendance creation');
        System.assertEquals(partnerUsersMap.get(L1_PROFILE).get(0).ContactId, updatedAttendance.Level_1__c,
         'Level 1 user not updated on Attendance creation');

         updatedAttendance.OwnerId = UserInfo.getUserId();
        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        update updatedAttendance;
        Test.stopTest();
        updatedAttendance = [SELECT Id, Level_1__c, Level_2__c FROM Attendance__c WHERE Id = :newAttendance.Id];
        System.assertEquals(null, updatedAttendance.Level_1__c, 'Level 1 user not updated on Attendance update');
    }


    @isTest private static void executingSchedulerShouldScheduleBatchJob() {
        String cronExpression = '0 0 0 1/1 * ? *';
        Test.startTest();
        String jobId = System.schedule('Appliances Batch Share', cronExpression, new AppliancesScheduleSharing());
        Test.stopTest();

        CronTrigger cronInstance = [SELECT Id, CronExpression, NextFireTime, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, cronInstance.CronExpression, 'Failed to scheduled the batch job');
        System.assertEquals(0, cronInstance.TimesTriggered, 'Job has run ' + cronInstance.TimesTriggered + ' number of times');
        Date nextFireDate = Date.newinstance(cronInstance.NextFireTime.year(), cronInstance.NextFireTime.month(), cronInstance.NextFireTime.day());
        DateTime nextDayDateTime = DateTime.now().addDays(1);
        Date nextDay = Date.newinstance(nextDayDateTime.year(), nextDayDateTime.month(), nextDayDateTime.day());
        System.assertEquals(nextDay, nextFireDate, 'Job schedule is at an unexpected time: ' + cronInstance.NextFireTime);
    }

    private static Map<String, List<User>> getPartnerUsersByProfile() {
        Map<String, List<User>> userMap = new Map<String, List<User>>();
        for (User each: [SELECT Id, Profile.Name, ContactId, LastName FROM User WHERE LastName IN :USER_LAST_NAMES_LIST]) {
            if (userMap.containsKey(each.Profile.Name)) {
                userMap.get(each.Profile.Name).add(each);
            } else {
                userMap.put(each.Profile.Name, new List<User>{each});
            }
        }
        return userMap;
    }

    @isTest private static void reportsToUpdatesShouldBeReplicatedOnCustomObjects() {
        Map<String, List<User>> partnerUsersMap = getPartnerUsersByProfile();
        Attendance__c attendanceRecord;
        Billed_Sales_Outstandings__c bsoRecord;
        Receivable__c receivableRecord;

        // Create new Opportunity as a D2D user
        System.runAs(partnerUsersMap.get(D2D_PARTNER_PROFILE).get(0)) {
            attendanceRecord = new TestAttendanceBuilder().setStartOfDayTime(System.now().addDays(-1)).setEndOfDayTime(System.now().addDays(-1).addHours(1))
                .setTypeValue('Leave').setAutoSubmit(false).getSavedTestRecord();
            bsoRecord = new TestBilledSalesOutstandingsBuilder().getSavedTestRecord();
            receivableRecord = new TestReceivableBuilder().getSavedTestRecord();
        }

        User originalL2User;
        User newL2User;
        User level1User = partnerUsersMap.get(L1_PROFILE).get(0);
        for (User each : partnerUsersMap.get(System.Label.Appliances_L2_Profile)) {
            if (each.LastName.equals('OriginalL2')) {
                originalL2User = each;
            } else {
                newL2User = each;
            }
        }

        // Update reports to on contact and ensure the reports to is updated
        Contact reportsToUpdate = new Contact(Id = level1User.ContactId, ReportsToId = newL2User.ContactId);
        update reportsToUpdate;

        // Reset the static check for test method. In usual scenarios, this will be a separate transaction
        SharingUtility.hasSharingUtilityRun = false;
        Test.startTest();
        Database.executeBatch(new AppliancesBatchSharing());
        Test.stopTest();

        attendanceRecord = [SELECT Id, Level_1__c, Level_2__c FROM Attendance__c WHERE Id = :attendanceRecord.Id];
        bsoRecord = [SELECT Id, Level_1__c, Level_2__c FROM Billed_Sales_Outstandings__c WHERE Id = :bsoRecord.Id];
        receivableRecord = [SELECT Id, Level_1__c, Level_2__c FROM Receivable__c WHERE Id = :receivableRecord.Id];
        System.assertEquals(newL2User.ContactId, attendanceRecord.Level_2__c, 'Level 2 user not updated on Attendance record after batch execution');
        System.assertEquals(newL2User.ContactId, bsoRecord.Level_2__c, 'Level 2 user not updated on Billed Sales record after batch execution');
        System.assertEquals(newL2User.ContactId, receivableRecord.Level_2__c, 'Level 2 user not updated on Line Items record after batch execution');
    }
}