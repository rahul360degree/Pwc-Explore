/**
 * @description       : Created for https://gnbdigitalprojects.atlassian.net/browse/SMEPB-24
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 05-24-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api } from 'lwc';
import getPendingApprovals from '@salesforce/apex/PendingApprovalsMHE.doInit'
import { NavigationMixin } from 'lightning/navigation';

export default class PendingApprovalMHE extends NavigationMixin(LightningElement){
    @api sObjectName = 'Pricing_approval_request__c';
    @api recordsToDisplay=[];
    @api spinner = false;

    connectedCallback() {
        this.fetchProcessWorkItems();
    }

    fetchProcessWorkItems() {
        getPendingApprovals({ sObjectName: this.sObjectName })
            .then(result => {
                console.log(result);
                if (result) {
                    this.dataCreationHelper(result);
                }else{
                    this.spinner = true;
                }
            })
            .catch(error => {
                this.spinner = true;
                console.log(error);
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
        if (result && result.parRecords && result.quoteRecords) {
            result.parRecords.filter(par => {
                result.quoteRecords.filter(quote => {
                    if (par.Quote__c == quote.Id) {
                        quoteMap.set(par.Id, quote);
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
                obj.ActorName = v.Actor.Name;
                obj.ElapsedTimeInDays = v.ElapsedTimeInDays;
                obj.Id = v.Id;
                //obj.CreatedDate = v.CreatedDate;

                obj.AreaCode = quote.Area_Code__c;
                obj.CreatedDate = quote.CreatedDate;
                obj.OpportunityName = quote.Opportunity.Name;
                obj.OpportunityId = quote.OpportunityId;
                obj.EnquiryCategory = quote.Opportunity.MHE_Division__c;
                obj.QuoteNo = quote.QuoteNumber;
                obj.ApprovedPrice = quote.Total_Unit_Basic__c;
                obj.qliRecord = [];
                obj.QuoteId = quote.Id;


                quote.QuoteLineItems.filter(qli => {
                    let qliObject = { Product: '', RequestedDiscount: 0, ApprovedDiscount: 0 };
                    qliObject.Product = (typeof qli.Product_Name__c == undefined || qli.Product_Name__c == null) ? '' : qli.Product_Name__c;
                    qliObject.RequestedDiscount = ((typeof qli.Requested_Customer_Discount__c == undefined || qli.Requested_Customer_Discount__c == null) ? 0 : qli.Requested_Customer_Discount__c)/100;
                    qliObject.ApprovedDiscount = ((typeof qli.Approved_Customer_Discount__c == undefined || qli.Approved_Customer_Discount__c == null) ? 0 : qli.Approved_Customer_Discount__c)/100;
                    qliObject.Product2Id = qli.Product2Id;
                    obj.qliRecord.push(qliObject);
                })
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