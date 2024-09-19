/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 01-10-2024
 * @last modified by  : Varun Rajpoot 
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   01-10-2024   Varun Rajpoot   Initial Version
**/
import {LightningElement,track,api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountDetails from '@salesforce/apex/DSACheckController.getAccountDetails';
import findAccountCode from '@salesforce/apex/OLAPDSAExtension.findAccountCode';
import Id from '@salesforce/user/Id'
import IsDealer from '@salesforce/apex/OLAPDSAExtension.IsDealer';
//import My_Resource from '@salesforce/resourceUrl/jsPDFfile';
//import jsPDF2 from '@salesforce/resourceUrl/jsPDF2';
//import jQuery from '@salesforce/resourceUrl/jQuery2';
//import html2canvas from '@salesforce/resourceUrl/html2canvas';
import {loadScript} from "lightning/platformResourceLoader";
//import JSPDF from '@salesforce/resourceUrl/jsPDF2';
//import DsaPDFUrl from  '@salesforce/label/c.DsaPDFUrl';
//import getContactsController from '@salesforce/apex/DSACheckController.getContactsController';

const columns = [
  { label: 'Fiscal Year', fieldName: 'fiscal_year' },
  { label: 'Fiscal Period', fieldName: 'fiscal_period' },
  { label: 'BP Code', fieldName: 'bp_code' },
  { label: 'Document Number', fieldName: 'document_number',typeAttributes: {tooltip: {fieldName: 'document_Number'}} },
  { label: 'Document Date', fieldName: 'document_date'},
  { label: 'Document Type', fieldName: 'document_type' },
  { label: 'Cheque #', fieldName: 'cheque_no' },
  { label: 'Debit Amount', fieldName: 'debit_amount', type: 'currency',typeAttributes: { currencyCode: 'INR'} },
  { label: 'Credit Amount', fieldName: 'credit_amount', type: 'currency',typeAttributes: { currencyCode: 'INR'} },
  { label: 'Balance', fieldName: 'balance', type: 'currency',typeAttributes: { currencyCode: 'INR'} },
  { label: 'Receipt Remarks', fieldName: 'receipt_remarks_reference',typeAttributes: {tooltip: {fieldName: 'receipt_remarks_reference'}}}
  
   ];

   const showIt = 'showIt';
   const hideIt = 'hideIt';

export default class CheckDSAFromTab extends NavigationMixin(LightningElement){

    contactList =[];
    dataList =[];
    /*headers = this.createHeaders([
    "Id",
    "FirstName",
    "LastName"]);  */

    headers = this.createHeaders([
      "FiscalYear",      
      "FiscalPeriod",
      "BPCode",
      "DocumentNumber",
      "DocumentDate",
      "DocumentType",
      "Cheque",
      "DebitAmount",
      "CreditAmount",
      "Balance",
      "ReceiptRemarks"      
      ]); 

    //jsPDF = My_Resource + '/jsPDF-1.3.2.zip/jsPDF-1.3.2/jspdf.js';
    //jsPDF2 = jsPDF2;
    //jQuery = jQuery;
    //html2canvas = html2canvas;

    //jsPDF = jsPDF;


    @track isLoading = true;    
    @track isReset = false;
    @track isTableLoading = false;

    @track showDsaStatementTable = false;
    @track showDsaTable =false;
    @track tableFieldJSON = {
         data: [],
         columns: [],        
      };
    @track dsaTableJSON = Object.assign({}, this.tableFieldJSON);
    @track dsaTableColumns = null;
    @track dsaTableData = null;

    @track dsaDataInPDF = null;
		
		//@track hrefdata;   

    //Properties to Track Account LookUp. 
    @track accountName;  //to get Account Name from Lookup 
    @track accountRecordId; //to get Account Id from Lookup     
    @track acc_code;   
    acc_code = new String;
    @track internal_AccCode;  
    internal_AccCode = new String;

    //Properties to Track Populated Code displaying in portal page of External User/Dealer.
    @track dealerAccsCode;  
    dealerAccsCode = new String; 
    @track user_id;  
    user_id = new String;  
    user_id = Id;
    @track DealerCode;  
    DealerCode = new String;
    @track populatedCode;

    @track isLookup = false; //to check whether user is internal or external/dealer
    @track inputBPcode;

    @track setBalanceData;
    @track finalBalance;

    //To check whether Opening/Closing Balance is Credited/Debited
    @track debitAmountClose = false;
    @track creditAmountclose = false;
    @track zeroAmountClose = false;
    @track debitAmountOpen = false;
    @track creditAmountOpen = false;
    @track zeroAmountOpen = false;

    //For PDF & Excel Button 
    @track pageTracking = {
   
      //isCheckStatementPDFButton:true,
      isCheckStatementExcelButton:true

    };

    //Toast Message
    titleText ='Error';
    messageText = 'Account Name is mandatory';
    variant = 'error';

    //Variables to Populate field in Input Fields
    @track InternalName;   
    @track InternalFromDate;
    @track InternalToDate;
    @track InputFromDate; 
    @track InputToDate;
    @track filterValues;
    filterValues = new Map();

   //To fetch the value Opening Balance in frontend.
   @api
   get setBalanceData(){
     return this.setBalanceData;
   }

   //To fetch the value Closing Balance in frontend.
   @api
   get finalBalance(){
    return this.finalBalance;
  }
   
 /*loadScript(src) {
    // creates a <script> tag and append it to the page
    // this causes the script with given src to start loading and run when complete
    let script = document.createElement('script');
    script.src = src;
    document.head.append(script);
  } */

	    connectedCallback() {

        //Call Apex Class Method to get Dealer Account Code whenever External User/Dealer logs in. 
        IsDealer({ uid: this.user_id})  
        .then((result) => {       
          this.DealerCode= JSON.stringify(result);  
          if (result.length===0) {  
            this.isLookup = true;
          }              
          else if(result.length !==0) {
            this.isLookup = false;
            this.dealerAccsCode = this.DealerCode.substring(this.DealerCode.indexOf('Account_Code__c') + 18,this.DealerCode.indexOf('Account_Code__c') + 27);
            this.populatedCode =this.dealerAccsCode;     //set dealer account code to html input text field
          }                        
        })        

        if(FORM_FACTOR.toLowerCase() == 'small') {
            this.isMobile = true;
        }       
            this.isLoading = false;        
       }

      renderedCallback() {
        if(this.isReset) {
          this.isReset = false;
        }
        //Promise.all([loadScript(this, JSPDF)]);
        /*.then((values) => {
          console.log(values);
        })
        .catch(error => {
        }); */
          //loadScript(this, jsPDF+'/jspdf.min.js'),
          //loadScript('https://cdnjs.cloudflare.com/ajax/libs/jspdf/1.3.2/jspdf.min.js')
      //]);
      /*.then(() => {
      })
      .catch(error => {
      }); */
      //loadScript('https://cdnjs.cloudflare.com/ajax/libs/jspdf/1.3.2/jspdf.min.js');

       }             
    
    onAccountSelection(event){  
        this.accountName = event.detail.selectedValue;        //set account Name
        this.accountRecordId = event.detail.selectedRecordId; //set account Id
        console.log('Final Console :' +this.accountName + 'Account Id :'+this.accountRecordId); 
        
        //Call Apex Class Method to get  Account Code of Selected Account in lookup
        findAccountCode({ accId: this.accountRecordId, accName: this.accountName})  
        .then((result) => {  
          this.acc_code = JSON.stringify(result);
          var accCodeParse = JSON.parse(this.acc_code);
          for (var i = 0; i < accCodeParse.length; i++) {
             this.internal_AccCode = accCodeParse[i]['Account_Code__c']
        } 
        }) 
        .catch((error) => {  
          this.error = error;  
          this.recordsList = undefined;  
         }); 
       } 

    // Function that handles the input change for Transaction From Date field.    
    handleTransactionFromChange(event) {
        let fromDate = [];
        let fromDateValue;
        fromDate.push(event.detail.value);

        if(fromDate.length > 0) {
            this.filterValues.set('inputFromDate', fromDate);            
            fromDateValue = fromDate.toString();
            if (fromDateValue.substr(fromDateValue.length - 2, fromDateValue.length) !="01") 
            {
                //set an error
                event.target.setCustomValidity("From date should begin from the 1st of the month");
                event.target.reportValidity();
            }
            else {
                event.target.setCustomValidity("");
                event.target.reportValidity();
            }
           }
          else {
            this.filterValues.delete('transactionFromDate');            
           }
    }

  // Function that handles the input change for Transaction To Date field.     
  handleTransactionToChange(event)
   {
     let ToDate = [];
     this.filterValues.set('inputToDate', ToDate);
     ToDate.push(event.detail.value);

      if (new Date(ToDate.toString()) > new Date())
      {
         event.target.setCustomValidity("To date should not be from future date");
         event.target.reportValidity();                 
      }
      else{
         event.target.setCustomValidity("");
         event.target.reportValidity();
      }      
     }

  //Function after clicking on Get Statement
   handleClick(event) 
  {
    this.isTableLoading = true;   //added by shreela for spinner
    this.showDsaStatementTable = false;
    this.dsaTableData = null;
    //this.dsaDataInPDF = null;
    this.showDsaTable =false;

      //Set BP code value based on Login(Dealer or Internal)
      if(this.isLookup == true){
        this.inputBPcode = this.internal_AccCode;
       }
      if(this.isLookup == false){
        this.inputBPcode = this.populatedCode;
       }

    if(this.isLookup == true) {
        if(this.inputBPcode == ""){
          const evt = new ShowToastEvent({
            title: this.titleText,
            message: this.messageText,
            variant: this.variant
           });
        this.dispatchEvent(evt);
       }
     }
     
    let inputFromDateCmp = this.template.querySelector(".inputFromDate");
    let fromDateValue = inputFromDateCmp.value;
    this.InputFromDate = inputFromDateCmp.value;

    let inputToDateCmp = this.template.querySelector(".inputToDate");
    let toDateValue = inputToDateCmp.value;
    this.InputToDate = inputToDateCmp.value;

    inputFromDateCmp.reportValidity();
    inputToDateCmp.reportValidity();
    
    if(fromDateValue == "" || toDateValue == "" ){
   
      if (fromDateValue == "")
        {
          inputFromDateCmp.setCustomValidity("Please Select Transaction From Date");
          inputFromDateCmp.reportValidity();
        } 

      else {
          inputFromDateCmp.setCustomValidity(""); 
          inputFromDateCmp.reportValidity();  
        }


      if(toDateValue == "")
        {
          inputToDateCmp.setCustomValidity("Please select Transaction To Date");
          inputToDateCmp.reportValidity();
        }

      else {
          inputToDateCmp.setCustomValidity(""); 
          inputToDateCmp.reportValidity();  
        }

    }

    else
      {
        if (fromDateValue.substr(fromDateValue.length - 2, fromDateValue.length) !="01") 
        {
          //set an error
          inputFromDateCmp.setCustomValidity("From date should begin from the 1st of the month");
          inputFromDateCmp.reportValidity();
        } 
        else if (new Date(fromDateValue) > new Date(toDateValue)) {
          //set an error
          inputFromDateCmp.setCustomValidity("From date should be less than To Date");
          inputFromDateCmp.reportValidity();
        } 
        else if (new Date(toDateValue) > new Date()) {
          //set an error
          inputToDateCmp.setCustomValidity("To date cannot be a future one");
          inputToDateCmp.reportValidity();
        } 
        else {
          //reset an error
          inputFromDateCmp.setCustomValidity("");
          inputFromDateCmp.reportValidity();
          inputToDateCmp.setCustomValidity("");
          inputToDateCmp.reportValidity();
        }
      }
   
    let bpCodeValue = this.inputBPcode;
    this.handleGetStatement(fromDateValue, toDateValue, bpCodeValue);
  } 

  //Function to handle requestObj
  handleGetStatement(fromDateValue, toDateValue, bpCodeValue) 
  {
    let arrFromDate = fromDateValue.split("-");
    let arrToDate = toDateValue.split("-");
    let closingFiscalMonth;
    let closingFiscalYear;
    let fromFiscalMonth;
    let fromFiscalYear;
    let toFiscalMonth;
    let toFiscalYear;

    if (parseInt(arrFromDate[1]) - 3 <= 0) {
      fromFiscalMonth = parseInt(arrFromDate[1]) + 9;
      fromFiscalYear = parseInt(arrFromDate[0]);
     } 
    else {
      fromFiscalMonth = parseInt(arrFromDate[1]) - 3;
      fromFiscalYear = parseInt(arrFromDate[0]) + 1;
     }

    if (parseInt(fromFiscalMonth) - 1 == 0) {
      closingFiscalMonth = 12;
      closingFiscalYear = parseInt(fromFiscalYear) - 1;
    } 
    else {
      closingFiscalMonth = fromFiscalMonth - 1;
      closingFiscalYear = fromFiscalYear;
    }

    if (parseInt(arrToDate[1]) - 3 <= 0) {
      toFiscalMonth = parseInt(arrToDate[1]) + 9;
      toFiscalYear = parseInt(arrToDate[0]);
    } 
    
    else {
      toFiscalMonth = parseInt(arrToDate[1]) - 3;
      toFiscalYear = parseInt(arrToDate[0]) + 1;
    }

    let requestObj = {
      BPCode: bpCodeValue,
      CloseBalYear: closingFiscalYear,
      CloseBalMonth: closingFiscalMonth,
      TransFromYear: fromFiscalYear,
      TransFromMonth: fromFiscalMonth,
      TransToYear: toFiscalYear,
      TransToMonth: toFiscalMonth,
      TransFromdt: fromDateValue,
      TransTodt: toDateValue
    }; 

    //console.log('JSON.stringify(requestObj) :'+JSON.stringify(requestObj));  

    getAccountDetails({accountdetails: JSON.stringify(requestObj)})
    .then(response => {

      this.isTableLoading = false;
      this.debitAmountClose = false;
      this.creditAmountClose = false;
      this.zeroAmountClose = false;
      this.debitAmountOpen = false;
      this.creditAmountOpen = false;
      this.zeroAmountOpen = false;

      let pageTrackingClone = this.pageTracking;
      //pageTrackingClone.isCheckStatementPDFButton = false;
      pageTrackingClone.isCheckStatementExcelButton = false;
      this.pageTracking = pageTrackingClone;
      let result = JSON.parse(response); 
      //alert('Result :'+result);     
      //console.log('response'+response);
      console.log('result'+result);
      
      if((result.status == 'Success') && (result.statusCode ==1011)) 
      {
        console.log('Error msg');
        this.showToast('Error Check for Response', result.message, 'error');
      }
      else { 
        if(result.data !=null || result.data.transactionalData== null){
          var test1 = result.data.transactionalData;
          var bpcodedata = result.data.bpCode;
          var docnNumber = "Opening Balance";
          var debitNumber = result.data.closing_Balance_DR;
          var creditNumber = result.data.closing_Balance_CR;
          var obj1 = {"fiscal_Year": "","fiscal_Period": "","bP_Code": bpcodedata,"document_Number": docnNumber,"document_Date": "","document_Type": "","cheque_No": "","debit_Amount": debitNumber,"credit_Amount": creditNumber,"receipt_Remarks_reference": "" };
          insertObject(test1,obj1);    //to insert opening balance as first row                 
        }

        function insertObject(arr, obj) {
          arr.unshift(obj);   
         }

        var resultCalculation =result.data.transactionalData;
        var getDebitData;
        var getCreditData;
        var setBalanceData2;
        let getBalance;
        let getBalance2;
        var finalBalance2;
        var finalBalance3;

       //To set balance of each row 
       for(var i=0;i< resultCalculation.length;i++){
            if(i==0){
              getDebitData= resultCalculation[0]['debit_Amount'];
              getCreditData = resultCalculation[0]['credit_Amount'];
              setBalanceData2 = getDebitData - getCreditData;
              this.setBalanceData = setBalanceData2.toLocaleString('en-IN',{ style: 'currency', currency: 'INR' });
                
                //To check whether Opening Balance is debited/credited
                if(setBalanceData2>0){ 
                  this.debitAmountOpen = setBalanceData2;
                }
                else if(setBalanceData2<0) {
                  this.creditAmountOpen = setBalanceData2;
                }
                else {
                this.zeroAmountOpen = true;
                }

              this.finalBalance = setBalanceData2.toLocaleString('en-IN',{ style: 'currency', currency: 'INR' }) ;
              resultCalculation[0]['balance'] = setBalanceData2.toFixed(2);
              getBalance=resultCalculation[0]['balance'];
            }
            else {      
              getBalance2 = parseFloat(getBalance) + parseFloat(resultCalculation[i]['debit_Amount'] - resultCalculation[i]['credit_Amount']);
              resultCalculation[i]['balance'] = getBalance2.toFixed(2);
              getBalance = resultCalculation[i]['balance'];
              this.finalBalance = getBalance2.toLocaleString('en-IN',{ style: 'currency', currency: 'INR' });            
            }           
          }
          
          finalBalance2 = getBalance;
          //To add Closing Balance in the last row of table 
          if((result.data !=null) || (result.data.transactionalData!= null ||result.data.transactionalData== null)){
            var test2 = result.data.transactionalData;
            var docClosingBal = "Closing Balance";
            finalBalance3 = finalBalance2;
            var obj2 = {"fiscal_Year": "","fiscal_Period": "","bP_Code": "","document_Number": docClosingBal,"document_Date": "","document_Type": "","cheque_No": "","debit_Amount": finalBalance3,"credit_Amount": "","balance":"","receipt_Remarks_reference": "" };
            var obj3 = {"fiscal_Year": "","fiscal_Period": "","bP_Code": "","document_Number": docClosingBal,"document_Date": "","document_Type": "","cheque_No": "","debit_Amount": "" ,"credit_Amount": finalBalance3,"balance":"","receipt_Remarks_reference": "" };
            
            //To check whether Closing Balance is debited/credited
            if(finalBalance2>0){
              insertObject2(test2,obj2);
              this.debitAmountClose = this.finalBalance;
            }
            else if(finalBalance2<0) {
              insertObject2(test2,obj3); 
              this.creditAmountClose = this.finalBalance;
            } 
            else {
              this.zeroAmountClose = true;
              console.log('Closing check');
            }        
          }

          function insertObject2(arr, obj) {
            arr.push(obj);   
            console.log(arr);
        }
     
        let tempTableJSON = Object.assign({}, this.dsaTableJSON);
        tempTableJSON.columns = columns;
        tempTableJSON.data = this.parseDsaData(result);
        this.showDsaStatementTable = true;
        this.dsaTableColumns = tempTableJSON.columns;
        console.log('this.dsaTableColumns'+JSON.stringify(this.dsaTableColumns));
        this.dsaTableData = tempTableJSON.data;
        console.log('this.dsaTableData'+JSON.stringify(this.dsaTableData));
        //this.dsaDataInPDF = this.parseDataNoCaps(result);
        this.dsaDataInPDF =this.dsaTableData.map(data => {        
          return { FiscalYear: data.fiscal_year, FiscalPeriod: data.fiscal_period,
          BPCode:data.bp_code,DocumentNumber: data.document_number,
          DocumentDate: data.document_date, DocumentType: data.document_type,
          Cheque: data.cheque_no,DebitAmount: data.debit_amount,
          CreditAmount: data.credit_amount, Balance: data.balance, 
          ReceiptRemarks: data.receipt_remarks_reference
                };
          });

        //Added to set input filters
        this.InternalName = this.accountName;
        this.InternalFromDate = this.InputFromDate;
        this.InternalToDate = this.InputToDate;
      }

    })
    .catch(error => {
        this.isTableLoading = false;
        let pageTrackingClone = this.pageTracking;
        //pageTrackingClone.isCheckStatementPDFButton = false;
        pageTrackingClone.isCheckStatementExcelButton = false;
        this.pageTracking = pageTrackingClone;
        //console.log(error);
        let errorMessage = 'There was an error while fetching DSA.';
        if(error.hasOwnProperty('body') && error.body.hasOwnProperty('isUserDefinedException') && error.body.isUserDefinedException) {
            errorMessage = error.body.message;
        }
        this.showToast('Error', errorMessage, 'error');
    }); 
   }


    // Function to show toast message.
    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    //Function  to parse data received from response
    parseDsaData(records){
        let data = [];
        var resultGrid = records.data.transactionalData;
        resultGrid.forEach(record => {
            let tempDataObj = {};
            let idValue = ''; 

            for(const [key, value] of Object.entries(record)) 
             {
                if(key.toLowerCase() == 'fiscal_year' || key.toLowerCase() == 'fiscal_period' || key.toLowerCase() == 'bp_code' || key.toLowerCase() == 'document_number' || key.toLowerCase() == 'document_date' || key.toLowerCase() == 'document_type' || key.toLowerCase() == 'cheque_no' || key.toLowerCase() == 'debit_amount' || key.toLowerCase() == 'credit_amount' || key.toLowerCase() == 'balance' || key.toLowerCase() == 'receipt_remarks_reference') 
                {
                    idValue += value;                    
                }
                tempDataObj[key.toLowerCase()] = value;
            } 

            tempDataObj.Id = idValue;
            data.push(tempDataObj);
        });
        return data;

    }	

    /*parseDataNoCaps(){
      let data1 = [];
      var resultGrid1 = records.data.transactionalData;
      resultGrid1.forEach(record => {
          let tempDataObj = {};
          let idValue = ''; 

          for(const [key, value] of Object.entries(record)) 
           {
              if(key == 'Fiscal Year' || key == 'Fiscal Period' || key == 'BP Code' || key == 'Document Number' || key == 'Document Date' || key == 'Document Type' || key.toLowerCase() == 'Cheque No' || key.toLowerCase() == 'debit_amount' || key.toLowerCase() == 'credit_amount' || key.toLowerCase() == 'balance' || key.toLowerCase() == 'receipt_remarks_reference') 
              {
                  idValue += value;                    
              }
              tempDataObj[key] = value;
          } 

          tempDataObj.Id = idValue;
          data1.push(tempDataObj);
      });
      return data1;


    } */

    /*generateData(){
      //let contactData;
      getContactsController().then(result =>{
        //this.contactList = result;
        this.contactList = JSON.stringify(result);
        console.log('check generateData'+this.contactList);
        //this.checkStatementinPDF(); 
      }); */

        /* ------------------------*/
        /*
        this.contactList.forEach(record => { 
        let tempContactDataObj = {};
        let idValue = '';    
        for(const [key, value] of Object.entries(record)) 
      {
         if(key == 'Id' || key == 'FirstName' || key == 'LastName') 
         {
             idValue += value;  
             console.log('Testing');                  
         }
         tempContactDataObj[key] = value;
     } 

     tempContactDataObj.Id = idValue;
     contactData.push(tempContactDataObj);      
      });
      return contactData;  */
      /* ---------------*/
    //}

    createHeaders(keys){
      let  result = [];
      for(let i=0;i<keys.length;i+=1){
        result.push({
          id:keys[i],
          name:keys[i],
          prompt:keys[i],
          //width:65,
          //width:22,
          width:32,
          //align:"centre",
          align:"left",
          padding:0,
        })
      }
      return result;
    }
    
    checkStatementinPDF() {
      let urlPDF  = DsaPDFUrl;
      //urlPDF.searchParams.set('param_1', 'val_1');
       //window.location.assign("https://gnb--onecrmdev--c.visualforce.com/apex/DsaPDF");
       //window.open("https://gnb--onecrmdev--c.visualforce.com/apex/DsaPDF");

      // console.log(urlPDF+'?BPCode=[@'+bpCodeValue+']&StartDate=[@'+fromDateValue+']&EndDate=[@'+toDateValue+']');
      //window.open(urlPDF+'?BPCode=[@'+bpCodeValue+']&StartDate=[@'+fromDateValue+']&EndDate=[@'+toDateValue+']');
      //window.open(urlPDF+'?BPCode='+bpCodeValue+'&StartDate='+fromDateValue+'&EndDate='+toDateValue);
      //window.open(urlPDF);
       
      //window.open(urlPDF+'?BPCode='+this.inputBPcode+'&StartDate='+this.InputFromDate+'&EndDate='+this.InputToDate);
      //window.open('https://gnb--onecrmdev--c.visualforce.com/apex/VF_SOA?bpCode='+3HX000001&fromDate=2019-05-01&toDate=2019-05-02&mode=PDF
      
      
      //Commented below line as not in use
      //window.open('https://gnb--onecrmdev--c.visualforce.com/apex/VF_SOA?bpCode='+this.inputBPcode+'&fromDate='+this.InputFromDate+'&toDate='+this.InputToDate+'&mode=PDF');
      /*const {jsPDF} = window.jspdf;
      const doc = new jsPDF('p', 'mm', 'a3',{
        encryption:{
          userPermissions : ["print","modify","copy","annot-forms"]
        }
      });       
      doc.text("Dealer Statement of Accounts",20, 20);
      doc.table(10,30,this.dsaDataInPDF,this.headers,{autosize:true,fontSize :11}); 
      doc.save("testDSA.pdf"); */      
    }

    //Function to download excel file in csv format
    checkStatementinExcel() {  
      let columnHeader = ["Fiscal Year", "Fiscal Period", "BP Code", "Document Number", "Document Date", "Document Type", "Cheque No", "Debit Amount", "Credit Amount", "Balance", "Receipt Remarks Reference"];  // This array holds the Column headers to be displayd
      let jsonKeys = ["fiscal_year", "fiscal_period", "bp_code", "document_number", "document_date", "document_type", "cheque_no", "debit_amount", "credit_amount", "balance", "receipt_remarks_reference"]; // This array holds the keys in the json data  
      var jsonRecordsData = this.dsaTableData;
      let csvIterativeData;  
      let csvSeperator  
      let newLineCharacter;  
      csvSeperator = ",";  
      newLineCharacter = "\n";  
      csvIterativeData = "";  
      csvIterativeData += columnHeader.join(csvSeperator);  
      csvIterativeData += newLineCharacter;  
       for (let i = 0; i < jsonRecordsData.length; i++) 
       {  
        let counter = 0;  
         for (let iteratorObj in jsonKeys) {  
           let dataKey = jsonKeys[iteratorObj];  
             if (counter > 0) {  
               csvIterativeData += csvSeperator;  
             }  
             if (  jsonRecordsData[i][dataKey] !== null &&  jsonRecordsData[i][dataKey] !== undefined ) {  
               csvIterativeData += '"' + escape(jsonRecordsData[i][dataKey]) + '"';  
             } 
             else {  
               csvIterativeData += '""';  
             }  
          counter++;  
         }  
         csvIterativeData += newLineCharacter;  
          console.log("new line added"); 
       }  
      console.log("csvIterativeData", csvIterativeData);  
      //this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
         
           var hiddenElement = document.createElement('a');
           hiddenElement.href = 'data:text/csv;charset=utf-8,' + csvIterativeData;
           //hiddenElement.href = 'data:application/excel;base64,' + csvIterativeData;
           hiddenElement.target = '_self'; // 
           hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv] 
           //hiddenElement.download = 'ExportData.xls';  // CSV file Name* you can change it.[only name not .csv] 
           document.body.appendChild(hiddenElement); // Required for FireFox browser
           hiddenElement.click(); // using click() js function to download csv file
           hiddenElement.remove();
 
    }  
    
}