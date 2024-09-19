/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-11-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, track, wire,api } from 'lwc';
import getProdList from '@salesforce/apex/AddOpportunityProductHelper.getProdList';
import upsertReecord from '@salesforce/apex/AddOpportunityProductHelper.upsertReecord';
import fetchLandedRate from '@salesforce/apex/AddOpportunityProductHelper.fetchLandedRate';
import { refreshApex } from '@salesforce/apex';
import { updateRecord  } from 'lightning/uiRecordApi';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Product Type', fieldName: 'Label' },
    { label: 'User Input Price', fieldName: 'User_Price__c', type: 'number', editable: true },
];

const savedLandedRateColumn = [
    { label: 'Label', fieldName: 'Label__c' },
    { label: 'Landed Rate', fieldName: 'Landed_Rate__c', type: 'currency' }
    
];
let query='Select Id,Name';
savedLandedRateColumn.filter(v=>{
    query += ', '+v.fieldName;

})
export default class AddOpportunityProduct extends LightningElement {
    @track isData = false;
    columns = COLUMNS;
    draftValues = []
    @track error;
    @track prodList;

    _wiredResult;
    @api recordId='';
    @api savedLandedRateColumn = savedLandedRateColumn;
    @track savedLandedRatedata;
    query = query;


  @wire(fetchLandedRate,{recordId:'$recordId',query:'$query'})
  wiredLandedRatedata(result){
    this._wiredResult = result;
    if (result.data) {
        this.savedLandedRatedata = result.data;
    } else if (result.error) {
        console.log(error);
    }
  }
 
    //Method called on button click
    handleClick(event) {
        getProdList().then(result => {
            result.filter(v=>{
                this.savedLandedRatedata.filter(k=>{
                    if(v.DeveloperName==k.Name){
                        v.User_Price__c = k.Landed_Rate__c
                        return v;
                    }
                })
            })
            //this.prodList = result;
            this.prodList =result.sort((a, b) => a.Product_Sequence__c - b.Product_Sequence__c);  //Added by poonam(SCF - 102)
            this.error = undefined;
            this.isData = true;
        })
            .catch(error => {
                console.log(error);
                this.error = error;
                this.prodList = undefined;
                this.isData = false;
            });
    }

    //On Save Event
    saveHandleAction(event) {
        this.isData = false;
        console.log(event.detail.draftValues);
        let recordData = event.detail.draftValues;
        let landedRecords = [];
        event.detail.draftValues.filter(row => {
            let orginalRow =  this.prodList.filter(k=>k.Id==row.Id)[0];
            let recordtoUpsert = this.savedLandedRatedata.filter(v=>v.Name==orginalRow.DeveloperName);
            const recordtoUpsertId = recordtoUpsert.length>0?recordtoUpsert[0].Id:null;
            let obj = {
                sobjectType: 'Opportunity_Landed_Rate__c',
                Landed_Rate__c: row.User_Price__c,
                Related_Opportunity__c: this.recordId,
                Name: orginalRow.DeveloperName,
                Id:recordtoUpsertId,
                Label__c:orginalRow.Label 
            }
            landedRecords.push(obj);
        })

        upsertReecord({landedRecords:landedRecords, opportunityId:this.recordId})
            .then(result => {
                this.refreshData();
                this.handleCancel();
                window.location.reload(true);
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleCancel(){
        this.isData = false;
    }

    refreshData() {
        return refreshApex(this._wiredResult);
    }



}