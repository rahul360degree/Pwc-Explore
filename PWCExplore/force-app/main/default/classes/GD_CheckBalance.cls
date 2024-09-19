/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 12-25-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public class GD_CheckBalance {
    
    public static decimal decCreditLimit;
    public static decimal decOrderBalance;
    public static decimal decInvoiceBalance;
    public static decimal decBillingRequest;
    public static decimal decAvailableBalance;    
   	    
    public static void callAPIfuture(Id orderId) {
        Id profileId= UserInfo.getProfileId();
        String profileName='';
        
        List<Profile> pro;
        
        pro = [Select Id,Name from Profile where Id=:profileId];
        
        if(pro != null && pro.size() > 0)
            profileName = pro[0].Name;
        
        system.debug('>>> profileName >>>'+profileName);
        
        if( profileName != 'Integration Administrator' ){
            
            Order objOrder = [ Select AccountId, Account.Account_Code__c from Order where Id =: orderId  ];
            
            String bpCode = objOrder.Account.Account_Code__c;
            
            if( !String.isBlank(bpCode) && bpCode.startsWith('H') ){
                callBDE(orderId);
            }
        }
    }
    
    @future(callout=true)
    public static void callBDE(Id orderId) {
        callAPI(orderId); 
    }

    
    @AuraEnabled
    public static String callAPI(Id orderId){ 
        try
        {
        system.debug('orderId > '+ orderId);
        Order objOrder = [ Select AccountId, Account.Account_Code__c from Order where Id =: orderId  ];
        
        String bpCode = objOrder.Account.Account_Code__c;
        
        system.debug('>>> bpCode >>>' + bpCode);
        
        if( String.isBlank(bpCode) )
            return 'BP code does not exists on this Account.';
        else if( !bpCode.startsWith('H') )
            return 'This feature is available only for Appliances division. Please contact System Administrator.';
        else{
        
            // String strEndpoint = 'https://uatxi.godrej.com:7443/infor/CustomerApi/UAT/BDE/CustomerBalance_GB/LN_UAT';
            
            String strEndpoint = System.Label.PRODUCT_STOCK_ENQUIRY_BDE_URL;
            
            String strSoap = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cus="http://www.infor.com/businessinterface/CustomerBalance_GB">'+
                               '<soapenv:Header>'+
                                  '<cus:Activation>'+
                                  '</cus:Activation>'+
                               '</soapenv:Header>'+
                               '<soapenv:Body>'+
                                  '<cus:Show>'+
                                     '<ShowRequest>'+
                                        '<DataArea>'+
                                           '<CustomerBalance_GB>'+
                                              '<Customer>' + bpCode + '</Customer>'+
                                              '<OrganizationId>'+UserInfo.getOrganizationId()+'</OrganizationId>'+
                                            //   '<OrganizationId>00D2h0000008gtlEAA</OrganizationId>'+
                                           '</CustomerBalance_GB>'+
                                        '</DataArea>'+
                                     '</ShowRequest>'+
                                  '</cus:Show>'+
                               '</soapenv:Body>'+
                            '</soapenv:Envelope>';
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(strEndpoint);
            request.setBody(strSoap);
            request.setMethod('POST');
            request.setHeader('Content-Type','text/xml;charset=UTF-8');
            request.setHeader('Content-Length',string.valueOf( strSoap.length()) );
            
            HttpResponse response;
            
            // if(Test.isRunningTest())
            //     Test.setMock(HttpCalloutMock.class, new GD_CheckBalance_HttpResponseMock());    
            
            response = http.send(request);
                
            system.debug('>>>RES>>>'+response);
            system.debug('>>>RES>>>'+response.getStatusCode());
            system.debug('>>>RES>>>'+response.getHeader('Content-Type'));
            
            if(response.getStatusCode() == 200){
                
                system.debug('>>>RES BODY>>>'+response.getBody());
                
                Dom.Document doc = new Dom.Document();
                doc.load(response.getBody());
        
                dom.XmlNode xroot = doc.getrootelement();
        
                dom.XmlNode [] xrec = xroot.getchildelements();
        
                dom.XmlNode [] xrec2 = xrec[0].getchildelements();
        
                if( xrec2[0].getName() != 'Fault' ){
        
                    dom.XmlNode [] xrec3 = xrec2[0].getchildelements();
                    dom.XmlNode [] xrec4 = xrec3[0].getchildelements();
                    dom.XmlNode [] xrec5 = xrec4[0].getchildelements();
                    dom.XmlNode name = xrec5[0].getchildelement('Name',null);
            
                    dom.XmlNode CreditLimit = xrec5[0].getchildelement('CreditLimit',null);
                    decCreditLimit = decimal.valueOf(CreditLimit.gettext());
            
                    dom.XmlNode OrderBalance = xrec5[0].getchildelement('OrderBalance',null);
                    decOrderBalance = decimal.valueOf(OrderBalance.gettext());
            
                    dom.XmlNode InvoiceBalance = xrec5[0].getchildelement('InvoiceBalance',null);
                    decInvoiceBalance = decimal.valueOf(InvoiceBalance.gettext());
            
                    dom.XmlNode BillingRequest = xrec5[0].getchildelement('BillingRequest',null);
                    decBillingRequest = decimal.valueOf(BillingRequest.gettext());
            
                    dom.XmlNode AvailableBalance = xrec5[0].getchildelement('AvailableBalance',null);
                    decAvailableBalance = decimal.valueOf(AvailableBalance.gettext());
                    
                    Account acc = new Account(
                        Id = objOrder.AccountId,
                        //Credit_Limit__c = decCreditLimit,
                        Available_Balance__c = decAvailableBalance,
                        Invoice_Balance__c = decInvoiceBalance,
                        Order_Balance__c = decOrderBalance,
                        Billing_Request__c = decBillingRequest,
                        Account_Balance_Date__c = system.now()
                    );
                    
                    update acc;
                    return 'Account successfully updated with Balance, please refresh this page.';
                }
                
            }else if( (response.getBody()).contains( 'Business Partner ' + bpCode + '  does not exist.' ) ){
                return 'BP Code does not exist in LN. Please check with your System Administrator.';
            }else if( (response.getBody()).contains( 'Invalid Organization ID' ) ){
                return 'Error: Invalid Organization ID. Please check with your System Administrator.';
            }
            
        }
        
        return 'Unhandled exception occurred. Please check with your System Administrator.';
    }
        catch (Exception ex) {            
            throw new AuraHandledException(ex.getMessage());
        }
    }
}