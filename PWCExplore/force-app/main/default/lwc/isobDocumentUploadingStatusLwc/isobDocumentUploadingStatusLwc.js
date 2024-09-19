import { LightningElement,track,api,wire } from 'lwc';
import getOrderSpecification from '@salesforce/apex/IsobController.getOrderSpecificationDetails'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class IsobDocumentUploadingStatusLwc extends LightningElement {   
	@api recordId; 
    @api OrderSpecificationrecordId;
    @track pendingCount = 0;

   @wire(getOrderSpecification, { OrderId: '$recordId' })
    wiredOrdSpc({ data, error }) {       
        if (data) {           
            this.OrderSpecificationrecordId = data;
			
        } else if (error) {           
            console.log('error :' + JSON.stringify(error));
        }
    }

    handleChange(event){ 
				this.pendingCount = 0;
				const inputPickVals = this.template.querySelectorAll('.input-container .lightning-input');				
				inputPickVals.forEach((inputPickVal, index)=>{
								//const fieldName = 'input' + (index + 1);								
								if(inputPickVal.value === 'Pending'){
										this.pendingCount++;										
								}
						})
    }

	showSuccessMessage(){
	    const toastEvent = new ShowToastEvent({
			title : 'Success',
			message : 'Attachment Status Updated Successfully',
			variant : 'success'
		});
		this.dispatchEvent(toastEvent);
	}	
	handleclick(){
			this.showSuccessMessage();
	}
		
}