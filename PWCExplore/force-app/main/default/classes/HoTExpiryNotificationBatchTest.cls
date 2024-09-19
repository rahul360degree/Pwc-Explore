@isTest
public class HoTExpiryNotificationBatchTest {

    @isTest 
    public static void checkHoTNotificationTest(){
        //This test runs a scheduled job at midnight Sept. 15th. 2022
        String CRON_EXP = '0 0 0 15 * ? *';
        //Creating test data
        List<HEAD_OF_TERMS__c> bc=new List<HEAD_OF_TERMS__c>();
            HEAD_OF_TERMS__c g=new HEAD_OF_TERMS__c();
            g.Approval_Status__c='Not Submitted';
            bc.add(g);
        insert bc;
           
      Test.startTest();
        HoTExpiryNotificationBatch x = new HoTExpiryNotificationBatch();
        Database.QueryLocator ql = x.start(null);
        x.execute(null,bc);
        x.Finish(null);
        //To schedule the batch job at specific time
        String jobID = System.schedule('Scheduletest', CRON_EXP, x);
      Test.stopTest();
      System.assertEquals('Not Submitted',[SELECT Approval_Status__c FROM HEAD_OF_TERMS__c].Approval_Status__c);
    }
    
}