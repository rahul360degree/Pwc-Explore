@isTest
global class MockFocResponseGenerator2 implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());

        String body = '';
        String tokenBody = '{"access_token": "accToken12345"}';
        String inforResponseBody = '{"status":"No Content","statusCode":204,"message":"Order lines not delivered yet","deliveryDate":""}';
        if(req.getEndpoint() == System.Label.FOC_Token_URL) {
            body = tokenBody;
        } else if(req.getEndpoint() == System.Label.FOC_URL) {
            body = inforResponseBody;
        }
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(204);
        return res;
    }

}