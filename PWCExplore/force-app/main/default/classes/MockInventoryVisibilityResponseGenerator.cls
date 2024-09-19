@isTest
global class MockInventoryVisibilityResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());

        String body = '';
        String tokenBody = '{"access_token": "accToken1234"}';
        String inforResponseBody = '{"status": "Success","statusCode": 200,"message": "","listCount": 2,"data": [{"itemCode": "26101304PA00035","itemDesc": "MotorPA Brush Holder Gpsm2/3","BusinessCode": "KV","itemGroup": "26MOHP / Motor Spares","warehouse": "Z2F18S / WZHUB-H-MHE SERVICE-FG-R","warehouseType": "Finished Goods","transactionAging": 892,"stock": 9,"freeStock": 9,"invUnit": "ECH""Serial" :"a,b,c"},{"itemCode": "240-STK001-STTRDXXXXXXXXX23","itemDesc": "954752","BusinessCode": "Y9","itemGroup": "56STSP / Storage Unit Parts","warehouse": "Z2F1XE / WZHUB  -DEF-2","warehouseType": "Finished Goods","transactionAging": 709,"stock": 35,"freeStock": 35,"invUnit": "EA"}]}';
        if(req.getEndpoint() == System.Label.Token_URL) {
            body = tokenBody;
        } else if(req.getEndpoint() == System.Label.Endpoint) {
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