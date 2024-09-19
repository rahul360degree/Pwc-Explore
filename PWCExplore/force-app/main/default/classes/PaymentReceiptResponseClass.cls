public class PaymentReceiptResponseClass
{  
 public HttpResponse generateSMSRequest(String MobNo,String SMSBody){
        
        String url = System.Label.EndpointPaymentAdvance;
        //System.debug('URL inside Payment Advance'+url);
        DateTime currentDateTime = DateTime.now();
		String mobileNo = MobNo;
        String getSmsBody = SMSBody;
        String trackIdValue = System.Label.TrackIdForPaymentReceipt;
		String finUrl = url+'MobileNo='+mobileNo+'&DateTime='+currentDateTime+'&msg='+trackIdValue+' CUSTGOD '+getSmsBody+'&trackid='+trackIdValue;
        //System.debug('DateTime inside Payment Advance'+currentDateTime);   
        String finalurl =finUrl.replace(' ', '%20'); 
        System.debug('finalurl'+finalurl);
     
        //Instantiate a new http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalurl);
        req.setMethod('GET');
         
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug('res.getBody() inside generateSMSRequest:'+res.getBody());
		return res;
    }
        
}