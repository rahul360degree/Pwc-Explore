/*------------------------------------------------------------------------
Author:        Sai Kumar
Company:       PWC
Description:   Class for Service Request REST API
Inputs:        NA
Test Class:    
History
08-04-2024      Sai Kumar     Initial Release
----------------------------------------------------------------------------*/
@RestResource(urlMapping='/ServiceRequestRest/*')
global class ServiceRequestRestAPI {
    @HttpPost
    global static void doPost(){
        string response;
        boolean status;
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        list<case> lstservice =new list<case>();
        
        list<string> Adhaar=new list<string>();
        list<ResponseWrapper> responslist=new  list<ResponseWrapper>();
        ResponseWrapper resp=new ResponseWrapper();
        
        map<string,contact> oldcontactmap = new map<string,contact>();
        //map<string,contact> newcontactmap = new map<string,contact>();
        //list<contact> lstcon =new list<contact>();
        
        map<string,case> ServiceReqId = new map<string,case>();
        list<map<string,case>> responselist=new  list<map<string,case>>();
        try{            
            string jsonReq= RestContext.request.requestBody.toString();
            system.debug('jsonReq'+jsonReq);
            list<RequestJSONWrapper.ServiceRequestWrapper> lstcustomer= (list<RequestJSONWrapper.ServiceRequestWrapper>)JSON.deserialize(jsonReq,list<RequestJSONWrapper.ServiceRequestWrapper>.class);
            for(RequestJSONWrapper.ServiceRequestWrapper data: lstcustomer ){
                Adhaar.add(data.Adhaar);
            }
            
            list<contact> Duplicate_Check=[select id,Aadhaar_Card_Number__c from contact where Aadhaar_Card_Number__c =: Adhaar];
            for(contact co:Duplicate_Check){
                oldcontactmap.put(co.Aadhaar_Card_Number__c,co);
            }
            
            system.debug('oldcontactmap67'+oldcontactmap);
            for(RequestJSONWrapper.ServiceRequestWrapper data: lstcustomer ){
                
                case c=new case();
                c.ContactId =oldcontactmap.get(data.Adhaar).id;
                c.Service_Request_Type__c=data.serviceRequestType;
                c.Status =data.Status;
               // c.Address_by_BP__c='a06C4000008q77FIAQ';
                c.Service_Required_For__c=data.serviceRequiredFor;
                c.Product_Category__c = data.productCategory;
                c.Origin = data.serviceRequestChannel;
                c.RecordTypeId='0122x000000hZXYAA2';
                lstservice.add(c);
                ServiceReqId.put(data.Adhaar,c);
                responselist.add(ServiceReqId);
                
                
            }
            
            
            insert lstservice;
            for(case ca:lstservice){
                response = getResponse(true,'Success: Service Request Booked Successfully',ca.CaseNumber);
                
            }
            
            
            //response= getResponse(true, 'message', 'GUID');
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
            
        }
        catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            //ResponseWrapper resp=new ResponseWrapper();
            response = getResponse(false, e.getMessage(), null);
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(response);
        }
        
    }
    public class ResponseWrapper{
        public boolean status;
        public string message;
        public string serviceRequestNo;
        //public list<case> lstcase;
    }
    public static string getResponse(boolean status, string message, string serviceRequestNo){
        ResponseWrapper reswrapper =new ResponseWrapper();
        reswrapper.status = status;
        reswrapper.message =message;
        reswrapper.serviceRequestNo =serviceRequestNo;
        return JSON.serialize(reswrapper);
    }
    
}