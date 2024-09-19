/*------------------------------------------------------------------------
Author:        HansRaj Yadav
Company:       PWC
Description:   IVR controller class for Service Request Creation
Inputs:        
Test Class:    

Modification Log :

* Developer             Date               Description
---------------------------------------------------------------------------
* HansRaj Yadav         16-04-2024        Initial Release
* 
----------------------------------------------------------------------------*/
@RestResource(urlMapping='/v1/IVR/CreateServiceRequest')
global class IVR_ServiceRequestRestController {

    @HttpPost
    global static void doPost(){
        RestRequest request = RestContext.request;
        SR_Response resp = new SR_Response();
        
        String jsonReq= RestContext.request.requestBody.toString();
        IVR_RequestWrapper wrapInst = (IVR_RequestWrapper)JSON.deserialize(jsonReq,IVR_RequestWrapper.class);
        
		        
        
		Id applianceRecordType = [SELECT id, Name FROM RecordType WHERE sobjecttype ='Case' and name='Appliance Service Request'].Id;
        System.debug('applianceRecordType '+applianceRecordType);
        
        
        Case srRcrd = new Case(
            RecordTypeId = applianceRecordType != null ? applianceRecordType : null,
           	//ContactId = wrapInst.parentId,
        	AccountId = wrapInst.accountId,
            AssetId = wrapInst.locationID,
            Service_Request_Type__c = wrapInst.serviceRequestType,
            Subject = 'IVR Case created for '+wrapInst.mobileNo
        );
        
        if( wrapInst.customerType != null && wrapInst.customerType == 'B2B' ){
            srRcrd.ContactId = wrapInst.parentId;
        }

        Database.SaveResult saveResults = Database.insert(srRcrd);
        System.debug('srv '+saveResults);

        if( saveResults.isSuccess() ){
            resp.status = true;
            resp.statusRemarks =  'Success: Service Request Booked Successfully';
            resp.serviceRequestNo = saveResults.getId();

        } else {
            List<Database.Error> err = saveResults.getErrors();
            resp.status = false;
            resp.statusRemarks = err[0].getMessage();   
        }
        
        String jsonresponse= JSON.serializePretty(resp);
        RestResponse res = RestContext.response;        
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(jsonresponse);
        //RestContext.response = res;
    }
    
    private static void validateInputFields( IVR_RequestWrapper wrapper ){
        if( true ){
            
        }
        
        Id assetId = wrapper.locationID;
        String sObjName = assetId.getSObjectType().getDescribe().getName();
    }	

    public class SR_Response {
        
        public Boolean status;
        public String statusRemarks;
        public String serviceRequestNo;
    }

    public class IVR_RequestWrapper {
        public String parentId;
        public String customerType;
        public String contactId;
        public String accountId;
        public String documentID;	//320200904171501
        public String mobileNo;	//9415610432
        public String division;	//APP
        public String productCategory;	//AIR CONDITIONER
        public String locationID;	//0129876532 //ContactID
        public String title;	//
        public String customerFirstName;	//
        public String customerLastName;	//
        public String customerAddress1;	//
        public String customerAddress2;	//
        public String customerAddress3;	//
        public String customerAddress4;	//
        public String customerPinCode;	//
        public String customerEmail;	//
        public String alternateNo;	//
        public String serviceRequiredFor;	//IVR
        public String serviceRequestType;	//REPAIR
        public String serviceRequestChannel;	//IVR-RM
    }
}