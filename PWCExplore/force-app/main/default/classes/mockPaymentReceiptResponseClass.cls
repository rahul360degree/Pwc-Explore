@isTest
global class mockPaymentReceiptResponseClass implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());

        String body = '';
        String trackid = '{"trackid": "accToken12345"}';
        String ResponseBody = '{"status": "Success","statusCode": 200}';
        if(req.getEndpoint() == 'accToken12345') {
            body = trackid;
        } else if(req.getEndpoint() == 'http://www.sms.godrej.com/FetchMessages.php?MobileNo=9075294054&DateTime= 2021-08-04 16:00:00&msg= SFONECRM CUSTGOD dear user&trackid= accToken12345') {
            body = ResponseBody;
        }
      
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('success');
        res.setStatusCode(200);
        return res;
    }
      
}