import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveRecordDetails from '@salesforce/apex/SaveProductFieldDetail.saveRecordDetails'
import getDefaultRecordValue from '@salesforce/apex/SaveProductFieldDetail.getDefaultRecordValue'
export default class ShowFieldsAsPerQuoteProductForConstructionMaterial extends LightningElement {

    @track selected = [];
    @track selectedtoShow = [];
    @track test;
    @api qRecord = {};

    @api Estimated_Project_AAC_Qty_in_CBM__c = 0;
    @api G_B_Quantity_AAC_Qty_in_CBM__c = 0;
    @api Estimated_Project_Duroplast_Qty_Bag__c = 0;
    @api G_B_Quantity_Duroplast_Qty_Bags__c = 0;
    @api Estimated_Project_EasyFix_Qty_Bag__c = 0;
    @api G_B_Quantity_EasyFix_Qty_Bags__c = 0;
    @api Estimated_Project_Pavers_in_Sqm__c = 0;
    @api G_B_Quantity_Pavers_in_Sqm__c = 0;
    @api Estimated_Project_Curb_Stone_in_Nos__c = 0;
    @api G_B_Quantity_Curb_Stone_in_Nos__c = 0;
    @api Est_Project_Solid_Concrete_Block_Nos__c = 0;
    @api G_B_Quantity_Solid_Concrete_Block_Nos__c = 0;
    @api Estimated_Project_Tilefix_Qty_Bag__c = 0;
    @api G_B_Quantity_Tilefix_Qty_Bags__c = 0;

    @track containsAAC = false;
    @track containsDuroplast = false;
    @track containsEasyFix = false;
    @track containsPavers = false;
    @track containsCurb_Stone = false;
    @track containsSolid_Concrete_Block = false;
    @track containsTilefix = false;

    @track showAAC = false;
    @track showDuroplast = false;
    @track showEasyFix = false;
    @track showPavers = false;
    @track showCurb_Stone = false;
    @track showSolid_Concrete_Block = false;
    @track showTilefix = false;

    get options() {
        return [
            { label: 'AAC', value: 'AAC' },
            { label: 'Duroplast', value: 'Duroplast' },
            { label: 'EasyFix', value: 'EasyFix' },
            { label: 'Pavers', value: 'Pavers' },
            { label: 'Solid Concrete Block', value: 'Solid Concrete Block' },
            { label: 'Curb Stone', value: 'Curb Stone' },
            { label: 'Tilefix', value: 'Tilefix' },
        ];
    }


    get selected() {
        return this.selected.length ? this.selected : 'none';
    }

    @wire(getDefaultRecordValue,{rec:'$qRecord'})
    wiredLeads({ error, data }) {
    if (data) {
      this.selectedtoShow = data;
      this.error = undefined;
      this.showAAC = (this.selectedtoShow[0]);
      this.showDuroplast = (this.selectedtoShow[1]);
      this.showEasyFix = (this.selectedtoShow[2]);
      this.showPavers = (this.selectedtoShow[4]);
      this.showCurb_Stone = (this.selectedtoShow[5]); 
      this.showSolid_Concrete_Block = (this.selectedtoShow[3]);
      this.showTilefix = (this.selectedtoShow[6]);
    } 
    else if (error) {
      this.error = error;
      this.contacts = undefined;
    }
  }

    handleChange(event) {
        this.selected = event.detail.value;

        this.containsAAC = (this.selected.includes('AAC'))? true : false;
        this.containsDuroplast =  (this.selected.includes('Duroplast')) ? true : false;
        this.containsEasyFix =  (this.selected.includes('EasyFix')) ? true : false;
        this.containsPavers = (this.selected.includes('Pavers')) ? true : false;
        this.containsCurb_Stone = (this.selected.includes('Curb Stone'))  ? true : false;
        this.containsSolid_Concrete_Block = (this.selected.includes('Solid Concrete Block')) ? true : false;
        this.containsTilefix = (this.selected.includes('Tilefix'))? true : false;
    }

    handlefieldChange(event) {

        const name = event.target.name;
        const value = parseFloat(event.target.value);

        switch (name) {
            case 'Estimated_Project_AAC_Qty_in_CBM__c':
                this.Estimated_Project_AAC_Qty_in_CBM__c = value;
                break;
            case 'G_B_Quantity_AAC_Qty_in_CBM__c':
                this.G_B_Quantity_AAC_Qty_in_CBM__c = value;
                break;
            case 'Estimated_Project_Duroplast_Qty_Bag__c':
                this.Estimated_Project_Duroplast_Qty_Bag__c = value;
                break;
            case 'G_B_Quantity_Duroplast_Qty_Bags__c':
                this.G_B_Quantity_Duroplast_Qty_Bags__c = value;
                break;
            case 'Estimated_Project_EasyFix_Qty_Bag__c':
                this.Estimated_Project_EasyFix_Qty_Bag__c = value;
                break;
            case 'G_B_Quantity_EasyFix_Qty_Bags__c':
                this.G_B_Quantity_EasyFix_Qty_Bags__c = value;
                break;
            case 'Estimated_Project_Pavers_in_Sqm__c':
                this.Estimated_Project_Pavers_in_Sqm__c = value;
                break;
            case 'G_B_Quantity_Pavers_in_Sqm__c':
                this.G_B_Quantity_Pavers_in_Sqm__c = value;
                break;
            case 'Estimated_Project_Curb_Stone_in_Nos__c':
                this.Estimated_Project_Curb_Stone_in_Nos__c = value;
                break;
            case 'G_B_Quantity_Curb_Stone_in_Nos__c':
                this.G_B_Quantity_Curb_Stone_in_Nos__c = value;
                break;
            case 'Est_Project_Solid_Concrete_Block_Nos__c':
                this.Est_Project_Solid_Concrete_Block_Nos__c = value;
                break;
            case 'G_B_Quantity_Solid_Concrete_Block_Nos__c':
                this.G_B_Quantity_Solid_Concrete_Block_Nos__c = value;
                break;
            case 'Estimated_Project_Tilefix_Qty_Bag__c':
                this.Estimated_Project_Tilefix_Qty_Bag__c = value;
                break;
            case 'G_B_Quantity_Tilefix_Qty_Bags__c':
                this.G_B_Quantity_Tilefix_Qty_Bags__c = value;
                break;

        }
    }

    checkValues() {
        console.log('checkvalue fun:');
        this.test = true;
        if (this.G_B_Quantity_AAC_Qty_in_CBM__c > this.Estimated_Project_AAC_Qty_in_CBM__c) {
            this.ShowToast('Error', 'G&B Quantity AAC Qty (in CBM) should not exceed Estimated Project AAC Qty (in CBM) ', 'error');
            this.test = false;

        }
        if (this.G_B_Quantity_Duroplast_Qty_Bags__c > this.Estimated_Project_Duroplast_Qty_Bag__c) {
            this.ShowToast('Error', 'G&B Quantity Duroplast Qty (Bags)should not exceed Estimated Project Duroplast Qty', 'error');
            this.test = false;
        }
        if (this.G_B_Quantity_EasyFix_Qty_Bags__c > this.Estimated_Project_EasyFix_Qty_Bag__c) {
            this.ShowToast('Error', 'G&B Quantity EasyFix Qty (Bags) should not exceed Estimated Project EasyFix Qty (Bag)', 'error');
            this.test = false;
        }
        if (this.G_B_Quantity_Pavers_in_Sqm__c > this.Estimated_Project_Pavers_in_Sqm__c) {
            this.ShowToast('Error', 'G&B Quantity Pavers (in Sqm) should not exceed Estimated Project Pavers (in Sqm)', 'error');
            this.test = false;
        }
        if (this.G_B_Quantity_Curb_Stone_in_Nos__c > this.Estimated_Project_Curb_Stone_in_Nos__c) {
            this.ShowToast('Error', 'G&B Quantity Curb Stone (in Nos) should not exceed Estimated Project Curb Stone (in Nos)', 'error');
            this.test = false;
        }
        if (this.G_B_Quantity_Solid_Concrete_Block_Nos__c > this.Est_Project_Solid_Concrete_Block_Nos__c) {
            this.ShowToast('Error', 'G&B Quantity Solid Concrete Block (Nos) should not exceed Estimated Project Solid Concrete Block (Nos)', 'error');
            this.test = false;
        }
        if (this.G_B_Quantity_Tilefix_Qty_Bags__c > this.Estimated_Project_Tilefix_Qty_Bag__c) {
            this.ShowToast('Error', 'G&B Quantity Tilefix Qty (Bags) should not exceed Estimated Project Tilefix Qty (Bag)', 'error');
            this.test = false;
        }
        if (this.test) {
            console.log('Calling save');
            this.handleClick();
        }
    }

    handleClick(event) {
        //console.log("Final val",this.allFieldRec);
        var q = { 'sobjectType': 'Quote' };
        q.Id = this.qRecord.Id;
        console.log('check id: LN 237', this.qRecord.Id);
        q.Estimated_Project_AAC_Qty_in_CBM__c = this.Estimated_Project_AAC_Qty_in_CBM__c;
        q.G_B_Quantity_AAC_Qty_in_CBM__c = this.G_B_Quantity_AAC_Qty_in_CBM__c;
        q.Estimated_Project_Duroplast_Qty_Bag__c = this.Estimated_Project_Duroplast_Qty_Bag__c;
        q.G_B_Quantity_Duroplast_Qty_Bags__c = this.G_B_Quantity_Duroplast_Qty_Bags__c;
        q.Estimated_Project_EasyFix_Qty_Bag__c = this.Estimated_Project_EasyFix_Qty_Bag__c;
        q.G_B_Quantity_EasyFix_Qty_Bags__c = this.G_B_Quantity_EasyFix_Qty_Bags__c;
        q.Estimated_Project_Pavers_in_Sqm__c = this.Estimated_Project_Pavers_in_Sqm__c;
        q.G_B_Quantity_Pavers_in_Sqm__c = this.G_B_Quantity_Pavers_in_Sqm__c;
        q.Estimated_Project_Curb_Stone_in_Nos__c = this.Estimated_Project_Curb_Stone_in_Nos__c;
        q.G_B_Quantity_Curb_Stone_in_Nos__c = this.G_B_Quantity_Curb_Stone_in_Nos__c;
        q.Est_Project_Solid_Concrete_Block_Nos__c = this.Est_Project_Solid_Concrete_Block_Nos__c;
        q.G_B_Quantity_Solid_Concrete_Block_Nos__c = this.G_B_Quantity_Solid_Concrete_Block_Nos__c;
        q.Estimated_Project_Tilefix_Qty_Bag__c = this.Estimated_Project_Tilefix_Qty_Bag__c;
        q.G_B_Quantity_Tilefix_Qty_Bags__c = this.G_B_Quantity_Tilefix_Qty_Bags__c;
        q.Product_List__c = this.selected;

        saveRecordDetails({ rec: q })
        .then(result => {
            if (result == 'SUCCESS') {
                this.ShowToast('Success', 'Records saved successfully', 'success');
            }else {
                this.ShowToast('Error', 'Unknown error occurred', 'error');
            }
        })
        .catch(error => {
            console.log('save error', error);
            this.ShowToast('Error', error.body.message, 'error');
        })
    }

    ShowToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);

    }
}