/*------------------------------------------------------------------------
 * Author:        Joshna
 * Company:       Salesforce
 * Description:   Helper class to create time entries
 * Inputs:        NA
 * Test Class:    CreateTimeEntriesFromFlowTest
 * ---------------------------------------------------------------------------
 * History
 * 19-11-2020      Joshna     Initial Release
 * ----------------------------------------------------------------------------*/
public class CreateTimeEntriesFromFlow {
    @InvocableMethod
    public static List<String> createTimeEntries(List<TimeEntryWrapper> userInputs) {
        try{
            List<Time_Entry__c> timeEntryRecords = new List<Time_Entry__c>();
            for (TimeEntryWrapper each : userInputs) {
                for (Integer i = 0; i < each.startTimeList.size(); i++) {
                    if (each.startTimeList[i] != null && each.endTimeList[i] != null && String.isNotBlank(each.typeList[i])) {
                        if (each.startTimeList[i].date() != each.attendanceLogTime.date() || each.endTimeList[i].date() != each.attendanceLogTime.date()) {
                            throw createCustomException(Label.Attendance_Date_Invalid);
                        }
                        List<String> startTimeSplit = String.valueOf(each.startTimeList[i]).substringAfter(' ').split(':');
                        List<String> endTimeSplit = String.valueOf(each.endTimeList[i]).substringAfter(' ').split(':');
                        Time startTime = Time.newInstance(Integer.valueOf(startTimeSplit[0]), Integer.valueOf(startTimeSplit[1]), 0, 0);
                        Time endTime = Time.newInstance(Integer.valueOf(endTimeSplit[0]), Integer.valueOf(endTimeSplit[1]), 0, 0);
                        timeEntryRecords.add(new Time_Entry__c(Attendance__c = each.attendanceRecordId, Type__c = each.typeList[i],
                            StartTime__c = startTime, EndTime__c = endTime));
                    }
                }
            }
            insert timeEntryRecords;
        } catch(DMLException ex){
            throw createCustomException(ex.getDmlMessage(0));
        }
        return null;
    }

    // To display user friendly exception message on flow
    public class CustomException extends Exception {}
    static CustomException createCustomException(String message){
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }

    public class TimeEntryWrapper {
        @InvocableVariable public List<DateTime> startTimeList;
        @InvocableVariable public List<DateTime> endTimeList;
        @InvocableVariable public List<String> typeList;
        @InvocableVariable public String attendanceRecordId;
        @InvocableVariable public Datetime attendanceLogTime;
    }
}