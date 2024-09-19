@IsTest
public with sharing class MockCTI_DisposeCallController implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        String body = '{"Test": "Mockdata"}'; //EzetapMockFocResponsebody
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
}