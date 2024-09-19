/*------------------------------------------------------------------------
Author:        HansRaj Yadav
Company:       PWC
Description:   
Inputs:        
Test Class:    

Modification Log :

* Developer             Date               Description
---------------------------------------------------------------------------
* HansRaj Yadav         17-04-2024        Initial Release
* 
----------------------------------------------------------------------------*/


@RestResource(urlMapping='/v1/CallCenter/LeadId')
global class CTI_CallCenterRestControllerCreateTask { //callRecording - class name change...
    @HttpPost
    global static void createTaskFormLead(){
        try {
            RestResponse res = RestContext.response;
            String jsonBody = RestContext.request.requestBody.toString(); // body - agentId, leadId update leadId on agent...
            ResponseWrapper requestBodyWrapper = (ResponseWrapper)JSON.deserialize(jsonBody, ResponseWrapper.class);
            User usr = [SELECT Id, Lead_Id__c FROM User WHERE Id =: requestBodyWrapper.agentId];
            String leadId = requestBodyWrapper.leadId;
            usr.Lead_Id__c = leadId;     
            update usr;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'true', 'message'=>'Success'}));

        } catch (Exception e) {
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.Serialize(new Map<String, String>{'success'=> 'false', 'message'=>e.getMessage()}));
        }      
    }

    public class ResponseWrapper {
        public String agentId;
        public String leadId;
    }
}