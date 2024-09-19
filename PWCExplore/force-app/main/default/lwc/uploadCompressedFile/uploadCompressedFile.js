import { LightningElement, api, track } from 'lwc';
import createContentDocuments from '@salesforce/apex/UploadCompressedFileHelper.createContentDocuments';

export default class FileUploadComponent extends LightningElement {
    @api uploadLabel;
    @api acceptedFormats;
    @api recordId;
    @api allowMultiple;
    @api isRequired;
    @track uploadMessage;
    @track showSpinner = false;
    @api uploadedIds;
    @api uploadedIdsList = [];
    @api compressFile = false;
    @api fileName;
    wasImageUploaded = false;
    compressedFiles = [];
    fileType = 'png';
    maxFileSize = 1000000;

    displayUploadedMessage(event) {
        let canvas = document.createElement('canvas');
        let allFiles = event.target.files;
        let base64 = 'base64,';
        let reader = new FileReader();
        let base64DataURL;
        let base64File;
        this.showSpinner = true;
        for (let each = 0; each < allFiles.length; each++) {
            reader.onloadend = (() => {
                base64DataURL = reader.result;
                let imgVar = new Image();
                imgVar.onload = (() => {
                    let aspectRatio = 0.1;
                    if (allFiles[each].size < this.maxFileSize) {
                        aspectRatio = 1;
                    }
                    let context = canvas.getContext('2d');
                    canvas.width = imgVar.width * aspectRatio;
                    canvas.height = imgVar.height * aspectRatio;
                    context.drawImage(imgVar, 0, 0, canvas.width, canvas.height);
                    let data = canvas.toDataURL('image/png', aspectRatio);
                    let fileStart = data.indexOf(base64) + base64.length;
                    base64File = data.substring(fileStart);
                    this.compressedFiles.push(encodeURIComponent(base64File));
                    if (each === (allFiles.length - 1)) {
                        createContentDocuments({base64StringList: this.compressedFiles, fileName: this.fileName, fileType: this.fileType})
                        .then((result) => {
                            this.uploadedIdsList = result;
                            this.uploadedIds = this.uploadedIdsList.join(";");
                            this.uploadMessage = 'Uploaded ' + allFiles.length + ' file(s) successfully';
                            this.wasImageUploaded = true;
                            this.showSpinner = false;
                        })
                        .catch((error) => {
                            console.log(result);
                        })
                    }
                });
                imgVar.src = base64DataURL;
            });
            reader.readAsDataURL(allFiles[each]);
        }
    }

    @api
    validate() {
        if((this.isRequired && this.wasImageUploaded) || !this.isRequired) {
            return { 
                isValid: true,
                errorMessage: ''
            };
        } else {
            return { 
                isValid: false, 
                errorMessage: 'Please upload an image/file to proceed'
            }; 
        }
    }
}