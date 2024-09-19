/*------------------------------------------------------------------------
Author:        Srinivasa Angaluri
Company:       Godrej Infotech Limited
Description:   Test Class to auto create PJP records
Inputs:        
Test Class:   
Created Date
25-07-2023      Srinivasa Angaluri     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class GeneratePJPTest {

    @isTest
    Public static void TestPJPRecords(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PJP__c pjprecord = new PJP__c (Name = 'Test', PJP_Generated__c = TRUE);
        insert pjprecord;
        System.runAs(thisUser){
          Test.startTest();
          GeneratePJPRecords.generatePJP();  
          List<PJP__c> pJP = new List<PJP__c>();
          String UserId = UserInfo.getUserId();
          Date startDate = Date.today();  
          String UserName = String.ValueOf([Select Name from User where Id =:UserId].name);
          Integer currentyear = startDate.year();  
          //pJP.Start_Date__c = DateTime.parse('2023-07-14 05:00:00');
          //pJP.End_Date__c =  DateTime.parse('2023-07-20 05:00:00');
         // Instert pJP;
          Date endDate = date.newinstance(currentyear, 12, 31).toStartOfWeek();
          date WeekStartDate = startDate.toStartOfWeek().addDays(1);
          date WeekEndDate = WeekStartDate.addDays(6);
          Date financialYearStartDate = Date.newInstance(startDate.year(), 4, 1);
          Date financialYearEndDate = financialYearStartDate.addYears(1).addDays(-1);
          Integer days = Integer.valueOf(math.floor(startDate.daysBetween(financialYearEndDate)/7));
          Integer WeekNumber = Integer.valueOf(math.floor(financialYearStartDate.daysBetween(startDate)/7)+1);
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
             pJP.add(p1);
             system.debug('P1-->'+p1.Name);           
      }
            Insert pJP;
          Test.stopTest();  
        }
    }
}