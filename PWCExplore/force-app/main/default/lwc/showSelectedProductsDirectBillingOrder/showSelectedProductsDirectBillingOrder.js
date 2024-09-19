import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShowSelectedProductsDirectBillingOrder extends LightningElement {
		@api record;
		@api selectedOptions;
		@api itemCode;
		@api availablequantity;
		@api stockfileid;
		
		@api logisticscompany;
		@api lstOrderProducts = [];
		@api whCode;
		@api arrwhcodes = [];
		
		@track data = [];
		@track orderProduct;
		
		connectedCallback(){
				this.lstOrderProducts = [];
				for(let op of this.record){
						
						this.orderProduct = {
                "Item_Code__c": op.Item_Code__c,
                "Quantity": 0,
                "Warehouse__c": op.Warehouse__c,
                "Stock_File__c": op.Stock_File__c
            };
            
            this.lstOrderProducts.push(this.orderProduct);					
						
				}
				console.log("this.lstOrderProducts " + this.lstOrderProducts);
				
				/*this.lstOrderProducts = [{
								"Product2Id": "P1",
								"Quantity": "10"
						},
						{
								"Product2Id": "P2",
								"Quantity": "20"
						}
				];*/

		}
		
		closeModal(event){
        this.itemCode = null;
    }
		
		handleCheckInventory(event)
		{
				
				this.itemCode = event.target.name;				
				this.whCode = event.target.closest('[data-warehouse]').dataset.warehouse;
				this.availablequantity = event.target.closest('[data-availablequantity]').dataset.availablequantity;
				this.stockfileid = event.target.closest('[data-stockfileid]').dataset.stockfileid;
				console.log("this.availablequantity " + this.availablequantity);
				console.log("this.stockfileid " + this.stockfileid);				
				this.arrwhcodes.length = 0;
				this.arrwhcodes.push(this.whCode);

				
				
		}
		
		handleQuantityChange(event)
		{

			if (parseInt(event.target.value) > parseInt(event.target.closest('[data-availablequantity]').dataset.availablequantity)) {
            event.target.value = "";
            console.log('inside if of handlequanitychange');
            this.showToast('Oops', 'Ordered Quantity cannot be more than Available Quantity', 'error');
						event.target.focus();
        }
				else
						{
								this.updateOrderedQuantity(event.target.value, event.target.name);
						}

		}
		updateOrderedQuantity(enteredQuantity, stockFileId)
		{
				for (let recOrderProduct of this.lstOrderProducts){
						if (recOrderProduct.Stock_File__c == stockFileId)
								{
										recOrderProduct.Quantity = enteredQuantity;
								}
						
				}
		}
		fetchValue( event ) {

        
       this.lstOrderProducts = event.detail;

    }
		
		    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

}