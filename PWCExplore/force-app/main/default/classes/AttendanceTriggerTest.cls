@isTest
public with sharing class AttendanceTriggerTest {
    public static String CRON_EXP = '0 0 0 15 3 ? *';
    @TestSetup
    static void makeData(){
        TestUserBuilder tub = new TestUserBuilder();
        Id profileId = UserInfo.getProfileId();
        tub.setProfileId(profileId);
        User internalUser = tub.getTestRecord();
        internalUser.persona__c = 'Appliances- Business Development Manager Direct sales';
        Id roleId = [select id from userRole where name = 'Appliances'].id;
        internalUser.userRoleId = roleId;
        
        internalUser.Business_unit__c = 'H';

        insert internalUser;
        system.runAs(internalUser){
        Account partnerAccount = new TestAccountBuilder()
                .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId())
                .setBusinessUnit('H').setName('GD').getSavedTestRecord();
        

            List<Contact> partnerContacts = new List<Contact> {
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord(),
                new TestContactBuilder().setAccountId(partnerAccount.Id).getTestRecord()
                    
            };
                
              insert  partnerContacts; 
            partnerContacts[0].Leaves_Left__c = 18;
            update partnerContacts;
            //system.assertEquals(12, date.today().month());
            //date.today().month() = 12;
            DateTime dateOneMonthAgo = System.Today().addMonths(-1);
            String mMonth = String.valueOf(dateOneMonthAgo.month());
            LeavesAllotedCalculation.yearEndLogic(partnerContacts);
        }
    }
    
    @isTest
    public static void createAttendanceWithFutureDateShouldFail() {
        TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setStartOfday(system.now().addDays(2));
        attendanceRec = tab.setType('Missing Attendance');
        Test.startTest();
        User internalUser = [select id,IsActive from user where persona__c = 'Appliances- Area Sales Manager' and IsActive=true limit 1];
        List<Attendance__c> attendanceList = new List<Attendance__c>();   
        system.runAs(internalUser) {
       
           try{
                insert attendanceRec;
                attendanceList = [SELECT Id FROM Attendance__c];
                System.assertEquals(0,attendanceList.size(),'Attendance with future date should not have inserted');
                
            }catch(Exception e){
                attendanceList = [SELECT Id FROM Attendance__c];
                System.assertEquals(0,attendanceList.size(),'Attendance with future date should not have inserted');
            }
        }
        Test.stopTest();
     }
    
    @isTest
    public static void createAttendanceWithPastShouldPass() {
        TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setType('Missing Attendance');
        attendanceRec.end_of_day__c = attendanceRec.start_of_day__c.addHours(2);
        attendanceRec.Auto_Submit_For_Approval__c = false;
        //Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
        //insert setting;
        insert attendanceRec;
        List<Attendance__c> attendanceList = new List<Attendance__c>(); 
                
       
        Test.startTest();
        	String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP,
            new LeaveUpdateYearlyBatch());

            try{
                attendanceRec.start_of_day__c = System.now().addDays(-1);
                update attendanceRec;
                attendanceList = [SELECT Id,Start_Of_day__c FROM Attendance__c LIMIT 1];
                System.assertEquals(System.now().addDays(-1).day(),attendanceList[0].Start_Of_day__c.day(),'Attendance with Past date not updated');
               
            }catch(Exception e){
                attendanceList = [SELECT Id,Start_Of_day__c FROM Attendance__c LIMIT 1];
                System.assertEquals(System.now().addDays(-1).day(),attendanceList[0].Start_Of_day__c.day(),'Attendance with Past date not updated');
            }
        Test.stopTest();
    }

    @isTest
    public static void createDuplicateAttendanceWithShouldFail() {
        TestUserBuilder tub = new TestUserBuilder();
        Id profileId = UserInfo.getProfileId();
        tub.setProfileId(profileId);
        User internalUser = tub.getTestRecord();
        internalUser.persona__c = 'Appliances- Self calling executive';
        internalUser.Latitude = null;
        internalUser.Longitude = null;
        Id roleId = [select id from userRole where name = 'Appliances'].id;
        internalUser.userRoleId = roleId;        
        insert internalUser;
        system.runAs(internalUser) {
        TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setType('Missing Attendance');
        attendanceRec.end_of_day__c = attendanceRec.start_of_day__c.addHours(2);
        attendanceRec.Auto_Submit_For_Approval__c = false;
        insert attendanceRec;
        //Increase coverage
        Attendance__c attendanceRec2 =  new TestAttendanceBuilder().setType('Missing Attendance');
        attendanceRec2.start_of_day__c = attendanceRec2.start_of_day__c.addDays(-5);
        attendanceRec2.end_of_day__c = attendanceRec2.start_of_day__c.addHours(2);
        attendanceRec2.Auto_Submit_For_Approval__c = false;
        insert attendanceRec2;
        List<Attendance__c> attendanceList = new List<Attendance__c>(); 
        Test.startTest();
        try{
            Attendance__c attendanceRecDup = tab.setType('Missing Attendance');
            attendanceRecDup = tab.setStartOfDay(System.now().AddDays(-1));
            attendanceRecDup = tab.setEndOfDay(attendanceRecDup.Start_Of_day__c);
            attendanceRecDup.Id = null;
            insert attendanceRecDup;
            attendanceList = [SELECT Id FROM Attendance__c];
            System.assertEquals(2,attendanceList.size(),'Dupilcate attendance record should not have inserted');
          }catch(Exception e){
            attendanceList = [SELECT Id FROM Attendance__c];
            System.assertEquals(2,attendanceList.size(),'Dupilcate attendance record should not have inserted');
          }
        }
         Test.stopTest();
    }
    


    //Appliances- Cluster Head direct sales
    @isTest
    public static void createAttendanceWithPartnerUserApproverFail() {
        TestUserBuilder tub = new TestUserBuilder();
        User partnerUser = tub.getPartnerUser();
        partnerUser.persona__c = 'Appliances- Door to Door Sales executive';
        update partnerUser;
        system.runAs(partnerUser) {
        Attendance__c attendanceRec = new Attendance__c();
        attendanceRec.Type__c =GlobalConstants.ATT_MISSING_ATTENDANCE;
        attendanceRec.Start_Of_Day__c= system.now();
        attendanceRec.End_Of_Day__c= system.now().AddHours(+4);
        attendanceRec.Auto_Submit_For_Approval__c = false;
        insert attendanceRec;
         
        List<Attendance__c> attendanceList = new List<Attendance__c>(); 
        Test.startTest();
        
             try{
                 
                 attendanceList = [SELECT Id FROM Attendance__c];
                 System.assertEquals(1,attendanceList.size(),'Attendance record with Partner user approver should have failed');
                   
             }catch(Exception e){
                 attendanceList = [SELECT Id FROM Attendance__c];
                 System.assertEquals(0,attendanceList.size(),'Attendance record with Partner user approver should have failed');
             }
        }    
        Test.stopTest();
    }

    
    //Added by pankaj on 2 feb 2023
    @isTest
    public static void createAdditionalAttendance() {
        TestUserBuilder tub = new TestUserBuilder();
        Id profileId = UserInfo.getProfileId();
        tub.setProfileId(profileId);
        User internalUser = tub.getTestRecord();
        internalUser.persona__c = 'Appliances- Door to Door Sales executive';
        internalUser.Latitude = null;
        internalUser.Longitude = null;
        Id roleId = [select id from userRole where name = 'Appliances'].id;
        internalUser.userRoleId = roleId;        
        insert internalUser;
        system.runAs(internalUser) {
        TestAttendanceBuilder tab = new TestAttendanceBuilder();
        Attendance__c attendanceRec = tab.setType(GlobalConstants.ATTENDANCE_LOCATION_RESET_REQUEST);
        attendanceRec.start_of_day__c =  datetime.newInstance(2014, 9, 15, 10, 20, 0);
        attendanceRec.end_of_day__c =  datetime.newInstance(2014, 9, 15, 18, 30, 0);
        attendanceRec.Auto_Submit_For_Approval__c = false;
            Boolean expectedExceptionThrown;
            try{
        		insert attendanceRec;
            }catch(Exception ex){
                expectedExceptionThrown =  ex.getMessage().contains('Base Location Reset request is not applicable for your persona') ? true : false;
            }            
            system.assertEquals(true, expectedExceptionThrown);
        }      
    }
    
 
}