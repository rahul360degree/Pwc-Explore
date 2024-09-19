import { LightningElement,api,track } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class GetSerialNumbers extends LightningElement {
    @api serialNumbers;
    @track assetSerialNumbers = [];
    @api quantity;

    connectedCallback() {
        if (this.serialNumbers !== undefined && this.serialNumbers !== null && this.serialNumbers !== '') {
            this.assetSerialNumbers = this.serialNumbers.split(';');
            if (this.assetSerialNumbers.length < this.quantity) {
                for (let i = 0; i < this.quantity - this.assetSerialNumbers.length; i++) {
                    this.assetSerialNumbers.push('');
                }
            }
        } else {
            for (let i = 0; i < this.quantity; i++) {
                this.assetSerialNumbers.push('');
            }
        }
    }

    handleSerialNumberChange(event) {
        let allSerialNumbers = [];
        let allValues = this.template.querySelectorAll("lightning-input");
        allValues.forEach(function(element) {
            if (element.value !== undefined) {
                allSerialNumbers.push(element.value);
            }
        }, this);
        this.serialNumbers = allSerialNumbers.join(";");
        const attributeChangeEvent = new FlowAttributeChangeEvent('serialNumbers', this.serialNumbers);
        this.dispatchEvent(attributeChangeEvent);
    }
}