// public with sharing class PDFGenerator {
//     @AuraEnabled(cacheable=true)
//     public static String generatePDFContent(Id recordId) {
//         // Fetch record details based on recordId
//         Service_Audit_Report__c report = [SELECT Name, Audit_Status__c, Audit_Type__r.Name, Auditee__r.Name, Auditor__r.Name, Completed_Date__c, Executed_Date__c 
//                                           FROM Service_Audit_Report__c 
//                                           WHERE Id = :recordId];

//         // Construct PDF content
//         String pdfContent = 'Service Audit Report Details:\n\n';
//         pdfContent += 'Name: ' + report.Name + '\n';
//         pdfContent += 'Audit Status: ' + report.Audit_Status__c + '\n';
//         pdfContent += 'Audit Type: ' + (report.Audit_Type__r != null ? report.Audit_Type__r.Name : '') + '\n';
//         pdfContent += 'Auditee: ' + (report.Auditee__r != null ? report.Auditee__r.Name : '') + '\n';
//         pdfContent += 'Auditor: ' + (report.Auditor__r != null ? report.Auditor__r.Name : '') + '\n';
//         pdfContent += 'Completed Date: ' + (report.Completed_Date__c != null ? report.Completed_Date__c.format() : '') + '\n';
//         pdfContent += 'Executed Date: ' + (report.Executed_Date__c != null ? report.Executed_Date__c.format() : '') + '\n';

//         return EncodingUtil.base64Encode(Blob.valueOf(pdfContent));
//     }
// }
public with sharing class PDFGenerator {
    @AuraEnabled(cacheable=true)
    public static String generatePDFContent() {
        String pdfContent = 'Hello, this is a test PDF content.';
        return EncodingUtil.base64Encode(Blob.valueOf(pdfContent));
    }
}