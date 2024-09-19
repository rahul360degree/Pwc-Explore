// assetOnboardingScreen.js
import { LightningElement, track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import makeCalloutAppliances from '@salesforce/apex/AssetOnboardingController.makeCallout';
import isSerialIdLinked from '@salesforce/apex/AssetOnboardingController.isSerialIdLinked';
import uploadFile from '@salesforce/apex/AssetOnboardingController.saveAttachment';
import makeCalloutLocks from '@salesforce/apex/AssetOnboardingController.makeMockApiCall';
import transferAsset from '@salesforce/apex/AssetOnboardingController.transfertAnAsset';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';

export default class AssetOnboarding extends LightningElement {
    @track selectedOption = 'Appliances';
    @track itemCode;
    assetId = '02iC40000003xrZIAQ';
    barcodeScanner;
    @api recordId;
    @track files = [];
    @track isSerialIdLinkedResult = false;
    @track isItemCodeDisabled = false;
    @track previousAssetId;
    @track previusAccount;
    @track rentalProduct = false;
    @track salesProductCode;
    constructor(){
        super();
        const style = document.createElement('style');
        style.innerText = '.slds-form-element__control{display:flex}';
        document.querySelector('head').appendChild(style);
    }

    get radioOptions() {
        return [
            { label: 'Appliances', value: 'Appliances' },
            { label: 'Locks', value: 'Locks' },
        ];
    }

    connectedCallback() {
        this.barcodeScanner = getBarcodeScanner();
    }

    handleOptionChange(event) {
        this.selectedOption = event.detail.value;
    }

    handleInputChange(event) {
        this.itemCode = event.target.value;
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        const reader = new FileReader();
        
        reader.onload = () => {
            this.fileData = {
                fileName: file.name,
                base64Data: reader.result.split(',')[1]
            };
            this.handleSaveDocument(); 
        };

        reader.readAsDataURL(file);
    }


    handleCheckboxChange(event) {
        this.rentalProduct = event.target.checked;
        
    }
    
    handleSaveDocument() {
        if (!this.fileData) {
            return;
        }
        uploadFile({ parentId: this.recordId,fileName: this.fileData.fileName, base64Data: this.fileData.base64Data })
            .then(result => {
                this.showSuccessToast('Document uploaded successfully');
                console.log('Document saved successfully:', result);
            })
            .catch(error => {
                console.error('Error saving document:', error);
            });
    }

    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

   

    handleScan() {
        if (this.barcodeScanner.isAvailable()) {
            let scanningOptions = {
                "barcodeTypes": ["code128","code39", "code93", "ean13", "ean8", "upca", "upce", "qr", "datamatrix", "itf", "pdf417"], 
                "instructionText":"Position barcode in the scanner view.\nPress x to stop.",
                "successText":"Successful Scan!"
            };
            this.barcodeScanner.scan(scanningOptions)
                .then((results) => {
                    this.itemCode = results[0].value;
                    this.isItemCodeDisabled = true;
                })
                .catch((error) => {
                    this.showToast('Error', error.body.message, 'error');
                })
                .finally(() => {
                    this.barcodeScanner.dismiss();
                });
        } else {
            this.showToast('Error', 'Barcode scanner is not available', 'error');
        }
    }

    handleCallout() {
        if (!this.itemCode) {
            this.showToast('Warning', 'Please enter a value in the input field.', 'warning');
            return;
        }

        isSerialIdLinked({ serialId: this.itemCode })
            .then(result => {
                this.isSerialIdLinkedResult = result.isLinked;
                this.previousAssetId = result.recordId;
                this.previusAccount = result.AccountId;
                console.log('LinkedBoolean-->',this.isSerialIdLinkedResult);
                console.log('RecordId--->',this.previousAssetId);
                if (result.isLinked) {
                    this.showToast('Warning', 'The scanned serial ID is already linked with an existing asset.', 'warning');
                } else {
                    if (this.selectedOption === 'Appliances') {
                        this.makeCalloutAppliances();
                    } else if (this.selectedOption === 'Locks') {
                        this.makeCalloutLocks();
                    }
                }
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleTransferClick() {
        transferAsset({recordID:this.recordId,previousAssetId:this.previousAssetId,accountId:this.previusAccount }).then(result=>{
            this.showToast('Success',result,'success');
        })
    }

    makeCalloutAppliances() {
        makeCalloutLocks({ scannedValue: this.itemCode,recordId:this.recordId})
            .then(result => {
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    makeCalloutLocks() {
        makeCalloutLocks({ scannedValue: this.itemCode,recordId:this.recordId }) // Pass scannedValue to the Apex method
            .then(result => {
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}