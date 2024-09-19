import { LightningElement, wire,track,api } from 'lwc';
import FullCalendarJS from '@salesforce/resourceUrl/Fullcalendar';
import FullCalendarCustom from '@salesforce/resourceUrl/FullCalendarCustom';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from '@salesforce/apex';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord ,getFieldValue} from 'lightning/uiRecordApi';
import { publish, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import calendarMapChannel from '@salesforce/messageChannel/calenderMapChannel__c';
import fetchASMoptions from '@salesforce/apex/CustomCalendarController.fetchASMoptions';
import getAllVisitsData from '@salesforce/apex/CustomCalendarController.getAllVisitsData';
import updateScheduledDate from '@salesforce/apex/CustomCalendarController.updateScheduledDate';
import monthWiseRender from '@salesforce/apex/CustomCalendarController.monthWiseRender';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import checkUserRole from '@salesforce/apex/CustomCalendarController.checkUserRole';
import Id from "@salesforce/user/Id";
//import stausChange from '@salesforce/messageChannel/PJPRecordStatusChangeEvent__c';

export default class CustomCalendar extends NavigationMixin(LightningElement) {
    showPickList=false;
    @track pDateForNRecord;
    @track isShowModalRT=false;
    @track selectedOptionRT;
    @track recTypeOptions=[];
    @track displaynewbutton=false;
    @track isEditable=false;
    teamview=false;
    vId;   
    @track monthRend;
    monthRender='';
    @track isShowModal = false;
    @api recordId;
    @api pageType;
    @track asmOptions=[];
    @track pjpDate;
    @track displayDate;
    @track visitDetails=[];
    @track userId = Id ;//'005C4000002SCjUIAW';// using hardcode @track userId = Id; use this for bsm view:0052x000005Neh2AAC , use this for asm view:005C4000002SCjUIAW
    isBSM=false;
    enableNxtPrv=false;
    // value=null;
    calendar;
    calendarTitle;
    objectApiName = 'Visit__c';
    @track eventsList = [];
    
    @wire(getRecord, { recordId: "$recordId", fields: ["PJP__c.Start_Date__c","PJP__c.Status__c"] })
   wiredPjpData({error,data}){
    if(data){
        console.log("PJP Data for Date:",data);
        this.pjpDate=data.fields.Start_Date__c.value;
        console.log("PJP  Date:",this.pjpDate);
        let status = data.fields.Status__c.value;
        if((status == 'Draft'|| status=='Rejected') && (this.pageType=='Home'||this.pageType=='Details')){
            this.isEditable = true;
        }else{
            this.isEditable = false;
        }
        // this.displayDate=this.pjpDate;
    }
    else if(error){
        console.log("error",error);
    }
   }
   @wire(MessageContext)
   messageContext;

   //subscription;

   @wire(monthWiseRender,{forThisDate:'$monthRender',idForSearch:'$userId'})
   wiredPjpMonthData({error,data}){
    if(data){
        console.log('datais'+JSON.stringify(data));
        console.log('monthWiseRender'+this.monthRender);
        if(data.length===0){
            console.log("Array is empty",);
            // this.recordId = null;
            const payload=null;
            publish(this.messageContext,calendarMapChannel,payload);
        
        // this.userId=null;
        }else{
            console.log("in pjpdatamonth else",JSON.stringify(data));
            this.recordId = data[0].Id;
            let statusOfPjp=data[0].Status__c;
            this.userId=data[0].OwnerId;
            console.log('id'+this.recordId);
            if((statusOfPjp == 'Draft'|| statusOfPjp=='Rejected') && (this.pageType=='Home'||this.pageType=='Details')){
                this.isEditable = true;
            }else{
                this.isEditable = false;
            }
        }
        
    }
    else if(error){
        console.log(error);
    }
 }
  
    
    @wire(getAllVisitsData,{userId:'$userId',pjprecId:'$recordId',pageType:'$pageType'})
    wiredvisits({error,data}) {
        if(data) {
            console.log('datadata');
            console.log("full data",data)
            const eventList = [];
            const lmsData=[];
            for(let visit of data) {
                let colortype;
                console.log('recordtypeid'+visit.RecordTypeId
                );
                if(visit.RecordTypeId =='012C4000000ZIWjIAO'){
                    colortype = 'green';
                    console.log('inside if');
                }
                const event = {
                    id: visit.Id,
                    editable: this.isEditable, 
                    allDay : false,
                    start: visit.Visit_Planned_Date__c,
                    title: visit.Name,
                    color: colortype
                }
                console.log("**VisitName**",visit.Name);
                console.log("**ScheduleDate**",visit.Visit_Planned_Date__c);
                eventList.push(event);
                const lmsDt={
                    id:visit.Id,
                    Name:visit.Name,
                    PlannedDate:visit.Visit_Planned_Date__c,
                    StartDate:visit.Visit_Start_Date__c,
                    VisitStatus:visit.Status__c,
                    Lat:visit.Geolocation__Latitude__s, 
                    Long:visit.Geolocation__Longitude__s,
                    AccId:visit.Account__r.Id,
                    AccName:visit.Account__r.Name,
                    AccAddressCity:visit.Account__r.Primary_Add_City__c,
                    AccAddressState:visit.Account__r.Primary_Add_State__c,
                    AccAddressCode:visit.Account__r.Primary_Address_Code__c,
                    AccAddressStreet:visit.Account__r.Primary_Address__r.Street__c,
                    AccAddressCountry:visit.Account__r.Primary_Address__r.Country__c,
                    pjpStatus:visit.PJP__r.Status__c,
                    pjpName:visit.PJP__r.Name

                }
                
                lmsData.push(lmsDt);
            }
            
            // console.log("date in",this.pjpDate);
            this.eventsList = eventList;
            this.visitDetails=lmsData;
            console.log("In wiredvisits");
            console.log("is it empty?",eventList);
            console.log("recordIDPjp"+this.recordId);
            console.log("Page Type"+this.pageType);
            console.log(lmsData);
            if(eventList==null){
                lmsData=[];
            }
            const stringeventList=JSON.stringify(lmsData);
            const payload={PjpRecordId: stringeventList};
            
            console.log(this.eventsList);
            publish(this.messageContext,calendarMapChannel,payload);
            
            // this.getPJPdate();
            this.displayDate=this.pjpDate;
            console.log("DisplayDate Details",this.displayDate);
            this.initializeCalendar();
            this.showNewBt();
        } else if(error){
            console.log(error);
        }
    }
     
    showNewBt(){
        let currentdate= new Date();
            let currentMandY= (currentdate.getMonth()+1) + ' ' + currentdate.getFullYear();
            console.log('currentmonth'+currentMandY);
            let calendardate = this.calendar.view.activeStart;
            let calendarMandY= (calendardate.getMonth()+1) + ' ' + calendardate.getFullYear();
            console.log('calendarmonth'+calendarMandY);
            if((calendarMandY==currentMandY) && (this.pageType=='Home' || this.pageType=='Details')){
                this.displaynewbutton=true;
            }
            else{
                this.displaynewbutton=false;
            }

    }


    

    calendarActionsHandler(event) {
        const actionName = event.target.value;
        if(actionName === 'previous') {
            
            this.calendar.prev();
            this.monthRend=this.calendar.view.activeStart;
            this.monthRender= this.monthRend.getFullYear()+ '-' +(this.monthRend.getMonth()+1)+'-01';
            this.showNewBt();         
        } else if(actionName === 'next') {
            
            this.calendar.next();
            this.monthRend=this.calendar.view.activeStart;
            this.monthRender= this.monthRend.getFullYear()+ '-' +(this.monthRend.getMonth()+1)+'-01' ;
            this.showNewBt();
        } else if(actionName === 'today') {
            
            this.calendar.today();
            this.monthRend= new Date();//this.calendar.view.activeStart;
            this.monthRender= this.monthRend.getFullYear()+ '-' +(this.monthRend.getMonth()+1)+'-01' ;
            this.showNewBt();
        } else if(actionName === 'new') {
            this.recordTypeSelectionHandler();
        }
        //  else if(actionName === 'refresh') {
        //     this.refreshHandler();
        // }
        this.calendarTitle = this.calendar.view.title;
        
    }

    navigateToNewRecordPage(objectName, defaultValues) {
        if(!defaultValues) {
            let defaultadhoc="Ad-Hoc";
            let defaultstatus="Not Started";
            defaultValues = encodeDefaultFieldValues({
                Visit_Category__c: defaultadhoc,
                Status__c : defaultstatus
            });
        }
        // refreshApex(this.getAllVisitsData);
        console.log("In mixinAdded new meth",defaultValues);
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: objectName,
            actionName: "new",
          },
          state: {
            defaultFieldValues: defaultValues,
            nooverride: '1',
            recordTypeId: this.selectedOptionRT
          }
        });
        
    }

    dragDropEventHandler(newdate,recordId){
        
            console.log("In dragdrop method");
            updateScheduledDate({Id:recordId,dt:newdate})
            .then(()=>{
                console.log("DrnD method Worked");
            })
            .catch(error=> console.log('Error here'+JSON.stringify(error)));
    }


    connectedCallback() {
        Promise.all([
            loadStyle(this, FullCalendarJS + '/lib/main.css'),
            loadScript(this, FullCalendarJS + '/lib/main.js'),
            loadStyle(this, FullCalendarCustom)
                ])
            .then(() => {      
                checkUserRole({userId:this.userId})
                     .then(result=>{
                           
                         this.isBSM=result;
                         console.log("User Role",this.isBSM);
                         this.pageBasedDisplay();  
                            
                      })
                     .catch(error => console.log(error))
                   
                console.log("Promise done");                
             })
            .catch(error => console.log(error))   
            //this.subscribetoPJPRecordStatusChange(); 
    }

    // refreshHandler() {
    //     console.log(" refresh");
    //     refreshApex(this.dataToRefresh);
    //     this.initializeCalendar();
    //     console.log("In refresh");
    // }
    
    // subscribetoPJPRecordStatusChange(){
    //     const messageCallback = (response) =>{
        
    //         if(response.data.payload){
    //             console.log('worked');
    //             location.reload();
    //         }
    //     };
    //     subscribe('/event/PJPRecordStatusChangeEvent__e',-1,messageCallback).then(response =>{
    //         this.subscription = response;
    //     });
    // }

    // disconnectedCallback() {
    //     unsubscribe(this.subscription,response =>{
    //         console.log('Unsubscribed'+response.channel);
    //     });
    // }

    pageBasedDisplay(){

        console.log("User ID**",JSON.stringify(this.userId));        
        if(this.pageType=='TeamView'){
            console.log("In Team View page");
            this.recordId=null;
            this.displayDate=new Date();
            
            this.monthRender=this.displayDate.getFullYear()+ '-' +(this.displayDate.getMonth()+1)+'-01';

                this.showPickList=true;
                console.log("In BSM TRUE");
                fetchASMoptions({userId:this.userId})
                .then(result=>{
                    console.log("in Fetch asm options");
                    let arr=result.map(item=>({
                        label:item.Name, value:item.Id
                    }));   
                    this.userId=null;
                    this.handlePageType();             
                    this.asmOptions=arr;
                                    
                })
                .catch(error => console.log(error))
            
        }else if(this.pageType=='Home'){
            this.recordId=null;
            this.displayDate=new Date();
            this.monthRender=this.displayDate.getFullYear()+ '-' +(this.displayDate.getMonth()+1)+'-01';
        }
        
        this.handlePageType(); 
    }
    initializeCalendar() {
        const calendarEl = this.template.querySelector('div.fullcalendar');
        const copyOfOuterThis = this;
        const calendar = new FullCalendar.Calendar(calendarEl, {
            headerToolbar: false,
            //timeZone: 'UTC', 
            initialDate: copyOfOuterThis.displayDate,//new Date(),// //1537302134028 ,            
            showNonCurrentDates: false,
            fixedWeekCount: false,
            allDaySlot: false,
            displayEventEnd:false,
            navLinks: false,
            eventColor: '#f36e83',
            events: copyOfOuterThis.eventsList,
            eventDisplay: 'block',
            eventTimeFormat: {
                hour: 'numeric',
                minute: '2-digit',
                omitZeroMinute: true,
                meridiem: 'short'
            },
            dayMaxEventRows: false,
            displayEventTime:false,
            eventDidMount:function(info){
                if(!calendar.currentData||!calendar.currentData.dateProfile.activeRange)return;
                const startOfMon=calendar.currentData.dateProfile.activeRange.start;
                const endOfMon=calendar.currentData.dateProfile.activeRange.end;
                if(info.event.start >=startOfMon && info.event.end <=endOfMon){
                    return true;
                }
                return false;

            },
            
            
            eventTextColor: 'rgb(3, 45, 96)',
            dateClick: function(info) {
                let currentTime='T03:30:00.000+0000';
                let stringgetDandT= info.dateStr +''+ currentTime;
                copyOfOuterThis.pDateForNRecord=stringgetDandT;
                copyOfOuterThis.recordTypeSelectionHandler();
            },
            eventDrop: function(info){
                console.log("in event drop");
                const newdate=info.event.start;
                const recordId=info.event.id;
                copyOfOuterThis.dragDropEventHandler(newdate,recordId);

            },
            eventClick: function(info) {
                
                copyOfOuterThis.displayVisitDetails(info.event);
            }
        });
        console.log('here');
        console.log(copyOfOuterThis.events);
        calendar.render();
        calendar.setOption('contentHeight', 550);
        this.calendarTitle = calendar.view.title;
        
        console.log("CalendarTitle",this.calendarTitle);
        
        this.calendar = calendar;
        this.CurDate=this.calendar.view;//.currentStart;
        console.log("CurDate",this.CurDate);
    }

    get optionsASM() {
        return this.asmOptions;
    }

    handleChangeCB(event) {
        this.userId = event.detail.value;
        console.log('selected option'+this.userId);
        // this.initializeCalendar();
    }

    handlePageType(){
        console.log("in HandlePageType");
        if(this.pageType=='Home'){
             this.enableNxtPrv=true;
             this.teamview = false; 
        }
        else if(this.pageType=='TeamView'){
            this.displaynewbutton=false;
            this.enableNxtPrv=true;
            this.teamview = true; 
        }
        else if(this.pageType=='Details'){
            this.teamview == false;
            this.enableNxtPrv=false;
        }
        
    }

    displayVisitDetails(event){
        console.log("in displayVisitDetails before assigning"+event.id);
        this.vId=event.id;
        console.log("vId",this.vId);
        console.log("out of loop");
        this.isShowModal=true;
        
    }
    hideModalBox() {  
        this.isShowModal = false;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName'  })
    
    getObjectInfo({ error, data }) {
    if (data) {
        
        
        for(let key in data.recordTypeInfos){

            if(data.recordTypeInfos[key].name=='Master'){
                
                continue;
            }else{
                this.recTypeOptions.push({value:key,label:data.recordTypeInfos[key].name});
            }
            
           
        }
        console.log("RecordTYpes",this.recTypeOptions);

        
        
    } else if (error) {
      console.log("error while fetching record types",error);
    }
                           
   
  }
   
  get optionRecordID(){
    return this.recTypeOptions;
    
  }

  recordTypeSelectionHandler(){
    let currentdate= new Date();
            let currentMandY= (currentdate.getMonth()+1) + ' ' + currentdate.getFullYear();
            console.log('currentmonth'+currentMandY);
            let calendardate = this.calendar.view.activeStart;
            let calendarMandY= (calendardate.getMonth()+1) + ' ' + calendardate.getFullYear();
            console.log('calendarmonth'+calendarMandY);
            if(this.teamview == false){
                if(calendarMandY==currentMandY){
                    console.log("In RT Modal");
                    this.isShowModalRT=true;
                }
                else{
                    console.log('else statement');
                    this.isShowModalRT=false;
                    const event = new ShowToastEvent({
                                        title: 'Warning!',
                                        message: 'Cant Create Ad-Hoc Visits on this Month',
                                        variant: 'error'
                                    });
                                    this.dispatchEvent(event);
                }
            }
            

    
  }

  handleRadioChange(event){
    this.selectedOptionRT = event.detail.value;

  }

  handleSaveClick(){
    console.log("Selected RT value",this.selectedOptionRT);
    this.isShowModalRT=false;
    let defaultadhoc="Ad-Hoc";
    let defaultstatus="Not Started";
    const defaultValues = encodeDefaultFieldValues({
                    Visit_Planned_Date__c: this.pDateForNRecord,
                    PJP__c: this.recordId,
                    Visit_Category__c: defaultadhoc,
                    Status__c : defaultstatus
                    //RecordTypeId:this.selectedOptionRT
                });
                this.navigateToNewRecordPage(this.objectApiName, defaultValues);
                console.log("Save is closed");
       
  }
  handleCloseClick() {
    this.isShowModalRT=false;
    this.close('canceled');
  }


   
}