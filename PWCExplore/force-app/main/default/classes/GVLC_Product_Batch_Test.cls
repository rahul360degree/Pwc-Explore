@isTest
private class GVLC_Product_Batch_Test {
    @testSetup static void setup() {
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;
        
        
        Address__c address = new Address__c();
        address.Address_Type__c = 'B2B';
        address.Address_Format__c = 'ADR';
        address.Name__c = 'Nuvoco Plant Pune';
        address.Telephone__c = '8765432111';
        address.Email__c = 'punetest1234@nuvoco.com';
        address.Building__c = 'Avenues';
        address.Street2__c = '1st Street';
        insert address;
        
        
        Asset asset = new Asset(
            AccountId = newAccount.id,
            Address_Code__c = address.id,
            Status = 'Pending QR Codes',
            QR_Code__c = 'TestQRCode',
            QR_Code_Generation_Date__c = Date.today(),
            Product_Code__c = '1234',
            Product_Name__c = 'Test Product',
            Name= 'test Asset',
            Coverage__c = 'KFTWC01200001',
            Type_of_Warranty__c = 'Special Warranty',
            Member_Mobile_Number__c = '1234567890',
            Loyalty_Points__c = 100
        );
        insert asset;
    }
    @isTest
    static void testBatchExecution() {

        // Set up mock response for the callout
        HttpCalloutMock mock = new GVLC_Product_Batch_Test.MockHttpResponse();
        Test.setMock(HttpCalloutMock.class, mock);

        // Start the batch execution
        Test.startTest();
        Database.executeBatch(new GVLC_Product_Batch());
        Test.stopTest();

        // Verify that the asset record is updated
        Asset asset = [SELECT QR_Code_Generation_Date__c, Product_Code__c, Product_Name__c, Member_Mobile_Number__c, Loyalty_Points__c FROM Asset WHERE QR_Code__c = 'TestQRCode' LIMIT 1];
        System.assertEquals('2023-11-02', String.valueOf(asset.QR_Code_Generation_Date__c));
        System.assertEquals('2569', asset.Product_Code__c);
        System.assertEquals('Hinge SS 150X76X2.5mm (6X12)', asset.Product_Name__c);
        System.assertEquals('9865741236', asset.Member_Mobile_Number__c);
        System.assertEquals(100, asset.Loyalty_Points__c);
    }

    // Inner class to mock HTTP response
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            res.setBody('[{"QrCode":"TestQRCode","QRCodeGenerationDate":"2023/11/02","ProductCode":2569,"ProductName":"Hinge SS 150X76X2.5mm (6X12)","MemberMobileNumber":"9865741236","LoyaltyPoints":"100","ResponseCode":"001","ResponseMessage":"Success","UniqueID":"Get Product Details 03-06-2023 5665 PM"}]');
            res.setStatusCode(200);
            return res;
        }
    }
}