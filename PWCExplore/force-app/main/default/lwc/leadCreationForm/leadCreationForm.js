import { LightningElement, track, wire,api } from 'lwc';
import createLead from '@salesforce/apex/LeadCreationFormController.createLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isLocksBusinessUnit  from '@salesforce/apex/LeadCreationFormController.isLocksBusinessUnit'

export default class LeadCreationForm extends LightningElement {

    @track selectedProductId;
    @track isLocks = false;
    @api recordId;
    @track quantity;
    @track finalSalePrice;
    @track selectedPreferredTime;
    @track selectedBillToLocation;
    @track selectedShipToLocation;
    @track externalMaterialPurchase = false;
    @track invoiceNumber;
    @track invoiceDate;
    @track selectedExistingSecurityStrength;
    @track selectedProposedSecurityStrength;
    @track selectedEntryPoint;
    @track selectedCompetitionReplaced;


    @track preferredTimeOptions = [
        { label: 'Morning', value: 'Morning' },
        { label: 'Afternoon', value: 'Afternoon' },
        { label: 'Evening', value: 'Evening' }
    ];
    @track billToLocationOptions = [
        { label: 'Customer', value: 'Customer' },
        { label: 'ASP', value: 'ASP' }
    ];
    @track shipToLocationOptions = [...this.billToLocationOptions];
    @track existingSecurityStrengthOptions = [
        { label: 'Level 1', value: 'Level 1' },
        { label: 'Level 2', value: 'Level 2' },
        { label: 'Level 3', value: 'Level 3' },
        { label: 'Level 4', value: 'Level 4' },
        { label: 'Level 5', value: 'Level 5' }
    ];
    @track proposedSecurityStrengthOptions = [...this.existingSecurityStrengthOptions];
    @track entryPointOptions = [
        { label: 'Main Door', value: 'Main Door' },
        { label: 'Inner Door', value: 'Inner Door' }
    ];
    @track competitionReplacedOptions = [
        { label: 'Europa', value: 'Europa' },
        { label: 'Yale', value: 'Yale' },
        { label: 'Dorset', value: 'Dorset' },
        { label: 'Link', value: 'Link' },
        { label: 'Qubo', value: 'Qubo' },
        { label: 'Quba', value: 'Quba' },
        { label: 'Lavna', value: 'Lavna' },
        { label: 'Others', value: 'Others' }
    ];
    

    handleProductSelect(event) {
        this.selectedProductId = event.detail.recordId;
    }

    handleProductNameChange(event) {
        this.productName = event.target.value;
    }

    handleQuantityChange(event) {
        this.quantity = event.target.value;
    }


    handleFinalSalePriceChange(event) {
        this.finalSalePrice = event.target.value;
    }

    handlePreferredTimeSelect(event) {
        this.selectedPreferredTime = event.detail.value;
    }

    handleBillToLocationSelect(event) {
        this.selectedBillToLocation = event.detail.value;
    }

    handleShipToLocationSelect(event) {
        this.selectedShipToLocation = event.detail.value;
    }

    handleExternalMaterialChange(event) {
        this.externalMaterialPurchase = event.target.checked;
    }

    handleInvoiceNumberChange(event) {
        this.invoiceNumber = event.target.value;
    }

    handleInvoiceDateChange(event) {
        this.invoiceDate = event.target.value;
    }

    handleExistingSecurityStrengthSelect(event) {
        this.selectedExistingSecurityStrength = event.detail.value;
    }

    handleProposedSecurityStrengthSelect(event) {
        this.selectedProposedSecurityStrength = event.detail.value;
    }

    handleEntryPointSelect(event) {
        this.selectedEntryPoint = event.detail.value;
    }

    handleCompetitionReplacedSelect(event) {
        this.selectedCompetitionReplaced = event.detail.value;
    }

    connectedCallback() {
        // Call the Apex method to check for "Locks" business unit
        this.checkForLocks();
    }

    checkForLocks() {
        isLocksBusinessUnit({ workOrderLineItemId: this.recordId })
            .then(result => {
                console.log('result00>' + result);
                this.isLocks = result;
                // Do something with the result, like update UI
            })
            .catch(error => {
                console.error('Error fetching Locks business unit', error);
            });
    }


    createLead() {
        createLead({
            selectedProductId: this.selectedProductId,
            quantity: this.quantity,
            finalSalePrice: this.finalSalePrice,
            preferredTime: this.selectedPreferredTime,
            billToLocation: this.selectedBillToLocation,
            shipToLocation: this.selectedShipToLocation,
            externalMaterialPurchase: this.externalMaterialPurchase,
            invoiceNumber: this.invoiceNumber,
            invoiceDate: this.invoiceDate,
            existingSecurityStrength: this.selectedExistingSecurityStrength,
            proposedSecurityStrength: this.selectedProposedSecurityStrength,
            entryPoint: this.selectedEntryPoint,
            competitionReplaced: this.selectedCompetitionReplaced,
            recordId:this.recordId
        })
        .then(result => {
            this.showToast('Success', result, 'success');
            this.resetForm();
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

    resetForm() {
        this.selectedProductId = null;
        //this.productName = null;
        this.quantity = null;
        this.finalSalePrice = null;
        this.selectedPreferredTime = null;
        this.selectedBillToLocation = null;
        this.selectedShipToLocation = null;
        this.externalMaterialPurchase = false;
        this.invoiceNumber = null;
        this.invoiceDate = null;
        this.selectedExistingSecurityStrength = null;
        this.selectedProposedSecurityStrength = null;
        this.selectedEntryPoint = null;
        this.selectedCompetitionReplaced = null;
    }
}