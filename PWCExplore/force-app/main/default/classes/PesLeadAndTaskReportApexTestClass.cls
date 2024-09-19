/*------------------------------------------------------------------------
Author:        Shreela Nair
Company:       Godrej Infotech
Description:   SPEP 14 - GPE-SGF-23 - Generate task report for all leads with or without task - To display Lead and Task data oF PES from UI
Inputs:        -

History
07-08-2023     Shreela Nair    Initial Release
05-09-2023     Shreela Nair    For replacing text field with Lookup field for SPEP -23 
12-09-2023     Shreela Nair    Adding new method to set Start Date for SPEP - 24
29-09-2023     Shreela Nair    Change in task record for SPEP - 30
----------------------------------------------------------------------------*/
@IsTest
public class PesLeadAndTaskReportApexTestClass {
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
                 setActivityDate(Date.newInstance(2023, 12, 23)).setWhoId(allLead[0].Id).getSavedTestRecord(); //Removed .setType('Call') and added setActionToBeTaken by Shreela on 29th Sept 2023 for SPEP - 30

            
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetLeadAndTaskReport() {
        User userToRun = [Select Id,Name,Username FROM User Where username = 'test.pesuser@godrej.com' AND Profile.Name = 'PES Sales And Marketing User' LIMIT 1];
        
        System.runAs(userToRun) {
            Test.startTest();
            Lead ld = [Select Id,LastName,Title,Description,Company,Status,Business_Unit__c,Lead_Incharge_GPE__c,PES_Sector__c FROM Lead  LIMIT 1]; //Modified from Lead_Incharge__c to Lead_Incharge_GPE__c by Shreela on 5th September 2023 for SPEP-23
            
            String fromcreationDate = '';
            String tocreationDate = '';
            Id leadIncharge = ld.Lead_Incharge_GPE__c; //Modified from Lead_Incharge__c to Lead_Incharge_GPE__c by Shreela on 5th September 2023 for SPEP-23
            String status = '';
            
            String result = PesLeadAndTaskReportApexClass.fetchFilteredRecords(fromcreationDate,tocreationDate, leadIncharge, status);
            
            // Deserialize the result into a list of dataWrapper objects
            List<PesLeadAndTaskReportApexClass.dataWrapper> dataList = (List<PesLeadAndTaskReportApexClass.dataWrapper>) JSON.deserialize(result, List<PesLeadAndTaskReportApexClass.dataWrapper>.class);
            
            
            for (PesLeadAndTaskReportApexClass.dataWrapper data : dataList) {
                
                Assert.areEqual(userToRun.Name, data.leadIncharge); //Modified parameters by Shreela on 5th September 2023 for SPEP-23
            }
            
            Test.stopTest();
        }
        
    }  
}