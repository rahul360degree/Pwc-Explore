import { LightningElement, wire, api } from 'lwc';
import getHotData from '@salesforce/apex/contractRenewal.getHotData';
import updateHotFields from '@salesforce/apex/contractRenewal.updateHotFields';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ContractRenewal extends LightningElement {

    @api recordId;
    hotId;
    hotEndDateOld;
    hotEndDate;
    reasonForChange;

    @wire(getHotData, { hotId: '$recordId' })
    hotData({ data, error }) {
        if (data) {
            this.hotId = data[0]['Id'];
            this.hotEndDateOld = data[0]['Licence_End_Date__c'];
        }

    }

    endDateHandler(event) {
        this.hotEndDate = event.detail.value;

    }

    reasonHandler(event) {
        this.reasonForChange = event.detail.value;

    }

    changeContract() {
        updateHotFields({ hotId: this.hotId, hotEndDate: this.hotEndDate, reasonForChange: this.reasonForChange, hotEndDateOld: this.hotEndDateOld })
            .then(result => {
                if (result.length > 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Updated conditions for Contract Renewal.',
                            variant: 'success'
                        })
                    );
                }
                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Validation',
                            message: 'Updating conditions for Contract Renewal faced an error.',
                            variant: 'warning',
                            mode: 'sticky'
                        })
                    );
                }
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {

                const toastError = new ShowToastEvent({
                    'title': 'System Exception',
                    'message': 'An unknown exception occurred while updating End Date over HOT.',
                    'variant': 'error',
                    'mode': 'sticky'
                });
                this.dispatchEvent(toastError);
            });
    }
}