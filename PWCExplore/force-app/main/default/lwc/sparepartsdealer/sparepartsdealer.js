/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

//import frec from '@salesforce/apex/DealerVisit_Poonam.visit';
export default class sparepartsdealer extends LightningElement {
    @track increamentalValue = 1;
    @api selectedOptions;
    @track sectionToDisplay= {};
    @api record={};
    //activeSections = ['A', 'C'];
    @api isRefrigerator_Compressor= false;
    @api isIDU_Air_Conditioner = false;
    @api isAir_Conditioner_Compressor = false;
    @api isCopper = false;
    noItemSelected = true;
    //sectionToDisplay = true;
    connectedCallback() { 
        //this.fetchrecord();
        //commentData = this.template.querySelector("lightning-input[data-id='"+record.Id+"']")
        if (this.record) {
            this.record = Object.assign({}, this.record);
            console.log(this.selectedOptions);
            if (typeof this.selectedOptions == 'string' && this.selectedOptions.length > 0) {
                let optionsArray = this.selectedOptions.split(';');
                console.log(this.optionsArray);
                
                for (let option of optionsArray) {
                    option = option.trim();
                    
                    if (option == 'Refrigerator_Compressor')
                        this.sectionToDisplay['Refrigerator_Compressor'] = true;
                    if (option == 'Air_Conditioner_Compressor')
                        this.sectionToDisplay['Air_Conditioner_Compressor'] = true;
                    if (option == 'Copper')
                        this.sectionToDisplay['Copper'] = true;
                    if (option == 'IDU_Air_Conditioner')
                        this.sectionToDisplay['IDU_Air_Conditioner'] = true;
                    if (option == 'Stabilizer')
                        this.sectionToDisplay['Stabilizer'] = true;
                    if (option == 'R22')
                        this.sectionToDisplay['R22'] = true;
                    if (option == 'R134A_Cans')
                        this.sectionToDisplay['R134A_Cans'] = true;
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
    /*fetchrecord() {
        frec({})
            .then(record => {
                if (record) {
                    this.record = record; //getrecord
                    console.log(record);
                    
                }
            })
            .catch(error => {
                console.log(error);
            });
    }*/
       

    /*if (this.sectionDisplay) {
        let displayValues = Object.values(this.sectionDisplay);
        if (displayValues) { 
            displayValues = displayValues.filter(v => {
                if (v == true)
                    return v;
            });
            if (displayValues && displayValues.length > 0)
                this.noItemSelected = false;

        }
    }*/

    handleToggleSection(event) {
        console.log(event.detail.openSections);
    }
    
    handleDataChange(event){
        this.record[event.detail.fieldapi] = event.detail.value;
        console.log(this.record);
    }

    handleComments(event){
        this.record[event.target.dataset.id] = event.target.value;
    }

    handleIncreamentChange(event){     
        this.increamentalValue = event.target.value;  
        if(event && event.target && event.target.value && event.target.value > 1){
            this.increamentalValue = event.target.value;
        }else{
            this.increamentalValue = 1;
        }

        this.increamentalValue = parseInt(this.increamentalValue);
    }


}