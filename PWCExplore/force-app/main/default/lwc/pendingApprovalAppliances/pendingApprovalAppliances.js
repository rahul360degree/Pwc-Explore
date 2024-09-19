/**
* @Author            : Ashwin Thale
* @class name  : pendingApprovalsAppliances.js
* @description  : 
* @created date  : 14-11-2023
* @last modified on  : 14-11-2023
* @last modified by  : Ashwin Thale
* Modifications Log	 :
* Ver   Date         Author          Modification
* 1.0   14-11-2023   Ashwin Thale   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import getPendingApprovals from '@salesforce/apex/PendingApprovalsAppliancesClass.doInit'
import submitForApproval from '@salesforce/apex/PendingApprovalsAppliancesClass.submitForApproval';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PendingApprovalMHE extends NavigationMixin(LightningElement) {
    @api sObjectName = 'Order';
    @api recordsToDisplay = [];
    @api spinner = false;
    @track isChecked = false;
    @track procInstWorkItem = [];
    @track procOrderItem = [];
    @track selectedProcessIds = [];
    @track selectedCommentsIds = [];
    @track selectedCommentsData = [];
    @track selectedDateTimeIds = [];
    @track selectedDateTimeData = [];
    PlannedDeliveryDate;
    selectedTime;
    selectedDate;

    handleChange(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecordId = recordId;
        for (let i = 0; i < this.procInstWorkItem.length; i++) {
            if (this.selectedRecordId == this.procInstWorkItem[i].ProcessInstance.TargetObjectId) {
                if (event.target.checked == true) {
                    if (!this.selectedProcessIds.includes(this.procInstWorkItem[i].Id)) {
                        this.selectedProcessIds.push(this.procInstWorkItem[i].Id);
                    }
                }
                else if (event.target.checked == false) {
                    if (this.selectedProcessIds.includes(this.procInstWorkItem[i].Id)) {
                        const indexToRemove = this.selectedProcessIds.indexOf(this.procInstWorkItem[i].Id);
                        this.selectedProcessIds.splice(indexToRemove, 1);
                    }
                }
            }
        }
    }

    handleDateTimeChange(event) {

        const recordValue = event.target.value;
        this.dateTimeValue = recordValue;
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecordId = recordId;
        for (let i = 0; i < this.procInstWorkItem.length; i++) {
            if (this.selectedRecordId == this.procInstWorkItem[i].ProcessInstance.TargetObjectId) {
                var idDateTime = '';
                idDateTime = this.procInstWorkItem[i].Id + '-' + this.procInstWorkItem[i].ProcessInstance.TargetObjectId + '-' + this.dateTimeValue;
                if (this.selectedDateTimeIds.includes(this.procInstWorkItem[i].Id)) {
                    const indexToRemove = this.selectedDateTimeIds.indexOf(this.procInstWorkItem[i].Id);
                    this.selectedDateTimeData.splice(indexToRemove, 1);
                    this.selectedDateTimeIds.splice(indexToRemove, 1);
                    this.selectedDateTimeData.push(idDateTime);
                    this.selectedDateTimeIds.push(this.procInstWorkItem[i].Id);
                }
                else if (!this.selectedDateTimeIds.includes(this.procInstWorkItem[i].Id)) {
                    this.selectedDateTimeData.push(idDateTime);
                    this.selectedDateTimeIds.push(this.procInstWorkItem[i].Id);
                }
            }
        }
    }

    handleSelectAll(event) {
        const checked = event.target.checked;
        if (checked == true) {
            this.isChecked = true;
            for (let i = 0; i < this.procInstWorkItem.length; i++) {
                for (let j = 0; j < this.procOrderItem.length; j++) {
                    if (this.procInstWorkItem[i].ProcessInstance.TargetObjectId == this.procOrderItem[j].Id) {
                        if (!this.selectedProcessIds.includes(this.procInstWorkItem[i].Id)) {
                            this.selectedProcessIds.push(this.procInstWorkItem[i].Id);
                        }
                    }
                }
            }
        }
        else if (checked == false) {
            this.isChecked = false;
            for (let i = 0; i < this.procInstWorkItem.length; i++) {
                for (let j = 0; j < this.procOrderItem.length; j++) {
                    if (this.procInstWorkItem[i].ProcessInstance.TargetObjectId == this.procOrderItem[j].Id) {
                        if (this.selectedProcessIds.includes(this.procInstWorkItem[i].Id)) {
                            const indexToRemove = this.selectedProcessIds.indexOf(this.procInstWorkItem[i].Id);
                            this.selectedProcessIds.splice(indexToRemove, 1);
                        }
                    }
                }
            }
        }
    }

    handleCommentChange(event) {

        const recordValue = event.target.value;
        this.textareaValue = recordValue;

        const recordId = event.currentTarget.dataset.id;
        this.selectedRecordId = recordId;
        for (let i = 0; i < this.procInstWorkItem.length; i++) {
            if (this.selectedRecordId == this.procInstWorkItem[i].ProcessInstance.TargetObjectId) {
                var idComment = '';
                idComment = this.procInstWorkItem[i].Id + '-' + this.textareaValue;
                if (this.selectedCommentsIds.includes(this.procInstWorkItem[i].Id)) {
                    const indexToRemove = this.selectedCommentsIds.indexOf(this.procInstWorkItem[i].Id);
                    this.selectedCommentsData.splice(indexToRemove, 1);
                    this.selectedCommentsIds.splice(indexToRemove, 1);
                    this.selectedCommentsData.push(idComment);
                    this.selectedCommentsIds.push(this.procInstWorkItem[i].Id);
                }
                else if (!this.selectedCommentsIds.includes(this.procInstWorkItem[i].Id)) {
                    this.selectedCommentsData.push(idComment);
                    this.selectedCommentsIds.push(this.procInstWorkItem[i].Id);
                }
            }
        }
    }

    //Submit records for bulk approval
    submitforBulkApproval(event) {
        this.showSpinner = true;
        this.helper_bulkApproval(event);
    }

    helper_bulkApproval(event) {
        var buttonName = event.target.dataset.name;
        let recordArray = [];
        let checkId;
        let checkComment;
        var checkValue = false;
        let dateArray = [];
        let dateId;
        let dateComment;
        var dateValue = false;

        if (this.selectedProcessIds && this.selectedProcessIds.length > 0) {
            for (let i = 0; i < this.selectedProcessIds.length; i++) {
                checkId = this.selectedProcessIds[i];
                checkValue = false;
                for (let j = 0; j < this.selectedCommentsData.length; j++) {
                    if (this.selectedCommentsData[j] != undefined) {
                        checkComment = this.selectedCommentsData[j];
                        if (checkComment.includes(checkId)) {
                            recordArray.push(checkComment);
                            checkValue = true;
                            break;
                        }
                    }
                }
                if (checkValue == false) {
                    checkComment = this.selectedProcessIds[i] + '-';
                    recordArray.push(checkComment);
                }
            }
            for (let i = 0; i < this.selectedProcessIds.length; i++) {
                dateId = this.selectedProcessIds[i];
                dateValue = false;
                for (let j = 0; j < this.selectedDateTimeData.length; j++) {
                    if (this.selectedDateTimeData[j] != undefined) {
                        dateComment = this.selectedDateTimeData[j];
                        if (dateComment.includes(dateId)) {
                            dateArray.push(dateComment);
                            dateValue = true;
                            break;
                        }
                    }
                }
                if (dateValue == false) {
                    dateComment = this.selectedProcessIds[i] + '-' + '-';
                    dateArray.push(dateComment);
                }
            }
            /*this.selectedProcessIds = null;
            this.selectedDateTimeData = null;
            this.selectedCommentsData = null;
            this.selectedDateTimeIds = null;
            this.selectedCommentsIds = null;*/

            submitForApproval({ RecordIds: recordArray, OrderIds: dateArray, buttonName: buttonName })
                .then(result => {
                    //this.helper_bulkApproval();
                    this.showSpinner = false;
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Orders Successfully ' + buttonName + ' ',
                        variant: 'Success',
                    });
                    this.dispatchEvent(evt);
                    //window.location.reload(true);
                    setTimeout(() => {
                        window.location.reload(true);
                    }, 3000);
                })
                .catch(error => {
                    console.log(error);
                    let errorMessage = '';
                    if (error && error.body && error.body.message) {
                        errorMessage = error.body.message;
                    } else {
                        errorMessage = error;
                    }
                    this.showSpinner = false;
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    //window.location.reload(true);
                    setTimeout(() => {
                        window.location.reload(true);
                    }, 3000);
                })

        } else {
            this.showSpinner = false;
            setTimeout(() => {
                window.location.reload(true);
            }, 3000);
            //window.location.reload(true);
        }

    }

    connectedCallback() {
        this.fetchProcessWorkItems();
    }

    fetchProcessWorkItems() {
        getPendingApprovals({ sObjectName: this.sObjectName })
            .then(result => {
                if (result) {
                    this.dataCreationHelper(result);
                } else {
                    this.spinner = true;
                }
            })
            .catch(error => {
                this.spinner = true;
                console.log(error);
            })
    }

    dataCreationHelper(result) {
        let parOrderMap = this.parOrderMap(result);
        //let parProcessInstMap = this.parProcessInstMap(result);
        let parProcessInstStepMap = this.parProcessInstStepMap(result);
        let parProcessInstWorkItemMap = this.parProcessInstWorkItemMap(result);
        this.recordsToDisplay = this.recordsToDisplayHelper(result, parOrderMap, parProcessInstStepMap);
    }

    parProcessInstWorkItemMap(result) {
        let ProcessInstWorkItemMap = new Map();
        if (result && result.procInstWorkItemList) {
            result.procInstWorkItemList.filter(workitem => {
                //ProcessInstWorkItemMap.set(workitem.ProcessInstance.TargetObjectId, workitem);
                this.procInstWorkItem.push(workitem);
            });
        }
        return ProcessInstWorkItemMap;
    }

    parOrderMap(result) {
        let OrderMap = new Map();
        if (result && result.ordList) {
            result.ordList.filter(order => {
                OrderMap.set(order.Id, order);
                this.procOrderItem.push(order);
            });
        }
        return OrderMap;
    }

    /*parProcessInstMap(result) {
        let ProcessInstMap = new Map();
        if (result && result.processInstanceList) {
                result.processInstanceList.filter(procinst => {
                        ProcessInstMap.set(procinst.Id, procinst);
                });
        }
        return ProcessInstMap;
    }*/

    parProcessInstStepMap(result) {
        let ProcessInstStepMap = new Map();
        if (result && result.procInstStepsList) {
            result.procInstStepsList.filter(stepMap => {
                ProcessInstStepMap.set(stepMap.Id, stepMap);
            });
        }
        return ProcessInstStepMap;
    }

    recordsToDisplayHelper(result, parOrderMap, parProcessInstStepMap) {
        let dataToDisplay = [];
        dataToDisplay = [];
        result.ordList.filter(v => {
            let order = parOrderMap.get(v.Id)
            if (order != undefined) {
                let objOrd = {};
                objOrd.Id = v.Id;
                objOrd.OrderNo = order.OrderNumber;
                if (order.Planned_Delivery_Date__c != undefined) {
                    var dateTimeString = order.Planned_Delivery_Date__c;
                    objOrd.PlannedDeliveryDate = order.Planned_Delivery_Date__c;
                    var [datePart, timePart] = dateTimeString.split(/[T,Z]/);
                    objOrd.selectedTime = timePart;
                    objOrd.selectedDate = datePart;
                }
                if (order.Sold_to_Business_Partner__c != undefined) {
                    objOrd.SoldToBussPatName = order.Sold_to_Business_Partner__r.Name;
                    objOrd.SoldToBussPatId = order.Sold_to_Business_Partner__c;
                }
                if (order.Logistics_Company_Branch__c != undefined) {
                    objOrd.LogisticCompanyBranch = order.Logistics_Company_Branch__c;
                }
                if (order.Additional_Disc_Percent__c != undefined) {
                    objOrd.DiscPerc = order.Total_Percent_Additional_Disc_Appliances__c;
                }

                objOrd.OrderId = order.Id;
                objOrd.ordItmRec = [];
                objOrd.prcRecord = [];

                if (order.OrderItems != undefined) {
                    objOrd.showCell = true;
                    order.OrderItems.filter(ordItm => {
                        let objOrdItm = {};
                        objOrdItm.ProductName = ordItm.Product2.Name;
                        objOrdItm.ItemCode = ordItm.Item_Code__c;
                        objOrdItm.UnitPrice = ordItm.UnitPrice;
                        objOrdItm.Product2Id = ordItm.Product2Id;
                        objOrdItm.PerUnitPrice = ordItm.Per_Unit_Price__c;
                        objOrdItm.DiscAmtUnit = ordItm.Discount_Amount_Per_Unit_For_Appliances__c;
                        var prdNpp = (ordItm.UnitPrice - ordItm.Applied_Discount_Matrix_Level_2_Amount__c) + ((ordItm.UnitPrice - ordItm.Applied_Discount_Matrix_Level_2_Amount__c) * (ordItm.Product2.Tax_Rate__c / 100));
                        objOrdItm.prdNpp = prdNpp.toFixed(2);
                        objOrdItm.OrderLineItemId = ordItm.Id;
                        objOrd.ordItmRec.push(objOrdItm);
                    })
                }
                else {
                    objOrd.showCell = false;
                }

                result.procInstStepsList.filter(v => {
                    let procinst = parProcessInstStepMap.get(v.Id)
                    if (procinst != undefined) {
                        let objProc = {};
                        if (procinst.ProcessInstanceId != undefined) {
                            if (procinst.ProcessInstance.TargetObjectId == order.Id) {
                                objProc.Id = v.Id;
                                if (procinst.ProcessInstance.SubmittedById != undefined) {
                                    objProc.SubmittedById = procinst.ProcessInstance.SubmittedById;
                                    objProc.SubmittedBy = procinst.ProcessInstance.SubmittedBy.Name;
                                }
                                if (procinst.ActorId != undefined) {
                                    objProc.ActionById = procinst.ActorId;
                                    objProc.ActionBy = procinst.Actor.Name;
                                    if (order.Level_1_Approvers__c != undefined) {
                                        if (order.Level_1_Approvers__c == procinst.ActorId) {
                                            objProc.ApproverLevel = 'Level 1 Approver';
                                        }
                                    }
                                    if (order.Level_2_Approvers__c != undefined) {
                                        if (order.Level_2_Approvers__c == procinst.ActorId) {
                                            objProc.ApproverLevel = 'Level 2 Approver';
                                        }
                                    }
                                    if (order.Level_3_Approvers__c != undefined) {
                                        if (order.Level_3_Approvers__c == procinst.ActorId) {
                                            objProc.ApproverLevel = 'Level 3 Approver';
                                        }
                                    }
                                }
                                if (procinst.StepStatus == 'Started') {
                                    objProc.ApproverLevel = 'Submitter';
                                }
                                if (objProc.ApproverLevel == undefined) {
                                    objProc.ApproverLevel = 'Assigned To';
                                }
                                if (procinst.CreatedDate != undefined) {
                                    objProc.CompletedDate = procinst.CreatedDate;
                                }
                                if (procinst.Comments != undefined) {
                                    objProc.Comments = procinst.Comments;
                                }
                                objProc.Status = procinst.StepStatus;
                                objProc.processInstId = procinst.Id;

                                objOrd.prcRecord.push(objProc);
                            }
                        }
                    }
                });
                dataToDisplay.push(objOrd);
            }
        });
        this.spinner = true;
        return dataToDisplay;
    }

    handleNavigate(event) {
        this.spinner = false;
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