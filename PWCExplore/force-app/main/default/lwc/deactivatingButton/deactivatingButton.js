import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import getAccountRecord from '@salesforce/apex/DeactivateButtonHandler.getAccountRecord';
import isWorkOrderExistOnAccount from '@salesforce/apex/DeactivateButtonHandler.isWorkOrderExistOnAccount';
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import ID_FIELD from "@salesforce/schema/Account.Id";
import PICKLIST_FIELD from '@salesforce/schema/Account.Reason_for_Closure__c';
import STATUS_FIELD from '@salesforce/schema/Account.Status__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';


export default class DeactivateButton extends LightningElement {
    @track picklistValues = [];
    @track recordTypeId;
    @track reasonForClosure;
    @track reactiveAccountObjectApiName;
    errorMessage;
    recordId;
    numberofLetters;
    showSpinner = true;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    
    async connectedCallback() {
        await getAccountRecord({recordId : this.recordId}).then((data) =>{
            this.numberofLetters = data.Number_of_Warning_Letters__c;
            if(data.Status__c != "Active") {
                this.showMessage("Status must be active before deactivating ASP", 'Error', 'error');
            }
        })
        .catch((error) => {
            this.showMessage(error.body.message, 'Error', 'error');
        })

        await isWorkOrderExistOnAccount({recordId : this.recordId}).then((data) => {
            if(data === true) {
                this.showMessage("Make sure there will be no active work order assigned to the ASP before deactivation.", 'Error', 'error');
            }
        })
        .catch((error) => {
            this.showMessage(error.body.message, 'Error', 'error');
        })
        this.showSpinner = false;
    }
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT})
    accountObjectInfo({ error, data }) {
        if (data) {
            const recordTypeInfo = Object.values(data.recordTypeInfos).find(rt => rt.name === 'Business Account');
            if (recordTypeInfo) {
                this.recordTypeId = recordTypeInfo.recordTypeId;
            }
        } else if (error) {
            this.showMessage(error.body.message, 'Error', 'error');
        }
    }
    showMessage(message, title, variant){
        const e = new ShowToastEvent({
                                    title: title,
                                    message: message,
                                    variant: variant,
                        });
        this.dispatchEvent(e);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: PICKLIST_FIELD
    })
    picklistValuesWire({ error, data }) {
        if (data) {
            this.picklistValues = data.values;
            if (this.picklistValues.length > 0) {
                this.reasonForClosure = this.picklistValues[0].value;
            }
        } else if (error) {
            this.showMessage(error.body.message, 'Error', 'error');
        }
    }

    handleChange(event){
        this.reasonForClosure = event.detail.value;
    }

    async handleSave(event){
        let statusFieldValue = 'Deactivation Initiated';
        const fields = {};


        fields[PICKLIST_FIELD.fieldApiName] = this.reasonForClosure;
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = statusFieldValue;
            
        const recordInput = {
            fields: fields
        };
        if(this.reasonForClosure == 'Below expectation performance' && (this.numberofLetters == undefined || this.numberofLetters < 2)){
            this.showMessage("There must be at least 2 Number of Warning Letters before deactivating ASP", 'Error', 'error');
        } else {
            this.showSpinner = true;
            await updateRecord(recordInput).then((record) => {
                this.showSpinner = false;
                this.showMessage('Successfully status updated', 'Success', 'success');
            })
            .catch((error) => {
                this.showMessage(error.body.message, 'Error', 'error');
            })
        }
        this.closeButton();
    }
    closeButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleCancel(event){
        this.closeButton();
    }
}