@isTest
global class MockFocResponseGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());

        String body = '';
        String tokenBody = '{"access_token": "accToken12345"}';
        String inforResponseBody = '{"status":"Success","statusCode":200,"message":"","deliveryDate":"02/01/2021"}';
        if(req.getEndpoint() == System.Label.FOC_Token_URL) {
            body = tokenBody;
        } else if(req.getEndpoint() == System.Label.FOC_URL) {
            body = inforResponseBody;
        }
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }

}