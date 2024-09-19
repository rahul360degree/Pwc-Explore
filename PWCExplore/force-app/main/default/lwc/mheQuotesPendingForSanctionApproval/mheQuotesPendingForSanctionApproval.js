/**
 * @description       : Used to display Pending Quote List on Home page
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-09-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const col = [
    { label: 'Name', fieldName: 'quoteLink', type: "url", typeAttributes: { label: { fieldName: "Name" }, target: "_blank" } },
    { label: 'Quote Number ', fieldName: 'QuoteNumber' },
    { label: 'Customer Name', fieldName: 'customerLink', type: "url", typeAttributes: { label: { fieldName: "customerName" }, target: "_blank" } }
];

export default class MheQuotesPendingForSanctionApproval extends NavigationMixin(LightningElement) {
    @api recordList = {}; // Input attribute from the Flow
    columns = col;
    @api accountList = {}; // Get Accounts
    connectedCallback() {
        if (this.recordList) {
            this.recordList = JSON.parse(JSON.stringify(this.recordList));
            this.recordList.filter(v => {
                v.quoteLink = '/' + v.Id;
                if (this.accountList) {
                    this.accountList.filter(k => {
                        if (v.AccountId == k.Id) {
                            v.customerName = k.Name;
                            v.customerLink = '/' + k.Id;
                            return;
                        }
                    })
                }
                return;
            });
        }
    }
}