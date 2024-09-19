/**
     * @description       : Display Line Item and spilt the quote to sync with PC
     * @author            : vrajpoot@godrej.com
     * @last modified on  : 07-08-2022
     * @last modified by  : vrajpoot@godrej.com
    **/
import { LightningElement, track, wire, api } from 'lwc';
import disableEnableQuoteSync from '@salesforce/apex/SplitQuoteLineitemQtyController.disableEnableQuoteSync';
import getQuoteLineItem from '@salesforce/apex/SplitQuoteLineitemQtyController.getQuoteLineItemFromQuote';
import syncRecord from '@salesforce/apex/SplitQuoteLineitemQtyController.syncRecord';
import updateQuoteAndLineItem from '@salesforce/apex/SplitQuoteLineitemQtyController.updateQuoteAndLineItem';
import parseLWCCalloutResponse from '@salesforce/apex/SplitQuoteLineitemQtyController.parseLWCCalloutResponse';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//Added for the PC integration
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import VERSION_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData';
import CONTENT_VERSION_ID from '@salesforce/schema/ContentDocument.LatestPublishedVersionId';
import getContentDocumentLink from '@salesforce/apex/SplitQuoteLineitemQtyController.ContentDocumentLinkFn';

import * as splitCalloutObj from './splitCallout.js';

const quoteLineItemColumn = [
    { label: 'Product type code', fieldName: 'Product_Type_Code__c' }, //Added by MRUNALI CHAUDHARI on 29-11-2022 (SLF-57)
    { label: 'Product', fieldName: 'Product_Name__c' },
    { label: 'Item Code', fieldName: 'Item_Code__c', editable: false },
    { label: 'Approved Quantity', fieldName: 'Quantity', type: 'Number', editable: false },
    { label: 'Ordered Quantity', fieldName: 'Ordered_Quantity__c', type: 'Number', editable: false },
    { label: 'To be Ordered', fieldName: 'splitQty', type: 'Number', editable: true },  
    { label: 'Unit Basic', fieldName: 'Quote_Unit_Basics_Cust__c' },//Added by MRUNALI CHAUDHARI on 29-11-2022 (SLF-57)   
    { label: 'Approved Sales Price', fieldName: 'UnitPrice' , type: 'Currency', editable: false},//Added Approved n Customer Sales Price by PSM SLF-34  
    { label: 'Customer Sales Price', fieldName: 'Customer_Sales_Price__c' , type: 'Currency', editable: true, step:.01},
];
export default class splitQuoteLineItemQty extends LightningElement {
    @track isData = true;
    fldsItemValues = []
    @track error;
    @api recordId;
    @api quoteLineItemColumn = quoteLineItemColumn;
    @track qliData;
    @track showSpinner = true;
    draftValues = [];
    @api sfQuotationPos = '';
    quoteNumber = '';

    //map{key=PC/HO/Supplier, value=ContentDocumentLink}
    attachMap;
    // Latest ContentDocument Ids to fetch the versionata
    po_dopcId;
    ho_dopcId;
    supplier_dopcId;

    // Encoded Binary Data
    po_atobData;
    ho_atobData;
    supplier_atobData;

    @track showSpinner = true;
    @track spinnerLwc = true;
    showSpinner_PO_Loading = false;
    showSpinner_HO_Loading = false;
    showSpinner_Supplier_Loading = false;

    //helper to show/hide spinner
    spinnerHelper() {
        if (this.showSpinner_PO_Loading || this.showSpinner_HO_Loading || this.showSpinner_Supplier_Loading || this.showSpinner) {
            this.spinnerLwc = true;
        } else {
            this.spinnerLwc = false;
        }
    }

    //get PO ContentVersionId
    @wire(getRecord, { recordId: '$po_dopcId', fields: [CONTENT_VERSION_ID] })
    po_contentdocument;
    get po_contentVersionId() {
        return getFieldValue(this.po_contentdocument.data, CONTENT_VERSION_ID);
    }

    //Get PO content Version
    @wire(getRecord, { recordId: '$po_contentVersionId', fields: [VERSION_DATA_FIELD] })
    po_contentversion({ error, data }) {
        if (data) {
            let fieldValue = getFieldValue(data, VERSION_DATA_FIELD);
            if (fieldValue) {
                this.po_atobData = atob(fieldValue);
                this.showSpinner_PO_Loading = false;
                this.spinnerHelper();
            }
        } else if (error) {
            console.log(error);
            this.showSpinner_PO_Loading = false;
            this.spinnerHelper();
        }
    }
    //get HO ContentVersionId
    @wire(getRecord, { recordId: '$ho_dopcId', fields: [CONTENT_VERSION_ID] })
    ho_contentdocument;
    get ho_contentVersionId() {
        return getFieldValue(this.ho_contentdocument.data, CONTENT_VERSION_ID);
    }
    //Get HO content Version
    @wire(getRecord, { recordId: '$ho_contentVersionId', fields: [VERSION_DATA_FIELD] })
    ho_contentversion({ error, data }) {
        if (data) {
            let fieldValue = getFieldValue(data, VERSION_DATA_FIELD);
            if (fieldValue) {
                this.ho_atobData = atob(fieldValue);
                this.showSpinner_HO_Loading = false;
                this.spinnerHelper();
            }
        } else if (error) {
            console.log(error);
            this.showSpinner_HO_Loading = false;
            this.spinnerHelper();
        }
    }
    //get supplier ContentVersionId
    supplier_dopcId;// = '0691m000001JwpdAAC';//'0691m000001Jx6ZAAS';
    @wire(getRecord, { recordId: '$supplier_dopcId', fields: [CONTENT_VERSION_ID] })
    supplier_contentdocument;
    get supplier_contentVersionId() {
        return getFieldValue(this.supplier_contentdocument.data, CONTENT_VERSION_ID);
    }
    //Get supplier content Version
    @wire(getRecord, { recordId: '$supplier_contentVersionId', fields: [VERSION_DATA_FIELD] })
    supplier_contentversion({ error, data }) {
        if (data) {
            let fieldValue = getFieldValue(data, VERSION_DATA_FIELD);
            if (fieldValue) {
                this.supplier_atobData = atob(fieldValue);
                this.showSpinner_Supplier_Loading = false;
                this.spinnerHelper();
            }
        } else if (error) {
            console.log(error);
            this.showSpinner_Supplier_Loading = false;
            this.spinnerHelper();
        }
    }
    //Called during intialization
    connectedCallback() {
        if (this.recordId) {
            this.callinit();
            this.fetchContentDocument();
        }
    }
    //Fetch the documents
    fetchContentDocument() {
        getContentDocumentLink({ recordId: this.recordId })
            .then(v => {
                this.attachMap = new Map();
                v.filter(k => {
                    if (k.ContentDocument.LatestPublishedVersion.Type__c) {
                        this.attachMap.set(k.ContentDocument.LatestPublishedVersion.Type__c, k);
                        if (k.ContentDocument.LatestPublishedVersion.Type__c.toUpperCase() == 'PO') {
                            this.po_dopcId = k.ContentDocumentId;
                            this.showSpinner_PO_Loading = true;
                            this.spinnerHelper();
                        }
                        else if (k.ContentDocument.LatestPublishedVersion.Type__c.toUpperCase() == 'HO') {
                            this.ho_dopcId = k.ContentDocumentId;
                            this.showSpinner_HO_Loading = true;
                            this.spinnerHelper();
                        }
                        else if (k.ContentDocument.LatestPublishedVersion.Type__c.toUpperCase() == 'SUPPLIER') {
                            this.supplier_dopcId = k.ContentDocumentId;
                            this.showSpinner_Supplier_Loading = true;
                            this.spinnerHelper();
                        }
                    }
                })
            })
            .catch(e => {
                console.log(e);
            })

    }

    //Get Line Items
    callinit() {
        getQuoteLineItem({ recordId: this.recordId })
            .then(result => {
                this.qliData = result.filter(v => {
                    v.splitQty = v.Remaining_Quantity__c;
                    if(!v.Customer_Sales_Price__c || v.Customer_Sales_Price__c==null || typeof v.Customer_Sales_Price__c == undefined){
                        v.Customer_Sales_Price__c = v.UnitPrice;
                    }
                    console.log('v.Customer_Sales_Price__c on load:'+v.Customer_Sales_Price__c);
                    if (!this.quoteNumber) {
                        this.quoteNumber = v.Quote.QuoteNumber;
                    }
                    return v;
                });
                
                this.showSpinner = false;
                this.spinnerHelper();
            })
            .catch(error => {
                console.log(error);
                if (error && error.body && error.body.message)
                    this.handleError(error.body.message);
                else
                    this.handleError(JSON.stringify(error));
                this.showSpinner = false;
                this.spinnerHelper();
            })
    }
    //method to display Error message
    handleError(message) {
        this.showSpinner = false;
        this.spinnerHelper();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
    // Intiate the PC Callout
    saveHandleAction(event) {
        this.showSpinner = true;
        this.spinnerHelper();
        let table = this.template.querySelector("lightning-datatable");
        if (table && table.getSelectedRows()) {
            let selectedRows = table.getSelectedRows();
            if (selectedRows && selectedRows.length > 0) {
                let draftedValues = table.draftValues;
                let errorString = '';
                if (draftedValues) {
                    selectedRows = selectedRows.filter(v => {
                        v.Previous_Split_Quantitiy__c = v.splitQty;
                        //v.Customer_Sales_Price__c = v.CustomerSalesPrice;
                        //console.log('v.CustomerSalesPrice before k filter:'+v.CustomerSalesPrice);
                        console.log('v.Customer_Sales_Price__c before k filter:'+v.Customer_Sales_Price__c);                        
                        //if values has been drafted
                        draftedValues.filter(k => {
                            if (k.Id == v.Id) {
                                v.splitQty = k.splitQty;
                                v.Previous_Split_Quantitiy__c = k.splitQty;
                                if (typeof k.Customer_Sales_Price__c!=undefined && k.Customer_Sales_Price__c && k.Customer_Sales_Price__c!=null){ 
                                    //v.CustomerSalesPrice = k.CustomerSalesPrice;  
                                    v.Customer_Sales_Price__c = k.Customer_Sales_Price__c;
                                    console.log('v.Customer_Sales_Price__c after assigning in k loop:' +v.Customer_Sales_Price__c);   
                                    
                                }
                                console.log('v.Customer_Sales_Price__c' +v.Customer_Sales_Price__c);                             
                                return;
                            }
                        })
                        let remainingQty = isNaN(parseInt(v.Remaining_Quantity__c)) ? 0 : parseInt(v.Remaining_Quantity__c);
                        let splittedQty = isNaN(parseInt(v.splitQty)) ? 0 : parseInt(v.splitQty);
                        let csp = isNaN(parseFloat(v.Customer_Sales_Price__c)) ? 0 : parseFloat(v.Customer_Sales_Price__c);
                        console.log('csp : '+csp);
                        if (csp <= 0) {
                            errorString += 'Please enter valid amount for Customer Sales Price';
                        }
                        else if (csp<v.UnitPrice){
                            errorString += 'Cannot have Customer Sales Price to be less than the Approved Sales Price / Unit Price.';
                        }
                        if (splittedQty < 1) {
                            errorString += 'Please enter valid quantity.';
                        }
                        else if (splittedQty > remainingQty) {
                            errorString += 'Entered Quantity can not exceed approved Qty.';
                        } 
                        if(errorString == ''){
                            return v;
                        }
                    });
                    if(errorString != ''){
                        this.handleError(errorString);
                        return;
                    }
                    else if (errorString == '') {
                        disableEnableQuoteSync({ QuoteId: this.recordId, flag: 'true' })//step 1
                            .then(result => {
                                if (result == 'SUCCESS') {
                                    this.sfQuotationPos = this.quoteNumber + '-' + Date.now();
                                    syncRecord({ qLIrecords: selectedRows, QuoteId: this.recordId, sfQuotationPos: this.sfQuotationPos })//step 2
                                        .then(result => {
                                            //this.handleSendQuoteToPCResponse(result, selectedRows);//step 3
                                            this.makeCallout(result, selectedRows);
                                        })
                                        .catch(error => {
                                            if (error && error.body && error.body.message)
                                                this.handleError(error.body.message);
                                        });
                                }
                            })
                            .catch(error => {
                                if (error && error.body && error.body.message)
                                    this.handleError('Quote is not updatable. Error:' + error.body.message);
                            });


                    }
                }
            } else {
                this.handleError('Please select at least one Line Item');
            }
        }
        else {
            this.showSpinner = false;
            this.spinnerHelper();
        }
    }
    //make the callout
    makeCallout(result, selectedRows) {
        if (result && result.quoteRec) {
            let requestOptions = splitCalloutObj.splitCalloutClass.handleCallout(result, selectedRows, this.attachMap, this.po_atobData, this.ho_atobData, this.supplier_atobData, this.sfQuotationPos);


            fetch(result.quoteEndPointURL, requestOptions)
                .then(response => response.text())
                .then(result => {
                    console.log(result);
                    parseLWCCalloutResponse({ response: result.toString() })
                        .then(result => {
                            this.handleSendQuoteToPCResponse(result, selectedRows);
                        })
                        .catch(error => {
                            console.log(error);
                            this.handleError(error);
                        })

                })
                .catch(error => {
                    console.log('error', error);
                    this.handleError(error);
                });


        }
    }
    //Parse JSON
    handleSendQuoteToPCResponse(result, selectedRows) {
        let errorMessage = '';
        let opfNo = '';
        let jsonResponse = JSON.parse(result);
        console.log('handleSendQuoteToPCResponse -jsonResponse :' +JSON.stringify(result));
        if (jsonResponse && jsonResponse.model && jsonResponse.model[0]) {
            if (jsonResponse.model[0].opfNo) {
                opfNo = jsonResponse.model[0].opfNo;
                console.log(opfNo);
            } else {
                let returnJSON = JSON.parse(jsonResponse.model[0].returnJSON);
                if (returnJSON) {
                    returnJSON.filter(v => {
                        if (v.remarks) {
                            errorMessage += ' ' + v.remarks;
                        }
                        v.productDetails.filter(p => {
                            errorMessage += ' ' + p.unspscCode + ': ' + p.remarks;
                        })
                    });
                } else {
                    errorMessage += ' Returned JSON is null';
                }
            }
        } else {
            errorMessage += ' Error in received Response';
        }
        if (opfNo && opfNo != '') {
            /*if OPF is generated Successfully*/
            console.log(opfNo);
            this.handleSaveResponse_UpdateQLY(selectedRows, opfNo);
            //Add code to update the Quote add opfNo and sent Quantity
        } else if (errorMessage && errorMessage.trim() != '') {

            disableEnableQuoteSync({ QuoteId: this.recordId, flag: false })//unlock Quote;
            this.handleError(errorMessage);
            this.showSpinner = false;
            this.spinnerHelper();
        }
    }

    //Update the QLI
    handleSaveResponse_UpdateQLY(selectedRows, opfNo) {

        let quoteDescription = '<b>opfNo: ' + opfNo + '</b>';
        quoteDescription += '<br/>sfQuotationPos: ' + this.sfQuotationPos
        quoteDescription += '<br/>Date: ' + ((new Date()).toLocaleString());
        let qliRec = selectedRows.filter(v => {
            let orderedQty = isNaN(parseInt(v.Ordered_Quantity__c)) ? 0 : parseInt(v.Ordered_Quantity__c);
            let splittedQty = isNaN(parseInt(v.splitQty)) ? 0 : parseInt(v.splitQty);
            quoteDescription += '<br/>Product: ' + v.Product_Name__c
            quoteDescription += '<br/>Quantity: ' + splittedQty + '<br/>';
            v.Ordered_Quantity__c = (orderedQty + splittedQty);
            return v;
        });
        console.log(qliRec);
        updateQuoteAndLineItem({ qLIrecords: qliRec, QuoteId: this.recordId, opfNo: opfNo, quoteDescription: quoteDescription })
            .then(result => {
                if (result == 'SUCCESS') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Records Synced to PC Successfully!!',
                            variant: 'success'
                        })
                    );
                }
                else {
                    this.handleError(error.body.message);
                }
                window.location.reload(true);

            })
            .catch(error => {
                if (error && error.body && error.body.message) {
                    this.handleError(error.body.message);
                    window.location.reload(true);
                } else {
                    this.handleError(error);
                    window.location.reload(true);
                }
            })
    }
}