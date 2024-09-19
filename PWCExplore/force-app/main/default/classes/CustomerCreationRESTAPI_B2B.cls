@RestResource(urlMapping='/B2B_Customer/*')
global class CustomerCreationRESTAPI_B2B {
    @HttpPost
    global static void CustomerCreationB2B(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        list<RequestJSONWrapper.ResponseWrapper> listResponse=new list<RequestJSONWrapper.ResponseWrapper>();
        
        String response;
        try {
            String jsonReq = RestContext.request.requestBody.toString();
            List<RequestJSONWrapper.B2BCustomerRequestBody> lstcustomer = (List<RequestJSONWrapper.B2BCustomerRequestBody>)JSON.deserialize(jsonReq, List<RequestJSONWrapper.B2BCustomerRequestBody>.class);
            Set<String> panSet = new Set<String>();
            
            list<string> addresslist=new list<string>();
            Map<String, Address__c> AccountsAddressMap = new Map<String, Address__c>();
            
            for(RequestJSONWrapper.B2BCustomerRequestBody request : lstcustomer){
                panSet.add(request.PAN);
                addresslist.add(request.PrimaryAddress);
            }
            
            Map<String, Account> existingAccountsMap = new Map<String, Account>();
            for(Account acc : [SELECT PAN__c, Business_Unit__c, Account_Code__c FROM Account WHERE PAN__c IN :panSet]){
                existingAccountsMap.put(acc.PAN__c, acc);
            }
            
            list<Address__c>  addressBP =[select id,Address_Code__c from Address__c where Address_Code__c =:addresslist];
            system.debug('addressBP'+addressBP);
            if(!addressBP.isempty()){
                for(Address__c address: addressBP){
                    AccountsAddressMap.put(address.Address_Code__c,address);
                    
                }
            }
            
            List<Account> lstaccInsert = new List<Account>();
            for(RequestJSONWrapper.B2BCustomerRequestBody request : lstcustomer){
                if(existingAccountsMap.containsKey(request.PAN)){
                    
                    RequestJSONWrapper.ResponseWrapper response1=new RequestJSONWrapper.ResponseWrapper();
                    response1.status=true;
                    response1.message='B2B Customer already available with this PAN: ' + request.PAN;
                    response1.GUID=existingAccountsMap.get(request.PAN).Id;
                    listResponse.add(response1);
                    //response = getResponse(true, 'B2B Customer already available with this PAN: ' + request.PAN, existingAccountsMap.get(request.PAN).Id);
                } 
                Account existing_acc = existingAccountsMap.get(request.PAN);
                if(existing_acc == null) {
                    Account acc = new Account(
                        Name = request.Name,
                        Parent_Account_Code__c = request.ParentAccountCode,
                        Account_Series__c = request.AccountSeries,
                        Account_Code__c = request.AccountCode,
                        Primary_Address__c = AccountsAddressMap.get(request.PrimaryAddress).id,
                        Language__c = request.Language,
                        Currency__c = request.CustomerCurrency,
                        PAN__c = request.PAN,
                        CIN__c = request.CIN,
                        Phone = request.Phone,
                        Business_Partner_Status__c = request.BusinessPartnerStatus,
                        Start_Date__c = request.StartDate,
                        Sub_Division__c = request.SubDivision,
                        Business_Unit__c = request.BusinessUnit,
                        RecordTypeId ='0126g000000n8cxAAA'
                    );
                    lstaccInsert.add(acc);
                }
            }
            
            if(!lstaccInsert.isEmpty()){
                insert lstaccInsert;
                for(Account insertedac : lstaccInsert){
                    
                    RequestJSONWrapper.ResponseWrapper response2=new RequestJSONWrapper.ResponseWrapper();
                    
                    response2.status=true;
                    response2.message='B2B Customer Created successfully ';
                    response2.GUID=insertedac.Id;
                    listResponse.add(response2);
                    //response = getResponse(true, 'B2B Customer Created successfully', insertedac.Id);
                }
            }
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
        } catch (Exception e) {
            
            RequestJSONWrapper.ResponseWrapper errorResponse=new RequestJSONWrapper.ResponseWrapper();
            
            errorResponse.status=false;
            errorResponse.message = e.getMessage();
            errorResponse.GUID=null;
            listResponse.add(errorResponse);
            
            response =JSON.serialize(listResponse);
            //response = getResponse(false, e.getMessage(), null);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            system.debug('Error creating account: ' + e.getMessage());
            System.debug('Error '+e.getLineNumber());
        }
    }
    
   /* global class RequestBody {
        public String Name { get; set; }
        public String ParentAccountCode { get; set; }
        public String AccountSeries { get; set; }
        public String AccountCode { get; set; }
        public String PrimaryAddress { get; set; }
        public String Language { get; set; }
        public String CustomerCurrency { get; set; }
        public String PAN { get; set; }
        public String CIN { get; set; }
        public String Phone { get; set; }
        public String BusinessPartnerStatus { get; set; }
        public Date StartDate { get; set; }
        public String SubDivision { get; set; }
        public String BusinessUnit { get; set; }
    }
    
    global class ResponseWrapper{
        public boolean status;
        public string message;
        public String GUID;
    }
    
    global static string getResponse(boolean status, string message, String GUIDs){
ResponseWrapper reswrapper = new ResponseWrapper();
reswrapper.status = status;
reswrapper.message = message;
reswrapper.GUID = GUIDs;
return JSON.serialize(reswrapper);
}*/
}