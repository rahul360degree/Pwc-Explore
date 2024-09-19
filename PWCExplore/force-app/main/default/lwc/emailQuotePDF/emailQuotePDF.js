/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 02-02-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   02-02-2024   Varun Rajpoot   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePDF from '@salesforce/apex/EmailQuotePDFCtrl.generateQuotePDF';
import getTemplateIds from '@salesforce/apex/EmailQuotePDFCtrl.getQuoteTemplateIds';
import cannotGeneratePDF from '@salesforce/label/c.Quote_PDF_Error';

export default class EmailQuotePDF extends LightningElement {
    @api recordId;

    @track error = '';
    @track optionsList = [];
    @track internalOptionsList = [];
    @track hasTemplates;

    @track isLoading = true;
    @track value;
    
    connectedCallback() {
        console.log('Hi 1');
        this.isLoading = true;
        getTemplateIds({
            recordId : this.recordId
        })
        .then(result => {
            this.isLoading = false;
            if (result === null) {
                this.hasTemplates = false;
                this.error = cannotGeneratePDF;
            } else {
                for (let each in result) {
                    if (this.value == undefined) {
                        this.value = result[each].value;
                    }
                    this.internalOptionsList.push({
                        label: result[each].label,
                        value: result[each].value
                    });
                }
                this.optionsList = this.internalOptionsList;
                this.hasTemplates = true;
            }
        })
        .catch(error => {
            this.isLoading = false;
            this.error = error;
        });
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    saveToQuote(){
        console.log('Hi 2');
        this.isLoading = true;
        generatePDF({
            recordId : this.recordId,
            templateId: this.value
        })
        .then(result => {
            this.isLoading = false;
            const closePopup = new CustomEvent('close');
            // Dispatches the event.
            this.dispatchEvent(closePopup);
        })
        .catch(error => {
            this.isLoading = false;
            this.error = error;
        });
    }
}