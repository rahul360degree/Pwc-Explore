import { LightningElement,api,wire,track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import NoLocationsError from '@salesforce/label/c.No_Location_Found_Error';
import startOfDayTitle from '@salesforce/label/c.Start_of_Day_Title';
import endOfDayTitle from '@salesforce/label/c.End_of_Day_Title';

export default class ShowAttendanceLocations extends LightningElement {
    @api recordId;
    @track mapMarkers = [];
    error;
    @track selectedMarkerValue;
    zoomLevel = 10;

    @wire(getRecord, { recordId:'$recordId', fields: ['Attendance__c.Start_of_Day_Geolocation__Latitude__s',
                                                      'Attendance__c.Start_of_Day_Geolocation__Longitude__s',
                                                      'Attendance__c.End_of_Day_Geolocation__Latitude__s',
                                                      'Attendance__c.End_of_Day_Geolocation__Longitude__s',
                                                      'Attendance__c.Start_Of_Day__c',
                                                      'Attendance__c.End_Of_Day__c'
                                                      ]})
    wiredAttendance({ error, data }){
        if (data) {
            if(data.fields.Start_of_Day_Geolocation__Latitude__s.value === undefined && data.fields.Start_of_Day_Geolocation__Longitude__s.value === undefined){
                this.showToast('Error',NoLocationsError,'error');
            } else {
                let startDateVal = new Date(data.fields.Start_Of_Day__c.value).toString();
                this.mapMarkers = [{
                    location: {
                        Latitude: data.fields.Start_of_Day_Geolocation__Latitude__s.value,
                        Longitude: data.fields.Start_of_Day_Geolocation__Longitude__s.value
                    },
                    title: startOfDayTitle,
                    description: 'Logged at ' + startDateVal,
                    value: 'Start'
                }];
            }
            if (data.fields.End_of_Day_Geolocation__Latitude__s.value !== undefined && data.fields.End_of_Day_Geolocation__Latitude__s.value !== null) {
                let startDateVal = new Date(data.fields.Start_Of_Day__c.value).toString();
                let endDateVal = new Date(data.fields.End_Of_Day__c.value).toString();
                this.mapMarkers = [{
                    location: {
                        Latitude: data.fields.Start_of_Day_Geolocation__Latitude__s.value,
                        Longitude: data.fields.Start_of_Day_Geolocation__Longitude__s.value
                    },
                    title: startOfDayTitle,
                    description: 'Logged at ' + startDateVal,
                    value: 'Start'
                }, {
                    location: {
                        Latitude: data.fields.End_of_Day_Geolocation__Latitude__s.value,
                        Longitude: data.fields.End_of_Day_Geolocation__Longitude__s.value
                    },
                    title: endOfDayTitle,
                    description: 'Logged at ' + endDateVal,
                    value: 'End'
                }];
            }
            this.selectedMarkerValue = 'Start';
        } else if(error) {
            this.showToast('Error', error.body.message,'error')
        }
    }

    showToast(title,msg,variant){
        const evt = new ShowToastEvent({
            "title": title,
            "message": msg,
            "variant": variant
        });
        this.dispatchEvent(evt);
    }
}