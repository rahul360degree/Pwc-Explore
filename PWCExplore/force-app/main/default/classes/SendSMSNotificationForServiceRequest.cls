/*------------------------------------------------------------------------
Author:        Saurabh Mehta
File Name:     SendSMSNotificationForServiceRequest.cls
Company:       Stetig 
Description:   class on SMS creation when case is created, change in case status & case closed.
Inputs:        NA
Last Modified: 07/10/2021
Test Class:    
----------------------------------------------------------------------------*/
public class SendSMSNotificationForServiceRequest {
    
    public static Set<String> statusValue = new  Set<String>{ElbConstantsClass.CASE_WIP};

    // creating SMS Handler & calling method to on specific action
    public static void sendSMSHandller(List<Case> caseList, boolean isInsert) {
      
    Id CaseTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ElbConstantsClass.CASE_RECORD_TYPE_LEASING).getRecordTypeId();
        
  	for(Case cse : caseList) {
			try {
                if(cse.recordtypeId == CaseTypeID){
                if(String.isNotEmpty(cse.ContactPhone) && String.isNotBlank(cse.ContactPhone) && cse.ContactPhone <>'Null' ){
				if(validateMobileNumber(cse.ContactPhone)) {
					if(isInsert) {
						generateSMSRequest(cse.ContactPhone, getSMSBodyForCreateCase(cse));
					} else {
						if(cse.isClosed) {
							generateSMSRequest(cse.ContactPhone, getSMSBodyForCloseCase(cse));
						} else {
							if(cse.Job_assigned_to__c != null && cse.status == ElbConstantsClass.CASE_ASSIGNED) {
							   generateSMSRequest(cse.ContactPhone, getSMSBodyForUpdateCase(cse));
							  } else if (statusValue.contains(cse.status.toLowerCase())) {
								generateSMSRequest(cse.ContactPhone, getSMSBodyForUpdateCaseWithJobAssigned(cse));
							}
						}
					}
				}
				else {
					System.debug('invalid Phone number'+cse.ContactPhone);
				 }
               }      
             }       
			}catch(DmlException e) {
				System.debug('The following exception has occurred: ' + e.getMessage());
            }  
        }
    }
    
    @future(callout=true)
    public static void generateSMSRequest(String MobNo,String SMSBody){
        SMS_URL__c cs = SMS_URL__c.getOrgDefaults();
     	String url = cs.Godrej_URL__c;

        Datetime now = DateTime.now();
        Integer offset = UserInfo.getTimeZone().getOffset(now);
        Datetime local = now.addSeconds(offset/1000);
        DateTime currentDateTime = local;
        String mobileNo = MobNo;
        String getSmsBody = SMSBody;
        String trackIdValue = 'CONSLEASE';
        String finUrl = url+'MobileNo='+mobileNo+'&DateTime='+currentDateTime+'&msg='+trackIdValue+' CUSTGOD '+getSmsBody+'&trackid='+trackIdValue; 
        String finalurl =finUrl.replace(' ', '%20'); 
           
        //Instantiate a new http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalurl);
        req.setMethod('GET');
        
        
        HttpResponse res = h.send(req);    
       
    }
    
    //Mehtod is use for creating case body
    public static String getSMSBodyForCreateCase(Case cse) {
        String smsbody ='Dear '+cse.Contact.Name+', Greetings from Godrej! Your request '+cse.casenumber+' regarding '+cse.Leasing_Case_Category__c+' is registered with GBD Helpdesk. Regards,GBD Helpdesk'; 
        return smsbody;
    }
    
    //Mehtod is use for update body when case JOb has assigned status change
    public static String getSMSBodyForUpdateCase(Case cse) {
        String smsbody ='Dear '+cse.Contact.Name+', Thankyou for the call Your request '+cse.casenumber+' regarding '+cse.Leasing_Case_Category__c+'. is intiated by us. Regards,GBD Helpdesk';
        return smsbody;
    }
    
    //Mehtod is use for update case when status change
    public static String getSMSBodyForUpdateCaseWithJobAssigned(Case cse) {
		 String smsbody ='Dear '+cse.Contact.Name+', Greetings from Godrej! Your request '+cse.casenumber+' is in progress. Regards,GBD Helpdesk';
         return smsbody;
	}
    
    //Creating body for closing case
    public static String getSMSBodyForCloseCase(Case cse) {
        String smsbody ='Dear '+cse.Contact.Name+', The request '+cse.casenumber+' regarding '+cse.Leasing_Case_Category__c+' is closed. Regards,GBD Helpdesk';
        return smsbody;
    }
    
    // Method is use to check 10 digit mobile number
    public static boolean validateMobileNumber(String mobNumber) {
        Boolean flag = false;
        if (mobNumber != null ) {
            String checkmobTenDigitNo = mobNumber.substring(0,10);
            Boolean validateMobileNumber = checkmobTenDigitNo.isNumeric();
            if(validateMobileNumber){
                flag = true;
            }
        }
      return flag;
    }
}