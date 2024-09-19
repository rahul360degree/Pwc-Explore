/**
* @description       : 
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 07-08-2022
* @last modified by  : vrajpoot@godrej.com
**/
public class ProductConfig_Callout {
    public String userId;
    private String salCode;
    private String keyString;
    private String IVectorString;
    private Blob key;
    private Blob IVString;
    private String tokenURL;
    public String qliEndPointURL;
    //Constructor to get the metadatavalues
    public  ProductConfig_Callout() {
        User user = [Select Id, Email, Salary_Code__c from User where ID=:userinfo.getUserId()];
        userId = user.email.substringBefore('@');
        salCode = user.Salary_Code__c;
        configHelper();
        key = Blob.valueOf(keyString);
        IVString = Blob.valueOf(IVectorString);
    }
    //config helper to get values from Metadata
    private void configHelper(){
        for(Integration_Configuration__mdt mdt:[Select Id,Key_1__c,Key_2__c,DeveloperName from Integration_Configuration__mdt where DeveloperName IN ('PC_AES_256','PC_Creds','PC_URL')])
        {
            if(mdt.DeveloperName=='PC_AES_256'){
                keyString = mdt.Key_1__c;
                IVectorString = mdt.Key_2__c;
            }else if(mdt.DeveloperName=='PC_URL'){
                tokenURL =  mdt.Key_1__c;
                qliEndPointURL =  mdt.Key_2__c;
            }
        }
    }
    //Get Token
    public String  getsfpcToken(){
        JSONGenerator body = JSON.createGenerator(true);
        body.writeStartObject(); 
        body.writeStringField('userId',userId);
        body.writeStringField('salCode',salCode);
        body.writeEndObject();
        //system.debug('JSON request :'+body);
        blob data = Blob.valueOf(body.getAsString());        
        Blob encrypted = Crypto.encrypt('AES256', key, IVString,data);
        String body2 = EncodingUtil.base64Encode(encrypted);
        //System.debug('body2:: '+body2);
        //tokenURL = 'https://gnbnetdevapp1.godrej.com/ProductConfiguratorAPI/api/SFPCIntegration/GetSFPCToken';
        Generic_HTTPCalloutService obj2 = new Generic_HTTPCalloutService();
        HTTPResponse response = obj2.setEndpointURL(tokenURL)
            .setRequestMethod('POST')           
            .setHeaderParameter('Content-Type','application/json;charset=UTF-8')
            .setRequestBody(body2)
            .formHTTPRequest('String')
            .sendRequest();
        String responseBody= response.getBody();
        if(test.isRunningTest()){
            responseBody = 'p0Q7BwKlyzyd6rkXTCDulA4oZbLLJBPBxOpRUPFSR9ciWc1fUOJuowQs0s+zofU+VojYEJNr8tfLWtr/pVtkwas9LKgN7zD1DjxndiQECsG+yHGckpahV84C7NA+f79Z8xTNd7lgmZtkxCFSGIgnva4YRonuR95o3v1OHWsPFz7NYR/IvmsyxUGbJlAyJBimSEPCnUcVsGXtVpY99o3TUyjnXfdoiTAPLS/qyUvI8l85fhk83zM8cvPJYJPir+ZKcFAC8iMFFmfJVefsqO8tZP3FkJSEqSd9zSCgtLgPIF86V5yeolLFwby4HG78YDFzMZR4pMK82PGbVTFn0DDRYVMDp4RSb++m5OudG+/GtxdZrsPxufPMJ2ju10eNQUFKZDy3NFm7wNZQ99Q1rV5q8sNagc/om680b1roegvqCZtUUv7WVpvVRtryA4wu9C2P7utF1fiXZ4yJ8IyTrs+Wq501hWPzDdPDg7fwowT4py8XvohYVKM2UWGOljoHp0642y26DyfJJhzW7dmNZxkZ18isZe535eeRqgmKdFfuP1M5w6yUKlE6qa3hzJhkcpUruInER11xGa456wAHC3+oHfEVir2p6XEOcQ177Gv53K8=';
        }
        blob decrypt = Crypto.decrypt('AES256', key, IVString, EncodingUtil.base64Decode(responseBody) );        
        ProductConfigResponseHandler parseJSON = ProductConfigResponseHandler.parse(decrypt.toString());
        return parseJSON.model.sfpcToken;
    }
    
  /*  
    public String  sendQLI(String token , blob requestedBody){
        // String json  = JsonBody;
        // blob data = Blob.valueOf(json);
        // Blob encrypted = Crypto.encrypt('AES256', key, IVString,data);
        // //System.debug('Resquest: '+EncodingUtil.base64Encode(encrypted));
        
        Generic_HTTPCalloutService callObj = new Generic_HTTPCalloutService();
        HTTPResponse response = callObj.setEndpointURL(qliEndPointURL)
            .setRequestMethod('POST')            
            .setHeaderParameter('Content-Type', HttpHexFormBuilder.GetContentType())
            .setHeaderParameter('Authorization','Bearer '+token)            
            .setHeaderParameter('X-Skip-Encryption','')
            .setHeaderParameter('Connection','keep-alive')
            .setRequestBody(requestedBody)
            //.setRequestBody(EncodingUtil.base64Encode(encrypted))
            .formHTTPRequest('blob')
            .sendRequest();

        String responseBody= response.getBody();
        
        if(test.isRunningTest()){
            responseBody = 'Q9+qJ2TKbwFl5Y7IH3ZTrM9Erq5sTVJrbJLkFIMMC9/BMQljEwpDXfHBStAYjQz+qRBRaP7Ui0kktdwEjA/w7e6OAsJra9MzR5USJ//dfugm7VaDtCvIr60LRLFMrWXY1+zrn5BuL4lFStliLd9LfadPK7PbsCKgftCbnPWKv+U=';
        }
        
        Blob responseBlob = response.getBodyAsBlob();
        blob decrypt = Crypto.decrypt('AES256', key, IVString, EncodingUtil.base64Decode(responseBody) );
        return decrypt.toString();
        
    }   
*/

//Decode the response
    public String  parseResponse(String responseBody){
        blob decrypt = Crypto.decrypt('AES256', key, IVString, EncodingUtil.base64Decode(responseBody) );
        return decrypt.toString();
    }   


    
}