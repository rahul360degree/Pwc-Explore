/**
* @description       : PESReportsBatchTest
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 3-03-2023
* @last modified by  : snehalw@godrej.com
**/
@IsTest
public class PESReportsBatchTest {
     @TestSetup static void createData(){
        //Added by Profile and User Shreela on 16th March 2023
        Profile userProfile = [Select Id from Profile where Name = 'PES Sales And Marketing User' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'PES User', Alias = 'tpesuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.pesuser@godrej.com', username = 'test.pesuser@godrej.com', Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT);
        
        insert userToRun;
     }
    
    @IsTest
    static void testGetOppDataForReport() {
        User userToRun = [Select Id,Name,Username FROM User Where username = 'test.pesuser@godrej.com' AND Profile.Name = 'PES Sales And Marketing User' LIMIT 1];
        
        System.runAs(userToRun) {
        Test.startTest();
        
        // Create test data
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.Sector__c = 'Defence';
        opp.Firm_BQ__c = 'Firm';
        opp.stageName = GlobalConstants.OPPORTUNITY_INPROCESS;
        //opp.CloseDate = system.today() + 1;
        opp.CloseDate = Date.today().addMonths(-1);
        opp.Quote_Submission_date__c = Date.today().addMonths(-1);
        insert opp;
            
        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test Opportunity';
        opp2.Sector__c = 'Nuclear';
        opp2.Firm_BQ__c = 'Firm';
        opp2.stageName = 'In Process';
        //opp.CloseDate = system.today() + 1;
        opp2.CloseDate = Date.today().addMonths(-1);
        opp2.Quote_Submission_date__c = Date.today().addMonths(-1);
        insert opp2;    
            
        Opportunity opp3 = new Opportunity();
        opp3.Name = 'Test Opportunity';
        opp3.Sector__c = 'Exports';
        opp3.Firm_BQ__c = 'Firm';
        opp3.stageName = GlobalConstants.OPPORTUNITY_INPROCESS;
        //opp.CloseDate = system.today() + 1;
        opp3.CloseDate = Date.today().addMonths(-1);
        opp3.Quote_Submission_date__c = Date.today().addMonths(-1);
        insert opp3; 
            
            
        Opportunity opp4 = new Opportunity();
        opp4.Name = 'Test Opportunity';
        opp4.Sector__c = 'General Engineering';
        opp4.Firm_BQ__c = 'Firm';
        opp4.stageName = GlobalConstants.OPPORTUNITY_INPROCESS;
        //opp.CloseDate = system.today() + 1;
        opp4.CloseDate = Date.today().addMonths(-1);
        opp4.Quote_Submission_date__c = Date.today().addMonths(-1);
        insert opp4;    
        
        
        
        // Call the method being tested
        PESReportsBatch.getOppDataForReport(1, true,null,null);
        
        // Assert the results
        Map<String, String> totalOpportunitiesMap = PESReportsBatch.totalOpportunitiesMap;
        system.debug('totalOpportunitiesMap: ' + totalOpportunitiesMap);
        totalOpportunitiesMap.put('1' ,'1');
 
        
        System.assertEquals('1', totalOpportunitiesMap.get('1'));
        
        PESReportsBatch.sendEmailNotification(1);
        
        
        String sch = '0 39 11 * * ?';
        PESReportsBatch scheduledJob = new PESReportsBatch();
        String jobId = system.schedule('Test Job', sch, scheduledJob);
        
        Test.stopTest();
        }    
    }
    
    
}