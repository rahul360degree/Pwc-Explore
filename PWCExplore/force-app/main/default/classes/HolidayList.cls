/*
Written by  : Sreekanth Jujare
On          : 11/06/2022
Description : Returns Scheduled End Date on Task (Interio BMR) by =  Start Date + Sundays + SLA + Holiday List 
Test Class  : HolidayListTest 
*/
public class HolidayList{
    Public static void setScheduledEndDate(List<Task> newList){
        string taskSubActivityValue='';
        DateTime dt =null;
        Date dToday = Date.today();
        map<String,Integer> mapSubActivitySLA = new map<String,Integer>();
        List<HolidaysList__mdt> Hlst = HolidaysList__mdt.getall().values();
        List<Interio_SLA_values__mdt> lstInterioSLA = Interio_SLA_values__mdt.getall().values();
        for (Interio_SLA_values__mdt objInterioSLA :lstInterioSLA){
            mapSubActivitySLA.put(objInterioSLA.sub_activity__c,Integer.valueOf(objInterioSLA.SLA_Days__c));
        }
        
        for(Task tsks:newList){
            if (tsks.RecordTypeId == Globalconstants.Interio_BMR_RECORDTYPE && tsks.Start_Date__c!=null && tsks.Sub_Activity__c!=null){
                taskSubActivityValue=String.Valueof(tsks.Sub_Activity__c);
                dt=tsks.Start_Date__c;

                Integer count=0;
                Integer SLAdays=0; 
                System.debug ('count start:'+count);
                System.debug ('SLAdays b4:'+SLAdays);
                SLAdays=(mapSubActivitySLA.get(taskSubActivityValue)!=null)?mapSubActivitySLA.get(taskSubActivityValue):SLAdays;
                System.debug ('SLAdays after:'+SLAdays);
                // Looking for Holidays between the start date + SLA days
                for(HolidaysList__mdt hl:Hlst){
                    DateTime dtholiday = DateTime.newInstance(dToday.year(), Integer.valueOf(hl.month__c),Integer.valueOf(hl.day__c));
                    If(dt<dtholiday && dt+SLAdays>dtholiday){
                        count+=1;
                    }
                }
                System.debug ('count with holidays:'+count);
                //Looking for Sundays between the start date + SLA days
                for (Integer i = 0; i <= SLAdays; i++) {
                        date visitDateTime = dT.date().addDays(i);
                        Datetime nameOfTheDay = DateTime.newInstance(visitDateTime, Time.newInstance(0, 0, 0, 0));
                        if (nameOfTheDay.format('EEEE').equalsIgnoreCase(System.label.WeekEndDay_Sunday)) //Check for Sunday
                            count += 1; //Increment counter
                }
                System.debug ('count with sundays:'+count);
                tsks.Scheduled_End_Date__c=dt+count+SLAdays;
            }
        }
    }
}