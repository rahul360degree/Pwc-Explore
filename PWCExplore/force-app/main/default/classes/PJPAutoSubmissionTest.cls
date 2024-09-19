@isTest
global class PJPAutoSubmissionTest {
    
    global static testMethod void testclass(){
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {

   		Date today = Date.today();
    	Integer year = today.year();
    	Integer month = today.month();
    	Integer nextmonth = (month == 12) ? 1 : month+1;
    	Integer nextyear = (month==12) ? year+1 : year;
    	DateTime firstdayofmonth = DateTime.newInstance(nextyear,nextmonth,1,9,0,0);
   		DateTime lastdayofmonth = firstdayofmonth.addMonths(1).addDays(-1);
    	DateTime todaysDate = System.today();
		String todaysDateStr = '22';
        //todaysDate.format('dd')
        List<User> userdata = [select Id,name,UserRole.Name from User where Name like 'aditya rohith %' and UserRole.Name like '%Area%'];
        List<PJP__C> testpjpdata = new List<PJP__c>();
        testpjpdata.add(new PJP__C(
            Name = 'testpjp-2024-03-01',
            Status__c='Draft',
            OwnerId=userdata[0].Id,
            Start_Date__c=firstdayofmonth,
            End_Date__c=lastdayofmonth
        ));
        system.debug('pjpdata'+testpjpdata);
        insert testpjpdata;

        PJPAutoSubmission batch = new PJPAutoSubmission();
		System.enqueueJob(batch);
    }
    }
}