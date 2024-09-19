import { LightningElement, api, wire } from 'lwc';
import getOAData from '@salesforce/apex/ServiceAuditReportDatatableController.getOAData';
import updateSARLIRecords from '@salesforce/apex/ServiceAuditReportDatatableController.updateSARLIRecords';

// col for js
const columns = [

    // all used in table
    { label: 'Question', fieldName: 'Observation_Question__c', type: 'text', editable: false },
    { label: 'Maximum Score', fieldName: 'Maximum_Score__c', type: 'decimal', editable: false, typeAttributes: {minumumFractionDigits: 1, maximumFractionDigits: 1}},
    { label: 'Achieved Score', fieldName: 'Achieved_Score__c', type: 'decimal', editable: true },
    {
        label: 'Recommendation',
        fieldName: 'Recommendation__c',
        type: 'text',
        editable: true,
        typeAttributes: {
            rows: 5 // Setting the rows attribute for textarea
        },
        cellAttributes: {
            class: 'recommendation-cell'
        },
        cellAttributes: { class: 'slds-truncate' },
        cellAttributes: { iconPosition: 'right' }
    },
];

export default class OATable extends LightningElement {

    // acquired from Observation Area Id record id

    @api recordId;
    //populated by wiredOAdata
    sarliRecords = [];

    //calling method in controller class

    @wire(getOAData, { oaId: '$recordId' })

    // method to populate sarli record data

    wiredOAData({ data, error }) {
        if (data) {
            this.sarliRecords = data.sarliRecords;
        } else if (error) {
            console.error('Error retrieving OA data', error);
        }
    }

    // for lwc html
    get columns() {
        return columns;
    }

    handleSave(event) {
        const draftValues = event.detail.draftValues;

        if (draftValues.length > 0) {
            // Map draftValues to update only necessary fields
            const updatedRecords = draftValues.map(item => {
                return {
                    Id: item.Id,
                    Achieved_Score__c: item.Achieved_Score__c,
                    Recommendation__c: item.Recommendation__c,
                };
            });

            // Call Apex method to update records
            updateSARLIRecords({ updatedRecords })
                .then(result => {
                    // Optional: Handle success response
                    console.log('Records updated successfully:', result);

                    // Optional: Refresh data after successful save
                    this.refreshData();
                })
                .catch(error => {
                    // Handle errors
                    console.error('Error updating records:', error);
                });
        }
    }

    refreshData() {
        // Implement logic to refresh the data
        // You may want to re-fetch the data to reflect the changes
        this.sarliRecords = [];
        this.wiredOAData();
    }

}