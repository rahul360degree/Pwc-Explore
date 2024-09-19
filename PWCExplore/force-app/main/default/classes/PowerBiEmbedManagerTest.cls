/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 11-02-2023
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-02-2023   Varun Rajpoot   Initial Version
**/
@isTest
public class PowerBiEmbedManagerTest {
    private class RestMock1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"Test1": {"id":2, "name":"Test"}}');
            response.setStatusCode(200);
            return response;
               }
    }
    
    private class RestMock2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"Test1": {"id":2, "name":"Test"}}');
            response.setStatusCode(400);
            return response;
        }
    }
    
    static testMethod void test_PowerBiEmbedManager1(){
        Test.setMock(HttpCalloutMock.class, new RestMock1());
          PowerBiEmbedManager pbi = new PowerBiEmbedManager();
        PowerBiEmbedManager.getEmbeddingDataForReport('','');
        // System.assertNotEquals(null, PowerBiEmbedManager.getEmbeddingDataForReport('',''), 'Result should not be null');//gcp22
    }
    
    static testMethod void test_PowerBiEmbedManager2(){
        Test.setMock(HttpCalloutMock.class, new RestMock2());
         PowerBiEmbedManager pbi = new PowerBiEmbedManager(); 
        PowerBiEmbedManager.getEmbeddingDataForReport('','');
        PowerBiEmbedManager.checkConstructionUser();
        // System.assertNotEquals(null, PowerBiEmbedManager.getEmbeddingDataForReport('',''), 'Result should not be null');//gcp22;
    }
}