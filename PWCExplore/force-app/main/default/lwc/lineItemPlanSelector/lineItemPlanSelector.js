import { api, track, LightningElement } from 'lwc';
import getPlanSelectionComponentColumns from '@salesforce/apex/QuoteQALWCController.getPlanSelectionComponentColumns';
import saveSelectedPlans from '@salesforce/apex/QuoteQALWCController.saveSelectedPlans';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getAllPlansForLineItem from '@salesforce/apex/QuoteQALWCController.getAllPlansForLineItem';

export default class LineItemPlanSelector extends LightningElement {
    @track isModalOpen = false;
    @track planDatatableColumns;
    @track selectedPlanHelpText = "";
    @api benefitFields;
    @track isMobile = false;
    @api quoteId;
    @api selectedAssetId;

    connectedCallback() {
        this.init();
    }

    init() {
        if (FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        getAllPlansForLineItem({ lineItemId: this.quoteId,selectedAssetId : this.selectedAssetId })
            .then((result) => {
                let temp = [];
                for(let i=0;i<result.length;i++) {
                    if(result[i].isSelected){
                        temp.push(result[i].assetBenefit);
                    }
                }
                this.setPlanNameHelpText(temp);
            })
            .catch((error) => {
                console.error(error);
            });

        getPlanSelectionComponentColumns()
            .then((result) => {
                this.planDatatableColumns = result;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    @api
    callToUpdateHelpText(assetId) {
        getAllPlansForLineItem({ lineItemId: this.quoteId,selectedAssetId : assetId })
            .then((result) => {
                let temp = [];
                for(let i=0;i<result.length;i++) {
                    if(result[i].isSelected){
                        temp.push(result[i].assetBenefit);
                    }
                }
                this.setPlanNameHelpText(temp);
            })
            .catch((error) => {
                console.error(error);
            });
    }

    closeModal() {
        this.isModalOpen = false;
    }

    checkIfModalCanBeOpened() {
        this.dispatchEvent(
            new CustomEvent('checkasset'),
        );
    }

    @api
    openModal() {
        this.isModalOpen = true;
    }


    handleSave() {
        let selectedPlans = [];
        if(this.isMobile) {
            selectedPlans = this.template.querySelector('c-plan-selection-cards').getSelectedRows();
        } else {
            selectedPlans = this.template.querySelector('c-plan-selection-table').getSelectedRows();
        }
        
        let isPlanSelectionInvalid = this.validatePlansSelected(selectedPlans);
        if(isPlanSelectionInvalid === false) {
            saveSelectedPlans({plansSelected : selectedPlans,lineItemId : this.quoteId,assetId : this.selectedAssetId})
            .then((result) => {
                this.setPlanNameHelpText(selectedPlans);
                this.closeModal();
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: error.body.message,
                        variant: "Error",
                    }),
                );
            })
        } else {
            this.showError();
        }
    }

    showError() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Error",
                message: "Only 1 Basic plan can be selected",
                variant: "Error",
            }),
        );
    }

    validatePlansSelected(selectedPlans) {
        let isBasicPlanFound = false;
        let showError = false;
        if (selectedPlans && selectedPlans.length > 0) {
            for (let i = 0; i < selectedPlans.length; i++) {
                if (selectedPlans[i].Plan_Type__c === "Basic" || (selectedPlans[i].Plan__r && selectedPlans[i].Plan__r.Plan_Type__c === "Basic")) {
                    if (isBasicPlanFound === false) {
                        isBasicPlanFound = true;
                    } else {
                        showError = true;
                        break;
                    }
                }
            }
        }
        return showError;
    }

    setPlanNameHelpText(selectedPlans) {
        this.selectedPlanHelpText = "";
        if (selectedPlans && selectedPlans.length > 0) {
            for (let i = 0; i < selectedPlans.length; i++) {
                if (selectedPlans[i].Quote_Line_Item__c) {
                    this.selectedPlanHelpText += selectedPlans[i].Plan__r.Name + ',';
                } else {
                    this.selectedPlanHelpText +=  selectedPlans[i].Name + ',';
                }
            }
            this.selectedPlanHelpText = this.selectedPlanHelpText.replace(/,\s*$/, "");
        } else {
            this.selectedPlanHelpText = "None";
        }
    }
		@api
    getselectedPlanHelpText(){
        console.log('lineitemselector:: '+this.selectedPlanHelpText);
        return this.selectedPlanHelpText;
    }
}