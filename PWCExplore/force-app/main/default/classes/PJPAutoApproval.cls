global class PJPAutoApproval implements Queueable{
    global Date today = Date.today();
    global Integer year = today.year();
    global Integer month = today.month();
    global Integer nextmonth = (month == 12) ? 1 : month+1;
    global Integer nextyear = (month==12) ? year+1 : year;
    global DateTime firstdayofmonth = DateTime.newInstance(nextyear,nextmonth,1,9,0,0);
    global DateTime lastdayofmonth = firstdayofmonth.addMonths(1).addDays(-1);
    global List<ProcessInstanceWorkItem> pendingrecords = new List<ProcessInstanceWorkItem>(); 
    
    global void execute(QueueableContext context){
      Set<Id> pjpid = (new Map<Id, PJP__c>([SELECT Id FROM PJP__c WHERE Start_Date__c = :firstdayofmonth AND End_Date__c = :lastdayofmonth AND Owner.UserRole.Name Like '%Area%' AND Status__c = 'Submitted for Approval'])).keySet();
       Set<Id> pIds = (new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId in :pjpId])).keySet();
       List<ProcessInstanceWorkitem> autoapproval = [SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds];
        system.debug('pjpid'+pjpid);
       system.debug('autoapproval'+autoapproval);
        system.debug('pIds'+pIds);
        List<Approval.ProcessWorkitemRequest> allReq = new List<Approval.ProcessWorkitemRequest>(); 
        for (ProcessInstanceWorkitem pInstanceWorkitem : autoapproval){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Auto Approved as it is not approved by 25th');
            req.setAction('Approve');
            req.setWorkitemId(pInstanceWorkitem.Id);
            allReq.add(req);
        }
        Approval.ProcessResult[] result2 =  Approval.process(allReq);
    }
}