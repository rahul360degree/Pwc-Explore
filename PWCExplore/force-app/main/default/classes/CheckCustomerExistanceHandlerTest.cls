@IsTest
public with sharing class CheckCustomerExistanceHandlerTest {

    @isTest
	static void testGetCustomerDetails(){
        RestRequest request = new RestRequest();
        request.requestUri = Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/v1/IVR/CheckCustomerInfo/9789871001';
        request.httpMethod = 'GET';
        RestContext.request = request;
        CheckCustomerExistanceHandler.getCustomerDetails();	
        System.assertEquals(RestContext.response.statusCode, 200);
	}
}