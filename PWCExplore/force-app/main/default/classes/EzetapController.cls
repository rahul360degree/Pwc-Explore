/**
 * @Description       : class used to make create QR code and to send sms and to check status on Ezetap payment gateway
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-30-2024
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-06-2023   Varun Rajpoot   Initial Version
**/
public with sharing class EzetapController {
    private static Map<String,String> integrationConfigMap;
    
    @AuraEnabled
    public static String initiatePayment(String calloutType,String refNumber,String jsonPart){
        integrationConfigMap = getIntegrationConfig();
        System.debug(integrationConfigMap);
        String requestBody = '';
        String endPoint = integrationConfigMap.get('endPointURL');//'https://demo.ezetap.com/api/3.0/';

        if(calloutType =='createQR'){
            requestBody = paymentBody(jsonPart,calloutType);
            if(jsonPart.contains('automaticSMSPaymentLinkEnabled')){
                endpoint += 'pay/createPaymentLink';
            }else{
                //endpoint += 'https://demo.ezetap.com/api/2.0/merchant/upi/qrcode/generate';
                endpoint += 'merchant/upi/qrcode/generate';
            }
        }else if(calloutType =='checkStatus'){
            requestBody = paymentBody(jsonPart,calloutType);
            endpoint += 'txn/details';
        }

        
        Generic_HTTPCalloutService callout = new Generic_HTTPCalloutService();
        HTTPResponse response = callout.setEndpointURL(endpoint)
            .setRequestMethod('POST')           
            .setHeaderParameter('Content-Type','application/json;charset=UTF-8')
            .setRequestBody(requestBody)
            .formHTTPRequest('String')
            .sendRequest();
        return response.getBody();
    }

    private static String paymentBody(String jsonPart,String calloutType){
        String requestBodyJSON = '';
        requestBodyJSON = requestBodyJSON + '{';
        if(!String.isBlank(jsonPart)){
            requestBodyJSON = requestBodyJSON + jsonPart+',';
        }
        requestBodyJSON += authBody();
        requestBodyJSON = requestBodyJSON + '}';
        return requestBodyJSON;
    }


    // private static String statusCheckBody(String refrenceNumber){
    //     String requestBodyJSON = '';
    //     requestBodyJSON = requestBodyJSON + '{';
        
    //     requestBodyJSON = requestBodyJSON + '"appKey":"7308d7c7-c93f-4895-9688-b80d455d9323",';
    //     requestBodyJSON = requestBodyJSON + '"username":"3939000118",';
    //     requestBodyJSON = requestBodyJSON + '"externalRefNumber":"'+refrenceNumber+'",';
    //     requestBodyJSON = requestBodyJSON + '}';
    //     return requestBodyJSON;
    // }

    private Static String authBody(){
        String authBody ='';
        // authBody = authBody + '"appKey":"7308d7c7-c93f-4895-9688-b80d455d9323",';
        // authBody = authBody + '"username":"3939000118"';
        authBody = authBody + '"appKey":"'+integrationConfigMap.get('appKey')+'",';
        authBody = authBody + '"username":"'+integrationConfigMap.get('username')+'"';
        return authBody;
    }

    private static Map<String,String> getIntegrationConfig(){
        Map<String,String> configMap = new Map<String,String>();
        for(Integration_Configuration__mdt mdt:[Select Id,Key_1__c,Key_2__c,DeveloperName 
                                                from Integration_Configuration__mdt 
                                                where DeveloperName IN ('EzeTap_URL','EzeTap_Creds')])
        {
            if(mdt.DeveloperName == 'EzeTap_URL'){
                configMap.put('endPointURL',mdt.Key_1__c);
            }else if(mdt.DeveloperName == 'EzeTap_Creds'){
                configMap.put('username',mdt.Key_1__c);
                configMap.put('appKey',mdt.Key_2__c);
            }
        }
        System.debug(configMap);
        return configMap;
    }
}