@isTest
public class VisitStatusChangeBatchTest {
    @isTest static void testData(){
    
    }
    
    static testMethod void testmethods(){
        Date today = Date.today();
    	Integer year = today.year();
    	Integer month = today.month();
    	String formattedMonth = (month < 10) ? '0'+String.valueOf(month) : String.valueOf(month);
		DateTime firstdayofmonthstring = DateTime.valueOf(String.valueOf(year)+'-'+formattedMonth+'-'+'01 9:00:00.00');
        DateTime firstdayofmonth = DateTime.newInstance(year,month,1,9,0,0);
    	DateTime lastdayofmonth = firstdayofmonth.addMonths(1).addDays(-1);
        
		//system.debug('firstdayofmonthstring'+firstdayofmonthstring);
        List<User> userdata = [select Id from User where UserRole.Name like 'Appliances Area%' limit 1];
        //Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        List<Account> testaccount = [select Id from Account where RecordType.Name = 'Business Account' and Type='3'];
        system.debug('testaccount'+testaccount);
        List<Visit__c> listOfUnExecutedVisits = new List<Visit__c>();
        List<PJP__c> lisOfPJPs = new List<PJP__C>();
       
        lisOfPJPs.add(new PJP__c(
            			Name='testPjp',
            			Business_Unit__c = 'H',
                        OwnerId = userdata[0].Id,
                        Start_Date__c = DateTime.newInstance(year,month,1,9,0,0),
                        End_Date__c = firstdayofmonth.addMonths(1).addDays(-1),
                        Status__c = 'Draft'
        ));
        insert lisOfPJPs;
        Id devRecordTypeId = Schema.SObjectType.Visit__c.getRecordTypeInfosByName().get('ASP Visit').getRecordTypeId();
        listOfUnExecutedVisits.add(new Visit__c(
            			Name='statuschangetest',
            			Status__c='Not Started',
            			Visit_Category__c='Ad-Hoc',
            			RecordTypeId = devRecordTypeId,
                    	Account__c='001C400000CdgOfIAJ',
                    	OwnerId=userdata[0].Id,
                        PJP__c=lisOfPJPs[0].Id,
            			Visit_Scheduled_Date__c=firstdayofmonth,
                        Visit_Planned_Date__c=firstdayofmonth
            			
        ));
      	insert listOfUnExecutedVisits;
        
        Test.startTest();
        VisitStatusChangeBatch batch = new VisitStatusChangeBatch();
		Database.executeBatch(batch,300);
        Test.stopTest();
    }
}