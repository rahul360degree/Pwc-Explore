import { LightningElement, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldMetadata from '@salesforce/apex/InventoryCheckController.getFilterFieldsInfo';
import getProducts from '@salesforce/apex/InventoryCheckController.getProducts';
import getStockProducts from '@salesforce/apex/InventoryCheckController.getStockProducts';
import CURRENTUSERID from '@salesforce/user/Id';

import MAX_VALUE_SELECTABLE_FOR_GENERIC_PAGE from '@salesforce/label/c.MAX_VALUE_SELECTABLE_FOR_GENERIC_PAGE';
import NO_PRODUCTS_SELECTED from '@salesforce/label/c.NO_PRODUCTS_SELECTED';
import NO_PRODUCT_FILTERS from '@salesforce/label/c.NO_PRODUCT_FILTERS';
import NO_FILTERS_SELECTED from '@salesforce/label/c.NO_FILTERS_SELECTED';
import GENERIC_SEARCH_PRODUCT_ERROR_MSG from '@salesforce/label/c.GENERIC_SEARCH_PRODUCT_ERROR_MSG';
import USER_WAREHOUSE_CODES_ARE_EMPTY from '@salesforce/label/c.USER_WAREHOUSE_CODES_ARE_EMPTY';
import ERROR_IN_COMPONENT from '@salesforce/label/c.ERROR_IN_COMPONENT';
import ERROR_WHILE_FETCHING_STOCK_PRODUCTS from '@salesforce/label/c.ERROR_WHILE_FETCHING_STOCK_PRODUCTS';
import NO_COMPANY_AND_OR_WAREHOUSE_SELECTED from '@salesforce/label/c.NO_COMPANY_AND_OR_WAREHOUSE_SELECTED';

const showIt = 'showIt';
const hideIt = 'hideIt';

export default class CheckInventoryFromTabLWC extends LightningElement {
    pickListFieldJSON = {
        field_api_name: 'example',
        label: 'Status',
        reRenderComponent: false,
        placeHolder: 'Select Values',
        readOnly: true,
        singleSelect: false,
        allOptions: [
            {}
        ],
        optionMap: new Map(),
        options: [
            {}
        ]
    };

    tableFieldJSON = {
        label: '',
        field_api_name: '',
        reRenderTable: true,
        data: [],
        columns: [],
        maxDataSelectable: parseInt(MAX_VALUE_SELECTABLE_FOR_GENERIC_PAGE),
        hideCheckBoxColumn: false
    };

    stockResponseStructure = {
        itemcode: '',
        itemdesc: '',
        businesscode: '',
        itemgroup: '',
        warehouse: '',
        warehousetype: '',
        transactionaging: 0,
        invunit: '',
        stock: 0,    
        freestock: 0       
    };

    isSerialized = false;
    serializedItemMap = new Map();
    dependentFieldJSONTracker = new Map();
    filterValues = new Map();
    fireMainPageClickEvent = true;
    searchDataMap = new Map();
    selectedProductsForStockMap = new Map();
    receivedStockData = new Map();
    searchTableSelectionTracker = [];
    originalMetadataMap = new Map();

    @track disableProductLookup = false;
    @track isProjectCodeDisabled = false;
    @track isReset = false;
    @track originalMetadata;
    @track reloadPage = false;
    @track isLoading = true;
    @track isTableLoading = false;
    @track isMobile = false;
    @track pageTracking = {
        showPrimaryFilter: true,
        primaryFilterVisibility: showIt,
        showAdvancedFilter: false,
        advancedFilterVisibility: hideIt, 
        showSearchTable: false,
        searchTableVisibility: hideIt,
        showStockTable: false,
        stockTableVisibility: hideIt,
        isCheckStockButtonDisabled: true
    };

    // Properties to track picklist field properties.
    @track companyFieldJSON = Object.assign({}, this.pickListFieldJSON);
    @track stockCategoryFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track warehouseFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track productCategoryFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track productFamilyFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track statisticsCodeFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track businessCodeFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));
    @track productTypeFieldJSON = JSON.stringify(Object.assign({}, this.pickListFieldJSON));

    // Properties to track table related properties.
    @track searchTableJSON = Object.assign({}, this.tableFieldJSON);
    @track stockTableJSON = Object.assign({}, this.tableFieldJSON);
    @track tableColumns = null;
    @track tableData = null;
    @track searchTableColumns = null;
    @track searchTableData = null;
    @track stockTableColumns = null;
    @track stockTableData = null;

    // Used to catch any error's in the child component.
    errorCallback(error, stack) {
        console.log('Error Message: ' + error.message);
        console.log('Stack Value: ' + stack);
        this.showToast('Error', ERROR_IN_COMPONENT, 'error');
    }

    // Function called when the component is first loaded.
    connectedCallback() {
        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }
        this.stockTableJSON.hideCheckBoxColumn = true;
        this.initialize_FilterFields_Information();
        getFieldMetadata({userID: CURRENTUSERID}).then(result => {
            let jsonResult = JSON.parse(result);
            console.log(jsonResult);
            this.originalMetadata = jsonResult;
            this.createOriginalMetadataMap(jsonResult);
            this.init(jsonResult);
            this.isLoading = false;
        })
        .catch(error => {
            console.log(error);
            let errorMessage = 'There was an internal error while loading the component. Please contact your System Admin for more help.'
            if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                errorMessage = error.body.message;
            }
            this.isProjectCodeDisabled = true;
            this.disableProductLookup = true;
            
            this.isLoading = false;
            this.showToast('Error', errorMessage, 'error');
        });
    }

    // LWC lifecycle function called whenever the component is rerendered.
    renderedCallback() {
        if(this.isMobile) {
            this.template.querySelector('.mainContainer').addEventListener("touchmove", function(event){
                event.stopPropagation();
            });
        }

        if(this.isReset) {
            this.isReset = false;
        }
    }

    // Function to initialize the filter fields and set default values to them like label etc.
    initialize_FilterFields_Information() {
        this.companyFieldJSON.field_api_name = 'CompanyCodes';
        this.companyFieldJSON.label = 'Company';

        let tempFieldJSON = Object.assign({}, this.pickListFieldJSON);

        tempFieldJSON.field_api_name = 'Stock_Category__c';
        tempFieldJSON.label = 'Stock Category';
        this.stockCategoryFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'WarehouseCodes';
        tempFieldJSON.label = 'Warehouse Codes';
        this.warehouseFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'Product_Category__c';
        tempFieldJSON.label = 'Product Category';
        this.productCategoryFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'Family';
        tempFieldJSON.label = 'Product Family';
        this.productFamilyFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'Statistics_Code__c';
        tempFieldJSON.label = 'Statistics Code';
        this.statisticsCodeFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'Business_Code__c';
        tempFieldJSON.label = 'Business Code';
        this.businessCodeFieldJSON = JSON.stringify(tempFieldJSON);

        tempFieldJSON.field_api_name = 'Product_Type__c';
        tempFieldJSON.label = 'Product Type';
        this.productTypeFieldJSON = JSON.stringify(tempFieldJSON);
    }

    // Funtion to reset the various values to their original state. 
    resetValues() {
        this.filterValues = new Map();
        this.serializedItemMap = new Map();
        this.receivedStockData = new Map();
        this.selectedProductsForStockMap = new Map();
        this.searchTableSelectionTracker = [];
        this.isSerialized = false;
    }

    // Funtion to maintain the DS received at the loading of the component.
    createOriginalMetadataMap(resultArray) {
        if(resultArray && resultArray.length > 0) {
            resultArray.forEach(result => {
                this.originalMetadataMap.set(result.fieldAPIName, result);
            });
        }
    }

    /*
    *   Function to initilize the fields and their dependencies during the first load and whenever the page is cleared
    *   using the clear button.
    */
    init(result) {
        this.updateFieldJSON(result);
        this.setupFieldDependencyDS(result);
    }

    // Fucntion to update field JSON's based on their type and individual purpose.
    updateFieldJSON(fieldJSONList) {
        let multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
        let picklistFieldJSON = Object.assign({}, this.pickListFieldJSON);
        fieldJSONList.forEach(fieldJSON => {
            if(fieldJSON.fieldType === 'picklist') {
                switch (fieldJSON.fieldAPIName) {
                    case 'CompanyCodes':
                        picklistFieldJSON.label = fieldJSON.fieldLabel;
                        picklistFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        picklistFieldJSON.readOnly = false;
                        picklistFieldJSON.singleSelect = true;
                        picklistFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel); 
                        picklistFieldJSON.options = picklistFieldJSON.allOptions;
                        picklistFieldJSON.optionMap = this.createPicklistOptionMap(picklistFieldJSON.allOptions);
                        this.companyFieldJSON = picklistFieldJSON;
                        break;
                    case 'Stock_Category__c':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = true;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.stockCategoryFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'WarehouseCodes':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = true;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.warehouseFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'Product_Category__c':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = false;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.productCategoryFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'Family':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = false;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.productFamilyFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'Statistical_Group__c':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = false;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.statisticsCodeFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'Business_Code__c':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = false;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.businessCodeFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    case 'Product_Type__c':
                        multiSelectFieldJSON = Object.assign({}, this.pickListFieldJSON);
                        multiSelectFieldJSON.label = fieldJSON.fieldLabel;
                        multiSelectFieldJSON.field_api_name = fieldJSON.fieldAPIName;
                        multiSelectFieldJSON.readOnly = false;
                        multiSelectFieldJSON.allOptions = this.createPicklistOptionStructure(fieldJSON.fieldValueVSfieldLabel);
                        multiSelectFieldJSON.options = multiSelectFieldJSON.allOptions;
                        multiSelectFieldJSON.optionMap = this.createPicklistOptionMap(multiSelectFieldJSON.allOptions);
                        this.productTypeFieldJSON = JSON.stringify(multiSelectFieldJSON);
                        break;
                    default:
                        console.log('No match for: ' + fieldJSON.fieldAPIName);
                        break;
                }
            }
        });
    }

    // Function to setup field dependency object which will be used to track later on field updates.
    setupFieldDependencyDS(fieldJSONList) {
        fieldJSONList.forEach(fieldJSON => {
            if(fieldJSON.dependentFields.length > 0) {
                this.dependentFieldJSONTracker.set(fieldJSON.fieldAPIName, fieldJSON.dependentFields);
            }
        });
    }

    // Function to create picklist option structure to be passed to a generic component.
    createPicklistOptionStructure(fieldValueVSfieldLabel) {
        let picklistOptions = [];
        for (const [key, value] of Object.entries(fieldValueVSfieldLabel)) {
            let option = {label: '', value: '', name: ''};
            option.label = value;
            option.value = key;
            option.name = key;
            picklistOptions.push(option);
        }
        return picklistOptions;
    }

    // Function to create a map of picklist options in label: value format.
    createPicklistOptionMap(options) {
        let optionMap = new Map();
        options.forEach(option => {
            optionMap.set(option.value, option.label);
        })
        return optionMap;
    }

    // Function to handle field dependencies between different picklist fields.
    updateFieldDependencies(fieldAPIName, selectedValues) {
        if(this.dependentFieldJSONTracker.has(fieldAPIName) && selectedValues.length > 0) {
            let parentFieldJSON = this.originalMetadataMap.get(fieldAPIName);
            
            let tempStockCategoryFieldJSON = this.stockCategoryFieldJSON;
            let tempWarehouseFieldJSON = this.warehouseFieldJSON;

            this.dependentFieldJSONTracker.get(fieldAPIName).forEach(dependentFieldJSON => {
                let optionArray = [];

                // Identify the dependent field options.
                selectedValues.forEach(selectedValue => {
                    // Check if there are any dependent values.
                    let dependentValues = dependentFieldJSON.controllingFieldValue_VS_dependentValues[selectedValue];
                    if(dependentValues && dependentValues.length > 0) {
                        let dependentValueSet = new Set(dependentFieldJSON.controllingFieldValue_VS_dependentValues[selectedValue]);
                        dependentValueSet.forEach(dependentValue => {
                            let tempObj = {label: '', name: '', value: ''};
                            tempObj.value = dependentValue;
                            optionArray.push(tempObj);
                        });
                    }
                });

                if(dependentFieldJSON.dependentField_APIName == 'Stock_Category__c' && optionArray.length > 0) {
                    this.filterValues.delete('Stock_Category__c');
                    let multiSelectPicklistfieldJSON = JSON.parse(this.stockCategoryFieldJSON);
                    multiSelectPicklistfieldJSON.optionMap = this.createPicklistOptionMap(multiSelectPicklistfieldJSON.allOptions);
                    optionArray.forEach(option => {
                        option.label = multiSelectPicklistfieldJSON.optionMap.get(option.value);
                        option.name = option.value;
                    });

                    let tempfieldJSON = Object.assign({}, multiSelectPicklistfieldJSON);
                    tempfieldJSON.readOnly = false;
                    tempfieldJSON.options = optionArray;
                    tempfieldJSON.reRenderComponent = !tempfieldJSON.reRenderComponent;
                    tempStockCategoryFieldJSON = JSON.stringify(tempfieldJSON);

                    this.stockCategoryFieldJSON = tempStockCategoryFieldJSON;
                    this.template.querySelector('.stock-category-component').updateComponentProperties(JSON.parse(tempStockCategoryFieldJSON));
                    
                } else if(dependentFieldJSON.dependentField_APIName == 'WarehouseCodes' && optionArray.length > 0) {
                    optionArray = this.applyParentValueFilter(optionArray, parentFieldJSON, dependentFieldJSON.dependentField_APIName);
                    this.filterValues.delete('WarehouseCodes');
                    let multiSelectPicklistfieldJSON = JSON.parse(this.warehouseFieldJSON);
                    multiSelectPicklistfieldJSON.optionMap = this.createPicklistOptionMap(multiSelectPicklistfieldJSON.allOptions);
                    optionArray.forEach(option => {
                        option.label = multiSelectPicklistfieldJSON.optionMap.get(option.value);
                        option.name = option.value;
                    });

                    let tempfieldJSON = Object.assign({}, multiSelectPicklistfieldJSON);
                    tempfieldJSON.readOnly = false;
                    tempfieldJSON.options = optionArray;
                    tempfieldJSON.reRenderComponent = !tempfieldJSON.reRenderComponent;
                    tempWarehouseFieldJSON = JSON.stringify(tempfieldJSON);
                    
                    this.warehouseFieldJSON = tempWarehouseFieldJSON;
                    this.template.querySelector('.warehouse-category-component').updateComponentProperties(JSON.parse(tempWarehouseFieldJSON));
                }
            });
        } else if(this.dependentFieldJSONTracker.has(fieldAPIName)) {
            let fieldJSON = this.originalMetadataMap.get(fieldAPIName);
            if(fieldJSON.parentFieldAPIName && fieldJSON.parentFieldAPIName.length > 0 && this.filterValues.has(fieldJSON.parentFieldAPIName)) {
                let values = this.filterValues.get(fieldJSON.parentFieldAPIName);
                this.updateFieldDependencies(fieldJSON.parentFieldAPIName, values);
            }
            /*this.dependentFieldJSONTracker.get(fieldAPIName).forEach(dependentFieldJSON =>{
                if(dependentFieldJSON.dependentField_APIName == 'Stock_Category__c') {
                    let tempfieldJSON = Object.assign({}, JSON.parse(this.stockCategoryFieldJSON));
                    tempfieldJSON.options = tempfieldJSON.allOptions;
                    tempfieldJSON.reRenderComponent = !tempfieldJSON.reRenderComponent;
                    this.stockCategoryFieldJSON = JSON.stringify(tempfieldJSON);
                    this.template.querySelector('.stock-category-component').updateComponentProperties(JSON.parse(this.stockCategoryFieldJSON));
                } else if(dependentFieldJSON.dependentField_APIName == 'WarehouseCodes') {
                    let tempfieldJSON = Object.assign({}, JSON.parse(this.warehouseFieldJSON));
                    tempfieldJSON.options = tempfieldJSON.allOptions;
                    tempfieldJSON.reRenderComponent = !tempfieldJSON.reRenderComponent;
                    this.warehouseFieldJSON = JSON.stringify(tempfieldJSON);
                    this.template.querySelector('.warehouse-category-component').updateComponentProperties(JSON.parse(this.warehouseFieldJSON));
                }
            });*/
        }
    }

    // Function to update field dependencies based on the parent's parent field.
    applyParentValueFilter(optionArray, parentFieldJSON, currentDependentFieldAPIName) {
        if(parentFieldJSON.parentFieldAPIName.length == 0) {
            return optionArray;
        }

        let higherOrderParentJSON = this.originalMetadataMap.get(parentFieldJSON.parentFieldAPIName);
        let higherOrderParentValues = this.filterValues.get(higherOrderParentJSON.fieldAPIName);

        let dependentFieldValuesBasedOnHigherParent = [];
        for(let i=0; i < higherOrderParentJSON.dependentFields.length; i++) {
            if(higherOrderParentJSON.dependentFields[i].dependentField_APIName == currentDependentFieldAPIName) {
                dependentFieldValuesBasedOnHigherParent = higherOrderParentJSON.dependentFields[i].controllingFieldValue_VS_dependentValues;
            }
        }

        let valuesToConsider = [];

        higherOrderParentValues.forEach(value => {
            valuesToConsider.push(dependentFieldValuesBasedOnHigherParent[value]);
        });
        
        let newOptionArray = [];
        optionArray.forEach(option => {
            if(valuesToConsider.join().includes(option.value)) {
                newOptionArray.push(option);
            }
        });

        console.log('newOptionArray');
        console.log(newOptionArray);
        return newOptionArray;
    }

    // Function to decide whether to close multi-select picklist dropdowns on keep them open.
    handleMainComponentClick(event) {
        if(this.fireMainPageClickEvent) {
            this.controlMultiSelectPicklistDropDown('NONE');
        }
        this.fireMainPageClickEvent = true;
    }

    /*
    *   General Description: This function determines whether user is interating with the multi-select picklist component
    *   or with the some part of the parent component.
    
    *   Reason for implementation: This was required because parent component needs to determine whether to close the multi-select picklist
    *   dropdown if user is interacting with something else or whether the user is interacting with the multi-select picklist itself and
    *   thus the parent component should not close the dropdown.
    */
    handleMultiSelectPicklistOpenEvent(event) {
        this.controlMultiSelectPicklistDropDown(event.detail.field_api_name);
        this.fireMainPageClickEvent = false;
    }

    /*
    *   General Description: This function controls the opening and closing of multi-select picklist dropdowns.

    *   Reason for implementation: This was required because, since the multi-select picklist components are child components
    *   they are not aware when user clicks on some other component and they were not closing their dropdowns. 
    *   This function sends an event communicating to those multi-select fields which one needs to stay open 
    *   and which one's need to close their dropdowns.
    */
    controlMultiSelectPicklistDropDown(dropDownToKeepOpen) {
        let fieldApiName = dropDownToKeepOpen;
        let elements = this.template.querySelectorAll('.multiSelectPicklistComponent');
        elements.forEach(element => {
            element.closeDropDownEvent(fieldApiName);
        });
    }

    // Generic function to handle picklist events passed from the child components.
    handlePicklistEvent(event) {
        let fieldAPIName = event.detail.field_api_name;
        let values = event.detail.selected_values;
        if(values.length < 1) {
            this.filterValues.delete(fieldAPIName);
        } else {
            this.filterValues.set(fieldAPIName, values);
        }
        this.updateFieldDependencies(fieldAPIName, values);
    }

    // Generic function to handle events passed from the multi-select picklist child components.
    handleMultiSelectPicklistEvent(event) {
        let fieldAPIName = event.detail.field_api_name;
        let selectedValues = event.detail.selected_values;
        let valueArray = [];
        selectedValues.forEach(selectedValue => {
            valueArray.push(selectedValue.value);
        });

        if(!valueArray || valueArray.length < 1) {
            this.filterValues.delete(fieldAPIName);
        } else {
            this.filterValues.set(fieldAPIName, valueArray);
        }
        this.updateFieldDependencies(fieldAPIName, valueArray);
        this.fireMainPageClickEvent = false;
    }

    // Function called from the child table component, when user selects a row in the search table.
    handleSearchTableSelectionEvent(event) {
        this.isSerialized = false;
        let selectedRecords = JSON.parse(JSON.stringify(event.detail.selected_values));
        let itemCodes = [];
        selectedRecords.forEach(selectedRecord => {
            if(selectedRecord.hasOwnProperty('Part_Codes__c') && selectedRecord.Part_Codes__c.length > 0) {
                this.serializedItemMap.set(selectedRecord.Item__c, selectedRecord);
                this.isSerialized = true;
            }
            itemCodes.push(selectedRecord.Item__c);
            this.selectedProductsForStockMap.set(selectedRecord.Item__c, this.searchDataMap.get(selectedRecord.Item__c));
        });
        this.filterValues.set('itemCodes', itemCodes.join());
        if(itemCodes.length > 0) {
            this.searchTableSelectionTracker = event.detail.allSelected_RowTrackers;
            this.controlCheckStocksButton(false);
        } else {
            this.controlCheckStocksButton(true);
        }
    }

    // Function that handles the input change for Product lookup field.
    handleLookupSelection(event) {
        let itemCodes = [];
        let response = JSON.parse(event.detail.selected_values);
        response.forEach(value => {
            itemCodes.push(value);
        });
        if(itemCodes.length > 0) {
            this.filterValues.set('Item__c', itemCodes);
        } else {
            this.filterValues.delete('Item__c');
        }
    }

    // Function that handles the input change for Project__c field.
    handleProjectChange(event) {
        const projectAPIName = 'Project__c';
        let value = [];
        value.push(event.detail.value);
        if(value.length > 0) {
            this.filterValues.set(projectAPIName, value);
        } else {
            this.filterValues.delete(projectAPIName);
        }
    }

    // Function to show advanced filters page in mobile devices.
    showAdvancedFilters(event) {
        this.controlPageToDisplay('ADVANCED');
    }

    // Function to handle page navigation.
    navigateToPreviousPage(event) {
        if(this.pageTracking.showAdvancedFilter) {
            this.controlPageToDisplay('PRIMARY');
        } else if(this.pageTracking.showSearchTable) {
            this.controlPageToDisplay('ADVANCED');
        } else if(this.pageTracking.showStockTable) {
            //this.controlCheckStocksButton(true);
            this.controlPageToDisplay('SEARCH');
            this.updateSearchTablePreviousSelection();
        }
    }

    /*
    *   Function to maintain the state/show of previous selected values.
    *   Used when user navigates back from the Check Stock table.
    */
    updateSearchTablePreviousSelection() {
        if(this.searchTableSelectionTracker && this.searchTableSelectionTracker.length > 0) {
            let searchTableComponent = this.template.querySelector('.search-table-component');
            searchTableComponent.updateTableSelectionRows(this.searchTableSelectionTracker);
        }
    }

    // Function to search for products from apex based on the filters applied.
    searchForProducts(event) {
        this.isTableLoading = true;
        if(this.filterValues.size > 0) {
            
            let productFilters = {}
            for(const [key, value] of this.filterValues.entries()) {
                if(key.toUpperCase() != 'CompanyCodes'.toUpperCase() && key.toUpperCase() != 'WarehouseCodes'.toUpperCase()) {
                    productFilters[key] = value.join();
                }
            }

            if(Object.keys(productFilters).length < 1) {
                this.isTableLoading = false;
                this.showToast('Error', NO_PRODUCT_FILTERS, 'error');
            } else {
                getProducts({filters: JSON.stringify(productFilters)})
                .then(response => {
                    this.isTableLoading = false;
                    this.searchDataMap = new Map();
                    let jsonResult = Object.assign({}, JSON.parse(response));
                    let tempTableJSON = Object.assign({}, this.searchTableJSON);
                    tempTableJSON.columns = this.parseSearchTableColumns(jsonResult);
                    tempTableJSON.data = this.parseSearchTableData(jsonResult);
                    tempTableJSON.reRenderTable = tempTableJSON.reRenderTable ? false : true;
                    this.controlPageToDisplay('SEARCH');
                    this.searchTableColumns = tempTableJSON.columns;
                    this.searchTableData = tempTableJSON.data;
                    /*this.tableColumns = tempTableJSON.columns;
                    this.tableData = tempTableJSON.data;*/
                })
                .catch(error => {
                    console.log(error);
                    this.isTableLoading = false;
                    let errorMessage = GENERIC_SEARCH_PRODUCT_ERROR_MSG;
                    if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                        errorMessage = error.body.message;
                    }
                    this.showToast('Error', errorMessage, 'error');
                });
                
            }
        }else{
            this.controlPageToDisplay('ADVANCED');
            this.showToast('Error', NO_FILTERS_SELECTED, 'error');
            this.isTableLoading = false;
        }
    }

    // Method to parse the data and create column structure based on the response received from Salesforce, when user click "Search Products".
    parseSearchTableColumns(jsonResult) {
        let newColumns = [];
        for(const [key, value] of Object.entries(jsonResult.fieldValueVSfieldLabel)) {
            let tempColumnObj = {label: '', fieldName: '', sortable : true, type: 'text',wrapText: true};
            tempColumnObj.fieldName = key;
            tempColumnObj.label = value;
            newColumns.push(tempColumnObj);
        }
        return newColumns;
    }

    // Method to parse the data based on the response received from Salesforce, when user clicks on "Search Products".
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
            this.searchDataMap.set(tempObj.Item__c, tempObj);
            data.push(tempObj);
        });
        return data;
    }

    // Function that will fetch and display stock products obtained through external service.
    handleCheckStocksEvent(event) {
        this.isTableLoading = true;
        if(this.filterValues.has('itemCodes') && this.filterValues.get('itemCodes').length > 0) {
            let companyCodes = this.filterValues.get('CompanyCodes');
            let warehouseCodes = this.filterValues.get('WarehouseCodes');
            if(!companyCodes || !warehouseCodes) {
                this.showToast('Error', NO_COMPANY_AND_OR_WAREHOUSE_SELECTED, 'error');
                this.controlPageToDisplay('SEARCH');
                this.isTableLoading = false;
                return;
            }
            let requestObj = {
                CompanyCodes: companyCodes.join(),
                IsSerialized: this.isSerialized,
                ProjectCodes: "",
                WarehouseCodes: warehouseCodes.join()
            }
            if(this.isSerialized) {
                requestObj.ItemCodes = this.updateRequestObjectToShowSerializedData();
            } else {
                requestObj.ItemCodes = this.filterValues.get('itemCodes');
            }
            console.log(requestObj);
            getStockProducts({productsToGet: JSON.stringify(requestObj)})
            .then(response => {
                this.isTableLoading = false;
                this.controlCheckStocksButton(true);
                console.log('Stock Response');
                let result = JSON.parse(response);
                console.log(result);
                // Show error message if response or data is not received.
                if(result.status == 'Failed' || !result.data || result.listCount < 1) {
                    this.filterValues.delete('itemCodes');
                    this.controlPageToDisplay('SEARCH');
                    this.showToast('Error', result.message, 'error');
                } else {
					//Added by Varun & Pankaj on 21-02-22
                    let resultFreeStock =result.data;
					resultFreeStock.filter(v=>{
					v.blockedStock = v.stock- v.freeStock- v.commitedQty;
					return v;
					});
					//End by Varun & Pankaj

                    let tempTableJSON = Object.assign({}, this.stockTableJSON);
                    tempTableJSON.columns = this.parseStockColumns(result);
                    tempTableJSON.data = this.parseStockData(result);
                    if(this.receivedStockData.size > 0) {
                        console.log(Array.from(this.receivedStockData.values()));
                        tempTableJSON.data = Array.from(this.receivedStockData.values());
                    }
                    if(this.selectedProductsForStockMap.size > 0 && !this.isSerialized) {
                        let missingStockData = this.appendMissingSearchValues();
                        tempTableJSON.data = tempTableJSON.data.concat(missingStockData);
                        console.log('Missing data');
                        console.log(missingStockData);
                    }
                    tempTableJSON.reRenderTable = tempTableJSON.reRenderTable ? false : true;
                    tempTableJSON.hideCheckBoxColumn = true;
                    // Remove the itemCodes
                    this.filterValues.delete('itemCodes');
                    this.controlPageToDisplay('STOCK');
                    this.stockTableColumns = tempTableJSON.columns;
                    this.stockTableData = tempTableJSON.data;
                }
            })
            .catch(error => {
                console.log(error);
                let errorMessage = ERROR_WHILE_FETCHING_STOCK_PRODUCTS;
                if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
                    errorMessage = error.body.message;
                }

                this.showToast('Error', errorMessage, 'error');
                this.controlCheckStocksButton(true);
                this.isTableLoading = false;
                this.controlPageToDisplay('SEARCH');
            });
        } else {
            this.isTableLoading = false;
            this.controlPageToDisplay('SEARCH');
            this.showToast('Error', NO_PRODUCTS_SELECTED, 'error');
        }
    }

    // A parser to update the item codes being sent if a serialized item is selected for check stock operation.
    updateRequestObjectToShowSerializedData() {
        let itemCodes = this.filterValues.get('itemCodes').split(',');
        let actualItemCodeList = [];
        itemCodes.forEach(itemCode => {
            if(this.serializedItemMap.has(itemCode) && this.serializedItemMap.get(itemCode).hasOwnProperty('Part_Codes__c')) {
                actualItemCodeList = actualItemCodeList.concat((this.serializedItemMap.get(itemCode).Part_Codes__c.split(',')));
            }
        });
        return actualItemCodeList.join();
    }

    // Method to parse the data and create column structure based on the response received from Infor, when user click "Check Stock".
    parseStockColumns(records) {
        let newColumns = [];
        let keyArray = [];
        
        if(records.data.length > 0) {
            keyArray = Object.keys(records.data[0]);
        }
        keyArray.forEach(key => {
            let tempObj = {label: '', fieldName: '', wrapText: true};
            tempObj.fieldName = key.toLowerCase();
            tempObj.label = key.toUpperCase();
            newColumns.push(tempObj);
        });
        return newColumns;
    }

    // Method to parse the data based on the response received from Infor, when user clicks on "Check Stock".
    parseStockData(records) {
        let data = [];
        records.data.forEach(record => {
            let tempDataObj = {};
            let idValue = ''; // Used for rendering stock data in mobile since it requires a key named Id for data manipulation.
            for(const [key, value] of Object.entries(record)) {
                if(key.toLowerCase() == 'itemcode' || key.toLowerCase() == 'transactionaging' || key.toLowerCase() == 'stock' || key.toLowerCase() == 'FREESTOCK') {
                    idValue += value;
                }
                tempDataObj[key.toLowerCase()] = value;
                if(key.toLowerCase() == 'itemcode') {
                    // Delete entries for those records from the map for which we have received response from Infor.
                    this.selectedProductsForStockMap.delete(value);
                }
            }
            // Maintain a map of the records that we received from Infor, for we will keep showing them until the user doesn't select
            // for the same set of records for stock check again.
            this.receivedStockData.set(idValue, tempDataObj);
            tempDataObj.Id = idValue;
            data.push(tempDataObj);
        });
        return data;
    }

    /*
    *   This function creates records with free stock, transaction aging and on hand stock values for those products whose stock info
    *   was not received from infor.
    */
    appendMissingSearchValues() {
        if(this.selectedProductsForStockMap.size == 0) {
            return [];
        } else {
            let missingDataArray = [];
            Array.from(this.selectedProductsForStockMap.values()).forEach(searchData => {
                let tempStockObj = Object.assign({}, this.stockResponseStructure);
                tempStockObj.businesscode = searchData.Business_Code__c ? searchData.Business_Code__c : '';
                tempStockObj.itemcode = searchData.Item__c ? searchData.Item__c : '';
                tempStockObj.itemgroup = searchData.Item_Group__c ? searchData.Item_Group__c : '';
                tempStockObj.itemdesc = searchData.Name ? searchData.Name : '';
                missingDataArray.push(tempStockObj);
            });
            this.selectedProductsForStockMap = new Map();
            return missingDataArray;
        }
    }

    // Function to control which page to display through pageTracking property.
    controlPageToDisplay(pageToShow) {
        let tempPageTrackingObject = Object.assign({}, this.pageTracking);
        switch (pageToShow) {
            case 'SEARCH':
                tempPageTrackingObject.showPrimaryFilter = false;
                tempPageTrackingObject.showAdvancedFilter = false;
                tempPageTrackingObject.showStockTable = false;
                tempPageTrackingObject.showSearchTable = true;

                // For mobile.
                tempPageTrackingObject.primaryFilterVisibility = hideIt;
                tempPageTrackingObject.advancedFilterVisibility = hideIt;
                tempPageTrackingObject.searchTableVisibility = showIt;
                tempPageTrackingObject.stockTableVisibility = hideIt;
                break;
            case 'ADVANCED':
                tempPageTrackingObject.showPrimaryFilter = false;
                tempPageTrackingObject.showAdvancedFilter = true;
                tempPageTrackingObject.showStockTable = false;
                tempPageTrackingObject.showSearchTable = false;

                // For mobile.
                tempPageTrackingObject.primaryFilterVisibility = hideIt;
                tempPageTrackingObject.advancedFilterVisibility = showIt;
                tempPageTrackingObject.searchTableVisibility = hideIt;
                tempPageTrackingObject.stockTableVisibility = hideIt;
                break;
            case 'STOCK':
                tempPageTrackingObject.showPrimaryFilter = false;
                tempPageTrackingObject.showAdvancedFilter = false;
                tempPageTrackingObject.showStockTable = true;
                tempPageTrackingObject.showSearchTable = false;

                // For mobile.
                tempPageTrackingObject.primaryFilterVisibility = hideIt;
                tempPageTrackingObject.advancedFilterVisibility = hideIt;
                tempPageTrackingObject.searchTableVisibility = hideIt;
                tempPageTrackingObject.stockTableVisibility = showIt;
                break;
            default:
                tempPageTrackingObject.showPrimaryFilter = true;
                tempPageTrackingObject.showAdvancedFilter = false;
                tempPageTrackingObject.showStockTable = false;
                tempPageTrackingObject.showSearchTable = false;

                // For mobile.
                tempPageTrackingObject.primaryFilterVisibility = showIt;
                tempPageTrackingObject.advancedFilterVisibility = hideIt;
                tempPageTrackingObject.searchTableVisibility = hideIt;
                tempPageTrackingObject.stockTableVisibility = hideIt;
                break;
        }
        this.pageTracking = Object.assign({}, tempPageTrackingObject);
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

    // Function to clear all the filters
    handleClearEvent(event) {
        this.resetValues();
        this.reloadPage = !this.reloadPage;
        this.init(Array.from(this.originalMetadataMap.values()));
        this.controlPageToDisplay('PRIMARY');
        this.controlCheckStocksButton(true);
        this.isReset = true;
    }
}