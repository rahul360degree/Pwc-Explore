@RestResource(urlMapping='/ACCOUNTRESTAPI/*')
global class CustomerCreationRESTAPI {
    @HttpPost
    global static void doPost(){
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        list<ErrorSuccessResponse> listResponse=new list<ErrorSuccessResponse>();
        string response;
        try{
            string jsonReq= RestContext.request.requestBody.toString();
            system.debug('jsonReq'+jsonReq);
            
            // Deserialize the JSON request body into a list of AccountWrapper objects.
            list<B2CCustomerRequestJSONWrapper> lstcustomer= (list<B2CCustomerRequestJSONWrapper>)JSON.deserialize(jsonReq,list<B2CCustomerRequestJSONWrapper>.class);
            
            list<account> lstacc =new list<account>();
            // List<String> GUID = new List<String>();
            Map<String, Account> CustomerMap = new Map<String, Account>();
            Map<String, Account> ExistingCustomerMap = new Map<String, Account>();
            Map<String, string> CustomerEmailandAddress = new Map<String, string>();
            
            Map<String, ContactPointAddress> ContactpointMap = new Map<String, ContactPointAddress>();
            //List<ContactPointAddress> Check_ContactPointAddress = new List<ContactPointAddress>();
            list<ContactPointAddress> lstcpa=new list<ContactPointAddress>();
            
            // Iterate through each AccountWrapper object to create or update Account records.
            for(B2CCustomerRequestJSONWrapper data: lstcustomer) {
                system.debug('email;'+data.Email);
                CustomerEmailandAddress.put(data.address,data.Email);
            }
            
            // Duplicate Check existing customers and ContactpoitAddress
            list<Account> Check_existingCustomer=[SELECT Id, PersonEmail,(select id,name,Address1__c from ContactPointAddresses where Address1__c =:CustomerEmailandAddress.KeySet()),name FROM Account WHERE PersonEmail IN :CustomerEmailandAddress.values()];
            system.debug('Check_existingCustomer '+Check_existingCustomer);
            
            if(!Check_existingCustomer.isEmpty()){
                
                for (Account existingCustomer: Check_existingCustomer ) {
                    
                    // ErrorSuccessResponse response1=GenericResponse('Customer already available in salesforce with an Email: '+existingCustomer.PersonEmail, true,existingCustomer.Id);
                    //listResponse.add(response1);
                    
                    system.debug('existingCustomer.ContactPointAddresses.size() '+existingCustomer.ContactPointAddresses.size());
                    ExistingCustomerMap.put( existingCustomer.PersonEmail, existingCustomer);
                    
                    if(existingCustomer.ContactPointAddresses.size()>0){
                        for(B2CCustomerRequestJSONWrapper data: lstcustomer) {
                            ContactpointMap.put(data.address,existingCustomer.ContactPointAddresses);
                            
                        }
                        
                        
                    }
                    
                    
                } 
                
            }
            system.debug('ExistingCustomerMap :'+ExistingCustomerMap);
            
            for(B2CCustomerRequestJSONWrapper data: lstcustomer ){
                
                system.debug( 'existac'+ExistingCustomerMap.get(data.Email));
                account acc = ExistingCustomerMap.get(data.Email);
                if(acc== null){
                    
                    account a =new account();
                    a.Salutation =data.Salutation;
                    a.FirstName = data.firstname;
                    a.LastName =data.lastname;
                    a.PersonEmail = data.Email;
                    a.Phone =data.phone;
                    a.PersonMobilePhone = data.phone;
                    a.Mobile_Number__c =data.phone;
                    a.Sub_Division__c =data.SubDivision;
                    a.RecordTypeId ='0122x000000QDhkAAG';
                    lstacc.add(a);
                    CustomerMap.put( a.PersonEmail, a);
                    system.debug('a.PersonEmail'+a.PersonEmail);
                    system.debug('CustomerMap'+CustomerMap);
                    
                }
                else{
                    
                    ErrorSuccessResponse response1=GenericResponse('Customer already available in salesforce with an Email: '+data.Email, true,ExistingCustomerMap.get(data.Email).Id);
                    listResponse.add(response1);
                    
                    
                }
                
            }
            
            if(lstacc.size()>0){
               // insert lstacc;
                CreateCustomeRelatedRecords(lstacc);
                for(Account acc : lstacc) {
                    
                    ErrorSuccessResponse response2=GenericResponse('B2C Customer Created successfully With Email: '+acc.PersonEmail, true,acc.Id);
                    listResponse.add(response2);
                }
                
             for(B2CCustomerRequestJSONWrapper data: lstcustomer ){
                 system.debug('data.Email'+data.Email);
                 system.debug('insert acc Id :'+CustomerMap.get(data.Email).id);
                
                ContactPointAddress CPAddress = ContactpointMap.get(data.address);
                system.debug('contactpoint address'+ ContactpointMap.get(data.address));
                if(CPAddress == null){
                    ContactPointAddress cpa =new ContactPointAddress();
                    cpa.ParentId =CustomerMap.get(data.Email).id;
                    cpa.Name= data.name;//CustomerMap.get(lineItem.customer.email).name;
                    cpa.PostalCode = data.postalCode;
                    cpa.City = data.city;
                    cpa.Country =data.country;
                    cpa.State =data.state;
                    // cpa.Address='';
                    cpa.Address1__c =data.address;
                    lstcpa.add(cpa);
                }
                
                
            }
                
            }
            system.debug('lstcpa.size() '+lstcpa.size());

            if(lstcpa.size()>0){
                insert lstcpa;
            }
            
            // Prepare response
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        } catch(Exception e) {
            String errorMessage = 'Error occurred: ' + e.getMessage();
            
            ErrorSuccessResponse ErrorResponse=GenericResponse(e.getMessage(), false,null);
            listResponse.add(ErrorResponse);
            
            System.debug('Error '+e.getLineNumber());
            
            response =JSON.serialize(listResponse);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        }
        
    }
    
    public static void CreateCustomeRelatedRecords(list<account> customerpayload){
        
        list<ContactPointEmail> lstcpm=new list<ContactPointEmail>();
        list<ContactPointPhone> lstcpp=new list<ContactPointPhone>();
        
        for(Account a:customerpayload){
            
            ContactPointEmail cpm =new ContactPointEmail();
            system.debug('adsda'+a.PersonEmail);
            cpm.EmailAddress =a.PersonEmail;
            cpm.ParentId = a.Id;
            lstcpm.add(cpm);
            System.debug('Adding ContactPointEmail: ' + cpm);
            
            ContactPointPhone cpp=new ContactPointPhone();
            cpp.TelephoneNumber =a.phone;
            cpp.ParentId=a.id;
            lstcpp.add(cpp);
            System.debug('Adding ContactPointEmail: ' + cpp);
            
            
        }
        insert lstcpm;
        insert lstcpp;
        
    }
    public class ErrorSuccessResponse{
        public boolean status;
        public string message;
        public string GUID;
        
    }
    public static ErrorSuccessResponse GenericResponse(string message, boolean status,string GUID){
        ErrorSuccessResponse errorResponse=new ErrorSuccessResponse();
        errorResponse.status=status;
        errorResponse.message = message;
        errorResponse.GUID = GUID;
        return errorResponse;
    }
        public class B2CCustomerRequestJSONWrapper {
    public string firstname;
    public string lastname;
    public string Salutation;
    public string address;
    public string Email;
    public string phone;
    public string name;
    public string city;
    public string postalcode;
    public string state;
    public string country;
    public string GUID;
    public string SubDivision;
}
    
    
}