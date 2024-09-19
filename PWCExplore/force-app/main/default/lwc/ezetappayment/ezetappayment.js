/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-30-2024
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   11-06-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import makeCallout from '@salesforce/apex/EzetapController.initiatePayment';
// import qrcode from './qrcode.js';
export default class Ezetappayment extends LightningElement {
    @track calloutResponse;
    @api paymentUrl;
    @api calloutParams;
    @api referenceNumber;
    @api displayData;
    calloutType='';
    isCreateQR = false;
    isStatusCheck = false;
    @api expiryTime;
    timer=0;

    connectedCallback() {
        if(this.calloutParams){
            
            if(this.calloutParams.calloutType === 'createQR'){
                this.paymentAPICallout();
                this.referenceNumber = '';
                this.isCreateQR  = true;
                this.timer = (parseInt(this.expiryTime)*60);
            }else if(this.calloutParams.calloutType ==='checkStatus'){
                this.isStatusCheck = true;
                this.checkstatus(this.calloutParams);//verify param
            }
        }
    }

    paymentAPICallout() {
        makeCallout({calloutType:this.calloutParams.calloutType,refNumber:this.calloutParams.externalRefrenceNo,jsonPart:this.calloutParams.jsonPart})
            .then(result => {
                this.calloutResponse = JSON.parse(result);
                if(this.calloutParams.calloutType === 'createQR'){
                    this.displayData = true;
                    this.handleQRCode();
                }
                if(this.calloutResponse && this.calloutResponse.status && this.calloutResponse.status ==='AUTHORIZED'){
                    this.paymentUrl = '';
                }
                this.sendPaymentCreationResponse();
            })
            .catch(error => {
                console.log(error);
            })
    }

    @api
    checkstatus(calloutParams){
        this.calloutParams = calloutParams;
        
        if(this.calloutParams.calloutType === 'createQR'){
            this.isCreateQR  = true;
        }else if(this.calloutParams.calloutType ==='checkStatus'){
            this.isStatusCheck = true;
            
        }
        
       this.paymentAPICallout(this.calloutParams.calloutType);
    }

    //Display QR Code
    handleQRCode() {
        if (this.calloutResponse.success) {
           this.paymentUrl = this.calloutResponse.paymentLink?this.calloutResponse.paymentLink:this.calloutResponse.qrCodeUri;
           console.log(this.paymentUrl);
        }

    }

    //Send Response to container component
    sendPaymentCreationResponse(){
        console.log(this.calloutResponse);
        const valueChange = new CustomEvent("calloutresponse",{
            detail:this.calloutResponse
        })
        this.dispatchEvent(valueChange);
    }


}