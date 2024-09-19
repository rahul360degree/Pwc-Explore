@IsTest
public with sharing class IVR_ServiceRequestRestControllerTest {
    @TestSetup
    static void createData(){
        Profile profile = [SELECT Id FROM Profile WHERE Name =:GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME];
        User contextuser = new TestUserBuilder().setProfileId(profile.Id)
            .setBusinessUnit(GlobalConstants.Construction_BUSINESS_UNIT).setSalaryCode('25389')
            .setPersona(GlobalConstants.const_engineer_persona)
            .getSavedTestRecord();

        System.runAs(contextuser) {
            Id accId = LeaseTestDataFactory.createAccount('OANIN1234K');
        }
    }

    @IsTest
    static void testDoPost() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        RestRequest request = new RestRequest();
        request.requestUri = Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/v1/CallCenter/LogCall';
        request.requestBody = Blob.valueOf('{"accountId" : "' + acc.Id + '", "mobileNo" : "9876952146"}');
        request.httpMethod = 'POST';
        RestContext.request = request;
        IVR_ServiceRequestRestController.doPost();		
        Case cs = [SELECT AccountId from Case limit 1];
        System.assertEquals(cs.AccountId, acc.Id);
    }

}