public with sharing class GVLC_QR_Code_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT ID,QR_Code__c,QR_Code_Generation_Date__c,Product_Code__c,Product_Name__c,Member_Mobile_Number__c,Loyalty_Points__c FROM Asset WHERE Status = \'Pending QR Codes\' AND QR_Code__c != NULL');
    }
    public void execute(Database.BatchableContext bc, List<Asset> assetRecords) {
        List<Map<String, String>> jsonDataList = new List<Map<String, String>>();
        Map<String, Asset> assetMap = new Map<String, Asset>();
        List<Asset> assetRecordToUpdate = new List<Asset>();
        for(Asset a : assetRecords){
            jsonDataList.add(new Map<String, String>{
                'QrCode' => a.QR_Code__c,
                'Unique ID' => 'Get Product Details 03-06-2023 5665 PM'
            });
            assetMap.put(a.QR_Code__c, a);
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://52cb3cb5-e7d1-4fcd-8038-d6d6d60f2bce.mock.pstmn.io/getRecords');
        req.setMethod('POST');

        String jsonDataString = JSON.serialize(jsonDataList);
        req.setBody(jsonDataString);

        HttpResponse res = h.send(req);
        if(res.getStatusCode() == 200){
            List<ResponseWrapperClass> wrapperObj = (List<ResponseWrapperClass>)JSON.deserialize(res.getBody(), List<ResponseWrapperClass>.class);
            for(ResponseWrapperClass obj : wrapperObj){
                System.debug(obj.QrCode);
                System.debug(assetMap.keySet());
                if(assetMap.get(obj.QrCode) != null){
                    Asset a = assetMap.get(obj.QrCode);
                    a.QR_Code_Generation_Date__c = obj.getQRCodeGenerationDateAsDate();
                    a.Product_Code__c = String.valueOf(obj.ProductCode);
                    a.Product_Name__c = obj.ProductName;
                    a.Member_Mobile_Number__c = obj.MemberMobileNumber;
                    a.Loyalty_Points__c = Decimal.valueOf(obj.LoyaltyPoints);
                    assetRecordToUpdate.add(a);
                }
            }
        }
        if(!assetRecordToUpdate.isEmpty()){
            System.debug(assetRecordToUpdate[0]);
            update assetRecordToUpdate;
        }
        System.debug(res.getBody());
        
    }
    public void finish(Database.BatchableContext bc) {

    }
    public class ResponseWrapperClass {
        public String QrCode { get; set; }
        public String QRCodeGenerationDate { get; set; }
        public Integer ProductCode { get; set; }
        public String ProductName { get; set; }
        public String MemberMobileNumber { get; set; }
        public String LoyaltyPoints { get; set; }
        public String ResponseCode { get; set; }
        public String ResponseMessage { get; set; }
        public String UniqueID { get; set; }

        public Date getQRCodeGenerationDateAsDate() {
            // Check if the date string is not null or empty
            if (String.isNotBlank(QRCodeGenerationDate)) {
                // Split the date string by '/' character
                List<String> dateParts = QRCodeGenerationDate.split('/');
                // Ensure that the date string has three parts (year, month, day)
                if (dateParts.size() == 3) {
                    // Extract year, month, and day from the date parts
                    Integer year = Integer.valueOf(dateParts[0]);
                    Integer month = Integer.valueOf(dateParts[1]);
                    Integer day = Integer.valueOf(dateParts[2]);
                    // Construct a Date variable using the year, month, and day
                    return Date.newInstance(year, month, day);
                }
            }
            return null;
        }
    }
}