import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import findRecords from "@salesforce/apex/GenericLookupComponentController.findRecords";
import SEARCH_KEY_IS_EMPTY from '@salesforce/label/c.SEARCH_KEY_IS_EMPTY';

export default class LwcLookup extends LightningElement {
    selectedValues = [];
    currentSelectedOptions = [];
    productOptions = [];
    overallSelectedOptionsWithSearchKey = [];
    @track overallSelectedOptions = [];
    selectedProducts = [];
    @track isLoaded = false;

    @track isInfoOpen = false;
    tempSelectedProducts = [];

    @track isSearching = false;
    @track showPillContainer = false;
    @track options = [];
    @track selectedOptions = [];
    @track recordsList;
    @track searchKey = "";
    @track message;
    @track values = [];

    @api additionalFieldsToGet;
    @api selectedValue;
    @api selectedRecordId;
    @api objectApiName;
    @api fieldName;
    @api keyField;
    @api iconName;
    @api lookupLabel;
    @api componentDetails;
    @api isDisabled;

    get IsDisabled() {
        return this.isDisabled;
    }

    onLeave(event) {
        setTimeout(() => {
            this.searchKey = "";
            this.recordsList = null;
        }, 300);
    }

    handleKeyChange(event) {
        if(event.keyCode == 13) {
            this.isSearching = true;
            const searchKey = (event.target.value).trim();
            this.searchKey = searchKey;
            this.getLookupResult();
        }
    }

    handleItemRemoval(event) {
        const index = event.detail.index;
        // Remove that element from the selectedOptions array.
        let removedValue = this.selectedOptions.splice(index, 1);
        if(!this.selectedOptions || this.selectedOptions.length == 0) {
            this.showPillContainer = false;
            this.values = [];
        } else {
            let valueSet = new Set(this.values);
            valueSet.delete(removedValue[0].value);
            this.values = Array.from(valueSet);
        }
        this.sendValuesToParent();
    }

    getLookupResult() {
        // If the search key is empty or null throw a toast message informing the user of the same.
        if(!this.searchKey && this.searchKey.length < 1) {
            this.showToast('Error', SEARCH_KEY_IS_EMPTY, 'error');
            return;
        }

        let filterFields = this.fieldName + ',' + this.keyField;
        let additionalFields = this.fieldName + ',' + this.keyField;
        if(this.additionalFieldsToGet) {
            additionalFields += ',' + this.additionalFieldsToGet;
        }
        findRecords({ searchKey: this.searchKey, objectName : this.objectApiName, fieldNames: filterFields, additionalFieldsToGet: additionalFields })
        .then((result) => {
            this.showPillContainer = false;
            this.isSearching = false;
            if (result.length===0) {
                this.recordsList = [];
                this.message = "No Records Found";
            } else {
                this.recordsList = result;
                this.createOptionStructure();
                this.message = "";
            }
            this.error = undefined;
        })
        .catch((error) => {
            if(this.values && this.values.length > 0) {
                this.showPillContainer = true;
            } else {
                this.showPillContainer = false;
            }
            this.isSearching = false;
            this.error = error;
            this.recordsList = undefined;
            
            let errorMessage = 'There was an error while loading products information.'
            if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                errorMessage = error.body.message;
            }
            this.showToast('Error', errorMessage, 'error');
        });
    }

    createOptionStructure() {
        let optionArray = [];
        this.recordsList.forEach(record => {
            let tempOptionObj = Object.assign({label: '', value: ''}, record);
            tempOptionObj.label = record[this.fieldName];
            tempOptionObj.value = record[this.keyField];
            optionArray.push(tempOptionObj);
        });
        console.log(optionArray);
        this.options = optionArray;
    }

    handleCheckboxChange(event) {
        this.overallSelectedOptions = [];
        var searchKey = this.template.querySelector("lightning-input").value;
        this.currentSelectedOptions = [];
        let values = event.detail.value;
        let selectedOptions = [];
        let optionArray = [];
        values.forEach(value => {
            let optionStructure = { label: '', value: '' };
            optionStructure.label = value;
            optionStructure.value = value;
            optionArray.push(optionStructure);
            selectedOptions.push(value);
        });
        this.currentSelectedOptions = optionArray;
        //this.values = this.values.concat(values);
        this.values = event.detail.value;
        this.overallSelectedOptionsWithSearchKey[searchKey] = selectedOptions;

        for (const [key, value] of Object.entries(this.overallSelectedOptionsWithSearchKey)) {
            value.forEach(op => {
                if (this.overallSelectedOptions.indexOf(op) == -1) {
                    this.overallSelectedOptions.push(op);
                }
            });           
        }        
    }

    handleDoneClick(event) {
        this.searchKey = "";
        this.recordsList = null;
        this.updateSelectedOptions();
        this.showPillContainer = false;
        this.sendValuesToParent();
    }

    updateSelectedOptions() {
        this.productOptions = [];
        this.options.forEach(option => {
            this.productOptions.push({ key: option.Item__c, value: option.label });
        });
        console.log(this.productOptions);
        let valueSet = new Set(this.overallSelectedOptions);
        // This set is used to identify whether the value is already added to the optionArray
        let displayValueSet = new Set();
        let allOptions = this.selectedOptions.concat(this.currentSelectedOptions);
        let optionArray = [];
        allOptions.forEach(option => {
            let tempObject;
            if (valueSet.has(option.value) && !displayValueSet.has(option.value)) {
                tempObject = option;
                optionArray.push(tempObject);
                displayValueSet.add(option.value);
            }
        });
        console.log('optionArray');
        console.log(optionArray);
        this.selectedOptions = optionArray;

        if(this.overallSelectedOptions.length > 0){
            var inputElement = this.template.querySelector("lightning-input");
            inputElement.placeholder = this.overallSelectedOptions.length + ' values selected';
        }else{
            var inputElement = this.template.querySelector("lightning-input");
            inputElement.placeholder = 'Enter search term';
        }

        let response = Array.from(new Set(this.overallSelectedOptions));
        this.productOptions.forEach(option => {
            response.forEach(val => {
                if(val === option.key && this.tempSelectedProducts.indexOf(option.key) == -1){
                    this.tempSelectedProducts.push(option.key);
                    this.selectedProducts.push({key:option.key,value:option.value});
                }
            });
        });

        let afterRemovalProducts = [];
        //remove deselcted values from selectedProducts
        this.selectedProducts.forEach(sp => {
            let indexVal = this.overallSelectedOptions.indexOf(sp.key);
            if( indexVal == -1){
                var keyVal = sp.value;
                var indexToRm = this.tempSelectedProducts.indexOf(keyVal);
                if(indexToRm != -1){
                    this.tempSelectedProducts.splice(indexToRm,1);
                }                
            }else{
                afterRemovalProducts.push({key:sp.key,value:sp.value});
            }
        });
        this.selectedProducts = afterRemovalProducts;
        
    }

    sendValuesToParent() {
        let valueSet = new Set(this.overallSelectedOptions);
        const passEventr = new CustomEvent('recordselection', {
            detail: {
                selected_values: JSON.stringify(Array.from(valueSet))}
        });
        this.dispatchEvent(passEventr);
    }

    // Function to show toast message.
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    //on click event on info icon for products
    onClickInfo(event){
        if(this.selectedProducts.length == 0){
            this.showToast('Error','No product selected. Please select first','error');
        }else if(this.isInfoOpen == true){
            this.isInfoOpen = false;
        }else if(this.isInfoOpen == false){
            this.isInfoOpen = true;
        }
    }

    //remove item code from selected items for Product lookup filter
    removeRow(event){
        this.isLoaded = true;
        var selectedRow = event.currentTarget;
        var selectedKey = selectedRow.dataset.id;
        let tempSelectedProductsAfterDelete = [];
        if(this.selectedProducts.length>1){
            this.selectedProducts.forEach(selectedValue => {
                if(selectedValue.key !== selectedKey){
                    tempSelectedProductsAfterDelete.push(selectedValue);
                }
            });
            this.selectedProducts = tempSelectedProductsAfterDelete;
            let index = this.overallSelectedOptions.indexOf(selectedKey);
            if(index != -1){
                this.overallSelectedOptions.splice(index, 1);
            }            
            let indexVal = this.tempSelectedProducts.indexOf(selectedKey);  
            if(index != -1){
                this.tempSelectedProducts.splice(indexVal, 1);
            }    
            this.isLoaded = false;
        }else if(this.selectedProducts.length == 1){
            this.selectedProducts = [];
            this.tempSelectedProducts = [];
            this.overallSelectedOptions = [];
            this.isInfoOpen = false;
            this.isLoaded = false;
        }

        if(this.overallSelectedOptions.length > 0){
            var inputElement = this.template.querySelector("lightning-input");
            inputElement.placeholder = this.overallSelectedOptions.length + ' values selected';
        }else{
            var inputElement = this.template.querySelector("lightning-input");
            inputElement.placeholder = 'Enter search term';
        }

        this.sendValuesToParent();
    }
}