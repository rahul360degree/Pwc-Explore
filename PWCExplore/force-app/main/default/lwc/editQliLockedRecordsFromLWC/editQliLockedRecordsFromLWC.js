import { LightningElement, api, track } from 'lwc';
import getQLIRecords from '@salesforce/apex/QLILockedRecordsPopulator.fetchQuoteLineItemforLocksB2CISTD';
import updateQLIforLocksB2C from '@salesforce/apex/QLILockedRecordsPopulator.updateQuoteLineItemforLocksB2CISTD';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
 
// columns for datatable
const columns = [
    {label: 'Product',fieldName: 'Product_Name__c',initialWidth: 360}, 
    {label: 'Search Key II',fieldName: 'Search_Key_II_Referenced__c',type: 'number',initialWidth: 170},
    {label: 'Sales Price',fieldName: 'UnitPrice',type: 'currency',initialWidth: 170},
    {label: 'MRP',fieldName: 'MRP__c',type: 'currency',initialWidth: 150},
    {label: 'Quantity',fieldName: 'Quantity',type: 'number',editable: true,initialWidth: 150,typeAttributes: {minimumFractionDigits: 2, maximumFractionDigits: 2}}, 
    {label: 'Discount %',fieldName: 'Discount__c',type: 'number',editable: true,initialWidth: 170,typeAttributes: {minimumFractionDigits: 2, maximumFractionDigits: 2}},
    {label: 'Distributor Retention (in %)',fieldName: 'Distributor_Retention__c', type: 'number',editable: true,initialWidth: 240,typeAttributes: {minimumFractionDigits: 2, maximumFractionDigits: 2}},
    {label: 'Retailer Retention (in %)',fieldName: 'Retailer_Retention__c',type: 'number',editable: true,initialWidth: 240,typeAttributes: {minimumFractionDigits: 2, maximumFractionDigits: 2}},
    {label: 'Trade Discount %',fieldName: 'Trade_Discount_Percent__c',initialWidth: 240,type: "number",typeAttributes: {minimumFractionDigits: 2, maximumFractionDigits: 2}},
    {label: 'Status',fieldName: 'Status__c',type: 'text',initialWidth: 110}

];


export default class EditQliLockedRecordsFromLWC extends LightningElement {
    @api recordId;
    @track columns = columns;
    @track data = null;
    saveDraftValues = [];


    connectedCallback() {
        //To fetch datatable from 
        getQLIRecords({recordId: this.recordId})
        .then(result => {
            this.data = result;
        })
        .catch(error => {
            let message = JSON.stringify(error);
            this.showToast('Error', message);
          });

    }

 
    handleSave(event) {
        this.saveDraftValues = event.detail.draftValues; //To fetch draft values done by User
        this.quoteLineRecords = this.saveDraftValues.slice().map(draft => { //To update changed values entered by User in database
            const fields = Object.assign({}, draft);
            return { fields };
        }); 
        
        //To update Quantity/Discount % / Distributor Retention / Retailer Retention  of QLI Locked  Records of 
        updateQLIforLocksB2C({recordId: this.recordId,qliRecords : JSON.stringify(this.quoteLineRecords)})
        .then(result => {
            console.log('QLI Records updated Successfully');
            this.dispatchEvent(new CustomEvent('close'));
            this.ShowToast('Success', 'Record Updated Successfully','success');
        })
        .catch(error => {
            let message = JSON.stringify(error.body.message);
            console.log('Error message for updateQLI:'  +message);
            this.ShowToast('Error', message,'error');    
          }); 

    }
 
    ShowToast(title, message, variant, mode){
        const evt = new ShowToastEvent({
                title: title,
                message:message,
                variant: variant,
                mode: mode
            });
            this.dispatchEvent(evt);
    }
 
}