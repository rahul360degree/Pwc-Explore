@isTest
public class GenericOrderInboundTest {
    
    @testSetup static void dataSetup() {
        // Create test accounts
        List<Contact> testconts = new List<Contact>();
        for(Integer i=0;i<2;i++) {
            testconts.add(new Contact(Lastname = 'TestAcct'+i));
        }
        insert testconts;        
    }
    
    
    public static testMethod void unitTestOne(){
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/createaccountorder'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json'); 
        
        req.requestBody = Blob.valueof('[{"Active":"Yes","SLA":"Gold","SLAExpirationDate":"2024-04-20","SLASerialNumber":"111","salutation":"Mr","firstName":"web service test ","lastName":"from postman 2","personMobilePhone":"8125829237","subDivision":"B2B","personEmail":"customer1@gmail.com","RecordTypeId":"0122x000000QDhkAAG","type":"SOT","paymentTerms":"30","lineOfBusiness":"01s2x000005I17YAAS","Ship_To_Address__c":"a06C4000008PB3jIAG","Ship_To_Account__c":"001C400000C7XMwIAN","Ship_to_Area_code__c":"SX1","Sold_to_Business_Partner__c":"001C400000C7XMwIAN","Sold_To_Address__c":"a06C4000008PB3jIAG","MHE_Division__c":"Contracts","Logistics_Company_Branch__c":"5000","Line_of_Business__c":"DLR","Area__c":"SX1","Sales_Office__c":"a0SC40000009ABRMA2","Sales_Order_Series__c":"KOS","Order_Currency__c":"INR","Order":{"Contract":"8005i000000QYDlAAO","type":"SOT","Pricebook2Id":"01s2x000005I17YAAS","paymentTerms":"30","effectiveDate":"2024-10-10","status":"Draft","shiptoAreacode":"SX1","MHEDivision":"Contracts","logisticsCompanyBranch":"5000","lineofBusiness":"DLR","area":"SX1","salesOrderSeries":"KOS","businessUnit":"K","subDivision":"B2B","orderCurrency":"INR","RecordTypeId":"012C4000000ZconIAC"},"OrderItems":[{"Quantity":"1","Product2Id":"01t2x000000euxVAAQ","ListPrice":"89","PricebookEntryId":"01u2x000000xlCUAAY","UnitPrice":"50"},{"Quantity":"1","Product2Id":"01t2x000000euxVAAQ","ListPrice":"89","PricebookEntryId":"01u2x000000xlCUAAY","UnitPrice":"50"}]}]');
        //req.requestBody = Blob.valueof('[{"AccountId":"001C400000CJvTOIA1"}]');
        RestContext.request = req;
        RestContext.response = res; 
        Test.startTest();
            GenericOrderInbound.createOrder();
        Test.stopTest();              
    }
    
}