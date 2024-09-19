public class ServiceAuditWarningLetterController 
{
	/*private ApexPages.StandardController stdController;
    public Service_Audit_Report__c report {get; set;}
    
    public ServiceAuditWarningLetterController(ApexPages.StandardController stdController) 
    {
        this.stdController = stdController;
        Id serviceAuditReportId = (Id)stdController.getId();
        fetchServiceAuditReportData(serviceAuditReportId);

    }
    
    private void fetchServiceAuditReportData(Id serviceAuditReportId) {
        List<Observation_Area__c> areas = [SELECT Id, Name, Status__c
                                            FROM Observation_Area__c
                                            WHERE Service_Audit_Report__c = :serviceAuditReportId];
        
        
        }
    }*/
            

    @InvocableMethod(label='Service Audit Warning Letter' description='Generates and Emails Warning Letter PDF')
    public static void generateWarningLetter(List<List<String>> args){
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'onecrm@godrej.com' ];
        List<String> nested = args[0];
        
        String email = nested[0];
        String serviceAuditReportId = nested[1];
        //String url = 'https://gnb--pwcexplore.sandbox.lightning.force.com/lightning/r/Service_Audit_Report__c/'+serviceAuditReportId+'/view';
        
        PageReference servicereportPDF = new PageReference('/apex/ServiceAuditWarningLetter?id=' + serviceAuditReportId);
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Service Audit Warning Letter.pdf');
        
        if(!test.isRunningTest())
        {
            attachment.body = servicereportPDF.getContent();
        } 
        else 
        {
           attachment.body = blob.valueOf('blob');
        }
        
        attachment.setInline(false);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email});
        mail.setSubject('Service Audit Warning Letter');
        mail.setHtmlBody('Here\'s a warning letter that has been sent to you.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        mail.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}