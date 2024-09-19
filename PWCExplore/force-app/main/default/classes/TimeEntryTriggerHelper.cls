/*------------------------------------------------------------------------------
 * Author:        Joshna
 * Company:       Salesforce
 * Description:   Trigger helper for time entry object
 * ---------------------------------------------------------------------------
 * History
 * 16-11-2020      Joshna     Initial Release
 * ----------------------------------------------------------------------------*/
public with sharing class TimeEntryTriggerHelper {
    String regularTimeEntry = 'Regular';

    public void validateTimeEntryRecords(List<Time_Entry__c> newItems) {
        Set<Id> attendanceIds = new Set<Id>();
        Map<Id, Attendance__c> attendanceMap = new Map<Id, Attendance__c>();
        Set<Id> existingIds = new Set<Id>();
        Map<Id, List<TimeEntrySorter>> timeEntriesByAttendance = new Map<Id, List<TimeEntrySorter>>();

        for (Time_Entry__c each : newItems) {
            attendanceIds.add(each.Attendance__c);
            if (String.isNotBlank(each.Id)) {
                existingIds.add(each.Id);
            }
            // Gathering all time entries in the inserted or updated list
            if (timeEntriesByAttendance.containsKey(each.Attendance__c)) {
                timeEntriesByAttendance.get(each.Attendance__c).add(new TimeEntrySorter(each));
            } else {
                timeEntriesByAttendance.put(each.Attendance__c, new List<TimeEntrySorter> {new TimeEntrySorter(each)});
            }
        }
        
        // Sorting the inserted or updated list so that the entries can be compared only with previous item
        for (Id each : timeEntriesByAttendance.keySet()) {
            timeEntriesByAttendance.get(each).sort();
            List<TimeEntrySorter> timeEntries = timeEntriesByAttendance.get(each);
            for (Integer i = 1; i < timeEntries.size(); i++) {
                if (timeEntries[i].timeEntry.StartTime__c < timeEntries[i - 1].timeEntry.EndTime__c) {
                    timeEntries[i].timeEntry.addError(Label.Time_Entry_Overlap);
                }
            }
        }

        for (Attendance__c each : [SELECT Id, Start_of_Day__c, End_Of_Day__c, (SELECT Id, StartTime__c, EndTime__c FROM Time_Entry__r ORDER BY StartTime__c, EndTime__c)
                                   FROM Attendance__c WHERE Id IN :attendanceIds]) {
            attendanceMap.put(each.Id, each);
        }

        // Validating all time entries to ensure they're after logged time, in valid intervals and are not overlapping with existing time entries
        for (Integer i = 0; i < newItems.size(); i++) {
            Time_Entry__c each = newItems[i];
            if (each.StartTime__c >= each.EndTime__c) {
                each.addError(Label.Start_Should_Be_Before_End);
            }
            if (!attendanceMap.containsKey(each.Attendance__c)) {
                continue;
            }
            if (attendanceMap.get(each.Attendance__c).End_of_Day__c != null) {
                each.addError(Label.Cannot_Create_A_Time_Entry);
            }
            attendanceMap.get(each.Attendance__c).Start_of_Day__c = attendanceMap.get(each.Attendance__c).Start_of_Day__c.addSeconds(
                attendanceMap.get(each.Attendance__c).Start_of_Day__c.second() * -1);
            if (attendanceMap.get(each.Attendance__c).Start_of_Day__c.time() > each.StartTime__c) {
                each.addError(Label.Start_Should_Be_After_Log_Time);
            }
            if (attendanceMap.get(each.Attendance__c).Time_Entry__r.isEmpty()) {
                continue;
            }
            for (Time_Entry__c existingEntry : attendanceMap.get(each.Attendance__c).Time_Entry__r) {
                if (existingIds.contains(existingEntry.Id)) {
                    continue;
                }
                if ((each.StartTime__c >= existingEntry.StartTime__c && each.StartTime__c <= existingEntry.EndTime__c)
                    || (each.EndTime__c >= existingEntry.StartTime__c && each.EndTime__c <= existingEntry.EndTime__c)) {
                    each.addError(Label.Time_Entry_Overlap);
                    break;
                }
            }
        }
    }

    public void validateTimeEntryRecords(Map<Id, Time_Entry__c> newItemsMap, Map<Id, Time_Entry__c> oldItemsMap) {
        List<Time_Entry__c> updatedTimeEntries = new List<Time_Entry__c>();
        for (Time_Entry__c each : newItemsMap.values()) {
            if (each.StartTime__c != oldItemsMap.get(each.Id).StartTime__c || each.EndTime__c != oldItemsMap.get(each.Id).EndTime__c) {
                updatedTimeEntries.add(each);
            }
        }
        validateTimeEntryRecords(updatedTimeEntries);
    }
}