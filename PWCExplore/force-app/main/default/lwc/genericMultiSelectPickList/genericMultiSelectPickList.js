import { LightningElement, track, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

const OPEN_DROPDOWN = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
const CLOSED_DROPDOWN = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

export default class TestMultiSelectPicklist extends LightningElement {
    dropDownOpen = false;
    isMobile = false;
    @api componentDetails;
    @track componentProps;
    @track dropdown = CLOSED_DROPDOWN;
    @track showPillContainer = false;
    @track selectedOptions = [];
    allOptions = [];
    @track dropdownList = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
    
    // Functions to return values that are required by the LWC combobox component.
    get name() {
        return this.componentProps.picklist_name;
    }
    get label() {
        return this.componentProps.label;
    }

    get placeHolder() {
        if(this.selectedOptions && this.selectedOptions.length > 0) {
            return ('' + this.selectedOptions.length + ' values selected');
        } else {
            return this.componentProps.placeHolder;
        }
    }

    get options() {
        this.updateOptionDataStructure(this.componentProps.options);
    }

    get IsDisabled() {
        return this.componentProps.readOnly;
    }

    get optionsToRender() {
        return this.allOptions;
    }

    get reRenderComponent() {
        return this.componentProps.reRenderComponent;
    }

    get fieldAPIName() {
        return this.componentProps.field_api_name;
    }

    get isSingleSelect() {
        return this.componentProps.singleSelect;
    }

    // Function called when the component is first loaded.
    connectedCallback() {
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        this.componentProps = JSON.parse(this.componentDetails);
        this.updateOptionDataStructure(this.componentProps.options);
    }

    /*
    *   This function is called from the parent component which passes an the updated component properties, 
    *   which should then result in the component getting rerendered. 
    */
    @api updateComponentProperties(componentProps) {
        this.selectedOptions = [];
        this.componentProps = componentProps;
        this.updateOptionDataStructure(this.componentProps.options);
    }

    /*
    *   This function is called from the parent component which passes an information 
    *   whether the particular component's dropdown is to stay open or not.
    */
    @api closeDropDownEvent(dropDownToKeepOpen) {
        if(this.componentProps.field_api_name.toLowerCase() != dropDownToKeepOpen.toLowerCase()) {
            this.closeDropDown();
        }
    }

    // Function that is used to update the datastructure for the options being displayed which will be used for processing.
    updateOptionDataStructure(optionData) {
        let options = optionData;
        let tempOptionArray = [];
        options.forEach(option => {
            let tempOptionHolder = Object.assign({}, option);
            tempOptionHolder.isChecked = false;
            tempOptionHolder.class = this.dropdownList;
            tempOptionArray.push(tempOptionHolder);
        });

        this.allOptions = tempOptionArray;
    }

    // Function that controls the opening and closing of the dropdown.
    controlDropDown(event) {
        if(this.dropdown == OPEN_DROPDOWN) {
            this.closeDropDown();
        } else {
            this.openDropdown();
        }
        this.dropDownOpen = !this.dropDownOpen;
    }

    // Function to open the drop down when the element is clicked.
    openDropdown(){
        this.dropdown = OPEN_DROPDOWN;
        if(this.selectedOptions && this.selectedOptions.length > 0) {
            this.updateOptionOrder();
        }
        this.fireMultiSelectPicklistOpenEvent();
    }

    // Function to update the option order so as to show selected options at the top.
    updateOptionOrder() {
        let tempSelectedOptionArray = [];
        let tempNonSelectedOptionArray = [];
        
        this.allOptions.forEach(option => {
            if(option.isChecked) {
                tempSelectedOptionArray.push(option);
            } else {
                tempNonSelectedOptionArray.push(option);
            }
        });
        this.allOptions = tempSelectedOptionArray.concat(tempNonSelectedOptionArray);
    }

    // Function to close the drop down.
    closeDropDown() {
        this.dropdown = CLOSED_DROPDOWN;
    }

    // Function to handle the flow when one of the options is selected/deselected.
    handleSelectOptionEvent(event) {
        let isCheck = event.currentTarget.dataset.id;
        let label = event.currentTarget.dataset.name;
        let selectedOptions = [];
        for(let i=0; i < this.allOptions.length; i++) {
            let selectedOption = {};
            if(this.allOptions[i].label === label) {
                if(isCheck==='true') {
                    this.allOptions[i].isChecked = false;
                    this.allOptions[i].class = this.dropdownList;
                } else { 
                    this.allOptions[i].isChecked = true;
                    this.allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                }
            }

            if(this.allOptions[i].isChecked) {
                selectedOption = Object.assign({}, this.allOptions[i]);
                selectedOptions.push(selectedOption);
            }
        }
        this.selectedOptions = selectedOptions;
        this.sendValuesToParent();
    }

    // Function to dispatch child data using event to the parent component.
    sendValuesToParent() {
        const childEvent = new CustomEvent('picklistupdate', {detail: {
            'field_api_name': JSON.parse(this.componentDetails).field_api_name,
            'selected_values': this.selectedOptions
        }});
        this.dispatchEvent(childEvent);
    }

    fireMultiSelectPicklistOpenEvent() {
        const childPicklistOpenEvent = new CustomEvent('picklistopen', {detail: {
            'field_api_name': JSON.parse(this.componentDetails).field_api_name
        }});
        this.dispatchEvent(childPicklistOpenEvent);
    }
}