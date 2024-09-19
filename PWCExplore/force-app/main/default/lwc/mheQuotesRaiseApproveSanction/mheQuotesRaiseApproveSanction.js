/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 02-23-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api, track, wire } from 'lwc';
//import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const userPersonaSales = 'Sales';
const userPersonaHead = 'Head';
const userPersonaCPT = 'CPT';

export default class MheQuotesRaiseApproveSanction extends LightningElement {
    @api record = {};// input attribute from the flow
    @track recordToDisplay = {}; // Attribute to display input on page
    @api updateRecord; // output attribute used for flow to update quote
    
    /** boolean variables for the userpersona */
    @track isSales;
    @track isHead;
    @track isCPT;
    @api userPersona = '';

    @track options; // drop-down menu
    
    @api headPendingText =''; // email template text for Head
    @api cptPendingText =''; // email template text for CPT
    
    @api
    get disableSPApproval() {
        return this.isCPT ? false : true
    }

    @api get displayForSales_AND_Head() {
        return this.isSales || this.isHead ? true : false;
    }

    connectedCallback() {
        this.isSales = false;
        this.isHead = false;
        this.isCPT = false;

        if (this.userPersona == userPersonaSales) {  // after adding userPersonaSales, picklist is not able to see
            this.isSales = true;
        } else if (this.userPersona == userPersonaHead) {
            this.isHead = true;
        } else if (this.userPersona == userPersonaCPT) {
            this.isCPT = true;
        }
        if (this.isSales) {
            this.options = [
                { label: 'None', value: '' },
                { label: 'Requested', value: 'Requested' },
                { label: 'Approved', value: 'Approved' },
                { label: 'Rejected', value: 'Rejected' },
            ];
        }
        else if (this.isHead) {
            this.options = [
                { label: 'Requested', value: 'Requested' },
                { label: 'Approved', value: 'Approved' },
                { label: 'Rejected', value: 'Rejected' },
            ];
        }
        this.record = Object.assign({}, this.record);
        this.recordToDisplay = Object.assign({}, this.record);

    }


    salesPersonaHelper(key, value) {
        if (key == 'LD_Request_Comments__c' || key == 'CT_Requested_Comments__c' || key == 'Special_Remarks_Requested__c') {
            //identify Approval comment field and checkbox field
            let approvalCommentsKey = '', checkboxKey = '';
            if (key == 'LD_Request_Comments__c') {
                approvalCommentsKey = 'LD_Approver_Comments__c';
                checkboxKey = 'LD_Applicable__c';
            } else if (key == 'CT_Requested_Comments__c') {
                approvalCommentsKey = 'CT_Approver_Comments__c';
                checkboxKey = 'Credit_Terms__c';
            } else if (key == 'Special_Remarks_Requested__c') {
                approvalCommentsKey = 'Special_Remarks_Approver__c';
                checkboxKey = 'Special_Delivery_Period__c';
            }

            if (value == '' || typeof (value) == undefined) {//Remove the sanction request
                this.recordToDisplay[approvalCommentsKey] = '';
                this.recordToDisplay[checkboxKey] = false;
            }
            else if (value == this.record[key]) {//Ctrl-z revert user's input
                this.recordToDisplay[approvalCommentsKey] = this.record[approvalCommentsKey];
                this.recordToDisplay[checkboxKey] = this.record[checkboxKey];
            } else { // Raise the sanction
                this.recordToDisplay[approvalCommentsKey] = '';//delete the comments as new  request comment has been added
                this.recordToDisplay[checkboxKey] = true;
            }
        }
    }

    headPersonaHelper(key, value) {
        let checkboxKey = '';
        if (key == 'LD_Approver_Comments__c') {
            checkboxKey = 'LD_Applicable__c';
        } else if (key == 'CT_Approver_Comments__c') {
            checkboxKey = 'Credit_Terms__c';
        }
        this.recordToDisplay[checkboxKey] = false; //After approval remove from pending
    }

    cptPersonaHelper(key, value) {
        let checkboxKey = '';
        if (key == 'Special_Remarks_Approver__c') {
            checkboxKey = 'Special_Delivery_Period__c';
        }
        this.recordToDisplay[checkboxKey] = false; //After approval remove from pending
    }

    handleChange(event) {
        let key = event.currentTarget.dataset.id;
        let value = event.detail.value;

        this.recordToDisplay[key] = value;// Assign the new value
        //Perform action as per logged in User
        if (this.userPersona == userPersonaSales) {
            this.salesPersonaHelper(key, value);
        } else if (this.userPersona == userPersonaHead) {
            this.headPersonaHelper(key, value);
        } else if (this.userPersona == userPersonaCPT) {
            this.cptPersonaHelper(key, value);
        }

        this.updateRecord = this.recordToDisplay; // Assign value to output variable.
        this.prepareEmailTextHelper(); // Email text head and CPT users
    }

    // prepare email text for Sales User changes.
    prepareEmailTextHelper() {
        if (this.isSales) {
            this.headPendingText = '';
            this.cptPendingText = '';
            if (
                (this.record.BG_Status__c != 'Requested' && this.updateRecord.BG_Status__c == 'Requested')
                || (this.record.CG_Status__c != 'Requested' && this.updateRecord.CG_Status__c == 'Requested')
                || (this.updateRecord.LD_Applicable__c && (this.updateRecord.LD_Request_Comments__c != this.record.LD_Request_Comments__c ) )
                || (this.updateRecord.Credit_Terms__c && (this.updateRecord.Credit_Terms__c != this.record.Credit_Terms__c ) )
            ) {
                if (this.updateRecord.BG_Status__c == 'Requested') {
                    this.headPendingText += '<b>Bank Gaurantee Sanction:</b> ' + this.updateRecord.BG_Status__c + '<br/>';
                }

                if (this.updateRecord.CG_Status__c == 'Requested') {
                    this.headPendingText += '<b>Corporate Gaurantee Sanction:</b> ' + this.updateRecord.CG_Status__c + '<br/>';
                }

                if (this.updateRecord.LD_Applicable__c) {
                    this.headPendingText += '<b>Liquidity Damage Requested Comments:</b> ' + this.updateRecord.LD_Request_Comments__c + '<br/>';
                }
                if (this.updateRecord.Credit_Terms__c) {
                    this.headPendingText += '<b>Credit Terms Requested Comments:</b> ' + this.updateRecord.CT_Requested_Comments__c + '<br/>';
                }

            }

            if(this.updateRecord.Special_Delivery_Period__c && (this.updateRecord.Special_Remarks_Requested__c != this.record.Special_Remarks_Requested__c )){
                
                this.cptPendingText += '<b>Special Delivery Requested Comments:</b> ' + this.updateRecord.Special_Remarks_Requested__c + '<br/>';
            }
        }


    }



    handlePicklistChange(event) {
        let value = event.target.value;
        
        this.updateRecord = this.recordToDisplay;
        this.prepareEmailTextHelper();
        if (this.userPersona == userPersonaSales) {  // after adding userPersonaSales, picklist is not able to see
             if(value == 'Approved' || value == 'Rejected'){
                this.displayToast('error','You are not allowed to select Approved and Rejected value');
                this.recordToDisplay[event.currentTarget.dataset.id] = this.record[event.currentTarget.dataset.id];
             }else{
                this.recordToDisplay[event.currentTarget.dataset.id] = value;
             }
        } else if (this.userPersona == userPersonaHead) {
            if(value == 'Requested'){
                this.displayToast('error','You are not allowed to select Requested value');
                this.recordToDisplay[event.currentTarget.dataset.id] = this.record[event.currentTarget.dataset.id];
             }else{
                this.recordToDisplay[event.currentTarget.dataset.id] = value;
             }
        } 
    }




    displayToast(type,message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: type,
                message: message,
                variant: type
            })
        );
    }

}