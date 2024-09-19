/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 06-12-2023
 * @last modified by  : snehalw@godrej.com
**/
import { LightningElement,api,track } from 'lwc';
import getQuotes from '@salesforce/apex/InterioB2BApprovalProcess.quoteList';
import { NavigationMixin } from 'lightning/navigation';
export default class Interiob2bpendingquotes extends NavigationMixin(LightningElement) {
@api records;
@api quoteId;
@track hideSpinner;
displayQuoteSection = false;
sortDocumentDate='';
sortPendingDate='';
sortDirection;
fieldName;
filterDocumentId = '';
filterQuote = '';
filterAccount = '';
filterOpportunity = '';
filterSubmittingBranch = '';
filterSubmittingZone = '';
filterSegment = '';
filterTransactionType = '';
filterSalesPerson = '';
filterDocumentId = '';
showQuoteInputBox = false ;
showAccountInputBox = false ;
showOpportunityInputBox = false ;
showSubmittingBranchInputBox = false ;
showSubmittingZoneInputBox = false ;
showSegmentInputBox = false ;
showTransactionTypeInputBox = false ;
showSalesPersonInputBox = false ;
showDocumentIdInputBox = false ;
@api originalRecords ;
connectedCallback(){
  this.getQuoteData();
}
getQuoteData(){
  getQuotes({})        
  .then(result=>{
      this.displayQuoteSection = true;
      // console.log(result);
      this.records = result;
      this.originalRecords = result;
      this.helperHideSpinner();
  })
  .catch(error=>{
      console.log(error);
      this.helperHideSpinner();
  });
}

handleQuoteClick(event){
  this.displayQuoteSection = false;
  this.quoteId = event.target.dataset.id;
}
closeModal(event){
  this.quoteId = null;
  this.displayQuoteSection = true;
}

helperHideSpinner(){
  this.hideSpinner = true;
}
helperDisplaySpinner(){
  this.hideSpinner = false;
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

handleSorting(event) {    
  this.fieldName = event.target.dataset.name;
  this.sortDocumentDate = (this.fieldName==='CreatedDate') ? ((this.sortDocumentDate==='' || this.sortDocumentDate==='↑') ? '↓' : '↑'):'' ;
  this.sortPendingDate = (this.fieldName==='Pending_Since_Date__c') ? ((this.sortPendingDate==='' || this.sortPendingDate==='↑') ? '↓' : '↑'):'' ;
  this.sortDirection = (this.fieldName==='CreatedDate') ? (this.sortDocumentDate==='↑' ?'asc':'desc'):(this.sortPendingDate==='↑' ?'asc':'desc');   

  let parseData = JSON.parse(JSON.stringify(this.records));
  // Return the value stored in the field
  let keyValue = (a) => {
      return a[this.fieldName];
  };
  // cheking reverse direction
  let isReverse = this.sortDirection === 'asc' ? 1: -1;
  // sorting data
      parseData.sort((x, y) => {
          x = keyValue(x) ? keyValue(x) : ''; // handling null values
          y = keyValue(y) ? keyValue(y) : '';
          // sorting values based on direction
          return isReverse * ((x > y) - (y > x));
      });
      this.records = parseData;
      
  }
  // Added by snehal W 12/06/2023
  // Add filter functions
  handleFilterQuote(event) {
      this.filterQuote = event.target.value.toLowerCase();
      this.filterRecords();
    }
    

handleFilterAccount(event) {
this.filterAccount = event.target.value.toLowerCase();
this.filterRecords();
}
handleFilterOpportunity(event) {
this.filterOpportunity = event.target.value.toLowerCase();
this.filterRecords();
} 
handleFilterSubmittingBranch(event) {
this.filterSubmittingBranch = event.target.value.toLowerCase();
this.filterRecords();
} 
handleFilterSubmittingZone(event) {
this.filterSubmittingZone = event.target.value.toLowerCase();
this.filterRecords();
}
/*
handleFilterSegment(event) {
this.filterSegment = event.target.value.toLowerCase();
this.filterRecords();
}*/
handleFilterTransactionType(event) {
this.filterTransactionType = event.target.value.toLowerCase();
this.filterRecords();
}
handleFilterSalesPerson(event) {
this.filterSalesPerson = event.target.value.toLowerCase();
this.filterRecords();
}
handleFilterDocumentId(event) {
this.filterDocumentId = event.target.value.toLowerCase();
this.filterRecords();
}
// Added by snehal W 12/06/2023
filterRecords() { // filtering the records based on the criteria
let filteredRecords = [...this.originalRecords];

filteredRecords = filteredRecords.filter(rec => { //  filteredRecords array is filtered using the filter() method
let quoteMatch = rec.Name.toLowerCase().includes(this.filterQuote);
let accountMatch = rec.Account.Name.toLowerCase().includes(this.filterAccount);
let opportunityMatch = rec.Opportunity.Name.toLowerCase().includes(this.filterOpportunity);
let submittingBranchMatch = rec.Sales_Branch_Name__c.toLowerCase().includes(this.filterSubmittingBranch);
let submittingZoneMatch = rec.Zone__c.toLowerCase().includes(this.filterSubmittingZone);
//let segmentMatch = rec.End_Customer_Segment__c.toLowerCase().includes(this.filterSegment);
let transactionTypeMatch = rec.Transaction_Type_c__c.toLowerCase().includes(this.filterTransactionType);
let salesPersonMatch = rec.Opportunity.Owner.Name.toLowerCase().includes(this.filterSalesPerson);
let documentIdMatch = rec.QuoteNumber.toLowerCase().includes(this.filterDocumentId);

return quoteMatch && accountMatch && opportunityMatch && submittingBranchMatch && submittingZoneMatch && salesPersonMatch && documentIdMatch && transactionTypeMatch;  // && segmentMatch
});
this.records = filteredRecords;
}
// Added by snehal W 12/06/2023
handleVisibility(event) {
this.fieldName = event.target.dataset.name; // used to identify which field's visibility is being toggled.
if (this.fieldName === 'Quote') {
this.showQuoteInputBox = !this.showQuoteInputBox; 

  this.filterQuote = ''; // resetting value
  

}
if (this.fieldName === 'Account') {
  this.showAccountInputBox = !this.showAccountInputBox;
    this.filterQuote = '';
}
if (this.fieldName === 'Opportunity') {
  this.showOpportunityInputBox = !this.showOpportunityInputBox;
    this.filterOpportunity = '';
}
if (this.fieldName === 'Sales_Branch_Name__c') {
  this.showSubmittingBranchInputBox = !this.showSubmittingBranchInputBox;
    this.filterSubmittingBranch = '';
}
if (this.fieldName === 'Zone__c') {
  this.showSubmittingZoneInputBox = !this.showSubmittingZoneInputBox;
    this.filterSubmittingZone = '';
}
/*
if (this.fieldName === 'End_Customer_Segment__c') {
  this.showSegmentInputBox = !this.showSegmentInputBox;
    this.filterSegment = '';
} */
if (this.fieldName === 'Transaction_Type_c__c') {
  this.showTransactionTypeInputBox = !this.showTransactionTypeInputBox;
    this.filterTransactionType = '';
} 
if (this.fieldName === 'Opportunity.Owner.Name') {
  this.showSalesPersonInputBox = !this.showSalesPersonInputBox;
    this.filterSalesPerson = '';
} 
if (this.fieldName === 'QuoteNumber') {
  this.showDocumentIdInputBox = !this.showDocumentIdInputBox;
    this.filterDocumentId = '';
} 

this.filterRecords();
}

}