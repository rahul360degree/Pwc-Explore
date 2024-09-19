global class PJPAutoSubmission implements Queueable{
    global Date today = Date.today();
    global Integer year = today.year();
    global Integer month = today.month();
    global Integer nextmonth = (month == 12) ? 1 : month+1;
    global Integer nextyear = (month==12) ? year+1 : year;
    global DateTime firstdayofmonth = DateTime.newInstance(nextyear,nextmonth,1,9,0,0);
    global DateTime lastdayofmonth = firstdayofmonth.addMonths(1).addDays(-1);
    global DateTime todaysDate = System.today();
	global String todaysDateStr = todaysDate.format('dd');
    global List<PJP__c> submitforapproval22 = new List<PJP__c>(); 
    
    global void execute(QueueableContext context){
        if(todaysDateStr == '22'){
            system.debug('hi');
            submitforapproval22 = [select Id From PJP__c where Status__c='Draft' AND Start_Date__c = :firstdayofmonth AND End_Date__c = :lastdayofmonth AND Owner.UserRole.Name Like '%Area%'];
            system.debug('records are'+submitforapproval22);
        }
        else if(todaysDateStr == '25' || System.Test.isRunningTest()){
            submitforapproval22 = [select Id From PJP__c where Status__c IN ('Draft','Rejected') AND Start_Date__c = :firstdayofmonth AND End_Date__c = :lastdayofmonth AND Owner.UserRole.Name Like '%Area%'];
        }
        system.debug('records'+submitforapproval22);
        List<Id> recordids = new List<Id>();
        for(PJP__C submit : submitforapproval22){
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
    }
}