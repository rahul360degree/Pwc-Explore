/*
@description       : 
@author            : snehalw@godrej.com
@group             : 
@last modified on  : 05-09-2023
@last modified by  : snehalw@godrej.com
*/
import { LightningElement,api,track } from 'lwc';
import getQuotes from '@salesforce/apex/InterioB2BApprovalProcess.quoteList';
import { NavigationMixin } from 'lightning/navigation';
export default class Interiob2bpendingquotes extends NavigationMixin(LightningElement) {
@api records;
@api quoteId;
@track hideSpinner;

connectedCallback(){
this.getQuoteData();
}
getQuoteData(){
getQuotes({})        
.then(result=>{
    this.displayQuoteSection = true;
    this.records = result;
    this.originalRecords = result;
    this.helperHideSpinner();
})
.catch(error=>{
    console.log(error);
    this.helperHideSpinner();
});
}

handleQuoteClick(event){
this.displayQuoteSection = false;
this.quoteId = event.target.dataset.id;
}
closeModal(event){
this.quoteId = null;
this.displayQuoteSection = true;
}

helperHideSpinner(){
this.hideSpinner = true;
}
helperDisplaySpinner(){
this.hideSpinner = false;
}
helperNavigation(event) {
this[NavigationMixin.GenerateUrl]({
    type: "standard__recordPage",
    attributes: {
        recordId: event.currentTarget.dataset.id,
        objectApiName: event.currentTarget.dataset.name,
        actionName: 'view'
    }
}).then(url => {
    window.open(url, "_blank");
});
}
}