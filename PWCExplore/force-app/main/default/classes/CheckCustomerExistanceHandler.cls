/*------------------------------------------------------------------------
Author:        HansRaj Yadav
Company:       PWC
Description:   Handler class for checking valid customer
Inputs:        NA
Test Class:    

Modification Log :

* Developer             Date               Description
---------------------------------------------------------------------------
* HansRaj Yadav         12-04-2024        Initial Release
* 
----------------------------------------------------------------------------*/
@RestResource(urlMapping='/v1/IVR/CheckCustomerInfo/*')
global with sharing class CheckCustomerExistanceHandler {

    @HttpGet
    global static void getCustomerDetails(){
        System.debug('custmer check');
        Map<String, String> paramMap = RestContext.request.params;
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        //RestResponse resp = new RestResponse();

        String mobileNumber = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1 );
        
        if( mobileNumber != null && mobileNumber != ''){
            paramMap.put('mobileNumber', mobileNumber);
        }

        CheckCustomerExistanceHelper.ResponseWrapper wrapperInst = CheckCustomerExistanceHelper.checkCustomerIsValid(mobileNumber);

        res.addHeader('Content-Type', 'application/json');
        System.debug('text 1'+wrapperInst);
        res.responseBody = Blob.valueOf(JSON.serialize(wrapperInst));
        System.debug('text '+res.responseBody);
        
    }
}