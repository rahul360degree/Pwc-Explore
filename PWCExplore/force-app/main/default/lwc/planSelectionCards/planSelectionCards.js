import { api, LightningElement, track } from 'lwc';
import getAllPlansForLineItem from '@salesforce/apex/QuoteQALWCController.getAllPlansForLineItem';

export default class PlanSelectionCards extends LightningElement {

    @api quoteId;
    @track isLoading;
    @track allPlans;
    @api benefitFields;
    @api assetId;

    connectedCallback() {
        this.isLoading = true;
        getAllPlansForLineItem({ lineItemId: this.quoteId,selectedAssetId : this.assetId })
            .then((result) => {
                this.allPlans = result;
                this.isLoading = false;
            })
            .catch((error) => {
                console.error(error);
                this.isLoading = false;
            });
    }

    @api
    getSelectedRows() {
        let plans = [];
        this.template.querySelectorAll('c-plan-selection-card').forEach(template => {
            if (template.isRowSelected()) {
                plans.push(template.assetBenefit);
            }
        });
        return plans;
    }
}