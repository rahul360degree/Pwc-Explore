/*------------------------------------------------------------------------------
 * Author:        Joshna
 * Company:       Salesforce
 * Description:   Custom sort class for Time Entries
 * ---------------------------------------------------------------------------
 * History
 * 19-12-2020      Joshna     Initial Release
 * ----------------------------------------------------------------------------*/
public class TimeEntrySorter implements Comparable {
    public Time_Entry__c timeEntry;
    
    public TimeEntrySorter(Time_Entry__c entryRec) {
        timeEntry = entryRec;
    }
    
    public Integer compareTo (Object compareTo) {
        TimeEntrySorter compareToEntry = (TimeEntrySorter) compareTo;
        Integer returnValue = 0;
        if (timeEntry.StartTime__c > compareToEntry.timeEntry.StartTime__c) {
            returnValue = 1;
        } else if (timeEntry.StartTime__c < compareToEntry.timeEntry.StartTime__c) {
            returnValue = -1;
        }      
        return returnValue;
    }
}