/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-30-2024
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-26-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, api, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchPhoneNumbercontactInfo from "@salesforce/apex/AppliancesAdvancedPayment.getPhoneNumber";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import AdvPmt_Object from "@salesforce/schema/Advance_Payment_Details__c";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const paymentOption = [
    { label: 'upi', value: 'upi' },
    { label: 'sms', value: 'sms' },
];
export default class AppliancesAdPmtCreate extends NavigationMixin(LightningElement) {
    @api orderId;
    @api pendingAmount;
    pmtRecord;
    @track phoneNumber;
    isEMI=false;    
    isRemaningAmountZero = true;
    
    paymentOptions = paymentOption;
    selectedPayment = 'upi';
    
    
    // Get Phone Number to display
    @wire(fetchPhoneNumbercontactInfo,{'orderId':'$orderId'})
    coninfo({error,data}){
        if(data){
            this.phoneNumber = data;
        }
    }

    //Get Appliances Record Type
    @wire(getObjectInfo, { objectApiName: AdvPmt_Object })
    objectInfo;
    
    get recordTypeId() {
        const rtIds = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtIds).find((rti) => rtIds[rti].name === "Appliances");
    }

    // Assign Default Values
    assignDefaultValues(event) {
        this.spinnerEvent(false);
        event.preventDefault();       // stop the form from submitting      
        this.spinnerEvent(false);
        const fields = event.detail.fields;
        
        if( parseFloat(fields.Amount__c) > parseFloat(this.pendingAmount)){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Payment Amount can\'t exceed pending amount',
                variant: 'error',
                message: 'Payment Amount can\'t exceed pending amount'
            }));
            this.spinnerEvent(true);
            return;
        }
        
        /*Required Fields*/
        fields.Reference_Number__c = 'EzeTap Requested'; //disscuss
        fields.Bank_Provider_Name__c = 'EzeTap Requested';//disscuss
        fields.Mode_of_Advance_Payment__c = 'EzeTap';
        fields.Bank_Name__c = fields.Bank_Provider_Name__c;
        fields.Credit_Card_Last_four_digits__c = 'NA';//disscuss
        fields.Credit_Debit_Card_Approval_Code__c = 'NA';//disscuss
        fields.Order__c = this.orderId;
        
        //Additonal Fields
        fields.Transaction_Type__c = '328';
        fields.Currency__c = 'INR';
        fields.Transaction_Entry_Date__c = new Date();
        fields.Instrument_date__c = fields.Transaction_Entry_Date__c;
        fields.Payment_Date__c = fields.Transaction_Entry_Date__c;
        //fields.Logistics_Company_Branch__c = user
        //fields.Processing_Fees__c = 
        fields.RecordTypeId = this.recordTypeId;
        fields.Payment_Status__c = this.paymentStatus;

        this.pmtRecord = fields;
        if(!this.isEMI){
            fields.EMI_Vendor__c = '';
            fields.EMI_Scheme__c = '';
            fields.Processing_Fees__c = 0;
            fields.Delivery_Order_Number__c = '';
        }

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    //Check EMI or Normal Transaction.
    handlePaymentModeChange(event){
        this.isEMI = event.target.value === 'EMI'?true:false;
    }
    
    //On Record creation send Advanced Payment record Id to parent Record.
    handleRecordCreationSuccess(event) {        
        this.sendAdvancedPaymentRecordId(event.detail.id);
    }

    // Handle Record Creation error
    handleRecordCreationError(event) {
        this.spinnerEvent(true);
        
    }

    //On Record creation send Advanced Payment record Id to parent Record.
    sendAdvancedPaymentRecordId(recordId) {
        let data = {
            "adPMTId" : recordId,
            "phone" : this.pmtRecord.Phone__c,
            "amount" : parseFloat(this.pmtRecord.Amount__c) + parseFloat(this.pmtRecord.Processing_Fees__c),
            "selectedPayment" : this.selectedPayment
        };
        const cEvt = new CustomEvent("adpmtcreate", {
            detail: data
        })
        this.dispatchEvent(cEvt);
    }

    //Hide display Spinner Event
    spinnerEvent(hideSpinner){
        const cEvt = new CustomEvent("spinnerevent", {
            detail: hideSpinner
        })
        this.dispatchEvent(cEvt);
    }

    handlePaymentChange(event) {
        this.selectedPayment = event.detail.value;
    }
}