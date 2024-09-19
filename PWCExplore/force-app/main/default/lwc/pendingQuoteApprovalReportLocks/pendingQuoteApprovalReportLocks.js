import { LightningElement, api } from 'lwc';
import getPendingApprovals from '@salesforce/apex/PendingQuoteApprovalReportLocksSubClass.doInit'
import { NavigationMixin } from 'lightning/navigation';
export default class PendingQuoteApprovalReportLocks extends NavigationMixin(LightningElement){
    @api sObjectName = 'Quote';
    @api recordsToDisplay=[];
    @api spinner = false;
    connectedCallback() {
        this.fetchProcessWorkItems();
    }
    fetchProcessWorkItems() {
        getPendingApprovals({ sObjectName: this.sObjectName })
            .then(result => {
                if (result) {
                    this.dataCreationHelper(result);
                }else{
                    this.spinner = true;
                }
            })
            .catch(error => {
                this.spinner = true;
            })
    }
    // prepare data
    dataCreationHelper(result) {
        let parQuoteMap = this.parQuoteMap(result);
        this.recordsToDisplay = this.recordsToDisplayHelper(result, parQuoteMap);
    }
    //Prepare map for PAR and Quote //Key=> PricingApprovalId; Value:Quote
    parQuoteMap(result) {
        let quoteMap = new Map();
        if (result && result.processInstanceRecords && result.quoteRecords) {
            result.processInstanceRecords.filter(par => {
                result.quoteRecords.filter(quote => {
                    if (par.ProcessInstance.TargetObjectId == quote.Id) {
                        quoteMap.set(par.ProcessInstance.TargetObjectId, quote);
                    }
                })
            });
        }
        return quoteMap;
    }
    //helper to Prepare the data 
    recordsToDisplayHelper(result, parQuoteMap) {
        let dataToDisplay = [];
        dataToDisplay = [];
        result.processInstanceRecords.filter(v => {
            let quote = parQuoteMap.get(v.ProcessInstance.TargetObjectId)
            if (quote) {
                let obj = {};
                obj.Id = quote.Id,
                obj.CreatedDate = quote.CreatedDate.substring(8,10)+"/"+quote.CreatedDate.substring(5,7)+"/"+quote.CreatedDate.substring(0,4),
                obj.QuoteName = quote.Name,
                obj.OpportunityName = quote.Opportunity.Name,
                obj.OpportunityOwnerName = quote.Opportunity.Owner.Name,
                obj.OpportunityId = quote.OpportunityId,
                obj.AccountName = quote.Account.Name,
                obj.QuoteNo = quote.QuoteNumber,
                obj.RaisedBy = quote.CreatedBy.Name,
                obj.PendingWith = v.Actor.Name,
                obj.PendingSince = v.ElapsedTimeInDays,
                obj.PendingSinceDate = "  ("+v.CreatedDate.substring(8,10)+"/"+v.CreatedDate.substring(5,7)+"/"+v.CreatedDate.substring(0,4)+")",
                obj.AgreedByCustomer = quote.Agreed_by_customer__c?"Yes":"No",
                obj.QuoteId = quote.Id 

                dataToDisplay.push(obj);
            }
        });
        this.spinner = true;
        return dataToDisplay;
    }
    //Open Quote Record
    handleNavigate(event){
        this.spinner = false;
        //this[NavigationMixin.Navigate]({
        this[NavigationMixin.GenerateUrl]({
            type: "standard__app",
            attributes: {
                appTarget: "standard__LightningSales",
                pageRef: {
                    type: "standard__recordPage",
                    attributes: {
                        recordId: event.currentTarget.dataset.id,
                        objectApiName: event.currentTarget.dataset.name,
                        actionName: "view"
                    }
                }
            }
       })
       .then(url => {
            window.open(url, "_blank");
        });
       ;
       this.spinner = true;
    }
}