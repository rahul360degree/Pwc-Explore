@isTest
public with sharing class TestAttendanceBuilder {
    Attendance__c attendanceInstance;
    public TestAttendanceBuilder() {
        attendanceInstance = new Attendance__c();
        attendanceInstance.Start_Of_day__c = System.now().addDays(-1);
        attendanceInstance.End_Of_Day__c = attendanceInstance.Start_Of_day__c;
        attendanceInstance.Reason__c = 'For the test class';
        attendanceInstance.Start_of_Day_Geolocation__latitude__s = 10;
        attendanceInstance.Start_of_Day_Geolocation__longitude__s = 10;
    }

    public Attendance__c setStartOfDay(Datetime startofday) {
        attendanceInstance.Start_of_day__c = startofday;
        return attendanceInstance;
    }

    public TestAttendanceBuilder setStartOfDayTime(Datetime startOfDay) {
        attendanceInstance.Start_of_day__c = startOfDay;
        return this;
    }

    public TestAttendanceBuilder setEndOfDayTime(Datetime endOfDay) {
        attendanceInstance.End_of_day__c = endOfDay;
        return this;
    }

    public Attendance__c setEndOfDay(Datetime endOfDay) {
        attendanceInstance.End_of_day__c = endOfDay;
        return attendanceInstance;
    }

    public Attendance__c setReason(String reason) {
        attendanceInstance.Reason__c = reason;
        return attendanceInstance;
    }

    public Attendance__c setType(String type) {
        attendanceInstance.Type__c = type;
        return attendanceInstance;
    }

    public TestAttendanceBuilder setTypeValue(String type) {
        attendanceInstance.Type__c = type;
        return this;
    }

    public TestAttendanceBuilder setAutoSubmit(Boolean autoSubmit) {
        attendanceInstance.Auto_Submit_For_Approval__c = autoSubmit;
        return this;
    }

    public TestAttendanceBuilder setApprover(Id UserId) {
        attendanceInstance.Approver__c = UserId;
        return this;
    }
    
    public Attendance__c getTestRecord() {
        return attendanceInstance;
    }

    public Attendance__c getSavedTestRecord() {
        insert attendanceInstance;
        return attendanceInstance;
    }
}