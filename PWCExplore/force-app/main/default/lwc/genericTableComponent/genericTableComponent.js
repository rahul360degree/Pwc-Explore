import { LightningElement, track, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NO_OF_TABLE_ROWS from '@salesforce/label/c.NO_OF_TABLE_ROWS';
import MAXIMUM_SELECTABLE_VALUE_EXCEEDED_MSG from '@salesforce/label/c.MAXIMUM_SELECTABLE_VALUE_EXCEEDED_MSG';

const MAX_RECORDS_IN_PAGE = parseInt(NO_OF_TABLE_ROWS);
const showIt = 'visibility:visible';
const hideIt = 'visibility:hidden';
const TABLE_MINIMUM_SEARCH_STRING = 3;

export default class GenericTableComponent extends LightningElement {
    originalData = [];
    dataBeingShown = [];
    columns = [];
    dataMap = new Map();
    isRendered = false;
    selectedValueMap = new Map();
    @track sortBy;
    @track sortDirection;

    @track overallSelectedRows = [];
    
    // Propeties to control pagination related attributes.
    paginationTracker = {
        totalPages: 1,
        currentPage: 1,
        noOfRecords: 0,
        dataToBeShown: []
    }
    controlPrevious = hideIt;
    controlNext = showIt;
    pageNumber = 1;
    totalPages = 1;

    @api hideRowSelection = false;
    @api componentDetails;
    @api tableColumns;
    @api tableData;
    @track isMobile = false;
    @track selectionTracker = [];
    selectedRows = [];

    get hideRowSelectionToogle() {
        return this.hideRowSelection;
    }

    get getMaxRowSelection() {
        return this.componentDetails.maxDataSelectable;
    }

    // Function called when the component is first loaded.
    connectedCallback() {
        let columns;
        let data;
        if(this.tableColumns != null && this.tableColumns.length > 0) {
            columns = this.tableColumns;
        } else {
            columns = this.componentDetails.columns;
        }

        if(this.tableData != null && this.tableData.length > 0) {
            data = this.tableData;
        } else {
            data = this.componentDetails.data;
        }

        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }

        this.columns = columns;
        if(!this.isMobile){
            this.originalData = data;
        } else {
            this.originalData = this.updateColumnsWithValues(columns, data);
        }
        this.updateComponentDetails();
    }

    // Method to preselect the rows of the table.
    @api updateTableSelectionRows(selectionTrackerValues) {
        this.selectionTracker = selectionTrackerValues[this.paginationTracker.currentPage] || [];
    }

    /*
    *   Function to add value to the columns data structure, since for mobile we need to show values 
    *   and we cannot determine it in runtime in the template in LWC.
    */
    updateColumnsWithValues(columns, data) {
        let updatedData = [];
        console.log('updateColumnsWithValues: columns');
        console.log(columns);
        console.log('updateColumnsWithValues: data');
        console.log(data);

        data.forEach(dataObj => {
            let innerObject = {Id: dataObj.Id, childDataArray: [], IsChecked: false};
            columns.forEach(column => {
                let newColumn = Object.assign({fieldValue: ''}, column);
                if( ('' + dataObj[newColumn.fieldName]).length > 0) {
                    newColumn.fieldValue = dataObj[newColumn.fieldName];
                    innerObject.childDataArray.push(newColumn);
                }
            });
            updatedData.push(innerObject);
        });

        console.log('updatedData');
        console.log(updatedData);
        return updatedData;
    }

    // LWC lifecycle function called whenever the component is rerendered.
    renderedCallback() {
        if(this.isMobile) {
            this.template.querySelector('.component-container').addEventListener("touchmove", function(event){
                event.stopPropagation();
            });
        }
    }

    // Function to initialize the component related properties.
    updateComponentDetails() {
        this.parseData();
        this.createPaginationDatastructure();
    }

    // Function to parse the received data and store it in a map.
    parseData() {
        this.originalData.forEach(object => {
            this.dataMap.set(object.Id, Object.values(object));
        });
    }

    // Function to create the data structure necessary for table pagination.
    createPaginationDatastructure() {
        if(!this.isMobile) {
            this.updateTableDataRowsBeingDisplayed(this.originalData);
        } else {
            this.dataBeingShown = this.originalData;
        }
    }

    // Function to display correct number of records using pagination.
    updateTableDataRowsBeingDisplayed(dataToSplitInPages) {
        // Identify the data that is to be shown in the table.
        this.paginationTracker.dataToBeShown = dataToSplitInPages;

        // Get the number of pages that will be needed to show the data.
        this.identifyNumberOfPages(dataToSplitInPages);

        let startIndex = 1;
        if(this.paginationTracker.currentPage != 1) {
            startIndex = (this.paginationTracker.currentPage - 1) * MAX_RECORDS_IN_PAGE;
        }
        let endIndex = startIndex + MAX_RECORDS_IN_PAGE;
        this.dataBeingShown = dataToSplitInPages.slice(startIndex - 1, endIndex -1 );
        this.pageNumber = this.paginationTracker.currentPage;

        this.controlPreviousAndNext_ButtonVisibility();
    }

    // Function to identify the number of pages.
    identifyNumberOfPages(dataBeingShown) {
        if(dataBeingShown.length > MAX_RECORDS_IN_PAGE) {
            let totalRecords = dataBeingShown.length;
            let numberOfPages = totalRecords / MAX_RECORDS_IN_PAGE;

            this.paginationTracker.totalPages = Math.ceil(numberOfPages);
            this.totalPages = this.paginationTracker.totalPages;
        }
    }

    // Function to control the visibility of previous and next buttons.
    controlPreviousAndNext_ButtonVisibility() {
        // Control visibility of previous page button.
        if(this.paginationTracker.currentPage > 1) {
            this.controlPrevious = showIt;
        } else {
            this.controlPrevious = hideIt;
        }

        // Control visibility of next page button.
        if(this.paginationTracker.currentPage < this.paginationTracker.totalPages) {
            this.controlNext = showIt;
        } else {
            this.controlNext = hideIt;
        }
    }

    // Function to handle the event where user want's to navigate to the previous page in the table.
    previousPage(event) {
        if(this.paginationTracker.currentPage > 1) {
            this.paginate(event,
                this.paginationTracker.currentPage,
                --this.paginationTracker.currentPage,
                this.paginationTracker.dataToBeShown);
        }
    }

    // Function to handle the event where user want's to navigate to the next page in the table.
    nextPage(event) {
        if(this.paginationTracker.currentPage < this.paginationTracker.totalPages) {
            this.paginate(event,
                this.paginationTracker.currentPage,
                ++this.paginationTracker.currentPage,
                this.paginationTracker.dataToBeShown);
        }
    }

    // Function to update the table data being displayed based on user action.
    paginate(event, oldPageNumber, newPageNumber, dataToBeShown) {
        
        this.updateOverAllSelectionTracker(oldPageNumber, newPageNumber);
        // Get the number of pages that will be needed to show the data.
        this.identifyNumberOfPages(dataToBeShown);

        let startIndex = 1;
        if(newPageNumber != 1) {
            startIndex = (newPageNumber - 1) * MAX_RECORDS_IN_PAGE;
        }
        let endIndex = startIndex + MAX_RECORDS_IN_PAGE;
        this.dataBeingShown = dataToBeShown.slice(startIndex - 1, endIndex -1 );
        this.pageNumber = newPageNumber;

        this.controlPreviousAndNext_ButtonVisibility();
    }

    // Function to update the overallSelectedRows property which mantains all the selected values irrespective of pagination for a table.
    updateOverAllSelectionTracker(oldPageNumber, newPageNumber) {
        let currentSelectedRows = this.selectionTracker;
        let overallSelectedRows = this.overallSelectedRows || {};
        
        //store selected rows for each page as index
        overallSelectedRows[oldPageNumber] = currentSelectedRows;
        //store all selected rows across all pages
        this.overallSelectedRows = overallSelectedRows;
        //store only selected rows for current page displayed on UI
        this.selectionTracker = overallSelectedRows[newPageNumber] || [];
    }

    // Function to handle the event where user manually enters the page to navigate to.
    handlePageNumberChange(event) {
        if(event.keyCode === 13){
            let currentPageNumber = this.paginationTracker.currentPage;
            if(event.target.value < this.paginationTracker.totalPages && event.target.value > 0) {
                this.paginationTracker.currentPage = event.target.value;
            } else if(event.target.value > this.paginationTracker.totalPages) {
                this.paginationTracker.currentPage = this.paginationTracker.totalPages;
            } else {
                this.paginationTracker.currentPage = 1;
            }
            let changedPageNumber = this.paginationTracker.currentPage;
            this.paginate(event,
                currentPageNumber,
                changedPageNumber,
                this.paginationTracker.dataToBeShown);
        }        
    }

    // Function to handle row selection for mobile devices.
    onRowSelectedMobile(event) {
        console.log('Row Selected Mobile:');
        console.log(event);

        let eventClone = {detail: {selectedRows: []}};
        let tempSelectedValueMap = this.selectedValueMap;
        for(let i=0; i<this.originalData.length; i++) {
            if(this.originalData[i].Id == event.currentTarget.name) {
                this.originalData[i].IsChecked = !this.originalData[i].IsChecked;
                let childData = this.originalData[i].childDataArray;
                let tempObj = {Id: event.currentTarget.name, IsChecked: this.originalData[i].IsChecked};
                childData.forEach(data => {
                    if(data.fieldValue && ('' + data.fieldValue).length > 0) {
                        tempObj[data.fieldName] = data.fieldValue;
                    }
                });
                tempSelectedValueMap.set(event.currentTarget.name, tempObj);
                break;
            }
        }
        // If the toggle button is unchecked then remove the value from the map.
        if(!event.currentTarget.checked) {
            tempSelectedValueMap.delete(event.currentTarget.name);
        }
        eventClone.detail.selectedRows = Array.from(tempSelectedValueMap.values());
        this.onRowSelected(eventClone);
    }

    // Function to handle selection of a row.
    onRowSelected(event) {
        let isError = false;
        let errorMessage = '';

        if(!event.detail.selectedRows || event.detail.selectedRows.length == 0) {
            this.selectionTracker = [];
            this.selectedRows = [];            
            this.overallSelectedRows.splice(this.paginationTracker.currentPage, 1);
            this.updateSelectedValueMap();
            this.dispatchValues(isError, errorMessage);
        }
        else {
            let currentSelectedRows = new Map();
            event.detail.selectedRows.forEach(row => {
                if(this.selectedValueMap && !this.selectedValueMap.has(row.Id)) {
                    this.selectedValueMap.set(row.Id, row);
                }
                currentSelectedRows.set(row.Id,row);
            });

            this.selectedRows = Array.from(currentSelectedRows.values());
            this.selectionTracker = Array.from(currentSelectedRows.keys());
            this.overallSelectedRows[this.paginationTracker.currentPage] = this.selectionTracker;

            // Calculate selected values and then show error msg if it's higher than permissable limit.
            let currentSelectedRowLength = 0;
            this.overallSelectedRows.forEach(idValues => {
                if(idValues) {
                    currentSelectedRowLength += idValues.length;
                }
            });
            if(currentSelectedRowLength <= this.componentDetails.maxDataSelectable) {
                this.updateSelectedValueMap();
                this.dispatchValues(isError, errorMessage);
            } else {
                isError = true;
                errorMessage = MAXIMUM_SELECTABLE_VALUE_EXCEEDED_MSG + ' ' + this.componentDetails.maxDataSelectable;
                this.showToast('Error', errorMessage, 'error');
            }
        }
    }

    updateSelectedValueMap() {
        let tempSelectedValueMap = new Map();
        this.overallSelectedRows.forEach(idValues => {
            if(idValues && idValues) {
                idValues.forEach(idValue => {
                    tempSelectedValueMap.set(idValue, this.selectedValueMap.get(idValue));
                });
            }
        });
        this.selectedValueMap = tempSelectedValueMap;
    }

    // Function to handle search functionality and filter table data based on the search string.
    handleSearch(event) {
        let searchString = event.detail.value;
        let matchingData = [];
        if(searchString.length > TABLE_MINIMUM_SEARCH_STRING) {
            // Since the data structure for mobile view is different we also have to parse it differently.
            if(this.isMobile) {
                matchingData = this.handleSearchForMobile(searchString);
                this.dataBeingShown = matchingData;
            } else {
                this.originalData.forEach(object => {
                    let tempArray = Object.values(object).filter(value => ((''+value).toLowerCase()).includes(searchString.toLowerCase()));
                    if(tempArray.length > 0) {
                        matchingData.push(object);
                    }
                });
                this.paginationTracker.dataToBeShown = matchingData;
                this.updateTableDataRowsBeingDisplayed(this.paginationTracker.dataToBeShown);
            }
        } else {
            this.dataBeingShown = this.originalData;
            this.paginationTracker.dataToBeShown = this.originalData;
            if( !(this.isMobile) ) {
                this.updateTableDataRowsBeingDisplayed(this.paginationTracker.dataToBeShown);
            }
        }
    }

    // Function to handle search functionality and filter table data based on the search string - For mobile devices.
    handleSearchForMobile(searchString) {
        let matchingData = [];
        let dataRows = this.originalData;
        dataRows.forEach(data => {
            let dataValues = [];
            dataValues.push(data.Id);

            data.childDataArray.forEach(childData => {
                if(childData.fieldValue) {
                    dataValues.push(childData.fieldValue);
                }
            });
            if( dataValues.filter(value => ((''+value).toLowerCase()).includes(searchString.toLowerCase())).length > 0 ) {
                matchingData.push(data);
            }
        });

        return matchingData;
    }

    // Function to dispatch child data using event to the parent component.
    dispatchValues(isError, errorMsg) {
        const eventDispatcher = new CustomEvent('valueselected', {detail: {
            'field_api_name': 'search_table',
            'selected_values': Array.from(this.selectedValueMap.values()),
            'allSelected_RowTrackers': this.overallSelectedRows,
            'isError': isError,
            'errorMsg': errorMsg
        }});

        this.dispatchEvent(eventDispatcher);
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

    // Function to handle sorting properties for the table component.
    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    // Function to perform the sorting of the data.
    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.dataBeingShown));

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

        // set the sorted data to data table data
        this.dataBeingShown = parseData;

    }
}