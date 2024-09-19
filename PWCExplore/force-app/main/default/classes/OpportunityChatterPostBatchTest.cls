@istest
public class OpportunityChatterPostBatchTest {
    public static String CRON_EXP = '0 30 20 L * ?';
    @istest
    public static void chatterPostTestOnOpportunity(){
        test.startTest();
        
        Account newAccount = new Account( FirstName = 'Test', LastName ='Person Account', PersonEmail = 'test@invalid.com', 
                                         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId());
        insert newAccount;
        List<Opportunity> oppo = new List<Opportunity>();
        for(Integer i =1 ; i < 4 ; i++){
            Opportunity opp = new Opportunity(Name = 'test'+i, stageName = 'open',closedate = system.today() +1, accountId = newAccount.id );
            oppo.add(opp);
        }
        // by Siddhesh
        Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        setting.FireOpportunityValidationRules__c = false;
        insert setting;
        Opportunity opp = new Opportunity(Name = 'testafterweek', stageName = 'open',closedate = system.today() - 7, accountId = newAccount.id );
        oppo.add(opp) ;
        insert Oppo;
        setting.FireOpportunityValidationRules__c = true;
        update setting;
        String jobId = system.schedule('testforOpportunityChatterPostBatch', CRON_EXP, new OpportunityChatterPostBatch());
       // OpportunityChatterPostBatch batchObj = new OpportunityChatterPostBatch();
       // Database.executeBatch(batchObj,200);
        test.stopTest();
    }
}