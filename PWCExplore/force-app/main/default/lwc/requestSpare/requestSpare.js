import { LightningElement,track,wire } from 'lwc';
import saveFormData from '@salesforce/apex/RequestSparesController.saveFormData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RequestSpare extends LightningElement {


    @track issue;
    @track partCode;
    @track modelNumber;
    @track reasonForReplacement;
    @track quantity;
    @track selectedDeliveryOption;
    @track workOrderId;
    @track serialNumberFile;
    @track invoiceFile;

    deliveryOptions = [
        { label: 'ASP', value: 'ASP' },
        { label: 'Customer', value: 'Customer' }
    ];

    handleIssueChange(event) {
        this.issue = event.target.value;
    }

    handlePartCodeChange(event) {
        this.partCode = event.target.value;
    }

    handleModelNumberChange(event) {
        this.modelNumber = event.target.value;
    }

    handleReasonChange(event) {
        this.reasonForReplacement = event.target.value;
    }

    handleQuantityChange(event) {
        this.quantity = event.target.value;
    }

    handleWorkOrderIdChange(event) {
        this.workOrderId = event.detail.value[0];
    }

    handleDeliveryChange(event) {
        this.selectedDeliveryOption = event.detail.value;
    }

    handleSerialNumberChange(event) {
        this.serialNumberFile = event.target.files[0];
    }

    handleInvoicePhotoChange(event) {
        this.invoiceFile = event.target.files[0];
    }

    handleSave() {
        let missingField;
        // Check which file is missing
        if (!this.serialNumberFile && !this.invoiceFile) {
            missingField = "Serial Number and Invoice photos";
        } else if (!this.serialNumberFile) {
            missingField = "Serial Number photo";
        } else if (!this.invoiceFile) {
            missingField = "Invoice photo";
        }

        // If any file is missing, show error message and stop further processing
        if (missingField) {
            const errorMessage = `Please upload ${missingField}.`;
            this.showToast('Error', errorMessage, 'error');
            return;
        }

        // Proceed with saving form data if all required fields are present
        const formData = {
            issue: this.issue,
            partCode: this.partCode,
            modelNumber: this.modelNumber,
            reasonForReplacement: this.reasonForReplacement,
            quantity: this.quantity,
            selectedDeliveryOption: this.selectedDeliveryOption,
            workOrderId: this.workOrderId,
            serialNumberFile: this.serialNumberFile,
            invoiceFile: this.invoiceFile
        };

        saveFormData({ formData: formData })
            .then(result => {
                // Handle success
                const successMessage = "Form data saved successfully.";
                this.showToast('Success', successMessage, 'success');
                // Optionally, reset form fields or perform any other actions after successful save
            })
            .catch(error => {
                // Handle error
                this.showToast('Error', error.body.message, 'error');
            });
    }

    // Function to display toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}