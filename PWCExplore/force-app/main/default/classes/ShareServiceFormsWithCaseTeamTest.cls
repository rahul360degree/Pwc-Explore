/*------------------------------------------------------------------------------------
 * Author        :        Nupoor
 * Company       :        Salesforce
 * Description   :        Test class for ShareServiceFormsWithCaseTeam
 * Inputs        :        
 * Test Class    :    
 * History
 * --------
 * 17-12-2020      Nupoor Sharma     Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class ShareServiceFormsWithCaseTeamTest {
    
    //Setting up data for all test cases
    @testsetup
    private static void createData() {
        
        Profile userProfile = [Select Id from Profile where Name = 'System Administrator' LIMIT 1];
        // Create User record.
        User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Test', lastname = 'User', Alias = 'tuser',
                            languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,isActive=true,
                            timezonesidkey = 'Asia/Kolkata', email = 'test.user@godrej.com', username = 'shareserviceforms.user@godrej.com', Business_Unit__c = GlobalConstants.MHE_DIVISION_CODE);

        userToRun.Persona__c = 'MHE Sales-KAM';
        userToRun.Sub_Division__c = 'B2B';
        userToRun.Logistic_Company__c = '2000';
        userToRun.Area_Code__c = 'WN1';
        insert userToRun;

        
        Account accountRecord = new TestAccountBuilder()
            .setRecordTypeId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId())
            .getSavedTestRecord();
        accountRecord.Business_Unit__c = GlobalConstants.BUSINESS_UNIT_MHE_DIVISION;
        update accountRecord;

         
        Case caseRecord = new TestCaseBuilder()
                              .setAccountId(accountRecord.Id)
                              .setAlternateMobile('9999999990')
                              .setAlternateEmail('test.user@email.com')
            				  .setRecordTypeId((RecordTypeUtils.getInstance()).getRecordTypeId('Case', 'Interio_B2C'))
                              .getSavedTestRecord();
        CaseTriggerHandler.TriggerDisabled = true;
        update caseRecord;
        CaseTriggerHandler.TriggerDisabled = false;
		
        List<Service_Form__c> serviceforms = new List<Service_Form__c>();
        Service_Form__c serviceForm = new TestServiceFormBuilder()
                                      .setCaseId(caseRecord.Id)
            						  .setRecordTypeId((RecordTypeUtils.getInstance()).getRecordTypeId('Service_Form__c', 'Job_Card'))
                                      .getSavedTestRecord();
        //update serviceForm;
        serviceforms.add(serviceForm);
        Service_Form__c serviceForm2 = new TestServiceFormBuilder()
                                      .setCaseId(caseRecord.Id)
            						  .setRecordTypeId((RecordTypeUtils.getInstance()).getRecordTypeId('Service_Form__c', 'Commissioning_Checklist'))
                                      .getSavedTestRecord();
        //update serviceForm2;
        serviceforms.add(serviceForm2);
        update serviceforms;
        
    }
    
    //Tests that the service form records are shared with case owner
    @IsTest
    static void testServiceFormsAreSharedWithCaseOwner(){
        test.startTest();
        List<Case> caseList = new List<Case>([Select Id FROM Case]);
        //test.startTest();
        caseList[0].OwnerId = UserInfo.getUserId();
        CaseTriggerHandler.TriggerDisabled = true;
        update caseList;
        CaseTriggerHandler.TriggerDisabled = false;
        ShareServiceFormsWithCaseTeam.shareForCase(caseList);
        //test.stopTest();

       List<Service_Form__Share> shareRecords = new List<Service_Form__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate 
                                                                               FROM Service_Form__Share 
                                                                               WHERE RowCause = 'Case_Team__c']);
       	Test.stopTest();
        System.assertEquals(TRUE, shareRecords.size()>0, 'Share Record should be inserted for Case Owner');
    }
    
    //Tests that the service form records are shared with case team members
    @IsTest
    static void testServiceFormsAreSharedWithCaseTeam(){
        List<Case> caseList = new List<Case>([Select Id FROM Case]);
        caseList[0].OwnerId = UserInfo.getUserId();
        CaseTriggerHandler.TriggerDisabled = true;
        update caseList;
        CaseTriggerHandler.TriggerDisabled = false;

        ShareServiceFormsWithCaseTeam.shareForCase(caseList);
        
        List<Service_Form__Share> shareRecords = new List<Service_Form__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate 
                                                                               FROM Service_Form__Share 
                                                                               WHERE RowCause = 'Case_Team__c']);
        System.assertEquals(TRUE, shareRecords.size()>0, 'Share Record should be inserted for Case Owner');
        
        //Insert CaseTeamMember
        Id caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Support Agent' LIMIT 1].id;
        Id userId = [SELECT Id FROM User WHERE username = 'shareserviceforms.user@godrej.com' LIMIT 1].id;
        CaseTeamMember ctm = new CaseTeamMember();
        ctm.MemberId = userId;
        ctm.ParentId = caseList[0].id;
        ctm.TeamRoleId = caseTeamRoleId;
        insert ctm;
        Test.startTest();
        ShareServiceFormsWithCaseTeam.shareForCase(caseList);
        List<Service_Form__Share> shareRecords2 = new List<Service_Form__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate 
                                                                               FROM Service_Form__Share 
                                                                               WHERE RowCause = 'Case_Team__c']);
        Test.stopTest();
        System.assertEquals(TRUE, shareRecords2.size()>shareRecords.size(), 'Share Record should be inserted for Case Team Members');
    }
    
    //Tests that the service form records are revoked from users not required
    @IsTest
    static void testOutdatedShareRecordsAreRevoked(){
        List<Case> caseList = new List<Case>([Select Id FROM Case]);
        //Insert CaseTeamMember
        Id caseTeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Support Agent' LIMIT 1].id;
        Id userId = [SELECT Id FROM User WHERE username = 'shareserviceforms.user@godrej.com' LIMIT 1].id;
        CaseTeamMember ctm = new CaseTeamMember();
        ctm.MemberId = userId;
        ctm.ParentId = caseList[0].id;
        ctm.TeamRoleId = caseTeamRoleId;
        insert ctm;
        //deleting the case team member
        delete ctm;
        Test.startTest();
        ShareServiceFormsWithCaseTeam.shareForCase(caseList);
        
        List<Service_Form__Share> shareRecords2 = new List<Service_Form__Share>([SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause, LastModifiedDate 
                                                                                 FROM Service_Form__Share 
                                                                                 WHERE RowCause = 'Case_Team__c'
                                                                                 AND UserorGroupId = : userId]);
        Test.stopTest();
        System.assertEquals(TRUE, shareRecords2.size()==0, 'Share Record should not be shared with deleted case team member');
    }
    
    
    //Tests the helper method for aura component
    @IsTest
    static void testAuraHelper(){
        Test.startTest();
        List<Case> caseList = new List<Case>([Select Id FROM Case]);
        String retrurnVal = ShareServiceFormsWithCaseTeam.shareCaseForms(caseList[0].Id);
        Test.stopTest();
        System.assertEquals(retrurnVal, caseList[0].id, 'Should return the recordId for Successful transaction');
    }




}