import { api, LightningElement } from 'lwc';

export default class QuoteLineItemCards extends LightningElement {
    @api quoteLineItems; 

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

    handleCardUpdateEvent(event) {
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
}