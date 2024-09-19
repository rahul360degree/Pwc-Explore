/*------------------------------------------------------------------------
    Author:        Anupam Mishra && Shankar Sahu
    Company:       GITL
    Description:   Method to generate a request object and make a callout to the OLAP external service.
    Inputs:        String jsonString
    Output Type:   HttpResponse
    Test Class:   

    History
    ----------------------------------------------------------------------------*/

public class FOCNumberExtension {
     
        public HttpResponse generateRequest(String jsonString){
        String url = System.Label.FOC_URL;
        string orders ='{"Orders": '+jsonString+'}';
        System.debug('URL inside FOC '+url);
        System.debug('Json String : '+jsonString);
        //Instantiate a new http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method  as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        System.debug('set method : ');
        req.setHeader('Content-Type', 'application/json');
       // req.setHeader('Accept', 'application/json');
        req.setTimeout(120000);
        String token = generateOAuthToken();
        req.setHeader('Authorization','Bearer '+token);
        req.setBody(orders);
        system.debug('request'+req.getBody());
        system.debug('request'+token);
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug('response'+res.getBody());
        return res;
    }
   /*------------------------------------------------------------------------
    Company:       GITL
    Description:   Method to get the OAuth token which is used to authorize the incoming request for OLAP approach.
    Inputs:        
    Output Type:   String
    ----------------------------------------------------------------------------*/
    public static String generateOAuthToken(){
        String url = System.Label.FOC_Token_URL;
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
        system.debug('Res '+res);
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        system.debug( 'respone '+response);
        return (String)response.get('access_token');
    }
}