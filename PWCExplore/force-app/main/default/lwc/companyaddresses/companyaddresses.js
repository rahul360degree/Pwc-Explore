/**
 * @description       : This component will display list of additional addresses.
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-17-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement, api} from 'lwc';

export default class Companyaddresses extends LightningElement {
    @api addresses;
    @api records;
    @api businessunit;

    totalrecords;
    recordsToDisplay;
    recordsPerPage = 4;
    currentPage = 1;
    paginationArray;

    //intialize
    connectedCallback() {				
        console.log(this.businessunit);
        this.totalrecords = this.records.length;        
        this.setPagination()
        this.displayRecord();
        
    }

    //Set the records to display
    get pageSizeOptions() {
        return [
            { label: '4', value: 4 },
            { label: '8', value: '8' },
            { label: '12', value: '12' }
        ];
    }

    //Set the pagination array 
    setPagination() {
        let delta = 2,
            left = this.currentPage - delta,
            right = this.currentPage + delta + 1,
            range = [],
            l,
            last = Math.ceil(this.totalrecords / this.recordsPerPage);
        this.paginationArray = [];
        for (let i = 1; i <= last; i++) {
            if (i == 1 || i == last || i >= left && i < right) {
                range.push(i);
            }
        }

        for (let i of range) {
            if (l) {
                if (i - l === 2) {
                    this.paginationArray.push(l + 1);
                } else if (i - l !== 1) {
                    this.paginationArray.push('...');
                }
            }
            this.paginationArray.push(i);
            l = i;
        }
    }

    //handle pagination click to show the records
    handleCurrentPageChange({ target: { dataset: { id } } }) {
        this.currentPage = parseInt(id);
        this.setPagination();
        this.displayRecord();
    }

    //handle page size change 
    handlePageSizeChange(event) {
        this.recordsPerPage = parseInt(event.detail.value);
        this.setPagination();
        this.displayRecord();
    }

    //display record as per page size and pagination
    displayRecord() {        
        if (this.records.length > this.recordsPerPage) {
            let recordsStart = (this.currentPage - 1) * this.recordsPerPage;
            let recordsEnd = recordsStart + this.recordsPerPage;
            this.recordsToDisplay = this.records.slice(recordsStart, recordsEnd);
        } else {
            this.recordsToDisplay = this.records;
        }

    }

    // fire event on primary address selection 
    handleAddressSelection({ target: { dataset: { name } } }) {
        let recordtoPass = this.recordsToDisplay[parseInt(name)];
        this.dispatchEvent(new CustomEvent('primaryaddrchange', {
            detail: recordtoPass
        }));

    }

    handleAdditionalAddressSelection({ target: { dataset: { name } } }) {
        let recordtoPass = this.recordsToDisplay[parseInt(name)];
        this.dispatchEvent(new CustomEvent('addrchange', {
            detail: recordtoPass
        }));

    }
}