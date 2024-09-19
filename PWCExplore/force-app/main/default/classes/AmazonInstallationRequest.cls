/*------------------------------------------------------------------------
Author:        Sai Kumar
Company:       PWC
Description:   Amazon Integration
Inputs:        NA
Test Class:    
History
-04-2024      Sai Kumar     Initial Release
----------------------------------------------------------------------------*/
global class AmazonInstallationRequest{
    
    global static void execute() {
        
        Integer iter = 1;
        Integer divideCount = 10;
        List<string> requestIdList;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://gnb--pwcexplore.sandbox.my.salesforce.com/services/apexrest/crmis-gammacom');
        request.setMethod('GET');       
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization','Bearer 000DC4000000agIT!AQEAQOSHaUqB6TUDS2JsipZ4NBXBNSQdlE_3CH0Y.vqQ.WBJPawhXS1d0Fv8_cVVa9ZwlvOoaOJIPWX2l_DqZ68VGrW2aRXZ');
        HttpResponse response = http.send(request);
        
        if(response.getStatusCode() == 200) {
            
            System.debug(response.getBody());
            string responsebody=response.getBody();
            JSONResponseWrapperIds resp=(JSONResponseWrapperIds)JSON.deserialize(responsebody, JSONResponseWrapperIds.class);
            system.debug('Ids'+resp.ids);
            system.debug('size'+resp.ids.size());
            // Loop through the IDs and process in batches
            While(iter<=resp.ids.size()) {
                if(Math.mod(iter, divideCount) == 1) {
                    requestIdList = new List<string>();
                }
                requestIdList.add(resp.ids[iter-1]);
                if(Math.mod(iter, divideCount) == 0 || iter == resp.ids.size()) {
                    getInstallationRequestData(requestIdList);
                } 
                iter++;
            }  
            
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            
        } 
    }
    // Method to process installation request data asynchronously
    @future(Callout=true)
    global static void getInstallationRequestData(List<string> InstallationRequestId){
        String customURL = '';
        Integer iter = 1;
        //custom URL for request
        for(String idStr : InstallationRequestId) {
            customURL += 'request-ids-' + iter + '=' + idStr + '&';
            iter += 1;
        }
        system.debug('customURL '+customURL);
        String requestCapture;
        String responseCapture;
        list<ContactPointAddress> lstcpa=new list<ContactPointAddress>();
        List<Case> casesToUpsert = new List<Case>();
        List<Account> CustomerInsert = new List<Account>();
        List<string> casenumbercheck = new List<string>();
        List<ContactPointAddress> Check_ContactPointAddress = new List<ContactPointAddress>();
        Map<String, string> CustomerEmailandAddress = new Map<String, string>();
        Map<String, Account> CustomerMap = new Map<String, Account>();
        map<string,request> casenumbermap=new map<string,request>();
        Map<String, Case> existingCasesMap = new Map<String, Case>();
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        
        String JSONDATA =JSON.serialize(InstallationRequestId);            
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization','Bearer 00DC4000000agIT!AQEAQOSHaUqB6TUDS2JsipZ4NBXBNSQdlE_3CH0Y.vqQ.WBJPawhXS1d0Fv8_cVVa9ZwlvOoaOJIPWX2l_DqZ68VGrW2aRXZ');
        req.setEndpoint('https://gnb--pwcexplore.sandbox.my.salesforce.com/services/apexrest/crmis-gamma-twocom?'+customURL);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        responseCapture = res.getBody(); 
        system.debug('responseCapture '+responseCapture);
        system.debug('responseCapture '+res.getStatusCode());
        
        if(res.getStatusCode() == 200){
            JSONResponseWrapper respdata = (JSONResponseWrapper)JSON.deserialize(responseCapture, JSONResponseWrapper.class);
            System.debug('Response: '+respdata);
            
            
            // Process requests
            for (String key : respdata.requests.keySet()) {
                Request request = respdata.requests.get(key);
                system.debug('request.id :'+request.lineItemId);
                casenumbercheck.add(request.crmTicketId);
                casenumbermap.put(request.id,request);
                
            }
            for(String key : respdata.lineItems.keySet()) {
                LineItem lineItem = respdata.lineItems.get(key);
                system.debug('lineItem.customer.email;'+lineItem.customer.email);
                CustomerEmailandAddress.put(lineItem.mailingAddress.address,lineItem.customer.email);
            }
            
            // Check existing customers and ContactpoitAddress
            list<Account> Check_existingCustomer=[SELECT Id, PersonEmail,(select id,name from ContactPointAddresses where name =:CustomerEmailandAddress.KeySet()),name FROM Account WHERE PersonEmail IN :CustomerEmailandAddress.values()];
            system.debug('Check_existingCustomer '+Check_existingCustomer);
            if(!Check_existingCustomer.isEmpty()){
                for (Account existingCustomer :Check_existingCustomer ) {
                    CustomerMap.put(existingCustomer.PersonEmail, existingCustomer);
                    system.debug('existingCustomer.ContactPointAddresses.size()'+existingCustomer.ContactPointAddresses.size());
                    if(existingCustomer.ContactPointAddresses.size()>0){
                        Check_ContactPointAddress.add(existingCustomer.ContactPointAddresses);
                        
                    }
                    
                    
                } 
                
            }
            else{
                // Create new accounts for new customers
                for(String key : respdata.lineItems.keySet()) {
                    LineItem lineItem = respdata.lineItems.get(key);
                    Account ac=new Account();
                    ac.PersonEmail = lineItem.customer.email;
                    ac.PersonMobilePhone =lineItem.customer.phoneNumber;
                    ac.LastName = lineItem.customer.name;
                    ac.RecordTypeId ='0122x000000QDhkAAG';
                    CustomerInsert.add(ac);
                    CustomerMap.put( ac.PersonEmail, ac);
                }
                if(!CustomerInsert.isempty()){
                    insert CustomerInsert;
                    CustomerCreationRESTAPI.CreateCustomeRelatedRecords(CustomerInsert);
                }
                
            }
            system.debug('existingCustomerMap '+CustomerMap);
            
            if(casenumbercheck != null){
                for (Case existingCase : [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :casenumbercheck]) {                 
                    existingCasesMap.put(existingCase.CaseNumber, existingCase);                   
                } 
            }
           system.debug('existingCasesMap '+existingCasesMap);
            
            
            // Process line items
            for (String key : respdata.lineItems.keySet()) {
                LineItem lineItem = respdata.lineItems.get(key);
                
                Case newCase = new Case();
                newCase.Email__c = lineItem.customer.email;
                newCase.Mobile__c =lineItem.customer.phonenumber;
                system.debug('casnumber.get(lineItem.orderId).crmTicketId  '+casenumbermap.get(lineItem.orderId).crmTicketId);                
                String crmTicketId = casenumbermap.get(lineItem.orderId).crmTicketId;
                if (String.isNotBlank(crmTicketId) && existingCasesMap.containsKey(crmTicketId)) {
                    
                    Case existingCase = existingCasesMap.get(crmTicketId);
                    system.debug('existingCase.Id '+existingCase.Id);
                    if (existingCase != null && existingCase.Id != null) {
                        newCase.Id = existingCase.Id;
                        newCase.Status=casenumbermap.get(lineItem.orderId).status;
                        system.debug('existingCase.Id160 '+existingCase.Id);
                    }
                    else{
                        newCase.Status='New';  
                    }
                }
                system.debug('CustomerMap.get(lineItem.customer.email).name '+CustomerMap.get(lineItem.customer.email).name);
                if (String.isNotBlank(CustomerMap.get(lineItem.customer.email).id)) {
                    newCase.AccountId = CustomerMap.get(lineItem.customer.email).id;
                    if(Check_ContactPointAddress.size()==0){
                        ContactPointAddress cpa =new ContactPointAddress();
                        cpa.ParentId =CustomerMap.get(lineItem.customer.email).id;
                        cpa.Name= lineItem.mailingAddress.address;//CustomerMap.get(lineItem.customer.email).name;
                        cpa.PostalCode = lineItem.mailingAddress.postalCode;
                        cpa.City = lineItem.mailingAddress.city;
                        lstcpa.add(cpa); 
                    }
                    
                }
                newCase.Service_Request_Type__c = 'Install and Demo';
                newCase.Product_Category__c = lineItem.item.category;
                newCase.Amazon_Id__c =casenumbermap.get(lineItem.orderId).lineItemId;
                newCase.Amazon_Order_Id__c =lineItem.orderId;
                newCase.Service_Required_For__c='testABCEFG81258'; 
                newCase.Product_Name__c =lineItem.item.title;
                newCase.Agency__c=lineItem.item.brand;
                newCase.RecordTypeId = '0122x000000hZXYAA2';
                newCase.Model_Number_of_the_product__c =lineItem.item.modelNumber;
                casesToUpsert.add(newCase);
                
            }
            
            // Process failed request IDs
            for (FailedRequestId failedRequestId : respdata.failedRequestIds) {
                // Process each failed request ID as needed
            }
            if (lstcpa.size()>0) {
                insert lstcpa;
            }
            
            if (!casesToUpsert.isEmpty()) {
                upsert casesToUpsert;                
            }
        }
        
    }
    
    global  class JSONResponseWrapper {
        global Map<String, Request> requests;
        global Map<String, LineItem> lineItems;
        global List<FailedRequestId> failedRequestIds;
    }
    global  class Request {
        global  String id;
        global  string lineItemId;
        global  String status;
        global  string crmTicketId;
    }
    global  class LineItem {
        global  String orderId;
        global  integer estimatedDeliveryDate;
        global  item item;
        global  customer customer;
        global  mailingAddress mailingAddress;
    } 
    global  class FailedRequestId {
        global  String errorMsg;
        global  string failedId;
        global  String recoverable;
    } 
    global  class item {
        global  String title;
        global  string modelNumber;
        global  String brand;
        global  string category;
    }	
    global  class customer {
        global  String name;
        global  string phoneNumber;
        global  String email;
        
    }
    global  class mailingAddress {
        global  String address;
        global  string postalCode;
        global  String city;
    } 
    
    global  class JSONResponseWrapperIds {
        global  list<string> ids;
    }
    
    
}