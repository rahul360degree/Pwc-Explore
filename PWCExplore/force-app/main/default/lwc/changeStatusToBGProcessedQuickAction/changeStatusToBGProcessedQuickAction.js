import { LightningElement, api,track,wire } from "lwc";
import getAccountRecord from '@salesforce/apex/DeactivateButtonHandler.getAccountRecord';
import updateAccountStatus from '@salesforce/apex/DeactivateButtonHandler.updateAccountStatus';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import profileName from '@salesforce/schema/User.Profile_Name__c';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

export default class ChangeStatusToBGProcessedQuickAction extends LightningElement {
    @api recordId;
    showSpinner = true;
    showError = false;

    @wire(getRecord, { recordId: Id, fields: [UserNameFIELD, userEmailFIELD, profileName ]}) 
    currentUserInfo({error, data}) {
        if(data) {
            if (data.fields.Profile_Name__c.value != 'Appliances Commercial User - Service') {
                this.showError = true;
            }
        } else if (error) {
            this.showMessage(error.body.message, 'Error', 'error');
        }
    }
    @api async invoke () {
        if(!this.showError){
            await getAccountRecord({recordId : this.recordId}).then((record) => {
                if(record.Status__c != 'Deactivation Approved') {
                    this.showMessage("Status must be Deactivation Approved before changing it to BG Processed", 'Error', 'error');
                } else {
                    this.saveRecord();
                }
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.showMessage(error.message, 'Error', 'error');
            })
        } else {
            this.showMessage("You can't change status to BG Processed because you are not a commercial user", 'Error', 'error');
        }
    }

    showMessage(message, title, variant){
        const e = new ShowToastEvent({
                                    title: title,
                                    message: message,
                                    variant: variant,
                        });
        this.showSpinner = false;
        this.dispatchEvent(e);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async saveRecord() {
        await updateAccountStatus({recordId : this.recordId}).then((record) => {
            this.showSpinner = false;
            this.showMessage('Successfully status updated', 'Success', 'success');
        })
        .catch((error) => {
            try {
                this.showMessage(error?.body?.output?.errors[0]?.message, 'Error', 'error');
            } catch(e) {
                this.showMessage(error.body.message, 'Error', 'error');
            }
        })
    }
}