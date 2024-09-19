/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 01-17-2023
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CURRENTUSERID from '@salesforce/user/Id';
import getProductsBasedOnDefaultValues from '@salesforce/apex/InventoryCheckController.getProductsBasedOnDefaultValues';
import getStockProductsForBDE from '@salesforce/apex/InventoryCheckController.getStockProductsForBDE';
import getStockProducts from '@salesforce/apex/InventoryCheckController.getStockProducts';
import ERROR_WHILE_FETCHING_STOCK_PRODUCTS from '@salesforce/label/c.ERROR_WHILE_FETCHING_STOCK_PRODUCTS';
import GENERIC_SEARCH_PRODUCT_ERROR_MSG from '@salesforce/label/c.GENERIC_SEARCH_PRODUCT_ERROR_MSG';
import MAX_VALUE_SELECTABLE_FOR_OBJECT_PAGE from '@salesforce/label/c.MAX_VALUE_SELECTABLE_FOR_OBJECT_PAGE';
import WAREHOUSE_LOOKUP_NOT_POPULATED from '@salesforce/label/c.WAREHOUSE_LOOKUP_NOT_POPULATED';
import NO_PROPER_RECORD_SELECTED from '@salesforce/label/c.NO_PROPER_RECORD_SELECTED';

const stockColumnsToExclude = ['organizationid', 'messagetype', 'message', 'warehousetype', 'warehousedesc'];
const stockColumnsToShowInOrder = ['itemcode', 'description', 'onhandstock', 'freestock', 'company', 'warehouse'];
const showIt = 'showIt';
const hideIt = 'hideIt';

export default class CheckInventoryFromObjectLWC extends NavigationMixin(LightningElement) {
    tableFieldJSON = {
        data: [],
        columns: [],
        maxDataSelectable: parseInt(MAX_VALUE_SELECTABLE_FOR_OBJECT_PAGE),
        reRenderTable: true,
        hideCheckBoxColumn: false
    };

    isSerialized = false;
    serializedItemMap = new Map();
    reverseSerializedItemMap = new Map();
    filterValues = new Map();
    companyCodes = new Map();
    warehouseCodes = new Map();
    selectedValueIds = new Map();
    receivedStockData = new Map();
    searchTableSelectionTracker = [];

    // Response structure to be sent to the apex function for serialized items of BDE.
    serializedItemResponseStructure = {
        Itemcode: '',
        Project: '',
        OnHandStock: '',
        FreeStock: '',
        TransactionAgingDays: '',
        message: '',
        messageType: ''
    }

    @track isMobile = false;
    @api recordId;
    @api sobjectname;
    @track isLoading = false;
    @track pageTracking = {
        backButtonLabel: 'Cancel',
        showSearchTable: true,
        showStockTable: false,
        isCheckStockButtonDisabled: true
    };
    // Properties to track table related properties.
    @track searchTableJSON = Object.assign({}, this.tableFieldJSON);
    @track stockTableJSON = Object.assign({}, this.tableFieldJSON);

    searchTableData = [];
    stockTableData = [];

    // Used to catch any error's in the child component.
    errorCallback(error, stack) {
        console.log(error.message);
        console.log(stack);
    }

    // Function called when the component is first loaded.
    connectedCallback() {
        console.log('Inside connected callback');
        this.isLoading = true;
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        getProductsBasedOnDefaultValues({ recId: this.recordId, userId: CURRENTUSERID})
        .then(result => {
            let jsonResult = Object.assign({}, JSON.parse(result));
            console.log(jsonResult);
            let tempTableJSON = Object.assign({}, this.searchTableJSON);
            tempTableJSON.columns = this.parseSearchTableColumns(jsonResult);
            tempTableJSON.data = this.parseSearchTableData(jsonResult);
            tempTableJSON.reRenderTable = tempTableJSON.reRenderTable ? false : true;
            this.populateDefaultValues(jsonResult.config);
            this.searchTableJSON = Object.assign({}, tempTableJSON);
            this.isLoading = false;
        })
        .catch(error => {
            console.log(error);
            this.isLoading = false;
            this.showToast('Error', GENERIC_SEARCH_PRODUCT_ERROR_MSG, 'error')
        });
    }

    // Method to parse the data and create column structure based on the response received from Salesforce, when the page loads.
    parseSearchTableColumns(jsonResult) {
			
        let newColumns = this.searchTableJSON.columns;
        for(const [key, value] of Object.entries(jsonResult.fieldValueVSfieldLabel)) {
            let tempColumnObj = {label: '', fieldName: '', sortable : true, type: 'text',wrapText: true};
            tempColumnObj.fieldName = key;
            tempColumnObj.label = value;
            newColumns.push(tempColumnObj);
        }
        return newColumns;
    }

    // Method to parse the data based on the response received from Salesforce, when the page loads.
    parseSearchTableData(jsonResult) {
        let tempDataHolder = [];
        jsonResult.config.data.forEach(tempData => {
            let tempObj = Object.assign({}, JSON.parse(tempData));
            tempDataHolder.push(tempObj);
        });

        let data = [];
        tempDataHolder.forEach(tempData => {
            let tempObj = {...tempData};
            delete tempObj.attributes;
            data.push(tempObj);
        });
        console.log('parseSearchTableData');
        console.log(data);
        return data;
    }

    populateDefaultValues(result) {
        result.CompanyCodes.forEach(companyCode => {
            let companyCodeValues = [];
            let key = companyCode.split('--')[0];
            let value = companyCode.split('--')[1];

            if(this.companyCodes.has(key)) {
                companyCodeValues = this.companyCodes.get(key);
            }
            companyCodeValues.push(value);
            this.companyCodes.set(key, companyCodeValues);
        });

        result.WarehouseCodes.forEach(warehouseCode => {
            let warehouseCodeValues = [];
            let key = warehouseCode.split('--')[0];
            let value = warehouseCode.split('--')[1];

            if(this.warehouseCodes.has(key)) {
                warehouseCodeValues = this.warehouseCodes.get(key);
            }
            warehouseCodeValues.push(value);
            this.warehouseCodes.set(key, warehouseCodeValues);
        });
    }

    // Function to handle navigation to the previous page / record detail based on where the user was present when clicking the back button.
    handleBackButtonEvent(event) {
				
        if(this.pageTracking.showSearchTable) {
            this.navigateToRecordDetail();
        } else if(this.pageTracking.showStockTable) {
            this.navigateToSearchTable();
        }
    }

    // Function to control the page flow from "Check Stock" page to product table page.
    navigateToSearchTable() {
        let pageTrackingClone = this.pageTracking;
        pageTrackingClone.showSearchTable = true;
        pageTrackingClone.backButtonLabel = 'Cancel';
        pageTrackingClone.showStockTable = false;
        pageTrackingClone.searchTableVisibility = showIt;

        this.pageTracking = pageTrackingClone;
        this.updateSearchTablePreviousSelection();
    }

    // Function to maintain the state of the selected products in the table.
    updateSearchTablePreviousSelection() {
        if(this.searchTableSelectionTracker && this.searchTableSelectionTracker.length > 0) {
            let searchTableComponent = this.template.querySelector('.search-table');
            // Execute the next statement if a component is found.
            if(searchTableComponent) {
                searchTableComponent.updateTableSelectionRows(this.searchTableSelectionTracker);
            }
        }
    }

    // Function to handle selection of product rows.
    handleSearchTableSelectionEvent(event) {
        this.isSerialized = false;
        this.serializedItemMap = new Map();
        this.reverseSerializedItemMap = new Map();

        console.log(event.detail);
        let selectedRecords = JSON.parse(JSON.stringify(event.detail.selected_values));
        let itemCodes = new Set();
        this.searchTableSelectionTracker = event.detail.allSelected_RowTrackers;
        this.selectedValueIds = new Map();

        if(selectedRecords && selectedRecords.length > 0) {
            this.controlCheckStocksButton(false);
        } else {
            this.controlCheckStocksButton(true);
        }
        
        selectedRecords.forEach(selectedRecord => {
            if(selectedRecord.hasOwnProperty('Part_Codes__c') && selectedRecord.Part_Codes__c.length > 0) {
                this.serializedItemMap.set(selectedRecord.Item__c, selectedRecord);
                this.isSerialized = true;
                selectedRecord.Part_Codes__c.split(',').forEach(partCode => {
                    this.reverseSerializedItemMap.set(partCode.trim(), selectedRecord.Item__c);
                });
            }
            this.selectedValueIds.set(selectedRecord.Item__c.trim(), selectedRecord.Id);
            itemCodes.add(selectedRecord.Item__c);
        });
        this.filterValues.set('itemCodes', Array.from(itemCodes).join());
    }

    // Function to make callout to external service for serialized items.
    makeSerializedCallout(requestObjArray) {
        let finalRequestObj = {
            CompanyCodes: '',
            WarehouseCodes: '',
            ProjectCodes: '',
            IsSerialized: this.isSerialized,
            ItemCodes: ''
        };

        let companyCodes = [];
        let warehouseCodes = [];
        let itemCodes = [];
        let partCodes = [];

        requestObjArray.forEach(requestObjString => {
            let requestObj = JSON.parse(requestObjString);
            companyCodes = companyCodes.concat(requestObj.CompanyCodes.split(','));
            warehouseCodes = warehouseCodes.concat(requestObj.WarehouseCodes.split(','));
            itemCodes = itemCodes.concat(requestObj.ItemCodes.split(','));
        });

        // Get list of part codes based on item code values
        itemCodes.forEach(itemCode => {
            if(this.serializedItemMap.has(itemCode) && this.serializedItemMap.get(itemCode).hasOwnProperty('Part_Codes__c')) {
                partCodes = partCodes.concat(this.serializedItemMap.get(itemCode).Part_Codes__c.split(','));
            }
        });

        finalRequestObj.CompanyCodes = Array.from(new Set(companyCodes)).join();
        finalRequestObj.WarehouseCodes = Array.from(new Set(warehouseCodes)).join();
        finalRequestObj.ItemCodes = Array.from(new Set(partCodes)).join();

        this.getStockProductForSerializedItems(finalRequestObj);
    }

    // Function to handle the response after making the callout to external service for serialized items.
    getStockProductForSerializedItems(requestObj) {
        this.isLoading = true;
        console.log('finalRequestObj');
        console.log(requestObj);

        getStockProducts({productsToGet: JSON.stringify(requestObj)})
            .then(response => {
                this.controlCheckStocksButton(true);
                console.log('Stock Response');
                let result = JSON.parse(response);				
                console.log(result);
                // Show error message if response or data is not received.
                if(result.status == 'Failed' || !result.data || result.listCount < 1) {
                    this.filterValues.delete('itemCodes');
                    this.isLoading = false;
                    this.showToast('Error', result.message, 'error');
                    this.updateSearchTablePreviousSelection();
                } else {
                    this.pageTracking.showSearchTable = false;
                    this.pageTracking.searchTableVisibility = hideIt;
                    this.pageTracking.showStockTable = true;
                    this.pageTracking.backButtonLabel = 'Back';

                    let tempTableJSON = Object.assign({}, this.stockTableJSON);
                    let columns = this.parseStockColumns(result);
                    // Get the array of data returned form Infor in a proper format.
                    let dataArray = this.parseStockData(result);

                    /*
                    *   The reason I have maintained two maps is because to keep the data order in a proper format.
                    *   I want the latest stock data to appear at the top and previous stock data to be appended at the bottom.
                    */
                    // Create a map to store both current and past stock data.
                    let allDataMap = new Map();
                    dataArray.forEach(data => {
                        allDataMap.set(data.itemcode + data.warehouse, data);
                    });

                    // If there are any past stock check values then append them to the current map.
                    if(this.receivedStockData.size > 0) {
                        Array.from(this.receivedStockData.keys()).forEach(key => {
                            if(!allDataMap.has(key)) {
                                allDataMap.set(key, this.receivedStockData.get(key));
                            }
                        });
                    }
										console.log('allDataMap is>>>');
										console.log(allDataMap.values());
                    // Update the past stock value maintenance map.
                    this.receivedStockData = allDataMap;

                    this.isLoading = false;
                    // Create the table data structure to be passed to the generic table component.
                    tempTableJSON.columns = columns;
                    tempTableJSON.data = Array.from(allDataMap.values());
                    tempTableJSON.reRenderTable = !tempTableJSON.reRenderTable;
                    tempTableJSON.hideCheckBoxColumn = true;
                    this.stockTableJSON = tempTableJSON;
                }
            })
            .catch(error => {
                console.log('error');
                console.log(error);
                this.isLoading = false;
                let errorMessage = ERROR_WHILE_FETCHING_STOCK_PRODUCTS;
                if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                    errorMessage = error.body.message;
                }

                this.showToast('Error', errorMessage, 'error');
                this.controlCheckStocksButton(false);
                this.navigateToSearchTable();
            });
    }

    // Function to handle check stock button click event which would then fetch stock information from external service.
    handleCheckMultipleStocksEvent(event) {
        this.isLoading = true;
        let itemCodes = this.filterValues.get('itemCodes').split(',');
        let requestObjArray = [];

        // No products are selected if the itemCodes array is empty.
        if(!itemCodes || itemCodes.length == 0) {
            console.log(NO_PRODUCTS_SELECTED);
            this.isLoading = false;
            this.showToast('Error', NO_PRODUCTS_SELECTED, 'error');
            return;
        }

        // Create an array of request objects.
        let productsWithoutWarehouseInfo = [];
        itemCodes.forEach(itemCode => {
            let id = this.selectedValueIds.get(itemCode);
            // Only create the respective request obj if there is a proper company and warehouse code for each selected record.
            // Else ignore that particular record and show an error message.
            if(this.companyCodes && this.warehouseCodes && this.companyCodes.has(id) && this.warehouseCodes.has(id)) {
                let companyCodes = this.companyCodes.get(id);
                let warehouseCodes = this.warehouseCodes.get(id);

                let requestObj = {
                    CompanyCodes: companyCodes.join(),
                    ItemCodes: itemCode,
                    WarehouseCodes: warehouseCodes.join(),
                }
                console.log('requestObj: '+requestObj);

                requestObjArray.push(JSON.stringify(requestObj));
                console.log('requestObjArray: '+requestObjArray);
            } else {
                productsWithoutWarehouseInfo.push(itemCode);
            }
        });

        // Show the error message if the any selected products do not have warehouse lookup populated.
        if(productsWithoutWarehouseInfo && productsWithoutWarehouseInfo.length > 0) {
            this.isLoading = false;
            let errorMessage = WAREHOUSE_LOOKUP_NOT_POPULATED + ': ' + productsWithoutWarehouseInfo.join();
            this.showToast('Error', errorMessage, 'error');
            return;
        }

        // Show a toast message if no proper products are selected resulting in the requested products for stock check being empty.
        if(!requestObjArray || requestObjArray.length == 0) {
            console.log(NO_PROPER_RECORD_SELECTED);
            this.isLoading = false;
            this.showToast('Error', NO_PROPER_RECORD_SELECTED, 'error');
            return;
        }

        console.log(requestObjArray);
        // If any serialized product is included then make the callout to the CR/OLAP service.
        if(this.isSerialized) {
            this.makeSerializedCallout(requestObjArray);
        } else {
            // Make parallel callouts to the apex service and then combine the response.
            this.makeParallelCallouts(requestObjArray, this.recordId, this.sobjectname)
            .then(response => {
                this.controlCheckStocksButton(true);
                let successRecords = [];
                let failureRecords = [];
                console.log('Continuation Response Success');
                console.log(response);
                response.forEach(result => {
                    let stockResult = JSON.parse(result);
                    if(stockResult.status != 'Failed' && stockResult.listCount > 0 && stockResult.data ) {
                        //Added by Pankaj & Shreela on 24-02-2022
                        console.log('result---------------------------');
                        stockResult.data.filter(v=>{                       
                        v.BlockedStock = v.OnHandStock- v.FreeStock - v.CommittedQty;
                        return v;
                        });//End by pankaj

                        successRecords.push(stockResult);
                    } else {
                        failureRecords.push(stockResult);
                    }
                });

                if(successRecords && successRecords.length > 0) {
                    this.showStockData(successRecords);
                } else {
                    this.isLoading = false;
                    let errorMessage = 'No data found';
                    if(failureRecords.length > 0 && failureRecords[0].data.length > 0 && failureRecords[0].data[0].message) {
                        errorMessage = failureRecords[0].data[0].message;
                    }
                    this.showToast('Error', errorMessage, 'error');
                    this.navigateToSearchTable();
                }
            })
            .catch(error => {
                console.log('Continuation Response Error');
                console.log(error);
                this.isLoading = false;
                let errorMessage = 'There was an error while fetching stock information for products.';
                if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                    errorMessage = error.body.message;
                }else if(error && error.body && error.body.pageErrors){ // Added Else if SAEPB-48
                    errorMessage = '';
                    let pgErrors = error.body.pageErrors;
                    pgErrors.filter(v=>{
                        if(v.message)
                            errorMessage += v.message+' ';
                    });
                }
                this.showToast('Error', errorMessage, 'error');
                this.controlCheckStocksButton(false);
                this.navigateToSearchTable();
            });
        }
    }

    // Function to make parallel callouts.
    async makeParallelCallouts(requestObjArray, recordId, sobjectname) {
        const promiseArray = requestObjArray.map(requestObj => this.callStockApexFunction(requestObj, recordId, sobjectname));
        const responseArray = await Promise.all(promiseArray);
        return responseArray;
    }

    // Function to call the apex function that makes the callout to the external service.
    callStockApexFunction(requestObj, recordId, sobjectname) {
        let promiseResponse = getStockProductsForBDE({productsToGet: requestObj, parentRecordId: recordId, parentObjectName: sobjectname});
        return promiseResponse;
    }

    // Function to display stock data based on the response received for non-serialized items.
    showStockData(successRecords) {
        this.isLoading = false;
        this.pageTracking.showSearchTable = false;
        this.pageTracking.searchTableVisibility = hideIt;
        this.pageTracking.showStockTable = true;
        this.pageTracking.backButtonLabel = 'Back';

        let tempTableJSON = Object.assign({}, this.stockTableJSON);

        let columns = this.parseStockColumns(successRecords[0]);
        let allDataMap = new Map();
        successRecords.forEach(successRecord => {
            let id = this.selectedValueIds.get(successRecord.data[0].Itemcode);
            let data = this.parseStockData(successRecord);
            allDataMap.set(id, data[0]);
        });

        
    /*    if(this.receivedStockData.size > 0) {
            Array.from(this.receivedStockData.keys()).forEach(key => {
                if(!allDataMap.has(key)) {
                    allDataMap.set(key, this.receivedStockData.get(key));
                }
            });
        } */

        this.receivedStockData = allDataMap;
        tempTableJSON.data = Array.from(allDataMap.values());
        tempTableJSON.columns = columns;
        tempTableJSON.reRenderTable = !tempTableJSON.reRenderTable;
        tempTableJSON.hideCheckBoxColumn = true;

        console.log('Final list of stock data to be displayed');
        console.log(tempTableJSON.data);
        
        this.stockTableJSON = tempTableJSON;
    }

    // Function to create data structure for the stock columns based on the received response.
    parseStockColumns(records) {
        let newColumns = [];
        let keyArray = [];

        stockColumnsToShowInOrder.forEach(defaultColumn => {
            let tempObj = {label: '', fieldName: '', wrapText: true};
            tempObj.fieldName = defaultColumn.toLowerCase();
            tempObj.label = defaultColumn.toUpperCase();
            newColumns.push(tempObj);
        });
        
        if(records.data.length > 0) {
            keyArray = Object.keys(records.data[0]);
        }
        keyArray.forEach(key => {
            // If the key is not part of stockColumnsToExclude and stockColumnsToShowInOrder then add it to newColumns array.
            if( !stockColumnsToExclude.includes(key.toLowerCase()) && !stockColumnsToShowInOrder.includes(key.toLowerCase())) {
                let tempObj = {label: '', fieldName: '', wrapText: true};
                tempObj.fieldName = key.toLowerCase();
                tempObj.label = key.toUpperCase();
                newColumns.push(tempObj);
            }
        });
        console.log('Stock columns to be shown');
        console.log(newColumns);
        return newColumns;
    }

    // Function to create data structure for the stock data to be displayed based on the received response.
    parseStockData(records) {
        let data = [];
        records.data.forEach(record => {
            let tempDataObj = {};
            for(const [key, value] of Object.entries(record)) {
                if( !stockColumnsToExclude.includes(key.toLowerCase())) {
                    tempDataObj[key.toLowerCase()] = value;
                }
            }
            data.push(tempDataObj);
        });
        return data;
    }

    // Function to navigate to the record detail page.
    navigateToRecordDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.sobjectname,
                actionName: 'view'
            }
        });
    }

    // Function to control whether "Check Stocks" button will be enabled or disabled.
    controlCheckStocksButton(isDisabled) {
        let pageTrackingClone = this.pageTracking;
        pageTrackingClone.isCheckStockButtonDisabled = isDisabled;
        this.pageTracking = pageTrackingClone;
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
}