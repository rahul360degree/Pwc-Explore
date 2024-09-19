import { api, track, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getQuoteLineItemsFromQuoteRecId from '@salesforce/apex/QuoteQALWCController.getQuoteLineItemsFromQuoteRecId';
import saveQuoteLineItems from '@salesforce/apex/QuoteQALWCController.saveQuoteLineItems';
import FORM_FACTOR from '@salesforce/client/formFactor';
import isQuoteFinalized from '@salesforce/apex/QuoteQALWCController.isQuoteFinalized';
import finalizeQ from '@salesforce/apex/QuoteQALWCController.finalizeQuote';
import addDefaultPlan from '@salesforce/apex/QuoteQALWCController.addDefaultBenefits';
import handleCancel from '@salesforce/apex/QuoteQALWCController.handleCancel';
import finalizedQuoteMessage from '@salesforce/label/c.QuoteIsFinalized';
import assetNotPopulatedMessage from '@salesforce/label/c.Asset_not_populated_for_QLI';
import someRecordsHaveErrors from '@salesforce/label/c.Some_records_have_errors';
import gsc_buttonLabel from '@salesforce/label/c.Generate_Service_Contract_button';
export default class QuoteQAAssetAndPlan extends NavigationMixin(LightningElement) {
    @api recordId;
    @track quoteLineItems;
    @track showSpinner = false;
    @track isMobile = false;
    @track showGSC = false;
    @track isFinalized = false;
    @track isReset = false;
    @track isGcClicked =false;
    errorData = null;
    lineItemVSselectedAssetMap = new Map();
    selectedAssetIdVSselectedAssetName = new Map();
    // Expose the labels to use in the template.
    label = {
        finalizedQuoteMessage,
        gsc_buttonLabel,
        assetNotPopulatedMessage,
        someRecordsHaveErrors
    };
    
    connectedCallback() {
        this.init();
    }
    init() {
        this.showSpinner = true;
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        isQuoteFinalized({quoteId : this.recordId})
        .then((result) => {
            if(result) {
                this.isFinalized = true;
            }
        })
        .catch(error => {
            this.showToast("Error",error.body.message,"Error");
            this.dispatchEvent(new CustomEvent('close'));
        })
        addDefaultPlan({quoteId : this.recordId})
        .then((result) => {
            if(result) {
                this.showToast("Success","Default Plans added","Success");
            }
            getQuoteLineItemsFromQuoteRecId({quoteId : this.recordId})
            .then((result) => {
                this.quoteLineItems = this.parseDataAndUpdateJSON(result);
                this.showSpinner = false;
                if(this.errorData) {
                    this.updateQuoteLineItemsWithErrorDetails(this.errorData);
                }
            })
            .catch((error) => {
                console.error(error);
                this.showToast('Error',error.body.message,'Error');
            });
            //end
        })
        .catch(error => {
            this.showToast("Error",error.body.message,"Error");
            this.dispatchEvent(new CustomEvent('close'));
        })
    }
    renderedCallback() {
        if(this.isReset) {
            this.isReset = false;
        }
    }
    handleRefresh(event) {
        this.showSpinner = true;
        this.quoteLineItems = [];
        console.log('handleRefresh', event);
        this.init();
    }
    parseDataAndUpdateJSON(resultArray) {
        resultArray.forEach(result => {
            result.lineItem.isRecordError = false;
            result.lineItem.errorMessage = null;
        });
        console.log('result', resultArray);
        return resultArray;
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
    getQuoteLineItems() {
        this.lineItemVSselectedAssetMap = new Map();
        this.selectedAssetIdVSselectedAssetName = new Map();
        let quoteLineItems = [];
        if(this.isMobile) {
            let lineItemCards = this.template.querySelector('c-quote-line-item-cards');
            quoteLineItems = lineItemCards.save();
        } else {
            let lineItemTable = this.template.querySelector('c-quote-line-item-table');
            quoteLineItems = lineItemTable.save();
        }
        quoteLineItems.forEach(quoteLineItem => {
           this.lineItemVSselectedAssetMap.set(quoteLineItem.lineItemId, quoteLineItem.selectedAsset);
           this.selectedAssetIdVSselectedAssetName.set(quoteLineItem.selectedAsset, quoteLineItem.selectedAssetName);
        });
        return quoteLineItems;
    }
    updateQuoteLineItemsWithErrorDetails(result) {
        this.errorData = result;
        console.log('result: ', result);
        let tempHolder = this.quoteLineItems;
        tempHolder.forEach(qli => {
            if(result && result[qli.lineItem.Id]) {
                qli.lineItem.isRecordError = true;
                qli.lineItem.errorMessage = result[qli.lineItem.Id];
            }
        });
        this.quoteLineItems = tempHolder;
        console.log('quoteLineItems: ', this.quoteLineItems);
        this.isReset = true;
    }
    save() {
        this.showSpinner = true;
        this.errorData = null;
        let quoteLineItems = this.getQuoteLineItems();
        console.log('quoteLineItems:', quoteLineItems);
        // Update the quoteLineItems with the selectedAssetId and asset Name values, for rerendering purpose
        this.quoteLineItems.forEach(quoteLineItem => {
            if(this.lineItemVSselectedAssetMap.has(quoteLineItem.lineItem.Id)) {
                quoteLineItem.selectedAssetId = this.lineItemVSselectedAssetMap.get(quoteLineItem.lineItem.Id);
                quoteLineItem.selectedAssetName = this.selectedAssetIdVSselectedAssetName.get(quoteLineItem.selectedAssetId);
            }
        });
        saveQuoteLineItems({wrapper : quoteLineItems})
        .then((result) => {
            this.showSpinner = false;
            if(result == 'SUCCESS') {
                this.showToast("Success","Records updated","Success");
                if(this.isGcClicked){
                    this.showGCHandler();
                    this.isGcClicked = false;
                }
                //this.dispatchEvent(new CustomEvent('close'));
            } else {
                this.showToast('Error', this.label.someRecordsHaveErrors, 'error');
                this.updateQuoteLineItemsWithErrorDetails(JSON.parse(result));
                this.isGcClicked = false;

            }
        })
        .catch((error) => {
            this.showSpinner = false;
            this.showToast("Error",error.body.message,"Error");
        });
    }
    cancel(){
        this.showSpinner = true;
        handleCancel({quoteId : this.recordId})
        .then((result) => {
            this.showSpinner = false;
            this.dispatchEvent(new CustomEvent('close'));
        })
        .catch((error) => {
            this.showSpinner = false;
            console.error(error);
        })
    }
    showGC(){   
        if(this.isPlanNone()){
            this.showToast('Error', 'Please select atleast one plan for all the assets', 'error');
            return ;
        } else {
            this.isGcClicked = true;
            this.save();
        }
      }
      showGCHandler(){               
        let quoteLineItems = this.getQuoteLineItems();
        let isAnyQuoteMissingAsset = false;
        for(let i=0; quoteLineItems && i<quoteLineItems.length; i++) {
            if(!quoteLineItems[i].selectedAsset) {
                isAnyQuoteMissingAsset = true;
                break;
            }
        }
        if(isAnyQuoteMissingAsset) {
            this.showToast('Error', this.label.assetNotPopulatedMessage, 'error');
        } else {
            finalizeQ({quoteId : this.recordId})
            .then((result) => {
                if(result) {
                    this.showGSC = true;
                }
            })
            .catch(error => {
                this.showToast("Error",error.body.message,"Error");
                this.dispatchEvent(new CustomEvent('close'));
            });
        }
     }
    @api
    isPlanNone(){    
        return this.template.querySelector('c-quote-line-item-table').getselectedPlanHelpText();
    }
}