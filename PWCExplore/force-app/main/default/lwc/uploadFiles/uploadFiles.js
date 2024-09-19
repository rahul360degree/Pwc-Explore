import { LightningElement,wire,track,api} from 'lwc';
import fetchMetaData from '@salesforce/apex/UploadFilesMetaDataController.fetchMetaData';
import mdtLabelList from '@salesforce/apex/UploadFilesMetaDataController.mdtLabelList';
import updateContentVersionRecs from '@salesforce/apex/UploadFilesMetaDataController.updateContentVersionRecs';
import getDocuments from '@salesforce/apex/UploadFilesMetaDataController.getDocuments';
import { refreshApex } from '@salesforce/apex';
import { getRecord, deleteRecord } from 'lightning/uiRecordApi';
import Id from "@salesforce/user/Id";
import {NavigationMixin} from 'lightning/navigation';


// Appliance=H,Locks=L,Interio=W,Security Solution Division=U
const actions=[
    {label:'View',name:'view'},
    {label: 'Delete', name:'delete'}];
const columns = [    
    { label: 'Title', fieldName: 'Title' },  
    { label: 'File Type', fieldName: 'FileType' },  
    { label: 'Document Type', fieldName: 'Document_Name__c' },
    { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'auto' } } 
];  
export default class UploadFiles extends NavigationMixin(LightningElement) {
    @track userId = Id ;
    @api objectApiName;
    @api tabName;
@api recordId;
@api isCommunityPortal;
@track metaData;
columns = columns;

docList=[];
allDocsList=[];
allReqDocsList=[];
busUnit='';
selectedDoc;
documentList=[];
displayComp=false;
buField;
labelList=[];
get fields(){
    let fields = [];
    let statusField =  this.objectApiName ? `${this.objectApiName}.Status__c` : '';
    this.buField =  this.objectApiName ? `${this.objectApiName}.Business_Unit__c` : '';
    // if(this.objectApiName=='Contact'){
    //     this.buField= `${this.objectApiName}.BU__c`;
    // }else if(this.objectApiName=='Account'){
    //     this.buField= `${this.objectApiName}.Business_Unit__c`;
    // }else{
    //     this.buField= '';
    // }
    fields.push(statusField);
    fields.push(this.buField);


    return fields;
}


label='';//'TECH onboarding Documents_Appliances';//TECH Termination Documents_Appliances

consolidatedDocsList=[];

get filterDocumentList(){
    return this.documentList.filter(doc => this.allDocsList.includes(doc.Document_Name__c));
}
//Lets get the object and BU data using the recordId or something and then based on the BU lets fetch data from apex 

    // @wire(fetchMetaDataA)
    // wiredmetaData({error,data}){
    //     console.log("in wire",data);
    //     //this.allDocsList=data.DocumentName__c.split(',');
    //     console.log("Split data",this.allDocsList);

        
        
    // }

    @wire(getRecord,{recordId:'$recordId',fields: '$fields' })
    wiredRecData({error,data}){
        console.log(this.fields);
        console.log(data);
        if(data){
            if (data.fields) {
                let status = data.fields.Status__c.value;
                this.busUnit=data.fields.Business_Unit__c.value;
                // if(this.objectApiName=='Contact'){
                //     this.busUnit=data.fields.BU__c.value;
                // }else if(this.objectApiName=='Account'){
                //     this.busUnit=data.fields.Business_Unit__c.value;
                // }else{
                //     this.busUnit='Gen';
                // }
                console.log(typeof(this.busUnit));
                console.log("BusinessUnit",this.busUnit);
                mdtLabelList({BU:this.busUnit, objectApiName: this.objectApiName})
                .then(result=>{
                    this.labelList=result;
                    console.log('label list',this.labelList);
                    this.displayComponent(status);
                })
                .catch(error => console.log(error));
                
                
            } else {
                console.error("Fields not found in data:", data);
            }
        }else if(error){
            console.log("wireRECerror",error);
        }else{console.log("here",data);}
    }

    @wire(fetchMetaData,{label:'$label'})
    wiredMetaData({error,data}){
        if(data){
            this.metaData=data;
            console.log("MetaData",this.metaData);
            this.docListHandler();
        }else if(error){
            console.log("MetaDataerror",error);
        }
    }
    
    displayComponent(status){
        console.log("Status",status);
        if(this.objectApiName == 'Contact'){
            if(status == 'Deactivation Initiated' || status=='Submitted for Deactivation'|| status=='Deactivation Approved'|| status=="NOC Cleared"){
                for (let item of this.labelList){
                    if(item.Label && item.Label.toLowerCase().includes('termination'))
                    this.label=item.Label;
                }
                console.log('label assigned',this.label);
                //this.label = 'TECH Termination Documents_Appliances';
            } else {
                for (let item of this.labelList){
                    if(item.Label && item.Label.toLowerCase().includes('onboard'))
                    this.label=item.Label;
                }
               // this.label = 'TECH onboarding Documents_Appliances';//TECH Termination Documents_Appliances
            }  
        }else if(this.objectApiName == 'Account'){
            if(status!= null && status.includes('Deactivation')){
                for (let item of this.labelList){
                    if(item.Label && item.Label.toLowerCase().includes('deactivation')) {
                        this.label=item.Label;
                    }
                }
            } else if(status == 'NOC Initiated'|| status == 'Full and Final Settlement Done and ASP Closed' || status == 'BG Processed') {
                this.label = 'NOC Documents';
            } else  {
                for (let item of this.labelList){
                    if(item.Label && item.Label.toLowerCase().includes('onboard'))
                    this.label=item.Label;
                }
                console.log('Labe;l =====> ' + this.label);
                //this.label = 'ASPonBoarding';
            }
        }
        this.displayComp=true;
    }


    // connectedCallback(){

    
        
    //         // fetchMetaData({Bu:this.busUnit})//wire instead of ccback and in ccback we can check the BU
    //         // .then(result=>{
    //         //     console.log("in fetchData");
    //         //     this.metaData=result;    
    //         //     console.log("MetaData",this.metaData);
    //         //     this.docListHandler();

                   
    //         //  })
    //         // .catch(error => console.log(error))                  
    // }


    @wire(getDocuments,{rId : '$recordId'})
    getDocumentsList(value) {
        this.refreshData = value;
        const { data, error } = value;
        
        // console.log("what is in erroe",JSON.parse(error));

        if (data) {
            console.log('data---------->',data);
            this.documentList = data;
           //this.documentList = JSON.parse(JSON.stringify(data));
        } else if(error) {
            console.log('error ----> ' + error);
        }
    }

    handleDocTypeChange(event) {
        this.selectedDoc = event.detail.value;
    }

    docListHandler(){
        for(let a in this.metaData){
            this.allDocsList=this.metaData[a].DocumentName__c.split(',');
            this.allReqDocsList=this.metaData[a].RequiredDocuments__c.split(',');
            console.log("AllDocList",this.allDocsList);
            console.log("AllREQDocList",this.allReqDocsList);
        }
        const uniqueList=this.allDocsList.filter(element=> !this.allReqDocsList.includes(element));
        console.log("Consolidated list",uniqueList);
        let tempArray=this.allReqDocsList.concat(uniqueList);
        this.consolidatedDocsList=tempArray.map(value=>{
            return{
                docname:value,isRequired:uniqueList.includes(value)? false:true
            }
        });
        console.log("Combined data",this.consolidatedDocsList);

        
    }

    handleUploadFinished(event){
    console.log("In upload finished");
    const uploadedFiles = event.detail.files;
        let docType = event.target.dataset.doctype;
         console.log("uploadedfiles info",uploadedFiles);
         console.log("uploadedfiles docType",docType);
         console.log("version id?",event.target.dataset);

        updateContentVersionRecs({conVerRecIds:uploadedFiles.map(item=>item.contentVersionId), documentType:docType})
        .then(result => {
            console.log("updatemeth done");
            refreshApex(this.refreshData);
        }).catch(error => {
            // console.log("what is in data",data);
        console.log("what is in erroe",error);
            console.log('error---->' + JSON.stringify(error));
        })   
    }


    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'delete':
                deleteRecord(row.ContentDocumentId)
                .then(() => {
                    refreshApex(this.refreshData);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Document ${row.Title} deleted`,
                            variant: 'success'
                        })
                    );
                }).catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: `Error deleting ${row.Title} Document`,
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    });
                break;
                case 'view':
                    this.filePreview(row.ContentDocumentId);
                    break;
        }
    }

    filePreview(docId) {
      console.log("is comPortal",JSON.stringify(this.isCommunityPortal));
         if(this.isCommunityPortal==false){
            console.log("In if  comPortal",this.isCommunityPortal);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId:docId
            }
          })
        }else if(this.isCommunityPortal==true){
            let baseUrl= 'https://gnb--pwcexplore.sandbox.my.site.com/aspportal'+'/s/contentdocument/'+docId;

            window.open(baseUrl,'_blank');
            
        //     this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: baseUrl
        //     },
        
        //   },false);

         }
        
        


    }


    
}