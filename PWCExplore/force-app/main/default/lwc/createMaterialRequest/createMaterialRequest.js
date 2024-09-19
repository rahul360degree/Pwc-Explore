import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/MaterialRequestManager.init';
import insertRecord from '@salesforce/apex/MaterialRequestManager.insertRecord';
import insertOrderProducts from '@salesforce/apex/MaterialRequestManager.insertOrderProducts';
import updateServiceForm from '@salesforce/apex/MaterialRequestManager.updateServiceForm';
import { NavigationMixin } from 'lightning/navigation';
import noActiveContractMessage from '@salesforce/label/c.No_Active_Contract_Against_Service_Request_Message';
import noActiveWarrantyMessage from '@salesforce/label/c.No_Active_Warranty_Against_Asset_Message';
import orderCreatedSuccessMessage from '@salesforce/label/c.Order_Created_From_Serivce_Form_Success_Message';
import sfUpdateSuccessMessage from '@salesforce/label/c.Service_Form_Updated_For_MR_Update_Success_Message';
import orderProductCreateSuccessMessage from '@salesforce/label/c.Order_Products_Created_From_ServiceForm_Success_Message';

export default class CreateMaterialRequest extends  NavigationMixin (LightningElement) {
    @api recordId;
    @track isLoaded = false;
    @track recordTypeId;
    @track isInstallationGroupDisabled = true;
    @track isGenericWarrantyDisabled = true;
    @track isBranchDisabled = false;
    @track serviceForm;
    @track supplyToType;
    @track contractLineItem;
    @track salesOrderSeries;
    @track internalSalesServiceRep;
    @track mrType;
    @track salesOrderSeriesOptions = [];
    @track rentalOptions = [];
    @track contractOptions = [];
    @track warrantyOptions = [];
    @track goodwillOptions = [];
    @track isAccountDisabled = true;
    @track isWarrantyTemplateMandatory = false;
    @track branch;
    @track area;
    @track isOrderCreated = true;
    @track salesServiceOfficeId;
    @track orderType;
    @track orderTypeOptions = [
        { label: 'S10 / Normal (With Freight)', value: 'S10'},
        { label: 'S16 / War Issue & Receipt with Freight', value:	'S16'},
        { label: 'S01 / Normal' , value: 'S01'},
        { label: 'S02 / Repair Warranty', value:	'S02'},
        { label: 'S03 / Emergency', value: 'S03'},
        { label: 'S04 / Warranty', value:	'S04'},
        { label: 'S05 / Supplier Claim', value: 'S05'},
        { label: 'S06 / Customer Claim', value: 'S06'},
        { label: 'S07 / Project', value: 'S07'},
        { label: 'S08 / TRP', value: 'S08'},
        { label: 'S09 / Transport Service', value: 'S09'},
        { label: 'SOC / Service FOC WITH FREIGHT', value: 'SOC'}
    ];

    connectedCallback() {
        this.isLoaded = false;
        init({serviceFormId : this.recordId})
        .then((result) => {
            this.recordTypeId = result.mheRecordTypeId;
            if(this.contractLineItem && this.contractLineItem.ServiceContract.Sales_Rep_Code__c){
                this.internalSalesServiceRep = this.contractLineItem.ServiceContract.Sales_Rep_Code__c;
            }
            this.mrType = result.mrType;
            this.serviceForm = result.serviceForm;
            this.contractLineItem = result.cli;
            for(let i=0;i< result.salesOrderSeriesOptions.length;i++) {
                this.salesOrderSeriesOptions.push({label : result.salesOrderSeriesOptions[i],value : result.salesOrderSeriesOptions[i]});
            }
            for(let i=0;i< result.rentalOptions.length;i++) {
                this.rentalOptions.push({label : result.rentalOptions[i],value : result.rentalOptions[i]});
            }
            for(let i=0;i< result.contractOptions.length;i++) {
                this.contractOptions.push({label : result.contractOptions[i],value : result.contractOptions[i]});
            }
            for(let i=0;i< result.warrantyOptions.length;i++) {
                this.warrantyOptions.push({label : result.warrantyOptions[i],value : result.warrantyOptions[i]});
            }
            for(let i=0;i < result.goodwillOptions.length;i++){
                this.goodwillOptions.push({label : result.goodwillOptions[i],value : result.goodwillOptions[i]});
            }
            this.updateBranch('');
            if(this.serviceForm.Case__r.Asset.Area_Code__c){
                this.area = this.serviceForm.Case__r.Asset.Area_Code__c;
            }
            if(this.mrType === 'Sales'){
                this.orderType = 'SOC';
                this.salesOrderSeries = 'KOS';
                this.salesServiceOfficeId = result.salesServiceOfficeId;
            }
            this.isLoaded = true;
        })
        .catch((error) => {
            this.isLoaded = true;
            this.showToast('Error',error.body.message,'Error');
        })
    }

    updateBranch(newValue){
        if(this.mrType === 'Sales'){
            this.branch = '5000';
        }else if(newValue && newValue === 'Warranty'){
            if(this.serviceForm.Case__c && this.serviceForm.Case__r.AssetId && this.serviceForm.Case__r.Asset.Execution_Branch__c){
                this.branch = this.serviceForm.Case__r.Asset.Execution_Branch__c;
            }else{
                this.branch = '5000';
            }
            this.isBranchDisabled = true;
        }else{
            if(this.serviceForm.Case__c && this.serviceForm.Case__r.AssetId){
                this.branch = this.serviceForm.Case__r.Asset.Execution_Branch__c;
                this.isBranchDisabled = false;
            }
        }
    }

    showToast(title,message,variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
        );
    }

    
    handleSeriesOptions(event){
        this.salesOrderSeries =  event.detail.value;
    }

    handleClassChange(event){
        let newValue = event.detail.value;
        this.classValue = newValue;
        this.validateClassField(newValue);
        this.updateOrderSeriesOption(this.classValue);
        this.updateBranch(this.classValue);
    }

    updateOrderSeriesOption(value){
        if(this.mrType === 'Sales' && value !== "Goodwill"){
            this.salesOrderSeriesOptions = this.salesOrderSeriesOptions;
            this.salesOrderSeries = 'KOS';
        }else if(this.mrType === 'Sales' && value === "Goodwill"){
            this.salesOrderSeriesOptions = this.goodwillOptions;
        } else {
            if (value === "Rentals") {
                this.salesOrderSeriesOptions = this.rentalOptions;
            }
            if (value === "Contracts") {
                this.salesOrderSeriesOptions = this.contractOptions;
            }
            if (value === "Warranty") {
                this.salesOrderSeriesOptions = this.warrantyOptions;
            }
            if(value === "Goodwill"){
                this.salesOrderSeriesOptions = this.goodwillOptions;
            }
        }
    }
    @track classValue;
    isValidClass = false;
    validateClassField(value){
        this.isValidClass = true;
        if(value === "Warranty"){
            let warrantyStartDateTime =  ''+this.serviceForm.Case__r.Asset.Product_Purchased_Warranty_Start_Date__c;
            let warrantyEndateTime =  ''+this.serviceForm.Case__r.Asset.Product_Purchased_Warranty_End_Date__c;

            let warrantyStartDate = warrantyStartDateTime.slice(0,10);
            let warrantyEndate = warrantyEndateTime.slice(0,10);
            if(this.serviceForm.Case__r.Asset.Status === 'Active'){
                this.validateClassRelatedDates(warrantyStartDate, warrantyEndate, noActiveWarrantyMessage, value);
            }else{
                this.showClassFieldError(noActiveWarrantyMessage);
            }
        }else if(value === "Contracts"){
            if(this.contractLineItem 
                && this.contractLineItem.ServiceContract 
                && this.contractLineItem.ServiceContract.StartDate
                && this.contractLineItem.ServiceContract.MHE_Division__c){
                let scStartDate = ''+ this.contractLineItem.ServiceContract.StartDate;  
                let scEndDate = ''+ this.contractLineItem.ServiceContract.EndDate; 

                if(this.contractLineItem.ServiceContract.MHE_Division__c === "Contracts"){
                    this.validateClassRelatedDates(scStartDate, scEndDate, noActiveContractMessage, value);
                }else{
                    this.showClassFieldError(noActiveContractMessage);
                }
            }else{
                this.showClassFieldError(noActiveContractMessage);
            }
        }else if(value === "Rentals"){
            if(this.contractLineItem 
                && this.contractLineItem.ServiceContract 
                && this.contractLineItem.ServiceContract.StartDate
                && this.contractLineItem.ServiceContract.MHE_Division__c){ 
                let scStartDate = ''+ this.contractLineItem.ServiceContract.StartDate;  
                let scEndDate = ''+ this.contractLineItem.ServiceContract.EndDate; 

                if(this.contractLineItem.ServiceContract.MHE_Division__c === "Godrej RenTRUST"){
                    this.validateClassRelatedDates(scStartDate, scEndDate, noActiveContractMessage, value);
                }else{
                    this.showClassFieldError(noActiveContractMessage);
                }
            }else{
                this.showClassFieldError(noActiveContractMessage);
            }
        }
    }

    validateClassRelatedDates(startDate, endDate, message, classValue){
        let today = new Date();
        var current = new Date(today.getFullYear(),today.getMonth(),today.getDate());

        var d1 = startDate.split("-");
        var d2 = endDate.split("-");

        var start = new Date(d1[0], parseInt(d1[1])-1, d1[2]);  // -1 because months are from 0 to 11
        var end   = new Date(d2[0], parseInt(d2[1])-1, d2[2]);

        if((current >= start && current <= end)){
            this.isValidClass = true;
            this.handleFOCSupplyEdit(classValue);
        }else{
            this.showClassFieldError(message);
        }
    }

    showClassFieldError(message){
        this.isValidClass = false;
        
        //this.classValue = null;
        this.handleFOCSupplyEdit('');
        this.showToast('Error',message,'Error');
        const inputFields = this.template.querySelectorAll(
            '.orderClass'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                if(field.name === "class__c") {
                    field.value = null;
                    this.classValue = null; 
                }
            });
        }
        
    }

    handleFOCSupplyEdit(classValue){
        if(classValue === "Warranty") {
            this.isGenericWarrantyDisabled = false;
            this.isWarrantyTemplateMandatory = true;
        } else {
            this.isGenericWarrantyDisabled = true;
            this.isWarrantyTemplateMandatory = false;
            
            const inputFields = this.template.querySelectorAll(
                '.genericWarrantyField'
            );
            if (inputFields) {
                inputFields.forEach(field => {
                    field.value = null;
                });
            }

            const focSupplyreasonField = this.template.querySelectorAll(
                '.focSupplyReason'
            );
            if (focSupplyreasonField) {
                focSupplyreasonField.forEach(field => {
                    field.value = null;
                });
            }       
        }
    }


    handleCustomerTypeChange(event) {
        let newValue = event.detail.value;
        if(newValue === "Internal") {
            this.isInstallationGroupDisabled = false;
        } else {
            this.isInstallationGroupDisabled = true;
            const inputFields = this.template.querySelectorAll(
                '.installationGroupField'
            );
            if (inputFields) {
                inputFields.forEach(field => {
                    field.reset();
                });
            }
        }
    }

    get supplyToOptions() {
        return [
            { label: 'Customer', value: 'Customer' },
            { label: 'Dealer', value: 'Dealer' }
        ];
    }
    handleSupplyToChange(event){
        this.supplyToType = event.detail.value;
        if(this.supplyToType === 'Dealer'){
            const inputFields = this.template.querySelectorAll(
                '.supplyTo'
            );
            if (inputFields) {
                inputFields.forEach(field => {
                    field.reset();
                    this.isAccountDisabled = false; 
                });
            }
        }else if(this.supplyToType === 'Customer'){
            const inputFields = this.template.querySelectorAll(
                '.supplyTo'
            );
            if (inputFields) {
                inputFields.forEach(field => {
                    field.value = this.serviceForm.Case__r.AccountId;
                    this.isAccountDisabled = true;
                });
            }

            const shipToAddressFields = this.template.querySelectorAll(
                '.shipToAddressClass'
            );
            
            if (shipToAddressFields) {
                shipToAddressFields.forEach(field => {
                    field.reset();
                });
            }
        }
    }

    handleOrderTypeChange(event){
        this.orderType =  event.detail.value;
    }
   
    @track isSubmit = true;
    validateOnSubmitForm(){
        if(!this.isValidClass){
            this.isSubmit = false;
            this.showToast('Error creating Order','Please select valid Class(Warranty/Contract/Rentals)','Error');
            const inputFields = this.template.querySelectorAll(
                '.orderClass'
            );
            if(inputFields) {
                inputFields.forEach(field => {
                    if(field.name === "class__c") {
                        field.reset(); 
                    }
                });
            }
        }else{
            this.isSubmit = true;
        }
    }
    //orderRecordId;
    onSubmitHandler(event){
        event.preventDefault();
        const orderData = event.detail.fields;
        
        if(this.supplyToType === 'Customer'){
            orderData.AccountId = this.serviceForm.Case__r.AccountId;
        }else{
            orderData.AccountId = orderData.End_Customer__c;
        }
        orderData.Type = this.orderType;
        orderData.Sales_Order_Series__c = this.salesOrderSeries;
        this.validateOnSubmitForm();
				this.validateSalesOrderSeries();//Added by pankaj on 11/08/2023 for sales order series and service/Order Type validation
        if(this.isSubmit) {
            this.isOrderCreated = false; 
            this.isDealerConsumption = false;
            insertRecord({ serviceFormId: this.recordId, orderRec: orderData, supplyTo: this.supplyToType, isDealerConsumption: this.isDealerConsumption})
                .then((result) => {
                    this.isOrderCreated = true;
                    this.showToast('Success', orderCreatedSuccessMessage, 'Success');
                    this.insertOrderProductRecord(result);
                    if(!this.serviceForm.Order__c){
                        this.updateServiceFormRecord(result);
                    }
                    this.handleCancel();
                    this.navigateToOrder(result);
                })
                .catch((error) => {
                    this.isOrderCreated = true;
                    this.showToast('Error creating Order', error.body.message, 'Error');
                })
        }
    }

    insertOrderProductRecord(orderId){
        this.isOrderCreated = false;
        this.isDealerConsumption = false;
        insertOrderProducts({ serviceFormId: this.recordId, orderId: orderId,isDealerConsumption: this.isDealerConsumption})
        .then((result) => {
            this.isOrderCreated = true; 
            this.showToast('Success', orderProductCreateSuccessMessage, 'Success');
        })
        .catch((error) => {
            this.isOrderCreated = true;
            this.showToast('Error creating Order Products', error.body.message, 'Error');
        })
    }

    updateServiceFormRecord(orderId){
        this.isOrderCreated = false;
        updateServiceForm({ serviceForm: this.serviceForm, orderId: orderId })
        .then((result) => {
            this.isOrderCreated = true; 
            this.showToast('Success', sfUpdateSuccessMessage, 'Success');
        })
        .catch((error) => {
            this.isOrderCreated = true;
            this.showToast('Error updating Service Form', error.body.message, 'Error');
        })
    }

    handleCancel(){
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    navigateToOrder(orderId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: orderId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        });
    }
		//Added by pankaj on 11/08/2023 for sales order series and service/Order Type validation
		validateSalesOrderSeries(){			
				if(this.mrType === 'Service' && !this.salesOrderSeries){
            this.isSubmit = false;
            this.showToast('Error','Sales Order Series is required field','Error');
            const inputFields = this.template.querySelectorAll(
                '.salesOrdSrsCls'
            );
            if(inputFields) {
                inputFields.forEach(field => {
                    if(field.name === "Sales_Order_Series__c") {
                        field.reset(); 
                    }
                });
            }
        }else if(this.mrType === 'Service' && !this.orderType){
						this.isSubmit = false;
            this.showToast('Error','Service/Order Type is required field','Error');
            const inputFields = this.template.querySelectorAll(
                '.serviceOrderTypeCls'
            );
            if(inputFields) {
                inputFields.forEach(field => {
                    if(field.name === "Type") {
                        field.reset(); 
                    }
                });
            }
				}else{
            this.isSubmit = true;
        }			
		}
		//End by pankaj
}