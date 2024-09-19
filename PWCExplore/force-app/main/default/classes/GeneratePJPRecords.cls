/*------------------------------------------------------------------------
Author:        Srinivasa Angaluri
Company:       Godrej Infotech Limited
Description:   Class to auto create PJP records
Inputs:        
Test Class:   
Created Date
21-06-2023      Srinivasa Angaluri     Initial Release
----------------------------------------------------------------------------*/

public class GeneratePJPRecords {
   @InvocableMethod (label = 'Generate PJP records' description = 'Generate Weekly PJP records')
   //@AuraEnabled
    public static void generatePJP(){
        try{
        List<PJP__c> p = new List<PJP__c>();
        String UserId = UserInfo.getUserId();
        String UserName = String.ValueOf([Select Name from User where Id =:UserId].name);    
        Date startDate = Date.today();
        Integer currentyear = startDate.year();
        Date endDate = date.newinstance(currentyear, 12, 31).toStartOfWeek();
        system.debug('startDate'+startDate);
        system.debug('endDate'+endDate);
        date WeekStartDate = startDate.toStartOfWeek().addDays(1);
        date WeekEndDate = WeekStartDate.addDays(6);
        Date financialYearStartDate = Date.newInstance(startDate.year(), 4, 1);
        Date financialYearEndDate = financialYearStartDate.addYears(1).addDays(-1);
        Integer days = Integer.valueOf(math.floor(startDate.daysBetween(financialYearEndDate)/7));
        system.debug('Balance Days'+days);
        //Integer WeekNumber = Integer.valueOf(system.now().format('w'));
        Integer WeekNumber = Integer.valueOf(math.floor(financialYearStartDate.daysBetween(startDate)/7)+1);
        system.debug('WeekNumber'+WeekNumber);
      
        For(Integer i=0; i<=days; i++){
            PJP__c p1 = new PJP__c();
            Integer y = WeekStartDate.year();
            Integer m = WeekStartDate.month();
            Integer d = WeekStartDate.day();
            DateTime dt = DateTime.newInstance(y,m,d);
            String MonthName = dt.format('MMM');
            String Year = dt.format('YY');    
             p1.Name = 'W'+WeekNumber+MonthName+Year+UserName;
             p1.Start_Date__c = WeekStartDate;
             p1.End_Date__c = WeekEndDate;
             p1.PJP_Generated__c = TRUE;   
             WeekNumber = WeekNumber +1; 
             WeekStartDate = WeekStartDate +7;
             WeekEndDate = WeekEndDate +7;
             p.add(p1);
             system.debug('P1-->'+p1.Name);
             
      }
      Insert p;
     }
      catch(DmlException e) {
       System.debug('The following exception has occurred: ' + e.getMessage());
      }  
    }     

}