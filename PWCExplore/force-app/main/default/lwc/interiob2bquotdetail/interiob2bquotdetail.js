/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 18-09-2023
 * @last modified by  : snehalw@godrej.com
**/
import createApprovalComments from '@salesforce/apex/InterioB2BApprovalProcess.createApprovalComments';
import getQuoteLines from '@salesforce/apex/InterioB2BApprovalProcess.getPendingQuoteLines';
import callApprovalFunction from '@salesforce/apex/InterioB2BApprovalProcess.submitForApproval';
import wrapInfo from '@salesforce/apex/InterioB2BApprovalProcess.wrapInfo';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track } from 'lwc';
import * as interiob2bquotdetailhelper from './interiob2bquotdetailhelper.js';

const PERSONA_SALES = 'Sales Person';
const PERSONA_MANAGER = 'Manager';
const PERSONA_RM = 'Regional Manager';
const PERSONA_ZH = 'Zonal Head';
const PERSONA_HO = 'Head Officer';
const PERSONA_VP = 'Vice President';
const PERSONA_BH = 'Business Head';
const PERSONA_CST = 'CST';
const STATUS_APPROVED = 'Approved';
const STATUS_SUBMITTED_FOR_APPROVAL = 'Submitted for Approval';
const STATUS_DRAFT = 'Draft';
const STATUS_RESUBMIT = 'Resubmitted';
const STATUS_REJECTED = 'Rejected';
const TRANSACTION_TYPE_GEM = 'GEM';
const TRANSACTION_TYPE_GEM_RC = 'GEM+RC';
const TRANSACTION_TYPE_GEM_PAC = 'GEM-PAC';
const ROUNDDIGIT_INPUT = 2;
const ROUNDDIGIT_OUTPUT = 2;
const INPUT_FIELDS = ['Approved_Customer_Discount__c','Approved_Customer_Discounted_Basic_Price__c', 'Approved_WD_Retention_On_ReqDiscbasic__c', 'Approved_WD_CONT__c' ];

export default class Interiob2bquotdetail extends NavigationMixin(LightningElement) {
@api quoteId;
@track qliRecords = [];
@api hideSpinner;
approvalComment = undefined;
isVP_Persona = false;
is_HO_Persona = false;
@api is_Salesperson_Persona = false;
is_Cst_Persona = false;
showResubmitButton = true;
displayCOP = false;
userinfo={};
userQueueIds=[];
approvalButtonLabel = '';
approvalButtonId = ''; 
showStorageCheckbox  = false ;
showDeskingCheckbox  = false ;
isResubmitStorageProducts = false ;
isResubmitDeskingProducts = false ;
isValid = true ;
@api isModal = false;
@api fromapprover = false; 


tablediv = '';
tablestyle = `width : 100%`;
thclass = 'slds-cell-wrap';//'slds-is-resizable slds-is-sortable';
tablecss = 'slds-table slds-table_cell-buffer slds-table_bordered slds-table_col-bordered';//'slds-table slds-table_bordered slds-table_col-bordered slds-table_fixed-layout slds-table_resizable-cols tableCSS';
thdivcss = '';//'slds-grid slds-grid_vertical-align-center slds-has-flexi-truncate'
spancss = '';//'slds-truncate';
tdclass = 'slds-cell-wrap';
additionalFields = 'Quote.Opportunity.OwnerId,Quote.Opportunity.Owner.Name,Req_WD_Ret_Amt_SACConsBasic__c,Apr_WD_Ret_Amt_SACConsBasic__c,Req_WD_CONT_Amt_Consumer_Basic__c,Approved_WD_CONT_Amt_Consumer_Basic__c,Product2.Id,Product2.Name,Product2.Description,Product2.Item__c,Quantity,Effective_Pricebook_Date__c,ListPrice,Requested_Customer_Discount__c,UnitPrice,Approved_Customer_Discount__c,Approved_Customer_Discounted_Basic_Price__c,Req_WD_Ret_SAC_OnReqDiscBasic__c,Approved_WD_Retention_On_ReqDiscbasic__c,Req_WD_CONT__c,Approved_WD_CONT__c,Req_Net_Rlizd_Bsc_Disc__c,Req_Net_Realizd_BsicAmnt_Rate_Unit__c,Approved_Net_Realized_Basic_Discount__c,Approved_Net_Realized_Basic_Rate_Unit__c,COP__c,Requested_COP_Factor__c,Approved_COP_Factor__c,toLabel(Product_Line_c__c),List_of_Approvers__c,Current_Approver__c,Approval_Status__c,Pending_With_Owner__c,Quote.Approval_Status__c,Requested_WD_CONT_Req_Disc_Basic__c,Quote.Transaction_Type__c,Quote.Transaction_Type_c__c,Quote.Opportunity.CloseDate,Product2.Product_Type__c,Quote.Opportunity.Owner.Persona__c,Quote.Interio_Sub_Division__c,Quote.Opportunity.Owner.ManagerId,Quote.Is_KAM__c,Quote.Opportunity.Account.Is_Key_Account__c,Quote.End_Customer__r.Is_Key_Account__c';

// Added by rohit
LobWiseSummaryToStoreOnQuoteAsJson = [];

is_SubmitterFieldsReadOnly=true;
connectedCallback() {
    this.tablecss += this.isModal?'':' tableLayout';
    this.fetchApprovalComment();
    this.helperDisplaySpinner();
    this.handleFormFactor();
    console.log('isapprover' + this.fromapprover);
// this.fetchQLIRecords();
}

fetchApprovalComment() {
wrapInfo({ quoteId: this.quoteId})
.then(result => {
    this.approvalComment = result.approvalComment;
    this.userinfo = result.user;
// Added by snehal w 18/09/2023
console.log('===',this.userinfo.Persona__c);
if(this.userinfo.Persona__c == 'CST' ){
    this.is_Cst_Persona = true;
}
if((this.userinfo.Persona__c && this.userinfo.Persona__c == PERSONA_SALES) || this.is_Salesperson_Persona==true){
    this.is_Salesperson_Persona = true;   
    this.is_SubmitterFieldsReadOnly=false;         
}else if(this.userinfo.Persona__c && (this.userinfo.Persona__c == PERSONA_VP || this.userinfo.Persona__c == PERSONA_BH))
    this.isVP_Persona = true;
else if(this.userinfo.Persona__c && this.userinfo.Persona__c == PERSONA_HO){
    this.is_HO_Persona = true;

if(result.queueIdList){
    this.userQueueIds = result.queueIdList;
}
}

if(this.isVP_Persona || this.is_HO_Persona){
    this.displayCOP = true;
}

if(this.is_Salesperson_Persona || this.is_Cst_Persona ){ 
    this.approvalButtonLabel = 'Submit For Approval';
    this.approvalButtonId = STATUS_SUBMITTED_FOR_APPROVAL;
}
else{
    this.approvalButtonLabel = 'Approve';
    this.approvalButtonId = STATUS_APPROVED
}
// Added by snehal w 18/09/2023
if (this.is_Cst_Persona || this.is_Salesperson_Persona) {
    this.showResubmitButton = false;
}

this.fetchQLIRecords()
})
.catch(error => {
this.helperErrorMessage(error);
})
}

fetchQLIRecords() {

getQuoteLines({ quoteId: this.quoteId, additionalFields: this.additionalFields })
.then(record => {
if (record) {
    record.forEach(rec => {
    if ((rec.Approval_Status__c === STATUS_RESUBMIT || rec.Approval_Status__c === STATUS_DRAFT) && (this.userinfo.Persona__c == PERSONA_SALES || this.userinfo.Persona__c == PERSONA_CST) ) {
        rec.is_SubmitterFieldsReadOnly = false;
    } else {
        rec.is_SubmitterFieldsReadOnly = true;
    }
    });

    this.helperPrepareMap(record);
    this.helperSummation();
} else {
    this.qliRecords = [];
}
    this.helperHideSpinner();
})
.catch(error => {
    this.helperErrorMessage(error);
})
}
//Add read only condition here
helperPrepareMap(record) {
let categoryMap = new Map();
for (var rec of record) {
interiob2bquotdetailhelper.helperFiler.nullValueAssignment(rec,this.additionalFields);
let isEditable = false;

if((rec.Current_Approver__c == this.userinfo.Id || this.userQueueIds.includes(rec.Current_Approver__c) ) && (this.userinfo.Persona__c != PERSONA_SALES && this.userinfo.Persona__c != PERSONA_CST) ){
    isEditable = true;
// Added by Snehal W 12/06/2023
if(rec.Pending_With_Owner__c === 'Interio B2B Storage'){ 
    this.showStorageCheckbox  = true ;

}else if(rec.Pending_With_Owner__c === 'Interio B2B Desking'){
    this.showDeskingCheckbox  = true ;
}
}

rec.isReadOnly = isEditable?false:true;
let lobArray = [];
const lob = rec.Product_Line_c__c?rec.Product_Line_c__c:'Product';
if (categoryMap && categoryMap.get(lob)) {
    lobArray = categoryMap.get(lob);
}

lobArray.push(rec);
categoryMap.set(lob, lobArray);
}
if (categoryMap) {
    this.helperPrepareData(categoryMap);
}
}

helperPrepareData(categoryMap) {
let rowCount = 1; // Initialize the row count
for (const [key, value] of categoryMap) {
for (const rec of value) {
    rec.rowCount = rowCount; // Add a rowCount property to the record
    rowCount++; // Increment the row count
    }
this.qliRecords.push({ 'lob': key, 'records': value });
}

}


helperNavigation(event) {
this[NavigationMixin.GenerateUrl]({
type: "standard__recordPage",
attributes: {
recordId: event.currentTarget.dataset.id,
objectApiName: event.currentTarget.dataset.name,
actionName: 'view'
}
}).then(url => {
window.open(url, "_blank");
});
}

handleInputChange(event) {
this.qliRecords.filter(v => {
v.records.filter(record => {
if (record.Id == event.currentTarget.dataset.id) {
let apiName = event.currentTarget.dataset.name;
record[apiName] = parseFloat(event.currentTarget.value);
if (apiName == 'Approved_Customer_Discount__c') {
    this.calculateApprovedCustomerDiscountedBasicPrice(event.currentTarget, record);
//this.helperSummation();
} else if (apiName == 'Approved_Customer_Discounted_Basic_Price__c') {
    this.calculateApprovedCustomerDiscount(event.currentTarget, record);
//this.helperSummation();
} else if (apiName == 'Requested_Customer_Discount__c') {
    this.calculateRequestedCustomerDiscountedBasicPrice(event.currentTarget, record);
} else if (apiName == 'UnitPrice') {
    this.calculateRequestedCustomerDiscount(event.currentTarget, record);
} else if (apiName == 'Requested_WD_CONT_Req_Disc_Basic__c') {
    this.calculateRequestedWDCONTAmountOnConsumerBasic(event.currentTarget, record);
} 
// Added by snehal W 12/06/2023
if((record.Approved_Customer_Discount__c > record.Requested_Customer_Discount__c || record.Approved_WD_Retention_On_ReqDiscbasic__c > record.Req_WD_Ret_SAC_OnReqDiscBasic__c || record.Approved_WD_CONT__c > record.Requested_WD_CONT_Req_Disc_Basic__c) && record.Approval_Status__c != STATUS_RESUBMIT ) {
    this.helperErrorMessage("Approved percentages should not be more than Requested Percentages");
    this.isValid = false;                
}else{
this.isValid = true;              
}
}
});
this.helperSummation();
})
}


calculateApprovedCustomerDiscountedBasicPrice(currentTarget, record) {
record.Approved_Customer_Discounted_Basic_Price__c = this.round((record.ListPrice * (1 - (record.Approved_Customer_Discount__c / 100))), 'Approved_Customer_Discounted_Basic_Price__c');
}
calculateApprovedCustomerDiscount(currentTarget, record) {
record.Approved_Customer_Discount__c = this.round(((1 - (record.Approved_Customer_Discounted_Basic_Price__c / record.ListPrice)) * 100), 'Approved_Customer_Discount__c');
}

//Added by rohit on 2nd Jan 2023
calculateRequestedCustomerDiscountedBasicPrice(currentTarget, record) {
record.UnitPrice = this.round((record.ListPrice * (1 - (record.Requested_Customer_Discount__c / 100))), 'UnitPrice');
}

calculateRequestedCustomerDiscount(currentTarget, record) {
//record.Requested_Customer_Discount__c = this.round(((1 - (record.UnitPrice / record.ListPrice)) * 100), 2);
let discountPercentage = ((1 - (record.UnitPrice / record.ListPrice)) * 100);
record.Requested_Customer_Discount__c = discountPercentage.toFixed(2); // Format to 2 decimal places
}
//Added by Snehal W
calculateRequestedWDCONTAmountOnConsumerBasic(currentTarget, record) {
record.Req_WD_CONT_Amt_Consumer_Basic__c = this.round(((record.summationReqWDCONT / record.summation_listPrice) * 100), 2);
}
helperSummation() {
let LobSummary = [];
this.qliRecords.filter(v => {
v['summation_listPrice'] = 0;
v['summation_unitPrice'] = 0;
v['summationApprovedCustomerDiscountedBasicPrice'] = 0;
v['summationReqWDRetSACOnReqDiscBasic'] = 0;
v['summationAppWDRetReqDiscbasic'] = 0;
v['summationReqWDCONT'] = 0;
v['summationApprovedWDCONT'] = 0;
v['summationReqNetRealizdBsicAmntRateUnit'] = 0;
v['summationApprovedNetRealizedBasicRateUnit'] = 0;
v['summationCOPperUnit'] = 0;
v['summationApprovedCOPFactor'] = 0;

// Added by rohit 
v['summationReqWDRetSACOnReqDiscBasic_Percentage'] =0; 
v['summationReqWDRetSACOnConsumerBasic_Percentage'] =0;
v['summationAppWDRetReqDiscBasic_Percentage'] =0; 
v['summationAppWDRetConsumerBasic_Percentage'] =0;
v['summationReqWDCONTOnReqDiscBasic_Percentage'] =0; 
v['summationReqWDCONTOnConsumerBasic_Percentage'] =0;
v['summationApprovedWDCONTOnReqDiscBasic_Percentage'] =0; 
v['summationApprovedWDCONTOnConsumerBasic_Percentage'] =0;

v['summationUnitPrice_Percentage'] = 0;
v['summationApprovedCustomerDiscountedBasicPrice_Percentage'] = 0;
v['summationReqNetRealizdBsicAmntRateUnit_Percentage'] = 0;
v['summationApprovedNetRealizedBasicRateUnit_Percentage'] = 0;

v.grandTotal_listPrice = 0;            
v.records.filter(record => {
this.summation_ListPrice(v, record);
this.summation_UnitPrice(v, record);
this.summation_ApprovedCustomerDiscountedBasicPrice(v, record);
this.summation_ReqWDRetSACOnReqDiscBasic(v, record);
this.summation_AppWDRetReqDiscbasic(v, record);
this.summation_ReqWDCONT(v, record);
this.summation_ApprovedWDCONT(v, record); 

//check in bulk
this.summation_COPperUnit(v, record);
});

v['ReqWDRetentionAmtSAConConsumerBasic'] = this.calcualateRequestedWDRetentionAmountSAConConsumerBasic(v);
v['ApprWDRetentionAmtSACConsumerBasicRs'] = this.calculateApprWDRetentionAmtSACConsumerBasicRs(v);
v.RequestedWDCONTAmountConsumerBasic = this.calculateRequestedWDCONTAmountConsumerBasic(v);
v.ApprovedWDCONTAmountConsumerBasic = this.calculateApprovedWDCONTAmountConsumerBasic(v);

});

this.qliRecords.filter(v => {
v.records.filter(record => {
this.calculateReqNetRlizdBscDisc(v, record);
this.calculateReqNetRealizdBsicAmntRateUnit(v, record);
this.summation_ReqNetRealizdBsicAmntRateUnit(v, record);
//if(record.Approved_Customer_Discount__c > 0){
this.calculateApprovedNetRealizedBasicDiscount(v, record);
//}
this.calculateApprovedNetRealizedBasicRateUnit(v, record);
this.calculateApprovedCOPFactor(v, record); 

this.summation_ApprovedNetRealizedBasicRateUnit(v, record);
this.calculateRequestedCOPFactor(v, record);
this.summation_RequestedCOPFactor(v, record);
    
});

this.summation_ApprovedCOPFactor(v); 
//Added by rohit
this.summation_ReqWDRetSACOnReqDiscBasic_Percentage(v);
this.summation_ReqWDRetSACOnConsumerBasic_Percentage(v);
this.summation_AppWDRetReqDiscBasic_Percentage(v);
this.summation_AppWDRetConsumerBasic_Percentage(v);
this.summation_ReqWDCONTOnReqDiscBasic_Percentage(v);
this.summation_ReqWDCONTOnConsumerBasic_Percentage(v);
this.summation_ApprovedWDCONTOnReqDiscBasic_Percentage(v);
this.summation_ApprovedWDCONTOnConsumerBasic_Percentage(v);  

this.summation_UnitPrice_Percentage(v);
this.summation_ApprovedCustomerDiscountedBasicPrice_Percentage(v);           
this.summation_ReqNetRealizdBsicAmntRateUnit_Percentage(v);
this.summation_ApprovedNetRealizedBasicRateUnit_Percentage(v);

let obj = {
"LoB": v.lob,
"summation_listPrice": v.summation_listPrice,
"summation_unitPrice": v.summation_unitPrice,
"summationApprovedCustomerDiscountedBasicPrice": v.summationApprovedCustomerDiscountedBasicPrice,
"summationReqWDRetSACOnReqDiscBasic": v.summationReqWDRetSACOnReqDiscBasic,
"summationAppWDRetReqDiscbasic": v.summationAppWDRetReqDiscbasic,
"summationReqWDCONT": v.summationReqWDCONT,
"summationApprovedWDCONT": v.summationApprovedWDCONT,
"summationReqNetRealizdBsicAmntRateUnit": v.summationReqNetRealizdBsicAmntRateUnit,
"summationApprovedNetRealizedBasicRateUnit": v.summationApprovedNetRealizedBasicRateUnit,
"summationCOPperUnit": v.summationCOPperUnit,
"summationApprovedCOPFactor": v.summationApprovedCOPFactor,
"summationRequestedCOPFactor": v.summationRequestedCOPFactor,
"summationReqWDRetSACOnReqDiscBasic_Percentage": v.summationReqWDRetSACOnReqDiscBasic_Percentage,
"summationReqWDRetSACOnConsumerBasic_Percentage": v.summationReqWDRetSACOnConsumerBasic_Percentage,
"summationAppWDRetReqDiscBasic_Percentage": v.summationAppWDRetReqDiscBasic_Percentage,
"summationAppWDRetConsumerBasic_Percentage": v.summationAppWDRetConsumerBasic_Percentage,
"summationReqWDCONTOnReqDiscBasic_Percentage": v.summationReqWDCONTOnReqDiscBasic_Percentage,
"summationReqWDCONTOnConsumerBasic_Percentage": v.summationReqWDCONTOnConsumerBasic_Percentage,
"summationApprovedWDCONTOnReqDiscBasic_Percentage": v.summationApprovedWDCONTOnReqDiscBasic_Percentage,
"summationApprovedWDCONTOnConsumerBasic_Percentage": v.summationApprovedWDCONTOnConsumerBasic_Percentage,
"summationUnitPrice_Percentage": v.summationUnitPrice_Percentage,
"summationApprovedCustomerDiscountedBasicPrice_Percentage": v.summationApprovedCustomerDiscountedBasicPrice_Percentage,
"summationReqNetRealizdBsicAmntRateUnit_Percentage": v.summationReqNetRealizdBsicAmntRateUnit_Percentage,
"summationApprovedNetRealizedBasicRateUnit_Percentage": v.summationApprovedNetRealizedBasicRateUnit_Percentage
};
LobSummary.push(obj);              
});

//Storing Lob Wise Summary in JSON format on Quote Record to use in VF Page to display Lob Wise Summary.
this.LobWiseSummaryToStoreOnQuoteAsJson=[...LobSummary];

this.helper_GrandTotalCalculation();
}

summation_ListPrice(v, record) {
//let summation_unit = v['summation_unit'] ? v['summation_unit'] +record.UnitPrice:record.UnitPrice;
let sum = record.ListPrice * record.Quantity;
let value = v['summation_listPrice'] ? v['summation_listPrice'] + sum : sum;
v['summation_listPrice'] = this.round(value);

}

summation_UnitPrice(v, record) {
//let summation_unit = v['summation_unit'] ? v['summation_unit'] +record.UnitPrice:record.UnitPrice;
let sum = record.UnitPrice * record.Quantity;
let value = v['summation_unitPrice'] ? v['summation_unitPrice'] + sum : sum;
v['summation_unitPrice'] = this.round(value);
}

summation_ApprovedCustomerDiscountedBasicPrice(v, record) {

let sum = record.Approved_Customer_Discounted_Basic_Price__c * record.Quantity;
//v['summationApprovedCustomerDiscountedBasicPrice'] = (v['summationApprovedCustomerDiscountedBasicPrice'] ? v['summationApprovedCustomerDiscountedBasicPrice'] +sum:sum);
v['summationApprovedCustomerDiscountedBasicPrice'] = this.round((v['summationApprovedCustomerDiscountedBasicPrice'] ? v['summationApprovedCustomerDiscountedBasicPrice'] + sum : sum));

}

summation_ReqWDRetSACOnReqDiscBasic(v, record) {
let sum = (record.Req_WD_Ret_SAC_OnReqDiscBasic__c * record.UnitPrice * record.Quantity) / 100;
//v['summationReqWDRetSACOnReqDiscBasic'] = v['summationReqWDRetSACOnReqDiscBasic'] ? v['summationReqWDRetSACOnReqDiscBasic'] +sum:sum;
v['summationReqWDRetSACOnReqDiscBasic'] = this.round(v['summationReqWDRetSACOnReqDiscBasic'] ? v['summationReqWDRetSACOnReqDiscBasic'] + sum : sum);
}

calcualateRequestedWDRetentionAmountSAConConsumerBasic(v) {
return this.round(v['summationReqWDRetSACOnReqDiscBasic'] / (v['summation_listPrice'] / 100));
}

summation_AppWDRetReqDiscbasic(v, record) {
if (record.Approved_WD_Retention_On_ReqDiscbasic__c) {
let sum = (record.Approved_WD_Retention_On_ReqDiscbasic__c / 100) * (record.Approved_Customer_Discounted_Basic_Price__c * record.Quantity);
//v['summationAppWDRetReqDiscbasic'] = v['summationAppWDRetReqDiscbasic'] ? v['summationAppWDRetReqDiscbasic'] +sum:sum;
v['summationAppWDRetReqDiscbasic'] = this.round(v['summationAppWDRetReqDiscbasic'] ? v['summationAppWDRetReqDiscbasic'] + sum : sum);
}
}
calculateApprWDRetentionAmtSACConsumerBasicRs(v) {
return this.round((v['summationAppWDRetReqDiscbasic'] / v['summation_listPrice']) * 100);
}

summation_ReqWDCONT(v, record) {
let sum = (record.Requested_WD_CONT_Req_Disc_Basic__c / 100) * (record.UnitPrice * record.Quantity);
v['summationReqWDCONT'] = this.round(v['summationReqWDCONT'] ? v['summationReqWDCONT'] + sum : sum);
}

calculateRequestedWDCONTAmountConsumerBasic(v) {
return this.round((v.summationReqWDCONT / v.summation_listPrice) * 100);
}

summation_ApprovedWDCONT(v, record) {
if (!record.Approved_WD_CONT__c) {
record.Approved_WD_CONT__c = 0;
}
let sum = (record.Approved_WD_CONT__c / 100) * (record.Approved_Customer_Discounted_Basic_Price__c * record.Quantity);
//v['summationApprovedWDCONT'] = v['summationApprovedWDCONT'] ? v['summationApprovedWDCONT'] +sum:sum;
v['summationApprovedWDCONT'] = this.round(v['summationApprovedWDCONT'] ? v['summationApprovedWDCONT'] + sum : sum);
}

calculateApprovedWDCONTAmountConsumerBasic(v) {
return this.round((v.summationApprovedWDCONT / v.summation_listPrice) * 100);
}

calculateReqNetRlizdBscDisc(v, record) {
record.Req_Net_Rlizd_Bsc_Disc__c = this.round(record.Requested_Customer_Discount__c + v.ReqWDRetentionAmtSAConConsumerBasic + v.RequestedWDCONTAmountConsumerBasic);
}

calculateReqNetRealizdBsicAmntRateUnit(v, record) {
record.Req_Net_Realizd_BsicAmnt_Rate_Unit__c = this.round(record.ListPrice * (1 - (record.Req_Net_Rlizd_Bsc_Disc__c / 100)));
}

summation_ReqNetRealizdBsicAmntRateUnit(v, record) {
if (!record.Req_Net_Realizd_BsicAmnt_Rate_Unit__c) {
record.Req_Net_Realizd_BsicAmnt_Rate_Unit__c = 0;
}
let sum = record.Req_Net_Realizd_BsicAmnt_Rate_Unit__c * record.Quantity;
v['summationReqNetRealizdBsicAmntRateUnit'] = this.round(v['summationReqNetRealizdBsicAmntRateUnit'] ? v['summationReqNetRealizdBsicAmntRateUnit'] + sum : sum);
}

calculateApprovedNetRealizedBasicDiscount(v, record) {
record.Approved_Net_Realized_Basic_Discount__c = this.round(parseFloat(record.Approved_Customer_Discount__c) + v.ApprWDRetentionAmtSACConsumerBasicRs + v.ApprovedWDCONTAmountConsumerBasic);
}

calculateApprovedNetRealizedBasicRateUnit(v, record) {
record.Approved_Net_Realized_Basic_Rate_Unit__c = this.round(record.ListPrice * (1 - (record.Approved_Net_Realized_Basic_Discount__c / 100)));
}

//Error
summation_ApprovedNetRealizedBasicRateUnit(v, record) {
let sum = record.Approved_Net_Realized_Basic_Rate_Unit__c * record.Quantity;
v['summationApprovedNetRealizedBasicRateUnit'] = this.round(v['summationApprovedNetRealizedBasicRateUnit'] ? v['summationApprovedNetRealizedBasicRateUnit'] + sum : sum);
}

summation_COPperUnit(v, record) {
let sum = record.COP__c * record.Quantity;
v['summationCOPperUnit'] = this.round(v['summationCOPperUnit'] ? v['summationCOPperUnit'] + sum : sum);
}
calculateRequestedCOPFactor(v, record) {
record.Requested_COP_Factor__c = this.round(record.Req_Net_Realizd_BsicAmnt_Rate_Unit__c / record.COP__c);
}

summation_RequestedCOPFactor(v, record) {
v.summationRequestedCOPFactor = this.round(v.summationReqNetRealizdBsicAmntRateUnit / v.summationCOPperUnit);
}

calculateApprovedCOPFactor(v, record) {
record.Approved_COP_Factor__c = this.round(record.Approved_Net_Realized_Basic_Rate_Unit__c / record.COP__c);
}
summation_ApprovedCOPFactor(v) {
let value = v.summationApprovedNetRealizedBasicRateUnit / v.summationCOPperUnit;
value = this.round(value);
v['summationApprovedCOPFactor'] = value;
}

//Added by rohit

summation_ReqWDRetSACOnReqDiscBasic_Percentage(v){
v['summationReqWDRetSACOnReqDiscBasic_Percentage'] = this.round((v.summationReqWDRetSACOnReqDiscBasic / v.summation_unitPrice) * 100);
}

summation_ReqWDRetSACOnConsumerBasic_Percentage(v){
v['summationReqWDRetSACOnConsumerBasic_Percentage'] = this.round((v.summationReqWDRetSACOnReqDiscBasic / v.summation_listPrice) * 100);
}

summation_AppWDRetReqDiscBasic_Percentage(v){
v['summationAppWDRetReqDiscBasic_Percentage'] = this.round((v.summationAppWDRetReqDiscbasic / v.summationApprovedCustomerDiscountedBasicPrice) * 100);
}

summation_AppWDRetConsumerBasic_Percentage(v){
v['summationAppWDRetConsumerBasic_Percentage'] = this.round((v.summationAppWDRetReqDiscbasic / v.summation_listPrice) * 100);
}

summation_ReqWDCONTOnReqDiscBasic_Percentage(v){
v['summationReqWDCONTOnReqDiscBasic_Percentage'] = this.round((v.summationReqWDCONT / v.summation_unitPrice) * 100);
}

summation_ReqWDCONTOnConsumerBasic_Percentage(v){
v['summationReqWDCONTOnConsumerBasic_Percentage'] = this.round((v.summationReqWDCONT / v.summation_listPrice) * 100);
}

summation_ApprovedWDCONTOnReqDiscBasic_Percentage(v){
v['summationApprovedWDCONTOnReqDiscBasic_Percentage'] = this.round((v.summationApprovedWDCONT / v.summationApprovedCustomerDiscountedBasicPrice) * 100);
}

summation_ApprovedWDCONTOnConsumerBasic_Percentage(v){
v['summationApprovedWDCONTOnConsumerBasic_Percentage'] = this.round((v.summationApprovedWDCONT / v.summation_listPrice) * 100);
}

summation_UnitPrice_Percentage(v){
v['summationUnitPrice_Percentage']=this.round((1 - v.summation_unitPrice / v.summation_listPrice) * 100);
}

summation_ApprovedCustomerDiscountedBasicPrice_Percentage(v){
if(v.summationApprovedCustomerDiscountedBasicPrice > 0){
v['summationApprovedCustomerDiscountedBasicPrice_Percentage']=this.round((1 - v.summationApprovedCustomerDiscountedBasicPrice / v.summation_listPrice) * 100);
}
}
summation_ReqNetRealizdBsicAmntRateUnit_Percentage(v){
v['summationReqNetRealizdBsicAmntRateUnit_Percentage']=this.round((1 - v.summationReqNetRealizdBsicAmntRateUnit / v.summation_listPrice) * 100);
}

summation_ApprovedNetRealizedBasicRateUnit_Percentage(v){
v['summationApprovedNetRealizedBasicRateUnit_Percentage']=this.round((1 - v.summationApprovedNetRealizedBasicRateUnit / v.summation_listPrice) * 100);
}

grandTotal = {};
helper_GrandTotalCalculation() {
this.grandTotal.grandTotal_listPrice = 0;
this.grandTotal.grandTotal_unitPrice = 0;
this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice = 0;
this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic = 0;
this.grandTotal.grandTotalAppWDRetReqDiscbasic = 0;
this.grandTotal.grandTotalReqWDCONT = 0;
this.grandTotal.grandTotalApprovedWDCONT = 0;
this.grandTotal.grandTotalReqNetRealizdBsicAmntRateUnit = 0;
this.grandTotal.grandTotalApprovedNetRealizedBasicRateUnit = 0;
this.grandTotal.grandTotalAppWDRetReqDiscbasic = 0;
this.grandTotal.grandTotalCOPperUnit = 0;

this.qliRecords.filter(v => {
this.grandTotal.grandTotal_listPrice += v.summation_listPrice;
this.grandTotal.grandTotal_unitPrice += v.summation_unitPrice;
this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice += v.summationApprovedCustomerDiscountedBasicPrice;
this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic += v.summationReqWDRetSACOnReqDiscBasic;
this.grandTotal.grandTotalAppWDRetReqDiscbasic += v.summationAppWDRetReqDiscbasic;
this.grandTotal.grandTotalReqWDCONT += v.summationReqWDCONT;
this.grandTotal.grandTotalApprovedWDCONT += v.summationApprovedWDCONT;
this.grandTotal.grandTotalReqNetRealizdBsicAmntRateUnit += v.summationReqNetRealizdBsicAmntRateUnit;
this.grandTotal.grandTotalApprovedNetRealizedBasicRateUnit += v.summationApprovedNetRealizedBasicRateUnit;
this.grandTotal.grandTotalCOPperUnit += v.summationCOPperUnit;
})
this.grandTotal.grandTotalRequestedCOPFactor = this.grandTotal.grandTotalReqNetRealizdBsicAmntRateUnit / this.grandTotal.grandTotalCOPperUnit;
this.grandTotal.grandTotalApprovedCOPFactor = this.grandTotal.grandTotalApprovedNetRealizedBasicRateUnit / this.grandTotal.grandTotalCOPperUnit;

this.grandTotal.grandTotal_ReqCustDisc = (1-this.grandTotal.grandTotal_unitPrice / this.grandTotal.grandTotal_listPrice) * 100;
if(this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice > 0){
this.grandTotal.grandTota_AppCustDisc = (1-this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice / this.grandTotal.grandTotal_listPrice) * 100;
}
this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic_Percentage = (this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic / this.grandTotal.grandTotal_unitPrice) * 100;
this.grandTotal.grandTotalReqWDRetSACOnReqConsBasic_Percentage = (this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic /  this.grandTotal.grandTotal_listPrice) * 100 ;
this.grandTotal.grandTotalAppWDRetReqDiscbasic_Percentage = (this.grandTotal.grandTotalAppWDRetReqDiscbasic / this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice) * 100;
this.grandTotal.grandTotalAppWDRetReqConsbasic_Percentage = (this.grandTotal.grandTotalAppWDRetReqDiscbasic/this.grandTotal.grandTotal_listPrice) * 100
this.grandTotal.grandTotalReqWDCONTReq_Percentage = (this.grandTotal.grandTotalReqWDCONT / this.grandTotal.grandTotal_unitPrice) * 100;
this.grandTotal.grandTotalReqWDCONTCons_Percentage = (this.grandTotal.grandTotalReqWDCONT / this.grandTotal.grandTotal_listPrice) * 100;
this.grandTotal.grandTotalApprovedWDCONTDisc_Percentage = (this.grandTotal.grandTotalApprovedWDCONT / this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice) * 100;
this.grandTotal.grandTotalApprovedWDCONTCons_Percentage = (this.grandTotal.grandTotalApprovedWDCONT / this.grandTotal.grandTotal_listPrice) * 100;
this.grandTotal.grandTotalReqNetRealizedDiscConsOnTotal_Percentage = (1 - this.grandTotal.grandTotalReqNetRealizdBsicAmntRateUnit / this.grandTotal.grandTotal_listPrice) * 100;
this.grandTotal.grandTotalAppNetRelaizedDiscCOnsOnBasic_Percentage = (1 - this.grandTotal.grandTotalApprovedNetRealizedBasicRateUnit / this.grandTotal.grandTotal_listPrice) * 100;

for (let key of Object.keys(this.grandTotal)) {
this.grandTotal[key] = this.round(this.grandTotal[key]);
}
}

round(value,key) {
if(typeof value ==undefined || isNaN(value)){
value =  0;
}

if (value) {
if(key && INPUT_FIELDS.includes(key)){
value =  parseFloat(parseFloat(value).toFixed(ROUNDDIGIT_INPUT));
}else{
value =  parseFloat(parseFloat(value).toFixed(ROUNDDIGIT_OUTPUT));
}
}
return value;
}

handleResubmit(event) {
this.helperDisplaySpinner();
let qliRecords = this.getQLIRecordsListToSubmit(STATUS_RESUBMIT);
if(qliRecords.length > 0){
this.helper_ApprovalFunction(qliRecords,STATUS_RESUBMIT);
}
}

handleReject(){
this.helperDisplaySpinner();
let qliRecords = this.getQLIRecordsListToSubmit(STATUS_REJECTED);
this.helper_ApprovalFunction(qliRecords,STATUS_REJECTED);
}

handleApprovalClick(event) {
let buttonAction = event.target.name ;   //added by Snehal w 18/09/2023 
if(this.isValid == false){ //added by Snehal w 13/06/2023
this.helperErrorMessage("Approved percentages should not be more than Requested Percentages");
return;
}
this.helperDisplaySpinner();
//let approvalStatus = this.is_Salesperson_Persona?(event.currentTarget.dataset.id=='saveAction'?STATUS_DRAFT:STATUS_SUBMITTED_FOR_APPROVAL):STATUS_APPROVED;
let approvalStatus = event.currentTarget.dataset.id=='saveAction'?STATUS_DRAFT:event.currentTarget.dataset.id;
let qliRecords = this.getQLIRecordsListToSubmit(approvalStatus);   

this.helper_ApprovalFunction(qliRecords,approvalStatus,buttonAction);//
}

helper_ApprovalFunction(qliRecords,approvalStatus,actionSave){
let approvalCommentsQLI;  
approvalCommentsQLI = this.getApprovalComments();
if(approvalStatus == STATUS_SUBMITTED_FOR_APPROVAL){
for (let record of qliRecords) { //Added by snehal w 04/09/2023
if (!record.Quote.Transaction_Type__c) { 
    this.helperErrorMessage("Order Type can't be blank.");
    return;
}else  if (!record.Quote.Transaction_Type_c__c) { 
    this.helperErrorMessage("Transaction Type can't be blank.");
    return;
}
else if (new Date(record.Quote.Opportunity.CloseDate) < new Date()) { 
    this.helperErrorMessage("Close Date should not be in the past.");
    return;
}else  if (!record.Product2.Product_Type__c) { 
    this.helperErrorMessage("Product Type can't be blank.");
    return;
}
else  if (!record.Quote.Opportunity.Owner.Persona__c) { 
    this.helperErrorMessage("Persona can't be blank.");
    return;
}
else  if (!record.Quote.Opportunity.Owner.ManagerId) { 
    this.helperErrorMessage("Manager can't be blank.");
    return;
}
else  if (record.Quote.Interio_Sub_Division__c == 'B2B-BD') { 
    this.helperErrorMessage("Interio sub division should not be B2B-BD");
    return;
}
else  if (record.UnitPrice > record.ListPrice) { 
    this.helperErrorMessage("List price should not be less than Reuqsted customer discount basic price");
    return;
}
}
if(!approvalCommentsQLI ||  approvalCommentsQLI.trim()=='' || typeof approvalCommentsQLI == undefined){
this.helperErrorMessage("Comments can't be blank.");
return ;
}
}
callApprovalFunction({ qliRecords: qliRecords,approvalStatus:approvalStatus})
.then(result => {

if(approvalStatus==STATUS_RESUBMIT){
    this.displayToast('success', 'Resubmission request received. It is in progress in background.');
}else if(approvalStatus==STATUS_REJECTED){
    this.displayToast('success', 'Rejection request received. It is in progress in background.');
}
else if(this.is_Salesperson_Persona || this.is_Cst_Persona){
    this.displayToast('success', 'Approval submission request received. It is in progress in background.');
}else if(actionSave =='saveAction'){
    this.displayToast('Saved successfully');
}
else{
    this.displayToast('success', 'Approved successfully.');
}

let qliIds = [];
if(actionSave != 'saveAction'){
    this.addApprovalComments(qliRecords[0].QuoteId,approvalStatus);
}
})
.catch(error => {
this.helperErrorMessage(error);
});
}

getQLIRecordsListToSubmit(approvalStatus) {
let qliRecordList = [];               
this.qliRecords.filter(v => {
v.records.filter(record => {
//if ( (this.userinfo.Persona__c != PERSONA_HO) || (this.userinfo.Persona__c == PERSONA_HO &&  record.Current_Approver__c == this.userQueueIds)) {
//if ( (this.userinfo.Id == record.Current_Approver__c) || (this.userQueueIds && this.userQueueIds.includes(record.Current_Approver__c) )) {
if ( (this.is_Salesperson_Persona==true)|| (this.is_Cst_Persona==true) || (!record.isReadOnly &&  this.is_Cst_Persona==false) || (!record.isReadOnly &&  this.is_Salesperson_Persona==false)) {
record.Req_WD_Ret_Amt_SACConsBasic__c = v.ReqWDRetentionAmtSAConConsumerBasic;
record.Apr_WD_Ret_Amt_SACConsBasic__c = v.ApprWDRetentionAmtSACConsumerBasicRs;
record.Req_WD_CONT_Amt_Consumer_Basic__c = v.RequestedWDCONTAmountConsumerBasic;
record.Approved_WD_CONT_Amt_Consumer_Basic__c = v.ApprovedWDCONTAmountConsumerBasic;

if(this.is_Salesperson_Persona==true || this.is_Cst_Persona==true){
//thi.helperAddCommentsQLI(record);
if(approvalStatus==STATUS_DRAFT){
    record.Approval_Status__c = STATUS_DRAFT;
}
}

if(approvalStatus == STATUS_RESUBMIT && ((record.Product_Line_c__c != 'STORAGE' && record.Product_Line_c__c != 'DESKING' ) || ( record.Product_Line_c__c === 'STORAGE' )|| (record.Product_Line_c__c === 'DESKING' ))
){
    record.Current_Approver__c = record.Quote.Opportunity.OwnerId;
    record.Pending_With_Owner__c = record.Quote.Opportunity.Owner.Name;
    record.Approval_Status__c = STATUS_RESUBMIT;
}

if(approvalStatus == STATUS_REJECTED){
    record.Current_Approver__c = '';
    record.Approval_Status__c = STATUS_REJECTED;
}

    record.Quote.Total_List_Price__c = this.grandTotal.grandTotal_listPrice;
    record.Quote.Req_Cust_Disc__c = this.grandTotal.grandTotal_ReqCustDisc;
    record.Quote.Total_Sales_Price__c = this.grandTotal.grandTotal_unitPrice;
    record.Quote.App_Cust_Disc__c = this.grandTotal.grandTota_AppCustDisc;
    record.Quote.Total_Approved_Customer_Discount_Price__c = this.grandTotal.grandTotalApprovedCustomerDiscountedBasicPrice;
    record.Quote.Req_WD_Retention_SAC_Amnt_Req_Disc_Bsc__c = this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic;
    record.Quote.Req_WD_Retention_SAC_Amnt_Req_Cons_Bsc__c = this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic;
    record.Quote.Appr_WD_Ret_SAC_Amt_appr_Disc_Bsc__c = this.grandTotal.grandTotalAppWDRetReqDiscbasic;
    record.Quote.Appr_WD_Ret_SAC_Amt_on_cons_Bsc__c = this.grandTotal.grandTotalAppWDRetReqDiscbasic;
    record.Quote.Req_WD_CONT_Amt_on_Req_Disc_bsc__c = this.grandTotal.grandTotalReqWDCONT;
    record.Quote.Req_WD_CONT_amt_on_cons_bsc__c = this.grandTotal.grandTotalReqWDCONT;
    record.Quote.Appr_WD_CONT_Amt_On_Appr_Disc_Bsc__c = this.grandTotal.grandTotalApprovedWDCONT;
    record.Quote.Appr_WD_CONT_Amt_On_Cons_Bsc__c = this.grandTotal.grandTotalApprovedWDCONT;
    record.Quote.Req_Net_Rlizd_Basic_Rate_Cons__c = this.grandTotal.grandTotalReqNetRealizdBsicAmntRateUnit;
    record.Quote.Appr_Net_Rlizd_Basic_Rate_Cons__c = this.grandTotal.grandTotalApprovedNetRealizedBasicRateUnit;
    record.Quote.COP__c = this.grandTotal.grandTotalCOPperUnit;
    record.Quote.Requested_COP_Factor__c = this.grandTotal.grandTotalRequestedCOPFactor;
    record.Quote.Approved_COP_Factor__c = this.grandTotal.grandTotalApprovedCOPFactor;
    record.Quote.Req_WD_Ret_Disc_Basic__c = this.grandTotal.grandTotalReqWDRetSACOnReqDiscBasic_Percentage;
    record.Quote.Req_WD_Ret_Cons_Basic__c = this.grandTotal.grandTotalReqWDRetSACOnReqConsBasic_Percentage;
    record.Quote.Appr_WD_Ret_Disc_Basic__c = this.grandTotal.grandTotalAppWDRetReqDiscbasic_Percentage;
    record.Quote.Appr_WD_Ret_Cons_Basic__c = this.grandTotal.grandTotalAppWDRetReqConsbasic_Percentage;
    record.Quote.Req_WD_CONT__c = this.grandTotal.grandTotalReqWDCONTReq_Percentage;
    record.Quote.Req_WD_CONT_Cons_Basic__c = this.grandTotal.grandTotalReqWDCONTCons_Percentage;
    record.Quote.Appr_WD_CONT_Disc_Basic__c = this.grandTotal.grandTotalApprovedWDCONTDisc_Percentage;
    record.Quote.Appr_WD_CONT_Cons_Basic__c = this.grandTotal.grandTotalApprovedWDCONTCons_Percentage;
    record.Quote.Req_Net_Rlizd_Disc_Cons_Basic__c = this.grandTotal.grandTotalReqNetRealizedDiscConsOnTotal_Percentage;
    record.Quote.Appr_Net_Relzd_Bsc_Disc_On_Cons_Bsc__c = this.grandTotal.grandTotalAppNetRelaizedDiscCOnsOnBasic_Percentage;
    record.Quote.LOBSummaryTotal__c=JSON.stringify(this.LobWiseSummaryToStoreOnQuoteAsJson);

// added by snehal W 12/06/2023
if (
    approvalStatus === STATUS_RESUBMIT &&
    this.is_HO_Persona == true && 
   ( ((!record.Quote.Opportunity.Account.Is_Key_Account__c && !record.Quote.End_Customer__r.Is_Key_Account__c) &&
        (record.Quote.Transaction_Type_c__c != TRANSACTION_TYPE_GEM_RC && record.Quote.Transaction_Type_c__c != TRANSACTION_TYPE_GEM && record.Quote.Transaction_Type_c__c != TRANSACTION_TYPE_GEM_PAC ))
    &&
    (
      (this.isResubmitStorageProducts === false && record.Product_Line_c__c === 'STORAGE' ) ||
      (this.isResubmitDeskingProducts === false && record.Product_Line_c__c === 'DESKING' )
    ) )
  ) {
      console.log('i am in if condition');
  }
else{
    let rec = JSON.parse(JSON.stringify(record));
    delete rec.Product_Line_c__c;//delete picklist value due to restricted value;
if(approvalStatus != STATUS_RESUBMIT){ // Added by Snehal W 12/06/2023
    delete rec.Pending_With_Owner__c;
}
qliRecordList.push(rec);
}
}
});
});
return qliRecordList;
}
getApprovalComments(){
const lobKey = "data-id='approvalComments'"; 
return this.template.querySelectorAll("lightning-input["+lobKey+"]")[0].value;
}

addApprovalComments(quoteId,approvalStatus) {
let approvalComments =[];
let enteredComments = this.getApprovalComments();
approvalComments.push({
'sobjectType' : 'Quote_Approval_History__c',
'Approval_Comments__c' : enteredComments?enteredComments:'',
'Status__c' : approvalStatus,
//'Line_of_Business__c':element.dataset.id,
'Quote__c' : quoteId
});
if(approvalComments){       
    this.helperInsertComments(approvalComments);
}
this.helperHideSpinner();
}
helperInsertComments(approvalComments){
createApprovalComments({ 'approvalComments': approvalComments })
.then(result => {
this.displayToast('success', 'Approval comments added succesfully.');
this.helperHideSpinner();
this.closeModal();
})
.catch(error => {
this.helperErrorMessage(error);
});
}
helperHideSpinner() {
this.hideSpinner = true;
}
helperDisplaySpinner() {
this.hideSpinner = false;
}

closeModal() {
this.dispatchEvent(new CustomEvent('closemodal', { detail: true }));
//this.dispatchEvent(new CloseActionScreenEvent());
}

displayToast(type, message) {
const event = new ShowToastEvent({
title: type,
message: message,
variant: message
});
this.dispatchEvent(event);
}

helperErrorMessage(error){
if(error && error.body && error.body.message){
    this.displayToast('error', error.body.message);
}else{
    this.displayToast('error', error);
}

this.helperHideSpinner();
}
// added by snehal W 13/06/2023
handleChange1(event) {
if (!this.is_HO_Persona) {
    return; // Do nothing if is_HO_Persona is false
}else{
this.isResubmitStorageProducts = event.target.checked; // returning true if checked and false if unchecked.
}
}
handleChange2(event) {
if (!this.is_HO_Persona) {
    return; // Do nothing if is_HO_Persona is false
}else{
    this.isResubmitDeskingProducts = event.target.checked;
}
}
// Added by snehal W 29/06/2023
handleFormFactor() {
if (FORM_FACTOR === "Large") {
    this.deviceType = "Deskop/Laptop";
    this.thclass = `slds-cell-wrap`;
}
else if (FORM_FACTOR === "Medium") {
    this.deviceType = "Tablet";
    this.tablediv = `overflow-x: auto; overflow-y: auto`;
    this.tablestyle = `width : 500%`;
} else if (FORM_FACTOR === "Small") {
    this.deviceType = "Mobile";
    this.tablediv = `overflow-x: auto; overflow-y: auto`;
    this.tablestyle = `width : 500%`;
}
}

}