/*
Written by  : Sreekanth Jujare
On		    : 11/06/2022
Description : Returns Scheduled End Date on Task(Interio BMR) on Saving or Updating a Task record  */


trigger setScheduledEndDateInTask on Task (before insert,before update) {
    if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert)){
        HolidayList.setScheduledEndDate(trigger.new);
    }
}