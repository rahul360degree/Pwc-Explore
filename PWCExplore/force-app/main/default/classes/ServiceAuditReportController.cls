public with sharing class ServiceAuditReportController 
{
    // for ASP audit reports
    private ApexPages.StandardController stdController;
    public List<ObservationAreaWrapper> observationAreas { get; set; }
    public Service_Audit_Report__c report {get; set;}

    
    public class ObservationAreaWrapper {
        public Observation_Area__c area { get; set; }
        public List<Service_Audit_Report_Line_Item__c> lineItems { get; set; }
        
        public ObservationAreaWrapper(Observation_Area__c area) {
            this.area = area;
            this.lineItems = new List<Service_Audit_Report_Line_Item__c>();
        }
    }
    
    public ServiceAuditReportController(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        observationAreas = new List<ObservationAreaWrapper>();
        
        Id serviceAuditReportId = (Id)stdController.getId();
        
        fetchServiceAuditReportData(serviceAuditReportId);

    }
    
    private void fetchServiceAuditReportData(Id serviceAuditReportId) {
        List<Observation_Area__c> areas = [SELECT Id, Name, Status__c
                                            FROM Observation_Area__c
                                            WHERE Service_Audit_Report__c = :serviceAuditReportId];
        
        for (Observation_Area__c area : areas) {
            ObservationAreaWrapper wrapper = new ObservationAreaWrapper(area);
            
            List<Service_Audit_Report_Line_Item__c> lineItems = [SELECT Id, Achieved_Score__c, Approved_Rejected_By__c, Approved_Rejected_Date__c,
                                                                          Maximum_Score__c, Observation_Area__c, Observation_Details__c, 
                                                                          Observation_Question_LU__r.Question_Text__c, Penalty__c, Recommendation__c, 
                                                                          Rejection_Reason__c, Name, Status__c, Percentage_Achieved__c, Corrective_Actions__c, Preventive_Actions__c
                                                                   FROM Service_Audit_Report_Line_Item__c
                                                                   WHERE Observation_Area__c = :area.Id];
            
            wrapper.lineItems.addAll(lineItems);
            
            observationAreas.add(wrapper);
        }
    }
            

    @InvocableMethod(label='Service Report PDF' description='Generates and Emails Service Report PDF')
    public static void generatePDF(List<List<String>> args){
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'onecrm@godrej.com' ];
        List<String> nested = args[0];
        
        String email = nested[0];
        String serviceAuditReportId = nested[1];
        String url = 'https://gnb--pwcexplore.sandbox.lightning.force.com/lightning/r/Service_Audit_Report__c/'+serviceAuditReportId+'/view';
        
        PageReference servicereportPDF = new PageReference('/apex/ServiceAuditReportPage?id=' + serviceAuditReportId);
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Service Audit Report.pdf');
        
        if(!test.isRunningTest()){
            attachment.body = servicereportPDF.getContent();
        } else {
           attachment.body = blob.valueOf('blob');
        }
        
        attachment.setInline(false);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email});
        mail.setSubject('Service Report PDF');
        mail.setHtmlBody('Here\'s the Service Report PDF you requested. Click on the link to visit the record detail page ' + url);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        mail.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
       	
    }
}