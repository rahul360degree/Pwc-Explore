/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       Godrej Infotech
Description:   This test class covers sendPMOverdueNotificationBatch,sendPMOverdueNotificationScheduler                                          

History
10-05-2022      Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class sendPMOverdueNotificationBatchTest {
    @testSetup
    static void createData(){
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();
        Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
        Id ssgRTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        UserRole iaUserRole = new UserRole(Name = 'CEO');
        Profile iaProfile = [SELECT Id FROM Profile WHERE Name = 'Integration Administrator' LIMIT 1];
        User ssg_user = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                 Alias = 'ssg', Email='ssgUser@godrej.com',Salary_Code__c='377337',Business_Unit__c='G',
                                 EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                 TimeZoneSidKey='America/Los_Angeles',Username = 'ssgUser@godrej.com',CommunityNickname = 'test1234567');
        insert ssg_user;
        
        User ssg_collabrationMember = new User(UserRoleId = iaUserRole.Id, ProfileId = iaProfile.Id, 
                                               Alias = 'ssg', Email='chatterUser@godrej.com',Salary_Code__c='293030',Business_Unit__c='G',
                                               EmailEncodingKey='UTF-8', LastName='Testing_ssg', LanguageLocaleKey='en_US',LocaleSidKey='en_US',
                                               TimeZoneSidKey='America/Los_Angeles',Username = 'chatterUser@godrej.com',CommunityNickname = 'test1234568');
        insert ssg_collabrationMember;
        
        system.runAs(ssg_user){
            Runtime_Execution__c setting = Runtime_Execution__c.getInstance();
            setting.AccountTriggerDisabled__c = true;
            setting.OrderTriggerDisabled__c = true;
            setting.QuoteTriggerDisabled__c = true;
            insert setting;
            Account acc= new Account();
            acc.Name = 'TestAccount';
            acc.Interio_Sub_Division__c= 'B2B-KAM';
            acc.Business_Unit__c = 'G';
            acc.Type = 'F';
            acc.Account_Series__c = System.Label.Parent_Account_Series;
            insert acc;
            Contact con = new Contact();
            con.LastName = 'ssgcontact';
            con.AccountId = acc.id;
            con.Business_Unit__c = 'G';
            con.MobilePhone = '9870654865';
            con.Email = 'ssgcontact@gmail.com';
            insert con;
            
            Opportunity newSsgOpp = new Opportunity(
                Name = 'Test ssg Opp',               
                AccountId = acc.Id, 
                Sales_Branch_Name__c = '3010',               
                LeadSource = 'Advertisement',           
                Business_Unit__c = 'G',                       
                Organization_Name__c = '18-30 Lakhs',         
                Birthdate__c = Date.valueOf('1992-01-23'),    
                Amount = 8866.85,                             
                Anniversary__c = Date.valueOf('2019-11-07'),  
                CloseDate = Date.today().addDays(28),       
                StageName = 'Qualification',              
                ForecastCategoryName = 'Pipeline',            
                Probability = 35,                             
                Occupation__c = 'Business',                    
                Internal_Sales_Rep__c = UserInfo.getUserId(),    
                Area_Code__c = 'EA1',               
                Room_Planner_Demo_Done__c = 'No',             
                Product_Configuration_Demo_Given__c = 'Yes',  
                Exchange_Order__c = 'No',                     
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SSG').getRecordTypeId());
            
            insert newSsgOpp;
            Quote newQuote = new Quote(
                Name = 'Test Quote',                 
                Opportunity_Owner__c = UserInfo.getUserId(),         
                Status = 'Draft',                             
                OpportunityId = newSsgOpp.Id,                
                Approval_Status__c = 'Approval Not Required',     
                ExpirationDate = Date.today().addDays(20),      
                Area_Code__c = 'EA1',                   
                Transaction_Type__c = 'Primary',                  
                Quote_Type__c = 'Customer Facing'//,
            );
            insert newQuote;
            //Creating order for SSG
            Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                           Line_of_Business__c = 'ENGG',                               
                                           Business_Unit__c = 'G', Sub_Division__c = 'B2B',                                                
                                           Internal_Sales_Representative__c = ssg_user.id,Design_clearance_required__c='No',
                                           AccountId = acc.Id,EffectiveDate = System.today(),Status = 'Draft',
                                           Planned_Delivery_Date__c=system.today(), Planned_Receipt_Date__c=system.today(),
                                           QuoteId = newQuote.Id,sold_to_contact__c = con.Id,
                                           RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('SSG_Primary').getRecordTypeId());
            insert newOrder_ssg;
            
            Case TestPMGeneration = new Case();
            TestPMGeneration.Subject = 'Test SSG Service Request';
            TestPMGeneration.Description = 'Test SSG Service Request';
            TestPMGeneration.AccountId = acc.Id;
            TestPMGeneration.RecordTypeId = ssgRTID;
            TestPMGeneration.Project_Number__c = 'PRN012398';
            TestPMGeneration.Order__c=newOrder_ssg.id;
            insert TestPMGeneration;
            
            CollaborationGroup groupe = new CollaborationGroup(Name = 'SSG Design Post order tea', CollaborationType = 'Public');
            insert groupe;
            
            collaborationgroupmember cgm = new collaborationgroupmember();
            cgm.CollaborationGroupId = groupe.Id;
            cgm.MemberId = ssg_collabrationMember.Id;
            insert cgm;  
        }
    }
    
    @isTest
    static void pmTest(){
        List<Project_milestone__c> lstProMile = new List<Project_milestone__c>();
        Project_milestone__c pm = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: GlobalConstants.Supply_milestone_RECORDTYPE_ID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        pm.Planned_Completion_Date__c = System.today() - 1;
        pm.Status__c = 'Yet to start';
        pm.Dealer_Email__c = 'abc@gmail.com';
        pm.Internal_sales_rep_email__c = 'xyz@gmail.com';
        lstProMile.add(pm);
        update pm;
        Project_milestone__c pm1 = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: GlobalConstants.Design_milestone_RECORDTYPE_ID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        pm1.Planned_Completion_Date__c = System.today() - 1;
        pm1.Status__c = 'Yet to start';
        pm1.Dealer_Email__c = 'abc@gmail.com';
        pm1.Internal_sales_rep_email__c = 'xyz@gmail.com';        
        lstProMile.add(pm1);
        Project_milestone__c pm2 = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: GlobalConstants.Ho_Project_milestone_RECORDTYPE_ID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        pm2.Planned_Completion_Date__c = System.today() - 1;
        pm2.Status__c = 'Yet to start';
        pm2.Dealer_Email__c = 'abc@gmail.com';
        pm2.Internal_sales_rep_email__c = 'xyz@gmail.com';
        lstProMile.add(pm2);
        //update lstProMile;
        Test.startTest();
        String CRON_EXP = '0 30 16 * * ? *';
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new sendPMOverdueNotificationScheduler());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }
    
}