import { api, track, LightningElement } from 'lwc';
import getLineItemColumns from '@salesforce/apex/QuoteQALWCController.getLineItemColumns';
import AssetPlanSelectionTableNumOfRows from '@salesforce/label/c.AssetPlanSelectionTableNumOfRows';

export default class QuoteLineItemTable extends LightningElement {
    @api quoteLineItems;
    @track lineItemColumns = [];
    NUM_OF_ROWS = AssetPlanSelectionTableNumOfRows;
    @track totalPages;
    @track quoteLineItemsToShow;
    @track currentPageNum = 1;
    @track isPreviousButtonDisabled;
    @track isNexButtonDisabled;
    @track isLoading;

    connectedCallback() {
        getLineItemColumns()
        .then((result) => {
            this.lineItemColumns = result;
            this.calculateTotalPages();
        this.showLineItemsForCurrentPage();
        this.evaluateButtonStatus();
        })
        .catch((error) => console.error(error));
        
    }

    evaluateButtonStatus(){
        if(this.currentPageNum < this.totalPages) {
            this.isNexButtonDisabled = false;
        } else {
            this.isNexButtonDisabled = true;
        }
        if(this.currentPageNum == 1 || this.totalPages === 0) {
            this.isPreviousButtonDisabled = true;
        } else {
            this.isPreviousButtonDisabled = false;
        }
    }

    calculateTotalPages(){
        if(this.quoteLineItems.length % this.NUM_OF_ROWS > 0){
            this.totalPages = Math.floor(this.quoteLineItems.length / this.NUM_OF_ROWS) + 1;
        } else {
            this.totalPages = (this.quoteLineItems.length / this.NUM_OF_ROWS);
        }
    }

    showLineItemsForCurrentPage() {
        let startIndex = (this.currentPageNum * this.NUM_OF_ROWS) - this.NUM_OF_ROWS;
        let endIndex = (this.currentPageNum * this.NUM_OF_ROWS) - 1;
        let index = startIndex;
        let temp = [];
        while(index <= endIndex) {
            if(index < this.quoteLineItems.length) {
                temp.push(this.quoteLineItems[index]);
                index++;
            } else {
                break;
            }
        }
        this.quoteLineItemsToShow = temp;
    }

    @api save() {
        let plans = [];
        for(let i = 0; i< this.quoteLineItems.length; i++) {
            let wrapper = {
                lineItemId : this.quoteLineItems[i].lineItem.Id,
                selectedAsset : this.quoteLineItems[i].selectedAssetId,
                selectedAssetName : this.quoteLineItems[i].selectedAssetName
            };
            let planIds = [];
            for(let j = 0;j<this.quoteLineItems[i].plans.length;j++) {
                planIds.push(this.quoteLineItems[i].plans[j].Id);
            }
            wrapper.plans = planIds;
            let objToPush = Object.assign({},wrapper);
            plans.push(objToPush);
        }
        return plans;
    }

    handleNext() {
        this.isLoading = true;
        if(this.currentPageNum < this.totalPages) {
            this.currentPageNum += 1;
            this.showLineItemsForCurrentPage();
            this.evaluateButtonStatus();
        }
        this.isLoading = false;
    }

    handlePrevious() {
        this.isLoading = true;
        if(this.currentPageNum != 1) {
            this.currentPageNum -= 1;
            this.showLineItemsForCurrentPage();
            this.evaluateButtonStatus();
        }
        this.isLoading = false;
    }

    handleRowUpdated(event) {
        let temp = [...this.quoteLineItems];
        for(let i =0; i<temp.length;i++) {
            if(temp[i].lineItem.Id === event.detail.rowwrapper.lineItem.Id) {
                temp[i] = JSON.parse(JSON.stringify(event.detail.rowwrapper));
                break;
            }
        }
        console.log('handleRowUpdated temp', temp);
        this.quoteLineItems = temp;
    }

    handleParentRefresh(event) {
        this.dispatchEvent(new CustomEvent('refreshparent',{detail : {
            isReset : true,
            bubbles: true
        }}));
    }
     @api
    getselectedPlanHelpText(){    
        var helperText = this.template.querySelectorAll('c-quote-line-item-row');
        let isNone=false;
        helperText.forEach(v => {
            if(v.getselectedPlanHelpText()=='None'){
                isNone = true;
                return;
            }
        });
        return isNone;
    }
}