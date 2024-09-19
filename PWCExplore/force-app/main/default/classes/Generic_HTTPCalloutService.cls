/**
* @description       : Generic class to make the callout
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 07-08-2022
* @last modified by  : vrajpoot@godrej.com
**/
public virtual class Generic_HTTPCalloutService {
    String endpointURL, requestMethod, requestBody, requestCertificate;
    Blob requestBodyAsBlob;    
    Integer requestTimeout;
    public HTTPRequest request;
    HTTPResponse response;
    Boolean isCompressedRequest;
    Map<String, String> headerParametersMap = new Map<String, String>();
    
    //Set the EndPoint
    public Generic_HTTPCalloutService setEndpointURL(String endpointURL) {
        this.endpointURL = endpointURL;
        return this;
    }
    //Set the method
    public Generic_HTTPCalloutService setRequestMethod(String requestMethod) {
        this.requestMethod = requestMethod;
        return this;
    }
    //Set the header params
    public Generic_HTTPCalloutService setHeaderParameter(String key, String value) {
        //if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            this.headerParametersMap.put(key, value);
        //}
        return this;
    }
    //Set the timeout
    public  Generic_HTTPCalloutService setRequestTimeout(Integer requestTimeout) {
        this.requestTimeout = requestTimeout;
        return this;
    }
    //Set the body as string
    public  Generic_HTTPCalloutService setRequestBody(String requestBody) {
        this.requestBody = requestBody;
        return this;
    }
    //Set the body as blob
    public  Generic_HTTPCalloutService setRequestBody(Blob requestBodyAsBlob) {
        this.requestBodyAsBlob = requestBodyAsBlob;
        return this;
    }
    //form the http request
    public  Generic_HTTPCalloutService formHTTPRequest(String bodyType) {
        this.request = new HTTPRequest();
        this.request.setEndpoint(this.endpointURL);
        this.request.setMethod(this.requestMethod);
        
        for(String key : headerParametersMap.keySet()) {
            this.request.setHeader(key,headerParametersMap.get(key));
        }
        if(bodyType=='String'){
            this.request.setBody(requestBody);
        }else if(bodyType=='blob'){
            this.request.setBodyAsBlob(requestBodyAsBlob);
        }
        
        if(this.requestTimeout>0){
            this.request.setTimeout(this.requestTimeout);
        }
        return this;
        
    }

    //send the http request
    public  HTTPResponse sendRequest() {
        Http http = new Http();
        
        //system.debug(this.request.getBody());

        this.response = http.send(this.request);        
        
        return this.response;
    }
}