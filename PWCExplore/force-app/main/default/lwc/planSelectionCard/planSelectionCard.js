import { api, LightningElement, track } from 'lwc';

export default class PlanSelectionCard extends LightningElement {
    @api isChecked = false;
    @api assetBenefit;
    @track picklistOptions;
    @track columnValues = [];
    @api benefitFields;

    connectedCallback(){
        let tempRow = [];
        for(let i=0;i< this.benefitFields.length;i++) {
            let fieldObject = {};
            fieldObject.fieldApiName = this.benefitFields[i].fieldApiName;
            fieldObject.value = this.assetBenefit[this.benefitFields[i].fieldApiName];
            fieldObject.fieldType = this.benefitFields[i].fieldType;
            if(fieldObject.fieldType.toLowerCase() === "picklist"){
                fieldObject.isPicklist = true;
                let options = [];
                for(let key in this.benefitFields[i].fieldOptionsValueVsLabel) {
                    options.push({value : key, label : this.benefitFields[i].fieldOptionsValueVsLabel[key]});
                }
                fieldObject.options = [...options];
            }
            fieldObject.fieldLabel = this.benefitFields[i].fieldLabel;
            fieldObject.picklistOptions =this.benefitFields[i].fieldOptionsValueVsLabel;
            tempRow.push(fieldObject);
        }
        this.columnValues = [...tempRow];
    }
    

    handleFieldValueChange(event) {
        let temp = Object.assign({},this.assetBenefit);
        temp[event.target.label] = event.target.value;
        this.assetBenefit = temp;
    }

    @api
    isRowSelected(){
        return this.isChecked;
    }

    handleCheckboxChecked(event){
        this.isChecked = event.target.checked;
    }
}