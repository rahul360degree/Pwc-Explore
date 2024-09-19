/*------------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Test class for CreateTimeEntriesFromFlow
 * History
 * --------
 * 29-11-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class CreateTimeEntriesFromFlowTest {
    @TestSetup static void createData(){
        Profile appliancesSales = [SELECT Id FROM Profile WHERE Name = 'Appliances Sales User'];
        List<User> appliancesUsers = new List<User>{new TestUserBuilder().setLastName('attendanceTestL0').setProfileId(appliancesSales.Id).getTestRecord(),
            new TestUserBuilder().setLastName('attendanceTestL1').setProfileId(appliancesSales.Id).getTestRecord()};
        insert appliancesUsers;
        appliancesUsers[0].ManagerId = appliancesUsers[1].Id;
        update appliancesUsers[0];
        System.runAs(appliancesUsers[0]) {
            Attendance__c currentDayAttendance = new TestAttendanceBuilder().setStartOfDayTime(Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0)))
                .setEndOfDayTime(null).getSavedTestRecord();
        }
    }

    @isTest private static void validTimeEntriesShouldBeInserted() {
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 30, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 45, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting'};
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        Test.startTest();
        List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        Test.stopTest();
        List<Time_Entry__c> timeEntryList = [SELECT Id, StartTime__c, EndTime__c FROM Time_Entry__c];
        System.assertEquals(1, timeEntryList.size(), 'Valid request did not create any time entry');
    }

    @isTest private static void entryWithStartTimeAfterEndTimeShouldReturnError() {
        String exceptionMessage = '';
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 30, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 15, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting'};
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        Test.startTest();
        try {
            List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, exceptionMessage.contains(Label.Start_Should_Be_Before_End), 'Attendance logged incorrectly');
    }

    @isTest private static void entryWithStartTimeBeforeAttendanceLogTimeShouldReturnError() {
        String exceptionMessage = '';
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(11, 30, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 30, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting'};
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        
        Test.startTest();
        try {
            List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, exceptionMessage.contains(Label.Start_Should_Be_After_Log_Time), 'Attendance logged incorrectly');
    }

    @isTest private static void entryWithStartTimeOfAnotherDayShouldReturnError() {
        String exceptionMessage = '';
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(12, 30, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 45, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting'};
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        
        Test.startTest();
        try {
            List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, exceptionMessage.contains(Label.Attendance_Date_Invalid), 'Attendance logged incorrectly');
    }

    @isTest private static void entriesWithOverlappingSlotsShouldReturnError() {
        String exceptionMessage = '';
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 30, 0, 0)),
            DateTime.newInstance(Date.today(), Time.newInstance(13, 15, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(13, 30, 0, 0)),
            DateTime.newInstance(Date.today(), Time.newInstance(13, 45, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting', 'Meeting'};
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        
        Test.startTest();
        try {
            List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(Label.Time_Entry_Overlap, exceptionMessage, 'Attendance logged incorrectly');
    }

    @isTest private static void updatingTimeEntryWithExistingSlotShouldReturnError() {
        String exceptionMessage = '';
        CreateTimeEntriesFromFlow.TimeEntryWrapper wrapperRec = new CreateTimeEntriesFromFlow.TimeEntryWrapper();
        wrapperRec.startTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(12, 30, 0, 0)),
            DateTime.newInstance(Date.today(), Time.newInstance(13, 30, 0, 0))};
        wrapperRec.endTimeList = new List<DateTime>{DateTime.newInstance(Date.today(), Time.newInstance(13, 30, 0, 0)),
            DateTime.newInstance(Date.today(), Time.newInstance(14, 30, 0, 0))};
        wrapperRec.typeList = new List<String>{'Meeting', 'Meeting'};
        wrapperRec.attendanceRecordId = [SELECT Id FROM Attendance__c].Id;
        wrapperRec.attendanceLogTime = Datetime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0));
        List<String> responses = CreateTimeEntriesFromFlow.createTimeEntries(new List<CreateTimeEntriesFromFlow.TimeEntryWrapper>{wrapperRec});
        Time_Entry__c timeEntryRec = [SELECT Id, StartTime__c, EndTime__c FROM Time_Entry__c WHERE Attendance__c = :wrapperRec.attendanceRecordId ORDER BY StartTime__c DESC LIMIT 1];
        timeEntryRec.StartTime__c = Time.newInstance(13, 10, 0, 0);
        timeEntryRec.EndTime__c = Time.newInstance(13, 40, 0, 0);

        Test.startTest();
        try {
            update timeEntryRec;
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, exceptionMessage.contains(Label.Time_Entry_Overlap), 'Attendance logged incorrectly');
    }
}