/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-30-2024
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-06-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, track, api, wire } from 'lwc';
import fetchAllAdvancedPayment from '@salesforce/apex/AppliancesAdvancedPayment.getAdvancedPayment';
import fetchCurrentAdvancedPayment from '@salesforce/apex/AppliancesAdvancedPayment.getCurrentAdvancedPayment';
import callupdateAdvancedPayment from '@salesforce/apex/AppliancesAdvancedPayment.updateAdvancedPayment';
import backendStatusCheckJob from '@salesforce/apex/AppliancesAdvancedPayment.backendStatusCheckJob';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { registerRefreshHandler, unregisterRefreshHandler } from "lightning/refresh";

export default class AppliancesEzetapPayment extends NavigationMixin(LightningElement) {
    @api recordId; //Order or AdvancedPayment ID
    @track displayScreen = { createAdPMT: false, createQR: false, showResponse: false, checkStatus: false };
    pendingAmount; // calculate remaining Amount
    paymentRecordId; //Created Advanced Payment Id

    calloutParams = { calloutType: '', externalRefrenceNo: '', jsonPart: '' } // type=> createQR / CheckStatus
    hidecss = 'slds-hide';
    hideSpinner = false;
    @track apiResponse;
    externalRefNumber = '';
    expiryTime = 2; //Keep maximum 10 min
    
    hideAllForm = true;
    displayMessage = 'Loading...';

    connectedCallback() {
        let screenType = 'createAdPMT';
        if (this.recordId.startsWith('a07')) {
            screenType = 'checkStatus';
            this.paymentRecordId = this.recordId;
        }
        this.setDisplayScreenValue(screenType);


        if (screenType === 'createAdPMT') {
            this.getPendingAmount();//Fetch all ADP for the Order
        }
        else if (screenType === 'checkStatus') {
            //Go to step 8
            this.getCurrentAdvancedPayment();//Fetch specific ADP Record
        }
    }

    //Step 1: Identify the action/screen type
    setDisplayScreenValue(screenType) {
        if (this.displayScreen && screenType !== 'checkStatus') {
            for (let key of Object.keys(this.displayScreen)) {
                this.displayScreen[key] = false;
            }
        }
        this.displayScreen[screenType] = true;
    }



    // Step 2: Fetch remianing payment 
    getPendingAmount() {
        fetchAllAdvancedPayment({ recordId: this.recordId })
            .then(data => {
                if (data || data===0) {
                    this.pendingAmount = data;
                    if(data != 0){
                        this.hideAllForm = false;
                    }else{
                        this.displayMessage = 'No Pending Amount Found';
                    }
                }
                this.hideSpinner = true;
            })
            .catch(error => {
                this.hideSpinner = true;
                console.log(error);
            })
    }

    // Step 3: Set created Advanced PMT Record Id
    handlePMTCreateEvent(event) {
        this.hideSpinner = false;
        this.intiateQRCode(event.detail)
    }

    //Step 4:  Create QR Code
    intiateQRCode(eventData) {
        this.setDisplayScreenValue('createQR');//to hide create payment screen
        this.paymentRecordId = eventData.adPMTId;
        let jsonPart = '"amount": "' + eventData.amount + '" ';
        if (eventData.phone && eventData.phone !== 'null') {
            jsonPart += ','
            jsonPart += '"customerMobileNumber": "' + eventData.phone + '"';
        }
        jsonPart += ','
        if(eventData.selectedPayment =='sms'){
            jsonPart += '"automaticSMSPaymentLinkEnabled": "true"';
            jsonPart += ',';
        }
        jsonPart += '"expiryTime": "' + this.expiryTime + '"';


        this.hidecss = '';
        this.calloutParams.calloutType = 'createQR' // to call child component method
        this.calloutParams.jsonPart = jsonPart;
        this.calloutParams.externalRefrenceNo = '';
    }

    //Step 5.0: After payment generation prepare ADV to update
    handleCalloutResponse(event) {
        console.log(event.detail);
        this.apiResponse = event.detail;


        // if (this.apiResponse.success) {
        if (this.apiResponse) {
            // if (this.apiResponse.success === false && this.apiResponse.errorMessage != '') {
            //     paymentStatus = 'Failed';
            // } 

            if (this.apiResponse && this.apiResponse.externalRefNumber) {
                this.externalRefNumber = this.apiResponse.externalRefNumber;
            }

            // asyn job
            if (this.calloutParams.calloutType == 'createQR') {
                this.createBackgroundJob();
            }

            let record = {
                "sobjectType": "Advance_Payment_Details__c",
                "Reference_Number__c": this.externalRefNumber,
                "Id": this.paymentRecordId,

                "Payment_Error_Message__c": this.apiResponse.errorMessage ? this.apiResponse.errorMessage : '',
                "Payment_Error_Code__c": this.apiResponse.errorCode ? this.apiResponse.errorCode : '',
                "Payment_Message__c": this.apiResponse.message ? this.apiResponse.message : '',

            }

            if (this.apiResponse.customerReceiptUrl) {
                record["Payment_Receipt_Url__c"] = this.apiResponse.customerReceiptUrl;
            }

            if (this.apiResponse.txnId) {
                record["Payment_Transaction_Id__c"] = this.apiResponse.txnId;
            }

            if (this.apiResponse.paymentMode) {
                record["Mode_of_Advance_Payment__c"] = this.apiResponse.paymentMode;
            }

            if (this.apiResponse.states) {
                record["Payment_State__c"] = this.apiResponse.states ? this.apiResponse.states.toString() : '';
            }

            if (this.apiResponse.customerName) {
                record["Paying_Customer_Name__c"] = this.apiResponse.customerName ? this.apiResponse.customerName : '';
            }

            if (this.apiResponse.status) {
                record.Payment_Status__c = this.apiResponse.status;
            } else if (this.calloutParams.calloutType == 'createQR') {
                record.Payment_Status__c = 'Draft';
            } else if (this.calloutParams.errorMessage == 'No transaction records found.') {
                record.Payment_Status__c = 'No Payment Found';
            }

            if (this.apiResponse.paymentLink || this.apiResponse.qrCodeUri) {
                record.Payment_URL__c = this.apiResponse.paymentLink?this.apiResponse.paymentLink:this.apiResponse.qrCodeUri
            }
            


            if (this.apiResponse.cardLastFourDigit) {
                this.Credit_Card_Last_four_digits__c = this.apiResponse.cardLastFourDigit;
            }

            // if(this.calloutParams.calloutType == 'createQR'){
            //     record.Payment_Status__c = 'Draft';
            // }
            this.updateAdvancePayment(record);
        }
    }

    //Step 5.1 //Create Backend Job to check the status
    createBackgroundJob() {
        let jsonPart = this.statusCheck_calloutParams();
        jsonPart.expiryTime = this.expiryTime;
        backendStatusCheckJob(jsonPart)
            .then(data => {
                if (data) {
                    console.log(data);
                }
            })
            .catch(error => {
                console.log(error);
            })
    }
    //Step 6: Update
    updateAdvancePayment(record) {
        console.log(record);
        callupdateAdvancedPayment({ record: record })
            .then(data => {
                if (data) {
                    console.log(data);
                }


                if (this.displayScreen.checkStatus) {
                    // Hide QR display message                        
                    this.dispatchEvent(new CloseActionScreenEvent());
                    // eval("$A.get('e.force:refreshView').fire();");
                    
                }
                eval("$A.get('e.force:refreshView').fire();");
                this.hideSpinner = true;
            })
            .catch(error => {
                console.log(error);
                // this.openPaymentDetailPage();
                this.hideSpinner = true;
            })
    }


    //Step 7.1: check status
    statusCheck_calloutParams() {
        let jsonPart = '"externalRefNumber": "' + this.externalRefNumber + '" ';
        return { calloutType: 'checkStatus', refNumber: this.externalRefNumber, jsonPart: jsonPart };
    }

    //Step 7.2: check status
    checkPaymentStatus() {
        this.hideSpinner = false;
        this.calloutParams = this.statusCheck_calloutParams();
        this.setDisplayScreenValue('checkStatus');
        this.template.querySelector('c-ezetappayment').checkstatus(this.calloutParams);
        this.isCheckStatus = true;
    }


    // Step 8: Fetch current Adv PMT
    getCurrentAdvancedPayment() {
        fetchCurrentAdvancedPayment({ recordId: this.paymentRecordId })
            .then(data => {
                if (data) {
                    this.externalRefNumber = data;
                    this.checkPaymentStatus();
                }
                this.hideSpinner = true;
                this.hideAllForm = false;
            })
            .catch(error => {
                console.log(error);
                this.hideSpinner = true;
                this.hideAllForm = false;
                this.displayMessage = JSON.stringify(error);
            })
    }

    //Step 9:openAdvancedPayment
    openAdvancedPayment(event) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.paymentRecordId,
                objectApiName: 'Advance_Payment_Details__c',
                actionName: 'view'
            }
        }).then(url => {

            window.open(url);
        });
    }

    //Get Event from Child component
    spinnerEventHandler(event) {
        this.hideSpinner = event.detail;
    }

}