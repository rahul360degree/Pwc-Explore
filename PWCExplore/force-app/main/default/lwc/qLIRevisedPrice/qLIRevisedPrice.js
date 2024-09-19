/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 12-30-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const COLS = [
    { label: 'Product', fieldName: 'Search_Key_II_Referenced__c',hideDefaultActions: true },
    { label: 'Product Description', fieldName: 'Product_Description_N__c', type: 'text',hideDefaultActions: true  },
    { label: 'Quantity', fieldName: 'Quantity' ,hideDefaultActions: true },
    { label: 'MRP', fieldName: 'MRP__c', type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.01' },hideDefaultActions: true  },
    { label: 'Discount%', fieldName: 'Revised_Discount__c',hideDefaultActions: true },
    { label: 'Approved Price', fieldName: 'UnitPrice',  type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.01' },hideDefaultActions: true,initialWidth: 150 },
    { label: 'Offered Unit Basic', fieldName: 'Revised_Sales_Price__c', editable: true, type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.01' },hideDefaultActions: true,initialWidth: 150 },
    { label: 'GST%', fieldName: 'Tax_Rate_Percentage__c', type: 'number',hideDefaultActions: true  },
    { label: 'Total Basic', fieldName: 'Revised_Basic_Amount__c', type: 'currency', typeAttributes: { currencyCode: 'INR',step: '0.01' },hideDefaultActions: true  },
    
];
//{ label: 'Revised_Tax_Amount__c', fieldName: 'Revised_Tax_Amount__c', type: 'currency', typeAttributes: { currencyCode: 'INR',step: '0.01' } },
  //  { label: 'Revised_Amount_With_Tax__c', fieldName: 'Revised_Amount_With_Tax__c', type: 'currency', typeAttributes: { currencyCode: 'INR',step: '0.01' } },
export default class qLIRevisedPrice extends LightningElement {
    flag1 = true;
    flag2 = false;
    flag3 = false;
    @api recordId;
    columns = COLS;
    draftValues = [];
    quoteID = this.recordId;

    @track record;
    @track error;

    @api qliRecords = [];
    @api qliRecordsForOutput = [];
    @track qliRecordsForCalculation = [];
    error = '';
    // @wire(getQLIRelatedToQuote, { QuoteId: '$recordId' })
    // contact;
    //error
    totalBasicAmount = 0;
    connectedCallback() {
        console.log(this.qliRecords);
        this.qliRecords = JSON.parse(JSON.stringify(this.qliRecords));
        this.qliRecordsForCalculation = this.qliRecords;
        this.doCalculateTotalPrice();
    }

    handleSave(event) {
        this.error = '';
        event.detail.draftValues.filter(row => {
            this.qliRecordsForCalculation.filter(v => {
                if (v.Id == row.Id) {
                    row.Revised_Sales_Price__c = parseFloat(row.Revised_Sales_Price__c);
                    let maxApprovedPrice = parseFloat((v.UnitPrice * 1.20).toFixed(2));
                    let revisedSalesPriceWithGST = ((row.Revised_Sales_Price__c )* (1+(v.Tax_Rate_Percentage__c/100) ).toFixed(2));
                    //let maxMRPWithGST = (v.MRP__c)*(1+(v.Revised_Tax_Amount__c/v.Revised_Tax_Amount__c) );
                    if(revisedSalesPriceWithGST > v.MRP__c){
                        this.error += 'For \'' + v.Product_Name__c + '\' sales price with GST is '+revisedSalesPriceWithGST+' which can\'t exceed MRP:' + v.MRP__c + '. ';
                    }
                    if (row.Revised_Sales_Price__c > maxApprovedPrice) {
                        this.error += 'Max allowed for \'' + v.Product_Name__c + '\' is: ' + maxApprovedPrice + ' which can\'t exceed more than 20% of Approved Sales Price. ';
                    }
                    if (row.Revised_Sales_Price__c < v.UnitPrice) {
                        this.error += 'For \'' + v.Product_Name__c + '\' sales price can\'t be less than approved Sales price:' + v.UnitPrice + '. ';
                    }
                    
                    if(this.error == '')
                    {
                        v.Revised_Sales_Price__c = row.Revised_Sales_Price__c;
                    }
                }
            })
        });

        if (this.error == '') {
            this.template.querySelector('lightning-datatable').draftValues = [];
            this.doCalculateTotalPrice(true);
        } else {
            const event = new ShowToastEvent({
                title: 'Error',
                message: this.error,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
    }

    doCalculateTotalPrice(isTimeOutRequired) {
        this.totalBasicAmount = 0;
        this.qliRecordsForCalculation.filter(v => {
            
            v.Revised_Tax_Amount__c = parseFloat((( v.Revised_Sales_Price__c * (v.Tax_Rate_Percentage__c / 100) )* v.Quantity).toFixed(2));
            v.Revised_Discount__c = parseFloat(((1- v.Revised_Sales_Price__c / v.MRP__c)*100).toFixed(2));
            v.Revised_Basic_Amount__c = parseFloat((v.Revised_Sales_Price__c * v.Quantity).toFixed(2));            
            v.Revised_Amount_With_Tax__c = parseFloat(v.Revised_Basic_Amount__c + v.Revised_Tax_Amount__c);

            this.totalBasicAmount += v.Revised_Basic_Amount__c;
        });

        this.qliRecords = this.qliRecordsForCalculation;

        if (isTimeOutRequired) {
            this.qliRecordsForCalculation = [];
            setTimeout(() => {
                this.qliRecordsForCalculation = this.qliRecords;
            }, 3000);
        }
    }
}