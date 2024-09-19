import { LightningElement, wire, api } from 'lwc';
import getAccounts from '@salesforce/apex/changeAccountName.getAccounts';
import getContacts from '@salesforce/apex/changeAccountName.getContacts';
import getOpportunityData from '@salesforce/apex/changeAccountName.getOpportunityData';
import updateAccountName from '@salesforce/apex/changeAccountName.updateAccountName';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

let i = 0;

export default class changeAccountName extends LightningElement {

    isshow = false;
    accountName = '';
    accountList = [];
    accountId;
    messageResult = false;
    isShowResult = true;
    showSearchedValues = false;

    isshow1 = false;
    contactName = '';
    contactList = [];
    contactId;
    messageResult1 = false;
    isShowResult1 = true;
    showSearchedValues1 = false;

    oppotunityId;
    accountIdOld;
    reasonForChange;
    contactId;

    lookupRecord(event) {
        alert('Selected Record Value on Parent Component is ' + JSON.stringify(event.detail.selectedRecord));
    }

    @api recordId;

    @wire(getOpportunityData, { oppId: '$recordId' })
    opportunityData({ data, error }) {
        if (data) {

            this.oppotunityId = data[0]['Id'];
            this.accountIdOld = data[0]['AccountId'];
        }
    }

    @wire(getAccounts, { actName: '$accountName' })
    retrieveParentAccounts({ error, data }) {
        this.messageResult = false;
        if (data) {
            // TODO: Error handling 
            if (data.length > 0 && this.isShowResult) {
                this.accountList = data;
                this.showSearchedValues = true;
                this.messageResult = false;
            }
            else if (data.length == 0) {
                this.accountList = [];
                this.showSearchedValues = false;
                if (this.accountName != '')
                    this.messageResult = true;
            }

        } else if (error) {
            // TODO: Data handling
            this.accountId = '';
            this.accountName = '';
            this.accountList = [];
            this.showSearchedValues = false;
            this.messageResult = true;
        }
    }

    handleClick(event) {
        this.isShowResult = true;
        this.messageResult = false;
    }

    handleKeyChange(event) {
        this.messageResult = false;
        this.accountName = event.target.value;
    }

    handleParentSelection(event) {
        this.showSearchedValues = false;
        this.isShowResult = false;
        this.messageResult = false;

        //Set the parent calendar id
        this.accountId = event.target.dataset.value;

        //Set the parent calendar label
        this.accountName = event.target.dataset.label;

        getContacts({ accountId: this.accountId })
            .then((result) => {
                this.messageResult1 = false;
                // TODO: Error handling
                if (result.length > 0 && this.isShowResult1) {
                    for (i = 0; i < result.length; i++) {

                        this.contactList = [...this.contactList, { value: result[i].Id, label: result[i].Name }];
                    }
                    this.showSearchedValues1 = true;
                    this.messageResult1 = false;
                }
                else if (result.length == 0) {
                    this.contactList = [];
                    this.showSearchedValues1 = false;
                    if (this.contactName != '')
                        this.messageResult1 = true;
                }
            })
            .catch(error => {
                // TODO: Data handling
                this.contactId = '';
                this.contactName = '';
                this.contactList = [];
                this.showSearchedValues1 = false;
                this.messageResult1 = true;
            });
    }


    //fetch contact details
    get contactOptions() {
        return this.contactList;
    }

    handleClick1(event) {
        this.isShowResult1 = true;
        this.messageResult1 = false;
        //Set the contact id
        this.contactId = event.detail.value;
        //Set the contact label
        this.contactName = event.detail.label;
    }

    handleKeyChange1(event) {
        this.messageResult1 = false;
        //Set the contact id
        this.contactId = event.detail.value;
        //Set the contact label
        this.contactName = event.detail.label;
    }

    handleParentSelection1(event) {
        this.showSearchedValues1 = false;
        this.isShowResult1 = false;
        this.messageResult1 = false;
    }

    reasonHandler(event) {
        this.reasonForChange = event.detail.value;
    }

    changeAccountNameHandler() {
        updateAccountName({ oppId: this.oppotunityId, accountId: this.accountId, reasonForChange: this.reasonForChange, accountIdOld: this.accountIdOld, contactId: this.contactId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Updated Account Name over Opportunity',
                        variant: 'success'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                const toastError = new ShowToastEvent({
                    'title': 'System Exception',
                    'message': 'An unknown exception occurred while updating Account Name over Opportunity',
                    'variant': 'error',
                    'mode': 'sticky'
                });
                this.dispatchEvent(toastError);
            });
    }

}