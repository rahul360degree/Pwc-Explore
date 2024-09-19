@RestResource(urlMapping='/crmis-gammacom/*')
global with sharing class AmazonWebServiceTest {
	
    @HttpGet
    global static Map<String, List<String>> getUnAcKnowledgedInstallationRequestIds() {
        
        Map<String, List<String>> dataToReturn = new Map<String, List<String>>{
            'ids'=> new List<String>()
        };
        
        List<Order> lstOrderRecords = [select id from order limit 1];
        
        for(Order each : lstOrderRecords) {
            dataToReturn.get('ids').add(each.Id);
        }
        
        
        return dataToReturn;
    }
  
    @HttpPost
    global static String acknowledgeInstallationRequests() {
        // Parse the JSON request body
        RestRequest req = RestContext.request;
        AcknowledgementsWrapper wrapper = (AcknowledgementsWrapper) JSON.deserialize(req.requestbody.toString(), AcknowledgementsWrapper.class);
		System.debug('wrapper --> '+wrapper);
        // Check if the wrapper or acknowledgements list is null
        if (wrapper == null || wrapper.acknowledgements == null) {
            return 'Error: Invalid JSON format or missing "acknowledgements" array.';
        }

        // List to store error messages
        List<ErrorMessage> errorMessages = new List<ErrorMessage>();
        List<String> failedId = new List<String>();

        for (Acknowledgement ack : wrapper.acknowledgements) {
            if (ack.id == null || ack.crmTicketId == null) {
                // Add error id to the list
                failedId.add(ack.id);
            }
        }
        //concatenate the error id
        String str = String.join(failedId,','); 
        
        //Add error message to the list
        errorMessages.add(new ErrorMessage('Requested InstallationRequestId '+str +
														' does not exist in Tracking table for vendor vikas.jain@lge.com',
                                                  str, false));
        //Map to return the error 
        Map<String, ErrorMessage> mapToReturn = new Map<String, ErrorMessage>();
        for(ErrorMessage each:errorMessages){
            mapToReturn.put('failedRequestIds',each);
        }

        // Convert error messages to JSON
        String jsonResponse = JSON.serialize(mapToReturn);
        System.debug('jsonResponse ==> '+jsonResponse);
        
        return jsonResponse;
    }
    public class Acknowledgement {
        public String id;
        public String crmTicketId;
    }

    public class AcknowledgementsWrapper {
        public List<Acknowledgement> acknowledgements;
    }

    public class ErrorMessage {
        public String failedId;
        public String errorMsg;
        public boolean recoverable;

        public ErrorMessage( String text,String id, boolean recov) {
            failedId = id;
            errorMsg = text;
            recoverable = recov;
        }
    }
    
}