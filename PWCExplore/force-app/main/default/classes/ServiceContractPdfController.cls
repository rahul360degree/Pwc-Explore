public class ServiceContractPdfController {
    public ServiceContract serviceContract { get; set; }
    public String ServiceContractRecordTypeName { get; set; }
    public ServiceContractPdfController(ApexPages.StandardController controller) {
        Id ServiceContractId = ApexPages.currentPage().getParameters().get('id');
        serviceContract = [Select Id,Name,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,RecordTypeId from ServiceContract where Id =:ServiceContractId];
        
        ServiceContractRecordTypeName=serviceContract.RecordTypeId;
    }
    @InvocableMethod(label='Contract PDF' description='Generates and Emails Contract Details PDF')
    public static void generatePDF(List<List<String>> args){
        
        OrgWideEmailAddress orgWideEmailObj = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'onecrm@godrej.com' ];
        List<String> nested = args[0];
        
        String email = nested[0];
        String ServiceContractId = nested[1];
        String ServiceContractRecordTypeName = nested[2];
        
        PageReference ContractdetailsPDF;
        
        if(ServiceContractRecordTypeName == 'Appliances'){
            ContractdetailsPDF = new PageReference('/apex/AppliancesServiceContractPage?id=' + ServiceContractId);
        }
        
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Contract.pdf');
        
        if(!test.isRunningTest()){
            attachment.body = ContractdetailsPDF.getContent();
        } else {
           attachment.body = blob.valueOf('blob');
        }
        
        attachment.setInline(false);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {email});
        mail.setSubject('Contract PDF');
        mail.setHtmlBody('Here\'s your Contract Booking PDF.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        mail.setOrgWideEmailAddressId(orgWideEmailObj.Id);
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}