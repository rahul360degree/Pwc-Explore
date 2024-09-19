import { api, LightningElement, track } from 'lwc';
import getLineItemColumns from '@salesforce/apex/QuoteQALWCController.getLineItemColumns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuoteLineItemCard extends LightningElement {
    @track lineItem;
    @track recordId;
    @track showRecordEditForm = false;
    @track fields = [];
    @api lineItemWrapper;

    connectedCallback() {
        this.recordId = this.lineItemWrapper.lineItem.Id;
        this.lineItem = this.lineItemWrapper.lineItem;
        getLineItemColumns()
        .then((result) => {
            let temp = [];
            for(let i=0;i < result.length; i++){
                temp.push(result[i].fieldName);
            }
            this.fields = [...temp];
        })
        .catch((error) => console.error(error));
    }

    checkIfAssetIsSelected(event) {
        event.stopPropagation();
        event.preventDefault();
        let assetIdTemplate = this.template.querySelector('c-lwc-lookup');
        let assetId = assetIdTemplate.selectedRecordId; 
        if(assetId && assetId !== null && assetId !== "" && assetId !== undefined) {
            let plansTemplate = this.template.querySelector('c-line-item-plan-selector');
            plansTemplate.openModal();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: "Please select an asset",
                    variant: "Error",
                }),
            );
        }
    }

    handleAssetChanged(event) {
        //Assigning directly to this.lineItemWrapper.selected gives error
        let  y= JSON.parse(JSON.stringify(this.lineItemWrapper));
        y.selectedAssetId =  event.detail.selectedRecordId;
        y.selectedAssetName = event.detail.selectedValue;
        this.lineItemWrapper = JSON.parse(JSON.stringify(y));
        this.selectedAssetId = event.detail.selectedRecordId;
        console.log('Card this.lineItemWrapper', this.lineItemWrapper);
        this.dispatchEvent(new CustomEvent('cardupdated',{detail : {rowwrapper : this.lineItemWrapper}}));
        this.template.querySelector('c-line-item-plan-selector').callToUpdateHelpText(this.selectedAssetId);
    }

    showToast(title,message,variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    openRecordEditForm(event) {
        this.showRecordEditForm = true;
    }

    closeRecordModal(event) {
        this.showRecordEditForm = false;
    }

    handleSuccess(event) {
        console.log('success event', event);
        this.showToast('Success', 'Record updated successfully', 'success');
        this.closeRecordModal(event);
        this.dispatchEvent(new CustomEvent('refreshparent',{detail : {
            isReset : true
        }}));
    }

    handleError(event) {
        console.log('error event', event);
        this.showToast('Error', event.detail.message, 'error');
    }
}