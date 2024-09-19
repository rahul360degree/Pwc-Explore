import { LightningElement, track, api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import oneLineItemHasError from '@salesforce/label/c.Selected_quote_item_has_an_error';
import orderQuantityError from '@salesforce/label/c.Order_quantity_error';
import noProductError from '@salesforce/label/c.No_product_error';
import errorMessage from '@salesforce/label/c.Error';
import orderSuccessMessage from '@salesforce/label/c.Order_Record_Created';
import getQuoteDataForOrder from '@salesforce/apex/QuoteManager.getQuoteData';
import createOrder from '@salesforce/apex/QuoteManager.createOrder';
import getOpportunityData from '@salesforce/apex/QuoteManager.getOpportunityData';
import getOrderRecordTypeIdLabel from '@salesforce/apex/QuoteManager.getOrderRecordTypeIdLabel'; 

export default class GenerateCustomOrderLWC extends NavigationMixin(LightningElement) {
data = [];
columns = [];
// For displaying error messages
@track errors = {
    rows: {},
    table: {						
        title: null,
        messages: null
    }
}; 
// For easier retrieval of specific data row on change of any value in that row.
dataMap = new Map();
selectedRows = [];
@track isLoading = true;
@track isMobile = false;

@track hasValidationError;
@api recordId;

@track showAreaCodeScreen = false;
@track isLocksB2CISTDQuote = false;
@track isSSDQuote = false;
@api opportunityRecord;
@track stageName = '';
@track reasonForLost = '';
@track reasonForLostOthers = '';
orderRecordTypeId;

// Function called on load time.
connectedCallback() {
    let isTesting = false;
    
    if(isTesting) {
        this.isMobile = true;
        this.createTestData();
    } else {
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        this.getOpportunityInfo();
    //    this.getProductInfo();
    }
    
}
    
@wire(getOrderRecordTypeIdLabel) 
wiredOrderRecordTypeId({ error, data }) { 
    if (data) { 
        this.orderRecordTypeId = data; 
    } 
    else if (error) { 
        console.error(error); 
    }
    }
createTestData() {
    let data = [{
        'id': 123,
        'name': 'Long Product Name One of Many',
        'available_quantity': 15,
        'order_quantity': 15
    },
    {
        'id': 124,
        'name': 'Long Product Name Two of Many',
        'available_quantity': 25,
        'order_quantity': 25
    },
    {
        'id': 125,
        'name': 'Long Product Name Three of Many',
        'available_quantity': 35,
        'order_quantity': 35
    },
    {
        'id': 126,
        'name': 'Long Product Name Four of Many',
        'available_quantity': 45,
        'order_quantity': 45
    }];

    this.hasValidationError = false;
    this.data = data;
    this.columns = this.productColumnsFunc();
    this.parseDataToDataMap();
    this.isLoading = false;
}

// Used to fetch opportunity details - used for Locks B2C ISTD
getOpportunityInfo() {
    getOpportunityData({ quoteId: this.recordId })
    .then(result => {
        this.opportunityRecord = result;
        if(this.opportunityRecord.RecordType.DeveloperName=='Locks_B2C_ISTD')
        {
            this.isLocksB2CISTDQuote=true;
            this.isLoading = false;
            this.showAreaCodeScreen = true;
        }
        else if(this.opportunityRecord.RecordType.DeveloperName=='Security_Solutions_B2B')
        {
            this.isSSDQuote=true;
            this.getProductInfo();
        }
        else{
            this.getProductInfo();
        }
    })
    .catch(error=>{
        console.log(error);
    });
}

// Used to handle input field changes
handleInputChange( event ){
    if (event.currentTarget.dataset.name == 'Sales_Branch_Name__c') {            
        this.opportunityRecord.Sales_Branch_Name__c = event.currentTarget.value;
    }
    else if(event.currentTarget.dataset.name == 'Area_Code_For_IGST__c'){
        this.opportunityRecord.Area_Code_For_IGST__c = event.currentTarget.value;
    }
        else if (event.currentTarget.dataset.name == 'Order_Won_Lost__c') {            
        this.stageName = event.currentTarget.value;
    }
    else if(event.currentTarget.dataset.name == 'Reason_for_Lost__c'){
        this.reasonForLost = event.currentTarget.value;
    }
    else if(event.currentTarget.dataset.name == 'Reason_for_Lost_If_others__c'){
        this.reasonForLostOthers = event.currentTarget.value;
    }
}

handleNext(event)
{
    this.isLoading = true;
    this.showAreaCodeScreen = false;
    this.getProductInfo();
}

// Get the products data from Apex class
getProductInfo() {
    getQuoteDataForOrder({ quoteId: this.recordId })
    .then(result => {
        let jsonResult = JSON.parse(result);
        if(jsonResult.result == 'success') {
            this.hasValidationError = false;
            this.data = JSON.parse(jsonResult.data) == null ? noProductError : JSON.parse(jsonResult.data);
            this.columns = this.productColumnsFunc();
            this.parseDataToDataMap();
            this.isLoading = false;
        } else {
            this.hasValidationError = true;
            this.showToast('Error', jsonResult.error_message, 'error');
            this.dispatchEvent(new CustomEvent('close'));
        }
    })
    .catch(error => {
        this.hasValidationError = false;
        this.showToast('Error', errorMessage, 'error');
        this.dispatchEvent(new CustomEvent('close'));
    });
}

// This function houses product column structure that will house the table structure.
productColumnsFunc() {
    let productColumns;
    if(this.isLocksB2CISTDQuote){
        productColumns = [
            { label: 'Name', fieldName: 'name'},
            { label: 'Search Key II', fieldName: 'search_key_II', type: 'text' },
            { label: 'Available Quantity', fieldName: 'available_quantity', type: 'number' },
            { label: 'Order quantity', fieldName: 'order_quantity', type: 'number', editable: true }
            
        ];
    }
    else if(this.isSSDQuote){
        productColumns = [
            { label: 'Name', fieldName: 'name'},
            { label: 'Item Code', fieldName: 'item_code', type: 'text' }                
        ];
    }
    else{
        productColumns = [
            { label: 'Name', fieldName: 'name'},
            { label: 'Item Code', fieldName: 'item_code', type: 'text' },
            { label: 'Available Quantity', fieldName: 'available_quantity', type: 'number' },
            { label: 'Order quantity', fieldName: 'order_quantity', type: 'number', editable: true }
            
        ];
    }
    return productColumns;
}

// Parse the received data and create DS from it.
parseDataToDataMap() {
    this.data.forEach(data => {
        this.dataMap.set(data.id, data);
    });
}

handleCellChangeMobile(event) {
    let eventClone = {
        detail: {
            draftValues: []
        }
    }
    let value = {};
    value.id = event.currentTarget.name;
    value.order_quantity = event.detail.value;
    eventClone.detail.draftValues.push(value);
    this.handleCellChange(eventClone);
}

// Handles change in the value entered in any of the data cell.
handleCellChange(event) {
    event.detail.draftValues.forEach(value => {
        let tempDataRow = this.dataMap.get(value.id);
        Object.assign(tempDataRow, value);
        let errorMessage = this.performValidations(tempDataRow);
        this.handleAddOrRemoveErrors(tempDataRow, errorMessage);
        // Convert string values to integer for order_quantity field.
        tempDataRow.order_quantity = parseInt(tempDataRow.order_quantity, 10);
        this.dataMap.set(value.id, tempDataRow);
    });
}

performValidations(dataRow) {
    if(parseInt(dataRow.order_quantity, 10) > dataRow.available_quantity) {
        return orderQuantityError;
    }
    return null;
}

// When select all toggle component is true or false fire a custom event that updates the child row selector toggle components.
onallRowsSelected(event) {
    this.template.querySelectorAll('.rowSelected').forEach(element => {
        if(event.detail.checked) {
            element.checked = true;
            element.dispatchEvent(new CustomEvent('change', {detail: {checked: true}}));
        } else {
            element.checked = false;
            element.dispatchEvent(new CustomEvent('change', {detail: {checked: false}}));
        }
    });
}

// Prepare the datastructure required for mobile UI and send them to another function that actually handles storage of data.
onRowSelectedMobile(event) {
    let dataRow = {};
    let eventClone = {
        detail: {
            selectedRows: []
        }
    };
    let tempSelectedRows = this.selectedRows;
    dataRow = this.dataMap.get(event.currentTarget.name);

    let dataPresentInArray = false;
    for(let i=0; i < tempSelectedRows.length; i++) {
        // If the record is to be removed from the selected row datastructure.
        if(tempSelectedRows[i].id == dataRow.id) {
            if(!event.detail.checked) {
                tempSelectedRows.splice(i, 1);
            } else {
                // If the record values is to be updated in from selected row datastructure.
                dataPresentInArray = true;
                Object.assign(tempSelectedRows[i], dataRow);
            }
        }
    }
    // If a brand new data is to be inserted into the selected row datastructure.
    if(event.detail.checked && !dataPresentInArray) {
        tempSelectedRows.push(dataRow);
    }

    this.checkIfAllRowsAreSelected();

    eventClone.detail.selectedRows = tempSelectedRows;
    this.onRowSelected(eventClone);
}

checkIfAllRowsAreSelected() {
    let isAnyElementUnchecked = false;
    let allRowElements = this.template.querySelectorAll('.rowSelected');
    for(let i=0; i < allRowElements.length; i++) {
        if(!allRowElements[i].checked) {
            isAnyElementUnchecked = true;
        }
    };

    let element = this.template.querySelector('.allRowSelectionToggle');
    if(isAnyElementUnchecked) {
        element.checked = false;
    } else {
        element.checked = true;
    }
}

// Get the selected rows that user wants to insert and store them.
onRowSelected(event) {
    this.selectedRows = event.detail.selectedRows;
}

// Function to handle whether to associate an error message to a row 
// or to remove an error message associated with a row.
handleAddOrRemoveErrors(rowData, errorMessage) {
    if(errorMessage) {
        this.showRowErrorMessages(rowData, errorMessage);
    } else if(this.errors.rows[rowData.id]) {
        delete this.errors.rows[rowData.id];
    }
}

// To show the error messages for each row in the table if there is any.
showRowErrorMessages(dataRow, errorMessages) {
    this.errors.rows[dataRow.id] ={
        title: 'We found an error.',
        messages: errorMessages,
        fieldNames: ['order_quantity']
    };
    this.showToast('Error', errorMessages, 'error');
}

isThereAnyValidationError() {
    let isError = false;
    let isThereErrorInAnySelectedRow = false;

    for(let i=0; i < this.selectedRows.length; i++) {
        if(this.errors.rows.hasOwnProperty(this.selectedRows[i].id)) {
            isThereErrorInAnySelectedRow = true;
            break;
        }
    }

    if(this.selectedRows.length < 1) {
        this.showToast('Error', 'Please select atleast one product by clicking on the checkbox associated with the row.', 'error');
        isError = true;
    } else if(isThereErrorInAnySelectedRow) {
        this.showToast('Error', oneLineItemHasError, 'error');
        isError = true;
    }
    return isError;
}

createOrderClicked(event) {
    this.isLoading = true;
    let isError = this.isThereAnyValidationError();
    
    if ( this.opportunityRecord.RecordType.DeveloperName=='Security_Solutions_B2B' && !this.stageName ) {
    this.isLoading = false;
    this.showToast('Error', 'Order Won/Lost field is required.', 'error');
} else if (isError) {
    this.isLoading = false;
} else {
        let orderRec = { 'sobjectType': 'Order' };
orderRec.Order_Won_Lost__c = this.stageName;
orderRec.Reason_for_Lost__c = this.reasonForLost;
orderRec.Reason_for_Lost_If_others__c = this.reasonForLostOthers;

        createOrder({ quoteId: this.recordId, quoteToOrderRecordsJSON: JSON.stringify(this.selectedRows),opportunityRecord:this.opportunityRecord,orderRecFromLWC:orderRec })
            .then(newOrder => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newOrder.Id,
                        objectApiName: 'Order',
                        actionName: 'view'
                    }
                });
                this.showToast('Success', orderSuccessMessage, 'success');
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', error.body.message != null ? error.body.message : errorMessage, 'error');
                this.dispatchEvent(new CustomEvent('close'));
            });
    }
}

cancelOperation(event) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.recordId,
            objectApiName: 'Quote',
            actionName: 'view'
        }
    });
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