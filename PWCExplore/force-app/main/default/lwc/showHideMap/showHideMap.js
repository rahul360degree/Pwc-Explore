import {LightningElement,track,api} from 'lwc';
import getDistance from '@salesforce/apex/CalculateDistance.getDistance';
import locationActionDenied from '@salesforce/label/c.Location_Access_Denied';
import mapComponentTitle from '@salesforce/label/c.Map_Component_Title';
import locationCaptured from '@salesforce/label/c.Location_Captured';
import unableToDetermineDistance from '@salesforce/label/c.Unable_to_Determine_Distance';
import holdTillLocationCaptured from '@salesforce/label/c.Hold_till_location_is_captured';

export default class ShowHideMap extends LightningElement {

    @track showHideMap=false;
    @api latitude;
    @api longitude;
    @api errorCode;
    @track isError=false;
    @api showToggle;
    @track showToggleButton=false;
    @api SODLatitude;
    @api SODLongitude;
    @api mismatchReason;
    @api askForMismatchReason;
    @api showReasonTextBox=false;
    @track wasLocationCaptured = false; 
    @track errorString='';
    @track successMsg='';
    distance;
    mapMarkers = [{
        location: {
            Latitude: '20.5937',
            Longitude: '-122.39687978.9629'
        }
    }];

    zoomLevel = 15;
    @track selectedMarkerValue;
    hasRendered = false;

    connectedCallback() {
        if(!this.showToggle){
            this.showHideMap=true;
            this.showToggleButton=false;
        }
        else{
            this.showToggleButton=true;
        }
        if (!this.hasRendered) {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(position => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    if(this.SODLatitude!=undefined 
                        && this.SODLongitude!=undefined 
                        && this.askForMismatchReason 
                        && this.latitude!=undefined 
                        && this.longitude!=undefined){
                        this.getDistanceBetweenSODAndEOD();
                    }
                    this.mapMarkers = [{
                        location: {
                            Latitude: this.latitude,
                            Longitude: this.longitude
                        },
                        title: mapComponentTitle
                    }];
                    this.wasLocationCaptured = true;
                    this.successMsg=locationCaptured;
                },
                error=>{
                    if(error.code==1){
                        this.errorString=locationActionDenied;
                    }
                    this.errorCode=error.code; 
                    this.isError=true;   
                });
            }
            this.hasRendered = true;
        }
    }

    getDistanceBetweenSODAndEOD(){
        getDistance({
            startOfDayLatitude:this.SODLatitude,
            startOfDayLongitude:this.SODLongitude,
            endOfDayLatitude:this.latitude,
            endOfDayLongitude:this.longitude
        }).then(result => {
            this.distance=result;
            this.renderMismatchReasonTextBox();
        }).catch(error => {
            this.errorString=unableToDetermineDistance + error.body.message;
            this.isError=true;  
        });
    }

    renderMismatchReasonTextBox(){
        if(this.distance>0.2 && this.askForMismatchReason){
           this.showReasonTextBox=true;
        }
    }
    
    handleToggleChange(event){
       this.showHideMap = event.target.checked;
    }

    handleReasonInput(event){
        this.mismatchReason=event.target.value;
    }

    @api
    validate() {
        if(this.wasLocationCaptured) { 
            return { isValid: true }; 
        } else {
            return { 
                isValid: false, 
                errorMessage: holdTillLocationCaptured
            }; 
        }
    }
}