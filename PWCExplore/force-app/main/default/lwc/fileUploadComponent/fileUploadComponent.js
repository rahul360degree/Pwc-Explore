import { LightningElement, api, track } from 'lwc';

export default class FileUploadComponent extends LightningElement {
    @api uploadLabel;
    @api acceptedFormats;
    @api recordId;
    @api allowMultiple;
    @api isRequired;
    @track uploadMessage;
    @api uploadedIds;
    @api uploadedIdsList=[];
    wasImageUploaded = false;

    displayUploadedMessage(event) {
        this.wasImageUploaded = true;
        for (let each in event.detail.files) {
            this.uploadedIdsList.push(event.detail.files[each].documentId);
        }
        this.uploadedIds = this.uploadedIdsList.join(";");
        this.uploadMessage = 'Uploaded ' + event.detail.files.length + ' file(s) successfully';
    }

    @api
    validate() {
        if((this.isRequired && this.wasImageUploaded) || !this.isRequired) { 
            return { isValid: true,
                errorMessage: ''}; 
        } else {
            return { 
                isValid: false, 
                errorMessage: 'Please upload an image/file to proceed'
            }; 
        }
    }
}