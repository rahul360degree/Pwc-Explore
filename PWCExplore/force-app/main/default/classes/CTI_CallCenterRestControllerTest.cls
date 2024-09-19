@IsTest
public with sharing class CTI_CallCenterRestControllerTest {

    @TestSetup
    static void createData(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25389')
            .setPersona(GlobalConstants.const_engineer_persona)
            .getSavedTestRecord();

        System.runAs(contextuser) {
            Case newCase = new Case(
                Status = 'New', Priority = 'Medium', 
                Type = 'Product Quality Issue',
                Origin = 'Web'
            );

            insert newCase;
        }
    }

    @IsTest
    static void testLogCallHistory() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        RestRequest request = new RestRequest();
        request.requestUri = Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/v1/CallCenter/LogCall';
        request.requestBody = Blob.valueOf('{"durationOfCall" : "60", "mobileNo" : "9876952146", "callStartTime" : "02:10:10", "callEndTime" : "02:11:15", "caseId" : "' + caseRecord.Id +'"}');
        request.httpMethod = 'POST';
        RestContext.request = request;
        CTI_CallCenterRestController.logCallHistory();	
        Task tsk = [select id, Subject from task limit 1];	
        System.debug(String.valueOf(RestContext.response.responseBody));
        System.assertEquals(tsk.Subject.contains('9876952146'), true);
    }
}