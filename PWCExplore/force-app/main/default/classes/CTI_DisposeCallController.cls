public with sharing class CTI_DisposeCallController {
    

    //(label='Dispose the Call' description='Returns the disposition comments')
    @InvocableMethod
    public static List<DisposeOutput> disposeTheCall( List<DisposeInputs> callDisposinglInputs ){
        DisposeOutput response = new DisposeOutput();
        System.debug('input data '+callDisposinglInputs);
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://vivr.1point1.in:10446/godrej/dispose/');
        req.setMethod('POST');
        
        // String body = '{ "source" : "godrej","user": "api", "pass" : "APIZXFV321", "agent_user" : "demosfdc", "function": "external_status", "value" : "B", "token" : "R29kcmVqQCMyMDI0", "case_id" : "Z1234x12", "bu_lob" : "mmkkxxl"}';
		String body2 = 'source=godrej&user=api&pass=APIZXFV321&agent_user=demosfdc&function=external_status&value=B&token=R29kcmVqQCMyMDI0&case_id='+ callDisposinglInputs[0].currentCaseId + '&bu_lob=mmkkxxl&lead_id='+ callDisposinglInputs[0].uniqueConId;
		System.debug('body '+body2);
        // String requestBody = 'token=R29kcmVqQCMyMDI0&case_id=Z1234x12&bu_lob=mmkkxxl&source=godrej&user=api&pass=APIZXFV321&agent_user=333001&function=external_status&value=B&phone_number=7693971154&phone_code=91&account_id=123&calling_event_id=3333&list_id=270220246666';
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(body2);
        
        HttpResponse res = h.send(req);
        System.debug( ' get status '+ res.getStatus() );
        System.debug('res get body -'+res.getBody());

        if( res.getStatusCode() == 200 && res.getStatus() == 'OK' ){
            response.resultMsg = res.getBody();
        } else {    
            System.debug('res get body -'+res.getBody());
            response.resultMsg = res.getBody();
        }
        return new List<DisposeOutput>{response};
    }
    
    public class DisposeInputs {        
        @InvocableVariable
        // (required=true)
        public String currentUser;
        
        @InvocableVariable
        //(required=true)
        public String currentCaseId;
        
        @InvocableVariable
        //(required=true)
        public String processLob;

        @InvocableVariable
        //(required=true)
        public String value;
        
        @InvocableVariable
        //(required=true)
        public String uniqueConId;

    }


    public class DisposeOutput {        
        @InvocableVariable
        // (required=true)
        public String resultMsg;
    

    }
}