import { LightningElement, wire } from 'lwc';
import getLeadRecordTypeId from '@salesforce/apex/parentAccountSearchController.getLeadRecordTypeId';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getContacts from '@salesforce/apex/parentAccountSearchController.getContacts';
import fetchContactDetails from '@salesforce/apex/parentAccountSearchController.fetchContactDetails';
import { refreshApex } from '@salesforce/apex';


import getIpcAccounts from '@salesforce/apex/parentAccountSearchController.getIpcAccounts';
import createNewLeadRecord from '@salesforce/apex/parentAccountSearchController.createNewLeadRecord';


import fetchContactIpc from '@salesforce/apex/parentAccountSearchController.fetchContactIpc';
import createNewContactIpcRecord from '@salesforce/apex/parentAccountSearchController.createNewContactIpcRecord';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';



import LEAD_OBJECT from '@salesforce/schema/Lead';
import LEAD_SOURCE from '@salesforce/schema/Lead.Lead_Source__c';


let i = 0;

export default class CreateLead extends NavigationMixin(LightningElement) {

    isshow = false;
    accountName = '';
    accountList = [];
    accountId;
    messageResult = false;
    contactPresent = false;
    isShowResult = true;
    showSearchedValues = false;
    accountNameIpc = '';
    accountListIpc = [];
    accountIdIpc;
    messageResultIpc = false;
    contactPresentIpc = false;
    isShowResultIpc = true;
    showSearchedValuesIpc = false;
    parentAccountName;
    error = false;
    pickIpcSource = false;
    ipcError = false;
    contactError = false;
    ipcContactError = false;
    leadRecordTypeId = '';
    childAccounts = [];
    childAccountsData;
    childAccountValue = '';
    contactMobile;
    contactEmail;
    messageResult1 = false;
    showSearchedValues1 = false;
    showContactValues;
    contactValue;
    contactValueIpc = '';
    leadSource;
    ipcBool = false;
    createContactBool = true;
    contactListIpc = [];
    messageResultContactIpc = false;
    ipccontactId;
    isshow2 = false;
    isshow1 = false;
    accountId1;
    accountName1;
    contactData = [];
    contactList;
    newChildAccount = false;
    plusUseCounter = false;
    showContactDetails = false;
    showContactDetails1 = false;
    addedIpcContactBool = false;
    selectedContact;
    contactValueOld;
    contactMobileOld;
    contactEmailOld;
    cList = [];
    firstName;
    lastName;
    mobileNumber;
    mobileNumberIpc;
    emailIpc;
    location;
    spaceRequired;
    description;
    enteredOptions = {};
    contactIpcDetails = {};
    contactObjectList;
    contactIdIpc;
    isLoading;
    noContactMessage = false;
    hideContact = false;


    //handler to fetch the Child Account Details using SearchComponent/SearchController 
    lookupRecord(event) {


        if (event.detail.selectedRecord != undefined) {
            this.accountList = JSON.stringify(event.detail.selectedRecord);
            this.parentAccountName = event.detail.selectedRecord.Name;
            this.accountId = event.detail.selectedRecord.Id;
            this.noContactMessage = false;
            this.hideContact = false;


            //method to fetch contacts present under the selected child account 
            getContacts({ childAcountId: this.accountId })
                .then(result => {
                    this.showContactValues = true;
                    if (result.length > 0) {
                        this.noContactMessage = false;
                        this.contactData = result;
                        this.contactList = [];
                        for (i = 0; i < result.length; i++) {

                            this.contactList = [...this.contactList, { value: result[i].Id, label: result[i].Name }];
                        }
                    }
                    else {
                        if (this.parentAccountName == 'UNDISCLOSED CUSTOMER') {
                            this.hideContact = true;
                            //this.noContactMessage = false;
                        }
                        else {
                            this.noContactMessage = true;
                        }
                    }
                })
                .catch(error => {
                    this.showContactValues = false;
                });
        }
        else {
            this.accountList = JSON.stringify(event.detail.selectedRecord);
            this.parentAccountName = null;
            this.accountId = null;
            this.contactList = [];
        }
    }

    //wire method to fetch the Lead B2B Leasing RecordTypeId
    @wire(getLeadRecordTypeId)
    retrieveRecordTypeId({ error, data }) {
        if (data) {
            this.leadRecordTypeId = data;
        }
    }

    // to get the default record type id, if you dont' have any recordtypes then it will get master
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    accountMetadata;

    //get the picklist values for Lead Source from the selected record type id
    @wire(getPicklistValues, { recordTypeId: '$leadRecordTypeId', fieldApiName: LEAD_SOURCE })
    leadSourcePicklist;

    get contactOptions() {
        return this.contactList;
    }

    selectContactHandler(event) {
        this.contactId = event.detail.value;
        this.contactValueOld = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.contactValue = event.target.options.find(opt => opt.value === event.detail.value).label;


        fetchContactDetails({ contactId: this.contactId })
            .then(result => {

                this.contactValue = result[0]['Name'];
                this.contactMobile = result[0]['MobilePhone'];
                this.contactEmail = result[0]['Email'];
                return refreshApex(this.contactList);
            });
    }


    nameHandler(event) {
        this.contactValue = event.detail.value;
    }

    mobileNumberHandler(event) {
        this.contactMobile = event.detail.value;
    }

    emailHandler(event) {
        this.contactEmail = event.detail.value;
    }

    handleClick(event) {
        this.isShowResult = true;
        this.messageResult = false;
    }

    handleKeyChange(event) {
        this.messageResult = false;
        this.accountName = event.target.value;
    }

    handleOpenModal(event) {
        this.isshow = true;
    }

    handleCloseModal(event) {
        this.isshow = false;
    }

    handleSpinner(event) {
        this.isLoading = true;
    }

    handleSuccess(event) {
        this.isShowResult = false;
        this.messageResult = false;
        this.showSearchedValues = false;
        this.isshow = false;
        this.isLoading = false;
        this.accountId = event.detail.id;

        this.accountName = event.detail.fields.Name.value;

        this.lookupChildAccountHandler(this.accountName);

        if (this.accountName == 'UNDISCLOSED CUSTOMER') {
            this.createContactBool = false;
        }
    }

    lookupChildAccountHandler(value) {
        const selectedEvent = new CustomEvent('selectedModal', { detail: this.accountName });
        this.dispatchEvent(selectedEvent);
    }

    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        this.isshow = false;
    }

    selectDeselectAll(event) {
        if (event.target.checked) {
            this.showContactDetails = true;
            this.noContactMessage = false;
        }
        else {
            this.showContactDetails = false;
        }
    }

    leadSourcePicklistHandler(event) {
        this.leadSource = event.detail.value;
        if (this.leadSource != 'IPC' && this.parentAccountName == 'UNDISCLOSED CUSTOMER') {
            this.leadSource = '';
            this.pickIpcSource = true;
            this.messageResultIpc = false;
        }
        else if (this.leadSource == 'IPC') {
            this.ipcBool = true;
            this.error = false;
            this.pickIpcSource = false;
            this.messageResultIpc = false;
            this.messageResultContactIpc = false;
        }
        else {
            this.ipcBool = false;
            this.pickIpcSource = false;
        }
    }

    selectDeselectAll1(event) {
        if (event.target.checked) {
            this.showContactDetails1 = true;
            this.addedIpcContactBool = true;
        }
        else {
            this.showContactDetails1 = false;
            this.addedIpcContactBool = false;
        }
    }

    get contactName() {
        return this.contactName2;
    }

    get mobileNumber() {
        return this.contactMobile2;
    }

    get email() {
        return this.contactEmail2;
    }

    get contactMobile() {
        return this.contactMobile;
    }

    get contactEmail() {
        return this.contactEmail;
    }

    get contactValue() {
        return this.contactValue;
    }

    lastNameHandler(event) {
        this.lastName = event.detail.value;
    }


    handleIpcClick(event) {
        this.isShowResultIpc = true;
        this.messageResultIpc = false;
    }

    handleIpcKeyChange(event) {
        this.messageResultIpc = false;
        this.accountNameIpc = event.target.value;

        getIpcAccounts({ actName: this.accountNameIpc })
            .then(result => {
                if (result) {
                    this.messageResultIpc = false;
                    // TODO: Error handling 

                    if (result.length > 0 && this.isShowResultIpc) {
                        this.accountListIpc = result;
                        this.showSearchedValuesIpc = true;
                        this.messageResultIpc = false;
                    }
                    else if (result.length == 0) {
                        this.accountListIpc = [];
                        this.showSearchedValuesIpc = false;
                        if (this.accountNameIpc != '')
                            this.messageResultIpc = true;
                    }
                }
            })
            .catch(error => {

                // TODO: Data handling
                this.accountIdIpc = '';
                this.accountNameIpc = '';
                this.accountListIpc = [];
                this.showSearchedValuesIpc = false;
                this.messageResultIpc = true;
            });
    }


    handleIpcSelection(event) {
        //Set the parent calendar id
        this.showSearchedValuesIpc = false;
        this.accountIdIpc = event.target.dataset.value;
        //Set the parent calendar label
        if (this.accountIdIpc == '') {
            alert('IPC Account is Required');
        }
        this.accountNameIpc = event.target.dataset.label;

        fetchContactIpc({ accountId: this.accountIdIpc })
            .then(result => {

                this.contactValueIpc = result[0].Name;
                if (result.length == 0) {
                    this.messageResultContactIpc = true;
                }
                this.contactListIpc = [];
                for (i = 0; i < result.length; i++) {

                    this.contactListIpc = [...this.contactListIpc, { value: result[i].Id, label: result[i].Name }];
                }
            })
            .catch(error => {

                this.messageResultContactIpc = true;
            });
    }

    get contactOptionsIpc() {
        if (this.contactListIpc.length == 0) {
            this.messageResultContactIpc = true;
        }
        else {
            this.messageResultContactIpc = false;
        }
        return this.contactListIpc;
    }

    selectContactHandlerIpc(event) {
        this.contactIdIpc = event.detail.value;
        if (this.contactIdIpc == undefined) {
            alert('IPC Contact is Required');
        }
        this.contactValueIpc = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.messageResultContactIpc = true;
    }

    nameHandlerIpc(event) {
        this.contactValueIpc = event.detail.value;
    }

    mobileNumberHandlerIpc(event) {
        this.mobileNumberIpc = event.detail.value;
    }

    emailHandlerIpc(event) {
        this.emailIpc = event.detail.value;
    }


    locationHandler(event) {
        this.location = event.detail.value;
    }

    spaceRequiredHandler(event) {
        this.spaceRequired = event.detail.value;
    }

    descriptionHandler(event) {
        this.description = event.detail.value;
    }

    get contactValueIpc() {
        return this.contactValueIpc;
    }

    createIpcContactHandler(event) {
        this.contactIdIpc = event.detail.value;
        this.isLoading = true;
        this.ipcContactError = false;
        this.showContactDetails1 = false;
        this.messageResultContactIpc = false;

        this.contactIpcDetails = {
            updatedAccountIdIpc: this.accountIdIpc,
            updatedContactNameIpc: this.contactValueIpc,
            updatedContactMobileIpc: this.mobileNumberIpc,
            updatedContactEmailIpc: this.emailIpc,
        }

        createNewContactIpcRecord({ contactFieldDetails: this.contactIpcDetails })
            .then(result => {
                if (result.length == 0) {
                    this.isLoading = false;
                    this.ipcContactError = true;
                    this.contactIdIpc = result[0].Id;
                } else {
                    this.isLoading = true;
                    this.ipcContactError = false;
                    this.contactIdIpc = result[0].Id;
                }

            })
            .catch(error => {
                this.isLoading = false;
            });
    }

    createLeadHandler() {

        this.enteredOptions = {
            updatedContactOld: this.contactId,
            updatedParentAccountId: this.accountId,
            updatedParentAccountName: this.parentAccountName,
            updatedAccountId: this.accountId,
            updatedAccountName: this.parentAccountName,
            addedAccountName: this.accountName,
            updatedLocation: this.location,
            updatedSpaceRequired: this.spaceRequired,
            updatedMobileNumber: this.contactMobile,
            updatedName: this.contactValue,
            updatedEmail: this.contactEmail,
            updatedFirstName: this.firstName,
            updatedLastName: this.lastName,
            updatedDescription: this.description,
            updatedLeadSource: this.leadSource,
            updatedAccountIpc: this.accountIdIpc,
            updatedContactIdIpc: this.contactIdIpc,
            updatedContactValueIpc: this.ipccontactId,
            updatedContactNameIpc: this.contactValueIpc
        };

        this.error = false;
        this.ipcError = false;
        this.contactError = false;
        this.ipcContactError = false;
        if (this.leadSource != 'IPC') {
            if ((this.contactValue == '') || (this.contactValue == null)) {
                this.error = true;
                this.contactError = true;

            }
        }
        if (this.leadSource == 'IPC') {
            if ((this.accountIdIpc == '') || (this.accountIdIpc == null)) {
                this.error = true;
                this.ipcError = true;
            }
            //&& (this.ipccontactId == '') || (this.ipccontactId == null)
            if ((this.contactIdIpc == '') || (this.contactIdIpc == null)) {
                this.error = true;
                this.ipcContactError = true;

            }
        }

        if (this.error == false) {
            createNewLeadRecord({ leadFieldDetails: this.enteredOptions })
                .then(result => {

                    if (result.success) {
                        const toastSuccess = new ShowToastEvent({
                            'title': 'Success',
                            'message': result.message,
                            'variant': 'success'
                        });
                        this.dispatchEvent(toastSuccess);
                        this.navigateToRecordDetail(result.recId);
                        this.closeQuickAction();
                    } else {
                        const toastError = new ShowToastEvent({
                            'title': 'Exception',
                            'message': 'Unable to save the lead:' + result.message,
                            'variant': 'error',
                            'mode': 'sticky'
                        });
                        this.dispatchEvent(toastError);
                    }
                })
                .catch(error => {

                    this.error = 'Unknown error';
                    if (Array.isArray(error.body)) {
                        this.error = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.error = error.body.message;
                    }
                    const toastError = new ShowToastEvent({
                        'title': 'System Exception',
                        'message': 'An unknown exception occurred while creating the lead:' + this.error,
                        'variant': 'error',
                        'mode': 'sticky'
                    });
                    this.dispatchEvent(toastError);
                });
        }

    }
    navigateToRecordDetail(recId) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view'
            }
        });
    }
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

}