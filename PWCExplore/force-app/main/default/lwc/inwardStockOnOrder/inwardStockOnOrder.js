import { LightningElement,wire,api } from 'lwc';
import isWorkOrderExistOnAccount from '@salesforce/apex/InwardstockOnOrderHandler.getOrderItemData';
import {CurrentPageReference} from 'lightning/navigation';

const fields = [{ label: 'Order Item No.', fieldName: 'OrderItemNumber'},
                {label: 'Item Code', fieldName: 'Item_Code__c'},
                {label: 'Item Description', fieldName: 'ProductName'},
                {label: 'Category', fieldName: 'Category', editable: true,},
                {label: 'Claimed Quantity', fieldName: 'Claimed Quantity', editable: true,},
                {label: 'Delivery Quantity', fieldName: 'Delivery Quantity', editable: true,},
                {label: 'Spare Status', fieldName: 'Spare Status', editable: true,},
            ];
export default class InwardStockOnOrder extends LightningElement {
    @api recordId;
    columns = fields;
    records;

    constructor(){
        super();
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if(currentPageReference.state.recordId != undefined) {
                this.recordId = currentPageReference.state.recordId;
            } else {
                this.recordId = currentPageReference.attributes.recordId;
            }
        }
    }

    async connectedCallback() {
        console.log('Working');
        console.log(this.recordId);
        const data = await isWorkOrderExistOnAccount({orderId: this.recordId});
        console.log(JSON.stringify(data));
        this.records = data.map(row => ({ ...row, ProductName: row.Product2.Name }));
    }

    handleSave(event) {

    }
}