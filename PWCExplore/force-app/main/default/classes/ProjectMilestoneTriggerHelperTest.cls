/*------------------------------------------------------------------------
Author:        Suwarna Rao
Company:       Salesforce
Description:   Test class for 'projectMilestoneTriggerHelper'.
Inputs:        NA
Test Class:   

History
08-01-2021      Suwarna Rao     Initial Release
----------------------------------------------------------------------------*/
@isTest
public class ProjectMilestoneTriggerHelperTest {
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
            //Sold_To_Business_Partner__c = cocoUser.Account__c,  
            //Ship_To_Account__c = cocoUser.Account__c
            );
        insert newQuote;
        //Creating order for SSG
        Order newOrder_ssg = new Order( Logistics_Company_Branch__c = '1300',                  
                                       Line_of_Business__c = 'ENGG',                               
                                       Business_Unit__c = 'G', Sub_Division__c = 'B2B',                                                
                                       Internal_Sales_Representative__c = ssg_user.id,Design_clearance_required__c='No',
                                       AccountId = acc.Id,EffectiveDate = System.today(),Status = 'Draft',
                                       Planned_Delivery_Date__c=system.today(), Planned_Receipt_Date__c=system.today(),
                                       QuoteId = newQuote.Id,
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
            }
    }
    
    @isTest
    static void bookingEndDateValidationTest(){
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();       
        
        Project_milestone__c pm = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        
        pm.Start_Date__c = System.today();
        pm.End_Date__c = System.today().addDays(5);
        test.startTest();
        try{
            update pm;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Please complete the Design Status to edit this field'));
        }
        test.stopTest();             
    }
    
    @isTest
    static void ccDateValidationTest() {
        String SITE_VERIFICATION_RECORDTYPEID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.Label.Site_Verification_PM_Recordtype).getRecordTypeId();
        Project_milestone__c siteVerificationMilestone = [SELECT Id, Phase__c, Status__c from Project_milestone__c WHERE RecordTypeId =: SITE_VERIFICATION_RECORDTYPEID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        siteVerificationMilestone.Status__c = System.Label.SITE_VERIFICATION_COMPLETED_STATUS;
        update siteVerificationMilestone;
        
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        Project_milestone__c exeMilestone = [SELECT Id, Phase__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Phase__c = 'Phase 1';
        update exeMilestone;
        
        Project_milestone__c finalCommMilestone = [SELECT Id, CC_Date__c,Phase__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        finalCommMilestone.CC_Date__c = system.today();
        finalCommMilestone.Phase__c = 'Phase 1';
        
        
        String yourFiles = 'CC Certificate';
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = 'ionicLogo.png'; 
        conVer.Title = 'CC Certificate '; 
        conVer.VersionData = EncodingUtil.base64Decode(yourFiles); 
        insert conVer;
        
        // First get the content document Id from ContentVersion
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = finalCommMilestone.Id; 
        cDe.ShareType = 'I'; 
        cDe.Visibility = 'InternalUsers';
        insert cDe;
        
        test.startTest();
        try{
            update finalCommMilestone;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Please enter the Installation End date'));
        }
        test.stopTest();
    }
    
    @isTest
    static void installationStartDateValidationTest(){
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();        
        Id siteVerificationRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Site_Verification_Record_Type).getRecordTypeId();
        
        Project_milestone__c siteVerificationMilestone = [SELECT Id, Phase__c from Project_milestone__c WHERE RecordTypeId =: siteVerificationRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        siteVerificationMilestone.Phase__c = 'Phase 1';
        update siteVerificationMilestone;
        
        Project_milestone__c exeMilestone = [SELECT Id, Phase__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Phase__c = 'Phase 1';
        exeMilestone.Start_Date__c = system.today();
        
        test.startTest();
        try{
            update exeMilestone;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Please Enter the Site Verification Date'));
        }
        test.stopTest();
    }
    
    @isTest
    static void updateInstallationPendingReasonTest(){
        String SITE_VERIFICATION_RECORDTYPEID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.Label.Site_Verification_PM_Recordtype).getRecordTypeId();
        Project_milestone__c siteVerificationMilestone = [SELECT Id, Phase__c, Status__c from Project_milestone__c WHERE RecordTypeId =: SITE_VERIFICATION_RECORDTYPEID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        siteVerificationMilestone.Phase__c = 'Phase 1';
        siteVerificationMilestone.Site_Verification_Done_On__c = system.today().addDays(8);
        siteVerificationMilestone.Status__c = System.Label.SITE_VERIFICATION_COMPLETED_STATUS;
        update siteVerificationMilestone;
        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();      
        Id siteVerificationRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Site_Verification_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();
        
        Project_milestone__c finalCommMilestone = [SELECT Id, Phase__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        finalCommMilestone.Phase__c = 'Phase 1';
        
        Project_milestone__c exeMilestone = [SELECT Id, Phase__c,Start_Date__c,End_Date__c,Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Phase__c = 'Phase 1';
        exeMilestone.Start_Date__c = system.today();
        exeMilestone.End_Date__c = system.today().addDays(5);
        test.startTest();
        update exeMilestone;
        test.stopTest();
        
        Project_milestone__c exe = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        
        system.assertEquals('CC Awaited',exe.Installation_Pending_reason__c);
    }
    
    @isTest
    static void validateDataTest() {
        Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();      
        Project_milestone__c bookingMilestone = [SELECT Id, FOC_Number__c from Project_milestone__c WHERE RecordTypeId =: booking2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        bookingMilestone.FOC_Number__c = 'w23hjklpo';
        test.startTest();
        try{
            update bookingMilestone;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Please enter valid FOC/SO Number. First 3 characters should be text, remaining 6 should be numbers'));
        }
        test.stopTest();
    }
    
    @isTest
    static void validateSONumberTest(){
        Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();      
        Project_milestone__c bookingMilestone = [SELECT Id, SO_Number__c from Project_milestone__c WHERE RecordTypeId =: booking2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        bookingMilestone.SO_Number__c = 'S2C234589';
        test.startTest();
        try{
            update bookingMilestone;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Please enter valid FOC/SO Number. First 3 characters should be text, remaining 6 should be numbers'));
        }
        test.stopTest();
    }
    
    @isTest
    static void populateProjectStatusTest() {
        test.startTest();
        String SITE_VERIFICATION_RECORDTYPEID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.Label.Site_Verification_PM_Recordtype).getRecordTypeId();
        Project_milestone__c siteVerificationMilestone = [SELECT Id, Phase__c, Status__c from Project_milestone__c WHERE RecordTypeId =: SITE_VERIFICATION_RECORDTYPEID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        siteVerificationMilestone.Status__c = System.Label.SITE_VERIFICATION_COMPLETED_STATUS;
        update siteVerificationMilestone;
        
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();        
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        Project_milestone__c exe = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exe.End_Date__c = system.today().addDays(5);
        update exe;
        
        Project_milestone__c finalCommMilestone = [SELECT Id, CC_Date__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        finalCommMilestone.CC_Date__c = system.today();
        
        String yourFiles = 'CC Certificate';
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = 'ionicLogo.png'; 
        conVer.Title = 'CC Certificate '; 
        conVer.VersionData = EncodingUtil.base64Decode(yourFiles); 
        insert conVer;
        
        // First get the content document Id from ContentVersion
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = finalCommMilestone.Id; 
        cDe.ShareType = 'I'; 
        cDe.Visibility = 'InternalUsers';
        insert cDe;
        
        //test.startTest();
        update finalCommMilestone;
        test.stopTest();
        
        Project_milestone__c exeMilestone = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ]; 
        system.assertEquals('Not Applicable',exeMilestone.Installation_Pending_reason__c);   
    }
    
    @isTest
    static void reasonForHandoverDateChangeValidationTest() {
        Id execution2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Project_milestone__c exeMilestone = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: execution2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Reason_for_Handover_Date_Change__c = 'Installation Delay';
        test.startTest();
        try{
            update exeMilestone;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('Reason for Handover date Change can be modified only when Planned hand over date is modified'));
        }
        test.stopTest(); 
    }
    
    /*@isTest
static void preventDuplicateMilestoneRecordsTest() {
Id ssgRTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();      

Case ssgCase = [Select Id, Subject, RecordTypeId, CaseNumber from Case Where RecordTypeId =: ssgRTID AND Subject = 'Test SSG Service Request' LIMIT 1];

Project_milestone__c milestone = new Project_milestone__c();
milestone.RecordTypeId = booking2RTId ;
milestone.Service_Request__c = ssgCase.id;

test.startTest();
try{
insert milestone;
}catch(Exception ex){
System.assert(ex.getMessage().contains('Booking_2 record type milestone already exist for the case -00102538'));
}
test.stopTest();
}*/
    
    @isTest
    static void populateProjectNumberTest() {
        Id ssgRTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSG_Service_Request').getRecordTypeId();
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();      
        Order designOrder = [select id from Order where Design_clearance_required__c='No'];
        Account acc= new Account();
        acc.Name = 'TestAccount';
        acc.Interio_Sub_Division__c= 'B2B-KAM';
        acc.Business_Unit__c = 'G';
        acc.Type = 'M';	
        acc.Account_Series__c = System.Label.Parent_Account_Series;
        insert acc;
        
        Case ssgCase = new Case();
        ssgCase.Subject = 'SSG Service Request';
        ssgCase.Description = 'SSG Service Request';
        ssgCase.AccountId = acc.Id;
        ssgCase.RecordTypeId = ssgRTID;
        ssgCase.Project_Number__c = 'PRN012398';
        ssgCase.Order__c = designOrder.id;
        test.startTest();
        insert ssgCase;
        test.stopTest();
        
        Project_milestone__c bookingMilestone = [SELECT Id, Project_Number__c from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        
        system.assertEquals('PRN012398',bookingMilestone.Project_Number__c);  
    }
    
    @isTest
    static void populateOTIFDetailsTest() {
        test.startTest();
        String SITE_VERIFICATION_RECORDTYPEID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.Label.Site_Verification_PM_Recordtype).getRecordTypeId();
        Project_milestone__c siteVerificationMilestone = [SELECT Id, Phase__c, Status__c from Project_milestone__c WHERE RecordTypeId =: SITE_VERIFICATION_RECORDTYPEID AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        siteVerificationMilestone.Status__c = System.Label.SITE_VERIFICATION_COMPLETED_STATUS;
        //ProjectMilestoneTriggerHandler.TriggerDisabled = true;
        update siteVerificationMilestone;
        //ProjectMilestoneTriggerHandler.TriggerDisabled = false;
        
        Id execution2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id finalCommissioningAndHandOverRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Final_Commissioning_and_Handover_Record_Type).getRecordTypeId();  
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(system.label.Project_Milestone_Execution_Record_Type).getRecordTypeId();
        
        Project_milestone__c exe = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exe.End_Date__c = system.today().addDays(5);
        //ProjectMilestoneTriggerHandler.TriggerDisabled = true;
        update exe;
        //ProjectMilestoneTriggerHandler.TriggerDisabled = false;
        
        Project_milestone__c finalComm = [SELECT Id, CC_Date__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        
        String yourFiles = 'CC Certificate';
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = 'ionicLogo.png'; 
        conVer.Title = 'CC Certificate'; 
        conVer.VersionData = EncodingUtil.base64Decode(yourFiles); 
        insert conVer;
        
        // First get the content document Id from ContentVersion
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = finalComm.Id; 
        cDe.ShareType = 'I'; 
        cDe.Visibility = 'InternalUsers';
        insert cDe;
        
        Project_milestone__c finalCommMilestone = [SELECT Id, CC_Date__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        finalCommMilestone.CC_Date__c = system.today().addDays(10);
        finalCommMilestone.Phase__c = 'Phase 1';
        ProjectMilestoneTriggerHandler.TriggerDisabled = true;
        update finalCommMilestone;
        ProjectMilestoneTriggerHandler.TriggerDisabled = false;
        
        Project_milestone__c exeMilestone = [SELECT Id, Installation_Pending_reason__c from Project_milestone__c WHERE RecordTypeId =: execution2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Revised_Planned_Handover_Date_ISOB_IDD__c = system.today();
        exeMilestone.Phase__c = 'Phase 1';
        
        //test.startTest();
        //ProjectMilestoneTriggerHandler.TriggerDisabled = true;
        update exeMilestone;
        //ProjectMilestoneTriggerHandler.TriggerDisabled = false;
        test.stopTest();
        
        Project_milestone__c finalcomMilestone = [SELECT Id, OTIF_details__c from Project_milestone__c WHERE RecordTypeId =: finalCommissioningAndHandOverRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        system.assertEquals('OTIF - Delayed',finalcomMilestone.OTIF_details__c);                
    }
    
    /* @isTest
static void populateRevisedPlannedHanoverDateOnplannedHandoverDateChangeTest() {        
Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();       
Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();

Project_milestone__c designMilestone = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: designRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
designMilestone.Start_Date__c = system.today();
designMilestone.End_Date__c = system.today().addDays(5);
update designMilestone;

Project_milestone__c bookingMilestone = [SELECT Id, Start_Date__c, End_Date__c,Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
bookingMilestone.Planned_Handover_Date_ISOB_IDD__c = system.today();   
update bookingMilestone;


test.startTest();
Project_milestone__c exe = [SELECT Id, Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
exe.Phase__c = 'Phase 1';
update exe;
test.stopTest();
Project_milestone__c exeMilestone = [SELECT Id, Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
system.assertEquals(bookingMilestone.Planned_Handover_Date_ISOB_IDD__c, exeMilestone.Revised_Planned_Handover_Date_ISOB_IDD__c, 'revised planned handover date and planned hadover date should be the same');
}*/
    
    @isTest
    static void populateRevisedPlannedHandoverDateTest() {
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();       
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id designRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Design_Clearance_Record_Type).getRecordTypeId();
        
        Project_milestone__c designMilestone = [SELECT Id, Start_Date__c, End_Date__c from Project_milestone__c WHERE RecordTypeId =: designRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        designMilestone.Start_Date__c = system.today();
        designMilestone.End_Date__c = system.today().addDays(5);
        update designMilestone;
        
        Project_milestone__c bookingMilestone = [SELECT Id, Start_Date__c, End_Date__c,Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        bookingMilestone.Planned_Handover_Date_ISOB_IDD__c = system.today();
        update bookingMilestone;
        
        Project_milestone__c exeMilestone = [SELECT Id, Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Phase__c = 'Phase 1';
        
        test.startTest();
        update exeMilestone;
        test.stopTest();
        
        Project_milestone__c exe = [SELECT Id, Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        
        system.assertEquals(bookingMilestone.Planned_Handover_Date_ISOB_IDD__c, exeMilestone.Revised_Planned_Handover_Date_ISOB_IDD__c, 'revised planned handover date and planned hadover date should be the same');
    }
    
    @isTest
    static void supplyEndDatePopulationTest() {
        Account accRec = [Select Name, Business_Unit__c from Account WHERE Name = 'TestAccount'];
        
        Id booking2RTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_2_Record_Type).getRecordTypeId();      
        Project_milestone__c bookingMilestone = [SELECT Id, SO_Number__c from Project_milestone__c WHERE RecordTypeId =: booking2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        bookingMilestone.SO_Number__c = 'SCU234589';
        update bookingMilestone;
        
        Project_milestone__c booking = [SELECT Id, SO_Number__c from Project_milestone__c WHERE RecordTypeId =: booking2RTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        booking.SO_Number__c = 'ABC234589';
        
        test.startTest();
        update booking;
        test.stopTest();
    }
    
    @isTest
    static void reasonForHandoverDateChangeTest() {
        Id executionRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Execution_2_Record_Type).getRecordTypeId();
        Id bookingRTId = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(System.label.Project_Milestone_Booking_Record_Type).getRecordTypeId();
        
        Project_milestone__c bookingMilestone = [SELECT Id,Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: bookingRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        bookingMilestone.Planned_Handover_Date_ISOB_IDD__c = system.today();
        update bookingMilestone;
        
        Project_milestone__c exeMilestone = [SELECT Id, Revised_Planned_Handover_Date_ISOB_IDD__c from Project_milestone__c WHERE RecordTypeId =: executionRTId AND Service_Request__r.Subject = 'Test SSG Service Request' LIMIT 1 ];
        exeMilestone.Reason_for_Handover_Date_Change__c = 'Customer Delay' ;
        test.startTest();
        update exeMilestone;
        test.stopTest();
        
        system.assertEquals('Customer Delay', exeMilestone.Reason_for_Handover_Date_Change__c, 'reason for handover date change should be Customer Delay');
    }
    
}