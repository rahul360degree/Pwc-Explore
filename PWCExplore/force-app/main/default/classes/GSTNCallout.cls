/**
 * @description       : This class will make callout to gstn portal 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 12-28-2021
 * @last modified by  : vrajpoot@godrej.com

try Catch
desctipiotn
**/
public class GSTNCallout {
    @AuraEnabled(cacheable=true)
    public static String getcallout(String gstn){
        System.debug(gstn);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://taxpayer.irisgst.com/api/search?gstin='+gstn+'&apikey=2072c4af-6279-4d6b-89b2-2f0556618e1d');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        }
        return response.getBody();
    }
}