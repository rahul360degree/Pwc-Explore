// barcodeScannerExample.js
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';
import makeMockApiCall from '@salesforce/apex/QrScannerController.makeMockApiCall';

export default class QrScanner extends LightningElement {
    myScanner;
    scanButtonDisabled = false;
    scannedBarcode = '';

    connectedCallback() {
        this.myScanner = getBarcodeScanner();
        if (this.myScanner == null || !this.myScanner.isAvailable()) {
            this.scanButtonDisabled = true;
        }
    }

    handleBeginScanClick() {
        this.scannedBarcode = '';

        if (this.myScanner != null && this.myScanner.isAvailable()) {
            const scanningOptions = {
                barcodeTypes: [this.myScanner.barcodeTypes.QR],
                instructionText: 'Scan a QR Code',
                successText: 'Scanning complete.'
            };
            this.myScanner
                .beginCapture(scanningOptions)
                .then((result) => {
                    this.scannedBarcode = result.value;
                    this.makeMockApiCall(this.scannedBarcode);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Successful Scan',
                            message: 'Barcode scanned successfully.',
                            variant: 'success'
                        })
                    );
                })
                .catch((error) => {
                    console.error(error);
                    if (error.code == 'userDismissedScanner') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Scanning Cancelled',
                                message: 'You cancelled the scanning session.',
                                mode: 'sticky'
                            })
                        );
                    }
                    else { 
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Barcode Scanner Error',
                                message: 'There was a problem scanning the barcode: ' +
                                    error.message,
                                variant: 'error',
                                mode: 'sticky'
                            })
                        );
                    }
                })
                .finally(() => {
                    this.myScanner.endCapture();
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Barcode Scanner Is Not Available',
                    message: 'Try again from the Salesforce app on a mobile device.',
                    variant: 'error'
                })
            );
        }
    }

    makeMockApiCall(scannedValue) {
        makeMockApiCall({ scannedValue })
            .then(result => {
                console.log('Mock API response:', result);
                if (result === true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Product Found',
                            message: 'The product was found.',
                            variant: 'success'
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'No Product Found',
                            message: 'No product was found.',
                            variant: 'warning'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('Error making mock API call:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while processing your request.',
                        variant: 'error'
                    })
                );
            });
    }
}