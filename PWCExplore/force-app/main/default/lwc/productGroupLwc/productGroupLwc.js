import { LightningElement,track,api,wire } from 'lwc';
import getProductDetails from '@salesforce/apex/IsobController.getProductSpecifications';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; 
import updateJsonField from '@salesforce/apex/IsobController.updateJsonField';
export default class ProductGroupLwc extends LightningElement {
		@api recordId;
		@api records;		
		@api showButton = undefined;
		@track isDisabled = false;
//Added by pankaj on 12 oct 2023	
productData = [];
  @track readOnly = false;
	@track placeHolderValue = 'Type APO Color';
  @wire(getProductDetails,{recordId:'$recordId'})
		wiredJson({data,error}){		
			
				if(data){						
						this.productData = JSON.parse(data.Product_Attribute__c);	
							
				}		
				if(error){
						alert('error occured');
				}
		}		
		
		handleChekboxChange(event){
				
		}
		
		handleApoColorChange(event){
			
			
			// Find the specific record by its Id
			const productId = event.currentTarget.dataset.product_id;
			const specId = event.target.name;
			const specificationApoColor = event.detail.value;
			console.log("productId-->"+productId);
			console.log("specId-->"+specId);
			console.log("specificationApoColor-->"+specificationApoColor);

			// Find the specific record by its Id
			const recordIndex = this.productData.findIndex(record => record.Id === productId);

			if (recordIndex !== -1) {
				// Find the specific specification within the record
				const specIndex = this.productData[recordIndex].specification.findIndex(spec => spec.Id === specId);

				if (specIndex !== -1) {
					// Update the apoColor for the found specification
					this.productData[recordIndex].specification[specIndex].apoColor = specificationApoColor;
				} 
			} 
			console.log("NewSpecificationApoColor-->"+this.productData[0].specification[0].apoColor);

		
		}
		handleEdit(){
				this.isDisabled = false;
		}
		handleSave(){
				this.isDisabled = true;
				console.log(JSON.stringify(this.productData));
				updateJsonField({recordId : this.recordId, jsonString:JSON.stringify(this.productData)})
				.then(result => {						
						this.showSuccessMessage();
				})
				.catch(error => {
						console.log('error');
				});
		}
		
		connectedCallback(){
				
			const str = this.recordId;
			const firstTwoChars = str.slice(0, 2);
				if(firstTwoChars==='0Q'){
					this.showButton = true;
				}	
				else if(firstTwoChars==='80'){
						this.showButton = false;
						this.isDisabled = true;
				}
		}
		
		showSuccessMessage(){
				const toastEvent = new ShowToastEvent({
						title : 'Success',
						message : 'Product Group has been saved successfully',
						variant : 'success'
				});
				this.dispatchEvent(toastEvent);
		}
}