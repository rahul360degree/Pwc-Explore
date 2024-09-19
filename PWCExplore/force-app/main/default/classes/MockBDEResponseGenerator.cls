@isTest
global class MockBDEResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());
        System.assertEquals(System.Label.PRODUCT_STOCK_ENQUIRY_BDE_URL, req.getEndpoint());

        String body = '';
        String inforResponseBody = '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/"><S:Body><ShowResponse xmlns="http://www.infor.com/businessinterface/InventoryVisibility_GB"><ShowResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns=""><DataArea><InventoryVisibility_GB><OrganizationID>00D2h0000008gtlEAA</OrganizationID><Warehouse>ZNF11T</Warehouse><ItemCode>00001</ItemCode><ItemDescription>HINGES (95 DEGREE PENING)</ItemDescription><Company>5010</Company><WarehouseDesc>MUMBAI PL4 FG-TOC</WarehouseDesc><WarehouseType>Finish Good Warehouse</WarehouseType><Project/><ProjectDescription/><ItemGroup>30KCHW</ItemGroup><ItemGroupDesc>Kitchen Hardware</ItemGroupDesc><BusinessCode>WL</BusinessCode><BusinessName>Interio - Home Utility Kitchen</BusinessName><InvUnit>ECH</InvUnit><OnHandStock>183</OnHandStock><FreeStock>183</FreeStock><TransactionAgingDays>371</TransactionAgingDays><CommittedQty>1</CommittedQty></InventoryVisibility_GB></DataArea></ShowResponse></ShowResponse></S:Body></S:Envelope>'; //added CommittedQty by Shreela & Pankaj on 24-02-2022
        body = inforResponseBody;
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}