import { LightningElement, api, wire, track } from 'lwc';
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import ID_FIELD from "@salesforce/schema/Contact.Id";
import STATUS_FIELD from '@salesforce/schema/Contact.Status__c';
import ISACTIVE_FIELD from '@salesforce/schema/Contact.Active__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, updateRecord} from "lightning/uiRecordApi";
import{ShowToastEvent} from 'lightning/platformShowToastEvent';
import updateContentVersionRecs from '@salesforce/apex/UploadFilesMetaDataController.updateContentVersionRecs';

export default class IssueNOCTechbtn extends LightningElement {

    @api recordId;
    @track picklistValues = [];
    @track recordTypeId;
    @track reasonForClosure;
    @track display=false;
   

    @wire(getRecord,{ recordId: "$recordId", fields: [STATUS_FIELD,ISACTIVE_FIELD] })
    wiredRecord({error,data}){
        if (data) {
            let isActive=data.fields.Active__c.value;
            let status=data.fields.Status__c.value
            if(isActive==true && status=="Deactivation Approved"){
                this.display=true;
                
            }
            
        } else if (error) {
            console.error('Error fetching contact record:', error);
        }

    }

    handleUploadFinished(event){
        console.log("In upload finished");
        const uploadedFiles = event.detail.files;
            let docType = event.target.dataset.doctype;
             console.log("uploadedfiles info",uploadedFiles);
             console.log("uploadedfiles docType",docType);
             console.log("version id?",event.target.dataset);
    
            updateContentVersionRecs({conVerRecIds:uploadedFiles.map(item=>item.contentVersionId), documentType:docType})
            .then(result => {
                console.log("updatemeth done");
                this.updateStatus();
                
            }).catch(error => {
                // console.log("what is in data",data);
            console.log("what is in erroe",error);
                console.log('error---->' + JSON.stringify(error));
            })   
        }
    
    async updateStatus(){
        console.log("recId",this.recordId);
        let statusFieldValue = 'NOC Cleared';
        let active=false;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = statusFieldValue;
        fields[ISACTIVE_FIELD.fieldApiName] = active;   
        const recordInput = {
            fields: fields
        };
       await updateRecord(recordInput)
                .then(() => {
                    console.log("updated");
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Success',
                        message:'Record updated successfully',
                        variant:'success'
                    })
                );
            })
            .catch(error =>{
                console.log('Errorhere->',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Error updating record',
                        message:error.body.message,
                        variant:'error'
                    })
                )
            });
         this.closeButton();
    }
    closeButton(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}