/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   SPEP 14 - GPE-SGF-23 - Generate task report for all leads with or without task -Test class

History
05-08-2023     Shreela Nair    Initial Release
12-09-2023     Shreela Nair    Adding new method to set Start Date for SPEP - 24
29-09-2023     Shreela Nair    Change in task record for SPEP - 30
----------------------------------------------------------------------------*/
@IsTest
public class PesLeadAndTaskReportSchedulerTestClass {
    @TestSetup static void createData(){
         Test.startTest();
        Profile userProfile = [Select Id from Profile where Name = 'PES Sales And Marketing User' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'PES User', Alias = 'tpesuser',
                                  languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                  timezonesidkey = 'Asia/Kolkata', email = 'test.pesuser@godrej.com', username = 'test.pesuser@godrej.com', Business_Unit__c = GlobalConstants.PES_BUSINESS_UNIT);
        
        insert userToRun;
        
        System.runAs(userToRun) {
            
            List<Lead> allLead = new List<Lead> {
                //Changed values of setLeadIncharge by Shreela on 5th September 2023 for SPEP-23
                new TestLeadBuilder().setBusinessUnit('Q').setLeadIncharge(userToRun.Id).setPESSector('Defence').setLastName('Test Last Name').setTitle('Test 1').setDescription('For testing purpose').setCompany('NPCL').setStatus('New').getTestRecord(),
                new TestLeadBuilder().setBusinessUnit('Q').setLeadIncharge(userToRun.Id).setPESSector('Defence').setLastName('Test Last Name 2').setTitle('Test 2').setDescription('For testing purpose').setCompany('L&T Valves').setStatus('Qualified').getTestRecord()
                    };
            insert allLead;
            
            //Added setStartDate by Shreela on 12th Sept 2023 for SPEP - 24
             Task taskRecord = new TestTaskBuilder().setSubject('Call').setActionToBeTaken('testing').setStatus('Not Started').setStartDate(Date.newInstance(2023, 08, 23)).
                 setActivityDate(Date.newInstance(2023, 12, 23)).setWhoId(allLead[0].Id).getSavedTestRecord();//Removed .setType('Call')  and added setActionToBeTaken by Shreela on 29th Sept 2023 for SPEP - 30
            
            
        }
        Test.stopTest();
        
         }
    
    @IsTest
     static void testGetLeadAndTaskReport() {
       User userToRun = [Select Id,Name,Username FROM User Where username = 'test.pesuser@godrej.com' AND Profile.Name = 'PES Sales And Marketing User' LIMIT 1];
        
        System.runAs(userToRun) {
         Test.startTest();
            
         String sch = '0 39 11 * * ?';
         PesLeadAndTaskReportSchedulerClass scheduledJob = new PesLeadAndTaskReportSchedulerClass();
         String jobId = system.schedule('Test Job', sch, scheduledJob);   
   
         Test.stopTest();
          Assert.areEqual(2, [SELECT Count() FROM Lead WHERE RecordType.DeveloperName =: GlobalConstants.PES_Lead_RecordType]);   
        }
     }

}