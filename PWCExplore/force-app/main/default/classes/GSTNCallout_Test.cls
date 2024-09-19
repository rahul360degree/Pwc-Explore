/*
comments
*/
@isTest
global class GSTNCallout_Test implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('https://taxpayer.irisgst.com', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(200);
        return res;
    }
    @isTest static void testCallout() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new GSTNCallout_Test());
        GSTNCallout.getcallout('abcd');
        test.stopTest();
    }
    
}