@isTest
global class GD_CheckBalance_HttpResponseMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals(System.Label.PRODUCT_STOCK_ENQUIRY_BDE_URL, req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setBody('<?xml version="1.0" ?><S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/"><S:Body><ShowResponse xmlns="http://www.infor.com/businessinterface/CustomerBalance_GB"><ShowResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns=""><DataArea><CustomerBalance_GB><Customer>HDX002677</Customer><Name>MARKET MOVERS INDIA</Name><CreditLimit>1371409.591552</CreditLimit><OrderBalance>10905540.73</OrderBalance><InvoiceBalance>6775301.47</InvoiceBalance><BillingRequest>0</BillingRequest><AvailableBalance>-16309432.608448</AvailableBalance><OrganizationId>00D2h0000008gtlEAA</OrganizationId></CustomerBalance_GB></DataArea></ShowResponse></ShowResponse></S:Body></S:Envelope>');
        res.setStatusCode(200);
        return res;
    }
}