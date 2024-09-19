public with sharing class QrScannerController {
    @AuraEnabled
    public static Boolean makeMockApiCall(String scannedValue) {
        String mockApiEndpoint = 'https://test14.free.beeceptor.com';
        Boolean isProductFound = false;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(mockApiEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"barcode":"' + scannedValue + '"}');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            isProductFound = res.getBody() == 'true';
        } else {
            System.debug('Failed to make mock API call: ' + res.getStatus() + ' ' + res.getBody());
            isProductFound = false;
        }

        return isProductFound;
    }
}