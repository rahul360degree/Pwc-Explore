import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import ID_FIELD from "@salesforce/schema/Contact.Id";
import PICKLIST_FIELD from '@salesforce/schema/Contact.Reason_for_Closure__c';
import DETAILED_REASON_FIELD from '@salesforce/schema/Contact.Detailed_reason_for_closure__c';
import STATUS_FIELD from '@salesforce/schema/Contact.Status__c';
import ISACTIVE_FIELD from '@salesforce/schema/Contact.Active__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, updateRecord} from "lightning/uiRecordApi";
import{ShowToastEvent} from 'lightning/platformShowToastEvent';


export default class DeactivateTechBtn extends LightningElement {
    @api recordId;
    @track picklistValues = [];
    @track recordTypeId;
    @track reasonForClosure;
    @track detailedReason;
    disableBtn = true;
    @track display=false;
   

    @wire(getRecord,{ recordId: "$recordId", fields: [ISACTIVE_FIELD] })
    wiredRecord({error,data}){
        if (data) {
            let isActive=data.fields.Active__c.value;
            if(isActive==true){
                this.display=true;
                
            }
            
        } else if (error) {
            console.error('Error fetching contact record:', error);
        }

    }
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    accountObjectInfo({ error, data }) {
        if (data) {
            const recordTypeInfo = Object.values(data.recordTypeInfos).find(rt => rt.name === 'SSG');
            if (recordTypeInfo) {
                this.recordTypeId = recordTypeInfo.recordTypeId;
                console.log('Record Type ==> ' + this.recordTypeId); 

            }
        } else if (error) {
            console.error('Error fetching contact object info:', error);
        }
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
            console.error('Error fetching picklist values:', error);
        }
    }

    handleChange(event){
        this.reasonForClosure = event.detail.value;
        
    }
    handleDetailedReasonChange(event){
        this.detailedReason=event.detail.value;
        this.validateInputs();
    }
    validateInputs() {
        this.disableBtn = [this.detailedReason].some(value => !value)
      }
    async handleSave(event){
        console.log("recId",this.recordId);
        let statusFieldValue = 'Deactivation Initiated';
        
        const fields = {};


        fields[PICKLIST_FIELD.fieldApiName] = this.reasonForClosure;
        fields[DETAILED_REASON_FIELD.fieldApiName]=this.detailedReason;
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = statusFieldValue;
            
        const recordInput = {
            fields: fields
        };
       await updateRecord(recordInput)
                .then(() => {
                    console.log("updated");
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Success',
                        message:'Record updated successfully',
                        variant:'success'
                    })
                );
            })
            .catch(error =>{
                console.log('Errorhere->',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Error updating record',
                        message:error.body.message,
                        variant:'error'
                    })
                )
            });
         this.closeButton();
    }
    closeButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}