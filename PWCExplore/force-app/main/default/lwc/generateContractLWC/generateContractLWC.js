import { LightningElement, track, api } from 'lwc';
import errorMessage from '@salesforce/label/c.Error';
import successMessage from '@salesforce/label/c.Service_Contract_Created';
import validateQuote from '@salesforce/apex/ServiceContractManager.validateQuote';
import createServiceContract from '@salesforce/apex/ServiceContractManager.createServiceContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class GenerateOrder extends NavigationMixin(LightningElement) {

    @track hasValidationError;
    @api recordId;

    connectedCallback() {
        validateQuote({ quoteId: this.recordId })
            .then(result => {
                console.log('result :: ' + result);
                if (!result) {
                    this.hasValidationError = false;
                    createServiceContract({ quoteId: this.recordId })
                        .then(newServiceContract => {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: newServiceContract.Id,
                                    objectApiName: 'ServiceContract',
                                    actionName: 'view'
                                }
                            });
                            this.showToast('Success', successMessage, 'success');
                            this.dispatchEvent(new CustomEvent('close'));
                        })
                        .catch(error => {
                            this.error = error;
                            this.showToast('Error', error.body.message != null ? error.body.message : errorMessage, 'error');
                            this.dispatchEvent(new CustomEvent('close'));
                        });
                } else {
                    this.hasValidationError = true;
                    this.showToast('Error', result, 'error');
                    this.dispatchEvent(new CustomEvent('close'));

                }
            })
            .catch(error => {
                this.showToast('Error', errorMessage, 'error');
                this.dispatchEvent(new CustomEvent('close'));
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }
}