@RestResource(urlMapping='/servicerequestrestbulk/*')
global class AccountServiceReqAssetWoWoliInbound {
    
    @HttpPost
    global static void doPostServiceReq() {
        
        string response;
        boolean status;
        RestResponse res = RestContext.response;
        
        ResponseWrapper customResponse = new ResponseWrapper();
        customResponse.SuccessRecords = new List<ResponseData>();
        customResponse.FaildRecords = new List<ResponseData>();
        customResponse.success = true;
        
        Map<Decimal, ServiceRequestWrapper> mapBPCodeServiceReqWrapp = new Map<Decimal, ServiceRequestWrapper>();
        Map<String, ServiceRequestWrapper> mapAddCodeServiceReqWrapp = new Map<String, ServiceRequestWrapper>();
        Map<String, Id> mapItemCodeProduct2Id = new Map<String, Id>();
        Map<String, Asset> mapAllItemCodeAsset = new Map<String, Asset>();
        
        Set<Decimal> setValidBPCodes = new Set<Decimal>();
        Set<String> setValidAddressCodes = new Set<String>();
        Set<String> setAssetItemCodes = new Set<String>();
        
        //lists to insert
        List<Case> lstCaseToInsert = new List<Case>();
        List<Asset> lstAssetsToInsert = new List<Asset>();
        
        
        // try {
        
        string jsonReq = RestContext.request.requestBody.toString();
        
        list<AccountServiceReqItemsWrapper> lstWrapper = (list<AccountServiceReqItemsWrapper>) JSON.deserialize(jsonReq,list<AccountServiceReqItemsWrapper>.class);
        
        for(AccountServiceReqItemsWrapper requestWrapper : lstWrapper) {
            
            CustomerDetailsWrapper customerDetails = requestWrapper.CustomerDetails;
            ServiceRequestWrapper serviceRequest = requestWrapper.ServiceRequest;   
            
            if (customerDetails.BPCode != null && customerDetails.BPCode != ''){
                mapBPCodeServiceReqWrapp.put(Decimal.valueOf(customerDetails.BPCode), serviceRequest);
            } else if (customerDetails.AddressCode != null && customerDetails.AddressCode != null) {
                mapAddCodeServiceReqWrapp.put(customerDetails.AddressCode, serviceRequest);
            }
            
            for(AssetsWrapper eachAsset : serviceRequest.Items) {
                if (String.isNotBlank(eachAsset.ItemCode)){
                    setAssetItemCodes.add(eachAsset.ItemCode);
                }
            }
        }        	
        
        List<Account> lstBpCodeAccounts = [SELECT id, name, BP_Code__c,  Sub_Division__c from Account WHERE BP_Code__c IN : mapBPCodeServiceReqWrapp.KeySet()];
        List<ContactPointAddress> lstContactPointAdd = [SELECT id, Name, Parent.Id, Parent.Name, Address, Address_Code__c FROM ContactPointAddress WHERE Address_Code__c IN : mapAddCodeServiceReqWrapp.KeySet()];
        List<Product2> lstProduct2Records = [ SELECT id, Item_Code__c from Product2 where Item_Code__c IN : setAssetItemCodes ];
        
        for(Product2 eachProduct2 : lstProduct2Records) {
            mapItemCodeProduct2Id.put(eachProduct2.Item_Code__c, eachProduct2.Id);
        }
        
        
        for(Account eachAcc : lstBpCodeAccounts ){
            
            system.debug('Account by BPCode '+eachAcc);
            
            setValidBPCodes.add(eachAcc.BP_Code__c);
            ServiceRequestWrapper caseAssestWrapper = mapBPCodeServiceReqWrapp.get(eachAcc.BP_Code__c);
            
            lstCaseToInsert.add(getCaseObject(caseAssestWrapper, eachAcc.Id));   
            
            if(!caseAssestWrapper.Items.isEmpty()) {
                lstAssetsToInsert.addAll(getMappedAssetRecords(caseAssestWrapper.Items, eachAcc.Id, mapItemCodeProduct2Id));
            }
        }
        
        
        for(Decimal eachBPCode : mapBPCodeServiceReqWrapp.KeySet()) {
            
            ResponseData recordData = new ResponseData();
            recordData.BPCode = eachBPCode;
            if(setValidBPCodes.contains(eachBPCode)) {
                recordData.success = true;
                customResponse.SuccessRecords.add(recordData);                
            } else {
                recordData.success = false; 
                customResponse.FaildRecords.add(recordData);
            }
        }
        
        for(ContactPointAddress eachConPointAdd : lstContactPointAdd) {
            
            system.debug('Parent Acc of ContactPointAddress '+eachConPointAdd);
            
            setValidAddressCodes.add(eachConPointAdd.Address_Code__c);
            ServiceRequestWrapper caseAssestWrapper = mapAddCodeServiceReqWrapp.get(eachConPointAdd.Address_Code__c);
            lstCaseToInsert.add(getCaseObject(caseAssestWrapper, eachConPointAdd.Parent.Id));  
            
            if(!caseAssestWrapper.Items.isEmpty()) {
                lstAssetsToInsert.addAll(getMappedAssetRecords(caseAssestWrapper.Items, eachConPointAdd.Parent.Id, mapItemCodeProduct2Id));
            }
        }
        
        Map<String, Case> caseMap = new Map<String, Case>();        
        for(String eachAddressCode : mapAddCodeServiceReqWrapp.KeySet()) {
            
            ResponseData recordData = new ResponseData();
            recordData.AddressCode = eachAddressCode;
            if(setValidAddressCodes.contains(eachAddressCode)) {
                recordData.success = true;
                customResponse.SuccessRecords.add(recordData);
            } else {
                recordData.success = false; 
                customResponse.FaildRecords.add(recordData);
            }
        }       
        
        if(!lstCaseToInsert.isEmpty()) {
            
            INSERT lstCaseToInsert;
            //for(Case each: lstCaseToInsert){
            //caseMap.put(each.Asset_Details__c, each);                
            //}
            //getMappedCaseAssetRecords(caseAssestWrapper.Items, lstCaseToInsert, mapItemCodeProduct2Id)
        }
        
        if(!lstAssetsToInsert.isEmpty()) {
            INSERT lstAssetsToInsert;
        }
        
        for(Asset eachAsset : lstAssetsToInsert) {
            mapAllItemCodeAsset.put(eachAsset.Product_Code__c, eachAsset);
        }
        
        List<WorkOrder> workOrderToInsert = new List<WorkOrder>();
        
        for(Case each: lstCaseToInsert){
            WorkOrder wo = new WorkOrder();
            wo.CaseId = each.Id;
            wo.Account = each.account;
            wo.Business_Unit__c = 'Interio';
            wo.Subject = each.Subject;
            wo.Description = each.Description;
            wo.AssetDetails__c = each.AssetDetails__c;
            
            workOrderToInsert.add(wo);
        }
        
        if(!workOrderToInsert.isEmpty()) {
            insert workOrderToInsert;
        }   
        
        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        
        for(WorkOrder wo : workOrderToInsert) {
            
            List<String> itemCodesArr = wo.AssetDetails__c.split('-');
            
            Asset assetRec = new Asset();
            
            for(String eachItemCode : itemCodesArr){
                assetRec = mapAllItemCodeAsset.get(eachItemCode);
                WorkOrderLineItem woli = new WorkOrderLineItem();
                woli.WorkOrderId = wo.Id;
                woli.AssetId = assetRec.Id;            
                woliToInsert.add(woli);        
            }
        }
        
        if(!woliToInsert.isEmpty()) {
            system.debug('woliToInsert '+woliToInsert);
            INSERT woliToInsert;
        }
        
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
        //res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'true', 'message'=>' Service request and related assets created successfully !'}));            
        res.responseBody = Blob.valueOf(JSON.Serialize(customResponse));            
        /*   }

catch(Exception e) {

system.debug('e '+e.getLineNumber());

res.statusCode = 500;
res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'false', 'message'=>e.getMessage()}));        
}*/    
        
    }
    
    
    public static Case getCaseObject(ServiceRequestWrapper serviceReq, Id AccountId) {
        
        Case newCase = new Case();
        newCase.Subject = String.isNotBlank(serviceReq.Subject) ? serviceReq.Subject : '';
        newCase.AccountId = AccountId;
        newCase.RecordTypeId = '012C4000000Zsn7IAC';
        newCase.Service_Request_Type__c = String.isNotBlank(serviceReq.ServiceReqType) ? serviceReq.ServiceReqType : '';
        newCase.Service_Required_For__c = String.isNotBlank(serviceReq.ServiceReqFor) ? serviceReq.ServiceReqFor : '';
        
        String assetDetails;
        for(AssetsWrapper eachAsset : serviceReq.Items){
            if(assetDetails == null) {
                assetDetails = eachAsset.ItemCode;
            } else {
                assetDetails += '-'+eachAsset.ItemCode;
            }
        }
        newCase.AssetDetails__c = assetDetails;
        
        return newCase;
    }
    
    
    public static List<Asset> getMappedAssetRecords(List<AssetsWrapper> assetsWrapper, Id AccounId, Map<String, Id> mapItemCodeProduct2Id) {
        
        List<Asset> relatedAssets = new List<Asset>();
        
        for(AssetsWrapper eachAssetWrap : assetsWrapper) {
            
            Asset newAsset = new Asset();
            newAsset.AccountId = AccounId;
            newAsset.RecordTypeId = '012C4000000ZgNlIAK';
            newAsset.Product_Code__c = String.isNotBlank(eachAssetWrap.ItemCode) ? eachAssetWrap.ItemCode : '';
            newAsset.Product2Id = mapItemCodeProduct2Id.get(eachAssetWrap.ItemCode);
            newAsset.Name = String.isNotBlank(eachAssetWrap.Name) ? eachAssetWrap.Name : '';
            newAsset.Area_Code__c = String.isNotBlank(eachAssetWrap.AreaCode) ? eachAssetWrap.AreaCode : '';
            newAsset.Quantity = Decimal.valueOf(eachAssetWrap.ItemQuantity);
            relatedAssets.add(newAsset);
        }
        
        return relatedAssets;
    }
    
    /*public static List<Asset> getMappedCaseAssetRecords(List<AssetsWrapper> caseAssetsWrapper,List<Case> caseList, Map<String, Id> mapItemCodeProduct2Id) {
System.debug('caseAssetsWrapper ->'+caseAssetsWrapper);
for(Case each : caseList){
List<String> assectDetails = each.AssetDetails__c.split('-');
}
return null;
}*/
    
    
    
    
    public class AccountServiceReqItemsWrapper {
        public CustomerDetailsWrapper CustomerDetails;
        public ServiceRequestWrapper ServiceRequest;
    }
    
    public class CustomerDetailsWrapper {
        public string CustomerType;
        public string SubDivision;
        public string BPCode;
        public string AddressCode;
        public string Salutation;
        public string FirstName;
        public string LastName;
        public string PersonMobilePhone;
        public string PersonEmail;
        public string Adhaar;   
    }
    
    public class ServiceRequestWrapper {
        public string RecordType;
        public string ServiceReqType;
        public string ServiceReqFor;
        public string Subject;
        public List<AssetsWrapper> Items;
    }
    
    public class AssetsWrapper {
        public string ItemCode;
        public string Name;
        public string AreaCode;
        public integer ItemQuantity;
        public String relatedItemCodes;
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
    
}