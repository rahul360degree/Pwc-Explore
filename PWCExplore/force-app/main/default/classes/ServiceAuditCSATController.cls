public class ServiceAuditCSATController 
{
     @InvocableMethod(label='Send CSAT Survey Link to Customer' description='sends CSAT customer survey link')
    public static void generatePDF(List<List<String>> args)
    {
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'onecrm@godrej.com' ];
        List<String> nested = args[0];
        
        String email = nested[0];
        String caseId = nested[1];
        String url = 'https://gnb--pwcexplore.sandbox.my.site.com/csatsurvey/TakeSurvey?id=a48C40000000AllIAE&cId={!Contact.Id}&caId=' + caseId;
        //String url = 'https://gnb--pwcexplore.sandbox.lightning.force.com/lightning/r/Service_Audit_Report__c/'+serviceAuditReportId+'/view';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email});
        mail.setSubject('CSAT Survey');
        mail.setHtmlBody('Godrej & Boyce would like to hear from you based on your recent service request. Click on the link to take the Customer Satisfaction survey \n' + url);
        mail.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
       	
    }

}