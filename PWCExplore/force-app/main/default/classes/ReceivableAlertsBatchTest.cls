/*-----------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test class for ReceivableAlertsBatch, ReceivableAlertsScheduler,
 *                        ChatterUtility
 * History
 * --------
 * 19-10-2020      Joshna Palla     Initial Release
 * ---------------------------------------------------------------------------------------*/
@isTest
public with sharing class ReceivableAlertsBatchTest {
    static final String MHE_PROFILE = 'MHE Sales User';
    static final String SSG_PROFILE = 'SSG Sales Engineer & Manager User';
    static final String SALES_USER_ROLE = 'MHE_Sales_Engineer_Comm_AD_Hi_EXP_1';
    static final String SALES_MANAGER_ROLE = 'MHE_Sales_Head_Exp_HO';
    static Map<Id, String> receivablesMessagesMap = new Map<Id, String>();

    // Test setup method to create test data
    @TestSetup static void createData() {
        // Creating MHE users (a sales rep and manager)
        Map<String, Id> userRoleMap = new Map<String, Id>();
        Id ssgProfile, mheProfile;
        for(Profile each : [SELECT Id, Name FROM Profile WHERE Name = :MHE_PROFILE OR Name = :SSG_PROFILE]) {
            if (each.Name == SSG_PROFILE) {
                ssgProfile = each.Id;
            } else {
                mheProfile = each.Id;
            }
        }
        for (UserRole each : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = :SALES_USER_ROLE OR DeveloperName = :SALES_MANAGER_ROLE]) {
            userRoleMap.put(each.DeveloperName, each.Id);
        }
        List<User> salesUsers = new List<User> {
            new TestUserBuilder().setLastName('MHESalesUser').
                setProfileId([SELECT Id, Name FROM Profile WHERE Name=:'System Administrator'].id)
                .setUserRoleId(userRoleMap.get(SALES_USER_ROLE))
                .setBusinessUnit('K').getTestRecord(),
            new TestUserBuilder().setLastName('MHESalesManager').setProfileId(mheProfile).setUserRoleId(userRoleMap.get(SALES_MANAGER_ROLE))
                .setBusinessUnit('K').setAllowBusinessAccountCreation(true).getTestRecord(),
            new TestUserBuilder().setLastName('SSGSalesUser').setProfileId(ssgProfile).setBusinessUnit('G').setAllowBusinessAccountCreation(true)
                .getTestRecord(),
            new TestUserBuilder().setLastName('SSGSalesManager').setProfileId(ssgProfile).setBusinessUnit('G').setAllowBusinessAccountCreation(true)
                .getTestRecord()
        };
        insert salesUsers;

        salesUsers[0].ManagerId = salesUsers[1].Id;
        salesUsers[2].ManagerId = salesUsers[3].Id;
        update salesUsers;
/*
        Group grp = [SELECT Id, Name, DeveloperName FROM Group where DeveloperName  =: 'MHE_Outright_Equipmen_BSO_Group_View_All'];
        List<GroupMember> memberList = new List<GroupMember>();
        for(USer user:salesUsers){
            memberList.add(new GroupMember(GroupId=grp.Id, UserOrGroupId=user.Id));
        }
        insert memberList;*/
        // Creating test account, receivble record and batch configuration custom setting (for batch size)
        System.runAs(salesUsers[0]) {
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('K').getSavedTestRecord();

            Billed_Sales_Outstandings__c bsoRec = new TestBilledSalesOutstandingsBuilder().setOwnerId(salesUsers[0].Id).setAccount(partnerAccount.Id)
                .setBusinessUnit('K').getSavedTestRecord();
            Id receivableRecordTypeId = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId();
            Receivable__c receivableRecord = new TestReceivableBuilder().setInvoiceToBP(partnerAccount.Id).setOwnerId(salesUsers[0].Id)
                .setInvoice(bsoRec.Id).setBusinessUnit('K').setRecordTypeId(receivableRecordTypeId).getSavedTestRecord();

            Apex_Batch_Configurations__c batchSizeConfig = new Apex_Batch_Configurations__c(Name = 'ReceivableAlertsScheduler', Batch_Size__c = 5);
            insert batchSizeConfig;
        }
    }

    // Test method to validate batch job creates a chatter post on MHE receivable record when Due Date = TODAY
    @isTest private static void mheReceivableDueTodayShouldAlertOwner() {
        String messageContent = 'Invoice No. 12345 for ACCOUNT FOR TEST CLASS is due today. Current balance amount is INR 1000';
        Test.startTest();
        Database.executeBatch(new ReceivableAlertsBatch(), 200);
        Test.stopTest();

        Billed_Sales_Outstandings__c headerRec = [SELECT Id FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'K'];
        ConnectApi.FeedElementPage pageElements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Record, headerRec.Id);
        System.assertEquals(1, pageElements.elements.size(), 'Chatter post not created as per alerts configured');
        
        for (ConnectApi.FeedElement element : pageElements.elements) {
            System.assertEquals(true, element.toString().contains(messageContent), 'Incorrect chatter message posted');
        }
    }

    // Test method to validate batch job creates a chatter post on MHE receivable record when Due Date is 7 days from TODAY
    @isTest private static void mheReceivableDueIn7DaysShouldAlertOwner() {
        String messageContent = 'Invoice due in 7 days!';
        Billed_Sales_Outstandings__c headerRec = [SELECT Id, Due_Date__c FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'K'];
        headerRec.Due_Date__c = Date.today() + 7;
        update headerRec;

        Test.startTest();
        Database.executeBatch(new ReceivableAlertsBatch(), 200);
        Test.stopTest();

        ConnectApi.FeedElementPage pageElements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Record, headerRec.Id);
        System.assertEquals(1, pageElements.elements.size(), 'Chatter post not created as per alerts configured');
        
        for (ConnectApi.FeedElement element : pageElements.elements) {
            System.assertEquals(true, element.toString().contains(messageContent), 'Incorrect chatter message posted');
        }
    }

    // Test method to validate batch job creates a chatter post on MHE receivable record when Due Date is overdue for close to 6 months
    @isTest private static void mheReceivableOverdueShouldAlertOwner() {
        String messageContent = 'Invoice overdue by 6 months in 15 days!';
        Billed_Sales_Outstandings__c headerRec = [SELECT Id, Due_Date__c FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'K'];
        headerRec.Due_Date__c = Date.today() - 165;
        update headerRec;

        Test.startTest();
        Database.executeBatch(new ReceivableAlertsBatch(), 200);
        Test.stopTest();

        ConnectApi.FeedElementPage pageElements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Record, headerRec.Id);
        System.assertEquals(1, pageElements.elements.size(), 'Chatter post not created as per alerts configured');
        
        for (ConnectApi.FeedElement element : pageElements.elements) {
            System.assertEquals(true, element.toString().contains(messageContent), 'Incorrect chatter message posted');
        }
    }

    // Test method to validate batch job creates a chatter post on MHE receivable record when Planned Collection Date is due in 7 days
    @isTest private static void mheReceivableWithPlannedCollectionDateDueShouldAlertOwner() {
        String messageContent = 'Planned Collection due in 7 days!';
        Billed_Sales_Outstandings__c headerRec = [SELECT Id, Due_Date__c, Planned_Collection_Date_1__c FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'K'];
        headerRec.Planned_Collection_Date_1__c = Date.today() + 7;
        headerRec.Due_Date__c = null;
        update headerRec;

        Test.startTest();
        Database.executeBatch(new ReceivableAlertsBatch(), 200);
        Test.stopTest();

        ConnectApi.FeedElementPage pageElements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Record, headerRec.Id);
        System.assertEquals(1, pageElements.elements.size(), 'Chatter post not created as per alerts configured');
        
        for (ConnectApi.FeedElement element : pageElements.elements) {
            System.assertEquals(true, element.toString().contains(messageContent), 'Incorrect chatter message posted');
        }
    }

    // Test method to validate batch job creates a chatter post on SSG receivable record when Planned Collection Date is due today
    @isTest private static void ssgReceivableWithPlannedCollectionDateDueShouldAlertOwner() {
        // Updating due date for MHE record so that only one chatter post is executed in test instance. Multiple posts in test instance
        // return incorrect results
        Billed_Sales_Outstandings__c existingRec = [SELECT Id, Due_Date__c FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'K'];
        existingRec.Due_Date__c = Date.today() - 1;
        update existingRec;
        Id ssgSalesUser = UserInfo.getUserId();

        //System.runAs(ssgSalesUser) {
            Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('G').getSavedTestRecord();

            Billed_Sales_Outstandings__c bsoRec = new TestBilledSalesOutstandingsBuilder().setOwnerId(ssgSalesUser).setAccount(partnerAccount.Id)
                .setPlannedCollectionAmount1(1000).setPlannedCollectionDate1(Date.today()).setBusinessUnit('G').getSavedTestRecord();
            Id receivableRecordTypeId = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId();
            Receivable__c receivableRecord = new TestReceivableBuilder().setInvoiceToBP(partnerAccount.Id).setOwnerId(ssgSalesUser).setOrder('G12345')
                .setInvoice(bsoRec.Id).setBusinessUnit('G').setRecordTypeId(receivableRecordTypeId).getSavedTestRecord();
        //}
        String messageContent = 'Invoices of Sales Order No. G12345';
        Billed_Sales_Outstandings__c headerRec = [SELECT Id FROM Billed_Sales_Outstandings__c WHERE Business_Unit__c = 'G'];
        Test.startTest();
        Database.executeBatch(new ReceivableAlertsBatch(), 200);
        Test.stopTest();

        ConnectApi.FeedElementPage pageElements = ConnectApi.ChatterFeeds.getFeedElementsFromFeed(null, ConnectApi.FeedType.Record, headerRec.Id);
        System.assertEquals(1, pageElements.elements.size(), 'Chatter post not created as per alerts configured');
        
        for (ConnectApi.FeedElement element : pageElements.elements) {
            System.assertEquals(true, element.toString().contains(messageContent), 'Incorrect chatter message posted');
        }
    }

    // Test method to validate scheduler creates instances of batch run
    @isTest private static void executingSchedulerShouldScheduleBatchJob() {
        String cronExpression = '0 0 0 1/1 * ? *';
        Test.startTest();
        String jobId = System.schedule('Receivable Alerts Batch', cronExpression, new ReceivableAlertsScheduler());
        Test.stopTest();

        CronTrigger cronInstance = [SELECT Id, CronExpression, NextFireTime, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, cronInstance.CronExpression, 'Failed to scheduled the batch job');
        System.assertEquals(0, cronInstance.TimesTriggered, 'Job has run ' + cronInstance.TimesTriggered + ' number of times');

        Date nextFireDate = Date.newinstance(cronInstance.NextFireTime.year(), cronInstance.NextFireTime.month(), cronInstance.NextFireTime.day());
        DateTime nextDayDateTime = DateTime.now().addDays(1);
        Date nextDay = Date.newinstance(nextDayDateTime.year(), nextDayDateTime.month(), nextDayDateTime.day());
        System.assertEquals(nextDay, nextFireDate, 'Job schedule is at an unexpected time: ' + cronInstance.NextFireTime);
    }
}