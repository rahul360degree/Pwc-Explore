public class OpportunityChatterPostBatch implements Database.Batchable<sobject>, Schedulable {
    Date weekAfterCloseDate = Date.today().addDays(-7);
    Date dayBeforeCloseDate = Date.today().addDays(+1);
    public Database.QueryLocator start(Database.BatchableContext BC){
        List<String> stages = new List<String>{'Closed Lost','Purchase Order','Closed Won'};
        //Id oppId = '0061m000004CimSAAS';
        string query;
       // if (!Test.isRunningTest()) {
        query = 'select Id,Name,CloseDate,OwnerId from Opportunity where'+
            ' StageName Not IN :stages AND (CloseDate = TOMORROW OR CloseDate = :weekAfterCloseDate)';
      //  }
        return Database.getQueryLocator(query);        
    }
    
    public void execute(database.BatchableContext BC, List<opportunity> oppList){
        OpportunityChatterPostHelper.postChatterFeed(oppList,weekAfterCloseDate,dayBeforeCloseDate);
        
    }
    
    public void finish(database.BatchableContext BC){
        
    }
    
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(new OpportunityChatterPostBatch());
        
    }
        

}