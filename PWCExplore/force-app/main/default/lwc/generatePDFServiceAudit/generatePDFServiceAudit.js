// generatePDFServiceButton.js
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Define fields to fetch from the record
const FIELDS = [
    'Service_Audit_Report__c.Audit_Status__c',
    'Service_Audit_Report__c.Audit_Type__c',
    'Service_Audit_Report__c.Auditee__c',
    'Service_Audit_Report__c.Auditor__c',
    'Service_Audit_Report__c.Completed_Date__c',
    'Service_Audit_Report__c.Executed_Date__c',
    'Service_Audit_Report__c.Name'
];

export default class GeneratePDFServiceButton extends LightningElement {
    @api recordId;
    recordData;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.recordData = {
                Audit_Status__c: data.fields.Audit_Status__c.value,
                Audit_Type__c: data.fields.Audit_Type__c.value,
                Auditee__c: data.fields.Auditee__c.value,
                Auditor__c: data.fields.Auditor__c.value,
                Completed_Date__c: data.fields.Completed_Date__c.value,
                Executed_Date__c: data.fields.Executed_Date__c.value,
                Name: data.fields.Name.value
            };
        } else if (error) {
            console.error('Error fetching record', error);
            // Handle error scenario here
        }
    }

    async downloadPDF() {
        if (!this.recordData) {
            // Data not yet loaded, wait for it
            return;
        }
        
        const pdfContent = this.generatePDFContent(this.recordData);
        this.downloadFile(pdfContent);
    }

    generatePDFContent(recordData) {
        const content = `
            Audit Status: ${recordData.Audit_Status__c}
            Audit Type: ${recordData.Audit_Type__c}
            Auditee: ${recordData.Auditee__c}
            Auditor: ${recordData.Auditor__c}
            Completed Date: ${recordData.Completed_Date__c}
            Executed Date: ${recordData.Executed_Date__c}
            Name: ${recordData.Name}
        `;
        return content;
    }

    downloadFile(content) {
        const element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(content));
        element.setAttribute('download', 'Service_Audit_Report.txt');
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }
}