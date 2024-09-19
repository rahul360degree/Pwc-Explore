/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Utility class to perform inventory integration for OLAP approach
Inputs:        NA
Test Class:    OLAPInventoryExtensionTest
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public class InventoryVisiblityRequstor {

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to generate a request object and make a callout to the OLAP external service.
    Inputs:        String jsonString
    Output Type:   HttpResponse
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public HttpResponse generateRequest(String jsonString){
        String url = System.Label.Endpoint;
        //Instantiate a new http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        req.setTimeout(120000);
        String token = generateOAuthToken();
        req.setHeader('Authorization','Bearer '+token);
        req.setBody(jsonString); 
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug(res.getBody());
        return res;
    }
    
    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to get the OAuth token which is used to authorize the incoming request for OLAP approach.
    Inputs:        
    Output Type:   String
    Test Class:   

    History
    ----------------------------------------------------------------------------*/
    public static String generateOAuthToken(){
        String url = System.Label.Token_URL;

        String clientId = System.Label.ClientId;
        String clientSecrete = System.Label.ClientSecret;
        String username = System.Label.UserName;
        String password = System.Label.Password;
        // Instantiate a new http object
        Http h = new Http();
     
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        
        Blob headerValue = Blob.valueOf(username+ ':' +password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);
        req.setMethod('POST');
        req.setBody('grant_type=password' + 
                    '&client_id=' + clientId + 
                    '&client_secret=' + clientSecrete + 
                    '&username=' + username +
                    '&password=' + password
                   );    
        HTTPResponse res = h.send(req);
        system.debug(res.getBody());

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        return (String)response.get('access_token');
    }
}