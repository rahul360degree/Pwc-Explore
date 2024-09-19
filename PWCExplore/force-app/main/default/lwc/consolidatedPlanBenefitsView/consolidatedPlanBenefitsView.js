import { LightningElement, track, api, wire } from 'lwc';
import getContractBenefitDetails from '@salesforce/apex/ConsolidatedPlanBenefitsViewController.getContractBenefitDetails';
import getAccountBenefitDetails from '@salesforce/apex/ConsolidatedPlanBenefitsViewController.getAccountBenefitDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import recalculateBenefitDetails from '@salesforce/apex/ConsolidatedPlanBenefitsViewController.recalculateBenefitDetails';
import getOverridenBenefitDetails from '@salesforce/apex/ConsolidatedPlanBenefitsViewController.getOverridenBenefitDetails';


export default class ConsolidatedPlanBenefitsView extends LightningElement {
    @api recordId;    
    @track contractBenefitRecords =[];
    @track accountBenefitRecords =[];
    @track overridenBenefitRecords =[];
    @track error;

    connectedCallback(){
        getContractBenefitDetails({ parentRecordId: this.recordId })
            .then(result => {
                this.error = undefined;
                this.contractBenefitRecords = JSON.parse(result);
            })
            .catch(error => {
                this.error = error;
                this.contractBenefitRecords = undefined;
            });

        getAccountBenefitDetails({ parentRecordId: this.recordId })
            .then(result => {
                this.error = undefined;
                this.accountBenefitRecords = JSON.parse(result);
            })
            .catch(error => {
                this.error = error;
                this.accountBenefitRecords = undefined;
            });

        getOverridenBenefitDetails({ parentRecordId: this.recordId })
            .then(result => {
                this.error = undefined;
                this.overridenBenefitRecords = JSON.parse(result);
            })
            .catch(error => {
                this.error = error;
                this.overridenBenefitRecords = undefined;
            });
   } 

    
   handleRecalculate() {
    recalculateBenefitDetails({parentRecordId : this.recordId})
        .then((result) => {
            if(result == true){
                this.connectedCallback();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Plan Benefits recalculated successfully!!",
                        variant: "Success",
                    }),
                )
            } else {
                this.showError();
            }
            
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
    
    }

    showError() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Error",
                message: "Error Occurred during Plan Benefits recalculation",
                variant: "Error",
            }),
        );
    }


}