import { LightningElement,api, wire, track } from 'lwc';
import getRelatedInfo from '@salesforce/apex/RMAController.fetchWorkOrderData'

export default class RmaForm extends LightningElement {


    @api recordId;
    @track assetData;
    @track contactData;

    connectedCallback(){
        this.fetchRecord();
    }
   
    fetchRecord(){
        getRelatedInfo({workOrderId:this.recordId})
        .then(result=>{
            console.log('RecordId-->' , this.recordId);
            if(result){
                console.log('Result->' ,JSON.stringify(result));
                this.assetData = {
                    assetId : result.AssetId,
                    productId: result.Asset.Product2Id
                };
                this.contactData = {
                    contactId : result.ContactId,
                    contactName:result.Contact.Name
                };
            }
            console.log('Result->' ,result);
            console.log('ContactDetails->' ,JSON.stringify(this.contactData));
            console.log('ProdudctId--' , JSON.stringify(this.assetData));
        })
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert('No. of files uploaded : ' + uploadedFiles.length);
    }
    
}