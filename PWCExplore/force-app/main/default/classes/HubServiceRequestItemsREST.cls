@RestResource(urlMapping='/servicerequestcreation/*')
global class HubServiceRequestItemsREST {
    
    @HttpPost
    global static void doPostServiceReq() {
        
        string response = '';
        boolean status = false;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        Map<String, Id> mapItemCodeProduct2Id = new Map<String, Id>();
        Set<String> setAssetItemCodes = new Set<String>();
        List<Asset> lstAssetsToInsert = new List<Asset>();
        String invalidInput = '';
        String invalidInputData = '';
        //updated payload vars
        Id parentAccountId;
       // Account personAccount = new Account();
        Boolean isCreatedPersonAcc = false;
        
        //27-05-2024
        Set<Decimal> setBPCodes = new Set<Decimal>();
        Set<String> setAddressCodes = new Set<String>();
        
        Map<String, Id> mapBPCodeAcc = new Map<String, Id>();
        Map<String, Id> mapValidAddCodeAcc = new Map<String, Id>();
        
        Map<String, AccountServiceReqItemsWrapper> mapAddCodeWrapper = new Map<String, AccountServiceReqItemsWrapper>();
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            string jsonReq = RestContext.request.requestBody.toString();
            List<AccountServiceReqItemsWrapper> payloadWrapperList = (List<AccountServiceReqItemsWrapper>)JSON.deserialize(jsonReq,List<AccountServiceReqItemsWrapper>.class);
            
            for(AccountServiceReqItemsWrapper eachWrapper : payloadWrapperList) {                
                if(eachWrapper.CustomerType != null) {
                    if(eachWrapper.CustomerType.containsIgnoreCase('B2B')){
                        setBPCodes.add(Decimal.valueOf(eachWrapper.BPCode));
                    }else if(eachWrapper.CustomerType.containsIgnoreCase('B2C')){
                        setAddressCodes.add(eachWrapper.AddressCode);
                        mapAddCodeWrapper.put(eachWrapper.AddressCode, eachWrapper);
                    }
                }
            }
            
            List<Account> lstAccount = [ SELECT Id, Name, BP_Code__c FROM Account WHERE BP_Code__c IN : setBPCodes ];
            List<ContactPointAddress> lstCPA = [ SELECT Id, Address_Code__c FROM ContactPointAddress WHERE Address_Code__c IN : setAddressCodes ];
            
            for(Account eachAcc : lstAccount) {
                mapBPCodeAcc.put(String.valueOf(eachAcc.BP_Code__c), eachAcc.Id);
            }
            
            for(ContactPointAddress eachCPA : lstCPA) {
                mapValidAddCodeAcc.put(String.valueOf(eachCPA.Address_Code__c), eachCPA.ParentId);
            }
            
            List<Account> lstAccountsToInsert = new List<Account>();
            Map<String, Account> mapAddressCodePersonAcc = new Map<String, Account>();
            
            for(AccountServiceReqItemsWrapper eachWrapper : mapAddCodeWrapper.values()) {
                if(!mapValidAddCodeAcc.KeySet().contains(eachWrapper.AddressCode)) {
                    Account personAccount = new Account();
                    personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                    personAccount.Salutation = String.isNotBlank(eachWrapper.Salutation) ? eachWrapper.Salutation : ''; 
                    personAccount.FirstName = String.isNotBlank(eachWrapper.FirstName) ? eachWrapper.FirstName : '';
                    personAccount.LastName = String.isNotBlank(eachWrapper.LastName) ? eachWrapper.LastName : ''; 
                    personAccount.Phone = String.isNotBlank(eachWrapper.PersonMobilePhone) ? eachWrapper.PersonMobilePhone : ''; 
                    personAccount.PersonEmail = String.isNotBlank(eachWrapper.PersonEmail) ? eachWrapper.PersonEmail : '';
                    
                    mapAddressCodePersonAcc.put(eachWrapper.AddressCode, personAccount);
                }
            }        
            
            if(!mapAddressCodePersonAcc.values().isEmpty()) {
                INSERT mapAddressCodePersonAcc.values();
            }
                        
            List<ContactPointAddress> lstNewCPA = new List<ContactPointAddress>();
            for(String eachAddCode : mapAddressCodePersonAcc.KeySet()) {
                
                //Account accData = mapAddressCodePersonAcc.get(eachAddCode);
                AccountServiceReqItemsWrapper payloadWrapper = mapAddCodeWrapper.get(eachAddCode);
                ContactPointAddress contPointAdd = new ContactPointAddress();
                contPointAdd.Name = mapAddressCodePersonAcc.get(eachAddCode).Name + '-Add';
                contPointAdd.ParentId = mapAddressCodePersonAcc.get(eachAddCode).Id;
                contPointAdd.Address_Code__c = eachAddCode;
                contPointAdd.Street = String.isNotBlank(payloadWrapper.AddressLine1) ? payloadWrapper.AddressLine1 : '';
                contPointAdd.City = String.isNotBlank(payloadWrapper.AddressLine2) ? payloadWrapper.AddressLine2 : '';
                contPointAdd.Country = String.isNotBlank(payloadWrapper.AddressLine3) ? payloadWrapper.AddressLine3 : '';
                contPointAdd.PostalCode = String.isNotBlank(payloadWrapper.PinCode) ? payloadWrapper.PinCode : '';                    
                
                lstNewCPA.add(contPointAdd);
            }
            
            if(!lstNewCPA.isEmpty()) {
                INSERT lstNewCPA;
                
                for(ContactPointAddress eachCPA : lstNewCPA) {
                    mapValidAddCodeAcc.put(eachCPA.Address_Code__c, eachCPA.ParentId);
                }
            }
            
            List<Case> lstCaseToInsert = new List<Case>();
             
            for(AccountServiceReqItemsWrapper eachWrapper : payloadWrapperList) {
                
                if(eachWrapper.CustomerType != null) {
                    Case newCase = new Case();

                    if(eachWrapper.CustomerType.containsIgnoreCase('B2B')) newCase.AccountId = mapBPCodeAcc.get(eachWrapper.BPCode);
                    if(eachWrapper.CustomerType.containsIgnoreCase('B2C')) newCase.AccountId = mapValidAddCodeAcc.get(eachWrapper.AddressCode);
                    
                    newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interio Service Request').getRecordTypeId(); //'012C4000000Zsn7IAC';
                    //newCase.Service_Request_Type__c = String.isNotBlank(eachWrapper.ServiceReqType) ? eachWrapper.ServiceReqType : '';
                    //newCase.Service_Required_For__c = String.isNotBlank(eachWrapper.ServiceReqFor) ? eachWrapper.ServiceReqFor : '';
                    //newCase.Origin = String.isNotBlank(eachWrapper.ChannelCode) ? eachWrapper.ChannelCode : '';
                    newCase.Business_Unit_cc__c = (newCase.Origin == 'Appliance') ? 'H' : (newCase.Origin == 'Interio') ? 'W' : '';
                    
                    if(newCase.AccountId != null) lstCaseToInsert.add(newCase);
                }                    
            }            
            
            if(!lstCaseToInsert.isEmpty()) INSERT lstCaseToInsert;
            
            /*if(payloadWrapper.CustomerType.containsIgnoreCase('B2B')){
                
                System.debug('AT ---> B2B Customer');
                
                if(payloadWrapper.BPCode != null && String.isNotBlank(payloadWrapper.BPCode)) {
                    Decimal accBPCode = Decimal.valueOf(payloadWrapper.BPCode);
                    List<Account> lstParAccount = [ SELECT id, name, BP_Code__c,  Sub_Division__c from Account WHERE BP_Code__c =: accBPCode LIMIT 1 ];
                    if (!lstParAccount.isEmpty()) {
                        parentAccountId = lstParAccount[0].Id;
                    } else {
                        invalidInput = 'BPCode';
                        invalidInputData = payloadWrapper.BPCode;
                    }
                }
                
            }else if(payloadWrapper.CustomerType.containsIgnoreCase('B2C')){
                
                System.debug('AT ---> B2C Customer');
                
                if(payloadWrapper.AddressCode != null && String.isNotBlank(payloadWrapper.AddressCode)){
                    
                    List<ContactPointAddress> cptList = [ SELECT id, Name, Parent.Id, Parent.Name, Address, Address_Code__c FROM ContactPointAddress WHERE Address_Code__c =: payloadWrapper.AddressCode LIMIT 1 ];
                    if(!cptList.isEmpty() && cptList[0].ParentId != null) {
                        parentAccountId = cptList[0].ParentId;
                    }
                    //else {
                    //invalidInput = 'AddressCode';
                    //invalidInputData = payloadWrapper.AddressCode;
                    //}
                }
                
                if(parentAccountId == null) {
                    
                    personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                    personAccount.Salutation = String.isNotBlank(payloadWrapper.Salutation) ? payloadWrapper.Salutation : ''; 
                    personAccount.FirstName = String.isNotBlank(payloadWrapper.FirstName) ? payloadWrapper.FirstName : '';
                    personAccount.LastName = String.isNotBlank(payloadWrapper.LastName) ? payloadWrapper.LastName : ''; 
                    personAccount.Phone = String.isNotBlank(payloadWrapper.PersonMobilePhone) ? payloadWrapper.PersonMobilePhone : ''; 
                    personAccount.PersonEmail = String.isNotBlank(payloadWrapper.PersonEmail) ? payloadWrapper.PersonEmail : '';
                    
                    INSERT personAccount;
                    isCreatedPersonAcc = true;
                    parentAccountId = personAccount.Id;  
                    
                    try{
                        ContactPointAddress contPointAdd = new ContactPointAddress();
                        contPointAdd.Name = personAccount.Name + '-Add';
                        contPointAdd.ParentId = parentAccountId;
                        contPointAdd.Address_Code__c = String.isNotBlank(payloadWrapper.AddressCode)? payloadWrapper.AddressCode : '';
                        contPointAdd.Street = String.isNotBlank(payloadWrapper.AddressLine1)? payloadWrapper.AddressLine1 : '';
                        contPointAdd.City = String.isNotBlank(payloadWrapper.AddressLine2)? payloadWrapper.AddressLine2 : '';
                        contPointAdd.Country = String.isNotBlank(payloadWrapper.AddressLine3)? payloadWrapper.AddressLine3 : '';
                        contPointAdd.PostalCode = String.isNotBlank(payloadWrapper.PinCode) ? payloadWrapper.PinCode : '';
                        
                        
                        INSERT contPointAdd;
                    }catch(Exception e){
                        
						Database.rollback(sp);
                        res.statusCode = 400;
                        res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'cannot create contact point address')));
                                                    
                    }
                    
                    
                }                
            }*/
            
            
            if(parentAccountId != null) {
                
             /*   for(AssetsWrapper eachAsset : payloadWrapper.serviceRequest.Items) {
                    if (String.isNotBlank(eachAsset.ItemCode)){
                        setAssetItemCodes.add(eachAsset.ItemCode);
                    }
                }    */    
                
                List<Product2> lstProduct2Records = [ SELECT id, Item_Code__c from Product2 where Item_Code__c IN : setAssetItemCodes ];
                
                if(lstProduct2Records.size() == setAssetItemCodes.size()){
                    
                    for(Product2 eachProduct2 : lstProduct2Records) {
                        mapItemCodeProduct2Id.put(eachProduct2.Item_Code__c, eachProduct2.Id);
                    }
                    
                    Case newCase = new Case();
             /*       if(payloadWrapper.ServiceRequest != null){
                        
                        ServiceRequestWrapper serviceReq = payloadWrapper.ServiceRequest;
                        
                        newCase.AccountId = parentAccountId;
                        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interio Service Request').getRecordTypeId(); //'012C4000000Zsn7IAC';
                        newCase.Service_Request_Type__c = String.isNotBlank(serviceReq.ServiceReqType) ? serviceReq.ServiceReqType : '';
                        newCase.Service_Required_For__c = String.isNotBlank(serviceReq.ServiceReqFor) ? serviceReq.ServiceReqFor : '';
                        newCase.Origin = String.isNotBlank(serviceReq.ChannelCode) ? serviceReq.ChannelCode : '';
                        newCase.Business_Unit_cc__c = (newCase.Origin == 'Appliance') ? 'H' : (newCase.Origin == 'Interio') ? 'W' : '';
                    }
                    */
                    system.debug('newCase '+newCase);
                    try{
                        INSERT newCase;
                    }catch(Exception e){
                        Database.rollback(sp);
                        res.statusCode = 400;
                        res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'failed to create service request')));
                    }
                    
                    if(newCase.Id != null) {
                        
                    /*    if(payloadWrapper.ServiceRequest.Items.size() > 0) {
                            for(AssetsWrapper eachAssetWrap : payloadWrapper.ServiceRequest.Items) {
                                
                                Asset newAsset = new Asset();
                                newAsset.AccountId = parentAccountId;
                                newAsset.Service_Request_del_del__c = newCase.Id;
                                newAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Interio').getRecordTypeId(); // '012C4000000ZgNlIAK';
                                newAsset.Product_Code__c = String.isNotBlank(eachAssetWrap.ItemCode) ? eachAssetWrap.ItemCode : '';
                                newAsset.Product2Id = mapItemCodeProduct2Id.get(eachAssetWrap.ItemCode);
                                newAsset.Name = String.isNotBlank(eachAssetWrap.ItemCode) ? eachAssetWrap.ItemCode : '';
                                newAsset.Area_Code__c = String.isNotBlank(eachAssetWrap.AreaCode) ? eachAssetWrap.AreaCode : '';
                                newAsset.Quantity = Decimal.valueOf(eachAssetWrap.ItemQuantity);
                                newAsset.Rental_Agreement_Start_Date__c = String.isNotBlank(eachAssetWrap.RentalAggStartDate) ? Date.parse(eachAssetWrap.RentalAggStartDate) : null;
                                newAsset.Rental_Agreement_End_Date__c = String.isNotBlank(eachAssetWrap.RentalAggEndDate) ? Date.parse(eachAssetWrap.RentalAggEndDate) : null;
                                lstAssetsToInsert.add(newAsset);
                            }            
                        }*/
                        
                        if(!lstAssetsToInsert.isEmpty()){
                            try{
                                INSERT lstAssetsToInsert;
                            }catch(Exception e){
                                Database.rollback(sp);
                                res.statusCode = 400;
                                res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'failed to create assets')));
                            }
                            
                            
                            WorkOrder wo = new WorkOrder();
                            If(newCase.Id != null){
                                wo.CaseId = newCase.Id;
                                wo.AccountId = parentAccountId;
                                wo.Business_Unit__c = 'Interio';
                                wo.Subject = newCase.Subject;
                                wo.Description = newCase.Description;
                                INSERT wo;       
                            }
                            
                            //system.debug('wo '+wo);
                            
                            List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
                            
                            if(lstAssetsToInsert.size() > 0){
                                for(Asset eachAsset : lstAssetsToInsert){
                                    WorkOrderLineItem woli = new WorkOrderLineItem();
                                    woli.WorkOrderId = wo.Id;
                                    woli.AssetId = eachAsset.Id;            
                                    woliToInsert.add(woli);        
                                }
                            }
                            
                            if(!woliToInsert.isEmpty()) {
                                INSERT woliToInsert;
                            }
                            
                            // Commit the transaction for the current account
                            //Database.commit();
                            
                            res.statusCode = 200;
                            if(isCreatedPersonAcc) {

                                RequestResponse responseObject = new RequestResponse(newCase.Id, true, 'Successfully created service request with person account');
                                Map<String, Object> responseMap = new Map<String, Object>();
                                responseMap.put('servicerequestid', responseObject.servicerequestid);
                                responseMap.put('success', responseObject.success);
                                responseMap.put('message', responseObject.message);  
                                Map<String, Object> accountDetailsMap = new Map<String, Object>();
              /*                  accountDetailsMap.put('AccountId', personAccount.Id);
                                accountDetailsMap.put('LastName', personAccount.LastName);
                                if(personAccount.Salutation != null) accountDetailsMap.put('Salutation', personAccount.Salutation);
                                if(personAccount.FirstName != null) accountDetailsMap.put('FirstName', personAccount.FirstName);
                                if(personAccount.PersonMobilePhone != null) accountDetailsMap.put('PersonMobilePhone', personAccount.PersonMobilePhone);
                                if(personAccount.PersonEmail != null) accountDetailsMap.put('PersonEmail', personAccount.PersonEmail);*/
                                responseMap.put('AccountDetails', accountDetailsMap);
                                
                                res.responseBody = Blob.valueOf(JSON.Serialize(responseMap));
                            } else {
                                res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(newCase.Id, true, 'Succesfully created service request')));
                            }                            
                        }
                        
                    }else{
                        Database.rollback(sp);
                        res.statusCode = 400;
                        res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'item code doesnot exist')));
                    }
                    
                } else {
                    Database.rollback(sp);
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'item code doesnot exist')));                        
                }
            } else {
                Database.rollback(sp);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'Customer does not exist with '+invalidInput+' '+invalidInputData)));             
            }   
        } catch(Exception e) {
            // Rollback to the Savepoint if an exception occurs for the current account
            Database.rollback(sp);
            res.statusCode = 500;
            system.debug('e line no '+e.getLineNumber());
            system.debug('e line type '+e.getTypeName());
            system.debug('e line no '+e.getMessage());
            res.responseBody = Blob.valueOf(JSON.Serialize(new RequestResponse(null, false, 'No Records created, Transaction Rolled Back')));        
        }
    }
    
    
    public class AccountServiceReqItemsWrapper {
        public string CustomerType;
        public string BPCode;
        public string AddressCode;
        public string Salutation;
        public string FirstName;
        public string LastName;
        public string PersonMobilePhone;
        public string PersonEmail;
        public string AddressLine1;
        public string AddressLine2;
        public string AddressLine3;
        public string AddressLine4;
        public string PinCode;
        //   public string Adhaar;
        public ServiceRequestWrapper ServiceRequest;
    }
    
    public class ServiceRequestWrapper {
        public string ChannelCode;
        public string ServiceReqFor;        
        public string ServiceReqType;
        public List<AssetsWrapper> Items;
    }
    
    public class AssetsWrapper {
        public string ItemCode;
        public string AreaCode;
        public integer ItemQuantity;
        public string RentalAggStartDate;
        public string RentalAggEndDate;
    }
    
    public class ResponseWrapper {
        public boolean success;
        public List<ResponseData> SuccessRecords;
        public List<ResponseData> FaildRecords;
    }
    
    public class ResponseData{
        public boolean success;
        public Decimal BPCode;
        public string AddressCode;
    }
    
    public class RequestResponse {
        public string servicerequestid;
        public boolean success;
        public String message;
        public RequestResponse(String id, boolean success, String message) {
            this.servicerequestid = id;
            this.success = success;
            this.message = message;
        }
    }
    
}