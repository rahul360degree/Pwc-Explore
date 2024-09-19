/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 04-06-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api, wire, track } from 'lwc';
import getApprovalProcess from '@salesforce/apex/BillingBulkApproval.getPendingApprovals';
import submitForApproval from '@salesforce/apex/BillingBulkApproval.submitForApproval';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import Type_Billing from '@salesforce/schema/Billing__c.Type_of_billing__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
	{ label: 'Client Name', fieldName: 'accountLink', type: "url", sortable: "true",typeAttributes: { label: { fieldName: "Account" }, target: "_blank" } },
	{ label: 'Bill No', fieldName: 'billingLink', type: "url", typeAttributes: { label: { fieldName: "Name" }, target: "_blank" } },
	{ label: 'Billing Start Date', fieldName: 'startDate' },
	{ label: 'Billing End Date', fieldName: 'endDate' },
	{ label: 'Charge Type', fieldName: 'ChargeType' , sortable: "true"},
	{ label: 'Asset', fieldName: 'asset' },
	{ label: 'Amount Payable', type: 'currency' , fieldName: 'AmountPayable' },
	{ label: 'GST', type: 'currency' , fieldName: 'tax' },
	{ label: 'Total Amount', type: 'currency' , fieldName: 'TotalAmount' },
	{ label: 'Billing Type', fieldName: 'TypeOfBilling' },
];

export default class BillingBulkApproval extends LightningElement {
	@track showSpinner = true;
	@track sortBy;
    @track sortDirection;
	@api objectName = 'Billing__c';
	@api fieldNames = 'ProcessInstance.TargetObject.Name';
	selectedWorkIds = [];
	@track data = [];
	@track filteredData = [];
	columns = columns;
	rowOffset = 0;
	@track typePicklistValues = [];
	type_value = 'All';
	chargeId = '';
	accountName = '';
	//4 Fields to show the Grand Totals and record count 
	@track grandAmountPayable = 0;
	@track grandGST = 0;
	@track grandTotalAmount = 0;
	@track recordCount = 0;

	//intialize
	connectedCallback() {
		this.getApprovalProcess();
	}

	//Get Picklist values for Type Filter
	@wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Type_Billing })
	picklistValues({ error, data }) {
		if (data) {
			console.log(data);
			this.typePicklistValues = [...data.values];
			this.typePicklistValues.push({ label: 'All', value: 'All' });
		} else if (error) {
			console.log(error);
		}
	}

    doSorting(event) {
		let sortbyField = event.detail.fieldName;
		if (sortbyField === "accountLink") {
		  this.sortBy = "Account";
		} else {
		  this.sortBy = sortbyField;
		}
        //this.sortBy = event.detail.fieldName;
		console.log('this.sortBy:'+this.sortBy);
    	this.sortDirection = event.detail.sortDirection;
		console.log('this.sortDirection:'+this.sortDirection);
        this.sortData(this.sortBy, this.sortDirection);
		this.sortBy = sortbyField;
    }

	sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.filteredData));
		// Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
		
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
		// sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.filteredData = parseData;
    }    

	//  prepare data to display in table
	getApprovalProcess() {
		getApprovalProcess({ objectName: this.objectName, fieldNames: this.fieldNames })
			.then(result => {
				let workItems = result.workRecords;
				let sobjectRecords = result.records;
				//dancer_ages.length
				let record = [];
				workItems.filter(v => {
					let object = v.ProcessInstance.TargetObject;
					let billingRecord = sobjectRecords.filter(vr => (vr.Id == object.Id))[0];
					this.objectHelper(v, object, billingRecord);
					this.grandAmountPayable+=billingRecord.Amount_Payable__c;
					this.grandGST+=billingRecord.Tax__c;
					this.grandTotalAmount+=billingRecord.Total_Amount__c;
					
					result.hotList.filter(k => {
						if (k.Opportunity__c == object.opportunityId && k.Id == billingRecord.HEAD_OF_TERMS__c) {
							let rec = '';//moving inside loop
							k.Rental_Units__r.filter(l => {
								rec = '';
								rec += '' + l.Floor__r.Asset_Code__c + ',';
							})
							object.asset = rec.slice(0, -1);
							return;
						}
					})
					record.push(object);
				})
				this.data = record;
				this.filteredData = this.data;
				this.grandAmountPayable=(isNaN(this.grandAmountPayable) || this.grandAmountPayable==undefined)?0:this.grandAmountPayable;
				this.grandGST=(isNaN(this.grandGST) || this.grandGST==undefined)?0:this.grandGST;
				this.grandTotalAmount=(isNaN(this.grandTotalAmount) || this.grandTotalAmount==undefined)?0:this.grandTotalAmount;
				this.recordCount=(typeof this.filteredData != "undefined" && this.filteredData != null && this.filteredData.length != null)?this.filteredData.length:0;
				this.showSpinner = false;
			})
			.catch(error => {
				console.log(error);
				this.showSpinner = false;
			})
	}
	
	//object helper class to prepare data from Billing Object
	objectHelper(v, object, billingRecord) {
		object.TypeOfBilling = billingRecord.Type_of_billing__c;
		object.opportunityId = billingRecord.Opportunity__c;
		object.ChargeId = billingRecord.Charge__c;
		object.startDate = billingRecord.Billing_Start_Date__c;
		object.endDate = billingRecord.Billing_End_Date__c;
		object.tax = billingRecord.Tax__c;
		object.AmountPayable = billingRecord.Amount_Payable__c;
		object.TotalAmount = billingRecord.Total_Amount__c;
		object.ChargeType = billingRecord.Charge_Type__c;
		object.Id = v.Id;
		object.billingLink = '/' + billingRecord.Id;

		if (billingRecord.Opportunity__r && billingRecord.Opportunity__r.Account) {
			object.Account = billingRecord.Opportunity__r.Account.Name;
			object.accountLink = '/' + billingRecord.Opportunity__r.Account.Id;
		} else {
			object.Account = '';
			object.accountLink = '';
		}
		return object;
	}

	//Apply filter on Billing Type
	handleTypeFilter(event) {
		this.type_value = event.detail.value;
		this.filterHelper();
	}

	//Apply filter on Charge Type
	handleChargeEvent(event) {
		this.chargeId = event.detail.value[0];
		this.filterHelper();
	}
	//Apply filter on Acount Type
	handleAccountSearch(event) {
		//earlier
		const isEnterKey = event.keyCode === 13;
		if (isEnterKey) {
			this.accountName = (event.target.value == null || event.target.value == '' || typeof event.target.value == undefined) ? '' : event.target.value;
		}
		this.filterHelper();
	}
	//Generic Filter helper
	filterHelper() {
		if (this.type_value == 'All') {
			this.filteredData = this.data;
		} else {
			this.filteredData = [];
			this.data.filter(v => {
				if (v.TypeOfBilling == this.type_value) {
					this.filteredData.push(v);
				}
			})
		}

		if (this.chargeId) {
			this.filteredData = this.filteredData.filter(v => this.chargeId == v.ChargeId);
		}

		if (this.accountName) {
			this.filteredData = this.filteredData.filter(v => v.Account.toLowerCase().includes(this.accountName.toLowerCase()));
		}
		// To show the grand totals and record count per filter
		this.grandAmountPayable=0;
		this.grandGST=0;
		this.grandTotalAmount=0;
		this.filteredData.filter(v =>{
			console.log('Inside v.Amount_Payable__c : '+v.AmountPayable+ 'v.Tax: '+v.Tax+ 'v.TotalAmount: '+v.TotalAmount);
			this.grandAmountPayable+=v.AmountPayable;
			this.grandGST+=v.tax;
			this.grandTotalAmount+=v.TotalAmount;
		})
		this.grandAmountPayable=(isNaN(this.grandAmountPayable) || this.grandAmountPayable==undefined)?0:this.grandAmountPayable;
		this.grandGST=(isNaN(this.grandGST) || this.grandGST==undefined)?0:this.grandGST;
		this.grandTotalAmount=(isNaN(this.grandTotalAmount) || this.grandTotalAmount==undefined)?0:this.grandTotalAmount;
		this.recordCount=(typeof this.filteredData != "undefined" && this.filteredData != null && this.filteredData.length != null)?this.filteredData.length:0; 
	}

	//handle row selection in data table
	getSelectedRecords(event) {
		const selectedRows = event.detail.selectedRows;
		this.selectedWorkIds = [];
		if (selectedRows) {
			selectedRows.filter(vr => {
				this.selectedWorkIds.push(vr.Id);
			});
		}
		console.log(this.selectedWorkIds);
		console.log(selectedRows);
	}

	//Submit records for bulk approval
	submitforBulkApproval(event) {
		this.showSpinner = true;
		console.log(this.selectedWorkIds);
		this.helper_bulkApproval(event);
	}

	helper_bulkApproval(event) {
		
		if (this.selectedWorkIds && this.selectedWorkIds.length > 0) {
			var buttonName = event.target.dataset.name;
			let recordArray = [];
			if (this.selectedWorkIds && this.selectedWorkIds.length > 20) {
				recordArray = this.selectedWorkIds.slice(0, 20);
				this.selectedWorkIds = this.selectedWorkIds.slice(20);
			} else {
				recordArray = this.selectedWorkIds;
				this.selectedWorkIds = null;//added by PSM to make the list empty when less than 20 items to stop call to the method
			}
			submitForApproval({ workItemIds: recordArray, buttonName: buttonName })
				.then(result => {
					console.log(result);
					this.helper_bulkApproval();
				})
				.catch(error => {
					console.log(error);
					let errorMessage='';
					if (error && error.body && error.body.message) {
							errorMessage = error.body.message;
					}else{
						errorMessage = error;
					}
					this.showSpinner = false;
					const evt = new ShowToastEvent({
						title: 'Error',
						message: errorMessage,
						variant: 'error',
					});
					this.dispatchEvent(evt);
				})

		} else {
			this.showSpinner = false;
			window.location.reload(true);
			//this.getApprovalProcess();
		}
		
	}

}