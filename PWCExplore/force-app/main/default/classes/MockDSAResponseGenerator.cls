@isTest
global class MockDSAResponseGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());

        String body = '';
        String tokenBody = '{"access_token": "accToken12345"}';
        String inforResponseBody = '{"status": "Success","statusCode": 200,"message": "","data": {"year": 2020,"period": 4,"bpCode": "3HX000090","closing_Balance_DR": 371987.36,"closing_Balance_CR": 0.0,"transactionalData": [{"fiscal_Year": "2020","fiscal_Period": "3","bP_Code": "3HX000090","document_Number": "11P/11031980/0","document_Date": "2019-00-25","document_Type": "Sales Invoice","cheque_No": "","debit_Amount": 6196.00,"credit_Amount": 0.0,"receipt_Remarks_reference": "3HX000090/0519/CHA/A0003" }]}}';
        if(req.getEndpoint() == System.Label.Token_URL) {
            body = tokenBody;
        } else if(req.getEndpoint() == System.Label.EndpointDSA) {
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