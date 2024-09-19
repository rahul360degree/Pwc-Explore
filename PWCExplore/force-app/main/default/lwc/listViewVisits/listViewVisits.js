import { LightningElement,api,wire,track } from 'lwc';
import getrecords from '@salesforce/apex/listViewVisits.getrecords';
import {NavigationMixin} from 'lightning/navigation';
import { subscribe,APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import calenderMapChannel from '@salesforce/messageChannel/calenderMapChannel__c';
const columns = [
    //{ label: 'Id', fieldName: 'Id', type: 'text'},
    //{label: 'OwnerId', fieldName: 'OwnerId', type: 'Id'},
    //{label: 'PJP', fieldName: 'PJP__C', type: 'Id'},
    { label: 'Name', fieldName: 'Name', type: 'button',typeAttributes:{label:{fieldName:'Name'},variant:'base'} },
    {label:'Account Name',fieldName:'AccName',type:'text'},
    { label: 'Planned Date', fieldName: 'Visit_Planned_Date__c', type: 'Date' },
    { label: 'Start Date', fieldName: 'Visit_Start_Date__c', type: 'Date' },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'PJP Name', fieldName: 'PJP Name', type: 'text' },

];

export default class ListViewVisits extends NavigationMixin(LightningElement){
  @wire(MessageContext)
  messageContext
  @api userid;  
  @api recordId;
  @track columns = columns;
  @track data;
  subscribed = null;
  connectedCallback() {
    this.messagechannel();
  }

  messagechannel(){
    this.subscribed = subscribe(
        this.messageContext,calenderMapChannel,(message) =>
            this.handleMessage(message),{ scope: APPLICATION_SCOPE });
  }

  handleMessage(message){
    if(message!=null){
      console.log('message is'+message);
      console.log('message'+JSON.stringify(message.PjpRecordId));
      var visitRecordsList = JSON.parse(message.PjpRecordId);
      console.log(visitRecordsList[0]);
      visitRecordsList = visitRecordsList.map(item => ({'Id':item.id,'Name' : item.Name,'Visit_Planned_Date__c':item.PlannedDate,'AccName':item.AccName,'Visit_Start_Date__c':item.StartDate,'Status':item.VisitStatus,'PJP Name':item.pjpName}));
      console.log('data'+JSON.stringify(visitRecordsList));
        this.data=visitRecordsList;
    }else if(message==null){
      this.data=null;
    }
    
    
  }
  
  /*@wire(getrecords,{pjprecordid:'$recordId'})
  wiredgetrecods({error,data}){
    if(data){
        console.log('mydata')
        console.log(data);
        this.data=data;
        
    }
    else{
        console.log('error'+error);
    }
  }*/

  handlerowaction(event){
    const row =event.detail.row.Id;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes:{
            recordId: row,
            objectApiName: 'Visit__c',
            actionName: 'view'
        }
    });
  }
}