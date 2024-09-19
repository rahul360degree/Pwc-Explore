import { LightningElement ,api,wire, track } from 'lwc';
import PESReport from '@salesforce/apex/PESReportsBatch.getOppDataForReport';
import getOppDataForReport from '@salesforce/apex/PESReportsBatch.getOppDataForReport';


export default class PEsReport extends LightningElement {

  @track fromDate;
  @track toDate ;
  selectedvalue ;
  isShowTable = false;
  
  @track mapOpp = {}
  @track isVisible = false;

  
    
  getOppData() {
    console.log('From Date: ' + this.fromDate);
    console.log('From Date: ' + this.toDate);
    
      getOppDataForReport({ lastNMonth: 1, isCalledFromLWC: true, fromDate: this.fromDate , toDate:this.toDate })
    
      .then(data => {
        this.mapOpp = data;


        this.isVisible = true;
        console.log('Data', data);
      })
      .catch(error => {
          console.error('Error:', error);
      })
  }
     handleFromDateChange(event) {
         //const fromDate1 = event.target.value;
         this.fromDate = event.target.value;
        console.log('From Date: ' + this.fromDate);
        // Pass this value to Apex controller to fetch data
    }

    handleToDateChange(event) {
        // const toDate1 = event.target.value;
         this.toDate = event.target.value;
        console.log('To Date: ' + this.toDate);
        // Pass this value to Apex controller to fetch data
    }
   handleSearch(event){
      
     
      this.getOppData();
      this.isShowTable = true;
   }

  
   
}