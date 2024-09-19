import { LightningElement ,api, track,wire} from 'lwc';
import getVisitRecords from '@salesforce/apex/VisitPointerMapHelper.getRelatedVisit'
import { subscribe,MessageContext } from 'lightning/messageService';
import ASM_Details from '@salesforce/messageChannel/calenderMapChannel__c'

export default class VisitPointerMap extends LightningElement {
    @api recordId;
    @track mapMarkers = [];
    visible = false;
    data;
    subscribtion = null;
    @wire(MessageContext)
    MessageContext;

    connectedCallback(){
        this.subscribeToMessageChannel();
       // this.fetchVisitRecords();
    }

    subscribeToMessageChannel(){
        console.log('Subscriber---');
        this.MessageContext = subscribe(
            this.MessageContext,
            ASM_Details,
            (message)=> this.handleMessage(message)
        );
        console.log('this00' , this.MessageContext);
    }

    handleMessage(message){
        if(message==null){
            this.mapMarkers = [];
        }else{
            console.log('Data-->' , message.PjpRecordId);
            let visitRecord = JSON.parse(message.PjpRecordId);
            this.data = visitRecord;
            this.mapMarkers = [];
            visitRecord.forEach(visit=>{
                console.log('Visit-->',visit);
                        let location;
                        let mapIcon;
                        let marker ={};
                        if(visit.Lat && visit.Long){
                            console.log('Visit-2->',visit);
                            location={
                                Latitude: visit.Lat,
                                Longitude: visit.Long
                            };
                            console.log('MApICON');
                            mapIcon={
                                path: 'M 10,0 C 0,0 0,15 10,15 L 20,30 L 30,15 C 40,15 40,0 30,0 L 10,0 z',
                                fillColor:'green',
                                fillOpacity: 1.0,
                                strokeWeight: 2,
                                strokeColour:'white',
                                scale:0.4,
                                anchor:{x:20,y:15}
                            };
                            marker.mapIcon = mapIcon;
                        }else if(visit.AccId){
                            console.log('Visit Acc-->',visit);
                            location = {
                                Street: visit.AccAddressStreet,
                                City: visit.AccAddressCity,
                                State: visit.AccAddressState,
                                PostalCode: visit.AccAddressStreet,
                                Country: visit.AccAddressCountry
                            }
                        }
    
                        if(location){
                            marker.location = location;
                            marker.title = visit.Name;
                            this.mapMarkers.push(marker);
                        }
                        console.log('MArker--->' , this.mapMarkers);
            })
            console.log('VisitRecords--> ' , visitRecord);
        }
        

    }

    fetchVisitRecords(){
        console.log('RecordID-->', this.recordId);
        getVisitRecords({pjpId:this.recordId})
            .then(data=>{
                this.data = data;
                this.mapMarkers = [];
                data.forEach(visit => {
                    console.log('Visit-->',visit);
                    let location;
                    let mapIcon;
                    let marker ={};
                    if(visit.Geolocation__Latitude__s && visit.Geolocation__Longitude__s){
                        console.log('Visit-2->',visit);
                        location={
                            Latitude: visit.Geolocation__Latitude__s,
                            Longitude: visit.Geolocation__Longitude__s
                        };
                        console.log('MApICON');
                        mapIcon={
                            path: 'M 10,0 C 0,0 0,15 10,15 L 20,30 L 30,15 C 40,15 40,0 30,0 L 10,0 z',
                            fillColor:'green',
                            fillOpacity: 1.0,
                            strokeWeight: 2,
                            strokeColour:'white',
                            scale:0.4,
                            anchor:{x:20,y:15}
                        };
                        marker.mapIcon = mapIcon;
                    }else if(visit.Account__c){
                        console.log('Visit Acc-->',visit);
                        location = {
                            Street: visit.Account__r.Primary_Address__r.Street__c,
                            City: visit.Account__r.Primary_Add_City__c,
                            State: visit.Account__r.Primary_Add_State__c,
                            PostalCode: visit.Account__r.Primary_Address_Code__c,
                            Country: visit.Account__r.Primary_Address__r.Country__c
                        }
                    }

                    if(location){
                        marker.location = location;
                        marker.title = visit.Name;
                        this.mapMarkers.push(marker);
                    }
                });
                this.visible = true;

            }
            )
            .catch(error=>{
                console.log('Error -->',error);
            })
    }
    

  
}