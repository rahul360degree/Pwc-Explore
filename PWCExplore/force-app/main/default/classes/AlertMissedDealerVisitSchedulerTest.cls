/*------------------------------------------------------------------------
 * Author:        Shailja Mishra
 * Company:       Salesforce
 * Description:   Test class for AlertMissedDealerVisitScheduler
 * Inputs:        NA
 * ---------------------------------------------------------------------------
 * History
 * 18-11-2020      Shailja Mishra     Initial Release
 * ----------------------------------------------------------------------------*/
@isTest
public class AlertMissedDealerVisitSchedulerTest {
	@testsetup
    public static void testData() {
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        List<User> interioUsers = new List<User> {
            new TestUserBuilder().setLastName('SalesUser').setProfileId(userProfile.Id)
                .setBusinessUnit('W').setPersona('InteroScript- COCO Store Sales Executive').getTestRecord(),
            new TestUserBuilder().setLastName('Manager').setProfileId(userProfile.Id)
                .setBusinessUnit('W').setPersona('InteroScript- COCO Store Sales Executive').setAllowBusinessAccountCreation(true).getTestRecord(),
            new TestUserBuilder().setLastName('User2').setProfileId(userProfile.Id)
                .setBusinessUnit('W').setPersona('InteroScript- COCO Store Sales Executive').setAllowBusinessAccountCreation(true).getTestRecord()
        };
        insert interioUsers;
        
        interioUsers[0].ManagerId = interioUsers[1].Id;
        update interioUsers[0];
        
        interioUsers[1].Salary_Code__c = '1334';
        update interioUsers[1];
        
        interioUsers[2].Salary_Code__c = '4353';
        update interioUsers[2];
        
        Competitor_Visit__c cv = new Competitor_Visit__c(Competitor_Address__c = 'ABDC',
                                                         OwnerId = interioUsers[1].Id,
                                                         Person_accompanying_on_Visit__c = interioUsers[1].Id);
        insert cv;
        Datetime lastMonth = Datetime.now().addDays(-30);
        Test.setCreatedDate(cv.Id, lastMonth);
        
        Competitor_Visit__c cv1 = new Competitor_Visit__c(Competitor_Address__c = 'SGFDG',
                                                         OwnerId = interioUsers[2].Id,
                                                         Person_accompanying_on_Visit__c = interioUsers[2].Id,
                                                         Brand__c = 'Godrej');
        insert cv1;
        Datetime last90Days = Datetime.now().addDays(-65);
        Test.setCreatedDate(cv1.Id, last90Days);
    }
    
    @isTest private static void createDealerVisits(){
        List<User> users = [Select Id From User];
        Test.StartTest();
        AlertMissedCompetitorVisitScheduler scheduler = new AlertMissedCompetitorVisitScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Alert Competitor Visits Scheduler', sch, scheduler); 
        Test.stopTest();
        System.assert([Select Id From Competitor_Visit__c].size() > 0);
    }
}