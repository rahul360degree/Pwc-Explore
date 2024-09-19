import { api, track, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuoteLineItemRow extends LightningElement {
    @track lineItem;
    @track showRecordEditForm = false;
    @track isLoaded = false;
    @api columnsApiNames = [];
    @track rows = [];
    @api lineItemWrapper;
    @track selectedAssetId;
    @track recordId;

    connectedCallback(){
        console.log('this.lineItemWrapper', this.lineItemWrapper);
        this.recordId = this.lineItemWrapper.lineItem.Id;
        this.selectedAssetId = this.lineItemWrapper.selectedAssetId;
        this.lineItem = this.lineItemWrapper.lineItem;
        let tempRow = [];
        for(let i=0;i< this.columnsApiNames.length;i++) {
            tempRow.push(this.lineItem[this.columnsApiNames[i].fieldName]);
        }
        this.rows = [...tempRow];
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
        console.log('Row this.lineItemWrapper', this.lineItemWrapper);
        this.dispatchEvent(new CustomEvent('rowupdated',{detail : {rowwrapper : this.lineItemWrapper}}));
        this.template.querySelector('c-line-item-plan-selector').callToUpdateHelpText(this.selectedAssetId);
    }

    handlePlansSelected(event) {
        let y = JSON.parse(JSON.stringify(this.lineItemWrapper));
        y.plans = event.detail.plans;
        this.lineItemWrapper = JSON.parse(JSON.stringify(y));
        this.dispatchEvent(new CustomEvent('rowupdated',{detail : {rowwrapper : this.lineItemWrapper}}));
    }

    openRecordEditForm(event) {
        this.showRecordEditForm = true;
    }

    handleLoad(event) {
        this.isLoaded = true;
    }

    showToast(title,message,variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
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
    @api
    getselectedPlanHelpText(){    
        var helperText = this.template.querySelector('c-line-item-plan-selector').getselectedPlanHelpText();
        return helperText;
    }
}