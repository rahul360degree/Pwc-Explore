@isTest
global class PJPAutoApprovalTest {
    
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
            
            List<Id> recordids = new List<Id>();
        for(PJP__C submit : testpjpdata){
            recordids.add(submit.Id);
        }
        if(!recordids.isEmpty()){
            for(Id recordid : recordids){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Sent for approval');
                req1.setObjectId(recordid);
                Approval.ProcessResult result = Approval.process(req1);
            }
        }
            
            PJPAutoApproval batch = new PJPAutoApproval();
            System.enqueueJob(batch);
    }
    }
}