import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getProductsData from "@salesforce/apex/SRProductManager.getSRProductList";
import createOppAndOppProductRecords from "@salesforce/apex/SRProductManager.createOpportunity_And_OppProduct_Record";
import validateUser from "@salesforce/apex/SRProductManager.checkUserAccess";
import saveRecords from "@salesforce/apex/SRProductManager.saveRecords";
import markRecordAsIgnored from "@salesforce/apex/SRProductManager.markRecordAsIgnored";


export default class ShowSelectedSRProducts extends NavigationMixin(LightningElement) {

    @track allData = [];
    searchedProducts = [];
    pageSize = 20;
    totalPages = 1;
    replaceExistingData = false;
    @track data = [];
    @track pageNumber = 1;
    @track disablePrevious = true;
    @track isLastPage = true;
    @track isLoadingProducts;
    @track isMobile = false;
    @track showCreateOrderModal = false;
	@track showDealerConsumptionModal = false;
   
    @api recordId;

    // Function called on load time.
    connectedCallback() {
        this.isLoadingProducts = true;
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        this.init();
    }

    init() {
        validateUser()
        .then(result => {
            console.log(`result`, result);
            if(result == 'VALID_USER') {
                this.getRecords();
            } else {
                this.showToast('Error', 'You do not have access to perform this operation.', 'error');
                this.close();
            }
        })
        .catch(error => {
            console.log(`error`, error);
            this.showToast('Error', error.body.message, 'error');
            this.close();
        });
       
    }

    // Function to get SR Product records
    getRecords() {
        getProductsData({recordId: this.recordId})
        .then(result => {
            this.isLoadingProducts = false;
            console.log(`result`, result);
            this.allData = JSON.parse(JSON.stringify(result));
            //this.handlePaginationOnLoad();
            this.updateTotalPageCount(this.allData.length);
        })
        .catch(error => {
            this.isLoadingProducts = false;
            console.log(`error`, error);
            this.showToast('Error', error.body.message, 'error');
        });
    }

    handlePaginationOnLoad() {
        let counter = 0;
        if(this.allData.length <= this.pageSize) {
            this.data = this.allData;
        } else {
            while (counter < this.pageSize) {
                this.data.push(this.allData[counter]);
                counter += 1;
            }
        }
        this.updateTotalPageCount(this.allData.length);
    }

    // Handle product search events.
    handleSearch(event) {
        let searchKey = event.target.value;
        let matchingProducts = [];
        this.data = [];

        if(searchKey.length >= 2) {
            this.pageNumber = 1;
            this.allData.forEach(data => {
                let productName = data.productName.toLowerCase();
                let itemCode = data.itemCode &&  data.itemCode.length > 0 ? data.itemCode.toLowerCase() : '';
                if( productName.includes(searchKey.toLowerCase()) ||
                    itemCode.includes(searchKey.toLowerCase())
                ) {
                    matchingProducts.push(data);
                }
            });
            if(matchingProducts && matchingProducts.length > 0) {
                this.searchedProducts = matchingProducts;
                this.updateTotalPageCount(this.searchedProducts.length);
            }
        } else {
            this.pageNumber = 1;
            this.searchedProducts = [];
            this.updateTotalPageCount(this.allData.length);
        }
    }

    // When the toggle button is checked
    rowSelected(event) {
        let productId = event.currentTarget.name;
        let updatedData = this.allData.map( (e) => {
            if(productId == e.product2Id) {
                e.isInclusion = !e.isInclusion;
            }
            return {...e};
        });
        this.allData = updatedData;
        this.updateCurrentDataBeingShown();
    }
    // When the toggle button is checked for DC & Rep
    rowSelected2(event) {
        let productId = event.currentTarget.name;
        let updatedData = this.allData.map( (e) => {
            if(productId == e.product2Id) {
                e.isDealerConsumption = !e.isDealerConsumption; 
            }
            return {...e};
        });
        this.allData = updatedData;
        this.updateCurrentDataBeingShown();
    }
    // When toggle button is checked in mobile screen
    rowSelectedMobile(event) {
        let productId = event.currentTarget.name;
        let updatedData = this.allData.map( (e) => {
            if(productId == e.product2Id) {
                e.isInclusion = !e.isInclusion;
            }
            return {...e};
        });
        this.allData = updatedData;

        let dataRows = this.data.map( (e) => {
            if(productId == e.product2Id) {
                e.isInclusion = !e.isInclusion;
            }
            return {...e};
        });
        this.data = dataRows;
    }
     // When toggle button is checked in mobile screen for Dealer Consumption & Replenishment
     rowSelectedMobile2(event) {
        let productId = event.currentTarget.name;
        let updatedData = this.allData.map( (e) => {
            if(productId == e.product2Id) {
                e.isDealerConsumption = !e.isDealerConsumption;
            }
            return {...e};
        });
        this.allData = updatedData;

        let dataRows = this.data.map( (e) => {
            if(productId == e.product2Id) {
                e.isDealerConsumption = !e.isDealerConsumption;
            }
            return {...e};
        });
        this.data = dataRows;
    }


    updateTotalPageCount(dataLength) {
        if(dataLength > 0) {
            this.totalPages = Math.ceil(dataLength / this.pageSize);
        }
        this.updatePaginationButtonState();
        this.updateCurrentDataBeingShown();
    }

    // Control whether the pagination buttons are enabled or disabled.
    updatePaginationButtonState() {
        // Update state of previous and next pagination buttons
        if(this.totalPages > this.pageNumber) {
            this.isLastPage = false;
        } else {
            this.isLastPage = true;
        }

        if(this.pageNumber > 1) {
            this.disablePrevious = false;
        } else {
            this.disablePrevious = true;
        }
    }

    // Method to control which products are being shown from the entire list of product data available.
    updateCurrentDataBeingShown() {
        let startIndex = (this.pageNumber - 1) * this.pageSize;
        let endIndex = startIndex + this.pageSize;
        if(!this.isMobile || this.replaceExistingData) {
            this.replaceExistingData = false;
            this.data = this.searchedProducts.length > 0 ? this.searchedProducts.slice(startIndex, endIndex) : this.allData.slice(startIndex, endIndex);
        } else {
            this.data = this.searchedProducts.length > 0 ? this.data.concat(this.searchedProducts.slice(startIndex, endIndex)) : this.data.concat(this.allData.slice(startIndex, endIndex));
        }
    }

    // Load previous page
    previousPage(event) {
        this.pageNumber -= 1;
        this.updatePaginationButtonState();
        this.updateCurrentDataBeingShown();
    }

    // Load next page
    nextPage(event) {
        this.pageNumber += 1;
        this.updatePaginationButtonState();
        this.updateCurrentDataBeingShown();
    }

    // Save records
    handleSave(event) {
        console.log('@@AllData'+this.allData);
        saveRecords({pWrapperProdList: this.allData, recordId: this.recordId})
        .then(result => {
            console.log('save result: ' + result);
            this.showToast('Success', 'Records saved successfully', 'success');
						this.getRecords();
        })
        .catch(error => {
            console.log('save error', error);
            this.showToast('Error', error.body.message, 'error');
        });
    }

    // Delete record
    deleteRecord(event) {
        this.isLoadingProducts = true;
        let productId = event.currentTarget.dataset.id;
        console.log('productId for record to be deleted: ', productId);
        markRecordAsIgnored({recordId: this.recordId, productId: productId})
        .then(result => {
            this.showToast('Success', 'Successfully updated the records', 'success');
            this.replaceExistingData = true;
            this.getRecords();
        })
        .catch(error => {
            this.isLoadingProducts = false;
            this.showToast('Error', error.body.message, 'error');
        });
    }

    // Create opportunity record from exclusion products.
    createOpportunityRecord(event) {
        this.isLoadingProducts = true;
        createOppAndOppProductRecords({pWrapperProdList: this.allData, recordId: this.recordId})
        .then(result => {
            this.isLoadingProducts = false;
            console.log(`createOppAndOppProductRecords result `, result);

            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    actionName: 'view',
                },
            }).then(url => {
                let title = 'Success';
                let message = 'Opportunity Record {0} created successfully! See it {1}';
                let messageData = ['Salesforce', {url, label: 'here'}];
                let variant = 'success';
                this.showToastWithRecordLink(title, message, messageData, variant);
                this.navigateToRecordDetail(this.recordId, 'Service_Form__c');
            });
        })
        .catch(error => {
            this.isLoadingProducts = false;
            console.log(`createOppAndOppProductRecords error`, error);
            this.showToast('Error', error.body.message, 'error');
            this.close();
        });
    }

    // @Todo: Logic to create order records.
    createOrderRecord(event){
        //Programmatically call the SaveRecords function
        saveRecords({pWrapperProdList: this.allData, recordId: this.recordId})
        .then(result => {
            console.log('save result: ' + result);
            this.showToast('Success', 'Records saved successfully', 'success');
            this.getRecords();
            let cntr = 0;
            this.allData.forEach(data => {
                if(data.isInclusion){
                cntr++;
                }
						})
						if (cntr ==0){
								this.showToast('Error', 'There are no Inclusion Products. Please select at least one to proceed.', 'error');
						}else{
							this.showCreateOrderModal = true;
						}
				})
        .catch(error => {
           this.showToast('Error', error.body.message, 'error');
        });
        //End of Programmatically call the SaveRecords function
    }

    //@Todo: Logic to create Dealer consumption order records 
    createDealerConsumptionOrderRecord(event){
            this.showDealerConsumptionModal = true; 
            console.log(`@@@@@@DealerConsumptionrecords`);

    }

    // Function to show toast message.
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    // Function to show toast message with record link.
    showToastWithRecordLink(title, message, messageData, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant
            }),
        );
    }

    navigateToPrevMobileScreen(event) {
        this.close();
    }

    navigateToRecordDetail(recordId, objectAPIName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectAPIName,
                actionName: 'view'
            }
        });
    }

    // Pass the close event to the parent Aura component.
    close() {
        this.dispatchEvent(new CustomEvent("close"));
    }

    handleCloseOrderModal() {
        this.showCreateOrderModal = false;
    }
		
		handlerCloseDealerConsumptionModal(){
				this.showDealerConsumptionModal = false;
		}
}