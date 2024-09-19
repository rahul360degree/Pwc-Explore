import { LightningElement,api,wire,track } from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import getaddress from '@salesforce/apex/startVisithandler.getaddress';

const FIELDS = [
    'Visit__c.Account__c',
    'Visit__c.Account__r.Name',
    'Visit__c.Account__r.BillingStreet',
    'Visit__c.Account__r.BillingState',
    'Visit__c.Account__r.BillingCity',
    'Visit__c.Account__r.BillingPostalCode',
    'Visit__c.Account__r.BillingCountry'
];
export default class StartVisit extends LightningElement {
    @api recordId;
    @track accountadd;
    click(){
        if(navigator.geolocation){
            navigator.geolocation.getCurrentPosition(this.success.bind(this),this.error.bind(this));
        }
        else{
            console.log('not supported');
        }
    }
    success(position){
        const latitude = position.coords.latitude;
        const longitude = position.coords.longitude;
        console.log('recordId'+this.recordId);
        console.log('lat'+latitude+', long'+longitude);
        
    }
    error(error){
        console.log('error'+error.message);
    }

    @wire(getaddress, {recordId:'$recordId'})
    wiredaddress({error,data}){
        if(data){
            this.accountadd=data;
            console.log('address'+JSON.stringify(this.accountadd));
        }
        else if(error){
            console.error('error is'+error);
        }
    }
    
}