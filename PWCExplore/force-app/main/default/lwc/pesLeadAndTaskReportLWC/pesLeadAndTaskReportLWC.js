import { LightningElement,wire,track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import Status from '@salesforce/schema/Lead.Status';
import fetchFilteredRecords from '@salesforce/apex/PesLeadAndTaskReportApexClass.fetchFilteredRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LEAD_OBJECT from '@salesforce/schema/Lead'; // Import the Lead object

const columns = [
    { label: 'Lead Number', fieldName: 'leadNumber',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Lead Incharge', fieldName: 'leadIncharge',wrapText: true, wrapTextMaxLines: 3 },
    { label: 'PES Sector', fieldName: 'pesSector',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Title', fieldName: 'leadTitle',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Description', fieldName: 'description',wrapText: true, wrapTextMaxLines: 3 },
    { label: 'Customer/Company', fieldName: 'leadCompany',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Lead Status', fieldName: 'leadStatus',wrapText: true, wrapTextMaxLines: 3 },
    //{ label: 'Task Type', fieldName: 'taskType',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Task Subject', fieldName: 'taskSubject',wrapText: true, wrapTextMaxLines: 3 },
    { label: 'Action to be Taken', fieldName: 'actionToBeTaken',wrapText: true, wrapTextMaxLines: 3 },
    { label: 'Task Status', fieldName: 'taskStatus',wrapText: true, wrapTextMaxLines: 3  },
    { label: 'Task Start Date', fieldName: 'taskStartDate',wrapText: true, wrapTextMaxLines: 3 }, //Replaced label and field by Shreela on 12th Sept 2023 for SPEP - 24
    { label: 'Task End Date', fieldName: 'taskEndDate',wrapText: true, wrapTextMaxLines: 3  },
         ];
    //Changed Task Subject/Description to Task Subject, commented task type and added Action to be taken header by Shreela on 29th Sept 2023 for SPEP - 30

export default class PesLeadAndTaskReportLWC extends LightningElement {
    isLoading = false; // Set initial loading state
    @track statusOptions = []; // Array to store the picklist options
    @track leadFromCreationDate=''; //Set Lead Creation From Date 
    @track leadToCreationDate=''; //Set Lead Creation To Date 
    @track leadIncharge; //Set Lead Incharge
    @track leadStatus; //Set Lead Status
    @track showTable = false; //To render table conditionally
    @track data = []; //To set data of datatable
    @track columns = null; //To set column of datatable
   
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$pesLeadRecordTypeId', // Pass the dynamically retrieved record type Id
        fieldApiName: Status
    })
    statusValues({ error, data }) {
        if (data) {
            this.statusOptions = [
                { label: '--None--', value: '' },
                ...data.values.map((item) => ({
                    label: item.label,
                    value: item.value
                }))
            ];
        } else if (error) {
            console.log('error :' + JSON.stringify(error));
        }
    }

    get pesLeadRecordTypeId() {
        if (this.objectInfo.data) {
            const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
            for (const key in recordTypeInfos) {
                if (recordTypeInfos.hasOwnProperty(key)) {
                    const recordTypeInfo = recordTypeInfos[key];
                    if (recordTypeInfo.name === 'PES Lead') {
                        return recordTypeInfo.recordTypeId;
                    }
                }
            }
        }
        return null;
    }

    handleChange(event){
        this.fieldName = event.target.dataset.name;

        const fieldMapping = {
            LeadCreationFromDate: 'leadFromCreationDate',
            LeadCreationToDate: 'leadToCreationDate',
            LeadStatus: 'leadStatus'
        };

        if (fieldMapping[this.fieldName]) {
            this[fieldMapping[this.fieldName]] = event.target.value;

            // Check if the field is either LeadCreationFromDate or LeadCreationToDate
            if (this.fieldName === 'LeadCreationFromDate' || this.fieldName === 'LeadCreationToDate') {
                this.updateDateValidationMessage();
            }
        }
    }

    //Added onUserSelection by Shreela on 4th September 2023 for SPEP-23
    onUserSelection(event){  
        this.leadIncharge = event.detail.selectedRecordId; //set User Id
    }

        handleClick(event) {
           
            const selectedButton = event.target.getAttribute('data-id');
            fetchFilteredRecords({leadFromCreationDate: this.leadFromCreationDate,leadToCreationDate: this.leadToCreationDate,leadIncharge :this.leadIncharge,leadStatus : this.leadStatus})
            .then(response => {

                this.showTable = false;
                this.data = [];
                    if(response != null){
                        console.log('JSON.parse(response)'+response);
                        this.data = JSON.parse(response);
                        this.columns = columns;
                    }


                    if(this.data && this.data.length > 0){
                        if(selectedButton === 'button1'){ //If Get Records button is clicked
                            this.showTable = true;
                        }
                        else if (selectedButton === 'button2'){ //If Get Records in Excel button is clicked
                            // Generate CSV data and initiate download
                            this.generateAndDownloadCSV();
                    }
                    
                }
                else{
                    this.showToast('Error', 'No data found','error'); 

                } 
                
              })

            .catch((error) => { 
                console.log('error :'+error);
    
            })
    
    }

    showToast(title, message, variant){
        const evt = new ShowToastEvent({
                title: title,
                message:message,
                variant: variant
            });
            this.dispatchEvent(evt);
    }

    updateDateValidationMessage() {

        let fromField = this.template.querySelector('.leadFromCreatedDate');
        let toField = this.template.querySelector('.leadToCreatedDate');

        const date1 = this.leadFromCreationDate;
        const date2 = this.leadToCreationDate;

        //Modified and added few conditions by Shreela on 5th September 2023 for SPEP-23
        if (date1 && !date2) {
            // If From Date is added and To date is not, show error for missing To date
            fromField.setCustomValidity("Include To Date field when From Date is provided");
        } else if (!date1 && date2) {
            // If To date  is added and From Date is not, show error for missing From Date
            toField.setCustomValidity("Include From Date field when To Date is provided");
        }
        else if(date1 === null && date2){
            // If From Date is intentionally removed while To date is present, show error for missing date1
            fromField.setCustomValidity("Include From Date field when To Date is provided"); 
            toField.setCustomValidity("");

        }
        else if(date2 === null && date1){
            // If To date  is intentionally removed while From Date is present, show error for missing To date 
            fromField.setCustomValidity("");
            toField.setCustomValidity("Include  To Date field when  From Date is provided"); 
        }
        else {
            fromField.setCustomValidity("");
            toField.setCustomValidity("");
        }
    
        // Report validity for both fields
        fromField.reportValidity();
        toField.reportValidity();
    }

    generateAndDownloadCSV() {
        //Replaced Created date with Start date and interchange of Subject and Type by Shreela on 12th Sept 2023 for SPEP - 24
        let columnHeader = ["Lead Number", "Lead Incharge", "PES Sector", "Title", "Description", "Customer/Company", "Lead Status","Task Subject","Action to be Taken", "Task Status", "Task Start Date", "Task End Date"];  // This array holds the Column headers to be displayd
        //Changed Task Subject/Description to Task Subject by Shreela on 29th Sept 2023 for SPEP - 30
        let jsonKeys = ["leadNumber", "leadIncharge", "pesSector", "leadTitle", "description", "leadCompany", "leadStatus","taskSubject", "actionToBeTaken","taskStatus", "taskStartDate", "taskEndDate"]; // This array holds the keys in the json data  
        //Removed task Type and added ActionToBeTaken variable in column Header and jsonKeys by Shreela on 29th Sept 2023 for SPEP - 30    
        var jsonRecordsData = this.data;
        let csvIterativeData;  
        let csvSeperator  
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";    
        csvIterativeData = columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  

        // Loop and generate CSV data
        for (let i = 0; i < jsonRecordsData.length; i++) 
            {  
                let counter = 0;  
                    for (let iteratorObj in jsonKeys) { 
                        let dataKey = jsonKeys[iteratorObj];  
                            if (counter > 0) {   
                                csvIterativeData += csvSeperator;
                            }   
                            if ( jsonRecordsData[i][dataKey] !== null &&  jsonRecordsData[i][dataKey] !== undefined ) {  
                                csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"'; 
                            } 
                            else {  
                                csvIterativeData += '""';  
                            }  
                            counter++;  
                           
                        }  
                        csvIterativeData += newLineCharacter;   
            } 

        // Initiate download
        this.initiateCSVDownload(csvIterativeData);
    }
   

    initiateCSVDownload(csvData){
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvData);
        hiddenElement.target = '_self';
        hiddenElement.download = 'LeadTaskReportData.csv';
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        hiddenElement.remove();
    }
 


}