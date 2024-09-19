/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 08-30-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class Createdealervisit extends LightningElement {
    @api record;
    @track sectionToDisplay = {};
    @api isRefrigerators = false;
    @api isWashingMachine = false;
    @api isForklift = false;

    @api selectedOptions;

    noItemSelected = true;
    connectedCallback() {
        if (this.record) {
            this.record = Object.assign({}, this.record);
            console.log(this.selectedOptions);
            if (typeof this.selectedOptions == 'string' && this.selectedOptions.length > 0) {
                let optionsArray = this.selectedOptions.split(';');
                for (let option of optionsArray) {
                    option = option.trim();
                    if (option == 'Refrigerators')
                        this.sectionToDisplay['Refrigerators'] = true;
                    if (option == 'Washing Machine')
                        this.sectionToDisplay['WashingMachine'] = true;
                    if (option == 'Front Load')
                        this.sectionToDisplay['FrontLoad'] = true;
                    if (option == 'Air Conditioner')
                        this.sectionToDisplay['AirConditioner'] = true;
                    if (option == 'Microwave Oven')
                        this.sectionToDisplay['MWO'] = true;
                    if (option == 'Chest Freezer')
                        this.sectionToDisplay['CF'] = true;
                    if (option == 'Qube')
                        this.sectionToDisplay['Qube'] = true;
                    if (option == 'Cooler')
                        this.sectionToDisplay['CLR'] = true;
                    if (option == 'UV Case')
                        this.sectionToDisplay['UV_Case'] = true;
                }
            }

            if (this.sectionToDisplay) {
                let displayValues = Object.values(this.sectionToDisplay);
                if (displayValues) {
                    displayValues = displayValues.filter(v => {
                        if (v == true)
                            return v;
                    });
                    if (displayValues && displayValues.length > 0)
                        this.noItemSelected = false;

                }
            }
        }
    }
    //@api record = {sobjectType: 'Dealer_Visit__c'};


    // handleType(event) {
    //     var selectedVal = event.detail.value;
    //     this.displayCategoryHelper(event);
    // }

    // displayCategoryHelper(event) {
    //     this.sectionToDisplay = {};
    //     this.sectionToDisplay[event.detail.value] = true;
    // }

    // handleChangeEvent(event) {
    //     this.record[event.currentTarget.dataset.name] = event.target.value;
    // }

    // handleGoNext() {
    //     const attributeChangeEvent1 = new FlowAttributeChangeEvent('record', this.record);
    //     this.dispatchEvent(attributeChangeEvent1);
    //     const attributeChangeEvent = new FlowAttributeChangeEvent('record', this.record);
    //     this.dispatchEvent(attributeChangeEvent);
    //     // check if NEXT is allowed on this screen
    //     const navigateNextEvent = new FlowNavigationNextEvent();
    //     this.dispatchEvent(navigateNextEvent);
    // }

    handleToggleSection(event) {
        console.log(event.detail.openSections);
    }

    handleDataChange(event) {
        this.record[event.detail.fieldapi] = event.detail.value;
    }
}