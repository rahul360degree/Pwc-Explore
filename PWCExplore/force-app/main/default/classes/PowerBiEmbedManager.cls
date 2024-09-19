/**
 * @description       : 
 * @author            : Varun Rajpoot
 * @group             : 
 * @last modified on  : 11-02-2023
 * @last modified by  : Varun Rajpoot
**/
public with sharing class PowerBiEmbedManager {
    
    public PowerBiEmbedManager() {}
    
    public class ClientCredentialPostData {
        public String client_id;
        public String client_info;
        public string client_secret;
        public String scope;
        public string grant_type;
        public String getPostData(){
          return 'client_id=' + this.client_id + 
                '&client_info=' + this.client_info +
                '&client_secret=' + this.client_secret +
                '&scope=' + this.scope +
                '&grant_type=' + grant_type;
        }
    }

    public class ClientCredentialResponse {
        public String access_token;
        public String expires_in;
        public String ext_expires_in;
        public String token_type;
    }
    
    public class PowerBiReport    {
        public String id { get; set; } 
        public String reportType { get; set; } 
        public String name { get; set; } 
        public String webUrl { get; set; } 
        public String embedUrl { get; set; } 
        public boolean isFromPbix { get; set; } 
        public boolean isOwnedByMe { get; set; } 
        public String datasetId { get; set; } 
        public boolean IsEffectiveIdentityRequired { get; set; } 
   }
    
    public class PowerBiEmbedToken    {
        public string token { get; set; } 
        public string tokenId { get; set; } 
        public DateTime expiration { get; set; } 
    }
 
    public class PowerBiReportData    {
        @AuraEnabled
        public String workspaceId { get; set; } 
        @AuraEnabled
        public String reportId { get; set; } 
        @AuraEnabled
        public String name { get; set; } 
        @AuraEnabled
        public String embedUrl { get; set; } 
        @AuraEnabled
        public String embedToken { get; set; } 
        @AuraEnabled
        public DateTime embedTokenExpires { get; set; } 
        @AuraEnabled
        public String error { get; set; } 
     }
    
    public static String getPowerBiAccessToken() {

        // get auth settings from Custom Metadata Type reconrd
        Power_BI_Auth_Setting__mdt authSetting = Power_BI_Auth_Setting__mdt.getInstance('PowerBiApp');
        string TenantId = authSetting.TenantId__c;    
        string ClientId = authSetting.ClientId__c;    
        string ClientSecret = authSetting.ClientSecret__c;        

        // construct URL for client credentials flow
        String aadTokenEndpoint = 'https://login.microsoftonline.com/' + TenantId + '/oauth2/v2.0/token';

        // prepare HTTP request 
        HttpRequest reqClientCredentialsFlow = new HttpRequest();
        reqClientCredentialsFlow.setMethod('POST');
        reqClientCredentialsFlow.setEndpoint(aadTokenEndpoint);        
        reqClientCredentialsFlow.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        // compose data for POST body
        ClientCredentialPostData postData = new ClientCredentialPostData();
        postData.client_id = ClientId;
        postData.client_info = '1';
        postData.client_secret = ClientSecret;
        postData.scope = 'https://analysis.windows.net/powerbi/api/.default';
        postData.grant_type = 'client_credentials';        
        String postBody = postData.getPostData();
        reqClientCredentialsFlow.setBody(postBody);

        // send HTTP POST to execute client credentials flow
        Http http = new Http();        
        HttpResponse response = http.send(reqClientCredentialsFlow);
 
        // extract and return app-only access token for service principal
        String responseJson = response.getBody();
        //System.debug(responseJson);
        ClientCredentialResponse responseData = (ClientCredentialResponse)JSON.deserialize(responseJson, ClientCredentialResponse.class);
        String access_token = responseData.access_token;         
        return access_token;
    }
   
    @AuraEnabled(cacheable=true)
    public static PowerBiReportData getEmbeddingDataForReport(String WorkspaceId, String ReportId) {

        // get access token for Authorization header
        String access_token = getPowerBiAccessToken();        

        // Call to Power BI Service API to get report data for embedding        
        HttpRequest reqGetReport = new HttpRequest();
        reqGetReport.setMethod('GET');
        String urlGetReport = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + ReportId;
        //urlGetReport = 'https://app.powerbi.com/groups/me/apps/ff1b40e8-135e-47f1-bd93-bb72968ca1c8/reports/9a9da8f9-8f0e-482a-9059-aade01372cc3';
        reqGetReport.setEndpoint(urlGetReport);
        reqGetReport.setHeader('Authorization', 'Bearer ' + access_token);
        
        Http http = new Http();        
        HttpResponse response = http.send(reqGetReport);
        
        // check response for success
        if(response.getStatusCode()!=200){
            //System.debug('ERROR --- Getting Report Data --- ERROR');
            //System.debug('Status Code: ' + response.getStatusCode());
            PowerBiReportData getReportError = new PowerBiReportData();
            getReportError.error = 'Get Report Error: ' + response.getStatus();
            //System.debug('Status Code: ' + response.getStatusCode());
            
            return getReportError;            
        }            
    //System.debug('Body : ' + response.getBody());
        // extract Power BI report data from JSON response
        String responseJson = response.getBody();
        PowerBiReport powerBiReport = (PowerBiReport)JSON.deserialize(responseJson, PowerBiReport.class);
        
        // send report info to debug window
        //System.debug('id: ' + powerBiReport.id);        
        //System.debug('reportType: ' + powerBiReport.reportType);        
        //System.debug('name: ' + powerBiReport.name);  
        //System.debug('webUrl: ' + powerBiReport.webUrl);      
        //System.debug('embedUrl: ' + powerBiReport.embedUrl);        
        //System.debug('isFromPbix: ' + powerBiReport.isFromPbix);        
        //System.debug('isOwnedByMe: ' + powerBiReport.isOwnedByMe);        
        //System.debug('datasetId: ' + powerBiReport.datasetId);   
        //System.debug('IsEffectiveIdentityRequired: ' + powerBiReport.IsEffectiveIdentityRequired);   
        

        // Call to Power BI Service API to get embed token for report        
        HttpRequest reqGetEmbedToken = new HttpRequest();
        reqGetEmbedToken.setMethod('POST');
        String urlGetEmbedToken = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + ReportId + '/GenerateToken';
        reqGetEmbedToken.setEndpoint(urlGetEmbedToken);
        reqGetEmbedToken.setHeader('Authorization', 'Bearer ' + access_token); 
        reqGetEmbedToken.setHeader('Content-Type','application/json');
        
        //
        
 String body = '{"accessLevel": "View", ' +
              '  "datasetId":  "' + powerBiReport.datasetId + '", ' +
              '  "identities": ' +
              '        [{ ' +
              '            "username": "cherubin@godrej.com", ' +//,sumaiya@godrej.com cherubin@godrej.com
              '            "datasets": ["' + powerBiReport.datasetId + '"] ' +
              '        }' +
              '      ]' +  
              ' }' ;   

        
        //

        if (powerBiReport.name == 'Stocks'){
            reqGetEmbedToken.setBody(body);
        }
        else{
        
        reqGetEmbedToken.setBody('{ "accessLevel": "View", "datasetId": "' + powerBiReport.datasetId + '"}');
        }
        
        
        //reqGetEmbedToken.setBody('{"accessLevel": "View", "datasetId": "' + powerBiReport.datasetId + '"}');
        //reqGetEmbedToken.setBody('{"accessLevel": "View", "datasetId": "' + powerBiReport.datasetId + '",' + i + '}');
        //reqGetEmbedToken.setBody('{"accessLevel": "View",'+ i + '}'); //+ '"datasetId": "' + powerBiReport.datasetId + '"}');
        

    
        HttpResponse responseEmbedToken = http.send(reqGetEmbedToken);

        // check response for success
        if(responseEmbedToken.getStatusCode()!=200){
            //System.debug('ERROR --- Getting Embed Token --- ERROR');
            //System.debug('Status Code: ' + responseEmbedToken.getStatusCode());            
            PowerBiReportData getEmbedTokenError = new PowerBiReportData();
            getEmbedTokenError.error = 'Get Embed Token Error: ' + response.getStatus();
            //System.debug('Response Body : ' + responseEmbedToken.getBody());
            //System.debug('Request Body : ' + reqGetEmbedToken.getBody());
            //return getEmbedTokenError;            
        }            

        // extract Power BI embed token and expiration
        PowerBiEmbedToken embedToken = (PowerBiEmbedToken)JSON.deserialize(responseEmbedToken.getBody(), PowerBiEmbedToken.class);
        
        // send report info to debug window
        //System.debug('EmbedToken: ' + embedToken.token);        
        //System.debug('EmbedToken ID: ' + embedToken.tokenId);        
        //System.debug('expiration: ' + embedToken.expiration);
        
        // create custom remote-able object to return to caller in browser 
        
        PowerBiReportData powerBiReportData = new PowerBiReportData();        
        powerBiReportData.workspaceId = WorkspaceId;
        powerBiReportData.reportId = ReportId;
        powerBiReportData.name = powerBiReport.name;
        powerBiReportData.embedUrl = powerBiReport.embedUrl;
        powerBiReportData.embedToken = embedToken.token;
        //powerBiReportData.embedToken = access_token;
        powerBiReportData.embedTokenExpires = embedToken.expiration;
        
        return powerBiReportData;            
 
    }

    
    @AuraEnabled
    public static String checkConstructionUser(){
        User user = [Select Id,Business_Unit__c from User where Id =: UserInfo.getUserId()];
        return user.Business_Unit__c;
    }
}