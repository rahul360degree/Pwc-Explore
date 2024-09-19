/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 02-22-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, wire,track,api } from 'lwc';
export default class MheQuotesSanctionQLIParser extends LightningElement {
    @api recordList=[]; // Input attribute from the Flow
    @api productList = '';
    connectedCallback(){
        if(this.recordList){
            this.recordList.filter(v=>{
                this.productList += '<p><b>Product:</b>' +v.Product_Name__c+'.</p><p><b>Quantity:</b>'+v.Quantity+ '</p><br/>';
            })
        }
    }
}