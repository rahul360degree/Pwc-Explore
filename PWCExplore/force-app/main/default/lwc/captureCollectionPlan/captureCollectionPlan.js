import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateCollectionPlan from '@salesforce/apex/CaptureCollectionPlanController.updateCollectionPlan';
import getCollectionPlan from '@salesforce/apex/CaptureCollectionPlanController.getCollectionPlan';
import successMessageLabel from "@salesforce/label/c.Added_Collection_Plan";
import amountDueForCollection from '@salesforce/label/c.Amount_Due_For_Collection';

export default class CaptureCollectionPlan extends NavigationMixin(LightningElement) {
    label = {
        amountDueForCollection
    };
    @api recordId;
    @track billedSalesRecord = {};
    @track collectionPlanRecord = {};
    @track errorMessage = '';
    @track successMessage = '';
    @api sObjectName;
    @track hasError = false;

    connectedCallback() {
        getCollectionPlan({recordId : this.recordId})
        .then(result => {
            this.collectionPlanRecord = result;
        })
        .catch(error => {
            this.errorMessage = error.body.message;
            this.hasError = true;
        });
    }

    updateAllDates(event) {
        updateCollectionPlan({recordId : event.detail.id})
        .then(result => {
            const event = new ShowToastEvent({
                title: 'Success',
                message: successMessageLabel,
                variant: 'success'
            });
            this.dispatchEvent(event);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: this.sObjectName,
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            this.errorMessage = error.body.message;
            this.hasError = true;
        });
    }
}