public class LeaveUpdateYearlyBatch implements Database.Batchable<sobject> , Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc){
        String d2dAccount = '%' + 'GD' + '%';
        String applianceBusinessUnit = 'H';
        String Query = 'SELECT ID, Leaves_Left__c FROM Contact where account.business_unit__c=:applianceBusinessUnit AND account.name like:d2dAccount';
        System.debug('Query->'+Query);
            return Database.getQueryLocator(Query);
    }
    //system.debug('database query'+Database.QueryLocator);
    public void execute(Database.BatchableContext bc, List<Contact> con ){
       	leavesAllotedCalculation.monthlyLeavesAlloted(con);
        if(date.today().month() == 12){ 
            leavesAllotedCalculation.yearEndLogic(con);
        }
    }
    Public void finish(database.BatchableContext bc){
        
    }
    Public void execute(SchedulableContext ctx){
		LeaveUpdateYearlyBatch LUYB = new LeaveUpdateYearlyBatch();
        Id batchid = Database.executeBatch(LUYB);
    }
}