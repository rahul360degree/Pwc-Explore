/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Generic LWC component to show multi-select picklist values.
Inputs:        componentDetails => (object)
Unit Test:   

History
18-09-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
import { LightningElement, track, api } from 'lwc';

export default class GenericPicklistComponent extends LightningElement {
    @api componentDetails;
    @track selectedOptions = [];
    @track anyOptionsSelected = false;

    // Function called when the component is first loaded.
    connectedCallback() {
        if(this.componentDetails.options.length == 0) {
            this.componentDetails.options = Object.assign({}, this.componentDetails.allOptions);
        }
    }

    // Functions to return values that are required by the LWC combobox component.
    get name() {
        return this.componentDetails.picklist_name;
    }
    get label() {
        return this.componentDetails.label;
    }
    get placeHolder() {
        return this.componentDetails.placeHolder;
    }
    get options() {
        return this.componentDetails.options;
    }

    get IsDisabled() {
        return this.componentDetails.readOnly;
    }

    get isSingleSelect() {
        return this.componentDetails.singleSelect;
    }

    // Function to handle change event.
    handleChange(event) {
        let elementSelected = {};

        // Based on the value get the entire object that has multiple properties for that value.
        this.componentDetails.options.forEach(element => {
            if(event.detail.value == element.value) {
                elementSelected = element;
            }
        });

        /*
        *   If the selectionOptions set is empty then add the elementSelected object else
        *   check if the selectionOptions set already has the object added, and if it's not then add it.
        */
        if(this.selectedOptions.length == 0 || this.componentDetails.singleSelect) {
            this.selectedOptions = new Array();
            this.selectedOptions.push(elementSelected);
        } else {
            let valueAlreadySelected = false;
            for(let i = 0; i < this.selectedOptions.length; i++) {
                if( (this.selectedOptions[i]).value == event.detail.value ) {
                    valueAlreadySelected = true;
                    break;   
                }
            }
            if(!valueAlreadySelected) {
                this.selectedOptions.push(elementSelected);
            }
        }

        this.anyOptionsSelected = true;
        if(!(this.componentDetails.singleSelect)) {
            this.resetComboboxValue();
        }
        this.dispatchValues(); // Dispatch the updated values to parent object.
    }

    // Function to reset the combobox since we are using LWC pill container to show selected values.
    resetComboboxValue() {
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.value = null;
        });
    }

    // Function to handle the removal of items from the LWC pill container.
    handleItemRemoval(event) {
        console.log(event);
        const index = event.detail.index;
        // Remove that element from the selectedOptions array.
        this.selectedOptions.splice(index, 1);
        if(this.selectedOptions.length == 0) {
            this.anyOptionsSelected = false;
        }
        this.dispatchValues();
    }

    // Function to dispatch child data using event to the parent component.
    dispatchValues() {
        let selectedValues = [];
        this.selectedOptions.forEach(selectedOption => {
            selectedValues.push(selectedOption.value);
        });
        const eventDispatcher = new CustomEvent('picklistupdate', {detail: {
            'field_api_name': this.componentDetails.field_api_name,
            'selected_values': selectedValues
        }});

        this.dispatchEvent(eventDispatcher);
    }
}